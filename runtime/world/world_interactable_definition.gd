class_name PixelRPGWorldInteractableDefinition
extends Resource

@export var object_id: StringName
@export var visual_id: StringName
@export var map_id: StringName
@export var position := Vector2.ZERO
@export var interaction_radius := 32.0
@export var prompt_action := "互動"
@export var prompt_title := ""
@export var action_id: StringName
@export var required_flag: StringName


func is_available(flags: Dictionary) -> bool:
	return required_flag.is_empty() or bool(flags.get(String(required_flag), false))
