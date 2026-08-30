# 《霧落農歌：鐘塔之季》v1.1.3

這是 Windows Steam 商店候選版。遊戲內容、SaveGame v4 與 `1.1.0` 網路協定保持相容；本版加入保守且可自動驗證的 Steamworks 後台設定、Big Picture 啟動行為及 SteamPipe preview 工具。

## 本版驗證強化

- `SteamTenfoot=1` 實際啟動會進入全螢幕，但不會把 Big Picture 的暫時偏好寫入存檔；正式 EXE 的視窗實測完整覆蓋 1920×1080 螢幕並以 exit code 0 結束。
- Steam 候選閘門 51/51：Windows Steam client 已安裝並執行、鍵盤滑鼠完成實機主流程、18 組操作具鍵盤與 XInput 映射。
- Godot 實測連接手把數為 0，因此商店只標「部分控制器支援」；不宣稱完整控制器支援或 Steam Deck Verified。
- 1280×800 實際視窗通過：640×360 遊戲畫面以 2× 整數縮放輸出 1280×720，搭配上下各 40px 留邊；最小可見文字換算 30px。
- 保留 283 筆內容、712 項圖片、137 項可見全功能、38 程序多人、12,000 日／250 次存檔、1080p／20 敵人、Windows ZIP、零預設網路端點及 AI／設計來源排除等商業閘門。

## 下載

下載 `Mistfall-Bell-Seasons-v1.1.3-Windows-x64.zip`，完整解壓後執行 `Mistfall-Bell-Seasons.exe`。自行開服請閱讀壓縮檔內的 `SERVER_GUIDE.md`。

正式檔尚未取得公眾信任的 Authenticode 簽章。Steam 上架仍需帳號持有人提供 App／Depot ID、完成費用／稅務／內容問卷／商店素材、上傳私有 branch 並送交 Valve review；預先生成的 AI 輔助美術必須如實披露。
