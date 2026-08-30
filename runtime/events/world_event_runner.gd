class_name PixelRPGWorldEventRunner
extends RefCounted

const ALLOWED_ACTIONS := [
	"dialogue", "set_flag", "quest", "give_item", "take_item", "change_map",
	"spawn_actor", "remove_actor", "animation", "sound", "cutscene"
]


func validate_event(event: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if int(event.get("schema_version", 0)) != 1:
		errors.append("不支援的 WorldEvent schema_version")
	if String(event.get("id", "")).is_empty():
		errors.append("WorldEvent 缺少 id")
	if not event.get("actions", null) is Array:
		errors.append("WorldEvent.actions 必須是陣列")
		return errors
	for action: Variant in event["actions"]:
		if not action is Dictionary:
			errors.append("事件動作必須是物件")
			continue
		var action_type := String(action.get("type", ""))
		if action_type not in ALLOWED_ACTIONS:
			errors.append("不允許的事件動作：%s" % action_type)
	return errors


func conditions_met(conditions: Array) -> bool:
	for raw_condition: Variant in conditions:
		if not raw_condition is Dictionary:
			return false
		var condition := raw_condition as Dictionary
		match String(condition.get("type", "")):
			"flag_equals":
				if GameState.get_flag(StringName(condition.get("flag", ""))) != bool(condition.get("value", true)):
					return false
			"quest_state":
				var quest_id := String(condition.get("quest_id", ""))
				if String(GameState.quest_states.get(quest_id, "inactive")) != String(condition.get("state", "active")):
					return false
			"has_item":
				var item_id := String(condition.get("item_id", ""))
				if int(GameState.inventory.get(item_id, 0)) < int(condition.get("count", 1)):
					return false
			_:
				return false
	return true


func execute(event: Dictionary) -> PackedStringArray:
	var errors := validate_event(event)
	if not errors.is_empty():
		return errors
	if bool(event.get("once", false)) and GameState.get_flag(StringName("event_done_%s" % event["id"])):
		return errors
	if not conditions_met(event.get("conditions", [])):
		return errors
	for action: Dictionary in event["actions"]:
		_execute_action(action)
	if bool(event.get("once", false)):
		GameState.set_flag(StringName("event_done_%s" % event["id"]), true)
	return errors


func _execute_action(action: Dictionary) -> void:
	match String(action.get("type", "")):
		"dialogue":
			DialogueAdapter.start_dialogue(StringName(action.get("dialogue_id", "")), StringName(action.get("start_node", "")))
		"set_flag":
			GameState.set_flag(StringName(action.get("flag", "")), bool(action.get("value", true)))
		"quest":
			QuestAdapter.set_state(StringName(action.get("quest_id", "")), StringName(action.get("state", "active")))
		"give_item":
			InventoryAdapter.add_item(StringName(action.get("item_id", "")), int(action.get("count", 1)))
		"take_item":
			InventoryAdapter.remove_item(StringName(action.get("item_id", "")), int(action.get("count", 1)))
		"change_map":
			EventBus.map_change_requested.emit(StringName(action.get("map_id", "")), StringName(action.get("spawn_id", "default")))
		"spawn_actor":
			EventBus.actor_spawn_requested.emit(StringName(action.get("actor_id", "")), StringName(action.get("marker_id", "")))
		"remove_actor":
			EventBus.actor_remove_requested.emit(StringName(action.get("actor_id", "")))
		"animation":
			EventBus.animation_requested.emit(StringName(action.get("target_id", "")), StringName(action.get("animation_id", "")))
		"sound":
			EventBus.sound_requested.emit(StringName(action.get("sound_id", "")))
		"cutscene":
			EventBus.cutscene_requested.emit(StringName(action.get("cutscene_id", "")))
