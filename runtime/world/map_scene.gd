class_name PixelRPGMapScene
extends Node2D

@export var map_id: StringName
@export_file("*.png") var background_path := ""

var semantic_layer: PixelRPGSemanticTileMapLayer


func _ready() -> void:
	semantic_layer = get_node_or_null("SemanticLayer") as PixelRPGSemanticTileMapLayer
	if semantic_layer == null:
		semantic_layer = PixelRPGSemanticTileMapLayer.new()
		semantic_layer.name = "SemanticLayer"
		semantic_layer.map_id = map_id
		add_child(semantic_layer)


func definition() -> PixelRPGWorldMapDefinition:
	return PixelRPGWorldMapCatalog.definition(map_id)


func semantic_at(world_position: Vector2) -> StringName:
	if is_instance_valid(semantic_layer):
		return semantic_layer.semantic_at(world_position)
	return PixelRPGWorldMapCatalog.semantic_at(map_id, world_position)
