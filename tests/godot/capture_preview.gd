extends SceneTree

const OUTPUT_DIRECTORY := "res://screenshots"


func _initialize() -> void:
	call_deferred("_capture_all")


func _capture_all() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY))
	await _capture_map(&"mistfall_farm", Vector2(330, 250), "commercial_farm.png")
	await _capture_map(&"mistfall_village", Vector2(330, 250), "commercial_village.png")
	await _capture_map(&"mistfall_depths", Vector2(84, 285), "commercial_dungeon.png")
	await _capture_menu()
	await _capture_festival()
	await _capture_dialogue()
	quit(0)


func _capture_map(map_id: StringName, position: Vector2, file_name: String) -> void:
	var state_store: Node = root.get_node("GameState")
	state_store.reset()
	state_store.set_flag(&"title_seen", true)
	state_store.current_map_id = map_id
	state_store.player_position = position
	if map_id == &"mistfall_farm":
		state_store.farm.rank = 4
		state_store.farm.purchase_animal("chicken")
		state_store.farm.purchase_animal("cow")
	if map_id == &"mistfall_depths":
		state_store.dungeon.current_floor = 20
	var scene: Node = load("res://sample/main.tscn").instantiate()
	root.add_child(scene)
	for _frame in range(8):
		await process_frame
	var image: Image = root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUTPUT_DIRECTORY.path_join(file_name)))
	scene.queue_free()
	await process_frame


func _capture_festival() -> void:
	var state_store: Node = root.get_node("GameState")
	state_store.reset()
	state_store.set_flag(&"title_seen", true)
	state_store.calendar.day = 8
	state_store.current_map_id = &"mistfall_farm"
	var scene: Node = load("res://sample/main.tscn").instantiate()
	root.add_child(scene)
	for _frame in range(4):
		await process_frame
	var overlay: CanvasLayer = scene.get("festival_overlay")
	overlay.open_today()
	for _frame in range(4):
		await process_frame
	var image: Image = root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUTPUT_DIRECTORY.path_join("commercial_festival.png")))
	overlay.close()
	scene.queue_free()
	await process_frame


func _capture_dialogue() -> void:
	var state_store: Node = root.get_node("GameState")
	state_store.reset()
	state_store.set_flag(&"title_seen", true)
	state_store.current_map_id = &"mistfall_village"
	var scene: Node = load("res://sample/main.tscn").instantiate()
	root.add_child(scene)
	for _frame in range(4):
		await process_frame
	var overlay: CanvasLayer = scene.get("dialogue_overlay")
	overlay.open_line(&"mira", "霧不是沒有路，只是要走近一點才看得見彼此。", "米拉・雨日對話")
	for _frame in range(4):
		await process_frame
	var image: Image = root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUTPUT_DIRECTORY.path_join("commercial_dialogue.png")))
	overlay.close()
	scene.queue_free()
	await process_frame


func _capture_menu() -> void:
	var state_store: Node = root.get_node("GameState")
	state_store.reset()
	state_store.set_flag(&"title_seen", true)
	state_store.current_map_id = &"mistfall_farm"
	var scene: Node = load("res://sample/main.tscn").instantiate()
	root.add_child(scene)
	for _frame in range(4):
		await process_frame
	var menu: CanvasLayer = scene.get("game_menu")
	menu.open()
	for _frame in range(4):
		await process_frame
	var image: Image = root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUTPUT_DIRECTORY.path_join("commercial_menu.png")))
	menu.close()
	scene.queue_free()
	await process_frame
