# 霧落農歌：鐘塔之季

《霧落農歌：鐘塔之季》是以 PixelRPG Studio／Godot 4.7.2 製作的繁體中文 Windows 單人俯視像素農場動作 RPG。v1.0.4 為可離線遊玩的商業發行候選版；遊戲 Runtime 不包含模型、Creator Service、知識庫或網路請求。

![農場畫面](screenshots/commercial_farm.png)

## 遊戲內容

- 每季 30 日、一年 120 日、無限年份；快速／標準／悠閒三種日長，主線與戀愛沒有期限。
- 48 種作物、12 種魚、40 道料理、雞牛飼養與繁殖、10 級農場、工具升級、商店、出貨及 12 項成就。
- 12 場年度節慶，每場有五回合操作、評分、技巧獎勵與前三年不同敘事。
- 10 名主要 NPC、超過 180 段四季／天氣／節慶／好感台詞；4 名不限玩家外觀的戀愛候選、結婚與孩子成長。
- 12 章無期限三年主線；第 4 年起保留第三年節慶變體、規則式委託與無限年份經營。
- 40 層四季鐘窟、12 種一般敵人、4 名季節守護者、獨立攻擊型態、四枚封印、最終戰與無限挑戰。
- 四方向四幀玩家走路動畫、原創角色／敵人／動物圖集、季節與天候效果、程序式離線音樂與音效。
- SaveGame v3；可遷移 v1（28 日制）與 v2 存檔，保留原季節與日數。

## 下載與遊玩

[GitHub Releases 的 Windows x64 v1.0.4 壓縮檔](https://github.com/WhaleChao/mistfall-bell-seasons/releases/tag/v1.0.4)為免安裝版：解壓縮後執行 `Mistfall-Bell-Seasons.exe`。系統需求為 Windows 10/11 x64、支援 OpenGL 3.3 的顯示硬體、4 GB RAM；不需要網路或 AI 模型。

原始專案中也可雙擊 `Play Mistfall.cmd`；若尚未安裝 Godot，先執行 `launcher/Fetch-Godot.ps1`。

| 功能 | 鍵盤 | 手把 |
|---|---|---|
| 移動 | WASD／方向鍵 | 左搖桿 |
| 互動／前往下一層 | E | Y |
| 攻擊／翻滾／技能 | J／K／L | A／B／X |
| 切換種子 | Q | RB |
| 遊戲手冊／設定 | Esc | Start |
| 節慶活動 | F／E | Y |
| 洞窟／返回 | B | — |
| 回復藥水 | H | — |
| 快速存檔／讀檔 | F5／F9 | 可在設定重新綁定 |

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
.\launcher\Run-FullAcceptance.ps1
.\launcher\Package-Release.ps1
.\launcher\Test-PublishedRelease.ps1 -Tag v1.0.4
.\launcher\Test-CodeSigningPipeline.ps1
```

發行閘門會驗證 269 筆內容、JSON Schema／引用、所有資產 SHA-256／授權、654 項圖片／圖集／畫面規則、Save v1→v2→v3、12,000 日／100 年、250 次磁碟存讀、20 敵人效能、640×360 至 2560×1440 整數縮放、離線 PCK 邊界、正式 ZIP 與解壓後啟動。另有非 headless 的[全功能實機驗收報告](reports/full_feature_acceptance/REPORT.md)，實際開啟遊戲視窗、驅動輸入與 UI，119 項通過並保存 12 張畫面證據；圖片閘門另自動檢查共 38 張遊戲、Studio、解析度及宣傳畫面。公開版另由[全新 Windows 11 VM](reports/CLEAN_WINDOWS_RELEASE.md)重新下載與啟動，執行期 TCP／UDP 觀測為零端點。RTX 3060 的 1080p／20 敵人連續封裝測試皆超過 800 FPS 容量；正式遊玩鎖定 60 FPS，精確結果保留於效能報告。

## PixelRPG Studio 與本機 AI

雙擊 `PixelRPG Studio.cmd` 可開啟 15 頁 Godot 編輯插件；Creator Service 可在製作端連接本機 Ollama，產生帶引用、可驗證並需人工套用的草稿。Studio 已通過 [57 項實機 UI 驗收](reports/studio_ui/REPORT.md)，最終封裝服務已通過 [24 項真實 AI 驗收](reports/real_ai_packaged/REPORT.md)與 [9 種文件／OCR／sqlite-vec 離線索引](reports/packaged_documents/REPORT.md)。AI 工具與設計文件由匯出規則硬性排除，不會跟著遊戲發布。

## 授權與隱私

程式碼採 [MIT License](LICENSE)。原創生成素材的來源、SHA-256 與 `LicenseRef-OpenAI-Generated` 記錄於 `data/assets/index.json`，第三方政策見 [THIRD_PARTY.md](THIRD_PARTY.md)；Windows ZIP 另附 Godot 4.7.2 的完整授權與第三方著作權原文。遊戲不收集遙測、不連網，詳見 [PRIVACY.md](PRIVACY.md)。
