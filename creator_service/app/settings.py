from __future__ import annotations

import os
import secrets
from dataclasses import dataclass, field
from pathlib import Path


@dataclass(slots=True)
class Settings:
    project_root: Path = field(default_factory=lambda: Path(
        os.environ.get("PIXELRPG_PROJECT_ROOT", Path(__file__).resolve().parents[2])
    ).resolve())
    session_token: str = field(default_factory=lambda: os.environ.get(
        "PIXELRPG_SESSION_TOKEN", secrets.token_urlsafe(32)
    ))
    ollama_url: str = field(default_factory=lambda: os.environ.get(
        "PIXELRPG_OLLAMA_URL", "http://127.0.0.1:11434"
    ).rstrip("/"))
    quality_model: str = field(default_factory=lambda: os.environ.get(
        "PIXELRPG_QUALITY_MODEL", "qwen3.5:9b"
    ))
    fast_model: str = field(default_factory=lambda: os.environ.get(
        "PIXELRPG_FAST_MODEL", "qwen3.5:4b"
    ))
    embedding_model: str = field(default_factory=lambda: os.environ.get(
        "PIXELRPG_EMBEDDING_MODEL", "qwen3-embedding:0.6b"
    ))
    host: str = "127.0.0.1"
    port: int = field(default_factory=lambda: int(os.environ.get("PIXELRPG_PORT", "8765")))
    max_context_tokens: int = 16_000

    @property
    def creator_directory(self) -> Path:
        path = self.project_root / ".creator"
        path.mkdir(parents=True, exist_ok=True)
        return path

    @property
    def database_path(self) -> Path:
        return self.creator_directory / "knowledge.db"

    def resolve_project_path(self, candidate: str | Path) -> Path:
        path = Path(candidate)
        if not path.is_absolute():
            path = self.project_root / path
        resolved = path.resolve()
        if not resolved.is_relative_to(self.project_root):
            raise ValueError("Path is outside the registered project root")
        return resolved


settings = Settings()
