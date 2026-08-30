# 霧落農歌：鐘塔之季 v1.0.2

本次補丁把可視化全功能驗收擴充為可重現的商業發布閘門，重點是圖片完整性、長期存檔安全、多解析度、供應鏈與解壓後成品。

- 非 headless 遊戲視窗再次完成 119 項全功能驗收，保存 12 張 1280×720 畫面證據。
- 9 張 Runtime 圖片通過 217 項原始 PNG／圖集逐格檢查；修正非整除圖集使用小數區域造成的邊界取樣風險。
- 12,000 遊戲日／100 年、1,200 場節慶、250 次磁碟存讀及損壞存檔復原全部通過。
- 640×360、1280×720、1920×1080、2560×1440 實際 GPU 畫面與整數縮放全部通過。
- 正式版移除 F4 除錯快轉；匯出 PCK 不含 AI、網路、模型、測試、報告或設計來源。
- 59 個第三方 Python 套件為 0 個已知漏洞，15 個 Python 測試零警告通過；正式 ZIP 附 Godot 4.7.2 授權及完整第三方著作權清單。
- ZIP 會在另一個隔離使用者目錄解壓後再次啟動，並驗證只有允許的成品與法律文件。

下載 `Mistfall-Bell-Seasons-v1.0.2-Windows-x64.zip`，解壓縮後執行 `Mistfall-Bell-Seasons.exe`。遊戲完全離線，不需要 Godot、Ollama 或 AI 模型。

Windows 執行檔目前未購買程式碼簽章，因此 SmartScreen 可能提示未知發行者；請使用同頁 `SHA256SUMS.txt` 核對下載內容。

發布後驗證：GitHub 的全新 Windows 11 VM 已直接下載公開 ZIP、核對 digest、解壓並啟動成功；遊戲執行期間 23 次 TCP／UDP 觀測皆為零端點。[查看驗證流程](https://github.com/WhaleChao/mistfall-bell-seasons/actions/runs/33289543994)

Windows ZIP SHA-256：`1dfcd68064f6d00aaff21e0dcfd3c98d769d5c07633bbbf8bdbe22fba00762b9`
