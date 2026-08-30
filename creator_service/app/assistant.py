from __future__ import annotations

import json
import re
from collections.abc import AsyncIterator
from pathlib import Path
from typing import Any

from .indexer import KnowledgeIndex
from .models import AssistRequest
from .ollama_client import OllamaClient
from .settings import settings
from .validator import reference_catalog, schema_for, validate_draft


SYSTEM_PROMPT = """你是 PixelRPG Studio 的本機內容助理。使用繁體中文，並只根據提供的來源與使用者要求工作。
不要聲稱不存在於來源的設定是既定事實。需要推測時標示為草稿。當要求結構化內容時，只輸出符合 JSON Schema 的 JSON 物件，
不可使用 Markdown code fence。所有 ID 必須是小寫英數字與底線，schema_version 固定為 1。"""


async def assist_events(
    request: AssistRequest,
    index: KnowledgeIndex,
    ollama: OllamaClient,
) -> AsyncIterator[dict[str, Any]]:
    sources = await index.search(request.prompt, ollama)
    for source in sources:
        yield {"type": "source", **source.model_dump()}
    image_paths: list[Path] = []
    for raw_path in request.image_paths:
        image_paths.append(settings.resolve_project_path(raw_path))
    schema = schema_for(request.artifact_type)
    source_context = "\n\n".join(
        f"[來源 {source.source_id} | {source.path} | {source.heading}]\n{source.excerpt}"
        for source in sources
    ) or "（索引沒有找到相關來源；不要自行補成既定世界觀。）"
    prompt = (
        f"任務：{request.task}\n內容類型：{request.artifact_type}\n使用者要求：{request.prompt}\n\n"
        f"可引用來源：\n{source_context}\n\n"
    )
    prompt += "專案既有穩定 ID（引用時只能使用這些值）：\n" + json.dumps(reference_catalog(), ensure_ascii=False) + "\n\n"
    if schema:
        prompt += "必須符合此 JSON Schema：\n" + json.dumps(schema, ensure_ascii=False)
        if request.artifact_type == "dialogues":
            prompt += (
                "\n\nDialogueGraph 引用規則：每個 line、condition、action 節點都必須有 next，"
                "且 next 必須等於 nodes 陣列中某個 id；choice 的每個 option.next 也必須如此。"
                "只有 end 節點不需要 next。輸出前逐一核對所有引用。"
            )
    else:
        prompt += "請以 JSON 物件回覆，至少包含 answer 與 citations（來源 ID 陣列）。"
    model = settings.quality_model if request.mode == "quality" else settings.fast_model
    last_text = ""
    last_errors: list[str] = []
    for attempt in range(3):
        generation_prompt = prompt
        if attempt:
            repair_model = settings.quality_model if attempt == 2 and model != settings.quality_model else model
            suffix = "（最終修復改用品質模型）" if repair_model != model else ""
            yield {"type": "warning", "message": f"結構驗證失敗，正在進行第 {attempt} 次自動修復{suffix}。"}
            generation_prompt += (
                "\n\n上一版輸出不合法。只修正下列錯誤，保留其他合法內容：\n- "
                + "\n- ".join(last_errors[:12])
                + "\n上一版 JSON：\n"
                + last_text[:16_000]
                + "\n請逐一核對錯誤已消失，再完整重輸出修正後的 JSON；不要解釋。"
            )
        else:
            repair_model = model
        chunks: list[str] = []
        try:
            async for token in ollama.stream_chat(repair_model, SYSTEM_PROMPT, generation_prompt, schema or "json", image_paths):
                chunks.append(token)
                yield {"type": "token", "content": token}
        except Exception as exc:
            yield {"type": "error", "message": f"Ollama 生成失敗：{exc}", "repair": "確認 Ollama 已啟動且模型已下載。"}
            return
        last_text = "".join(chunks)
        parsed = _parse_json_object(last_text)
        if parsed is None:
            last_errors = ["輸出不是有效的 JSON 物件"]
            continue
        result = validate_draft(request.artifact_type, parsed)
        if result.valid:
            yield {"type": "draft", "content": parsed, "validation": result.model_dump()}
            yield {"type": "done", "model": repair_model, "requested_model": model, "source_count": len(sources)}
            return
        last_errors = result.errors
    yield {
        "type": "error",
        "message": "草稿經兩次自動修復後仍未通過 schema 驗證。",
        "validation_errors": last_errors,
        "raw": last_text,
    }


def _parse_json_object(text: str) -> dict[str, Any] | None:
    cleaned = text.strip()
    cleaned = re.sub(r"^```(?:json)?\s*", "", cleaned, flags=re.IGNORECASE)
    cleaned = re.sub(r"\s*```$", "", cleaned)
    try:
        value = json.loads(cleaned)
        return value if isinstance(value, dict) else None
    except json.JSONDecodeError:
        start = cleaned.find("{")
        end = cleaned.rfind("}")
        if start >= 0 and end > start:
            try:
                value = json.loads(cleaned[start:end + 1])
                return value if isinstance(value, dict) else None
            except json.JSONDecodeError:
                return None
        return None
