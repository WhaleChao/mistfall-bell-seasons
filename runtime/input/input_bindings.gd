class_name PixelRPGInputBindings
extends RefCounted

const SETTINGS_PATH := "user://pixelrpg_input.json"
const SCHEMA_VERSION := 1
const KEYBOARD_DEVICE_ID := InputEvent.DEVICE_ID_KEYBOARD
const MIN_DEVICE_ID := -3
const MAX_DEVICE_ID := 16
const MAX_JOYPAD_BUTTONS := 128
const MAX_JOYPAD_AXES := 10
const MAX_KEY_CODE := 0x7fffffff
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
	return _save_to_path(SETTINGS_PATH)


static func _save_to_path(path: String) -> bool:
	var actions: Dictionary = {}
	for action: StringName in PERSISTED_ACTIONS:
		if not InputMap.has_action(action):
			continue
		var serialized: Array[Dictionary] = []
		for event: InputEvent in InputMap.action_get_events(action):
			var record := _serialize_event(event)
			if record.is_empty():
				return false
			serialized.append(record)
		if serialized.is_empty():
			return false
		actions[String(action)] = serialized
	var payload := {"schema_version": SCHEMA_VERSION, "actions": actions}
	var validated_actions: Dictionary = {}
	if not _build_candidate_actions(payload, validated_actions):
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload, "\t", false))
	file.close()
	return true


static func load_saved() -> bool:
	return _load_from_path(SETTINGS_PATH)


