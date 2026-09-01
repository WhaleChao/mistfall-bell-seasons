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
  ├─ Runtime + approved content/assets only; no AI or knowledge files
  └─ Optional player-hosted ENet/UDP; offline until host/join is chosen
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

`scripts/validate_content.py` 是 Editor、CI、release gate 共用的資料真相。每種 artifact 有獨立 JSON Schema，所有引用使用穩定字串 ID。SaveGame v6 保存玩家、120 日曆、天氣、農場、6×4 自動化設備／網路／統計、動物、關係、婚姻、孩子、節慶、洞窟、故事、工具、經濟、成就、設定、規則式委託、深潮狀態，以及目前 MapScene、來源 portal、位置、面向、室內狀態與動物所在場景；loader 內建 v1→v2→v3→v4→v5→v6 遷移，並保留舊 28 日日期原值。

## 多人信任邊界

玩家可在同一個正式遊戲內開設監聽主機、以 IP 直連，或用 `--headless -- --server` 啟動專用伺服器。伺服器對世界動作、農場自動化、農場模式、關係競爭、劇情分支、位置快照與原子存檔具權威；客戶端只能送出白名單動作。每個世界可選共同、私人或競爭農場，以及獨立或競爭關係。連線層不提供 TLS、官方帳號、公開媒合或反作弊服務，因此定位為玩家自行管理的可信朋友／LAN 伺服器；公開網際網路需自行設定路由器 UDP 轉送與網路安全。

## 發布隔離

`export_presets.cfg` 排除 Creator Service、knowledge、schemas、tests、launcher、`assets/source`、`.creator`、`.venv` 與設計文件。正式遊戲只引用處理後的 `assets/runtime`。Windows 與 macOS Universal 2 CI 都檢查這些規則、素材授權、PCK 邊界，並在預設單人模式驗證沒有網路端點；只有玩家主動開服或加入時才啟用 ENet。模型由 Ollama 管理，從不複製到專案或遊戲 PCK。
