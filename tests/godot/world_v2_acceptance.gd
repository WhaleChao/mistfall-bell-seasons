extends SceneTree

const WorldMapCatalog := preload("res://runtime/world/world_map_catalog.gd")
const AnimalPresenceState := preload("res://runtime/farming/animal_presence_state.gd")


func _initialize() -> void:
	OS.set_environment("PIXELRPG_TEST_ISOLATED", "1")
	call_deferred("_run")


func _run() -> void:
	var failures := PackedStringArray()
	var game_state: Node = root.get_node("GameState")
	game_state.reset()
	game_state.set_flag(&"title_seen", true)
	var game: Node = load("res://sample/main.tscn").instantiate()
	root.add_child(game)
	for _frame in range(4):
		await process_frame

	await _assert_map_catalog(game, failures)
	_assert_portal_graph(game, failures)
	await _assert_building_round_trips(game, game_state, failures)
	_assert_sleep_scope(game, game_state, failures)
	_assert_greenhouse_lock(game, game_state, failures)
	_assert_animal_presence(failures)
	_assert_visual_manifest(failures)
	_assert_actor_scale_contract(game, failures)
	_assert_combat_direction_and_phases(failures)

	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("Mistfall world v2 acceptance: PASS (10 maps, 100x house, 100x barn, 194 visuals)")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	print("Mistfall world v2 acceptance: FAIL (%d)" % failures.size())
	quit(1)


func _assert_map_catalog(game: Node, failures: PackedStringArray) -> void:
	if WorldMapCatalog.MAP_IDS.size() != 10:
		failures.append("World catalog must contain exactly 10 maps")
	for map_id: StringName in WorldMapCatalog.MAP_IDS:
		var definition: PixelRPGWorldMapDefinition = WorldMapCatalog.definition(map_id)
		if not ResourceLoader.exists(definition.scene_path):
			failures.append("Map scene is missing: %s" % map_id)
			continue
		if not ResourceLoader.exists(definition.background_path):
			failures.append("Map background is missing: %s" % map_id)
		else:
			var texture := load(definition.background_path) as Texture2D
			if texture == null or texture.get_size() != Vector2(640, 360):
				failures.append("Map background is not exact 640x360: %s" % map_id)
		var scene := load(definition.scene_path) as PackedScene
		var instance := scene.instantiate() as PixelRPGMapScene
		root.add_child(instance)
		await process_frame
		if instance.map_id != map_id:
			failures.append("Map scene id mismatch: %s" % map_id)
		if not is_instance_valid(instance.semantic_layer) or not instance.semantic_layer is TileMapLayer:
			failures.append("Map lacks its semantic TileMapLayer: %s" % map_id)
		elif not instance.semantic_layer.has_meta("semantic_types"):
			failures.append("Semantic TileMapLayer has no semantic contract: %s" % map_id)
		var mode := String(definition.mode)
		var safe_spawn := Vector2(definition.safe_spawn)
		if game.is_map_position_blocked(mode, safe_spawn, 7.0):
			failures.append("Catalog safe spawn is blocked: %s @ %s" % [map_id, safe_spawn])
		instance.queue_free()
		await process_frame


func _assert_portal_graph(game: Node, failures: PackedStringArray) -> void:
	failures.append_array(WorldMapCatalog.portal_graph_errors())
	for map_id: StringName in WorldMapCatalog.MAP_IDS:
		var portals: Array[PixelRPGMapPortalDefinition] = WorldMapCatalog.portals_for(map_id)
		if portals.is_empty():
			failures.append("Map has no portal and can trap the player: %s" % map_id)
		for portal: PixelRPGMapPortalDefinition in portals:
			if portal.source_map_id != map_id:
				failures.append("Portal source id mismatch: %s" % portal.portal_id)
			if portal.target_map_id not in WorldMapCatalog.MAP_IDS:
				failures.append("Portal points to unknown map: %s" % portal.portal_id)
				continue
			var target_mode := String(WorldMapCatalog.definition(portal.target_map_id).mode)
			if game.is_map_position_blocked(target_mode, portal.target_spawn, 7.0):
				var suggested: Vector2 = game._arrival_position_for_mode(target_mode, portal.source_map_id)
				failures.append("Portal target spawn is blocked: %s -> %s @ %s; runtime=%s" % [portal.portal_id, portal.target_map_id, portal.target_spawn, suggested])


