class_name PixelRPGActorVisualProfile
extends Resource

@export var profile_id: StringName
@export var foot_anchor := Vector2(0, 4)
@export var collision_size := Vector2(14, 19)
@export var y_sort_origin := 4
@export var idle_animation: StringName = &"idle"
@export var walk_animation: StringName = &"walk"
@export var attack_animation: StringName = &"attack"
@export var direction_rows := {
	"down": 0,
	"left": 1,
	"right": 2,
	"up": 3,
}
