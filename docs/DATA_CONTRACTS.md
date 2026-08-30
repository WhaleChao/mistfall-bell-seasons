# 資料契約速查

| 類型 | 目錄 | Schema | 主要引用 |
|---|---|---|---|
| ProjectManifest | `data/project_manifest.json` | `project_manifest.schema.json` | 起始地圖、依賴版本 |
| AssetRecord | `data/assets/index.json` | `asset_record.schema.json` | 角色／地圖／任務 ID |
| CharacterDefinition | `data/characters/` | `character_definition.schema.json` | lore、圖像 |
| EnemyDefinition | `data/enemies/` | `enemy_definition.schema.json` | 掉落物品 |
| ItemDefinition | `data/items/` | `item_definition.schema.json` | 效果與取得條件 |
| SkillDefinition | `data/skills/` | `skill_definition.schema.json` | 效果 |
| SpriteImportDefinition | `data/sprites/` | `sprite_import.schema.json` | 來源素材、runtime texture、動畫列 |
| QuestDefinition | `data/quests/` | `quest_definition.schema.json` | 物品、對話 |
| DialogueGraph | `data/dialogues/` | `dialogue_graph.schema.json` | 角色、節點跳轉 |
| WorldEvent | `data/world_events/` | `world_event.schema.json` | 對話、任務、物品 |
| SeasonDefinition | `data/seasons/` | `season_definition.schema.json` | 30 日與天氣權重 |
| CropDefinition | `data/crops/` | `crop_definition.schema.json` | 季節、成長、再生、價格 |
| FishDefinition | `data/fish/` | `fish_definition.schema.json` | 季節、時段、天氣、地點 |
| AnimalDefinition | `data/animals/` | `animal_definition.schema.json` | 產物與繁殖日數 |
| NPCSchedule | `data/npc_schedules/` | `npc_schedule.schema.json` | 時段、天氣、地圖標記 |
| FestivalDefinition | `data/festivals/` | `festival_definition.schema.json` | 季節 8／18／28 日 |
| FarmUpgrade | `data/farm_upgrades/` | `farm_upgrade.schema.json` | 農場 Lv.1–10 解鎖 |
| DungeonDefinition | `data/dungeons/` | `dungeon_definition.schema.json` | 40 層、Boss、電梯、封印 |
| ProceduralRequestTemplate | `data/request_templates/` | `procedural_request_template.schema.json` | 第 4 年後規則式委託 |
| StoryArcDefinition | `data/story_arcs/` | `story_arc_definition.schema.json` | 無期限三年主線 |
| RelationshipEventDefinition | `data/relationship_events/` | `relationship_event_definition.schema.json` | 四候選的心事件 |
| SaveGame v3 | `user://pixelrpg_quick_save.json` | `save_game.schema.json` | 日曆、農場、家庭、洞窟、故事、工具、經濟、成就與設定 |

共同規則：`schema_version` 必須存在；`id` 符合 `^[a-z][a-z0-9_]*$`；正式內容不得以檔名或顯示名稱作引用。AI、表單與手工修改最後都走相同 schema 驗證。

WorldEvent 的可執行動作固定為：`dialogue`、`set_flag`、`quest`、`give_item`、`take_item`、`change_map`、`spawn_actor`、`remove_actor`、`animation`、`sound`、`cutscene`。未知動作會被 runtime 拒絕。

同類內容可用單筆 JSON，或以 `{ "schema_version": 1, "definitions": [...] }` 保存為 catalog；ContentRegistry 與 Python 驗證器會展開成相同的穩定 ID 索引。SaveGame v1 由 Runtime 遷移至 v2，原 28 日制日期保留季節與日數，不做比例換算。
