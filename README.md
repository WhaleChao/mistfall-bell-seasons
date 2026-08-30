# 霧落農歌：鐘塔之季

《霧落農歌：鐘塔之季》是以 PixelRPG Studio／Godot 4.7.2 製作的繁體中文 Windows 俯視像素農場動作 RPG。v1.1.3 可完全離線單人遊玩，也能用 Godot ENet／UDP 自行開設最多 16 人的朋友伺服器；遊戲 Runtime 不包含模型、Creator Service、知識庫、遙測或廣告。本版另提供保守的 Steam Windows 商店設定與 SteamPipe 預覽工具。

![農場畫面](screenshots/commercial_farm.png)

## 遊戲內容

- 每季 30 日、一年 120 日、無限年份；快速／標準／悠閒三種日長，主線與戀愛沒有期限。
- 48 種作物、20 種魚（含 8 種異潮漁獲）、40 道料理、雞牛飼養與繁殖、10 級農場、工具升級、商店、出貨及 14 項成就。
- 12 場年度節慶，每場有五回合操作、評分、技巧獎勵與前三年不同敘事。
- 10 名主要 NPC、超過 180 段四季／天氣／節慶／好感台詞；4 名不限玩家外觀的戀愛候選、結婚與孩子成長。
- 12 章無期限三年主線；第 4 年起保留第三年節慶變體、規則式委託與無限年份經營。
- 40 層四季鐘窟、12 種一般敵人、4 名季節守護者、獨立攻擊型態、四枚封印、最終戰與無限挑戰。
- 無星異潮、100 點理智、異魚圖鑑、無期限「潮下的低語」任務，以及使用原創透明像素素材與 16 向彈幕的「克蘇魯之影・溺夢古神」。
- 可在遊戲內開設主機或用 IP 加入；另附無視窗專用伺服器。開服時可選共同農場、私人農場或私人競賽排行，以及獨立戀愛或同一 NPC 的競爭追求。
- 多人劇情依 1 人、2 人、3–4 人、5 人以上切換「獨鐘守望／雙鐘盟約／四季合奏／霧落拓荒議會」；共同、私人、競賽農場與 1／2／3／5／16 人拓撲合計以 7 服 31 客、38 個真實程序驗證版本握手、權威移動、最大容量、農場整合／隔離、四種篇章、戀愛平手／領先／唯一婚約與原子世界存檔。
- 四方向四幀玩家走路動畫、原創角色／敵人／動物圖集、季節與天候效果、程序式離線音樂與音效。
- SaveGame v4；可遷移 v1（28 日制）、v2 與 v3 存檔，保留原季節與日數。

## 下載與遊玩

