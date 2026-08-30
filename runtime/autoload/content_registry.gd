extends Node

const CONTENT_DIRECTORIES := {
	"characters": "res://data/characters",
	"enemies": "res://data/enemies",
	"items": "res://data/items",
	"skills": "res://data/skills",
	"sprites": "res://data/sprites",
	"quests": "res://data/quests",
	"dialogues": "res://data/dialogues",
	"world_events": "res://data/world_events",
	"seasons": "res://data/seasons",
	"crops": "res://data/crops",
	"fish": "res://data/fish",
	"animals": "res://data/animals",
	"npc_schedules": "res://data/npc_schedules",
	"npc_dialogues": "res://data/npc_dialogues",
	"festivals": "res://data/festivals",
	"farm_upgrades": "res://data/farm_upgrades",
	"dungeons": "res://data/dungeons",
	"request_templates": "res://data/request_templates",
	"recipes": "res://data/recipes",
	"story_arcs": "res://data/story_arcs",
	"relationship_events": "res://data/relationship_events",
	"tools": "res://data/tools",
	"shops": "res://data/shops",
	"achievements": "res://data/achievements",
}

var content: Dictionary = {}
var errors: PackedStringArray = []


func _ready() -> void:
	reload_all()


func reload_all() -> bool:
	content.clear()
	errors.clear()
	for artifact_type: String in CONTENT_DIRECTORIES:
		content[artifact_type] = {}
		_load_directory(artifact_type, CONTENT_DIRECTORIES[artifact_type])
	return errors.is_empty()


func get_artifact(artifact_type: String, artifact_id: StringName) -> Dictionary:
	return Dictionary(content.get(artifact_type, {})).get(String(artifact_id), {})


func get_all(artifact_type: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value: Variant in Dictionary(content.get(artifact_type, {})).values():
		result.append(Dictionary(value))
	return result


func validate_references() -> PackedStringArray:
	var reference_errors := PackedStringArray()
	for quest: Dictionary in get_all("quests"):
		for reward: Dictionary in quest.get("rewards", []):
			var item_id := String(reward.get("id", "")) if reward.get("type") == "item" else ""
			if not item_id.is_empty() and get_artifact("items", item_id).is_empty():
				reference_errors.append("Quest %s references missing item %s" % [quest.get("id"), item_id])
		for dialogue_id: String in quest.get("dialogue_refs", []):
			if get_artifact("dialogues", dialogue_id).is_empty():
				reference_errors.append("Quest %s references missing dialogue %s" % [quest.get("id"), dialogue_id])
	for enemy: Dictionary in get_all("enemies"):
		for drop: Dictionary in enemy.get("drops", []):
			var item_id := String(drop.get("item_id", ""))
			if not item_id.is_empty() and get_artifact("items", item_id).is_empty():
				reference_errors.append("Enemy %s references missing item %s" % [enemy.get("id"), item_id])
	for event: Dictionary in get_all("world_events"):
		for action: Dictionary in event.get("actions", []):
			if action.get("type") == "dialogue":
				var dialogue_id := String(action.get("dialogue_id", ""))
				if get_artifact("dialogues", dialogue_id).is_empty():
					reference_errors.append("World event %s references missing dialogue %s" % [event.get("id"), dialogue_id])
	return reference_errors


func _load_directory(artifact_type: String, directory_path: String) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return
	directory.list_dir_begin()
	var file_name := directory.get_next()
	while not file_name.is_empty():
		if not directory.current_is_dir() and file_name.ends_with(".json"):
			_load_file(artifact_type, directory_path.path_join(file_name))
		file_name = directory.get_next()
	directory.list_dir_end()


func _load_file(artifact_type: String, path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("Cannot read %s" % path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		errors.append("Invalid JSON object: %s" % path)
		return
	var document := Dictionary(parsed)
	if document.has("definitions"):
		if int(document.get("schema_version", 0)) < 1:
			errors.append("Missing schema_version: %s" % path)
			return
		for definition: Dictionary in document.get("definitions", []):
			var definition_id := String(definition.get("id", ""))
			if definition_id.is_empty():
				errors.append("Missing catalog definition id: %s" % path)
			elif content[artifact_type].has(definition_id):
				errors.append("Duplicate %s id %s" % [artifact_type, definition_id])
			else:
				content[artifact_type][definition_id] = definition
		return
	var artifact_id := String(document.get("id", ""))
	if artifact_id.is_empty():
		errors.append("Missing id: %s" % path)
		return
	if int(document.get("schema_version", 0)) < 1:
		errors.append("Missing schema_version: %s" % path)
		return
	content[artifact_type][artifact_id] = document
