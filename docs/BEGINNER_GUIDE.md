# 零基礎使用導覽

## 第一次開啟

1. 安裝 Godot 4.7.2 Standard（不需要 .NET 版）與 Python 3.12。
2. 在本專案上按右鍵開啟 PowerShell，執行 `launcher/Setup-PixelRPG.ps1 -WithDocuments -WithVector`。
3. 安裝 Ollama；在 PowerShell 執行 `ollama pull qwen3.5:4b` 與 `ollama pull qwen3-embedding:0.6b`。先用 4B 熟悉流程，品質足夠後再下載 9B。
4. 雙擊 `PixelRPG Studio.cmd`。Godot 上方會出現 `PixelRPG` 主畫面。

若只想先試遊戲，不需安裝 Python 或 Ollama：Windows 可雙擊 `Play Mistfall.cmd`，macOS 可雙擊 `Play Mistfall.command`；也可直接用 Godot 開啟專案後按 F5。

## 建議的第一小時

1. Windows 雙擊 `Play Mistfall.cmd`，macOS 雙擊 `Play Mistfall.command`，在標題畫面命名並選裝束。
2. 走近農地按 E，依序翻土、播種、澆水；按 T 切換時間速度，20:00 後按 C 睡到隔天，重複澆水直到成熟後收成。
3. 走近米拉、池塘與洞窟按 E，觀察情境互動；洞窟內用 J／K／L 戰鬥。雞與牛需先擴建農場後再於牧場購買。
4. 開啟 Studio 的「日曆」「農作」「節慶」頁，修改資料後以 Ctrl+Z 測試復原。
5. 到「測試」執行內容檢查，再以 `launcher/Test-PixelRPG.ps1` 跑完整回歸。

## 匯入素材

在「素材／參考庫」按「匯入檔案」。Studio 會複製原始檔到 `assets/source/`，保存 SHA-256、來源與授權。選取素材後填寫 SPDX，例如自己創作可使用 `Proprietary`，CC0 素材填 `CC0-1.0`。不確定授權時保持 `UNSPECIFIED`；系統會阻止正式 release，而不會替你猜。

文件和圖片也可作 AI 參考。文件索引只在 `.creator/knowledge.db`，不進遊戲。圖片描述是草稿；只有經 `/api/v1/images/confirm` 確認的文字才會進索引。

## 使用 AI 草稿

1. 必須用啟動器開啟，才能取得每次隨機產生的 session token。
2. 在 AI 頁按「連接本機服務」。
3. 選任務、內容類型與快速／品質模式，輸入明確要求。
4. 檢查右側引用與差異；按「驗證草稿」。
5. 只有滿意時按「套用」。任何套用都能以 Ctrl+Z 復原。

AI 沒有引用到的內容不是既定設定；將它視為提案。若顯示 Ollama 未啟動，其他 Studio 與遊戲功能仍正常。

## 下一步學習順序

先替現有農場補一項完整內容，例如「作物＋料理＋村民委託」，再擴成正式聚落、野外和季節地圖。進階擴充可從 `runtime/calendar/`、`runtime/farming/`、`runtime/social/` 與 `runtime/dungeon/` 的短小 GDScript 開始。
