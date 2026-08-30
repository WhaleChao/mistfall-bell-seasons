# Steam Windows 候選版驗收

結果：**PASS**　｜　51/51 通過

鍵盤滑鼠以實際 Windows 遊戲流程驗收；本機偵測到 0 支手把，因此手把只驗證 18 組輸入映射，不宣稱實體端到端或 Steam Deck Verified。

| 分類 | 項目 | 結果 | 細節 |
|---|---|---:|---|
| Steam 啟動 | Big Picture 環境旗標存在 | 通過 | SteamTenfoot=1 |
| 商店設定 | Steam 商店設定檔存在 | 通過 | res://steam/store_configuration.json |
| 商店設定 | Steam 商店設定為合法 JSON | 通過 |  |
| 商店設定 | 只宣稱已實作的單人功能 | 通過 |  |
| 商店設定 | IP 直連合作人數標示為 16 | 通過 |  |
| 商店設定 | 手把只標部分支援 | 通過 |  |
| 商店設定 | 未宣稱未整合的 Steamworks 功能 | 通過 |  |
| 商店設定 | 手把證據明確標示為非實體測試 | 通過 |  |
| 商店設定 | 沒有宣稱 Steam Deck Verified | 通過 |  |
| 內容問卷 | AI 輔助素材列為預先生成、非遊玩時生成 | 通過 |  |
| 啟動設定 | Steam Windows 遊戲與伺服器啟動項完整 | 通過 | 2 options |
| 輸入設定 | move_left 有鍵盤／滑鼠映射 | 通過 |  |
| 輸入設定 | move_left 有 XInput 相容映射 | 通過 | mapping-only |
| 輸入設定 | move_right 有鍵盤／滑鼠映射 | 通過 |  |
| 輸入設定 | move_right 有 XInput 相容映射 | 通過 | mapping-only |
| 輸入設定 | move_up 有鍵盤／滑鼠映射 | 通過 |  |
| 輸入設定 | move_up 有 XInput 相容映射 | 通過 | mapping-only |
| 輸入設定 | move_down 有鍵盤／滑鼠映射 | 通過 |  |
| 輸入設定 | move_down 有 XInput 相容映射 | 通過 | mapping-only |
| 輸入設定 | attack 有鍵盤／滑鼠映射 | 通過 |  |
| 輸入設定 | attack 有 XInput 相容映射 | 通過 | mapping-only |
| 輸入設定 | dodge 有鍵盤／滑鼠映射 | 通過 |  |
| 輸入設定 | dodge 有 XInput 相容映射 | 通過 | mapping-only |
| 輸入設定 | active_skill 有鍵盤／滑鼠映射 | 通過 |  |
| 輸入設定 | active_skill 有 XInput 相容映射 | 通過 | mapping-only |
| 輸入設定 | interact 有鍵盤／滑鼠映射 | 通過 |  |
| 輸入設定 | interact 有 XInput 相容映射 | 通過 | mapping-only |
| 輸入設定 | use_potion 有鍵盤／滑鼠映射 | 通過 |  |
| 輸入設定 | use_potion 有 XInput 相容映射 | 通過 | mapping-only |
| 輸入設定 | cycle_seed 有鍵盤／滑鼠映射 | 通過 |  |
| 輸入設定 | cycle_seed 有 XInput 相容映射 | 通過 | mapping-only |
| 輸入設定 | sleep_day 有鍵盤／滑鼠映射 | 通過 |  |
| 輸入設定 | sleep_day 有 XInput 相容映射 | 通過 | mapping-only |
| 輸入設定 | time_speed 有鍵盤／滑鼠映射 | 通過 |  |
| 輸入設定 | time_speed 有 XInput 相容映射 | 通過 | mapping-only |
| 輸入設定 | toggle_cave 有鍵盤／滑鼠映射 | 通過 |  |
| 輸入設定 | toggle_cave 有 XInput 相容映射 | 通過 | mapping-only |
| 輸入設定 | attend_festival 有鍵盤／滑鼠映射 | 通過 |  |
| 輸入設定 | attend_festival 有 XInput 相容映射 | 通過 | mapping-only |
| 輸入設定 | pause_menu 有鍵盤／滑鼠映射 | 通過 |  |
| 輸入設定 | pause_menu 有 XInput 相容映射 | 通過 | mapping-only |
| 輸入設定 | multiplayer_menu 有鍵盤／滑鼠映射 | 通過 |  |
| 輸入設定 | multiplayer_menu 有 XInput 相容映射 | 通過 | mapping-only |
| 輸入設定 | quick_save 有鍵盤／滑鼠映射 | 通過 |  |
| 輸入設定 | quick_save 有 XInput 相容映射 | 通過 | mapping-only |
| 輸入設定 | quick_load 有鍵盤／滑鼠映射 | 通過 |  |
| 輸入設定 | quick_load 有 XInput 相容映射 | 通過 | mapping-only |
| Steam 啟動 | Big Picture 啟動自動進入全螢幕 | 通過 | mode=3 |
| 1280×800 | 標題與 HUD 可見文字控制項已納入字級檢查 | 通過 | 4 controls |
| 1280×800 | 最小可見文字高於 Steam Deck 9px 下限 | 通過 | 15px logical × 2 = 30px |
| 測試環境 | 記錄連接的手把數量；證據等級仍限映射契約 | 通過 | 0 connected |