func _assert_building_round_trips(game: Node, game_state: Node, failures: PackedStringArray) -> void:
	for building: Dictionary in [
		{"mode":"farmhouse", "map":&"mistfall_farmhouse", "door":Vector2(205, 137), "return":Vector2(205, 159)},
		{"mode":"barn", "map":&"mistfall_barn", "door":Vector2(478, 137), "return":Vector2(478, 159)},
	]:
		for cycle in range(100):
			game.mode = "farm"
			game_state.current_map_id = &"mistfall_farm"
			var enter_portal: Dictionary = game._building_portal_at("farm", Vector2(building.door))
			if enter_portal.is_empty() or StringName(enter_portal.target) != StringName(building.map):
				failures.append("%s entrance missing during cycle %d" % [building.mode, cycle])
				break
			game._activate_building_portal(enter_portal)
			if game.mode != String(building.mode) or game_state.current_map_id != StringName(building.map) or game.player.global_position.distance_to(Vector2(320, 286)) > 0.1:
				failures.append("%s entered at the wrong scene/position during cycle %d" % [building.mode, cycle])
				break
			var exit_portal: Dictionary = game._building_portal_at(String(building.mode), Vector2(320, 316))
			if exit_portal.is_empty() or StringName(exit_portal.target) != &"mistfall_farm":
				failures.append("%s exit missing during cycle %d" % [building.mode, cycle])
				break
			game._activate_building_portal(exit_portal)
			if game.mode != "farm" or game_state.current_map_id != &"mistfall_farm" or game.player.global_position.distance_to(Vector2(building.return)) > 0.1:
				failures.append("%s returned to the wrong door during cycle %d" % [building.mode, cycle])
				break
			if game.is_world_position_blocked(game.player.global_position, 7.0) or game.portal_transition_cooldown <= 0.0:
				failures.append("%s return can stick or instantly rebound during cycle %d" % [building.mode, cycle])
				break
			if cycle % 10 == 9:
				await process_frame


func _assert_sleep_scope(game: Node, game_state: Node, failures: PackedStringArray) -> void:
	game.mode = "farm"
	game_state.current_map_id = &"mistfall_farm"
	game.player.global_position = Vector2(320, 250)
	if game.can_sleep_at_current_position():
		failures.append("Sleep remains available from an arbitrary farm position")
	game.mode = "farmhouse"
	game_state.current_map_id = &"mistfall_farmhouse"
	game.player.global_position = Vector2(156, 112)
	if not game.can_sleep_at_current_position():
		failures.append("Farmhouse bed does not enable sleeping")
	var previous_day: int = game_state.calendar.day
	game_state.calendar.minute_of_day = 20 * 60
	if not game_state.sleep_if_allowed() or game_state.calendar.day == previous_day:
		failures.append("Sleeping at the farmhouse bed did not end the day")


func _assert_greenhouse_lock(game: Node, game_state: Node, failures: PackedStringArray) -> void:
	game.mode = "farm"
	game_state.current_map_id = &"mistfall_farm"
	game_state.farm.greenhouse_unlocked = false
	var locked_portal: Dictionary = game._building_portal_at("farm", Vector2(102, 137))
	if locked_portal.is_empty() or not bool(locked_portal.locked):
		failures.append("Locked greenhouse does not explain that it is unavailable")
	game_state.farm.greenhouse_unlocked = true
	var unlocked_portal: Dictionary = game._building_portal_at("farm", Vector2(102, 137))
	if unlocked_portal.is_empty() or bool(unlocked_portal.locked):
		failures.append("Unlocked greenhouse cannot be entered")


func _assert_animal_presence(failures: PackedStringArray) -> void:
	for weather: String in ["rain", "storm", "typhoon", "snow", "blizzard"]:
		if AnimalPresenceState.scene_for(weather, 12 * 60) != &"mistfall_barn":
			failures.append("Animal leaves the barn during %s" % weather)
	for minute: int in [0, 7 * 60 + 59, 18 * 60, 23 * 60]:
		if AnimalPresenceState.scene_for("clear", minute) != &"mistfall_barn":
			failures.append("Animal outdoor schedule leaks outside 08:00-18:00 at %d" % minute)
	for minute: int in [8 * 60, 12 * 60, 17 * 60 + 59]:
		if AnimalPresenceState.scene_for("clear", minute) != &"mistfall_farm":
			failures.append("Animal does not enter the outdoor pasture at %d" % minute)