[GitHub Releases 的 Windows x64 v1.1.3 壓縮檔](https://github.com/WhaleChao/mistfall-bell-seasons/releases/tag/v1.1.3)為免安裝版：解壓縮後執行 `Mistfall-Bell-Seasons.exe`。系統需求為 Windows 10/11 x64、支援 OpenGL 3.3 的顯示硬體、4 GB RAM；單人遊玩不需要網路或 AI 模型。

按 `M`／手把 Select 開啟連線介面，可自行開設主機或輸入 IP 加入；發行包亦可雙擊 `Start Dedicated Server.cmd`。完整的 UDP 轉送、世界檔與安全界線見 [伺服器指南](SERVER_GUIDE.md)。

原始專案中也可雙擊 `Play Mistfall.cmd`；若尚未安裝 Godot，先執行 `launcher/Fetch-Godot.ps1`。

| 功能 | 鍵盤 | 手把 |
|---|---|---|
| 移動 | WASD／方向鍵 | 左搖桿 |
| 互動／前往下一層 | E | Y |
| 攻擊／翻滾／技能 | J／K／L | A／B／X |
| 切換種子 | Q | RB |
| 遊戲手冊／設定 | Esc | Start |
| 連線主機／加入 | M | Select／Back |
| 節慶活動 | F | L3 |
| 洞窟／返回 | B | R3 |
| 回復藥水 | H | LB |
| 時間速度／睡覺 | T／C | 十字鍵左／右 |
| 快速存檔／讀檔 | F5／F9 | 十字鍵上／下 |

鍵盤滑鼠已完成實際遊戲視窗全流程驗收。這台測試機沒有實體手把，因此表中的 XInput 欄位只證明映射與重綁契約；Steam 商店只應標「部分控制器支援」，不可宣稱完整控制器支援或 Steam Deck Verified。

完整操作與新手流程見 [新手指南](docs/BEGINNER_GUIDE.md)。

## 驗證與建置

```powershell
.\launcher\Fetch-Godot.ps1
.\launcher\Fetch-ExportTemplates.ps1
.\launcher\Setup-PixelRPG.ps1 -WithDocuments -WithVector -WithTestTools
.\launcher\Build-CreatorService.ps1
.\launcher\Test-PixelRPG.ps1
.\launcher\Test-PackagedDocuments.ps1
.\launcher\Test-RealAI.ps1 -CreatorExecutable .\creator_service\dist\PixelRPGCreatorService.exe
.\launcher\Test-StudioUI.ps1
.\launcher\Test-RenderPerformance.ps1
.\launcher\Test-SteamCandidate.ps1
.\launcher\Run-FullAcceptance.ps1
.\launcher\Test-Multiplayer.ps1
.\launcher\Package-Release.ps1
.\launcher\Test-PublishedRelease.ps1 -Tag v1.1.3
.\launcher\Test-CodeSigningPipeline.ps1
```

發行閘門會驗證 283 筆內容、JSON Schema／引用、所有資產 SHA-256／授權、圖片／圖集／畫面規則、Save v1→v2→v3→v4、12,000 日／100 年、250 次磁碟存讀、20 敵人效能、640×360 至 2560×1440 整數縮放（含 1280×800）、PCK 邊界、正式 ZIP 與解壓後啟動。另有非 headless 的[全功能實機驗收報告](reports/full_feature_acceptance/REPORT.md)，實際開啟遊戲視窗、驅動輸入與 UI，137 項通過並保存 15 張畫面證據；圖片閘門統一檢查 42 張遊戲、Studio、解析度及宣傳畫面。[Steam 候選報告](reports/steam_candidate/REPORT.md)驗證 Big Picture 全螢幕、商店勾選契約、18 組鍵盤／XInput 映射、0 支實體手把的證據限制與 1280×800 字級。[多人連線證據](reports/multiplayer_acceptance.json)由 38 個獨立 Godot 程序完成共同、私人、競賽農場與 1／2／3／5／16 人情境（7 台專用伺服器＋31 個客戶端）的握手、移動、最大容量、農場整合／隔離、四種篇章、戀愛競爭／唯一婚約及世界保存。公開版仍會在預設離線模式驗證零網路端點。RTX 3060 的最新 1080p／20 敵人連續封裝測試約 740 FPS；正式遊玩鎖定 60 FPS，精確結果保留於效能報告。

## PixelRPG Studio 與本機 AI

雙擊 `PixelRPG Studio.cmd` 可開啟 15 頁 Godot 編輯插件；Creator Service 可在製作端連接本機 Ollama，產生帶引用、可驗證並需人工套用的草稿。Studio 已通過 [57 項實機 UI 驗收](reports/studio_ui/REPORT.md)，最終封裝服務已通過 [24 項真實 AI 驗收](reports/real_ai_packaged/REPORT.md)與 [9 種文件／OCR／sqlite-vec 離線索引](reports/packaged_documents/REPORT.md)。AI 工具與設計文件由匯出規則硬性排除，不會跟著遊戲發布。

## 授權與隱私

程式碼採 [MIT License](LICENSE)。原創生成素材的來源、SHA-256 與 `LicenseRef-OpenAI-Generated` 記錄於 `data/assets/index.json`，第三方政策見 [THIRD_PARTY.md](THIRD_PARTY.md)；Windows ZIP 另附 Godot 4.7.2 的完整授權與第三方著作權原文。遊戲不收集遙測；只有玩家主動開服或加入時才建立 ENet 連線，詳見 [PRIVACY.md](PRIVACY.md)。
