from __future__ import annotations

import asyncio
import json
import os
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

os.environ["PIXELRPG_MOCK_AI"] = "1"

from app.main import app  # noqa: E402
from app.assistant import assist_events  # noqa: E402
from app.models import AssistRequest  # noqa: E402
from app.settings import settings  # noqa: E402
from app.validator import validate_draft  # noqa: E402


def test_project_root_blocks_path_escape() -> None:
    with pytest.raises(ValueError):
        settings.resolve_project_path(Path(settings.project_root).parent / "outside.txt")


def test_invalid_item_is_rejected() -> None:
    result = validate_draft("items", {"schema_version": 1, "id": "Bad ID"})
    assert not result.valid
    assert result.errors


def test_dialogue_semantics_reject_unknown_character_and_dangling_route() -> None:
    result = validate_draft("dialogues", {
        "schema_version": 1,
        "id": "bad_dialogue",
        "title": "Bad",
        "start_node": "start",
        "characters": ["mirra"],
        "nodes": [{"id": "start", "type": "line", "speaker": "mirra", "text": "hello"}],
    })
    assert not result.valid
    assert any("unknown character id" in error for error in result.errors)
    assert any("next" in error for error in result.errors)


def test_health_requires_session_token() -> None:
    with TestClient(app) as client:
        assert client.get("/api/v1/health").status_code == 401
        response = client.get("/api/v1/health", headers={"X-PixelRPG-Token": settings.session_token})
        assert response.status_code == 200
        assert response.json()["service"] == "ok"


def test_websocket_streams_validated_draft() -> None:
    with TestClient(app) as client:
        with client.websocket_connect(f"/api/v1/assist/stream?token={settings.session_token}") as websocket:
            websocket.send_json({
                "task": "對話草稿", "prompt": "替米拉寫一句對話", "artifact_type": "dialogues",
                "mode": "fast", "max_context_tokens": 4096,
            })
            event_types: list[str] = []
            draft = None
            for _ in range(100):
                event = websocket.receive_json()
                event_types.append(event["type"])
                if event["type"] == "draft":
                    draft = event["content"]
                if event["type"] in {"done", "error"}:
                    break
            assert "draft" in event_types
            assert "done" in event_types
            assert draft["schema_version"] == 1


def test_assistant_repair_receives_previous_json_and_fixes_dangling_route() -> None:
    class EmptyIndex:
        async def search(self, _query, _ollama):
            return []

    class RepairingOllama:
        def __init__(self) -> None:
            self.prompts: list[str] = []

        async def stream_chat(self, _model, _system, prompt, _schema, _images):
            self.prompts.append(prompt)
            draft = {
                "schema_version": 1,
                "id": "repair_test",
                "title": "修復測試",
                "start_node": "start",
                "characters": ["mira"],
                "nodes": [
                    {"id": "start", "type": "line", "speaker": "mira", "text": "請進。"},
                    {"id": "end", "type": "end"},
                ],
            }
            if len(self.prompts) > 1:
                draft["nodes"][0]["next"] = "end"
            yield json.dumps(draft, ensure_ascii=False)

    async def exercise() -> tuple[list[dict], RepairingOllama]:
        ollama = RepairingOllama()
        request = AssistRequest(
            task="修復對話",
            prompt="替米拉寫一句話後結束。",
            artifact_type="dialogues",
            mode="fast",
        )
        events = [event async for event in assist_events(request, EmptyIndex(), ollama)]
        return events, ollama

    events, ollama = asyncio.run(exercise())
    assert [event["type"] for event in events].count("warning") == 1
    assert events[-1]["type"] == "done"
    assert any(event["type"] == "draft" for event in events)
    assert len(ollama.prompts) == 2
    assert "上一版 JSON" in ollama.prompts[1]
    assert '"id": "repair_test"' in ollama.prompts[1]
    assert "next: must reference an existing node" in ollama.prompts[1]
