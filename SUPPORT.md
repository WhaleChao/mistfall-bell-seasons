# 支援與問題回報

請在 GitHub Issues 回報問題，附上：遊戲版本、Windows 版本、鍵盤或手把型號、重現步驟，以及是否能在新存檔重現。請勿上傳含個人資料的完整使用者目錄。

常見處理：

- 無法啟動：確認 Windows 10/11 x64 與顯示驅動已更新；將壓縮檔完整解壓後再執行。
- 畫面模糊：遊戲使用 640×360 基準與整數縮放；請在設定切換全螢幕。
- 手把配置：在 Esc／Start 的「設定」頁重新綁定。
- 多人連線：確認雙方皆為相同版本、主機允許所選 UDP 埠；網際網路主機需設定路由器 UDP 轉送，詳見 `SERVER_GUIDE.md`。
- 存檔問題：先備份 Godot `user://` 中的存檔再回報；不要手動降級 SaveGame schema。
- Windows SmartScreen：目前發行檔未使用公眾信任的 Authenticode 憑證；請只從專案 GitHub Releases 下載並核對 SHA-256。
