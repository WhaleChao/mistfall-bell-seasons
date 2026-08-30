from __future__ import annotations

import hashlib
import json
import math
import re
import sqlite3
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .extractors import DOCLING_EXTENSIONS, PLAIN_EXTENSIONS, extract_document, split_sections
from .models import SourceChunk
from .ollama_client import OllamaClient
from .settings import settings


@dataclass(slots=True)
class RebuildResult:
    indexed_files: int
    unchanged_files: int
    chunks: int
    warnings: list[str]
    vector_backend: str


class KnowledgeIndex:
    def __init__(self, database_path: Path | None = None) -> None:
        self.database_path = database_path or settings.database_path
        self.database_path.parent.mkdir(parents=True, exist_ok=True)
        self.vector_backend = "python-cosine"
        self._initialize()

    def _connect(self) -> sqlite3.Connection:
        connection = sqlite3.connect(self.database_path)
        connection.row_factory = sqlite3.Row
        return connection

    def _initialize(self) -> None:
        with self._connect() as connection:
            connection.executescript(
                """
                PRAGMA journal_mode=WAL;
                CREATE TABLE IF NOT EXISTS sources (
                    path TEXT PRIMARY KEY,
                    sha256 TEXT NOT NULL,
                    indexed_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
                );
                CREATE VIRTUAL TABLE IF NOT EXISTS chunks_fts USING fts5(
                    source_id UNINDEXED,
                    source_path UNINDEXED,
                    heading,
                    content,
                    tokenize='unicode61'
                );
                CREATE TABLE IF NOT EXISTS embeddings (
                    source_id TEXT PRIMARY KEY,
                    chunk_id INTEGER UNIQUE NOT NULL,
                    vector TEXT NOT NULL
                );
                """
            )
            try:
                import sqlite_vec

                connection.enable_load_extension(True)
                sqlite_vec.load(connection)
                connection.enable_load_extension(False)
                connection.execute(
                    "CREATE VIRTUAL TABLE IF NOT EXISTS vec_chunks USING vec0(embedding float[1024])"
                )
                self.vector_backend = "sqlite-vec"
            except (ImportError, sqlite3.Error):
                self.vector_backend = "python-cosine"

    def chunk_count(self) -> int:
        with self._connect() as connection:
            return int(connection.execute("SELECT count(*) FROM chunks_fts").fetchone()[0])

    def _default_paths(self) -> list[Path]:
        paths: list[Path] = []
        for relative in ("knowledge", "assets/source", "data"):
            root = settings.project_root / relative
            if not root.exists():
                continue
            paths.extend(path for path in root.rglob("*") if path.is_file())
        return paths

    async def rebuild(
        self,
        ollama: OllamaClient,
        requested_paths: list[str] | None = None,
        force: bool = False,
    ) -> RebuildResult:
        allowed = PLAIN_EXTENSIONS | DOCLING_EXTENSIONS
        if requested_paths:
            files = [settings.resolve_project_path(path) for path in requested_paths]
        else:
            files = self._default_paths()
        files = sorted({path for path in files if path.is_file() and path.suffix.lower() in allowed})
        indexed_files = 0
        unchanged_files = 0
        total_chunks = 0
        warnings: list[str] = []
        for path in files:
            relative = path.relative_to(settings.project_root).as_posix()
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            with self._connect() as connection:
                current = connection.execute("SELECT sha256 FROM sources WHERE path = ?", (relative,)).fetchone()
            if current and current[0] == digest and not force:
                unchanged_files += 1
                continue
            text, extraction_warnings = extract_document(path)
            warnings.extend(extraction_warnings)
            if not text.strip():
                continue
            sections = split_sections(text)
            vectors: list[list[float]] = []
            try:
                vectors = await ollama.embed([content for _, content in sections])
            except Exception as exc:
                warnings.append(f"Embedding unavailable for {relative}: {exc}")
            self._replace_source(relative, digest, sections, vectors)
            indexed_files += 1
            total_chunks += len(sections)
        return RebuildResult(indexed_files, unchanged_files, total_chunks, warnings, self.vector_backend)

    def _replace_source(
        self,
        path: str,
        digest: str,
        sections: list[tuple[str, str]],
        vectors: list[list[float]],
    ) -> None:
        with self._connect() as connection:
            old_ids = [row[0] for row in connection.execute(
                "SELECT source_id FROM chunks_fts WHERE source_path = ?", (path,)
            )]
            for source_id in old_ids:
                row = connection.execute(
                    "SELECT chunk_id FROM embeddings WHERE source_id = ?", (source_id,)
                ).fetchone()
                if row and self.vector_backend == "sqlite-vec":
                    try:
                        connection.execute("DELETE FROM vec_chunks WHERE rowid = ?", (row[0],))
                    except sqlite3.Error:
                        pass
            connection.execute("DELETE FROM embeddings WHERE source_id IN (SELECT source_id FROM chunks_fts WHERE source_path = ?)", (path,))
            connection.execute("DELETE FROM chunks_fts WHERE source_path = ?", (path,))
            for index, (heading, content) in enumerate(sections):
                source_id = hashlib.sha256(f"{path}:{index}:{digest}".encode()).hexdigest()[:20]
                connection.execute(
                    "INSERT INTO chunks_fts(source_id, source_path, heading, content) VALUES (?, ?, ?, ?)",
                    (source_id, path, heading, content),
                )
                if index < len(vectors) and vectors[index]:
                    vector = vectors[index]
                    chunk_id = int(hashlib.sha256(source_id.encode()).hexdigest()[:14], 16)
                    connection.execute(
                        "INSERT OR REPLACE INTO embeddings(source_id, chunk_id, vector) VALUES (?, ?, ?)",
                        (source_id, chunk_id, json.dumps(vector)),
                    )
                    if self.vector_backend == "sqlite-vec" and len(vector) == 1024:
                        try:
                            import sqlite_vec

                            connection.execute(
                                "INSERT OR REPLACE INTO vec_chunks(rowid, embedding) VALUES (?, ?)",
                                (chunk_id, sqlite_vec.serialize_float32(vector)),
                            )
                        except (ImportError, sqlite3.Error):
                            pass
            connection.execute(
                "INSERT OR REPLACE INTO sources(path, sha256, indexed_at) VALUES (?, ?, CURRENT_TIMESTAMP)",
                (path, digest),
            )

    async def search(self, query: str, ollama: OllamaClient, limit: int = 6) -> list[SourceChunk]:
        keyword_rows = self._keyword_search(query, max(limit * 2, 8))
        query_vector: list[float] = []
        try:
            embeddings = await ollama.embed([query])
            if embeddings:
                query_vector = embeddings[0]
        except Exception:
            pass
        vector_scores = self._vector_search(query_vector, max(limit * 2, 8)) if query_vector else {}
        combined: dict[str, dict[str, Any]] = {}
        for rank, row in enumerate(keyword_rows):
            combined[row["source_id"]] = {**dict(row), "score": 1.0 / (60 + rank)}
        for rank, (source_id, similarity) in enumerate(vector_scores.items()):
            if source_id not in combined:
                row = self._chunk_by_id(source_id)
                if row:
                    combined[source_id] = {**dict(row), "score": 0.0}
            if source_id in combined:
                combined[source_id]["score"] += (1.0 / (60 + rank)) + max(0.0, similarity) * 0.01
        ordered = sorted(combined.values(), key=lambda item: item["score"], reverse=True)[:limit]
        return [
            SourceChunk(
                source_id=item["source_id"], path=item["source_path"], heading=item["heading"],
                excerpt=item["content"][:1200], score=float(item["score"]),
            )
            for item in ordered
        ]

    async def confirm_image_description(self, relative_path: str, description: str, ollama: OllamaClient) -> int:
        """Index only user-confirmed image text; the original image stays untouched."""
        digest = hashlib.sha256(description.encode("utf-8")).hexdigest()
        sections = split_sections(f"# 圖片描述：{relative_path}\n\n{description}")
        vectors: list[list[float]] = []
        try:
            vectors = await ollama.embed([content for _, content in sections])
        except Exception:
            pass
        self._replace_source(f"confirmed-image:{relative_path}", digest, sections, vectors)
        return len(sections)

    def _keyword_search(self, query: str, limit: int) -> list[dict[str, Any]]:
        tokens = re.findall(r"[\w\u3400-\u9fff]+", query.lower())[:12]
        if not tokens:
            return []
        expression = " OR ".join(f'"{token}"' for token in tokens)
        merged: dict[str, dict[str, Any]] = {}
        with self._connect() as connection:
            try:
                for row in connection.execute(
                    "SELECT source_id, source_path, heading, content, bm25(chunks_fts) AS rank "
                    "FROM chunks_fts WHERE chunks_fts MATCH ? ORDER BY rank LIMIT ?",
                    (expression, limit),
                ):
                    merged[row["source_id"]] = dict(row)
            except sqlite3.Error:
                pass
            query_bigrams = _cjk_bigrams(query)
            if query_bigrams:
                scored: list[tuple[int, sqlite3.Row]] = []
                for row in connection.execute(
                    "SELECT source_id, source_path, heading, content FROM chunks_fts LIMIT 2000"
                ):
                    overlap = len(query_bigrams & _cjk_bigrams(row["content"]))
                    if overlap:
                        scored.append((overlap, row))
                scored.sort(key=lambda item: item[0], reverse=True)
                for overlap, row in scored[:limit]:
                    if row["source_id"] not in merged:
                        value = dict(row)
                        value["rank"] = -float(overlap)
                        merged[row["source_id"]] = value
        return list(merged.values())[:limit]

    def _vector_search(self, query_vector: list[float], limit: int) -> dict[str, float]:
        scored: list[tuple[str, float]] = []
        with self._connect() as connection:
            for row in connection.execute("SELECT source_id, vector FROM embeddings"):
                vector = json.loads(row["vector"])
                if len(vector) == len(query_vector):
                    scored.append((row["source_id"], _cosine(query_vector, vector)))
        scored.sort(key=lambda item: item[1], reverse=True)
        return dict(scored[:limit])

    def _chunk_by_id(self, source_id: str) -> sqlite3.Row | None:
        with self._connect() as connection:
            return connection.execute(
                "SELECT source_id, source_path, heading, content FROM chunks_fts WHERE source_id = ?",
                (source_id,),
            ).fetchone()


def _cosine(left: list[float], right: list[float]) -> float:
    numerator = sum(a * b for a, b in zip(left, right, strict=True))
    left_norm = math.sqrt(sum(value * value for value in left))
    right_norm = math.sqrt(sum(value * value for value in right))
    return numerator / (left_norm * right_norm) if left_norm and right_norm else 0.0


def _cjk_bigrams(text: str) -> set[str]:
    characters = [character for character in text if "\u3400" <= character <= "\u9fff"]
    return {"".join(characters[index:index + 2]) for index in range(len(characters) - 1)}
