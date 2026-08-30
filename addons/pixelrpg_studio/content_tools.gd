@tool
class_name PixelRPGContentTools
extends RefCounted

const TYPE_DIRECTORIES := {
	"角色": "characters", "敵人": "enemies", "物品": "items", "技能": "skills",
	"任務": "quests", "對話": "dialogues", "世界事件": "world_events"
	,"作物": "crops", "魚類": "fish", "動物": "animals", "NPC 排程": "npc_schedules"
	,"節慶": "festivals", "農場升級": "farm_upgrades", "洞窟": "dungeons"
	,"委託模板": "request_templates", "料理": "recipes"
}


static func read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()


static func write_text(path: String, value: String) -> bool:
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var temporary := absolute + ".pixelrpg.tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(value)
	file.close()
	if FileAccess.file_exists(absolute):
		DirAccess.remove_absolute(absolute)
	return DirAccess.rename_absolute(temporary, absolute) == OK


static func list_json(directory: String) -> PackedStringArray:
	var paths := PackedStringArray()
	var dir := DirAccess.open(directory)
	if dir == null:
		return paths
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			paths.append(directory.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()
	paths.sort()
	return paths


static func stable_id(value: String) -> String:
	var result := value.get_basename().to_snake_case().to_lower()
	var regex := RegEx.new()
	regex.compile("[^a-z0-9_]")
	result = regex.sub(result, "_", true).strip_edges().trim_prefix("_").trim_suffix("_")
	return "asset_%d" % int(Time.get_unix_time_from_system()) if result.is_empty() else result


static func artifact_directory(display_type: String) -> String:
	return String(TYPE_DIRECTORIES.get(display_type, "items"))


static func default_artifact(display_type: String) -> Dictionary:
	match display_type:
		"角色":
			return {"schema_version": 1, "id": "new_character", "display_name": "新角色", "portrait": "", "sprite": "", "faction": "neutral", "stats": {"max_health": 100, "attack": 10, "defense": 2, "move_speed": 100.0}, "lore_refs": []}
		"敵人":
			return {"schema_version": 1, "id": "new_enemy", "display_name": "新敵人", "sprite": "", "max_health": 40, "damage": 8, "move_speed": 50.0, "behavior": "melee", "is_boss": false, "drops": []}
		"技能":
			return {"schema_version": 1, "id": "new_skill", "display_name": "新技能", "description": "", "icon": "", "cooldown": 2.0, "power_multiplier": 1.0, "range": 32.0, "effects": []}
		"任務":
			return {"schema_version": 1, "id": "new_quest", "title": "新任務", "summary": "", "prerequisites": [], "objectives": [{"id": "step_1", "type": "talk", "target": "mira", "count": 1}], "rewards": [], "dialogue_refs": []}
		"對話":
			return {"schema_version": 1, "id": "new_dialogue", "title": "新對話", "start_node": "start", "characters": [], "nodes": [{"id": "start", "type": "line", "speaker": "", "text": "", "next": "end"}, {"id": "end", "type": "end"}]}
		"世界事件":
			return {"schema_version": 1, "id": "new_event", "trigger": {"type": "interact", "target": ""}, "conditions": [], "actions": [{"type": "set_flag", "flag": "new_flag", "value": true}], "once": true}
		"作物":
			return {"schema_version": 1, "id": "new_crop", "display_name": "新作物", "seasons": ["spring"], "growth_days": 5, "regrow_days": 0, "category": "fast", "seed_price": 20, "sell_price": 50, "color": "78dcca"}
		"魚類":
			return {"schema_version": 1, "id": "new_fish", "display_name": "新魚類", "seasons": ["spring"], "locations": ["river"], "hours": [6, 18], "weather": ["clear"], "sell_price": 100}
		"動物":
			return {"schema_version": 1, "id": "new_animal", "display_name": "新動物", "purchase_price": 1000, "product_id": "product", "product_interval_days": 1, "gestation_days": 10}
		"NPC 排程":
			return {"schema_version": 1, "id": "new_npc", "display_name": "新 NPC", "romance_candidate": false, "weekday": [{"from": 360, "to": 1440, "map": "village", "marker": "plaza"}]}
		"節慶":
			return {"schema_version": 1, "id": "new_festival", "display_name": "新節慶", "season": "spring", "day": 8, "start_minute": 600, "end_minute": 1080, "map": "village", "participation_reward": 100, "year_variants": ["第一年", "第二年", "第三年"]}
		"農場升級":
			return {"schema_version": 1, "id": "farm_rank_2", "display_name": "新升級", "rank": 2, "cost": 1000, "materials": {}, "unlocks": []}
		"洞窟":
			return {"schema_version": 1, "id": "new_dungeon", "display_name": "新洞窟", "max_floor": 40, "boss_floors": [10, 20, 30, 40], "elevator_interval": 5, "season_zones": [], "enemy_ids": [], "seal_ids": ["spring_seal", "summer_seal", "autumn_seal", "winter_seal"]}
		"委託模板":
			return {"schema_version": 1, "id": "new_request", "display_name": "新委託", "type": "delivery", "target_pool": ["crop"], "count_range": [1, 3], "reward_range": [100, 300], "duration_days": 3}
		"料理":
			return {"schema_version": 1, "id": "new_recipe", "display_name": "新料理", "season": "spring", "ingredients": {"spring_turnip": 1}, "energy": 20}
		_:
			return {"schema_version": 1, "id": "new_item", "display_name": "新物品", "icon": "", "category": "material", "description": "", "stack_limit": 99, "effects": [], "obtain_conditions": []}
