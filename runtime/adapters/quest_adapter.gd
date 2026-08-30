class_name QuestAdapter
extends RefCounted


static func is_external_plugin_available() -> bool:
	return Engine.has_singleton("QuestSystem")


static func set_state(quest_id: StringName, state: StringName) -> void:
	GameState.set_quest_state(quest_id, state)


static func get_state(quest_id: StringName) -> StringName:
	return StringName(GameState.quest_states.get(String(quest_id), "inactive"))
