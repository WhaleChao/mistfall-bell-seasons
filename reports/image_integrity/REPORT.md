# 《霧落農歌：鐘塔之季》圖片完整性報告

結果：**PASS**　｜　654 通過／0 失敗　｜　9 張 Runtime 圖片

本閘門自動盤點並直接解碼全部 Runtime PNG 與 SVG 圖示，驗證資產登錄、無損匯入、真 alpha、可追溯原稿、前景像素無遺失、格線安全邊界、動畫幀差異，以及 38 張實機／Studio／解析度／商業宣傳畫面。

| 分類 | 項目 | 結果 | 細節 |
|---|---|---:|---|
| 清單 | 所有 Runtime 圖片與應用程式圖示均已登錄 | 通過 | 10/10 |
| 清單 | 自動盤點的所有 Runtime 點陣圖均有完整性規則 | 通過 | 9/9 |
| 清單 | 應用程式 SVG 圖示已登錄資產與授權 | 通過 | res://icon.svg |
| 圖示 | SVG 應用程式圖示可讀取 | 通過 | 823 bytes |
| 圖示 | SVG 具有根節點與 viewBox | 通過 |  |
| 圖示 | SVG 不含可執行腳本 | 通過 |  |
| 圖示 | SVG 不依賴外部或內嵌遠端資源 | 通過 |  |
| 圖示 | Godot 可匯入並解碼 SVG 圖示 | 通過 | 128x128 |
| 清單 | 圖片已登錄資產與授權：mistfall_farm_title.png | 通過 | res://assets/runtime/backgrounds/mistfall_farm_title.png |
| 清單 | 圖片由 Runtime 自動盤點發現：mistfall_farm_title.png | 通過 | res://assets/runtime/backgrounds/mistfall_farm_title.png |
| 解碼 | PNG 可完整解碼：mistfall_farm_title.png | 通過 | OK |
| 尺寸 | 圖片尺寸在商業發行限制內：mistfall_farm_title.png | 通過 | 1672x941 |
| 格式 | 來源 PNG 不攜帶意外 mipmap：mistfall_farm_title.png | 通過 |  |
| 匯入 | Godot 圖片匯入設定存在：mistfall_farm_title.png | 通過 | res://assets/runtime/backgrounds/mistfall_farm_title.png.import |
| 匯入 | 圖片使用 Godot texture importer：mistfall_farm_title.png | 通過 |  |
| 匯入 | 圖片採無損匯入：mistfall_farm_title.png | 通過 |  |
| 匯入 | 像素圖片不產生 mipmap：mistfall_farm_title.png | 通過 |  |
| 匯入 | 透明邊緣色彩修正啟用：mistfall_farm_title.png | 通過 |  |
| 背景 | 背景解析度一致：mistfall_farm_title.png | 通過 | 1672x941 |
| 背景 | 背景維持 16:9 安全比例：mistfall_farm_title.png | 通過 | 1.77683 |
| 背景 | 背景不是空白／單色圖片：mistfall_farm_title.png | 通過 | variance=0.02063 |
| 背景 | 背景未大面積過曝或全黑：mistfall_farm_title.png | 通過 | dark=0.7% bright=0.0% |
| 清單 | 圖片已登錄資產與授權：mistfall_farm_commercial.png | 通過 | res://assets/runtime/backgrounds/mistfall_farm_commercial.png |
| 清單 | 圖片由 Runtime 自動盤點發現：mistfall_farm_commercial.png | 通過 | res://assets/runtime/backgrounds/mistfall_farm_commercial.png |
| 解碼 | PNG 可完整解碼：mistfall_farm_commercial.png | 通過 | OK |
| 尺寸 | 圖片尺寸在商業發行限制內：mistfall_farm_commercial.png | 通過 | 1672x941 |
| 格式 | 來源 PNG 不攜帶意外 mipmap：mistfall_farm_commercial.png | 通過 |  |
| 匯入 | Godot 圖片匯入設定存在：mistfall_farm_commercial.png | 通過 | res://assets/runtime/backgrounds/mistfall_farm_commercial.png.import |
| 匯入 | 圖片使用 Godot texture importer：mistfall_farm_commercial.png | 通過 |  |
| 匯入 | 圖片採無損匯入：mistfall_farm_commercial.png | 通過 |  |
| 匯入 | 像素圖片不產生 mipmap：mistfall_farm_commercial.png | 通過 |  |
| 匯入 | 透明邊緣色彩修正啟用：mistfall_farm_commercial.png | 通過 |  |
| 背景 | 背景解析度一致：mistfall_farm_commercial.png | 通過 | 1672x941 |
| 背景 | 背景維持 16:9 安全比例：mistfall_farm_commercial.png | 通過 | 1.77683 |
| 背景 | 背景不是空白／單色圖片：mistfall_farm_commercial.png | 通過 | variance=0.01202 |
| 背景 | 背景未大面積過曝或全黑：mistfall_farm_commercial.png | 通過 | dark=1.8% bright=0.0% |
| 清單 | 圖片已登錄資產與授權：mistfall_village_commercial.png | 通過 | res://assets/runtime/backgrounds/mistfall_village_commercial.png |
| 清單 | 圖片由 Runtime 自動盤點發現：mistfall_village_commercial.png | 通過 | res://assets/runtime/backgrounds/mistfall_village_commercial.png |
| 解碼 | PNG 可完整解碼：mistfall_village_commercial.png | 通過 | OK |
| 尺寸 | 圖片尺寸在商業發行限制內：mistfall_village_commercial.png | 通過 | 1672x941 |
| 格式 | 來源 PNG 不攜帶意外 mipmap：mistfall_village_commercial.png | 通過 |  |
| 匯入 | Godot 圖片匯入設定存在：mistfall_village_commercial.png | 通過 | res://assets/runtime/backgrounds/mistfall_village_commercial.png.import |
| 匯入 | 圖片使用 Godot texture importer：mistfall_village_commercial.png | 通過 |  |
| 匯入 | 圖片採無損匯入：mistfall_village_commercial.png | 通過 |  |
| 匯入 | 像素圖片不產生 mipmap：mistfall_village_commercial.png | 通過 |  |
| 匯入 | 透明邊緣色彩修正啟用：mistfall_village_commercial.png | 通過 |  |
| 背景 | 背景解析度一致：mistfall_village_commercial.png | 通過 | 1672x941 |
| 背景 | 背景維持 16:9 安全比例：mistfall_village_commercial.png | 通過 | 1.77683 |
| 背景 | 背景不是空白／單色圖片：mistfall_village_commercial.png | 通過 | variance=0.01189 |
| 背景 | 背景未大面積過曝或全黑：mistfall_village_commercial.png | 通過 | dark=0.3% bright=0.0% |
| 清單 | 圖片已登錄資產與授權：mistfall_dungeon_commercial.png | 通過 | res://assets/runtime/backgrounds/mistfall_dungeon_commercial.png |
| 清單 | 圖片由 Runtime 自動盤點發現：mistfall_dungeon_commercial.png | 通過 | res://assets/runtime/backgrounds/mistfall_dungeon_commercial.png |
| 解碼 | PNG 可完整解碼：mistfall_dungeon_commercial.png | 通過 | OK |
| 尺寸 | 圖片尺寸在商業發行限制內：mistfall_dungeon_commercial.png | 通過 | 1672x941 |
| 格式 | 來源 PNG 不攜帶意外 mipmap：mistfall_dungeon_commercial.png | 通過 |  |
| 匯入 | Godot 圖片匯入設定存在：mistfall_dungeon_commercial.png | 通過 | res://assets/runtime/backgrounds/mistfall_dungeon_commercial.png.import |
| 匯入 | 圖片使用 Godot texture importer：mistfall_dungeon_commercial.png | 通過 |  |
| 匯入 | 圖片採無損匯入：mistfall_dungeon_commercial.png | 通過 |  |
| 匯入 | 像素圖片不產生 mipmap：mistfall_dungeon_commercial.png | 通過 |  |
| 匯入 | 透明邊緣色彩修正啟用：mistfall_dungeon_commercial.png | 通過 |  |
| 背景 | 背景解析度一致：mistfall_dungeon_commercial.png | 通過 | 1672x941 |
| 背景 | 背景維持 16:9 安全比例：mistfall_dungeon_commercial.png | 通過 | 1.77683 |
| 背景 | 背景不是空白／單色圖片：mistfall_dungeon_commercial.png | 通過 | variance=0.00852 |
| 背景 | 背景未大面積過曝或全黑：mistfall_dungeon_commercial.png | 通過 | dark=4.0% bright=0.0% |
| 清單 | 圖片已登錄資產與授權：romance_candidates_atlas.png | 通過 | res://assets/runtime/portraits/romance_candidates_atlas.png |
| 清單 | 圖片由 Runtime 自動盤點發現：romance_candidates_atlas.png | 通過 | res://assets/runtime/portraits/romance_candidates_atlas.png |
| 解碼 | PNG 可完整解碼：romance_candidates_atlas.png | 通過 | OK |
| 尺寸 | 圖片尺寸在商業發行限制內：romance_candidates_atlas.png | 通過 | 2048x768 |
| 格式 | 來源 PNG 不攜帶意外 mipmap：romance_candidates_atlas.png | 通過 |  |
| 匯入 | Godot 圖片匯入設定存在：romance_candidates_atlas.png | 通過 | res://assets/runtime/portraits/romance_candidates_atlas.png.import |
| 匯入 | 圖片使用 Godot texture importer：romance_candidates_atlas.png | 通過 |  |
| 匯入 | 圖片採無損匯入：romance_candidates_atlas.png | 通過 |  |
| 匯入 | 像素圖片不產生 mipmap：romance_candidates_atlas.png | 通過 |  |
| 匯入 | 透明邊緣色彩修正啟用：romance_candidates_atlas.png | 通過 |  |
| 圖集 | 圖集切格餘數受控：romance_candidates_atlas.png | 通過 | cell=512x768 remainder=0x0 |
| 圖集 | 圖集每格解析度足夠：romance_candidates_atlas.png | 通過 | 512x768 |
| 圖集 | romance_candidates_atlas.png 格 0,0 含有效且有邊界的圖像 | 通過 | foreground=100.00% |
| 圖集 | romance_candidates_atlas.png 格 1,0 含有效且有邊界的圖像 | 通過 | foreground=100.00% |
| 圖集 | romance_candidates_atlas.png 格 2,0 含有效且有邊界的圖像 | 通過 | foreground=100.00% |
| 圖集 | romance_candidates_atlas.png 格 3,0 含有效且有邊界的圖像 | 通過 | foreground=100.00% |
| 圖集 | 所有預期圖格均非空白：romance_candidates_atlas.png | 通過 | 4/4 |
| 圖集 | 所有圖格內容可區分：romance_candidates_atlas.png | 通過 | 4/4 unique |
| 清單 | 圖片已登錄資產與授權：character_atlas_alpha.png | 通過 | res://assets/runtime/sprites/character_atlas_alpha.png |
| 清單 | 圖片由 Runtime 自動盤點發現：character_atlas_alpha.png | 通過 | res://assets/runtime/sprites/character_atlas_alpha.png |
| 解碼 | PNG 可完整解碼：character_atlas_alpha.png | 通過 | OK |
| 尺寸 | 圖片尺寸在商業發行限制內：character_atlas_alpha.png | 通過 | 1448x1086 |
| 格式 | 來源 PNG 不攜帶意外 mipmap：character_atlas_alpha.png | 通過 |  |
| 匯入 | Godot 圖片匯入設定存在：character_atlas_alpha.png | 通過 | res://assets/runtime/sprites/character_atlas_alpha.png.import |
| 匯入 | 圖片使用 Godot texture importer：character_atlas_alpha.png | 通過 |  |
| 匯入 | 圖片採無損匯入：character_atlas_alpha.png | 通過 |  |
| 匯入 | 像素圖片不產生 mipmap：character_atlas_alpha.png | 通過 |  |
| 匯入 | 透明邊緣色彩修正啟用：character_atlas_alpha.png | 通過 |  |
| 圖集 | 圖集切格餘數受控：character_atlas_alpha.png | 通過 | cell=362x362 remainder=0x0 |
| 圖集 | 圖集每格解析度足夠：character_atlas_alpha.png | 通過 | 362x362 |
| 圖集 | character_atlas_alpha.png 格 0,0 含有效且有邊界的圖像 | 通過 | foreground=22.27% |
| 圖集 | character_atlas_alpha.png 格 0,0 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | character_atlas_alpha.png 格 0,0 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | character_atlas_alpha.png 格 0,0 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | character_atlas_alpha.png 格 1,0 含有效且有邊界的圖像 | 通過 | foreground=21.00% |
| 圖集 | character_atlas_alpha.png 格 1,0 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | character_atlas_alpha.png 格 1,0 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | character_atlas_alpha.png 格 1,0 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | character_atlas_alpha.png 格 2,0 含有效且有邊界的圖像 | 通過 | foreground=25.39% |
| 圖集 | character_atlas_alpha.png 格 2,0 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | character_atlas_alpha.png 格 2,0 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | character_atlas_alpha.png 格 2,0 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | character_atlas_alpha.png 格 3,0 含有效且有邊界的圖像 | 通過 | foreground=22.46% |
| 圖集 | character_atlas_alpha.png 格 3,0 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | character_atlas_alpha.png 格 3,0 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | character_atlas_alpha.png 格 3,0 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | character_atlas_alpha.png 格 0,1 含有效且有邊界的圖像 | 通過 | foreground=26.37% |
| 圖集 | character_atlas_alpha.png 格 0,1 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | character_atlas_alpha.png 格 0,1 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | character_atlas_alpha.png 格 0,1 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | character_atlas_alpha.png 格 1,1 含有效且有邊界的圖像 | 通過 | foreground=25.68% |
| 圖集 | character_atlas_alpha.png 格 1,1 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | character_atlas_alpha.png 格 1,1 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | character_atlas_alpha.png 格 1,1 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | character_atlas_alpha.png 格 2,1 含有效且有邊界的圖像 | 通過 | foreground=22.36% |
| 圖集 | character_atlas_alpha.png 格 2,1 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | character_atlas_alpha.png 格 2,1 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | character_atlas_alpha.png 格 2,1 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | character_atlas_alpha.png 格 3,1 含有效且有邊界的圖像 | 通過 | foreground=25.39% |
| 圖集 | character_atlas_alpha.png 格 3,1 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | character_atlas_alpha.png 格 3,1 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | character_atlas_alpha.png 格 3,1 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | character_atlas_alpha.png 格 0,2 含有效且有邊界的圖像 | 通過 | foreground=23.34% |
| 圖集 | character_atlas_alpha.png 格 0,2 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | character_atlas_alpha.png 格 0,2 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | character_atlas_alpha.png 格 0,2 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | character_atlas_alpha.png 格 1,2 含有效且有邊界的圖像 | 通過 | foreground=26.07% |
| 圖集 | character_atlas_alpha.png 格 1,2 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | character_atlas_alpha.png 格 1,2 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | character_atlas_alpha.png 格 1,2 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | character_atlas_alpha.png 格 2,2 含有效且有邊界的圖像 | 通過 | foreground=17.38% |
| 圖集 | character_atlas_alpha.png 格 2,2 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | character_atlas_alpha.png 格 2,2 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | character_atlas_alpha.png 格 2,2 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | character_atlas_alpha.png 格 3,2 含有效且有邊界的圖像 | 通過 | foreground=15.04% |
| 圖集 | character_atlas_alpha.png 格 3,2 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | character_atlas_alpha.png 格 3,2 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | character_atlas_alpha.png 格 3,2 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | 所有預期圖格均非空白：character_atlas_alpha.png | 通過 | 12/12 |
| 透明 | 圖集使用真正 alpha 而非烘焙棋盤格：character_atlas_alpha.png | 通過 | 9495 sampled transparent pixels |
| 透明 | 圖集 alpha 為確定的像素級遮罩：character_atlas_alpha.png | 通過 | 0 sampled partial pixels |
| 透明 | 圖集仍保留不應被色鍵移除的亮色前景：character_atlas_alpha.png | 通過 | 1 sampled pixels |
| 圖集 | 所有圖格內容可區分：character_atlas_alpha.png | 通過 | 12/12 unique |
| 來源 | 透明圖集保留可追溯原稿：character_atlas_alpha.png | 通過 | res://assets/source/generated_atlases/character_atlas_checkerboard_source.png |
| 來源 | 原稿 SHA-256 與來源證據一致：character_atlas_checkerboard_source.png | 通過 | 7354dbd9a0ed60dedb8de633820bc394769f080fd9ef59fcdcf7a2797e33ab02 |
| 來源 | 棋盤格原稿可完整解碼：character_atlas_checkerboard_source.png | 通過 | OK |
| 來源 | 透明衍生圖只增加安全留白、不縮小原稿畫布：character_atlas_alpha.png | 通過 | (1448, 1086) -> (1448, 1086) |
| 來源 | 重新排格後仍在商業紋理限制內：character_atlas_alpha.png | 通過 | (1448, 1086) |
| 來源 | 所有明確非背景像素均保留：character_atlas_alpha.png | 通過 | 360121 >= 359680 |
| 來源 | 透明化確實移除與外緣連通的棋盤背景：character_atlas_alpha.png | 通過 | 1212407 pixels |
| 來源 | 透明化保留被輪廓包住的白色內容：character_atlas_alpha.png | 通過 | 441 pixels |
| 來源 | 透明衍生圖具有成功的可重現預處理紀錄：character_atlas_alpha.png | 通過 |  |
| 來源 | 重新排格沒有遺失任何前景像素：character_atlas_alpha.png | 通過 | 360121 -> 360121 |
| 來源 | 預處理紀錄與成品前景像素數一致：character_atlas_alpha.png | 通過 | 360121/360121 |
| 來源 | 每個圖格均取得至少一個連通前景元件：character_atlas_alpha.png | 通過 | [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0] |
| 清單 | 圖片已登錄資產與授權：enemy_atlas_alpha.png | 通過 | res://assets/runtime/sprites/enemy_atlas_alpha.png |
| 清單 | 圖片由 Runtime 自動盤點發現：enemy_atlas_alpha.png | 通過 | res://assets/runtime/sprites/enemy_atlas_alpha.png |
| 解碼 | PNG 可完整解碼：enemy_atlas_alpha.png | 通過 | OK |
| 尺寸 | 圖片尺寸在商業發行限制內：enemy_atlas_alpha.png | 通過 | 1332x1416 |
| 格式 | 來源 PNG 不攜帶意外 mipmap：enemy_atlas_alpha.png | 通過 |  |
| 匯入 | Godot 圖片匯入設定存在：enemy_atlas_alpha.png | 通過 | res://assets/runtime/sprites/enemy_atlas_alpha.png.import |
| 匯入 | 圖片使用 Godot texture importer：enemy_atlas_alpha.png | 通過 |  |
| 匯入 | 圖片採無損匯入：enemy_atlas_alpha.png | 通過 |  |
| 匯入 | 像素圖片不產生 mipmap：enemy_atlas_alpha.png | 通過 |  |
| 匯入 | 透明邊緣色彩修正啟用：enemy_atlas_alpha.png | 通過 |  |
| 圖集 | 圖集切格餘數受控：enemy_atlas_alpha.png | 通過 | cell=333x354 remainder=0x0 |
| 圖集 | 圖集每格解析度足夠：enemy_atlas_alpha.png | 通過 | 333x354 |
| 圖集 | enemy_atlas_alpha.png 格 0,0 含有效且有邊界的圖像 | 通過 | foreground=22.17% |
| 圖集 | enemy_atlas_alpha.png 格 0,0 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | enemy_atlas_alpha.png 格 0,0 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | enemy_atlas_alpha.png 格 0,0 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | enemy_atlas_alpha.png 格 1,0 含有效且有邊界的圖像 | 通過 | foreground=23.24% |
| 圖集 | enemy_atlas_alpha.png 格 1,0 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | enemy_atlas_alpha.png 格 1,0 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | enemy_atlas_alpha.png 格 1,0 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | enemy_atlas_alpha.png 格 2,0 含有效且有邊界的圖像 | 通過 | foreground=11.13% |
| 圖集 | enemy_atlas_alpha.png 格 2,0 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | enemy_atlas_alpha.png 格 2,0 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | enemy_atlas_alpha.png 格 2,0 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | enemy_atlas_alpha.png 格 3,0 含有效且有邊界的圖像 | 通過 | foreground=20.70% |
| 圖集 | enemy_atlas_alpha.png 格 3,0 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | enemy_atlas_alpha.png 格 3,0 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | enemy_atlas_alpha.png 格 3,0 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | enemy_atlas_alpha.png 格 0,1 含有效且有邊界的圖像 | 通過 | foreground=16.99% |
| 圖集 | enemy_atlas_alpha.png 格 0,1 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | enemy_atlas_alpha.png 格 0,1 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | enemy_atlas_alpha.png 格 0,1 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | enemy_atlas_alpha.png 格 1,1 含有效且有邊界的圖像 | 通過 | foreground=25.29% |
| 圖集 | enemy_atlas_alpha.png 格 1,1 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | enemy_atlas_alpha.png 格 1,1 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | enemy_atlas_alpha.png 格 1,1 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | enemy_atlas_alpha.png 格 2,1 含有效且有邊界的圖像 | 通過 | foreground=18.36% |
| 圖集 | enemy_atlas_alpha.png 格 2,1 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | enemy_atlas_alpha.png 格 2,1 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | enemy_atlas_alpha.png 格 2,1 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | enemy_atlas_alpha.png 格 3,1 含有效且有邊界的圖像 | 通過 | foreground=29.79% |
| 圖集 | enemy_atlas_alpha.png 格 3,1 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | enemy_atlas_alpha.png 格 3,1 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | enemy_atlas_alpha.png 格 3,1 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | enemy_atlas_alpha.png 格 0,2 含有效且有邊界的圖像 | 通過 | foreground=15.43% |
| 圖集 | enemy_atlas_alpha.png 格 0,2 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | enemy_atlas_alpha.png 格 0,2 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | enemy_atlas_alpha.png 格 0,2 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | enemy_atlas_alpha.png 格 1,2 含有效且有邊界的圖像 | 通過 | foreground=19.43% |
| 圖集 | enemy_atlas_alpha.png 格 1,2 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | enemy_atlas_alpha.png 格 1,2 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | enemy_atlas_alpha.png 格 1,2 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | enemy_atlas_alpha.png 格 2,2 含有效且有邊界的圖像 | 通過 | foreground=24.32% |
| 圖集 | enemy_atlas_alpha.png 格 2,2 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | enemy_atlas_alpha.png 格 2,2 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | enemy_atlas_alpha.png 格 2,2 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | enemy_atlas_alpha.png 格 3,2 含有效且有邊界的圖像 | 通過 | foreground=35.84% |
| 圖集 | enemy_atlas_alpha.png 格 3,2 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | enemy_atlas_alpha.png 格 3,2 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | enemy_atlas_alpha.png 格 3,2 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | enemy_atlas_alpha.png 格 0,3 含有效且有邊界的圖像 | 通過 | foreground=48.73% |
| 圖集 | enemy_atlas_alpha.png 格 0,3 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | enemy_atlas_alpha.png 格 0,3 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | enemy_atlas_alpha.png 格 0,3 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | enemy_atlas_alpha.png 格 1,3 含有效且有邊界的圖像 | 通過 | foreground=43.75% |
| 圖集 | enemy_atlas_alpha.png 格 1,3 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | enemy_atlas_alpha.png 格 1,3 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | enemy_atlas_alpha.png 格 1,3 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | enemy_atlas_alpha.png 格 2,3 含有效且有邊界的圖像 | 通過 | foreground=46.19% |
| 圖集 | enemy_atlas_alpha.png 格 2,3 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | enemy_atlas_alpha.png 格 2,3 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | enemy_atlas_alpha.png 格 2,3 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | enemy_atlas_alpha.png 格 3,3 含有效且有邊界的圖像 | 通過 | foreground=49.61% |
| 圖集 | enemy_atlas_alpha.png 格 3,3 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | enemy_atlas_alpha.png 格 3,3 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | enemy_atlas_alpha.png 格 3,3 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | 所有預期圖格均非空白：enemy_atlas_alpha.png | 通過 | 16/16 |
| 透明 | 圖集使用真正 alpha 而非烘焙棋盤格：enemy_atlas_alpha.png | 通過 | 11766 sampled transparent pixels |
| 透明 | 圖集 alpha 為確定的像素級遮罩：enemy_atlas_alpha.png | 通過 | 0 sampled partial pixels |
| 透明 | 圖集仍保留不應被色鍵移除的亮色前景：enemy_atlas_alpha.png | 通過 | 85 sampled pixels |
| 圖集 | 所有圖格內容可區分：enemy_atlas_alpha.png | 通過 | 16/16 unique |
| 來源 | 透明圖集保留可追溯原稿：enemy_atlas_alpha.png | 通過 | res://assets/source/generated_atlases/enemy_atlas_checkerboard_source.png |
| 來源 | 原稿 SHA-256 與來源證據一致：enemy_atlas_checkerboard_source.png | 通過 | 917759e5fcbbe7df435b3c38a61e9e2dbd5b3b4047efc341dfe416ef10990a65 |
| 來源 | 棋盤格原稿可完整解碼：enemy_atlas_checkerboard_source.png | 通過 | OK |
| 來源 | 透明衍生圖只增加安全留白、不縮小原稿畫布：enemy_atlas_alpha.png | 通過 | (1254, 1254) -> (1332, 1416) |
| 來源 | 重新排格後仍在商業紋理限制內：enemy_atlas_alpha.png | 通過 | (1332, 1416) |
| 來源 | 所有明確非背景像素均保留：enemy_atlas_alpha.png | 通過 | 532304 >= 521306 |
| 來源 | 透明化確實移除與外緣連通的棋盤背景：enemy_atlas_alpha.png | 通過 | 1353808 pixels |
| 來源 | 透明化保留被輪廓包住的白色內容：enemy_atlas_alpha.png | 通過 | 10998 pixels |
| 來源 | 透明衍生圖具有成功的可重現預處理紀錄：enemy_atlas_alpha.png | 通過 |  |
| 來源 | 重新排格沒有遺失任何前景像素：enemy_atlas_alpha.png | 通過 | 532304 -> 532304 |
| 來源 | 預處理紀錄與成品前景像素數一致：enemy_atlas_alpha.png | 通過 | 532304/532304 |
| 來源 | 每個圖格均取得至少一個連通前景元件：enemy_atlas_alpha.png | 通過 | [1.0, 2.0, 31.0, 6.0, 1.0, 1.0, 7.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 4.0] |
| 清單 | 圖片已登錄資產與授權：animal_atlas_alpha.png | 通過 | res://assets/runtime/sprites/animal_atlas_alpha.png |
| 清單 | 圖片由 Runtime 自動盤點發現：animal_atlas_alpha.png | 通過 | res://assets/runtime/sprites/animal_atlas_alpha.png |
| 解碼 | PNG 可完整解碼：animal_atlas_alpha.png | 通過 | OK |
| 尺寸 | 圖片尺寸在商業發行限制內：animal_atlas_alpha.png | 通過 | 1776x888 |
| 格式 | 來源 PNG 不攜帶意外 mipmap：animal_atlas_alpha.png | 通過 |  |
| 匯入 | Godot 圖片匯入設定存在：animal_atlas_alpha.png | 通過 | res://assets/runtime/sprites/animal_atlas_alpha.png.import |
| 匯入 | 圖片使用 Godot texture importer：animal_atlas_alpha.png | 通過 |  |
| 匯入 | 圖片採無損匯入：animal_atlas_alpha.png | 通過 |  |
| 匯入 | 像素圖片不產生 mipmap：animal_atlas_alpha.png | 通過 |  |
| 匯入 | 透明邊緣色彩修正啟用：animal_atlas_alpha.png | 通過 |  |
| 圖集 | 圖集切格餘數受控：animal_atlas_alpha.png | 通過 | cell=444x444 remainder=0x0 |
| 圖集 | 圖集每格解析度足夠：animal_atlas_alpha.png | 通過 | 444x444 |
| 圖集 | animal_atlas_alpha.png 格 0,0 含有效且有邊界的圖像 | 通過 | foreground=26.27% |
| 圖集 | animal_atlas_alpha.png 格 0,0 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | animal_atlas_alpha.png 格 0,0 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | animal_atlas_alpha.png 格 0,0 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 透明 | animal_atlas_alpha.png 格 0,0 保留白色動物／產物內容 | 通過 | 76 sampled pixels |
| 圖集 | animal_atlas_alpha.png 格 1,0 含有效且有邊界的圖像 | 通過 | foreground=24.80% |
| 圖集 | animal_atlas_alpha.png 格 1,0 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | animal_atlas_alpha.png 格 1,0 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | animal_atlas_alpha.png 格 1,0 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | animal_atlas_alpha.png 格 2,0 含有效且有邊界的圖像 | 通過 | foreground=34.28% |
| 圖集 | animal_atlas_alpha.png 格 2,0 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | animal_atlas_alpha.png 格 2,0 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | animal_atlas_alpha.png 格 2,0 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 透明 | animal_atlas_alpha.png 格 2,0 保留白色動物／產物內容 | 通過 | 34 sampled pixels |
| 圖集 | animal_atlas_alpha.png 格 3,0 含有效且有邊界的圖像 | 通過 | foreground=34.57% |
| 圖集 | animal_atlas_alpha.png 格 3,0 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | animal_atlas_alpha.png 格 3,0 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | animal_atlas_alpha.png 格 3,0 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | animal_atlas_alpha.png 格 0,1 含有效且有邊界的圖像 | 通過 | foreground=8.79% |
| 圖集 | animal_atlas_alpha.png 格 0,1 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | animal_atlas_alpha.png 格 0,1 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | animal_atlas_alpha.png 格 0,1 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | animal_atlas_alpha.png 格 1,1 含有效且有邊界的圖像 | 通過 | foreground=26.76% |
| 圖集 | animal_atlas_alpha.png 格 1,1 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | animal_atlas_alpha.png 格 1,1 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | animal_atlas_alpha.png 格 1,1 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | animal_atlas_alpha.png 格 2,1 含有效且有邊界的圖像 | 通過 | foreground=44.24% |
| 圖集 | animal_atlas_alpha.png 格 2,1 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | animal_atlas_alpha.png 格 2,1 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | animal_atlas_alpha.png 格 2,1 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 透明 | animal_atlas_alpha.png 格 2,1 保留白色動物／產物內容 | 通過 | 36 sampled pixels |
| 圖集 | animal_atlas_alpha.png 格 3,1 含有效且有邊界的圖像 | 通過 | foreground=19.14% |
| 圖集 | animal_atlas_alpha.png 格 3,1 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | animal_atlas_alpha.png 格 3,1 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | animal_atlas_alpha.png 格 3,1 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 透明 | animal_atlas_alpha.png 格 3,1 保留白色動物／產物內容 | 通過 | 24 sampled pixels |
| 圖集 | 所有預期圖格均非空白：animal_atlas_alpha.png | 通過 | 8/8 |
| 透明 | 圖集使用真正 alpha 而非烘焙棋盤格：animal_atlas_alpha.png | 通過 | 5951 sampled transparent pixels |
| 透明 | 圖集 alpha 為確定的像素級遮罩：animal_atlas_alpha.png | 通過 | 0 sampled partial pixels |
| 透明 | 圖集仍保留不應被色鍵移除的亮色前景：animal_atlas_alpha.png | 通過 | 178 sampled pixels |
| 圖集 | 所有圖格內容可區分：animal_atlas_alpha.png | 通過 | 8/8 unique |
| 來源 | 透明圖集保留可追溯原稿：animal_atlas_alpha.png | 通過 | res://assets/source/generated_atlases/animal_atlas_checkerboard_source.png |
| 來源 | 原稿 SHA-256 與來源證據一致：animal_atlas_checkerboard_source.png | 通過 | 6bdba66c0b8593c8891b3d8a3d5bd14adcc917d1ae0c9d9d4bfc3ab8ba05a725 |
| 來源 | 棋盤格原稿可完整解碼：animal_atlas_checkerboard_source.png | 通過 | OK |
| 來源 | 透明衍生圖只增加安全留白、不縮小原稿畫布：animal_atlas_alpha.png | 通過 | (1774, 887) -> (1776, 888) |
| 來源 | 重新排格後仍在商業紋理限制內：animal_atlas_alpha.png | 通過 | (1776, 888) |
| 來源 | 所有明確非背景像素均保留：animal_atlas_alpha.png | 通過 | 428107 >= 387572 |
| 來源 | 透明化確實移除與外緣連通的棋盤背景：animal_atlas_alpha.png | 通過 | 1148981 pixels |
| 來源 | 透明化保留被輪廓包住的白色內容：animal_atlas_alpha.png | 通過 | 40535 pixels |
| 來源 | 透明衍生圖具有成功的可重現預處理紀錄：animal_atlas_alpha.png | 通過 |  |
| 來源 | 重新排格沒有遺失任何前景像素：animal_atlas_alpha.png | 通過 | 428107 -> 428107 |
| 來源 | 預處理紀錄與成品前景像素數一致：animal_atlas_alpha.png | 通過 | 428107/428107 |
| 來源 | 每個圖格均取得至少一個連通前景元件：animal_atlas_alpha.png | 通過 | [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0] |
| 清單 | 圖片已登錄資產與授權：player_walk_atlas_alpha.png | 通過 | res://assets/runtime/sprites/player_walk_atlas_alpha.png |
| 清單 | 圖片由 Runtime 自動盤點發現：player_walk_atlas_alpha.png | 通過 | res://assets/runtime/sprites/player_walk_atlas_alpha.png |
| 解碼 | PNG 可完整解碼：player_walk_atlas_alpha.png | 通過 | OK |
| 尺寸 | 圖片尺寸在商業發行限制內：player_walk_atlas_alpha.png | 通過 | 1256x1256 |
| 格式 | 來源 PNG 不攜帶意外 mipmap：player_walk_atlas_alpha.png | 通過 |  |
| 匯入 | Godot 圖片匯入設定存在：player_walk_atlas_alpha.png | 通過 | res://assets/runtime/sprites/player_walk_atlas_alpha.png.import |
| 匯入 | 圖片使用 Godot texture importer：player_walk_atlas_alpha.png | 通過 |  |
| 匯入 | 圖片採無損匯入：player_walk_atlas_alpha.png | 通過 |  |
| 匯入 | 像素圖片不產生 mipmap：player_walk_atlas_alpha.png | 通過 |  |
| 匯入 | 透明邊緣色彩修正啟用：player_walk_atlas_alpha.png | 通過 |  |
| 圖集 | 圖集切格餘數受控：player_walk_atlas_alpha.png | 通過 | cell=314x314 remainder=0x0 |
| 圖集 | 圖集每格解析度足夠：player_walk_atlas_alpha.png | 通過 | 314x314 |
| 圖集 | player_walk_atlas_alpha.png 格 0,0 含有效且有邊界的圖像 | 通過 | foreground=23.34% |
| 圖集 | player_walk_atlas_alpha.png 格 0,0 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | player_walk_atlas_alpha.png 格 0,0 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | player_walk_atlas_alpha.png 格 0,0 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | player_walk_atlas_alpha.png 格 1,0 含有效且有邊界的圖像 | 通過 | foreground=23.14% |
| 圖集 | player_walk_atlas_alpha.png 格 1,0 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | player_walk_atlas_alpha.png 格 1,0 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | player_walk_atlas_alpha.png 格 1,0 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | player_walk_atlas_alpha.png 格 2,0 含有效且有邊界的圖像 | 通過 | foreground=24.12% |
| 圖集 | player_walk_atlas_alpha.png 格 2,0 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | player_walk_atlas_alpha.png 格 2,0 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | player_walk_atlas_alpha.png 格 2,0 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | player_walk_atlas_alpha.png 格 3,0 含有效且有邊界的圖像 | 通過 | foreground=23.63% |
| 圖集 | player_walk_atlas_alpha.png 格 3,0 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | player_walk_atlas_alpha.png 格 3,0 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | player_walk_atlas_alpha.png 格 3,0 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | player_walk_atlas_alpha.png 格 0,1 含有效且有邊界的圖像 | 通過 | foreground=19.14% |
| 圖集 | player_walk_atlas_alpha.png 格 0,1 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | player_walk_atlas_alpha.png 格 0,1 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | player_walk_atlas_alpha.png 格 0,1 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | player_walk_atlas_alpha.png 格 1,1 含有效且有邊界的圖像 | 通過 | foreground=19.53% |
| 圖集 | player_walk_atlas_alpha.png 格 1,1 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | player_walk_atlas_alpha.png 格 1,1 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | player_walk_atlas_alpha.png 格 1,1 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | player_walk_atlas_alpha.png 格 2,1 含有效且有邊界的圖像 | 通過 | foreground=19.43% |
| 圖集 | player_walk_atlas_alpha.png 格 2,1 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | player_walk_atlas_alpha.png 格 2,1 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | player_walk_atlas_alpha.png 格 2,1 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | player_walk_atlas_alpha.png 格 3,1 含有效且有邊界的圖像 | 通過 | foreground=18.95% |
| 圖集 | player_walk_atlas_alpha.png 格 3,1 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | player_walk_atlas_alpha.png 格 3,1 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | player_walk_atlas_alpha.png 格 3,1 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | player_walk_atlas_alpha.png 格 0,2 含有效且有邊界的圖像 | 通過 | foreground=19.43% |
| 圖集 | player_walk_atlas_alpha.png 格 0,2 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | player_walk_atlas_alpha.png 格 0,2 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | player_walk_atlas_alpha.png 格 0,2 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | player_walk_atlas_alpha.png 格 1,2 含有效且有邊界的圖像 | 通過 | foreground=19.43% |
| 圖集 | player_walk_atlas_alpha.png 格 1,2 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | player_walk_atlas_alpha.png 格 1,2 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | player_walk_atlas_alpha.png 格 1,2 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | player_walk_atlas_alpha.png 格 2,2 含有效且有邊界的圖像 | 通過 | foreground=19.43% |
| 圖集 | player_walk_atlas_alpha.png 格 2,2 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | player_walk_atlas_alpha.png 格 2,2 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | player_walk_atlas_alpha.png 格 2,2 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | player_walk_atlas_alpha.png 格 3,2 含有效且有邊界的圖像 | 通過 | foreground=19.43% |
| 圖集 | player_walk_atlas_alpha.png 格 3,2 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | player_walk_atlas_alpha.png 格 3,2 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | player_walk_atlas_alpha.png 格 3,2 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | player_walk_atlas_alpha.png 格 0,3 含有效且有邊界的圖像 | 通過 | foreground=21.39% |
| 圖集 | player_walk_atlas_alpha.png 格 0,3 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | player_walk_atlas_alpha.png 格 0,3 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | player_walk_atlas_alpha.png 格 0,3 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | player_walk_atlas_alpha.png 格 1,3 含有效且有邊界的圖像 | 通過 | foreground=21.48% |
| 圖集 | player_walk_atlas_alpha.png 格 1,3 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | player_walk_atlas_alpha.png 格 1,3 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | player_walk_atlas_alpha.png 格 1,3 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | player_walk_atlas_alpha.png 格 2,3 含有效且有邊界的圖像 | 通過 | foreground=21.29% |
| 圖集 | player_walk_atlas_alpha.png 格 2,3 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | player_walk_atlas_alpha.png 格 2,3 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | player_walk_atlas_alpha.png 格 2,3 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | player_walk_atlas_alpha.png 格 3,3 含有效且有邊界的圖像 | 通過 | foreground=21.68% |
| 圖集 | player_walk_atlas_alpha.png 格 3,3 四角為真透明且沒有切格溢出 | 通過 | transparent=100.00% |
| 圖集 | player_walk_atlas_alpha.png 格 3,3 四邊保留透明安全距離 | 通過 | transparent=100.00% |
| 透明 | player_walk_atlas_alpha.png 格 3,3 不含不確定半透明棋盤殘影 | 通過 | 0 |
| 圖集 | 所有預期圖格均非空白：player_walk_atlas_alpha.png | 通過 | 16/16 |
| 透明 | 圖集使用真正 alpha 而非烘焙棋盤格：player_walk_atlas_alpha.png | 通過 | 12955 sampled transparent pixels |
| 透明 | 圖集 alpha 為確定的像素級遮罩：player_walk_atlas_alpha.png | 通過 | 0 sampled partial pixels |
| 透明 | 圖集仍保留不應被色鍵移除的亮色前景：player_walk_atlas_alpha.png | 通過 | 7 sampled pixels |
| 圖集 | 所有圖格內容可區分：player_walk_atlas_alpha.png | 通過 | 16/16 unique |
| 動畫 | 玩家方向列 0 含 4 個不同動畫幀 | 通過 | 4/4 unique |
| 動畫 | 玩家方向列 1 含 4 個不同動畫幀 | 通過 | 4/4 unique |
| 動畫 | 玩家方向列 2 含 4 個不同動畫幀 | 通過 | 4/4 unique |
| 動畫 | 玩家方向列 3 含 4 個不同動畫幀 | 通過 | 4/4 unique |
| 來源 | 透明圖集保留可追溯原稿：player_walk_atlas_alpha.png | 通過 | res://assets/source/generated_atlases/player_walk_atlas_checkerboard_source.png |
| 來源 | 原稿 SHA-256 與來源證據一致：player_walk_atlas_checkerboard_source.png | 通過 | ff38826d3054d98b41f16c515e77b7ef493365a465baf10935ffe6b848046c85 |
| 來源 | 棋盤格原稿可完整解碼：player_walk_atlas_checkerboard_source.png | 通過 | OK |
| 來源 | 透明衍生圖只增加安全留白、不縮小原稿畫布：player_walk_atlas_alpha.png | 通過 | (1254, 1254) -> (1256, 1256) |
| 來源 | 重新排格後仍在商業紋理限制內：player_walk_atlas_alpha.png | 通過 | (1256, 1256) |
| 來源 | 所有明確非背景像素均保留：player_walk_atlas_alpha.png | 通過 | 331014 >= 330592 |
| 來源 | 透明化確實移除與外緣連通的棋盤背景：player_walk_atlas_alpha.png | 通過 | 1246522 pixels |
| 來源 | 透明化保留被輪廓包住的白色內容：player_walk_atlas_alpha.png | 通過 | 422 pixels |
| 來源 | 透明衍生圖具有成功的可重現預處理紀錄：player_walk_atlas_alpha.png | 通過 |  |
| 來源 | 重新排格沒有遺失任何前景像素：player_walk_atlas_alpha.png | 通過 | 331014 -> 331014 |
| 來源 | 預處理紀錄與成品前景像素數一致：player_walk_atlas_alpha.png | 通過 | 331014/331014 |
| 來源 | 每個圖格均取得至少一個連通前景元件：player_walk_atlas_alpha.png | 通過 | [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0] |
| 畫面證據 | 畫面集合數量完整：res://reports/full_feature_acceptance | 通過 | 12/12 |
| 畫面證據 | PNG 可完整解碼：01_title_and_profile.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：01_title_and_profile.png | 通過 | (1280, 720) |
| 畫面證據 | 畫面不是空白或單色：01_title_and_profile.png | 通過 | variance=0.01958 |
| 畫面證據 | 畫面具有足夠視覺內容：01_title_and_profile.png | 通過 | 247 sampled colors |
| 畫面證據 | 畫面未全黑或全白：01_title_and_profile.png | 通過 | dark=0.0% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：01_title_and_profile.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：02_four_frame_walk.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：02_four_frame_walk.png | 通過 | (1280, 720) |
| 畫面證據 | 畫面不是空白或單色：02_four_frame_walk.png | 通過 | variance=0.02288 |
| 畫面證據 | 畫面具有足夠視覺內容：02_four_frame_walk.png | 通過 | 513 sampled colors |
| 畫面證據 | 畫面未全黑或全白：02_four_frame_walk.png | 通過 | dark=0.2% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：02_four_frame_walk.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：03_dungeon_combat.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：03_dungeon_combat.png | 通過 | (1280, 720) |
| 畫面證據 | 畫面不是空白或單色：03_dungeon_combat.png | 通過 | variance=0.01724 |
| 畫面證據 | 畫面具有足夠視覺內容：03_dungeon_combat.png | 通過 | 463 sampled colors |
| 畫面證據 | 畫面未全黑或全白：03_dungeon_combat.png | 通過 | dark=0.1% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：03_dungeon_combat.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：04_floor_40_boss.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：04_floor_40_boss.png | 通過 | (1280, 720) |
| 畫面證據 | 畫面不是空白或單色：04_floor_40_boss.png | 通過 | variance=0.02031 |
| 畫面證據 | 畫面具有足夠視覺內容：04_floor_40_boss.png | 通過 | 469 sampled colors |
| 畫面證據 | 畫面未全黑或全白：04_floor_40_boss.png | 通過 | dark=0.1% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：04_floor_40_boss.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：05_final_boss.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：05_final_boss.png | 通過 | (1280, 720) |
| 畫面證據 | 畫面不是空白或單色：05_final_boss.png | 通過 | variance=0.02896 |
| 畫面證據 | 畫面具有足夠視覺內容：05_final_boss.png | 通過 | 477 sampled colors |
| 畫面證據 | 畫面未全黑或全白：05_final_boss.png | 通過 | dark=0.1% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：05_final_boss.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：06_mature_crop_and_weather.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：06_mature_crop_and_weather.png | 通過 | (1280, 720) |
| 畫面證據 | 畫面不是空白或單色：06_mature_crop_and_weather.png | 通過 | variance=0.02840 |
| 畫面證據 | 畫面具有足夠視覺內容：06_mature_crop_and_weather.png | 通過 | 537 sampled colors |
| 畫面證據 | 畫面未全黑或全白：06_mature_crop_and_weather.png | 通過 | dark=0.1% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：06_mature_crop_and_weather.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：07_animals_and_farm.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：07_animals_and_farm.png | 通過 | (1280, 720) |
| 畫面證據 | 畫面不是空白或單色：07_animals_and_farm.png | 通過 | variance=0.02823 |
| 畫面證據 | 畫面具有足夠視覺內容：07_animals_and_farm.png | 通過 | 553 sampled colors |
| 畫面證據 | 畫面未全黑或全白：07_animals_and_farm.png | 通過 | dark=0.2% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：07_animals_and_farm.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：08_shop_purchase.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：08_shop_purchase.png | 通過 | (1280, 720) |
| 畫面證據 | 畫面不是空白或單色：08_shop_purchase.png | 通過 | variance=0.01385 |
| 畫面證據 | 畫面具有足夠視覺內容：08_shop_purchase.png | 通過 | 85 sampled colors |
| 畫面證據 | 畫面未全黑或全白：08_shop_purchase.png | 通過 | dark=11.7% bright=0.4% |
| 畫面證據 | 商業截圖為完整不透明畫面：08_shop_purchase.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：09_village_dialogue.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：09_village_dialogue.png | 通過 | (1280, 720) |
| 畫面證據 | 畫面不是空白或單色：09_village_dialogue.png | 通過 | variance=0.02672 |
| 畫面證據 | 畫面具有足夠視覺內容：09_village_dialogue.png | 通過 | 280 sampled colors |
| 畫面證據 | 畫面未全黑或全白：09_village_dialogue.png | 通過 | dark=0.3% bright=0.6% |
| 畫面證據 | 商業截圖為完整不透明畫面：09_village_dialogue.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：10_interactive_festival.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：10_interactive_festival.png | 通過 | (1280, 720) |
| 畫面證據 | 畫面不是空白或單色：10_interactive_festival.png | 通過 | variance=0.01972 |
| 畫面證據 | 畫面具有足夠視覺內容：10_interactive_festival.png | 通過 | 89 sampled colors |
| 畫面證據 | 畫面未全黑或全白：10_interactive_festival.png | 通過 | dark=7.1% bright=0.7% |
| 畫面證據 | 商業截圖為完整不透明畫面：10_interactive_festival.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：11_status_inventory_menu.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：11_status_inventory_menu.png | 通過 | (1280, 720) |
| 畫面證據 | 畫面不是空白或單色：11_status_inventory_menu.png | 通過 | variance=0.02526 |
| 畫面證據 | 畫面具有足夠視覺內容：11_status_inventory_menu.png | 通過 | 51 sampled colors |
| 畫面證據 | 畫面未全黑或全白：11_status_inventory_menu.png | 通過 | dark=17.9% bright=1.7% |
| 畫面證據 | 商業截圖為完整不透明畫面：11_status_inventory_menu.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：12_acceptance_complete.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：12_acceptance_complete.png | 通過 | (1280, 720) |
| 畫面證據 | 畫面不是空白或單色：12_acceptance_complete.png | 通過 | variance=0.03078 |
| 畫面證據 | 畫面具有足夠視覺內容：12_acceptance_complete.png | 通過 | 532 sampled colors |
| 畫面證據 | 畫面未全黑或全白：12_acceptance_complete.png | 通過 | dark=0.1% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：12_acceptance_complete.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | 同一集合的每張畫面內容均可區分：res://reports/full_feature_acceptance | 通過 | 12/12 unique |
| 畫面證據 | 畫面集合數量完整：res://reports/studio_ui | 通過 | 16/16 |
| 畫面證據 | PNG 可完整解碼：01_project.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：01_project.png | 通過 | (1920, 1017) |
| 畫面證據 | 畫面不是空白或單色：01_project.png | 通過 | variance=0.00524 |
| 畫面證據 | 畫面具有足夠視覺內容：01_project.png | 通過 | 25 sampled colors |
| 畫面證據 | 畫面未全黑或全白：01_project.png | 通過 | dark=0.0% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：01_project.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：02_assets.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：02_assets.png | 通過 | (1920, 1017) |
| 畫面證據 | 畫面不是空白或單色：02_assets.png | 通過 | variance=0.00495 |
| 畫面證據 | 畫面具有足夠視覺內容：02_assets.png | 通過 | 25 sampled colors |
| 畫面證據 | 畫面未全黑或全白：02_assets.png | 通過 | dark=0.0% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：02_assets.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：03_world.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：03_world.png | 通過 | (1920, 1017) |
| 畫面證據 | 畫面不是空白或單色：03_world.png | 通過 | variance=0.00434 |
| 畫面證據 | 畫面具有足夠視覺內容：03_world.png | 通過 | 24 sampled colors |
| 畫面證據 | 畫面未全黑或全白：03_world.png | 通過 | dark=0.0% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：03_world.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：04_database.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：04_database.png | 通過 | (1920, 1017) |
| 畫面證據 | 畫面不是空白或單色：04_database.png | 通過 | variance=0.00466 |
| 畫面證據 | 畫面具有足夠視覺內容：04_database.png | 通過 | 25 sampled colors |
| 畫面證據 | 畫面未全黑或全白：04_database.png | 通過 | dark=0.0% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：04_database.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：05_calendar.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：05_calendar.png | 通過 | (1920, 1017) |
| 畫面證據 | 畫面不是空白或單色：05_calendar.png | 通過 | variance=0.00529 |
| 畫面證據 | 畫面具有足夠視覺內容：05_calendar.png | 通過 | 31 sampled colors |
| 畫面證據 | 畫面未全黑或全白：05_calendar.png | 通過 | dark=0.0% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：05_calendar.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：06_npc_schedules.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：06_npc_schedules.png | 通過 | (1920, 1017) |
| 畫面證據 | 畫面不是空白或單色：06_npc_schedules.png | 通過 | variance=0.00819 |
| 畫面證據 | 畫面具有足夠視覺內容：06_npc_schedules.png | 通過 | 32 sampled colors |
| 畫面證據 | 畫面未全黑或全白：06_npc_schedules.png | 通過 | dark=0.0% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：06_npc_schedules.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：07_crops.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：07_crops.png | 通過 | (1920, 1017) |
| 畫面證據 | 畫面不是空白或單色：07_crops.png | 通過 | variance=0.01005 |
| 畫面證據 | 畫面具有足夠視覺內容：07_crops.png | 通過 | 32 sampled colors |
| 畫面證據 | 畫面未全黑或全白：07_crops.png | 通過 | dark=0.0% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：07_crops.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：08_festivals.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：08_festivals.png | 通過 | (1920, 1017) |
| 畫面證據 | 畫面不是空白或單色：08_festivals.png | 通過 | variance=0.00903 |
| 畫面證據 | 畫面具有足夠視覺內容：08_festivals.png | 通過 | 30 sampled colors |
| 畫面證據 | 畫面未全黑或全白：08_festivals.png | 通過 | dark=0.0% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：08_festivals.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：09_farm_upgrades.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：09_farm_upgrades.png | 通過 | (1920, 1017) |
| 畫面證據 | 畫面不是空白或單色：09_farm_upgrades.png | 通過 | variance=0.00858 |
| 畫面證據 | 畫面具有足夠視覺內容：09_farm_upgrades.png | 通過 | 34 sampled colors |
| 畫面證據 | 畫面未全黑或全白：09_farm_upgrades.png | 通過 | dark=0.0% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：09_farm_upgrades.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：10_family.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：10_family.png | 通過 | (1920, 1017) |
| 畫面證據 | 畫面不是空白或單色：10_family.png | 通過 | variance=0.00551 |
| 畫面證據 | 畫面具有足夠視覺內容：10_family.png | 通過 | 27 sampled colors |
| 畫面證據 | 畫面未全黑或全白：10_family.png | 通過 | dark=0.0% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：10_family.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：11_dungeon.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：11_dungeon.png | 通過 | (1920, 1017) |
| 畫面證據 | 畫面不是空白或單色：11_dungeon.png | 通過 | variance=0.00442 |
| 畫面證據 | 畫面具有足夠視覺內容：11_dungeon.png | 通過 | 24 sampled colors |
| 畫面證據 | 畫面未全黑或全白：11_dungeon.png | 通過 | dark=0.0% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：11_dungeon.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：12_story.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：12_story.png | 通過 | (1920, 1017) |
| 畫面證據 | 畫面不是空白或單色：12_story.png | 通過 | variance=0.00694 |
| 畫面證據 | 畫面具有足夠視覺內容：12_story.png | 通過 | 34 sampled colors |
| 畫面證據 | 畫面未全黑或全白：12_story.png | 通過 | dark=0.0% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：12_story.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：13_ai.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：13_ai.png | 通過 | (1920, 1017) |
| 畫面證據 | 畫面不是空白或單色：13_ai.png | 通過 | variance=0.00446 |
| 畫面證據 | 畫面具有足夠視覺內容：13_ai.png | 通過 | 24 sampled colors |
| 畫面證據 | 畫面未全黑或全白：13_ai.png | 通過 | dark=0.0% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：13_ai.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：13_ai_completed.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：13_ai_completed.png | 通過 | (1920, 1017) |
| 畫面證據 | 畫面不是空白或單色：13_ai_completed.png | 通過 | variance=0.00674 |
| 畫面證據 | 畫面具有足夠視覺內容：13_ai_completed.png | 通過 | 28 sampled colors |
| 畫面證據 | 畫面未全黑或全白：13_ai_completed.png | 通過 | dark=0.0% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：13_ai_completed.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：14_tests.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：14_tests.png | 通過 | (1920, 1017) |
| 畫面證據 | 畫面不是空白或單色：14_tests.png | 通過 | variance=0.00383 |
| 畫面證據 | 畫面具有足夠視覺內容：14_tests.png | 通過 | 24 sampled colors |
| 畫面證據 | 畫面未全黑或全白：14_tests.png | 通過 | dark=0.0% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：14_tests.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：15_export.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：15_export.png | 通過 | (1920, 1017) |
| 畫面證據 | 畫面不是空白或單色：15_export.png | 通過 | variance=0.00390 |
| 畫面證據 | 畫面具有足夠視覺內容：15_export.png | 通過 | 21 sampled colors |
| 畫面證據 | 畫面未全黑或全白：15_export.png | 通過 | dark=0.0% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：15_export.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | 同一集合的每張畫面內容均可區分：res://reports/studio_ui | 通過 | 16/16 unique |
| 畫面證據 | 畫面集合數量完整：res://screenshots | 通過 | 6/6 |
| 畫面證據 | PNG 可完整解碼：commercial_dialogue.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：commercial_dialogue.png | 通過 | (1280, 720) |
| 畫面證據 | 畫面不是空白或單色：commercial_dialogue.png | 通過 | variance=0.02387 |
| 畫面證據 | 畫面具有足夠視覺內容：commercial_dialogue.png | 通過 | 271 sampled colors |
| 畫面證據 | 畫面未全黑或全白：commercial_dialogue.png | 通過 | dark=0.6% bright=0.3% |
| 畫面證據 | 商業截圖為完整不透明畫面：commercial_dialogue.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：commercial_dungeon.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：commercial_dungeon.png | 通過 | (1280, 720) |
| 畫面證據 | 畫面不是空白或單色：commercial_dungeon.png | 通過 | variance=0.01784 |
| 畫面證據 | 畫面具有足夠視覺內容：commercial_dungeon.png | 通過 | 465 sampled colors |
| 畫面證據 | 畫面未全黑或全白：commercial_dungeon.png | 通過 | dark=0.4% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：commercial_dungeon.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：commercial_farm.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：commercial_farm.png | 通過 | (1280, 720) |
| 畫面證據 | 畫面不是空白或單色：commercial_farm.png | 通過 | variance=0.02047 |
| 畫面證據 | 畫面具有足夠視覺內容：commercial_farm.png | 通過 | 508 sampled colors |
| 畫面證據 | 畫面未全黑或全白：commercial_farm.png | 通過 | dark=0.2% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：commercial_farm.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：commercial_festival.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：commercial_festival.png | 通過 | (1280, 720) |
| 畫面證據 | 畫面不是空白或單色：commercial_festival.png | 通過 | variance=0.01905 |
| 畫面證據 | 畫面具有足夠視覺內容：commercial_festival.png | 通過 | 81 sampled colors |
| 畫面證據 | 畫面未全黑或全白：commercial_festival.png | 通過 | dark=7.1% bright=0.7% |
| 畫面證據 | 商業截圖為完整不透明畫面：commercial_festival.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：commercial_menu.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：commercial_menu.png | 通過 | (1280, 720) |
| 畫面證據 | 畫面不是空白或單色：commercial_menu.png | 通過 | variance=0.02486 |
| 畫面證據 | 畫面具有足夠視覺內容：commercial_menu.png | 通過 | 51 sampled colors |
| 畫面證據 | 畫面未全黑或全白：commercial_menu.png | 通過 | dark=18.5% bright=1.7% |
| 畫面證據 | 商業截圖為完整不透明畫面：commercial_menu.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | PNG 可完整解碼：commercial_village.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：commercial_village.png | 通過 | (1280, 720) |
| 畫面證據 | 畫面不是空白或單色：commercial_village.png | 通過 | variance=0.02386 |
| 畫面證據 | 畫面具有足夠視覺內容：commercial_village.png | 通過 | 552 sampled colors |
| 畫面證據 | 畫面未全黑或全白：commercial_village.png | 通過 | dark=0.7% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：commercial_village.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | 同一集合的每張畫面內容均可區分：res://screenshots | 通過 | 6/6 unique |
| 畫面證據 | 四種整數縮放解析度畫面齊全 | 通過 | 4/4 |
| 畫面證據 | 解析度畫面檔名受契約約束：1280x720.png | 通過 |  |
| 畫面證據 | PNG 可完整解碼：1280x720.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：1280x720.png | 通過 | (1280, 720) |
| 畫面證據 | 畫面不是空白或單色：1280x720.png | 通過 | variance=0.02038 |
| 畫面證據 | 畫面具有足夠視覺內容：1280x720.png | 通過 | 508 sampled colors |
| 畫面證據 | 畫面未全黑或全白：1280x720.png | 通過 | dark=0.1% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：1280x720.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | 解析度畫面檔名受契約約束：1920x1080.png | 通過 |  |
| 畫面證據 | PNG 可完整解碼：1920x1080.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：1920x1080.png | 通過 | (1920, 1080) |
| 畫面證據 | 畫面不是空白或單色：1920x1080.png | 通過 | variance=0.02074 |
| 畫面證據 | 畫面具有足夠視覺內容：1920x1080.png | 通過 | 507 sampled colors |
| 畫面證據 | 畫面未全黑或全白：1920x1080.png | 通過 | dark=0.1% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：1920x1080.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | 解析度畫面檔名受契約約束：2560x1440.png | 通過 |  |
| 畫面證據 | PNG 可完整解碼：2560x1440.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：2560x1440.png | 通過 | (2560, 1440) |
| 畫面證據 | 畫面不是空白或單色：2560x1440.png | 通過 | variance=0.02052 |
| 畫面證據 | 畫面具有足夠視覺內容：2560x1440.png | 通過 | 496 sampled colors |
| 畫面證據 | 畫面未全黑或全白：2560x1440.png | 通過 | dark=0.1% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：2560x1440.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | 解析度畫面檔名受契約約束：640x360.png | 通過 |  |
| 畫面證據 | PNG 可完整解碼：640x360.png | 通過 | OK |
| 畫面證據 | 畫面解析度正確：640x360.png | 通過 | (640, 360) |
| 畫面證據 | 畫面不是空白或單色：640x360.png | 通過 | variance=0.01849 |
| 畫面證據 | 畫面具有足夠視覺內容：640x360.png | 通過 | 519 sampled colors |
| 畫面證據 | 畫面未全黑或全白：640x360.png | 通過 | dark=0.2% bright=0.0% |
| 畫面證據 | 商業截圖為完整不透明畫面：640x360.png | 通過 | 0 sampled transparent pixels |
| 畫面證據 | 所有商業畫面、實機驗收與解析度證據均納入統一閘門 | 通過 | 38/38 |
