class_name PixelRPGMapPortalDefinition
extends Resource

@export var portal_id: StringName
@export var source_map_id: StringName
@export var target_map_id: StringName
@export var reverse_portal_id: StringName
@export var position := Vector2.ZERO
@export var trigger_radius := 24.0
@export var target_spawn := Vector2.ZERO
@export var target_facing := Vector2.DOWN
@export var label := ""
@export var unlock_flag: StringName
@export_enum("interact", "auto") var transition_mode := "interact"


func is_unlocked(flags: Dictionary) -> bool:
	return unlock_flag.is_empty() or bool(flags.get(String(unlock_flag), false))
