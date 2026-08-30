extends SceneTree

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures := PackedStringArray()
	var arena := Node2D.new()
	root.add_child(arena)
	var player: CharacterBody2D = load("res://runtime/actors/player.gd").new()
	player.position = Vector2(320, 180)
	arena.add_child(player)
	var enemy_ids := [
		"moss_slime", "thorn_rat", "pollen_wisp", "ember_slime",
		"cave_bat", "magma_beetle", "amber_slime", "stone_boar",
		"fog_wisp", "ice_slime", "frost_wolf", "bell_guardian",
	]
	var registry: Node = root.get_node("ContentRegistry")
	for index in range(20):
		var enemy: CharacterBody2D = load("res://runtime/actors/enemy.gd").new()
		enemy.configure(registry.get_artifact("enemies", enemy_ids[index % enemy_ids.size()]))
		enemy.position = Vector2(90 + (index % 5) * 110, 90 + (index / 5) * 65)
		enemy.player = player
		arena.add_child(enemy)
	var started_usec := Time.get_ticks_usec()
	for _frame in range(600):
		await process_frame
	var elapsed_seconds := float(Time.get_ticks_usec() - started_usec) / 1_000_000.0
	var live_enemies := get_nodes_in_group("enemies").size()
	if live_enemies != 20:
		failures.append("Expected 20 live enemies during benchmark, found %d" % live_enemies)
	if elapsed_seconds > 5.0:
		failures.append("600-frame/20-enemy simulation took %.3f seconds" % elapsed_seconds)
	arena.queue_free()
	await process_frame
	if failures.is_empty():
		print("PixelRPG performance gate: PASS (600 frames, 20 enemies, %.3f seconds)" % elapsed_seconds)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
