# 支援與問題回報

請在 GitHub Issues 回報問題，附上：遊戲版本、作業系統版本、Windows x64／Intel Mac／Apple Silicon、鍵盤或手把型號、重現步驟，以及是否能在新存檔重現。請勿上傳含個人資料的完整使用者目錄。

常見處理：

- Windows 無法啟動：確認 Windows 10/11 x64 與顯示驅動已更新；將壓縮檔完整解壓後再執行。
- macOS 無法啟動：Intel 需 macOS 11 以上，Apple Silicon 需 macOS 13 以上。成品尚未 notarize；首次啟動請在 Finder 右鍵選「打開」，或到「系統設定 → 隱私權與安全性」選「仍要打開」。
- 畫面模糊：遊戲使用 640×360 基準與整數縮放；請在設定切換全螢幕。
- 手把配置：在 Esc／Start 的「設定」頁重新綁定。
- 多人連線：確認雙方皆為相同版本、主機允許所選 UDP 埠；網際網路主機需設定路由器 UDP 轉送，詳見 `SERVER_GUIDE.md`。
- 存檔問題：先備份 Godot `user://` 中的存檔再回報；不要手動降級 SaveGame schema。
- Windows SmartScreen：目前發行檔未使用公眾信任的 Authenticode 憑證；請只從專案 GitHub Releases 下載並核對 SHA-256。
- 崩潰報告：正式 macOS 遊戲的 bundle identifier 是 `com.whalechao.mistfall-bell-seasons`；若報告顯示 `org.godotengine.godot`，它是 Godot 編輯器而非遊戲 App，請一併說明當時是執行原始專案或匯出成品。
