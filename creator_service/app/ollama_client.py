from __future__ import annotations

import asyncio
import base64
import json
import os
from collections.abc import AsyncIterator
from pathlib import Path
from typing import Any

import httpx

from .settings import settings


class OllamaClient:
    def __init__(self, base_url: str | None = None) -> None:
        self.base_url = (base_url or settings.ollama_url).rstrip("/")

    async def models(self) -> list[dict[str, Any]]:
        if os.environ.get("PIXELRPG_MOCK_AI") == "1":
            return [{"name": "pixelrpg-mock", "digest": "local-test", "size": 0}]
        async with httpx.AsyncClient(timeout=3.0) as client:
            response = await client.get(f"{self.base_url}/api/tags")
            response.raise_for_status()
            return list(response.json().get("models", []))

    async def running_models(self) -> list[dict[str, Any]]:
        if os.environ.get("PIXELRPG_MOCK_AI") == "1":
            return []
        async with httpx.AsyncClient(timeout=3.0) as client:
            response = await client.get(f"{self.base_url}/api/ps")
            response.raise_for_status()
            return list(response.json().get("models", []))

    async def embed(self, texts: list[str]) -> list[list[float]]:
        if not texts:
            return []
        if os.environ.get("PIXELRPG_MOCK_AI") == "1":
            return [_mock_embedding(text) for text in texts]
        async with httpx.AsyncClient(timeout=90.0) as client:
            response = await client.post(
                f"{self.base_url}/api/embed",
                json={"model": settings.embedding_model, "input": texts, "truncate": True},
            )
            response.raise_for_status()
            return list(response.json().get("embeddings", []))

    async def stream_chat(
        self,
        model: str,
        system: str,
        prompt: str,
        output_format: dict[str, Any] | str | None,
        image_paths: list[Path] | None = None,
    ) -> AsyncIterator[str]:
        if os.environ.get("PIXELRPG_MOCK_AI") == "1":
            mocked = _mock_draft(prompt)
            for start in range(0, len(mocked), 31):
                await asyncio.sleep(0)
                yield mocked[start:start + 31]
            return
        user_message: dict[str, Any] = {"role": "user", "content": prompt}
        if image_paths:
            user_message["images"] = [
                base64.b64encode(path.read_bytes()).decode("ascii") for path in image_paths
            ]
        payload: dict[str, Any] = {
            "model": model,
            "messages": [{"role": "system", "content": system}, user_message],
            "stream": True,
            "options": {"num_ctx": settings.max_context_tokens, "temperature": 0.45},
        }
        if output_format:
            payload["format"] = output_format
        timeout = httpx.Timeout(180.0, connect=5.0)
        async with httpx.AsyncClient(timeout=timeout) as client:
            async with client.stream("POST", f"{self.base_url}/api/chat", json=payload) as response:
                response.raise_for_status()
                async for line in response.aiter_lines():
                    if not line:
                        continue
                    packet = json.loads(line)
                    content = str(packet.get("message", {}).get("content", ""))
                    if content:
                        yield content
                    if packet.get("done"):
                        break


def _mock_embedding(text: str, dimensions: int = 32) -> list[float]:
    values = [0.0] * dimensions
    for index, byte in enumerate(text.encode("utf-8")):
        values[index % dimensions] += (byte - 127.5) / 127.5
    norm = sum(value * value for value in values) ** 0.5 or 1.0
    return [value / norm for value in values]


def _mock_draft(prompt: str) -> str:
    lowered = prompt.lower()
    if "dialog" in lowered or "對話" in prompt:
        draft = {
            "schema_version": 1, "id": "ai_mira_draft", "title": "AI 草稿：米拉",
            "start_node": "start", "characters": ["hero", "mira"],
            "nodes": [
                {"id": "start", "type": "line", "speaker": "mira", "text": "鐘聲沒有消失，只是被霧藏了起來。", "next": "end"},
                {"id": "end", "type": "end"},
            ],
        }
    else:
        draft = {
            "schema_version": 1, "id": "ai_health_tonic", "display_name": "晨霧藥露",
            "icon": "", "category": "consumable", "description": "以霧晶調製的微甜藥露。",
            "stack_limit": 10, "effects": [{"type": "heal", "value": 25, "target": "self"}],
            "obtain_conditions": [],
        }
    return json.dumps(draft, ensure_ascii=False)
