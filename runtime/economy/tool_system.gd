class_name PixelRPGToolSystem
extends RefCounted

const MAX_STAMINA := 100

var stamina := MAX_STAMINA
var tool_levels: Dictionary = {"hoe": 1, "watering_can": 1, "axe": 1, "pickaxe": 1, "fishing_rod": 1, "sickle": 1}
var equipped_tool := "hoe"


func reset() -> void:
	stamina = MAX_STAMINA
	tool_levels = {"hoe": 1, "watering_can": 1, "axe": 1, "pickaxe": 1, "fishing_rod": 1, "sickle": 1}
	equipped_tool = "hoe"


func cost_for(action: String) -> int:
	var tool_id := _tool_for_action(action)
	if tool_id.is_empty():
		return 0
	var definition := ContentRegistry.get_artifact("tools", tool_id)
	var base_cost := int(definition.get("base_stamina", 1))
	var level := clampi(int(tool_levels.get(tool_id, 1)), 1, 4)
	return maxi(1, base_cost - (level - 1))


func use_for(action: String) -> bool:
	var cost := cost_for(action)
	if stamina < cost:
		return false
	stamina -= cost
	return true


func upgrade(tool_id: String) -> Dictionary:
	if not tool_levels.has(tool_id):
		return {"ok": false, "message": "找不到工具"}
	var current := int(tool_levels[tool_id])
	if current >= 4:
		return {"ok": false, "message": "工具已達最高等級"}
	tool_levels[tool_id] = current + 1
	return {"ok": true, "level": current + 1, "message": "%s升級至 %d 級" % [ContentRegistry.get_artifact("tools", tool_id).get("display_name", tool_id), current + 1]}


func restore_for_new_day() -> void:
	stamina = MAX_STAMINA


func to_data() -> Dictionary:
	return {"stamina": stamina, "tool_levels": tool_levels.duplicate(true), "equipped_tool": equipped_tool}


func load_data(data: Dictionary) -> void:
	stamina = clampi(int(data.get("stamina", MAX_STAMINA)), 0, MAX_STAMINA)
	tool_levels = Dictionary(data.get("tool_levels", tool_levels)).duplicate(true)
	equipped_tool = String(data.get("equipped_tool", "hoe"))


func _tool_for_action(action: String) -> String:
	return {"tilled": "hoe", "watered": "watering_can", "cleared": "sickle", "harvested": "sickle", "fishing": "fishing_rod", "mining": "pickaxe", "chopping": "axe"}.get(action, "")
