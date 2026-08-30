from __future__ import annotations

import csv
import io
from functools import lru_cache
from pathlib import Path


PLAIN_EXTENSIONS = {".md", ".txt", ".json", ".csv", ".tsv", ".gd"}
DOCLING_EXTENSIONS = {".pdf", ".docx", ".pptx", ".xlsx", ".html", ".png", ".jpg", ".jpeg", ".webp"}


@lru_cache(maxsize=1)
def _document_converter():
    from docling.document_converter import DocumentConverter

    return DocumentConverter()


def extract_document(path: Path) -> tuple[str, list[str]]:
    warnings: list[str] = []
    suffix = path.suffix.lower()
    if suffix in PLAIN_EXTENSIONS:
        text = path.read_text(encoding="utf-8-sig", errors="replace")
        if suffix in {".csv", ".tsv"}:
            delimiter = "\t" if suffix == ".tsv" else ","
            rows = csv.reader(io.StringIO(text), delimiter=delimiter)
            text = "\n".join(" | ".join(cell.strip() for cell in row) for row in rows)
        return text, warnings
    if suffix not in DOCLING_EXTENSIONS:
        return "", [f"Unsupported document type: {suffix}"]
    try:
        converter = _document_converter()
    except ImportError:
        return "", [f"Docling is not installed; skipped {path.name}"]
    try:
        result = converter.convert(path)
        return result.document.export_to_markdown(), warnings
    except Exception as exc:  # Docling can expose parser-specific failures.
        return "", [f"Could not parse {path.name}: {exc}"]


def split_sections(text: str, minimum_chars: int = 1200, maximum_chars: int = 3000) -> list[tuple[str, str]]:
    """Create roughly 400–800 token chunks while preserving Markdown headings."""
    paragraphs = [part.strip() for part in text.replace("\r\n", "\n").split("\n\n") if part.strip()]
    chunks: list[tuple[str, str]] = []
    heading = ""
    buffer: list[str] = []
    size = 0
    for paragraph in paragraphs:
        if paragraph.startswith("#"):
            heading = paragraph.lstrip("# ").strip()
        projected = size + len(paragraph) + 2
        if buffer and projected > maximum_chars and size >= minimum_chars:
            chunks.append((heading, "\n\n".join(buffer)))
            overlap = buffer[-1:] if buffer else []
            buffer = overlap.copy()
            size = sum(len(item) + 2 for item in buffer)
        buffer.append(paragraph)
        size += len(paragraph) + 2
    if buffer:
        chunks.append((heading, "\n\n".join(buffer)))
    return chunks
