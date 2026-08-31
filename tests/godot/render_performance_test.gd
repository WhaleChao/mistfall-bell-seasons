extends SceneTree

const DEFAULT_REPORT_PATH := "res://reports/render_performance.json"
const MINIMUM_AVERAGE_FPS := 58.0
const MINIMUM_BASELINE_RATIO := 0.95


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(640, 360)
	# The automated window is not focused, so Windows' compositor can force it to
	# half-refresh. Disable VSync here to measure actual render capacity.
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	OS.low_processor_usage_mode = false
	var baseline_started := Time.get_ticks_usec()
	for _baseline_frame in range(120):
		await process_frame
	var baseline_seconds := float(Time.get_ticks_usec() - baseline_started) / 1_000_000.0
	var baseline_fps := 120.0 / maxf(baseline_seconds, 0.001)
	var state_store: Node = root.get_node("GameState")
	state_store.reset()
	state_store.set_flag(&"title_seen", true)
	state_store.current_map_id = &"mistfall_depths"
	state_store.dungeon.current_floor = 35
	state_store.player_stats["health"] = 99999
	state_store.player_stats["max_health"] = 99999
	var scene: Node = load("res://sample/main.tscn").instantiate()
	root.add_child(scene)
	for _warmup in range(60):
		await process_frame
	scene.call("_clear_enemies")
	scene.set_process(false)
	var scene_started := Time.get_ticks_usec()
	for _scene_frame in range(120):
		await process_frame
	var scene_seconds := float(Time.get_ticks_usec() - scene_started) / 1_000_000.0
	var scene_fps := 120.0 / maxf(scene_seconds, 0.001)
	scene.set_process(true)
	var existing := get_nodes_in_group("enemies").size()
	var registry: Node = root.get_node("ContentRegistry")
	var enemy_script: GDScript = load("res://runtime/actors/enemy.gd")
	var enemy_ids := ["fog_wisp", "ice_slime", "frost_wolf", "bell_guardian"]
	for index in range(existing, 20):
		var enemy: CharacterBody2D = enemy_script.new()
		enemy.configure(registry.get_artifact("enemies", enemy_ids[index % enemy_ids.size()]))
		enemy.position = Vector2(70 + (index % 5) * 120, 85 + (index / 5) * 70)
		scene.add_child(enemy)
	var started_usec := Time.get_ticks_usec()
	for _frame in range(300):
		await process_frame
	var elapsed_seconds := float(Time.get_ticks_usec() - started_usec) / 1_000_000.0
	var measured_fps := 300.0 / maxf(elapsed_seconds, 0.001)
	var reported_elapsed := snappedf(elapsed_seconds, 0.001)
	var reported_fps := snappedf(measured_fps, 0.1)
	var reported_empty_fps := snappedf(baseline_fps, 0.1)
	var reported_scene_fps := snappedf(scene_fps, 0.1)
	var reported_capacity := snappedf(reported_fps / maxf(reported_empty_fps, 0.001), 0.001)
	var passed_by := "none"
	if reported_fps >= MINIMUM_AVERAGE_FPS:
		passed_by = "average_fps"
	elif reported_empty_fps < MINIMUM_AVERAGE_FPS and reported_capacity >= MINIMUM_BASELINE_RATIO:
		passed_by = "baseline_ratio"
	var passed := passed_by != "none"
	var expected_exit_code := 0 if passed else 1
	var completion_token := OS.get_environment("PIXELRPG_RENDER_COMPLETION_TOKEN")
	var report := {
		"schema_version": 2,
		"viewport": [1920, 1080],
		"frames": 300,
		"enemies": get_nodes_in_group("enemies").size(),
		"elapsed_seconds": reported_elapsed,
		"average_fps": reported_fps,
		"empty_window_fps": reported_empty_fps,
		"base_scene_fps": reported_scene_fps,
		"capacity_ratio": reported_capacity,
		"minimum_average_fps": MINIMUM_AVERAGE_FPS,
		"minimum_baseline_ratio": MINIMUM_BASELINE_RATIO,
		"renderer": RenderingServer.get_video_adapter_name(),
		"passed": passed,
		"passed_by": passed_by,
		"failure_reason": "" if passed else "performance_threshold",
		"expected_exit_code": expected_exit_code,
		"completion_token": completion_token,
		"completed": false,
	}
	scene.queue_free()
	await process_frame
	var audio_director: Node = root.get_node("AudioDirector")
	audio_director.call("shutdown_audio")
	await process_frame
	report["completed"] = true
	var report_path := OS.get_environment("PIXELRPG_RENDER_PERFORMANCE_REPORT")
	if report_path.is_empty():
		report_path = DEFAULT_REPORT_PATH
	var absolute_report_path := ProjectSettings.globalize_path(report_path)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_report_path.get_base_dir())
	if directory_error != OK:
		push_error("Cannot create render performance report directory: %s" % error_string(directory_error))
		quit(2)
		return
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write render performance report: %s" % FileAccess.get_open_error())
		quit(2)
		return
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
	print("PixelRPG 1080p render gate: %s (empty %.1f FPS, base %.1f FPS, 20 enemies %.1f FPS)" % ["PASS" if passed else "FAIL", reported_empty_fps, reported_scene_fps, reported_fps])
	print("PIXELRPG_RENDER_COMPLETED token=%s result=%s exit=%d" % [completion_token, "PASS" if passed else "FAIL", expected_exit_code])
	quit(expected_exit_code)
