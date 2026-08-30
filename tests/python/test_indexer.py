from __future__ import annotations

import asyncio
import os

os.environ["PIXELRPG_MOCK_AI"] = "1"

from app.indexer import KnowledgeIndex  # noqa: E402
from app.ollama_client import OllamaClient  # noqa: E402


def test_incremental_index_and_hybrid_search(tmp_path) -> None:
    asyncio.run(_exercise_index(tmp_path))


async def _exercise_index(tmp_path) -> None:
    index = KnowledgeIndex(tmp_path / "knowledge.db")
    ollama = OllamaClient()
    first = await index.rebuild(ollama, ["knowledge/world_bible.md"], force=True)
    assert first.indexed_files == 1
    assert first.chunks >= 1
    second = await index.rebuild(ollama, ["knowledge/world_bible.md"], force=False)
    assert second.unchanged_files == 1
    results = await index.search("替米拉寫一段請求玩家調查鐘塔的對話", ollama)
    assert results
    assert results[0].path == "knowledge/world_bible.md"
