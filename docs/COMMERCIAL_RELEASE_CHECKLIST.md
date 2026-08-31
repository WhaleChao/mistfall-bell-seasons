# v1.2.0 Windows／macOS 技術商業發行檢查表

Steam 僅作輸入、Big Picture、解析度與商店宣稱的品質基準；本版本不會上傳 Steam。

## 自動化門檻

- [x] 297 筆內容通過 JSON Schema、穩定 ID、三年主線完整性與跨檔引用驗證。
- [x] 14 個發行圖片／圖示逐檔存在、授權非空且 SHA-256 完全相符；13 張 Runtime 圖片另通過解碼、真 alpha、灰白光暈清除、亮色內容保留、原稿雜湊、圖集邊界及 47 張實機證據檢查，共 794 項。
- [x] 16 個 Python 測試通過；Godot smoke 與 600 幀／20 敵人模擬通過。
- [x] 四季 30 日與 12,000 日／100 年模擬無漂移；1,200 場節慶與第 4 年後委託持續生成。
- [x] 250 次磁碟存讀、主檔截斷備份復原、暫存檔復原與未知 schema 拒絕通過。
- [x] SaveGame v1、v2、v3、v4 可逐版遷移至 v5。
- [x] Runtime 原始碼無 HTTP／WebSocket／Ollama／模型參照；AI、索引、測試與設計來源不進入匯出。單人預設不開網路；多人只使用玩家主動開啟的 ENet／UDP。
- [x] 共同、私人、競賽農場及 1／2／3／5／16 人劇情拓撲以 7 台專用伺服器＋31 個客戶端實連，通過版本握手、權威移動、16 人最大容量、自動化設備整合／隔離／持久化、四種篇章、戀愛平手／領先／唯一婚約與原子世界存檔。
- [x] 10 台設備形成單一鐘能網，連續 12,000 日完成播種、澆水、收割、餵食與加工；400 次月存檔、12,000 個週期、0 次停機。
- [x] RTX 3060、1920×1080、20 敵人實測遠高於 60 FPS 容量。
- [x] Windows x64 release export、PCK 邊界、可執行檔啟動、正式 ZIP 精確檔案清單、解壓後啟動與 SHA-256 通過。
- [x] Windows 上交叉匯出的 macOS ZIP 為 Universal 2（x86_64＋arm64）、bundle ID／可執行權限／PCK 邊界均通過。
- [x] GitHub macOS runner 上完成 Universal 2、ad-hoc 簽章、實際啟動、零網路端點與授權封裝；最終 tag workflow `33316079744` 全部成功，ZIP 下載後 SHA-256 與本機複驗亦通過。
- [x] v1.2.0 發布後由全新 Windows／macOS runner 從公開 Release 重新下載、核對 SHA-256、解壓、啟動並觀測零網路端點；workflow `33316678467` 全部成功，Windows 25 次、macOS 200 次網路取樣均為 0 端點。
- [x] 640×360、1280×720、1280×800、1920×1080、2560×1440 實際 Windows 視窗、GPU 內容與 1×–4× 整數縮放通過；1280×800 為 1280×720 內容加上下各 40px 留邊。
- [x] Steam 品質基準 51/51：Big Picture 全螢幕、兩個啟動項、功能勾選契約、18 組鍵盤／XInput 映射、0 支手把的證據限制及 1280×800 最小 30px 有效字級通過；未上傳 Steam。
- [x] v1.2.0 正式 EXE 的 `SteamTenfoot=1` 視窗覆蓋與正常退出通過；視窗 1920×1082，覆蓋 1920×1080 螢幕。
- [x] 完整 Creator Service 環境 138 個依賴的已知漏洞掃描為 0，16 個 Python 測試通過；Godot 4.7.2 授權與完整第三方著作權原文以固定雜湊納入 ZIP。
- [x] 最終 Creator Service EXE 以真實 Ollama／Qwen 通過 24/24，並以 Docling、RapidOCR、sqlite-vec 通過 9/9 文件格式與離線增量索引。
- [x] Godot EditorPlugin 通過 57/57 實機 UI 驗收與 16 張互異畫面，涵蓋 15 頁、UndoRedo、節點圖、引用、diff 與套用前驗證。
- [x] Godot CLI 閘門除 exit code 外亦拒絕腳本解析、編譯、資源載入及一般 `ERROR` 日誌；Studio 僅隔離成功標記後三種已知 Editor 關閉診斷。
- [x] 最終發行資料夾與 ZIP 經 Windows Defender 定義 1.457.393.0 掃描，偵測 0 項威脅。
- [x] v1.2.0 公開 Release 已在全新 Windows／macOS runner 重新下載、驗證、解壓及啟動，並完成零網路端點觀測。
- [x] PFX Authenticode 管線以公開 EXE 隔離複本完成，且正式 EXE 原雜湊不變。
- [x] Apple M4／OpenGL Metal 的非 headless Godot 視窗完成 157 項全功能實機驗收，並保存 20 張畫面證據。

## 人工檢查

- [x] 標題、農場、村莊、洞窟、手冊、對話與節慶畫面已逐張檢視。
- [x] 鍵盤主流程可達農作、社交、節慶、商店與洞窟。
- [x] 玩家移動使用四方向四幀動畫；敵人與動物使用循環動作。
- [x] 遊戲內自行開服、IP 加入與專用伺服器 UI／命令列已可視，並納入 38 程序多人驗證。
- [x] 遊戲暫停時，對話、商店、節慶與手冊不推進時間。
- [x] 缺少授權資訊的素材會阻擋發行。

## 發布資訊

- 版本：1.2.0
- 平台：Windows x64 portable、macOS Universal 2 ZIP
- 語系：繁體中文
- 簽章：Windows 未簽章；macOS ad-hoc 簽章但未 notarize；提供 SHA-256 供核對
- Runtime 網路：預設離線；玩家主動多人模式使用 Godot ENet／UDP，無遙測、官方帳號或媒合服務
- Steam／手把界線：目前不上傳 Steam；若未來建立商店頁，只能標部分控制器支援，不可宣稱完整控制器支援或 Deck Verified
- 外部未結案：受信任的 Windows Authenticode、Apple Developer ID／notarization、實體手把／Deck、正式法律意見。Steam 帳號與 Valve review 不是本次發布範圍
