# Steam Windows 發行設定與檢查表

本檔是 Steamworks 後台的保守填寫契約，不是 Valve 核准或 Steam Deck 認證。實際勾選值以 `store_configuration.json` 為準。

## 可立即宣稱

- Windows 10/11 x64、繁體中文介面與字幕。
- 單人、區域網路合作、IP 直連線上合作，最多 16 人。
- 玩家自行開設 listen server，亦可用同一個 EXE 開專用伺服器。
- 鍵盤滑鼠完整支援；手把欄位最多勾選「部分控制器支援」。
- 1280×800、1280×720、1920×1080 等畫面均維持 640×360 基準的整數縮放。

## 不可勾選或宣稱

- 不勾「完整控制器支援」：目前沒有實體手把端到端證據，也沒有依裝置切換的按鍵圖示或文字輸入螢幕鍵盤。
- 不宣稱 Steam Deck Verified：目前只驗證 1280×800 畫面，尚未在 Deck／Proton 與實體控制器上驗證。
- 不勾 Steam Input API、Steam 成就、Steam Cloud、Steam Matchmaking／Lobbies、Steam Workshop、分割畫面或跨平台連線。
- 遊戲內成就不是 Steam 成就；玩家自行開服不是 Steam 媒合服務。
- 不宣稱正式遊戲含即時生成 AI。Creator Service 僅是開發工具，不會隨遊戲執行或匯出。

## Steamworks 帳號持有人必須完成

- [ ] 完成 Steamworks onboarding、稅務／銀行資料及每個產品的 Steam Direct 費用。
- [ ] 取得 App ID、Windows depot ID；若要另列工具，再取得 dedicated-server App／depot ID。
- [ ] 依 `store_configuration.json` 建立啟動選項及功能勾選，不增加未驗證功能。
- [ ] 完成 Content Survey；對隨遊戲出貨、玩家會看到的生成式 AI 輔助美術如實填寫「Pre-Generated」，並由權利人確認披露文字與內容權利。
- [ ] 上傳 gameplay-only 截圖、宣傳圖、說明、價格、分級與隱私／支援資料。
- [ ] 使用 `Prepare-SteamDepot.ps1` 產生 SteamPipe 預覽腳本，先上傳私有 beta branch；確認檔案清單後才 SetLive。
- [ ] 從乾淨 Steam 帳號安裝私有 branch，重跑鍵盤滑鼠單人、IP 多人、存檔、解除安裝／重裝測試。
- [ ] 將 near-final build 與商店頁送交 Valve review，依回饋修正後由帳號持有人按下發行。

## 官方依據

- Review Process: https://partner.steamgames.com/doc/store/review_process
- Content Survey: https://partner.steamgames.com/doc/gettingstarted/contentsurvey
- Steam Input: https://partner.steamgames.com/doc/features/steam_controller/getting_started_for_devs
- Steam Deck / Steam Machine Compatibility: https://partner.steamgames.com/doc/steamhardware/compat
- SteamPipe: https://partner.steamgames.com/doc/sdk/uploading