static func _load_from_path(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	var candidate_actions: Dictionary = {}
	if not _load_candidates_from_file(file, candidate_actions):
		return false
	_apply_candidate_actions(candidate_actions)
	return true


static func _load_candidates_from_file(file: FileAccess, candidate_actions: Dictionary) -> bool:
	if file == null:
		return false
	var parser := JSON.new()
	var error := parser.parse(file.get_as_text())
	file.close()
	if error != OK:
		return false
	return _build_candidate_actions(parser.data, candidate_actions)


static func _build_candidate_actions(parsed: Variant, candidate_actions: Dictionary) -> bool:
	candidate_actions.clear()
	if not parsed is Dictionary:
		return false
	var schema_version: Variant = parsed.get("schema_version")
	if not _is_integer_in_range(schema_version, SCHEMA_VERSION, SCHEMA_VERSION):
		return false
	var raw_actions: Variant = parsed.get("actions")
	if not raw_actions is Dictionary:
		return false
	var expected_action_count := 0
	var validated_actions: Dictionary = {}
	for action: StringName in PERSISTED_ACTIONS:
		if not InputMap.has_action(action):
			continue
		expected_action_count += 1
		var action_name := String(action)
		if not raw_actions.has(action_name):
			return false
		var raw_events: Variant = raw_actions[action_name]
		if not raw_events is Array or raw_events.is_empty():
			return false
		var events: Array[InputEvent] = []
		for raw_record: Variant in raw_events:
			if not raw_record is Dictionary:
				return false
			var event := _deserialize_event(raw_record)
			if event == null:
				return false
			events.append(event)
		validated_actions[action_name] = events
	if expected_action_count == 0 or validated_actions.size() != expected_action_count:
		return false
	candidate_actions.merge(validated_actions, true)
	return true


static func _apply_candidate_actions(candidate_actions: Dictionary) -> void:
	# Candidate mappings are fully validated before this function mutates InputMap.
	for action_name: String in candidate_actions:
		var action := StringName(action_name)
		InputMap.action_erase_events(action)
		for event: InputEvent in candidate_actions[action_name]:
			InputMap.action_add_event(action, event)


static func _serialize_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {
			"type": "key",
			"device": event.device,
			"physical_keycode": event.physical_keycode,
			"keycode": event.keycode,
			"key_label": event.key_label,
			"location": event.location,
			"alt_pressed": event.alt_pressed,
			"shift_pressed": event.shift_pressed,
			"ctrl_pressed": event.ctrl_pressed,
			"meta_pressed": event.meta_pressed,
		}
	if event is InputEventJoypadButton:
		return {"type": "joy_button", "device": event.device, "button_index": event.button_index}
	if event is InputEventJoypadMotion:
		return {"type": "joy_axis", "device": event.device, "axis": event.axis, "axis_value": event.axis_value}
	return {}


static func _deserialize_event(record: Dictionary) -> InputEvent:
	var event_type: Variant = record.get("type")
	if not event_type is String:
		return null
	match event_type:
		"key":
			var physical_keycode: Variant = record.get("physical_keycode", 0)
			var keycode: Variant = record.get("keycode", 0)
			var key_label: Variant = record.get("key_label", 0)
			var location: Variant = record.get("location", 0)
			var device: Variant = record.get("device", KEYBOARD_DEVICE_ID)
			if not _is_nonnegative_integer(physical_keycode) or not _is_nonnegative_integer(keycode) or not _is_nonnegative_integer(key_label):
				return null
			if int(physical_keycode) == 0 and int(keycode) == 0 and int(key_label) == 0:
				return null
			if not _is_integer_in_range(location, 0, 2) or not _is_integer_in_range(device, MIN_DEVICE_ID, MAX_DEVICE_ID):
				return null
			for modifier_name: String in ["alt_pressed", "shift_pressed", "ctrl_pressed", "meta_pressed"]:
				if record.has(modifier_name) and not record[modifier_name] is bool:
					return null
			var key := InputEventKey.new()
			key.device = int(device)
			key.physical_keycode = int(physical_keycode)
			key.keycode = int(keycode)
			key.key_label = int(key_label)
			key.location = int(location)
			key.alt_pressed = bool(record.get("alt_pressed", false))
			key.shift_pressed = bool(record.get("shift_pressed", false))
			key.ctrl_pressed = bool(record.get("ctrl_pressed", false))
			key.meta_pressed = bool(record.get("meta_pressed", false))
			return key
		"joy_button":
			var button_index: Variant = record.get("button_index")
			var device: Variant = record.get("device", 0)
			if not _is_integer_in_range(button_index, 0, MAX_JOYPAD_BUTTONS - 1) or not _is_integer_in_range(device, MIN_DEVICE_ID, MAX_DEVICE_ID):
				return null
			var button := InputEventJoypadButton.new()
			button.device = int(device)
			button.button_index = int(button_index)
			return button
		"joy_axis":
			var axis: Variant = record.get("axis")
			var axis_value: Variant = record.get("axis_value")
			var device: Variant = record.get("device", 0)
			if not _is_integer_in_range(axis, 0, MAX_JOYPAD_AXES - 1) or not _is_finite_number(axis_value) or not _is_integer_in_range(device, MIN_DEVICE_ID, MAX_DEVICE_ID):
				return null
			var normalized_axis_value := float(axis_value)
			if is_zero_approx(normalized_axis_value) or absf(normalized_axis_value) > 1.0:
				return null
			var motion := InputEventJoypadMotion.new()
			motion.device = int(device)
			motion.axis = int(axis)
			motion.axis_value = normalized_axis_value
			return motion
	return null


static func _is_integer_number(value: Variant) -> bool:
	if not value is int and not value is float:
		return false
	var number := float(value)
	return not is_nan(number) and not is_inf(number) and number == floorf(number)


static func _is_nonnegative_integer(value: Variant) -> bool:
	return _is_integer_in_range(value, 0, MAX_KEY_CODE)


static func _is_integer_in_range(value: Variant, minimum: int, maximum: int) -> bool:
	if not _is_integer_number(value):
		return false
	var number := float(value)
	return number >= float(minimum) and number <= float(maximum)


static func _is_finite_number(value: Variant) -> bool:
	if not value is int and not value is float:
		return false
	var number := float(value)
	return not is_nan(number) and not is_inf(number)
