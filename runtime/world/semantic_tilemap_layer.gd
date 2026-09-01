class_name PixelRPGSemanticTileMapLayer
extends TileMapLayer

## Non-rendering TileMapLayer that is the public semantic query surface for a map.
## Visual art is deliberately independent from navigation meaning: callers ask
## this layer whether a foot position is walkable instead of inferring movement
## from transparent pixels in the background painting.

@export var map_id: StringName


func _ready() -> void:
	visible = false
	set_meta("semantic_types", PixelRPGWorldMapCatalog.definition(map_id).semantic_layers)


func semantic_at(world_position: Vector2) -> StringName:
	return PixelRPGWorldMapCatalog.semantic_at(map_id, world_position)


func is_walkable(world_position: Vector2) -> bool:
	return semantic_at(world_position) in [&"walkable", &"bridge", &"door", &"portal", &"interaction"]
