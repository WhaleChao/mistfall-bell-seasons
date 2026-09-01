extends SceneTree

const REPORT_DIRECTORY := "res://reports/world_v2/after"
const EVIDENCE_SIZE := Vector2i(1280, 720)
const MAP_CASES: Array[Dictionary] = [
	{"id":&"mistfall_farm", "mode":"farm", "file":"01_farm"},
	{"id":&"mistfall_village", "mode":"village", "file":"02_village"},
	{"id":&"mistfall_river", "mode":"river", "file":"03_river"},
	{"id":&"bellwood_grove", "mode":"grove", "file":"04_grove"},
	{"id":&"clockwork_ruins", "mode":"ruins", "file":"05_ruins"},
	{"id":&"mistfall_depths", "mode":"dungeon", "file":"06_depths"},
	{"id":&"dreaming_shore", "mode":"abyss", "file":"07_dreaming_shore"},
	{"id":&"mistfall_farmhouse", "mode":"farmhouse", "file":"08_farmhouse"},
	{"id":&"mistfall_barn", "mode":"barn", "file":"09_barn"},
	{"id":&"mistfall_greenhouse", "mode":"greenhouse", "file":"10_greenhouse"},
]


func _initialize() -> void:
	OS.set_environment("PIXELRPG_TEST_ISOLATED", "1")
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIRECTORY))
	root.size = EVIDENCE_SIZE
	root.content_scale_size = Vector2i(640, 360)
	var game_state: Node = root.get_node("GameState")
	game_state.reset()
	game_state.set_flag(&"title_seen", true)
	game_state.farm.greenhouse_unlocked = true
	var game: Node = load("res://sample/main.tscn").instantiate()
	root.add_child(game)
	for _frame in range(5):
		await process_frame
	game.set_process(false)
	var failures := PackedStringArray()
	var captures: Array[String] = []
	for map_case: Dictionary in MAP_CASES:
		game._clear_enemies()
		game.mode = String(map_case.mode)
		game_state.current_map_id = StringName(map_case.id)
		game._set_background_for_mode()
		game.player.global_position = game._safe_spawn_for_mode(String(map_case.mode))
		game._sanitize_player_position()
		game.title_label.text = ""
		game._update_hud()
		game._hide_world_prompt()
		game.queue_redraw()
		for _frame in range(3):
			await process_frame
		# Headless Metal does not guarantee a frame_post_draw notification. Three
		# processed frames above are enough to flush the viewport deterministically.
		var image := root.get_texture().get_image()
		if image.get_size() != EVIDENCE_SIZE:
			image.resize(EVIDENCE_SIZE.x, EVIDENCE_SIZE.y, Image.INTERPOLATE_NEAREST)
		var relative_path := "%s/%s.png" % [REPORT_DIRECTORY, map_case.file]
		var save_error := image.save_png(ProjectSettings.globalize_path(relative_path))
		if save_error != OK:
			failures.append("Could not save %s: %d" % [map_case.id, save_error])
		else:
			captures.append(relative_path)
			if image.get_used_rect().size != EVIDENCE_SIZE:
				failures.append("Capture contains an empty outer region: %s" % map_case.id)
	var report := {
		"schema_version":2,
		"maps":MAP_CASES.size(),
		"captures":captures,
		"failed":failures.size(),
		"renderer":RenderingServer.get_video_adapter_name(),
		"logical_resolution":[640, 360],
		"evidence_resolution":[1280, 720],
	}
	var report_file := FileAccess.open("res://reports/world_v2/visual_report.json", FileAccess.WRITE)
	if report_file != null:
		report_file.store_string(JSON.stringify(report, "  ") + "\n")
	else:
		failures.append("Could not write world v2 visual report")
	game.queue_free()
	# Give queued actor sprites, map layers, and imported textures enough frames to
	# release before the SceneTree exits. This keeps the visual gate free of
	# misleading ObjectDB leak warnings on macOS/Metal.
	for _frame in range(8):
		await process_frame
	if failures.is_empty():
		print("Mistfall world v2 visual regression: PASS (10 captures)")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
