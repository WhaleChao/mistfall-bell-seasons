# 架構與信任邊界

## 模組

```text
PixelRPG Studio (Godot EditorPlugin)
  ├─ data/*.json ── schema v1 ──> Game Runtime
  ├─ UndoRedo <──── validated AI draft
  └─ WebSocket localhost + token
                    │
Creator Service (Python, authoring only)
  ├─ Docling/plain extractors
  ├─ SQLite FTS5 + sqlite-vec / cosine fallback
  ├─ Ollama chat + embeddings
  └─ schema validation; never edits content files

Exported Game
  └─ Runtime + approved content/assets only; no AI or knowledge files
```

Godot 是引擎與地圖編輯底座。Studio 是主畫面 `EditorPlugin`，沒有 fork Godot。Runtime 只依賴 GDScript 與穩定資料契約；Dialogue Manager、QuestSystem、GLoot 全部經 adapter 接入，未安裝時用內建 fallback。

## Creator Service 安全規則

- uvicorn 固定 bind `127.0.0.1`，TrustedHost 只接受 localhost。
- HTTP 需要 `X-PixelRPG-Token` 或 query token；WebSocket 需要 session token。
- token 由啟動器每次隨機產生，不保存到專案。
- 所有使用者傳入路徑先 `resolve()`，再確認位於註冊的 project root。
- 服務只把索引寫入 `.creator/`；內容草稿只回傳給 Studio。
- Studio 的「套用」先驗證，再用 Godot UndoRedo 進行原子寫入。

## 索引與生成

文字依 Markdown 標題分段，目標約 400–800 tokens。`sources` 保存來源 SHA-256，未變更檔案不重建。搜尋以 FTS5 bm25 與 embedding cosine／sqlite-vec 結果做 reciprocal-rank 融合。每個生成事件先送 `source`，再串流 `token`；合法 JSON 送 `draft` 與 `done`。

結構化輸出失敗時最多修復兩次。第三次仍不合法只送 `error`，不產生檔案。圖片可直接送 Qwen3.5 作草稿描述；確認 API 才把描述文字加入索引。

## 內容寫入與遷移

`scripts/validate_content.py` 是 Editor、CI、release gate 共用的資料真相。每種 artifact 有獨立 JSON Schema，所有引用使用穩定字串 ID。SaveGame v3 保存玩家、120 日曆、天氣、農場、動物、關係、婚姻、孩子、節慶、洞窟、故事、工具、經濟、成就、設定與規則式委託；loader 內建 v1→v2→v3 遷移，並保留舊 28 日日期原值。

## 發布隔離

`export_presets.cfg` 排除 Creator Service、knowledge、schemas、tests、launcher、`assets/source`、`.creator`、`.venv` 與設計文件。正式遊戲只引用處理後的 `assets/runtime`。CI 的 release 驗證會檢查這些規則及素材授權。模型由 Ollama 管理，從不複製到專案或遊戲 PCK。
