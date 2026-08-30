class_name DialogueAdapter
extends RefCounted


static func is_external_plugin_available() -> bool:
	return Engine.has_singleton("DialogueManager")


static func start_dialogue(dialogue_id: StringName, start_node: StringName = &"") -> void:
	# The stable fallback event keeps the game functional without the optional add-on.
	EventBus.dialogue_requested.emit(dialogue_id, start_node)