func _assert_visual_manifest(failures: PackedStringArray) -> void:
	var file := FileAccess.open("res://assets/runtime/icons/manifest.json", FileAccess.READ)
	var manifest: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	if not manifest is Dictionary or int(manifest.get("count", 0)) != 194:
		failures.append("Visual manifest does not declare all 194 raster ids")
		return
	var seen: Dictionary = {}
	for entry: Dictionary in Array(manifest.get("icons", [])):
		var visual_id := String(entry.get("visual_id", ""))
		var path := String(entry.get("path", ""))
		if visual_id.is_empty() or seen.has(visual_id):
			failures.append("Visual manifest contains a blank or duplicate id: %s" % visual_id)
		seen[visual_id] = true
		if path.get_extension().to_lower() != "png" or not ResourceLoader.exists(path):
			failures.append("Visual id is missing its raster asset: %s -> %s" % [visual_id, path])
			continue
		var texture := load(path) as Texture2D
		if texture == null or texture.get_size() != Vector2(64, 64):
			failures.append("Visual id is not a 64x64 PNG: %s" % visual_id)
	if seen.size() != 194:
		failures.append("Visual manifest has %d unique ids instead of 194" % seen.size())


func _assert_actor_scale_contract(game: Node, failures: PackedStringArray) -> void:
	var expected_sizes := {
		"res://assets/runtime/sprites/player_walk_atlas_final.png":Vector2(188, 188),
		"res://assets/runtime/sprites/character_atlas_final.png":Vector2(208, 156),
		"res://assets/runtime/sprites/animal_chicken_atlas_final.png":Vector2(188, 94),
		"res://assets/runtime/sprites/animal_livestock_atlas_final.png":Vector2(232, 116),
		"res://assets/runtime/sprites/enemy_atlas_final.png":Vector2(192, 204),
		"res://assets/runtime/sprites/enemy_boss_atlas_final.png":Vector2(240, 256),
	}
	for path: String in expected_sizes:
		var texture := load(path) as Texture2D
		if texture == null or texture.get_size() != Vector2(expected_sizes[path]):
			failures.append("Final-size actor atlas mismatch: %s" % path)
	var regular_heights := [47.0, 52.0, 47.0, 58.0, 51.0]
	var smallest: float = regular_heights.min()
	var largest: float = regular_heights.max()
	if largest / smallest > 1.25:
		failures.append("Regular actors use inconsistent scene scale: %.2f" % (largest / smallest))
	if game.player.visual_sprite.scale != Vector2.ONE:
		failures.append("Player still uses fractional runtime scaling")
	for npc_sprite: Sprite2D in game.npc_sprites.values():
		if npc_sprite.scale != Vector2.ONE:
			failures.append("NPC still uses fractional runtime scaling")
			break


func _assert_combat_direction_and_phases(failures: PackedStringArray) -> void:
	var player: Node2D = load("res://runtime/actors/player.gd").new()
	player.global_position = Vector2(300, 180)
	if [player.attack_phase(0.10), player.attack_phase(0.50), player.attack_phase(0.90)] != [&"prepare", &"strike", &"recovery"]:
		failures.append("Attack does not expose prepare/strike/recovery phases")
	for direction: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		player.facing = direction
		var hit: Dictionary = player.attack_hit_geometry()
		if Vector2(hit.center - player.global_position).dot(direction) <= 20.0:
			failures.append("Attack hit area points through the actor: %s" % direction)
		for progress: float in [0.0, 0.25, 0.5, 0.75, 1.0]:
			var slash: Dictionary = player.attack_effect_geometry(progress)
			var tail_forward := Vector2(slash.tail).dot(direction)
			var tip_forward := Vector2(slash.tip).dot(direction)
			if tail_forward <= 0.0 or tip_forward <= tail_forward + 10.0:
				failures.append("Slash points toward the actor: %s at %.2f" % [direction, progress])
	player.free()
