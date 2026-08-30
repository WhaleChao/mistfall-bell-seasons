class_name InventoryAdapter
extends RefCounted


static func is_external_plugin_available() -> bool:
	return Engine.has_singleton("GLoot")


static func add_item(item_id: StringName, count: int = 1) -> void:
	GameState.add_item(item_id, count)


static func remove_item(item_id: StringName, count: int = 1) -> bool:
	return GameState.consume_item(item_id, count)


static func get_count(item_id: StringName) -> int:
	return int(GameState.inventory.get(String(item_id), 0))
