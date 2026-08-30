from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator


ArtifactType = Literal[
    "characters", "enemies", "items", "skills", "quests", "dialogues", "world_events", "answer"
]


class AssistRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    task: str = Field(min_length=1, max_length=120)
    prompt: str = Field(min_length=1, max_length=20_000)
    artifact_type: ArtifactType = "answer"
    mode: Literal["quality", "fast"] = "quality"
    max_context_tokens: int = Field(default=16_000, ge=512, le=16_000)
    image_paths: list[str] = Field(default_factory=list, max_length=4)

    @field_validator("image_paths")
    @classmethod
    def no_blank_paths(cls, value: list[str]) -> list[str]:
        if any(not path.strip() for path in value):
            raise ValueError("image paths cannot be blank")
        return value


class ValidateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    artifact_type: ArtifactType
    draft: dict[str, Any]


class IndexRebuildRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    paths: list[str] = Field(default_factory=list, max_length=1000)
    force: bool = False


class ImageDescribeRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    path: str = Field(min_length=1, max_length=1000)
    prompt: str = Field(default="描述圖中的角色、物件、色彩與可用遊戲語意。", max_length=2000)
    mode: Literal["quality", "fast"] = "quality"


class ImageConfirmRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    path: str = Field(min_length=1, max_length=1000)
    description: str = Field(min_length=1, max_length=20_000)


class ValidationResult(BaseModel):
    valid: bool
    errors: list[str]
    warnings: list[str] = Field(default_factory=list)


class SourceChunk(BaseModel):
    source_id: str
    path: str
    heading: str = ""
    excerpt: str
    score: float


class HealthResult(BaseModel):
    service: Literal["ok"] = "ok"
    project_root: str
    ollama: bool
    gpu: str | None = None
    index_chunks: int
    models: list[str]
    warnings: list[str] = Field(default_factory=list)
