class_name PixelRPGWorldMapDefinition
extends Resource

@export var map_id: StringName
@export var mode: StringName
@export var display_name := ""
@export_file("*.tscn") var scene_path := ""
@export_file("*.png") var background_path := ""
@export var logical_bounds := Rect2(20, 54, 600, 284)
@export var safe_spawn := Vector2(320, 180)
@export var required_targets: Array[StringName] = []
@export var semantic_layers: PackedStringArray = PackedStringArray([
	"walkable", "blocked", "water", "bridge", "door", "portal",
	"interaction", "spawn_forbidden",
])


func is_interior() -> bool:
	return mode in [&"farmhouse", &"barn", &"greenhouse"]
