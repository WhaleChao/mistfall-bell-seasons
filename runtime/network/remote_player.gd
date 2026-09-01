class_name PixelRPGRemotePlayer
extends Node2D

var peer_id := 0
var player_name := "旅人"
var target_position := Vector2.ZERO
var facing := Vector2.DOWN
var visual_sprite: Sprite2D
var visual_region: AtlasTexture
var name_label: Label


func configure(id: int, display_name: String, initial_position: Vector2) -> void:
	peer_id = id
	player_name = display_name
	target_position = initial_position
	global_position = initial_position
	name = "RemotePlayer_%d" % id


func _ready() -> void:
	_update_depth_order()
	var atlas: Texture2D = load("res://assets/runtime/sprites/player_walk_atlas_final.png")
	if atlas != null:
		visual_region = AtlasTexture.new()
		visual_region.atlas = atlas
		visual_region.region = Rect2(0, 0, atlas.get_width() / 4.0, atlas.get_height() / 4.0)
		visual_sprite = Sprite2D.new()
		visual_sprite.texture = visual_region
		visual_sprite.scale = Vector2.ONE
		visual_sprite.position = Vector2(0, -12)
		visual_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(visual_sprite)
	name_label = Label.new()
	name_label.text = player_name
	name_label.position = Vector2(-45, -39)
	name_label.size = Vector2(90, 16)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", Color("9de7ff"))
	add_child(name_label)


func apply_snapshot(state: Dictionary) -> void:
	target_position = _array_to_vector(state.get("position", [global_position.x, global_position.y]))
	var new_facing := _array_to_vector(state.get("facing", [facing.x, facing.y]))
	if new_facing.length_squared() > 0.01:
		facing = new_facing.normalized()
	var updated_name := String(state.get("name", player_name))
	if updated_name != player_name:
		player_name = updated_name
		if is_instance_valid(name_label):
			name_label.text = player_name
	visible = String(state.get("map", "mistfall_farm")) == String(GameState.current_map_id)


func _process(delta: float) -> void:
	global_position = global_position.lerp(target_position, clampf(delta * 12.0, 0.0, 1.0))
	_update_depth_order()
	if not is_instance_valid(visual_region):
		return
	var row := 0
	if absf(facing.x) > absf(facing.y):
		row = 2 if facing.x > 0.0 else 1
	else:
		row = 0 if facing.y > 0.0 else 3
	var moving := global_position.distance_to(target_position) > 0.8
	var frame := int(Time.get_ticks_msec() / 110) % 4 if moving else 0
	var atlas := visual_region.atlas
	visual_region.region = Rect2(frame * atlas.get_width() / 4.0, row * atlas.get_height() / 4.0, atlas.get_width() / 4.0, atlas.get_height() / 4.0)


func _draw() -> void:
	draw_set_transform(Vector2(0, 4.5), 0.0, Vector2(1.0, 0.34))
	draw_circle(Vector2.ZERO, 9.0, Color(0.02, 0.03, 0.04, 0.42))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _update_depth_order() -> void:
	z_index = 100 + clampi(roundi(global_position.y), 0, 360)


func _array_to_vector(value: Variant) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO
