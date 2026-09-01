extends SceneTree

const GRID_STEP := 6
const MAP_IDS := {
	"farm": &"mistfall_farm",
	"village": &"mistfall_village",
	"river": &"mistfall_river",
	"grove": &"bellwood_grove",
	"ruins": &"clockwork_ruins",
	"dungeon": &"mistfall_depths",
	"abyss": &"dreaming_shore",
}

var game: Node
var player: CharacterBody2D
var player_shape := CapsuleShape2D.new()


func _initialize() -> void:
	OS.set_environment("PIXELRPG_TEST_ISOLATED", "1")
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	game_state.reset()
	game_state.set_flag(&"title_seen", true)
	game = load("res://sample/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame
	player = game.player
	player_shape.radius = 7.0
	player_shape.height = 19.0
	var failed := false
	for map_mode: String in MAP_IDS:
		game._clear_enemies()
		game.mode = map_mode
		game_state.current_map_id = MAP_IDS[map_mode]
		game._set_background_for_mode()
		player.global_position = game._safe_spawn_for_mode(map_mode)
		game._sanitize_player_position()
		await physics_frame
		await physics_frame
		var scan_start: Vector2 = player.global_position
		var summary := _physics_component_summary(scan_start)
		var traversal := _exercise_all_arrivals_to_right_edge(map_mode, Dictionary(summary.free_points))
		var passed := int(summary.reachable) == int(summary.free) and bool(traversal.ok)
		failed = failed or not passed
		print("[%s] %s actual physics: reachable=%d/%d right=%d/%d ratio=%.3f max_x=%d arrivals=%d/%d start=%s" % [
			"PASS" if passed else "FAIL", map_mode,
			int(summary.reachable), int(summary.free),
			int(summary.reachable_right), int(summary.free_right),
			float(summary.right_reachable_ratio), int(summary.max_reachable_x), int(traversal.tested), int(traversal.expected),
			scan_start,
		])
		if not passed:
			print("       components=%s" % [summary.components])
			print("       traversal=%s" % [traversal])
	game.queue_free()
	await process_frame
	print("PixelRPG actual-physics map reachability: %s" % ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)


func _physics_component_summary(start_position: Vector2) -> Dictionary:
	var free_points: Dictionary = {}
	for y in range(60, 333, GRID_STEP):
		for x in range(26, 615, GRID_STEP):
			var point := Vector2(x, y)
			if _physics_position_is_free(point):
				free_points[Vector2i(x, y)] = true
	var start_key := _nearest_free_key(free_points, start_position)
	var reachable: Dictionary = {}
	var frontier: Array[Vector2i] = []
	if free_points.has(start_key):
		reachable[start_key] = true
		frontier.append(start_key)
	var cursor := 0
	while cursor < frontier.size():
		var current := frontier[cursor]
		cursor += 1
		for direction: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var next := current + direction * GRID_STEP
			if free_points.has(next) and not reachable.has(next):
				reachable[next] = true
				frontier.append(next)
	var free_right := 0
	var reachable_right := 0
	var max_reachable_x := 0
	for point: Vector2i in free_points:
		if point.x >= 400:
			free_right += 1
			if reachable.has(point):
				reachable_right += 1
	for point: Vector2i in reachable:
		max_reachable_x = maxi(max_reachable_x, point.x)
	var components := _component_bounds(free_points)
	return {
		"free":free_points.size(),
		"reachable":reachable.size(),
		"free_right":free_right,
		"reachable_right":reachable_right,
		"disconnected_right":free_right - reachable_right,
		"right_reachable_ratio":float(reachable_right) / float(maxi(1, free_right)),
		"max_reachable_x":max_reachable_x,
		"components":components,
		"free_points":free_points,
	}


func _exercise_all_arrivals_to_right_edge(map_mode: String, free_points: Dictionary) -> Dictionary:
	var right_goal := Vector2i.ZERO
	var right_goal_score := -INF
	for point: Vector2i in free_points:
		var score := float(point.x) * 1000.0 - absf(float(point.y) - 196.0)
		if score > right_goal_score:
			right_goal = point
			right_goal_score = score
	var failures := PackedStringArray()
	var tested := 0
	var connections: Dictionary = Dictionary(game.REGION_CONNECTIONS.get(map_mode, {}))
	for source_map_id: String in connections:
		var route_anchor := Vector2(Dictionary(connections[source_map_id]).position)
		var route_stand := _nearest_free_key(free_points, route_anchor)
		if Vector2(route_stand).distance_to(route_anchor) > 28.0:
			failures.append("%s route has no physical standing point" % source_map_id)
			continue
		var arrival: Vector2 = game._arrival_position_for_mode(map_mode, StringName(source_map_id))
		var start_key := _nearest_free_key(free_points, arrival)
		if Vector2(start_key).distance_to(arrival) > 12.0:
			failures.append("%s arrival %s is not physically free" % [source_map_id, arrival])
			continue
		var path := _grid_path(free_points, start_key, right_goal)
		if path.is_empty():
			failures.append("%s arrival cannot path to right edge" % source_map_id)
			continue
		if not _drive_player_along_path(path):
			failures.append("%s CharacterBody2D collided along computed route" % source_map_id)
			continue
		tested += 1
	return {"ok":failures.is_empty(), "tested":tested, "expected":connections.size(), "failures":failures}


func _grid_path(free_points: Dictionary, start: Vector2i, target: Vector2i) -> Array[Vector2i]:
	var frontier: Array[Vector2i] = [start]
	var parents: Dictionary = {start:start}
	var cursor := 0
	while cursor < frontier.size() and not parents.has(target):
		var current := frontier[cursor]
		cursor += 1
		for direction: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var next := current + direction * GRID_STEP
			if free_points.has(next) and not parents.has(next):
				parents[next] = current
				frontier.append(next)
	if not parents.has(target):
		return []
	var reversed_path: Array[Vector2i] = [target]
	var current := target
	while current != start:
		current = Vector2i(parents[current])
		reversed_path.append(current)
	reversed_path.reverse()
	return reversed_path


func _drive_player_along_path(path: Array[Vector2i]) -> bool:
	if path.is_empty():
		return false
	player.set_physics_process(false)
	player.global_position = Vector2(path[0])
	var passed := true
	for index in range(1, path.size()):
		var destination := Vector2(path[index])
		var collision := player.move_and_collide(destination - player.global_position)
		if collision != null or player.global_position.distance_to(destination) > 0.1:
			passed = false
			break
	player.velocity = Vector2.ZERO
	player.set_physics_process(true)
	return passed


func _component_bounds(free_points: Dictionary) -> Array[Dictionary]:
	var remaining := free_points.duplicate()
	var components: Array[Dictionary] = []
	while not remaining.is_empty():
		var first: Vector2i = remaining.keys()[0]
		var frontier: Array[Vector2i] = [first]
		remaining.erase(first)
		var minimum := first
		var maximum := first
		var cursor := 0
		while cursor < frontier.size():
			var current := frontier[cursor]
			cursor += 1
			minimum = Vector2i(mini(minimum.x, current.x), mini(minimum.y, current.y))
			maximum = Vector2i(maxi(maximum.x, current.x), maxi(maximum.y, current.y))
			for direction: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
				var next := current + direction * GRID_STEP
				if remaining.erase(next):
					frontier.append(next)
		components.append({"size":frontier.size(), "min":minimum, "max":maximum})
	components.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return int(left.size) > int(right.size))
	return components


func _nearest_free_key(free_points: Dictionary, position: Vector2) -> Vector2i:
	var best := Vector2i.ZERO
	var best_distance := INF
	for point: Vector2i in free_points:
		var distance := Vector2(point).distance_squared_to(position)
		if distance < best_distance:
			best = point
			best_distance = distance
	return best


func _physics_position_is_free(position: Vector2) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = player_shape
	query.transform = Transform2D(0.0, position + Vector2(0, 4))
	query.collision_mask = 1 | 4 | 16
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [player.get_rid()]
	return player.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()
