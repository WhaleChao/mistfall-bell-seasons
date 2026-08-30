class_name PixelRPGInputBindings
extends RefCounted

const SETTINGS_PATH := "user://pixelrpg_input.json"
const PERSISTED_ACTIONS: Array[StringName] = [
	&"move_left", &"move_right", &"move_up", &"move_down",
	&"attack", &"dodge", &"active_skill", &"interact", &"use_potion",
	&"cycle_seed", &"sleep_day", &"time_speed", &"toggle_cave", &"attend_festival",
	&"pause_menu", &"multiplayer_menu", &"quick_save", &"quick_load",
]


static func rebind(action: StringName, event: InputEvent, replace_existing: bool = true) -> bool:
	if not InputMap.has_action(action) or event == null:
		return false
	if replace_existing:
		InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	return true


static func rebind_device(action: StringName, event: InputEvent) -> bool:
	if not InputMap.has_action(action) or event == null:
		return false
	var preserved: Array[InputEvent] = []
	for existing: InputEvent in InputMap.action_get_events(action):
		var same_device_family := (event is InputEventKey and existing is InputEventKey) or (event is InputEventJoypadButton and existing is InputEventJoypadButton) or (event is InputEventJoypadMotion and existing is InputEventJoypadMotion)
		if not same_device_family:
			preserved.append(existing)
	InputMap.action_erase_events(action)
	for existing: InputEvent in preserved:
		InputMap.action_add_event(action, existing)
	InputMap.action_add_event(action, event)
	return true


static func reset_to_project_defaults() -> void:
	InputMap.load_from_project_settings()


static func save() -> bool:
	var actions: Dictionary = {}
	for action: StringName in PERSISTED_ACTIONS:
		if not InputMap.has_action(action):
			continue
		var serialized: Array[Dictionary] = []
		for event: InputEvent in InputMap.action_get_events(action):
			var record := _serialize_event(event)
			if not record.is_empty():
				serialized.append(record)
		actions[String(action)] = serialized
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"schema_version": 1, "actions": actions}, "\t", false))
	return true


static func load_saved() -> bool:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return false
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or int(parsed.get("schema_version", 0)) != 1:
		return false
	for action_name: String in Dictionary(parsed.get("actions", {})):
		var action := StringName(action_name)
		if not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		for record: Dictionary in parsed["actions"][action_name]:
			var event := _deserialize_event(record)
			if event != null:
				InputMap.action_add_event(action, event)
	return true


static func _serialize_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {"type": "key", "physical_keycode": event.physical_keycode, "keycode": event.keycode}
	if event is InputEventJoypadButton:
		return {"type": "joy_button", "button_index": event.button_index}
	if event is InputEventJoypadMotion:
		return {"type": "joy_axis", "axis": event.axis, "axis_value": event.axis_value}
	return {}


static func _deserialize_event(record: Dictionary) -> InputEvent:
	match String(record.get("type", "")):
		"key":
			var key := InputEventKey.new()
			key.physical_keycode = int(record.get("physical_keycode", 0))
			key.keycode = int(record.get("keycode", 0))
			return key
		"joy_button":
			var button := InputEventJoypadButton.new()
			button.button_index = int(record.get("button_index", 0))
			return button
		"joy_axis":
			var motion := InputEventJoypadMotion.new()
			motion.axis = int(record.get("axis", 0))
			motion.axis_value = float(record.get("axis_value", 0.0))
			return motion
	return null
