class_name PixelRPGItemIconFactory
extends RefCounted

const ICON_SIZE := 64
const ICON_ROOT := "res://assets/runtime/icons"

static var _texture_cache: Dictionary = {}


static func texture_for(item_id: StringName, requested_kind: StringName = &"auto", pixel_size: int = ICON_SIZE) -> Texture2D:
	var id := String(item_id)
	var resolved := _resolve(id, String(requested_kind))
	var kind := String(resolved.kind)
	var resolved_size := clampi(pixel_size, 16, 128)
	var cache_key := "%s:%s:%d" % [kind, id, resolved_size]
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]
	var path := "%s/%s/%s.png" % [ICON_ROOT, kind, id]
	if not ResourceLoader.exists(path):
		push_error("Missing required visual ID %s/%s (%s)" % [kind, id, path])
		return null
	var source := load(path) as Texture2D
	if source == null:
		push_error("Required visual ID could not be loaded: %s" % path)
		return null
	var texture: Texture2D = source
	if resolved_size != ICON_SIZE:
		var image := source.get_image()
		image.resize(resolved_size, resolved_size, Image.INTERPOLATE_NEAREST)
		texture = ImageTexture.create_from_image(image)
	_texture_cache[cache_key] = texture
	return texture


static func visual_path_for(item_id: StringName, requested_kind: StringName = &"auto") -> String:
	var resolved := _resolve(String(item_id), String(requested_kind))
	return "%s/%s/%s.png" % [ICON_ROOT, resolved.kind, item_id]


static func display_name_for(item_id: StringName) -> String:
	var id := String(item_id)
	for artifact_type in ["items", "crops", "fish", "recipes", "animals", "tools", "automation_devices"]:
		var definition := _artifact(artifact_type, item_id)
		if not definition.is_empty():
			return String(definition.get("display_name", id))
	return id.replace("_", " ")


static func description_for(item_id: StringName) -> String:
	for artifact_type in ["items", "crops", "fish", "recipes", "animals", "tools", "automation_devices"]:
		var definition := _artifact(artifact_type, item_id)
		if not definition.is_empty():
			return String(definition.get("description", definition.get("lore", "")))
	return ""


static func _resolve(id: String, requested_kind: String) -> Dictionary:
	var kind := requested_kind
	var definition: Dictionary = {}
	if kind == "seed":
		definition = _artifact("crops", StringName(id))
	elif kind in ["crop", "produce"]:
		definition = _artifact("crops", StringName(id))
		kind = "crop"
	elif kind == "fish":
		definition = _artifact("fish", StringName(id))
	elif kind in ["dish", "recipe"]:
		definition = _artifact("recipes", StringName(id))
		kind = "dish"
	elif kind == "animal":
		definition = _artifact("animals", StringName(id))
	elif kind == "tool":
		definition = _artifact("tools", StringName(id))
	elif kind in ["automation", "device"]:
		definition = _artifact("automation_devices", StringName(id))
		kind = "automation"
	elif kind in ["item", "world_item"]:
		definition = _artifact("items", StringName(id))
		kind = "item"
	else:
		for candidate: Dictionary in [
			{"type":"items", "kind":"item"}, {"type":"crops", "kind":"crop"},
			{"type":"fish", "kind":"fish"}, {"type":"recipes", "kind":"dish"},
			{"type":"animals", "kind":"animal"}, {"type":"tools", "kind":"tool"},
			{"type":"automation_devices", "kind":"automation"},
		]:
			definition = _artifact(String(candidate.type), StringName(id))
			if not definition.is_empty():
				kind = String(candidate.kind)
				break
	if kind in ["", "auto"]:
		kind = "item"
	return {"kind":kind, "definition":definition}


static func _artifact(artifact_type: String, item_id: StringName) -> Dictionary:
	var scene_tree := Engine.get_main_loop() as SceneTree
	if scene_tree == null:
		return {}
	var registry := scene_tree.root.get_node_or_null("ContentRegistry")
	if registry == null or not registry.has_method("get_artifact"):
		return {}
	return Dictionary(registry.call("get_artifact", artifact_type, item_id))
