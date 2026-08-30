from __future__ import annotations

import argparse
import asyncio
import json
import re
import time
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

import httpx
from websockets.asyncio.client import connect


@dataclass(slots=True)
class Check:
    category: str
    name: str
    passed: bool
    details: str = ""


class RealAITest:
    def __init__(self, base_url: str, token: str, report_directory: Path) -> None:
        self.base_url = base_url.rstrip("/")
        self.ollama_url = "http://127.0.0.1:11434"
        self.token = token
        self.report_directory = report_directory
        self.project_root = Path(__file__).resolve().parents[1]
        self.checks: list[Check] = []
        self.metrics: dict[str, Any] = {}
        self.headers = {"X-PixelRPG-Token": token}

    def check(self, condition: bool, category: str, name: str, details: Any = "") -> None:
        if isinstance(details, dict) and "project_root" in details:
            details = {**details, "project_root": "<isolated-project-root>"}
        safe_details = str(details).replace(str(self.project_root), "<project>")
        self.checks.append(Check(category, name, bool(condition), safe_details))

    async def run(self) -> int:
        timeout = httpx.Timeout(360.0, connect=10.0)
        async with httpx.AsyncClient(timeout=timeout) as client:
            unauthorized = await client.get(f"{self.base_url}/api/v1/health")
            self.check(unauthorized.status_code == 401, "安全", "缺少工作階段 token 會被拒絕", unauthorized.status_code)

            health = (await client.get(f"{self.base_url}/api/v1/health", headers=self.headers)).json()
            self.check(health.get("service") == "ok", "服務", "Creator Service 健康檢查", health)
            self.check(health.get("ollama") is True and not health.get("warnings"), "服務", "Ollama 可用且無警告", health.get("warnings"))

            models = (await client.get(f"{self.base_url}/api/v1/models", headers=self.headers)).json()
            self.check(all(mode.get("available") for mode in models.get("modes", [])), "模型", "4B 與 9B 模式均可用", models)
            self.check(models.get("embedding", {}).get("available") is True, "模型", "Qwen3 Embedding 可用", models.get("embedding"))
            self.metrics["models"] = models

            # A previous indexing or assist session can leave another runner in
            # VRAM for five minutes. Evict every PixelRPG model first so the
            # cold-start measurement is isolated instead of timing GPU memory
            # pressure caused by an unrelated embedding runner.
            for installed_model in ("qwen3.5:4b", "qwen3.5:9b", "qwen3-embedding:0.6b"):
                await self._unload_model(client, installed_model)

            for model, label, cold_limit, warm_limit in (
                ("qwen3.5:4b", "fast", 30.0, 5.0),
                ("qwen3.5:9b", "quality", 30.0, 10.0),
            ):
                await self._unload_model(client, model)
                cold = await self._measure_model(client, model)
                warm = await self._measure_model(client, model)
                self.metrics[f"{label}_cold"] = cold
                self.metrics[f"{label}_warm"] = warm
                self.check(cold["first_token_seconds"] <= cold_limit, "效能", f"{label} 冷啟動首 token ≤ {cold_limit:g}s", cold)
                self.check(warm["first_token_seconds"] <= warm_limit, "效能", f"{label} 暖機首 token ≤ {warm_limit:g}s", warm)
                self.check(warm["tokens_per_second"] >= 8.0, "效能", f"{label} 暖機持續生成 ≥ 8 tokens/s", warm)

            rebuild = (await client.post(
                f"{self.base_url}/api/v1/index/rebuild",
                headers=self.headers,
                json={"paths": ["knowledge/world_bible.md"], "force": True},
            )).json()
            self.check(rebuild.get("indexed_files") == 1 and rebuild.get("chunks", 0) >= 1, "索引", "真實 embedding 建立文件索引", rebuild)
            self.check(not rebuild.get("warnings"), "索引", "文件索引沒有降級警告", rebuild.get("warnings"))
            incremental = (await client.post(
                f"{self.base_url}/api/v1/index/rebuild",
                headers=self.headers,
                json={"paths": ["knowledge/world_bible.md"], "force": False},
            )).json()
            self.check(incremental.get("unchanged_files") == 1 and incremental.get("indexed_files") == 0, "索引", "相同雜湊採增量略過", incremental)

            invalid = (await client.post(
                f"{self.base_url}/api/v1/validate",
                headers=self.headers,
                json={"artifact_type": "items", "draft": {"schema_version": 1, "id": "Bad ID"}},
            )).json()
            self.check(invalid.get("valid") is False and invalid.get("errors"), "驗證", "無效草稿只回報錯誤", invalid)

            fast_assist = await self._assist(
                mode="fast",
                artifact_type="dialogues",
                task="繁體中文對話草稿",
                prompt="根據世界觀替米拉寫兩個節點的短對話；只使用既有角色 hero 與 mira，最後必須有 end 節點。",
            )
            self.metrics["fast_assist"] = fast_assist
            self.check(fast_assist["done"] and fast_assist["draft_valid"], "生成", "4B WebSocket 串流產生合法 DialogueGraph", fast_assist)
            self.check(fast_assist["source_count"] >= 1, "RAG", "草稿先回傳引用來源", fast_assist["source_count"])
            self.check(bool(re.search(r"[\u4e00-\u9fff]", fast_assist.get("draft_text", ""))), "生成", "草稿包含繁體中文內容", "")

            quality_assist = await self._assist(
                mode="quality",
                artifact_type="answer",
                task="世界觀問答",
                prompt="只根據來源，用繁體中文簡短回答米拉與鐘塔的關係，JSON 必須包含 answer 與 citations。",
            )
            self.metrics["quality_assist"] = quality_assist
            self.check(quality_assist["done"] and quality_assist["draft_valid"], "生成", "9B WebSocket 串流完成世界觀問答", quality_assist)
            self.check(quality_assist["source_count"] >= 1, "RAG", "品質模式保留來源引用", quality_assist["source_count"])

            image_response = await client.post(
                f"{self.base_url}/api/v1/images/describe",
                headers=self.headers,
                json={
                    "path": "assets/runtime/backgrounds/mistfall_farm_commercial.png",
                    "prompt": "用繁體中文描述可見的農場、建築、池塘與洞窟入口；不得猜測圖片外內容。",
                    "mode": "fast",
                },
            )
            image_result = image_response.json()
            self.metrics["image_description"] = image_result
            image_draft = image_result.get("draft", {})
            self.check(image_result.get("valid") is True and image_draft.get("description") and image_draft.get("tags"), "圖片", "4B 真實圖片理解回傳結構化草稿", image_result)
            self.check(image_result.get("confirmed") is False, "圖片", "圖片描述預設不自動確認", image_result.get("confirmed"))
            if image_draft.get("description"):
                confirmation = (await client.post(
                    f"{self.base_url}/api/v1/images/confirm",
                    headers=self.headers,
                    json={"path": "assets/runtime/backgrounds/mistfall_farm_commercial.png", "description": image_draft["description"]},
                )).json()
                self.check(confirmation.get("confirmed") is True and confirmation.get("indexed_chunks", 0) >= 1, "圖片", "人工確認後才寫入圖片描述索引", confirmation)

            cancel = await self._cancel_generation()
            self.check(cancel, "串流", "WebSocket 生成可取消", cancel)

        return self._write_report()

    async def _unload_model(self, client: httpx.AsyncClient, model: str) -> None:
        await client.post(f"{self.ollama_url}/api/generate", json={"model": model, "keep_alive": 0})

    async def _measure_model(self, client: httpx.AsyncClient, model: str) -> dict[str, Any]:
        start = time.perf_counter()
        first_token_at: float | None = None
        final: dict[str, Any] = {}
        content_parts: list[str] = []
        payload = {
            "model": model,
            "messages": [{"role": "user", "content": "用繁體中文寫一段約八十字的原創農場晨景，只描述景色。"}],
            "stream": True,
            "think": False,
            "keep_alive": "5m",
            "options": {"num_ctx": 16000, "num_predict": 128, "temperature": 0.0},
        }
        async with client.stream("POST", f"{self.ollama_url}/api/chat", json=payload) as response:
            response.raise_for_status()
            async for line in response.aiter_lines():
                if not line:
                    continue
                packet = json.loads(line)
                content = str(packet.get("message", {}).get("content", ""))
                if content:
                    if first_token_at is None:
                        first_token_at = time.perf_counter()
                    content_parts.append(content)
                if packet.get("done"):
                    final = packet
                    break
        elapsed = time.perf_counter() - start
        eval_count = int(final.get("eval_count", 0))
        eval_duration = int(final.get("eval_duration", 0))
        return {
            "model": model,
            "first_token_seconds": round((first_token_at or time.perf_counter()) - start, 3),
            "elapsed_seconds": round(elapsed, 3),
            "eval_count": eval_count,
            "tokens_per_second": round(eval_count / (eval_duration / 1_000_000_000), 2) if eval_duration else 0.0,
            "load_seconds": round(int(final.get("load_duration", 0)) / 1_000_000_000, 3),
            "response_characters": len("".join(content_parts)),
        }

    async def _assist(self, **payload: Any) -> dict[str, Any]:
        url = self.base_url.replace("http://", "ws://") + f"/api/v1/assist/stream?token={self.token}"
        event_types: list[str] = []
        source_count = 0
        token_parts: list[str] = []
        draft: dict[str, Any] | None = None
        done = False
        errors: list[Any] = []
        first_token: float | None = None
        start = time.perf_counter()
        async with connect(url, open_timeout=10, close_timeout=10, max_size=8 * 1024 * 1024) as websocket:
            await websocket.send(json.dumps({**payload, "max_context_tokens": 16000, "image_paths": []}, ensure_ascii=False))
            for _ in range(2000):
                raw = await asyncio.wait_for(websocket.recv(), timeout=360)
                event = json.loads(raw)
                event_type = str(event.get("type", ""))
                event_types.append(event_type)
                if event_type == "source":
                    source_count += 1
                elif event_type == "token":
                    if first_token is None:
                        first_token = time.perf_counter() - start
                    token_parts.append(str(event.get("content", "")))
                elif event_type == "draft":
                    draft = event.get("content")
                elif event_type == "error":
                    errors.append(event)
                    break
                elif event_type == "done":
                    done = True
                    break
        return {
            "done": done,
            "draft_valid": isinstance(draft, dict),
            "source_count": source_count,
            "first_token_seconds": round(first_token or 0.0, 3),
            "event_types": sorted(set(event_types)),
            "warnings": event_types.count("warning"),
            "errors": errors,
            "draft_text": json.dumps(draft, ensure_ascii=False) if draft else "",
            "stream_characters": len("".join(token_parts)),
        }

    async def _cancel_generation(self) -> bool:
        url = self.base_url.replace("http://", "ws://") + f"/api/v1/assist/stream?token={self.token}"
        payload = {
            "task": "取消測試",
            "prompt": "請產生很長的繁體中文世界觀 JSON 回覆。",
            "artifact_type": "answer",
            "mode": "quality",
            "max_context_tokens": 16000,
            "image_paths": [],
        }
        async with connect(url, open_timeout=10, close_timeout=10) as websocket:
            await websocket.send(json.dumps(payload, ensure_ascii=False))
            # Cancellation must work while the model is still loading or
            # searching, not only after the first generated token arrives.
            await websocket.send(json.dumps({"cancel": True}))
            for _ in range(100):
                event = json.loads(await asyncio.wait_for(websocket.recv(), timeout=15))
                if event.get("type") == "done":
                    return event.get("cancelled") is True
                if event.get("type") == "error":
                    return False
        return False

    def _write_report(self) -> int:
        self.report_directory.mkdir(parents=True, exist_ok=True)
        failures = [check for check in self.checks if not check.passed]
        report = {
            "passed": not failures,
            "checks": [asdict(check) for check in self.checks],
            "passed_checks": len(self.checks) - len(failures),
            "failed_checks": len(failures),
            "metrics": self.metrics,
        }
        (self.report_directory / "report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
        rows = [
            "# PixelRPG 真實本機 AI 驗收",
            "",
            f"結果：**{'PASS' if not failures else 'FAIL'}**　｜　{len(self.checks) - len(failures)} 通過／{len(failures)} 失敗",
            "",
            "本測試不使用 `PIXELRPG_MOCK_AI`；Creator Service 綁定 127.0.0.1，透過真實 Ollama、HTTP 與 WebSocket 驗證模型、索引、RAG、結構化草稿、圖片理解及取消。",
            "",
            "| 分類 | 項目 | 結果 | 細節 |",
            "|---|---|---:|---|",
        ]
        for check in self.checks:
            details = check.details.replace("|", "\\|").replace("\n", " ")[:500]
            rows.append(f"| {check.category} | {check.name} | {'通過' if check.passed else '失敗'} | {details} |")
        rows.extend(["", "## 效能數據", "", "```json", json.dumps(self.metrics, ensure_ascii=False, indent=2), "```", ""])
        (self.report_directory / "REPORT.md").write_text("\n".join(rows), encoding="utf-8")
        print(f"PixelRPG real AI gate: {'PASS' if not failures else 'FAIL'} ({len(self.checks) - len(failures)}/{len(self.checks)})")
        for failure in failures:
            message = f"FAIL [{failure.category}] {failure.name}: {failure.details}"
            encoding = getattr(__import__("sys").stdout, "encoding", None) or "utf-8"
            print(message.encode(encoding, errors="replace").decode(encoding))
        return 0 if not failures else 1


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", required=True)
    parser.add_argument("--token", required=True)
    parser.add_argument("--report-directory", type=Path, required=True)
    args = parser.parse_args()
    return asyncio.run(RealAITest(args.base_url, args.token, args.report_directory).run())


if __name__ == "__main__":
    raise SystemExit(main())
