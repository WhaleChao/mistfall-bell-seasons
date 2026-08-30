from __future__ import annotations

import asyncio
from dataclasses import asdict

import uvicorn
from fastapi import Depends, FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.trustedhost import TrustedHostMiddleware

from .assistant import assist_events
from .indexer import KnowledgeIndex
from .models import (
    AssistRequest, HealthResult, ImageConfirmRequest, ImageDescribeRequest,
    IndexRebuildRequest, ValidateRequest,
)
from .ollama_client import OllamaClient
from .security import require_token, require_websocket_token
from .settings import settings
from .validator import validate_draft


app = FastAPI(
    title="PixelRPG Creator Service",
    version="0.1.0",
    docs_url=None,
    redoc_url=None,
    openapi_url=None,
)
app.add_middleware(TrustedHostMiddleware, allowed_hosts=["127.0.0.1", "localhost", "testserver"])
index = KnowledgeIndex()
ollama = OllamaClient()


@app.get("/api/v1/health", dependencies=[Depends(require_token)])
async def health() -> HealthResult:
    warnings: list[str] = []
    models: list[dict] = []
    running: list[dict] = []
    try:
        models = await ollama.models()
        running = await ollama.running_models()
    except Exception as exc:
        warnings.append(f"Ollama unavailable: {exc}")
    gpu = None
    if running:
        details = running[0].get("details", {})
        gpu = str(details.get("quantization_level") or running[0].get("processor") or "active")
    return HealthResult(
        project_root=str(settings.project_root), ollama=bool(models), gpu=gpu,
        index_chunks=index.chunk_count(), models=[str(model.get("name", "")) for model in models],
        warnings=warnings,
    )


@app.get("/api/v1/models", dependencies=[Depends(require_token)])
async def models() -> dict:
    available = await ollama.models()
    by_name = {str(model.get("name", "")): model for model in available}
    return {
        "modes": [
            {"id": "quality", "model": settings.quality_model, "vram_estimate_gb": 8.5, "available": settings.quality_model in by_name, "digest": by_name.get(settings.quality_model, {}).get("digest")},
            {"id": "fast", "model": settings.fast_model, "vram_estimate_gb": 5.0, "available": settings.fast_model in by_name, "digest": by_name.get(settings.fast_model, {}).get("digest")},
        ],
        "embedding": {"model": settings.embedding_model, "available": settings.embedding_model in by_name, "digest": by_name.get(settings.embedding_model, {}).get("digest")},
    }


@app.post("/api/v1/index/rebuild", dependencies=[Depends(require_token)])
async def rebuild_index(request: IndexRebuildRequest) -> dict:
    result = await index.rebuild(ollama, request.paths, request.force)
    return asdict(result)


@app.post("/api/v1/validate", dependencies=[Depends(require_token)])
async def validate(request: ValidateRequest) -> dict:
    return validate_draft(request.artifact_type, request.draft).model_dump()


@app.post("/api/v1/images/describe", dependencies=[Depends(require_token)])
async def describe_image(request: ImageDescribeRequest) -> dict:
    path = settings.resolve_project_path(request.path)
    if path.suffix.lower() not in {".png", ".jpg", ".jpeg", ".webp"} or not path.is_file():
        return {"valid": False, "error": "Path is not a supported project image"}
    model = settings.quality_model if request.mode == "quality" else settings.fast_model
    output_schema = {
        "type": "object",
        "required": ["description", "tags"],
        "properties": {
            "description": {"type": "string"},
            "tags": {"type": "array", "items": {"type": "string"}},
        },
        "additionalProperties": False,
    }
    chunks: list[str] = []
    try:
        async for token in ollama.stream_chat(
            model, "你是像素 RPG 素材分析員。只描述看得到的內容；不確定處必須明說。",
            request.prompt, output_schema, [path],
        ):
            chunks.append(token)
        import json

        draft = json.loads("".join(chunks))
        return {"valid": True, "draft": draft, "confirmed": False}
    except Exception as exc:
        return {"valid": False, "error": str(exc)}


@app.post("/api/v1/images/confirm", dependencies=[Depends(require_token)])
async def confirm_image(request: ImageConfirmRequest) -> dict:
    path = settings.resolve_project_path(request.path)
    if not path.is_file():
        return {"confirmed": False, "error": "Image does not exist"}
    relative = path.relative_to(settings.project_root).as_posix()
    chunks = await index.confirm_image_description(relative, request.description, ollama)
    return {"confirmed": True, "path": relative, "indexed_chunks": chunks}


@app.websocket("/api/v1/assist/stream")
async def assist(websocket: WebSocket, token: str | None = None) -> None:
    require_websocket_token(token)
    await websocket.accept()
    try:
        while True:
            payload = await websocket.receive_json()
            if payload.get("cancel"):
                await websocket.send_json({"type": "done", "cancelled": True})
                continue
            try:
                request = AssistRequest.model_validate(payload)
            except Exception as exc:
                await websocket.send_json({"type": "error", "message": f"要求格式錯誤：{exc}"})
                continue

            async def pump() -> None:
                async for event in assist_events(request, index, ollama):
                    await websocket.send_json(event)

            generation = asyncio.create_task(pump())
            control = asyncio.create_task(websocket.receive_json())
            done, _pending = await asyncio.wait({generation, control}, return_when=asyncio.FIRST_COMPLETED)
            if control in done:
                control_payload = control.result()
                if control_payload.get("cancel"):
                    generation.cancel()
                    await asyncio.gather(generation, return_exceptions=True)
                    await websocket.send_json({"type": "done", "cancelled": True})
                else:
                    generation.cancel()
                    await asyncio.gather(generation, return_exceptions=True)
                    await websocket.send_json({"type": "warning", "message": "上一項生成已被新要求取代。"})
            else:
                control.cancel()
                await asyncio.gather(control, return_exceptions=True)
                await generation
    except WebSocketDisconnect:
        return


def run() -> None:
    print(f"PixelRPG Creator Service: http://{settings.host}:{settings.port}")
    print(f"Registered project root: {settings.project_root}")
    if "PIXELRPG_SESSION_TOKEN" not in __import__("os").environ:
        print(f"Generated session token: {settings.session_token}")
    uvicorn.run(app, host=settings.host, port=settings.port, access_log=False)


if __name__ == "__main__":
    run()
