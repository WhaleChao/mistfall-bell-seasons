extends SceneTree

const REPORT_PATH := "res://reports/world_v2/mac_soak.json"
const SOAK_SECONDS := 300.0
const MINIMUM_AVERAGE_FPS := 58.0
const MAP_CASES: Array[Dictionary] = [
	{"id":&"mistfall_farm", "mode":"farm"},
	{"id":&"mistfall_village", "mode":"village"},
	{"id":&"mistfall_river", "mode":"river"},
	{"id":&"bellwood_grove", "mode":"grove"},
	{"id":&"clockwork_ruins", "mode":"ruins"},
	{"id":&"mistfall_depths", "mode":"dungeon"},
	{"id":&"dreaming_shore", "mode":"abyss"},
	{"id":&"mistfall_farmhouse", "mode":"farmhouse"},
	{"id":&"mistfall_barn", "mode":"barn"},
	{"id":&"mistfall_greenhouse", "mode":"greenhouse"},
]


func _initialize() -> void:
	OS.set_environment("PIXELRPG_TEST_ISOLATED", "1")
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(640, 360)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 60
	OS.low_processor_usage_mode = false
	var game_state: Node = root.get_node("GameState")
	game_state.reset()
	game_state.set_flag(&"title_seen", true)
	game_state.farm.greenhouse_unlocked = true
	game_state.player_stats["health"] = 999999
	game_state.player_stats["max_health"] = 999999
	game_state.player_stats["attack"] = 99
	var game: Node = load("res://sample/main.tscn").instantiate()
	root.add_child(game)
	for _frame in range(30):
		await process_frame

	# Tour every new map in the same 1920x1080 viewport before the combat soak.
	var toured := PackedStringArray()
	for map_case: Dictionary in MAP_CASES:
		game._clear_enemies()
		game.mode = String(map_case.mode)
		game_state.current_map_id = StringName(map_case.id)
		game._set_background_for_mode()
		game.player.global_position = game._safe_spawn_for_mode(String(map_case.mode))
		game._sanitize_player_position()
		game._update_hud()
		for _frame in range(6):
			await process_frame
		toured.append(String(map_case.id))

	# Save/load once after the map tour so map, position, facing, and indoor state
	# are exercised on the same target Mac run.
	game_state.player_position = game.player.global_position
	var save_ok: bool = root.get_node("SaveManager").save_quick()
	var load_ok: bool = root.get_node("SaveManager").load_quick()
	for _frame in range(12):
		await process_frame

	game_state.dungeon.current_floor = 35
	game._enter_dungeon(true)
	game.player.health = 999999
	game.player.max_health = 999999
	game.player.attack_power = 99
	_spawn_training_enemies(game, 16)
	for _frame in range(60):
		await process_frame

	var started_usec := Time.get_ticks_usec()
	var previous_usec := started_usec
	var frames := 0
	var attacks := 0
	var respawns := 0
	var one_second_frames := 0
	var one_second_started := started_usec
	var fps_samples: Array[float] = []
	var next_attack := 0.0
	var next_restock := 8.0
	while float(Time.get_ticks_usec() - started_usec) / 1_000_000.0 < SOAK_SECONDS:
		await process_frame
		frames += 1
		one_second_frames += 1
		var now_usec := Time.get_ticks_usec()
		var elapsed := float(now_usec - started_usec) / 1_000_000.0
		if elapsed >= next_attack and game.player.state == game.player.State.MOVE:
			var facing_index := int(elapsed / 2.0) % 4
			game.player.facing = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP][facing_index]
			game.player._start_attack(0)
			attacks += 1
			next_attack += 0.35
		if elapsed >= next_restock:
			var current_enemies := get_nodes_in_group("enemies").size()
			if current_enemies < 12:
				_spawn_training_enemies(game, 16 - current_enemies)
				respawns += 16 - current_enemies
			next_restock += 8.0
		if now_usec - one_second_started >= 1_000_000:
			var sample_seconds := float(now_usec - one_second_started) / 1_000_000.0
			fps_samples.append(float(one_second_frames) / sample_seconds)
			one_second_frames = 0
			one_second_started = now_usec
		previous_usec = now_usec

	var elapsed_seconds := float(Time.get_ticks_usec() - started_usec) / 1_000_000.0
	var average_fps := float(frames) / maxf(elapsed_seconds, 0.001)
	var minimum_sample_fps := 0.0
	if not fps_samples.is_empty():
		minimum_sample_fps = fps_samples[0]
		for sample: float in fps_samples:
			minimum_sample_fps = minf(minimum_sample_fps, sample)
	var passed := (
		toured.size() == MAP_CASES.size()
		and save_ok
		and load_ok
		and elapsed_seconds >= SOAK_SECONDS
		and average_fps >= MINIMUM_AVERAGE_FPS
		and attacks >= 750
	)
	var report := {
		"schema_version":1,
		"platform":OS.get_name(),
		"model":OS.get_model_name(),
		"renderer":RenderingServer.get_video_adapter_name(),
		"viewport":[1920, 1080],
		"logical_resolution":[640, 360],
		"maps_toured":Array(toured),
		"save_ok":save_ok,
		"load_ok":load_ok,
		"combat_seconds":snappedf(elapsed_seconds, 0.001),
		"frames":frames,
		"average_fps":snappedf(average_fps, 0.1),
		"minimum_one_second_fps":snappedf(minimum_sample_fps, 0.1),
		"attack_cycles":attacks,
		"enemy_respawns":respawns,
		"minimum_average_fps":MINIMUM_AVERAGE_FPS,
		"passed":passed,
	}
	game._clear_enemies()
	game.queue_free()
	for _frame in range(8):
		await process_frame
	root.get_node("AudioDirector").shutdown_audio()
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_PATH.get_base_dir()))
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write world v2 macOS soak report")
		quit(2)
		return
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
	print("Mistfall world v2 macOS soak: %s (%.1f FPS, %.1f seconds, %d attacks)" % ["PASS" if passed else "FAIL", average_fps, elapsed_seconds, attacks])
	quit(0 if passed else 1)


func _spawn_training_enemies(game: Node, count: int) -> void:
	var registry: Node = root.get_node("ContentRegistry")
	var enemy_script: GDScript = load("res://runtime/actors/enemy.gd")
	var enemy_ids := [&"fog_wisp", &"ice_slime", &"frost_wolf", &"bell_guardian"]
	var positions := [
		Vector2(252, 142), Vector2(320, 126), Vector2(388, 142), Vector2(426, 188),
		Vector2(388, 236), Vector2(320, 252), Vector2(252, 236), Vector2(214, 188),
	]
	for index in range(count):
		var definition: Dictionary = registry.get_artifact("enemies", enemy_ids[index % enemy_ids.size()]).duplicate(true)
		definition["max_health"] = 90
		definition["damage"] = 1
		var enemy: CharacterBody2D = enemy_script.new()
		enemy.configure(definition)
		enemy.global_position = positions[index % positions.size()] + Vector2((index / positions.size()) * 6, 0)
		game.add_child(enemy)
