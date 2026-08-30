# 《霧落農歌：鐘塔之季》圖片完整性報告

結果：**PASS**　｜　217 通過／0 失敗　｜　9 張 Runtime 圖片

本閘門直接解碼原始 PNG，驗證資產登錄、尺寸、比例、圖集格線、未使用餘邊、空白格、重複格、動畫幀差異與 12 張實機畫面證據。

| 分類 | 項目 | 結果 | 細節 |
|---|---|---:|---|
| 清單 | 所有 Runtime 點陣圖均有完整性規則 | 通過 | 9/9 |
| 清單 | 圖片已登錄資產與授權：mistfall_farm_title.png | 通過 | res://assets/runtime/backgrounds/mistfall_farm_title.png |
| 解碼 | PNG 可完整解碼：mistfall_farm_title.png | 通過 | OK |
| 尺寸 | 圖片尺寸在商業發行限制內：mistfall_farm_title.png | 通過 | 1672x941 |
| 格式 | 來源 PNG 不攜帶意外 mipmap：mistfall_farm_title.png | 通過 |  |
| 背景 | 背景解析度一致：mistfall_farm_title.png | 通過 | 1672x941 |
| 背景 | 背景維持 16:9 安全比例：mistfall_farm_title.png | 通過 | 1.77683 |
| 背景 | 背景不是空白／單色圖片：mistfall_farm_title.png | 通過 | variance=0.02063 |
| 背景 | 背景未大面積過曝或全黑：mistfall_farm_title.png | 通過 | dark=0.7% bright=0.0% |
| 清單 | 圖片已登錄資產與授權：mistfall_farm_commercial.png | 通過 | res://assets/runtime/backgrounds/mistfall_farm_commercial.png |
| 解碼 | PNG 可完整解碼：mistfall_farm_commercial.png | 通過 | OK |
| 尺寸 | 圖片尺寸在商業發行限制內：mistfall_farm_commercial.png | 通過 | 1672x941 |
| 格式 | 來源 PNG 不攜帶意外 mipmap：mistfall_farm_commercial.png | 通過 |  |
| 背景 | 背景解析度一致：mistfall_farm_commercial.png | 通過 | 1672x941 |
| 背景 | 背景維持 16:9 安全比例：mistfall_farm_commercial.png | 通過 | 1.77683 |
| 背景 | 背景不是空白／單色圖片：mistfall_farm_commercial.png | 通過 | variance=0.01202 |
| 背景 | 背景未大面積過曝或全黑：mistfall_farm_commercial.png | 通過 | dark=1.8% bright=0.0% |
| 清單 | 圖片已登錄資產與授權：mistfall_village_commercial.png | 通過 | res://assets/runtime/backgrounds/mistfall_village_commercial.png |
| 解碼 | PNG 可完整解碼：mistfall_village_commercial.png | 通過 | OK |
| 尺寸 | 圖片尺寸在商業發行限制內：mistfall_village_commercial.png | 通過 | 1672x941 |
| 格式 | 來源 PNG 不攜帶意外 mipmap：mistfall_village_commercial.png | 通過 |  |
| 背景 | 背景解析度一致：mistfall_village_commercial.png | 通過 | 1672x941 |
| 背景 | 背景維持 16:9 安全比例：mistfall_village_commercial.png | 通過 | 1.77683 |
| 背景 | 背景不是空白／單色圖片：mistfall_village_commercial.png | 通過 | variance=0.01189 |
| 背景 | 背景未大面積過曝或全黑：mistfall_village_commercial.png | 通過 | dark=0.3% bright=0.0% |
| 清單 | 圖片已登錄資產與授權：mistfall_dungeon_commercial.png | 通過 | res://assets/runtime/backgrounds/mistfall_dungeon_commercial.png |
| 解碼 | PNG 可完整解碼：mistfall_dungeon_commercial.png | 通過 | OK |
| 尺寸 | 圖片尺寸在商業發行限制內：mistfall_dungeon_commercial.png | 通過 | 1672x941 |
| 格式 | 來源 PNG 不攜帶意外 mipmap：mistfall_dungeon_commercial.png | 通過 |  |
| 背景 | 背景解析度一致：mistfall_dungeon_commercial.png | 通過 | 1672x941 |
| 背景 | 背景維持 16:9 安全比例：mistfall_dungeon_commercial.png | 通過 | 1.77683 |
| 背景 | 背景不是空白／單色圖片：mistfall_dungeon_commercial.png | 通過 | variance=0.00852 |
| 背景 | 背景未大面積過曝或全黑：mistfall_dungeon_commercial.png | 通過 | dark=4.0% bright=0.0% |
| 清單 | 圖片已登錄資產與授權：romance_candidates_atlas.png | 通過 | res://assets/runtime/portraits/romance_candidates_atlas.png |
| 解碼 | PNG 可完整解碼：romance_candidates_atlas.png | 通過 | OK |
| 尺寸 | 圖片尺寸在商業發行限制內：romance_candidates_atlas.png | 通過 | 2048x768 |
| 格式 | 來源 PNG 不攜帶意外 mipmap：romance_candidates_atlas.png | 通過 |  |
| 圖集 | 圖集切格餘數受控：romance_candidates_atlas.png | 通過 | cell=512x768 remainder=0x0 |
| 圖集 | 圖集每格解析度足夠：romance_candidates_atlas.png | 通過 | 512x768 |
| 圖集 | romance_candidates_atlas.png 格 0,0 含有效且有邊界的圖像 | 通過 | foreground=100.00% |
| 圖集 | romance_candidates_atlas.png 格 0,0 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | romance_candidates_atlas.png 格 1,0 含有效且有邊界的圖像 | 通過 | foreground=100.00% |
| 圖集 | romance_candidates_atlas.png 格 1,0 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | romance_candidates_atlas.png 格 2,0 含有效且有邊界的圖像 | 通過 | foreground=100.00% |
| 圖集 | romance_candidates_atlas.png 格 2,0 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | romance_candidates_atlas.png 格 3,0 含有效且有邊界的圖像 | 通過 | foreground=100.00% |
| 圖集 | romance_candidates_atlas.png 格 3,0 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | 所有預期圖格均非空白：romance_candidates_atlas.png | 通過 | 4/4 |
| 圖集 | 所有圖格內容可區分：romance_candidates_atlas.png | 通過 | 4/4 unique |
| 清單 | 圖片已登錄資產與授權：character_atlas.png | 通過 | res://assets/runtime/sprites/character_atlas.png |
| 解碼 | PNG 可完整解碼：character_atlas.png | 通過 | OK |
| 尺寸 | 圖片尺寸在商業發行限制內：character_atlas.png | 通過 | 1448x1086 |
| 格式 | 來源 PNG 不攜帶意外 mipmap：character_atlas.png | 通過 |  |
| 圖集 | 圖集切格餘數受控：character_atlas.png | 通過 | cell=362x362 remainder=0x0 |
| 圖集 | 圖集每格解析度足夠：character_atlas.png | 通過 | 362x362 |
| 圖集 | character_atlas.png 格 0,0 含有效且有邊界的圖像 | 通過 | foreground=22.27% |
| 圖集 | character_atlas.png 格 0,0 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | character_atlas.png 格 1,0 含有效且有邊界的圖像 | 通過 | foreground=21.39% |
| 圖集 | character_atlas.png 格 1,0 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | character_atlas.png 格 2,0 含有效且有邊界的圖像 | 通過 | foreground=25.59% |
| 圖集 | character_atlas.png 格 2,0 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | character_atlas.png 格 3,0 含有效且有邊界的圖像 | 通過 | foreground=22.95% |
| 圖集 | character_atlas.png 格 3,0 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | character_atlas.png 格 0,1 含有效且有邊界的圖像 | 通過 | foreground=26.95% |
| 圖集 | character_atlas.png 格 0,1 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | character_atlas.png 格 1,1 含有效且有邊界的圖像 | 通過 | foreground=26.86% |
| 圖集 | character_atlas.png 格 1,1 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | character_atlas.png 格 2,1 含有效且有邊界的圖像 | 通過 | foreground=21.97% |
| 圖集 | character_atlas.png 格 2,1 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | character_atlas.png 格 3,1 含有效且有邊界的圖像 | 通過 | foreground=25.59% |
| 圖集 | character_atlas.png 格 3,1 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | character_atlas.png 格 0,2 含有效且有邊界的圖像 | 通過 | foreground=23.24% |
| 圖集 | character_atlas.png 格 0,2 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | character_atlas.png 格 1,2 含有效且有邊界的圖像 | 通過 | foreground=25.00% |
| 圖集 | character_atlas.png 格 1,2 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | character_atlas.png 格 2,2 含有效且有邊界的圖像 | 通過 | foreground=17.19% |
| 圖集 | character_atlas.png 格 2,2 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | character_atlas.png 格 3,2 含有效且有邊界的圖像 | 通過 | foreground=15.33% |
| 圖集 | character_atlas.png 格 3,2 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | 所有預期圖格均非空白：character_atlas.png | 通過 | 12/12 |
| 圖集 | 所有圖格內容可區分：character_atlas.png | 通過 | 12/12 unique |
| 清單 | 圖片已登錄資產與授權：enemy_atlas.png | 通過 | res://assets/runtime/sprites/enemy_atlas.png |
| 解碼 | PNG 可完整解碼：enemy_atlas.png | 通過 | OK |
| 尺寸 | 圖片尺寸在商業發行限制內：enemy_atlas.png | 通過 | 1254x1254 |
| 格式 | 來源 PNG 不攜帶意外 mipmap：enemy_atlas.png | 通過 |  |
| 圖集 | 圖集切格餘數受控：enemy_atlas.png | 通過 | cell=313x313 remainder=2x2 |
| 圖集 | 圖集每格解析度足夠：enemy_atlas.png | 通過 | 313x313 |
| 圖集 | 未使用餘邊只有可移除背景：enemy_atlas.png | 通過 | 100.000% |
| 圖集 | enemy_atlas.png 格 0,0 含有效且有邊界的圖像 | 通過 | foreground=26.17% |
| 圖集 | enemy_atlas.png 格 0,0 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | enemy_atlas.png 格 1,0 含有效且有邊界的圖像 | 通過 | foreground=28.91% |
| 圖集 | enemy_atlas.png 格 1,0 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | enemy_atlas.png 格 2,0 含有效且有邊界的圖像 | 通過 | foreground=12.70% |
| 圖集 | enemy_atlas.png 格 2,0 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | enemy_atlas.png 格 3,0 含有效且有邊界的圖像 | 通過 | foreground=24.22% |
| 圖集 | enemy_atlas.png 格 3,0 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | enemy_atlas.png 格 0,1 含有效且有邊界的圖像 | 通過 | foreground=20.61% |
| 圖集 | enemy_atlas.png 格 0,1 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | enemy_atlas.png 格 1,1 含有效且有邊界的圖像 | 通過 | foreground=30.47% |
| 圖集 | enemy_atlas.png 格 1,1 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | enemy_atlas.png 格 2,1 含有效且有邊界的圖像 | 通過 | foreground=22.85% |
| 圖集 | enemy_atlas.png 格 2,1 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | enemy_atlas.png 格 3,1 含有效且有邊界的圖像 | 通過 | foreground=37.11% |
| 圖集 | enemy_atlas.png 格 3,1 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | enemy_atlas.png 格 0,2 含有效且有邊界的圖像 | 通過 | foreground=23.24% |
| 圖集 | enemy_atlas.png 格 0,2 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | enemy_atlas.png 格 1,2 含有效且有邊界的圖像 | 通過 | foreground=27.05% |
| 圖集 | enemy_atlas.png 格 1,2 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | enemy_atlas.png 格 2,2 含有效且有邊界的圖像 | 通過 | foreground=33.69% |
| 圖集 | enemy_atlas.png 格 2,2 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | enemy_atlas.png 格 3,2 含有效且有邊界的圖像 | 通過 | foreground=45.70% |
| 圖集 | enemy_atlas.png 格 3,2 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | enemy_atlas.png 格 0,3 含有效且有邊界的圖像 | 通過 | foreground=52.54% |
| 圖集 | enemy_atlas.png 格 0,3 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | enemy_atlas.png 格 1,3 含有效且有邊界的圖像 | 通過 | foreground=47.36% |
| 圖集 | enemy_atlas.png 格 1,3 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | enemy_atlas.png 格 2,3 含有效且有邊界的圖像 | 通過 | foreground=49.80% |
| 圖集 | enemy_atlas.png 格 2,3 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | enemy_atlas.png 格 3,3 含有效且有邊界的圖像 | 通過 | foreground=52.05% |
| 圖集 | enemy_atlas.png 格 3,3 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | 所有預期圖格均非空白：enemy_atlas.png | 通過 | 16/16 |
| 圖集 | 所有圖格內容可區分：enemy_atlas.png | 通過 | 16/16 unique |
| 清單 | 圖片已登錄資產與授權：animal_atlas.png | 通過 | res://assets/runtime/sprites/animal_atlas.png |
| 解碼 | PNG 可完整解碼：animal_atlas.png | 通過 | OK |
| 尺寸 | 圖片尺寸在商業發行限制內：animal_atlas.png | 通過 | 1774x887 |
| 格式 | 來源 PNG 不攜帶意外 mipmap：animal_atlas.png | 通過 |  |
| 圖集 | 圖集切格餘數受控：animal_atlas.png | 通過 | cell=443x443 remainder=2x1 |
| 圖集 | 圖集每格解析度足夠：animal_atlas.png | 通過 | 443x443 |
| 圖集 | 未使用餘邊只有可移除背景：animal_atlas.png | 通過 | 100.000% |
| 圖集 | animal_atlas.png 格 0,0 含有效且有邊界的圖像 | 通過 | foreground=17.29% |
| 圖集 | animal_atlas.png 格 0,0 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | animal_atlas.png 格 1,0 含有效且有邊界的圖像 | 通過 | foreground=24.41% |
| 圖集 | animal_atlas.png 格 1,0 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | animal_atlas.png 格 2,0 含有效且有邊界的圖像 | 通過 | foreground=30.66% |
| 圖集 | animal_atlas.png 格 2,0 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | animal_atlas.png 格 3,0 含有效且有邊界的圖像 | 通過 | foreground=33.79% |
| 圖集 | animal_atlas.png 格 3,0 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | animal_atlas.png 格 0,1 含有效且有邊界的圖像 | 通過 | foreground=9.08% |
| 圖集 | animal_atlas.png 格 0,1 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | animal_atlas.png 格 1,1 含有效且有邊界的圖像 | 通過 | foreground=26.37% |
| 圖集 | animal_atlas.png 格 1,1 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | animal_atlas.png 格 2,1 含有效且有邊界的圖像 | 通過 | foreground=40.72% |
| 圖集 | animal_atlas.png 格 2,1 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | animal_atlas.png 格 3,1 含有效且有邊界的圖像 | 通過 | foreground=16.41% |
| 圖集 | animal_atlas.png 格 3,1 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | 所有預期圖格均非空白：animal_atlas.png | 通過 | 8/8 |
| 圖集 | 所有圖格內容可區分：animal_atlas.png | 通過 | 8/8 unique |
| 清單 | 圖片已登錄資產與授權：player_walk_atlas.png | 通過 | res://assets/runtime/sprites/player_walk_atlas.png |
| 解碼 | PNG 可完整解碼：player_walk_atlas.png | 通過 | OK |
| 尺寸 | 圖片尺寸在商業發行限制內：player_walk_atlas.png | 通過 | 1254x1254 |
| 格式 | 來源 PNG 不攜帶意外 mipmap：player_walk_atlas.png | 通過 |  |
| 圖集 | 圖集切格餘數受控：player_walk_atlas.png | 通過 | cell=313x313 remainder=2x2 |
| 圖集 | 圖集每格解析度足夠：player_walk_atlas.png | 通過 | 313x313 |
| 圖集 | 未使用餘邊只有可移除背景：player_walk_atlas.png | 通過 | 100.000% |
| 圖集 | player_walk_atlas.png 格 0,0 含有效且有邊界的圖像 | 通過 | foreground=23.34% |
| 圖集 | player_walk_atlas.png 格 0,0 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | player_walk_atlas.png 格 1,0 含有效且有邊界的圖像 | 通過 | foreground=23.63% |
| 圖集 | player_walk_atlas.png 格 1,0 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | player_walk_atlas.png 格 2,0 含有效且有邊界的圖像 | 通過 | foreground=23.34% |
| 圖集 | player_walk_atlas.png 格 2,0 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | player_walk_atlas.png 格 3,0 含有效且有邊界的圖像 | 通過 | foreground=23.93% |
| 圖集 | player_walk_atlas.png 格 3,0 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | player_walk_atlas.png 格 0,1 含有效且有邊界的圖像 | 通過 | foreground=20.21% |
| 圖集 | player_walk_atlas.png 格 0,1 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | player_walk_atlas.png 格 1,1 含有效且有邊界的圖像 | 通過 | foreground=20.02% |
| 圖集 | player_walk_atlas.png 格 1,1 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | player_walk_atlas.png 格 2,1 含有效且有邊界的圖像 | 通過 | foreground=19.82% |
| 圖集 | player_walk_atlas.png 格 2,1 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | player_walk_atlas.png 格 3,1 含有效且有邊界的圖像 | 通過 | foreground=20.12% |
| 圖集 | player_walk_atlas.png 格 3,1 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | player_walk_atlas.png 格 0,2 含有效且有邊界的圖像 | 通過 | foreground=21.88% |
| 圖集 | player_walk_atlas.png 格 0,2 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | player_walk_atlas.png 格 1,2 含有效且有邊界的圖像 | 通過 | foreground=21.58% |
| 圖集 | player_walk_atlas.png 格 1,2 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | player_walk_atlas.png 格 2,2 含有效且有邊界的圖像 | 通過 | foreground=22.56% |
| 圖集 | player_walk_atlas.png 格 2,2 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | player_walk_atlas.png 格 3,2 含有效且有邊界的圖像 | 通過 | foreground=21.97% |
| 圖集 | player_walk_atlas.png 格 3,2 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | player_walk_atlas.png 格 0,3 含有效且有邊界的圖像 | 通過 | foreground=18.55% |
| 圖集 | player_walk_atlas.png 格 0,3 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | player_walk_atlas.png 格 1,3 含有效且有邊界的圖像 | 通過 | foreground=18.65% |
| 圖集 | player_walk_atlas.png 格 1,3 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | player_walk_atlas.png 格 2,3 含有效且有邊界的圖像 | 通過 | foreground=18.55% |
| 圖集 | player_walk_atlas.png 格 2,3 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | player_walk_atlas.png 格 3,3 含有效且有邊界的圖像 | 通過 | foreground=18.55% |
| 圖集 | player_walk_atlas.png 格 3,3 四角不含切格溢出 | 通過 | background=100.00% |
| 圖集 | 所有預期圖格均非空白：player_walk_atlas.png | 通過 | 16/16 |
| 圖集 | 所有圖格內容可區分：player_walk_atlas.png | 通過 | 16/16 unique |
| 動畫 | 玩家方向列 0 含 4 個不同動畫幀 | 通過 | 4/4 unique |
| 動畫 | 玩家方向列 1 含 4 個不同動畫幀 | 通過 | 4/4 unique |
| 動畫 | 玩家方向列 2 含 4 個不同動畫幀 | 通過 | 4/4 unique |
| 動畫 | 玩家方向列 3 含 4 個不同動畫幀 | 通過 | 4/4 unique |
| 畫面證據 | 全功能驗收保留 12 張畫面 | 通過 | 12 |
| 畫面證據 | 驗收畫面可完整解碼：01_title_and_profile.png | 通過 | OK |
| 畫面證據 | 驗收畫面解析度正確：01_title_and_profile.png | 通過 | 1280x720 |
| 畫面證據 | 驗收畫面可完整解碼：02_four_frame_walk.png | 通過 | OK |
| 畫面證據 | 驗收畫面解析度正確：02_four_frame_walk.png | 通過 | 1280x720 |
| 畫面證據 | 驗收畫面可完整解碼：03_dungeon_combat.png | 通過 | OK |
| 畫面證據 | 驗收畫面解析度正確：03_dungeon_combat.png | 通過 | 1280x720 |
| 畫面證據 | 驗收畫面可完整解碼：04_floor_40_boss.png | 通過 | OK |
| 畫面證據 | 驗收畫面解析度正確：04_floor_40_boss.png | 通過 | 1280x720 |
| 畫面證據 | 驗收畫面可完整解碼：05_final_boss.png | 通過 | OK |
| 畫面證據 | 驗收畫面解析度正確：05_final_boss.png | 通過 | 1280x720 |
| 畫面證據 | 驗收畫面可完整解碼：06_mature_crop_and_weather.png | 通過 | OK |
| 畫面證據 | 驗收畫面解析度正確：06_mature_crop_and_weather.png | 通過 | 1280x720 |
| 畫面證據 | 驗收畫面可完整解碼：07_animals_and_farm.png | 通過 | OK |
| 畫面證據 | 驗收畫面解析度正確：07_animals_and_farm.png | 通過 | 1280x720 |
| 畫面證據 | 驗收畫面可完整解碼：08_shop_purchase.png | 通過 | OK |
| 畫面證據 | 驗收畫面解析度正確：08_shop_purchase.png | 通過 | 1280x720 |
| 畫面證據 | 驗收畫面可完整解碼：09_village_dialogue.png | 通過 | OK |
| 畫面證據 | 驗收畫面解析度正確：09_village_dialogue.png | 通過 | 1280x720 |
| 畫面證據 | 驗收畫面可完整解碼：10_interactive_festival.png | 通過 | OK |
| 畫面證據 | 驗收畫面解析度正確：10_interactive_festival.png | 通過 | 1280x720 |
| 畫面證據 | 驗收畫面可完整解碼：11_status_inventory_menu.png | 通過 | OK |
| 畫面證據 | 驗收畫面解析度正確：11_status_inventory_menu.png | 通過 | 1280x720 |
| 畫面證據 | 驗收畫面可完整解碼：12_acceptance_complete.png | 通過 | OK |
| 畫面證據 | 驗收畫面解析度正確：12_acceptance_complete.png | 通過 | 1280x720 |
