extends SceneTree

const INPUT_BINDINGS_TEST_PATH := "user://pixelrpg_input_smoke_test.json"
const ItemIconFactory := preload("res://runtime/ui/item_icon_factory.gd")


func _initialize() -> void:
	OS.set_environment("PIXELRPG_TEST_ISOLATED", "1")
	call_deferred("_run")


func _run() -> void:
	var failures := PackedStringArray()
	var registry: Node = root.get_node_or_null("ContentRegistry")
	var state_store: Node = root.get_node_or_null("GameState")
	if registry == null or state_store == null:
		failures.append("Project autoloads were not initialized")
		_finish(failures)
		return
	if not registry.reload_all():
		failures.append_array(registry.errors)
	failures.append_array(registry.validate_references())
	_assert_content(registry, failures)
	_assert_item_icon_catalog(registry, failures)
	_assert_calendar(failures)
	_assert_input_bindings(failures)
	_assert_farming(failures)
	_assert_farm_automation(registry, failures)
	_assert_social(failures)
	_assert_dungeon(failures)
	_assert_eldritch_fishing(registry, state_store, failures)
	_assert_multiplayer_rules(failures)
	_assert_story(registry, state_store, failures)
	_assert_commercial_systems(state_store, failures)
	_assert_save_migration(state_store, failures)
	_assert_test_storage_isolation(failures)
	await _assert_runtime_ui_regressions(state_store, failures)
	var event_file := FileAccess.open("res://data/world_events/arena_victory.json", FileAccess.READ)
	var event_data: Variant = JSON.parse_string(event_file.get_as_text()) if event_file != null else null
	if not event_data is Dictionary:
		failures.append("Could not read sample WorldEvent")
	else:
		var runner: RefCounted = load("res://runtime/events/world_event_runner.gd").new()
		failures.append_array(runner.validate_event(event_data))
	var player: CharacterBody2D = load("res://runtime/actors/player.gd").new()
	if player.health != 100 or player.attack_power != 16:
		failures.append("Player defaults changed unexpectedly")
	player.free()
	_finish(failures)


func _assert_item_icon_catalog(registry: Node, failures: PackedStringArray) -> void:
	var requests: Array[Dictionary] = []
	for crop: Dictionary in registry.get_all("crops"):
		requests.append({"id":String(crop.id), "kind":&"seed"})
		requests.append({"id":String(crop.id), "kind":&"crop"})
	for artifact_type: String in ["fish", "items", "recipes", "animals", "tools", "automation_devices"]:
		var kind := StringName({"fish":"fish", "items":"item", "recipes":"dish", "animals":"animal", "tools":"tool", "automation_devices":"automation"}[artifact_type])
		for definition: Dictionary in registry.get_all(artifact_type):
			requests.append({"id":String(definition.id), "kind":kind})
	if requests.size() != 194:
		failures.append("Expected 194 seed, produce, fish, item, dish, animal, tool, and automation icon variants; got %d" % requests.size())
	for request: Dictionary in requests:
		var icon := ItemIconFactory.texture_for(StringName(request.id), StringName(request.kind))
		if icon == null:
			failures.append("Icon generator returned null: %s/%s" % [request.kind, request.id])
			continue
		var image := icon.get_image()
		if image.get_width() != 64 or image.get_height() != 64 or image.get_used_rect().size.x < 12 or image.get_used_rect().size.y < 12:
			failures.append("Icon is blank or incorrectly sized: %s/%s" % [request.kind, request.id])
		if image.get_pixel(0, 0).a > 0.02:
			failures.append("Icon lost transparent corners: %s/%s" % [request.kind, request.id])


func _assert_runtime_ui_regressions(state_store: Node, failures: PackedStringArray) -> void:
	state_store.reset()
	state_store.set_flag(&"title_seen", true)
	var game: Node = load("res://sample/main.tscn").instantiate()
	root.add_child(game)
	for _frame in range(4):
		await process_frame
	var runtime_player: Node = game.get("player")
	var game_menu: Node = game.get("game_menu")
	var automation_console: Node = game.get("automation_console")
	if not is_instance_valid(runtime_player) or not is_instance_valid(game_menu) or not is_instance_valid(automation_console):
		failures.append("Runtime scene did not create the player and game menu")
	else:
		var visual_sprite: Sprite2D = runtime_player.get("visual_sprite") as Sprite2D
		if runtime_player.z_index <= game.z_index or not is_instance_valid(visual_sprite) or visual_sprite.z_index < 0:
			failures.append("Player sprite can render behind farm plots or world decoration")
		for icon_path: String in ["res://assets/runtime/ui/seed_packet_v2.svg", "res://assets/runtime/ui/attack_slash_v2.svg"]:
			var icon_texture := load(icon_path) as Texture2D
			if icon_texture == null or icon_texture.get_width() < 64 or icon_texture.get_height() < 64:
				failures.append("Gameplay icon could not be loaded: %s" % icon_path)
			elif icon_texture.get_image().get_pixel(0, 0).a > 0.02:
				failures.append("Gameplay icon lost its transparent background: %s" % icon_path)
		if game_menu.tabs.get_tab_count() != 10:
			failures.append("Handbook should have ten tabs after moving automation into the world")
		for tab_index in range(game_menu.tabs.get_tab_count()):
			if game_menu.tabs.get_tab_title(tab_index) == "自動化":
				failures.append("Automation is still exposed as a handbook/settings tab")
		if not game.is_world_position_blocked(Vector2(160, 90)) or not game.is_world_position_blocked(Vector2(100, 250)):
			failures.append("Farm houses or pond are missing collision obstacles")
		runtime_player.global_position = Vector2(160, 155)
		var collision_start_y: float = float(runtime_player.global_position.y)
		Input.action_press("ui_up")
		for _frame in range(30):
			await physics_frame
		Input.action_release("ui_up")
		for _frame in range(10):
			await physics_frame
		if collision_start_y - runtime_player.global_position.y >= 25.0:
			failures.append("Player can still walk through the farm house")
		if runtime_player.visual_animation != &"idle" or runtime_player.visual_frame != 0:
			failures.append("Player did not return to the standing idle animation")
		var slash_direction_ok := true
		for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
			runtime_player.facing = direction
			for progress in [0.0, 0.5, 1.0]:
				var slash_geometry: Dictionary = runtime_player.attack_effect_geometry(progress)
				var tail_forward := Vector2(slash_geometry.tail).dot(direction)
				var tip_forward := Vector2(slash_geometry.tip).dot(direction)
				slash_direction_ok = slash_direction_ok and tail_forward > 0.0 and tip_forward > tail_forward + 10.0
		if not slash_direction_ok:
			failures.append("Melee slash points back through the player in one or more directions")
		runtime_player.facing = Vector2.RIGHT
		Input.action_press("attack")
		await physics_frame
		Input.action_release("attack")
		var attack_samples: Dictionary = {}
		var attack_rotation_min := INF
		var attack_rotation_max := -INF
		var previous_attack_progress := -1.0
		var attack_progress_monotonic := true
		for _frame in range(11):
			await physics_frame
			var progress := float(runtime_player.attack_visual_progress)
			if progress > 0.0:
				attack_samples[snappedf(progress, 0.01)] = true
				attack_progress_monotonic = attack_progress_monotonic and progress >= previous_attack_progress
				previous_attack_progress = progress
				attack_rotation_min = minf(attack_rotation_min, float(runtime_player.visual_sprite.rotation))
				attack_rotation_max = maxf(attack_rotation_max, float(runtime_player.visual_sprite.rotation))
		if attack_samples.size() < 8 or not attack_progress_monotonic or attack_rotation_max - attack_rotation_min < 0.025:
			failures.append("Melee animation does not provide a smooth multi-frame swing")
		while runtime_player.state != 0:
			await physics_frame
		var map_ids := {"farm":"mistfall_farm", "village":"mistfall_village", "river":"mistfall_river", "grove":"bellwood_grove", "ruins":"clockwork_ruins", "dungeon":"mistfall_depths"}
		for source_mode: String in ["farm", "village", "river", "grove", "ruins", "dungeon"]:
			var collision_summary: Dictionary = game.world_collision_summary(source_mode)
			if int(collision_summary.obstacles) < 6 or int(collision_summary.polygons) < 3:
				failures.append("World map lacks recalculated multi-shape collision coverage: %s" % source_mode)
			if game.foreground_layer_count(source_mode) < 3:
				failures.append("World map lacks dimensional walk-behind foreground layers: %s" % source_mode)
			var component_summary: Dictionary = game.walkable_component_summary(source_mode, 6.0)
			if int(component_summary.component_count) != 1:
				failures.append("World map contains unreachable walkable pockets: %s %s" % [source_mode, component_summary.components])
			for interaction: Dictionary in Array(game.interaction_reachability_cases()[source_mode]):
				if not game.map_has_reachable_interaction(source_mode, game._safe_spawn_for_mode(source_mode), Vector2(interaction.position), float(interaction.radius), 6.0):
					failures.append("World interaction cannot be reached without teleporting: %s/%s" % [source_mode, interaction.name])
				elif game.interaction_id_at(source_mode, Vector2(interaction.position)) != game._interaction_case_resolved_id(source_mode, String(interaction.name)):
					failures.append("World interaction target resolves to the wrong action: %s/%s -> %s" % [source_mode, interaction.name, game.interaction_id_at(source_mode, Vector2(interaction.position))])
				elif not game.map_has_unambiguous_interaction(source_mode, String(interaction.name), Vector2(interaction.position), float(interaction.radius), 6.0):
					failures.append("World interaction is reachable but masked by another route, actor, or action: %s/%s" % [source_mode, interaction.name])
			var connections: Dictionary = Dictionary(game.REGION_CONNECTIONS.get(source_mode, {}))
			if source_mode != "dungeon" and connections.size() < 4:
				failures.append("Outdoor region lacks direct routes: %s" % source_mode)
			var safe_spawn: Vector2 = game._safe_spawn_for_mode(source_mode)
			for destination_id: String in connections:
				var target_mode: String = game._mode_for_map(StringName(destination_id))
				if not Dictionary(game.REGION_CONNECTIONS.get(target_mode, {})).has(String(map_ids[source_mode])):
					failures.append("Region route is not bidirectional: %s -> %s" % [source_mode, destination_id])
				var route_position := Vector2(Dictionary(connections[destination_id]).position)
				if game.is_map_position_blocked(source_mode, route_position, 7.0):
					failures.append("Physical route is embedded in scenery: %s -> %s" % [source_mode, destination_id])
				elif not game.map_has_walkable_path(source_mode, safe_spawn, route_position, 6.0):
					failures.append("Physical route is disconnected from the walkable road network: %s -> %s" % [source_mode, destination_id])
		var collision_samples := {
			"farm":[Vector2(160, 90), Vector2(110, 240), Vector2(470, 240)],
			"village":[Vector2(110, 100), Vector2(320, 180), Vector2(80, 220), Vector2(470, 200)],
			"river":[Vector2(200, 80), Vector2(350, 180), Vector2(500, 190)],
			"grove":[Vector2(100, 250), Vector2(350, 180), Vector2(470, 90), Vector2(205, 145)],
			"ruins":[Vector2(130, 180), Vector2(320, 180), Vector2(500, 180), Vector2(480, 290)],
			"dungeon":[Vector2(160, 90), Vector2(590, 180), Vector2(320, 80)],
		}
		for sample_mode: String in collision_samples:
			for sample: Vector2 in collision_samples[sample_mode]:
				if not game.is_map_position_blocked(sample_mode, sample, 0.0):
					failures.append("Background landmark is missing collision: %s @ %s" % [sample_mode, sample])
		if game.is_map_position_blocked("river", Vector2(350, 263), 5.0):
			failures.append("River bridge is blocked even though surrounding water is impassable")
		for village_probe: Vector2 in [Vector2(320, 230), Vector2(game.SHOP_POSITIONS.mira_seed_shop), Vector2(game.NPC_POSITIONS.mira)]:
			var prompt_rects: Array[Rect2] = game.village_label_rects_for_position(village_probe)
			if prompt_rects.size() > 1 or not game.rects_do_not_overlap(prompt_rects):
				failures.append("Village contextual labels overlap at %s" % village_probe)
		for destination_id: String in game.REGION_CONNECTIONS.village:
			var route: Dictionary = Dictionary(game.REGION_CONNECTIONS.village[destination_id])
			var gateway_geometry: Dictionary = game._gateway_geometry(Vector2(route.position), String(route.label), destination_id)
			if bool(gateway_geometry.has_world_text) or bool(gateway_geometry.uses_rotated_text) or bool(gateway_geometry.has_chevrons) or Array(gateway_geometry.lanterns).size() != 2 or float(gateway_geometry.overlay_extent) > 18.0:
				failures.append("Village gateway reverted to character-overlappable world text: %s" % destination_id)
		var pickup_geometry: Dictionary = game.world_pickup_geometry(Vector2.ZERO)
		if bool(pickup_geometry.uses_placeholder_ring) or bool(pickup_geometry.uses_target_brackets) or Rect2(pickup_geometry.icon_rect).size != Vector2(20, 20) or not Array(pickup_geometry.sparks).is_empty():
			failures.append("Gatherable herb/reed/gear/ore visuals are oversized or use placeholder targeting geometry")
		var fishing_geometry: Dictionary = game.fishing_spot_geometry()
		if bool(fishing_geometry.uses_concentric_rings) or bool(fishing_geometry.uses_target_brackets) or int(fishing_geometry.wake_segments) > 2:
			failures.append("Fishing point reverted to concentric debug rings")
		game._travel_to_map(&"mistfall_village")
		var mira_sprite: Sprite2D = game.npc_sprites.get("mira")
		var grounded_mira_position: Vector2 = game._npc_sprite_anchor("mira", Vector2(game.NPC_POSITIONS["mira"]))
		var mira_position_before := mira_sprite.position
		for _frame in range(4):
			await process_frame
		if mira_sprite.position.distance_to(grounded_mira_position) >= 0.1 or mira_sprite.position.distance_to(mira_position_before) >= 0.1:
			failures.append("Mira is not foot-anchored to the village ground")
		if game.npc_collision_count() != game.NPC_POSITIONS.size():
			failures.append("Visible village NPCs do not all have physical collision bodies")
		for spawn_index in range(game.DUNGEON_ENEMY_SPAWN_POSITIONS.size()):
			var dungeon_spawn: Vector2 = Vector2(game.DUNGEON_ENEMY_SPAWN_POSITIONS[spawn_index])
			if not game.dungeon_enemy_spawn_is_clear(dungeon_spawn):
				failures.append("Dungeon enemy spawn is blocked or hidden by foreground: %d %s" % [spawn_index, dungeon_spawn])
			for other_index in range(spawn_index + 1, game.DUNGEON_ENEMY_SPAWN_POSITIONS.size()):
				if dungeon_spawn.distance_to(Vector2(game.DUNGEON_ENEMY_SPAWN_POSITIONS[other_index])) < 70.0:
					failures.append("Dungeon enemy spawn points overlap each other: %d/%d" % [spawn_index, other_index])
		var npc_frame_size: Vector2 = Vector2(208.0 / 4.0, 156.0 / 3.0) * float(game.NPC_SPRITE_SCALE)
		var npc_ids: Array = game.NPC_POSITIONS.keys()
		for first_index in range(npc_ids.size()):
			for second_index in range(first_index + 1, npc_ids.size()):
				var first_id := String(npc_ids[first_index])
				var second_id := String(npc_ids[second_index])
				var first_anchor: Vector2 = Vector2(game._npc_sprite_anchor(first_id, Vector2(game.NPC_POSITIONS[first_id])))
				var second_anchor: Vector2 = Vector2(game._npc_sprite_anchor(second_id, Vector2(game.NPC_POSITIONS[second_id])))
				var first_bounds: Rect2 = Rect2(first_anchor - npc_frame_size * 0.5, npc_frame_size)
				var second_bounds: Rect2 = Rect2(second_anchor - npc_frame_size * 0.5, npc_frame_size)
				var overlap: Rect2 = first_bounds.intersection(second_bounds)
				if overlap.get_area() > 256.0:
					failures.append("Village NPC silhouettes substantially overlap: %s/%s area=%.1f" % [first_id, second_id, overlap.get_area()])
		if runtime_player.visual_sprite.position.distance_to(Vector2(0, -12)) >= 0.01 or runtime_player.visual_sprite.scale.distance_to(Vector2.ONE) >= 0.001:
			failures.append("Player idle pose is not locked to a stable ground contact point")
		runtime_player.global_position = Vector2(200, 190)
		runtime_player._update_depth_order()
		var behind_depth: int = runtime_player.z_index
		runtime_player.global_position = Vector2(200, 210)
		runtime_player._update_depth_order()
		if runtime_player.z_index <= behind_depth or mira_sprite.z_index != 100 + roundi(Vector2(game.NPC_POSITIONS.mira).y):
			failures.append("Actor draw order is not derived from feet Y position")
		for npc_id: String in game.NPC_POSITIONS:
			if game.is_world_position_blocked(Vector2(game.NPC_POSITIONS[npc_id]), 9.0):
				failures.append("Village NPC is positioned inside an obstacle: %s" % npc_id)
		for shop_id: String in game.SHOP_POSITIONS:
			if game.is_world_position_blocked(Vector2(game.SHOP_POSITIONS[shop_id]), 9.0):
				failures.append("Village shop interaction is positioned inside an obstacle: %s" % shop_id)
		var river_marker: Dictionary = Dictionary(Dictionary(game.REGION_CONNECTIONS.village)["mistfall_river"])
		runtime_player.global_position = Vector2(river_marker.position)
		game._interact()
		await process_frame
		if game.mode != "river":
			failures.append("Village physical route did not reach the river")
		game._travel_to_map(&"mistfall_barn")
		runtime_player.global_position = Vector2(329, 88)
		game._interact()
		await process_frame
		if not automation_console.visible or not paused or automation_console.automation_tile_buttons.size() != 24:
			failures.append("Barn automation console is not an in-world interactive device")
		if automation_console.automation_device_select.get_item_icon(0) == null or automation_console.automation_crop_select.get_item_icon(0) == null:
			failures.append("Automation device or crop selector is missing icons")
		await _send_runtime_key(KEY_ESCAPE)
		if automation_console.visible or paused or state_store.calendar.paused:
			failures.append("Escape could not close the in-world automation console")
		game_menu.open()
		var bindings_before_cancel := _input_binding_snapshot()
		game_menu._begin_rebind(&"attack")
		await _send_runtime_key(KEY_ESCAPE)
		if not game_menu.visible or not game_menu.capture_action.is_empty() or _input_binding_snapshot() != bindings_before_cancel:
			failures.append("Escape did not cancel key rebinding without changing the binding or closing the menu")
		if game_menu.inventory_icon_count < 4:
			failures.append("Inventory did not render owned seeds and potion as icon cards")
		for recipe_index in range(game_menu.recipe_select.item_count):
			if game_menu.recipe_select.get_item_icon(recipe_index) == null:
				failures.append("Cooking recipe is missing an icon at index %d" % recipe_index)
				break
		game_menu.tabs.current_tab = 7
		game_menu._on_volume_changed(0.0)
		game_menu.volume_slider.grab_focus()
		await process_frame
		await _send_runtime_key(KEY_ESCAPE)
		for _frame in range(2):
			await process_frame
		if game_menu.visible or paused or state_store.calendar.paused:
			failures.append("Escape could not return from the muted settings menu to gameplay")
		var multiplayer_menu: Node = game.get("multiplayer_menu")
		game_menu.open()
		multiplayer_menu.open()
		multiplayer_menu.close()
		await process_frame
		if not game_menu.visible or not paused or not state_store.calendar.paused or not state_store.is_pause_owner_active(&"game_menu"):
			failures.append("Closing one of two modal overlays incorrectly resumes gameplay")
		game_menu.close()
		await process_frame
		if paused or state_store.calendar.paused or state_store.pause_owner_count() != 0:
			failures.append("The final modal overlay did not release its pause claim")
		multiplayer_menu.open()
		await process_frame
		await _send_runtime_key(KEY_ESCAPE)
		if multiplayer_menu.visible or game_menu.visible or paused or state_store.calendar.paused:
			failures.append("Escape could not close multiplayer without reopening another menu")
		var shop_menu: Node = game.get("shop_menu")
		shop_menu.open(&"mira_seed_shop")
		await process_frame
		if shop_menu.visible:
			var first_shop_offer := shop_menu.offer_box.get_child(0) as Button
			if first_shop_offer == null or first_shop_offer.icon == null:
				failures.append("Shop offer did not render its seed/item icon")
			await _send_runtime_key(KEY_ESCAPE)
			if shop_menu.visible or game_menu.visible or paused or state_store.calendar.paused:
				failures.append("Escape could not close a shop without reopening the pause menu")
		var dialogue_overlay: Node = game.get("dialogue_overlay")
		dialogue_overlay.open_line(&"mira", "返回鍵驗證")
		await process_frame
		await _send_runtime_key(KEY_ESCAPE)
		if dialogue_overlay.visible or paused or state_store.calendar.paused:
			failures.append("Escape could not leave dialogue and return to gameplay")
		var festival_overlay: Node = game.get("festival_overlay")
		state_store.calendar.season_index = 0
		state_store.calendar.day = 8
		state_store.festivals.attended.clear()
		festival_overlay.open_today()
		var cancelled_festival_id := StringName(festival_overlay.festival.get("id", ""))
		await process_frame
		await _send_runtime_key(KEY_ESCAPE)
		if festival_overlay.visible or paused or state_store.calendar.paused or state_store.festivals.has_attended(cancelled_festival_id, state_store.calendar.year):
			failures.append("Escape could not abandon an unfinished festival without consuming attendance")
	paused = false
	state_store.pause_game_time(false)
	if is_instance_valid(game):
		game.queue_free()
	await process_frame
func _send_runtime_key(keycode: int) -> void:
	var press := InputEventKey.new()
	press.pressed = true
	press.keycode = keycode
	press.physical_keycode = keycode
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventKey.new()
	release.pressed = false
	release.keycode = keycode
	release.physical_keycode = keycode
	Input.parse_input_event(release)
	await process_frame


func _assert_test_storage_isolation(failures: PackedStringArray) -> void:
	if OS.get_environment("PIXELRPG_TEST_ISOLATED") != "1":
		return
	var save_manager: Node = root.get_node("SaveManager")
	var network_manager: Node = root.get_node("NetworkManager")
	if save_manager.quick_save_path() == "user://pixelrpg_quick_save.json":
		failures.append("Isolated tests can still overwrite the player's quick save")
	if PixelRPGInputBindings.settings_path() == "user://pixelrpg_input.json":
		failures.append("Isolated tests can still overwrite the player's input bindings")
	if network_manager.server_world_directory() != "user://pixelrpg_test_servers" or network_manager.client_id_path() != "user://pixelrpg_test_client_id.txt":
		failures.append("Isolated tests can still overwrite the player's multiplayer data")


func _assert_content(registry: Node, failures: PackedStringArray) -> void:
	if registry.get_all("seasons").size() != 4:
		failures.append("Expected four seasons")
	if registry.get_all("crops").size() != 48:
		failures.append("Expected 48 crops")
	if registry.get_all("festivals").size() != 12:
		failures.append("Expected 12 festivals")
	if registry.get_all("npc_schedules").size() != 10:
		failures.append("Expected 10 NPC schedules")
	if registry.get_all("npc_dialogues").size() != 10:
		failures.append("Expected ten long-form NPC dialogue banks")
	if registry.get_all("recipes").size() != 40:
		failures.append("Expected 40 recipes")
	if registry.get_all("fish").size() != 20:
		failures.append("Expected 12 seasonal fish and eight eldritch fish")
	if registry.get_all("tools").size() != 6 or registry.get_all("shops").size() != 4 or registry.get_all("achievements").size() != 14:
		failures.append("Commercial economy catalogs are incomplete")
	if registry.get_all("automation_devices").size() != 9:
		failures.append("Expected nine farm automation devices")
	if registry.get_all("quests").size() < 14 or registry.get_all("dialogues").size() < 14:
		failures.append("Three-year playable narrative content is incomplete")
	var dungeon_definition: Dictionary = registry.get_artifact("dungeons", &"mistfall_depths")
	if Array(dungeon_definition.get("enemy_ids", [])).size() != 12 or Array(dungeon_definition.get("boss_ids", [])).size() != 4:
		failures.append("Dungeon must define 12 common enemies and four bosses")
	for season_id in ["spring", "summer", "autumn", "winter"]:
		var count := 0
		for crop: Dictionary in registry.get_all("crops"):
			if season_id in crop.get("seasons", []):
				count += 1
		if count != 12:
			failures.append("Season %s must have 12 crops" % season_id)


func _assert_calendar(failures: PackedStringArray) -> void:
	var calendar: RefCounted = load("res://runtime/calendar/calendar_system.gd").new()
	calendar.day = 30
	calendar.season_index = 0
	calendar.advance_day()
	if calendar.day != 1 or calendar.season_index != 1 or calendar.year != 1:
		failures.append("Spring day 30 did not roll to summer day 1")
	calendar.day = 30
	calendar.season_index = 3
	calendar.advance_day()
	if calendar.day != 1 or calendar.season_index != 0 or calendar.year != 2:
		failures.append("Winter day 30 did not roll to next year")
	calendar.reset()
	for _index in range(1200):
		calendar.advance_day()
	if calendar.year != 11 or calendar.season_index != 0 or calendar.day != 1:
		failures.append("Ten-year/1200-day simulation drifted")
	for mode in ["fast", "standard", "relaxed"]:
		calendar.reset()
		calendar.set_speed(mode)
		var seconds := float(PixelRPGCalendarSystem.SPEED_SECONDS[mode])
		calendar.process(seconds)
		if calendar.minute_of_day != PixelRPGCalendarSystem.DAY_END_MINUTE:
			failures.append("Speed mode %s did not reach 24:00 deterministically" % mode)


func _assert_input_bindings(failures: PackedStringArray) -> void:
	PixelRPGInputBindings.reset_to_project_defaults()
	var baseline := _input_binding_snapshot()
	var null_candidates: Dictionary = {}
	if PixelRPGInputBindings._load_candidates_from_file(null, null_candidates):
		failures.append("A null input settings file was accepted")
	if not _write_input_contents("{"):
		failures.append("Could not create the corrupt input settings fixture")
	else:
		if PixelRPGInputBindings._load_from_path(INPUT_BINDINGS_TEST_PATH):
			failures.append("Corrupt input settings JSON was accepted")
		if _input_binding_snapshot() != baseline:
			failures.append("Corrupt input settings changed the current InputMap")

	if not _write_input_payload({"schema_version": 1, "actions": []}):
		failures.append("Could not create the malformed input settings fixture")
	else:
		if PixelRPGInputBindings._load_from_path(INPUT_BINDINGS_TEST_PATH):
			failures.append("A non-dictionary input actions payload was accepted")
		if _input_binding_snapshot() != baseline:
			failures.append("Malformed input settings changed the current InputMap")

	var partial_payload := {
		"schema_version": 1,
		"actions": {
			"attack": [{"type": "key", "physical_keycode": KEY_P, "keycode": 0}],
		},
	}
	if not _write_input_payload(partial_payload):
		failures.append("Could not create the partial input settings fixture")
	else:
		if PixelRPGInputBindings._load_from_path(INPUT_BINDINGS_TEST_PATH):
			failures.append("A partial input actions payload was accepted")
		if _input_binding_snapshot() != baseline:
			failures.append("Partial input settings cleared or changed default bindings")

	var valid_payload: Variant = null
	if not PixelRPGInputBindings._save_to_path(INPUT_BINDINGS_TEST_PATH):
		failures.append("Could not save the default input bindings fixture")
	else:
		valid_payload = _read_input_payload()
	if valid_payload is Dictionary:
		var invalid_payload: Dictionary = valid_payload.duplicate(true)
		invalid_payload["actions"]["attack"] = [{"type": "key", "physical_keycode": "not-a-key"}]
		if not _write_input_payload(invalid_payload):
			failures.append("Could not create the invalid input event fixture")
		else:
			if PixelRPGInputBindings._load_from_path(INPUT_BINDINGS_TEST_PATH):
				failures.append("An invalid input event record was accepted")
			if _input_binding_snapshot() != baseline:
				failures.append("An invalid input event partially changed the InputMap")

		var empty_action_payload: Dictionary = valid_payload.duplicate(true)
		empty_action_payload["actions"]["attack"] = []
		if not _write_input_payload(empty_action_payload):
			failures.append("Could not create the empty input action fixture")
		else:
			if PixelRPGInputBindings._load_from_path(INPUT_BINDINGS_TEST_PATH):
				failures.append("An input action without events was accepted")
			if _input_binding_snapshot() != baseline:
				failures.append("An empty input action cleared default bindings")

		var legacy_payload: Dictionary = valid_payload.duplicate(true)
		for records: Array in legacy_payload["actions"].values():
			for record: Dictionary in records:
				for new_field: String in ["device", "key_label", "location", "alt_pressed", "shift_pressed", "ctrl_pressed", "meta_pressed"]:
					record.erase(new_field)
		if not _write_input_payload(legacy_payload):
			failures.append("Could not create the legacy input settings fixture")
		else:
			PixelRPGInputBindings.reset_to_project_defaults()
			if not PixelRPGInputBindings._load_from_path(INPUT_BINDINGS_TEST_PATH):
				failures.append("A complete legacy schema-1 input payload could not be loaded")
			elif _input_binding_snapshot() != baseline:
				failures.append("Legacy schema-1 input defaults did not round-trip")
	else:
		failures.append("Saved input bindings did not produce a JSON dictionary")

	PixelRPGInputBindings.reset_to_project_defaults()
	var mac_key := InputEventKey.new()
	mac_key.device = PixelRPGInputBindings.KEYBOARD_DEVICE_ID
	mac_key.physical_keycode = KEY_P
	mac_key.keycode = KEY_P
	mac_key.key_label = KEY_P
	mac_key.location = KEY_LOCATION_LEFT
	mac_key.alt_pressed = true
	mac_key.shift_pressed = true
	mac_key.ctrl_pressed = true
	mac_key.meta_pressed = true
	mac_key.pressed = true
	mac_key.echo = true
	mac_key.unicode = 112
	if not PixelRPGInputBindings.rebind_device(&"attack", mac_key):
		failures.append("Could not create a macOS modifier binding")
	elif not PixelRPGInputBindings._save_to_path(INPUT_BINDINGS_TEST_PATH):
		failures.append("Could not save a macOS modifier binding")
	else:
		var serialized_payload: Variant = _read_input_payload()
		var serialized_mac_key: Dictionary = {}
		if serialized_payload is Dictionary:
			for record: Dictionary in serialized_payload["actions"]["attack"]:
				if record.get("type", "") == "key" and int(record.get("physical_keycode", 0)) == KEY_P:
					serialized_mac_key = record
					break
		if serialized_mac_key.is_empty():
			failures.append("The macOS modifier key was missing from saved bindings")
		elif serialized_mac_key.has("pressed") or serialized_mac_key.has("echo") or serialized_mac_key.has("unicode"):
			failures.append("Transient key state was persisted with an input mapping")
		PixelRPGInputBindings.reset_to_project_defaults()
		if not PixelRPGInputBindings._load_from_path(INPUT_BINDINGS_TEST_PATH):
			failures.append("Could not reload a macOS modifier binding")
		else:
			var restored_key: InputEventKey = null
			for event: InputEvent in InputMap.action_get_events(&"attack"):
				if event is InputEventKey and event.physical_keycode == KEY_P:
					restored_key = event
					break
			if restored_key == null:
				failures.append("The macOS modifier key did not round-trip")
			elif not restored_key.alt_pressed or not restored_key.shift_pressed or not restored_key.ctrl_pressed or not restored_key.meta_pressed:
				failures.append("Alt/Shift/Ctrl/Meta modifiers did not round-trip")
			elif restored_key.keycode != KEY_P or restored_key.key_label != KEY_P or restored_key.location != KEY_LOCATION_LEFT or restored_key.device != PixelRPGInputBindings.KEYBOARD_DEVICE_ID:
				failures.append("Key code, label, location, or device did not round-trip")
			elif restored_key.is_pressed() or restored_key.is_echo() or restored_key.unicode != 0:
				failures.append("Transient pressed/echo/unicode state was restored")

	PixelRPGInputBindings.reset_to_project_defaults()
	var absolute_test_path := ProjectSettings.globalize_path(INPUT_BINDINGS_TEST_PATH)
	if FileAccess.file_exists(INPUT_BINDINGS_TEST_PATH) and DirAccess.remove_absolute(absolute_test_path) != OK:
		failures.append("Could not remove the input bindings smoke-test fixture")


func _write_input_payload(payload: Variant) -> bool:
	return _write_input_contents(JSON.stringify(payload))


func _write_input_contents(contents: String) -> bool:
	var file := FileAccess.open(INPUT_BINDINGS_TEST_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(contents)
	file.close()
	return true


func _read_input_payload() -> Variant:
	var file := FileAccess.open(INPUT_BINDINGS_TEST_PATH, FileAccess.READ)
	if file == null:
		return null
	var contents := file.get_as_text()
	file.close()
	return JSON.parse_string(contents)


func _input_binding_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for action: StringName in PixelRPGInputBindings.PERSISTED_ACTIONS:
		if not InputMap.has_action(action):
			continue
		var records: Array[Dictionary] = []
		for event: InputEvent in InputMap.action_get_events(action):
			records.append(PixelRPGInputBindings._serialize_event(event))
		snapshot[String(action)] = records
	return snapshot


func _assert_farming(failures: PackedStringArray) -> void:
	var farm: RefCounted = load("res://runtime/farming/farm_system.gd").new()
	farm.reset()
	var tile := Vector2i(0, 0)
	farm.interact_plot(tile, &"spring_turnip", &"spring")
	farm.interact_plot(tile, &"spring_turnip", &"spring")
	for day_index in range(3):
		farm.interact_plot(tile, &"spring_turnip", &"spring")
		farm.advance_day(&"spring", "clear")
	var plot: Dictionary = farm.plots["0,0"]
	if not bool(plot.get("ready", false)):
		failures.append("Three-day crop did not mature after three watered days")
	var harvest: Dictionary = farm.harvest(tile)
	if not bool(harvest.get("ok", false)) or int(farm.produce.get("spring_turnip", 0)) < 1:
		failures.append("Mature crop could not be harvested")
	farm.interact_plot(Vector2i(1, 0), &"spring_turnip", &"spring")
	farm.interact_plot(Vector2i(1, 0), &"spring_turnip", &"spring")
	farm.advance_day(&"summer", "clear")
	if not bool(Dictionary(farm.plots["1,0"]).get("withered", false)):
		failures.append("Out-of-season crop did not wither")
	farm.rank = 3
	var purchase: Dictionary = farm.purchase_animal("chicken")
	if not bool(purchase.get("ok", false)):
		failures.append("Rank-three farm could not purchase a chicken")
		return
	var grazing: Dictionary = farm.tend_animal("chicken_1", false, true)
	farm.advance_day(&"summer", "clear")
	var grazed_animal: Dictionary = farm.animals[0]
	if not bool(grazing.get("ok", false)) or not bool(grazed_animal.get("product_ready", false)) or int(grazed_animal.get("mood", 0)) != 64:
		failures.append("Clear-weather grazing did not count as daily care and produce an animal product")
	var clear_product: Dictionary = farm.collect_animal_product("chicken_1")
	var fog_grazing: Dictionary = farm.tend_animal("chicken_1", false, true)
	farm.advance_day(&"summer", "fog")
	if not bool(clear_product.get("ok", false)) or not bool(fog_grazing.get("ok", false)) or not bool(Dictionary(farm.animals[0]).get("product_ready", false)):
		failures.append("Fog-weather grazing did not count as daily care and produce an animal product")
	farm.animals[0]["hearts"] = 5
	var breeding: Dictionary = farm.begin_breeding("chicken_1")
	if not bool(breeding.get("ok", false)):
		failures.append("Five-heart animal could not begin breeding")
	for _day in range(7):
		farm.advance_day(&"summer", "clear")
	if farm.animals.size() != 2:
		failures.append("Chicken gestation did not create an offspring")
	if farm.animal_capacity() != 2 or bool(farm.purchase_animal("chicken").get("ok", false)):
		failures.append("Rank-three livestock capacity did not prevent overlapping overflow animals")
	farm.rank = 10
	while farm.animals.size() < farm.animal_capacity():
		if not bool(farm.purchase_animal("chicken").get("ok", false)):
			failures.append("Expanded livestock capacity rejected a legal animal slot")
			break
	if farm.animals.size() != farm.animal_capacity() or bool(farm.purchase_animal("cow").get("ok", false)):
		failures.append("Maximum livestock capacity is not enforced at the commercial farm rank")


func _assert_social(failures: PackedStringArray) -> void:
	var social: RefCounted = load("res://runtime/social/social_system.gd").new()
	social.reset()
	social.add_affection(&"mira", 2500)
	if not social.start_dating(&"mira") or not social.marry(&"mira", 1):
		failures.append("Ten-heart dating/marriage path failed")
	if not social.can_start_family_talk(31):
		failures.append("Family talk did not unlock after 30 days")
	social.confirm_family_talk()
	if not social.welcome_child("小鐘", 61):
		failures.append("Child arrival did not unlock after 60 married days")
	if social.update_child_stage(61 + 29) != "baby" or social.update_child_stage(61 + 30) != "toddler" or social.update_child_stage(61 + 90) != "child" or social.update_child_stage(61 + 210) != "teen":
		failures.append("Child stage boundaries are incorrect")


func _assert_farm_automation(registry: Node, failures: PackedStringArray) -> void:
	var farm: RefCounted = load("res://runtime/farming/farm_system.gd").new()
	farm.reset()
	farm.rank = 10
	var placements := [
		[Vector2i(0, 0), "bell_generator", 100], [Vector2i(0, 1), "bell_generator", 100],
		[Vector2i(1, 0), "mist_pump", 90], [Vector2i(2, 0), "field_sprinkler", 80],
		[Vector2i(2, 1), "seed_distributor", 70], [Vector2i(3, 1), "crop_harvester", 95],
		[Vector2i(3, 0), "preserves_processor", 60], [Vector2i(4, 0), "animal_feeder", 50],
		[Vector2i(5, 0), "tide_condenser", 40],
	]
	for entry: Array in placements:
		var placed: Dictionary = farm.place_automation_device(entry[0], StringName(entry[1]), {"priority": entry[2], "crop_filter": "spring_turnip"})
		if not bool(placed.get("ok", false)):
			failures.append("Automation placement failed for %s" % entry[1])
	var ready_tile := Vector2i(4, 1)
	farm.plots["4,1"] = {"tile":[4,1],"tilled":true,"watered":false,"crop_id":"spring_turnip","growth_progress":3,"ready":true,"withered":false}
	farm.plots["2,0"] = {"tile":[2,0],"tilled":true,"watered":false,"crop_id":"spring_potato","growth_progress":0,"ready":false,"withered":false}
	farm.produce["spring_turnip"] = 2
	var tide_fish_id := ""
	for fish: Dictionary in registry.get_all("fish"):
		if bool(fish.get("tide_required", false)):
			tide_fish_id = String(fish.get("id", ""))
			break
	farm.produce[tide_fish_id] = 1
	farm.animals.append({"id":"chicken_1","species":"chicken","name":"測試雞","hearts":0,"mood":50,"fed":false,"grazed":false,"product_ready":false,"pregnant_days":0})
	var inventory := {"animal_feed": 1, "mist_shard": 1}
	var report: Dictionary = farm.run_automation_day(&"spring", inventory)
	if int(report.get("networks", 0)) != 1 or int(report.get("stalled", 0)) != 0:
		failures.append("Connected automation network did not balance power/water")
	if int(report.get("watered", 0)) < 1 or int(report.get("harvested", 0)) < 1 or int(report.get("fed", 0)) != 1 or int(report.get("processed", 0)) != 2:
		failures.append("Automation did not water/harvest/feed/process deterministically")
	if int(farm.produce.get("mist_preserves", 0)) != 1 or int(farm.produce.get("dream_tide_salt", 0)) != 1 or int(inventory.get("animal_feed", 0)) != 0:
		failures.append("Automation outputs or consumable accounting are incorrect")
	farm.animals[0]["fed"] = false
	farm.animals[0]["grazed"] = true
	inventory["animal_feed"] = 1
	var grazed_report: Dictionary = farm.run_automation_day(&"spring", inventory)
	if int(grazed_report.get("fed", 0)) != 0 or int(inventory.get("animal_feed", 0)) != 1:
		failures.append("Animal feeder consumed feed for an animal already cared for by grazing")
	var saved: Dictionary = farm.to_data()
	var restored: RefCounted = load("res://runtime/farming/farm_system.gd").new()
	restored.reset()
	restored.load_data(saved)
	if restored.automation_devices.size() != 9 or restored.automation_cycle_count != 2:
		failures.append("Automation network did not survive save round-trip")
	var isolated: RefCounted = load("res://runtime/farming/farm_system.gd").new()
	isolated.reset()
	isolated.rank = 10
	isolated.place_automation_device(Vector2i(5, 3), &"field_sprinkler")
	var stalled_report: Dictionary = isolated.run_automation_day(&"spring", {})
	if int(stalled_report.get("stalled", 0)) != 1:
		failures.append("Unpowered isolated machine must report a stall")
	if bool(stalled_report.get("cycle_ran", true)) or isolated.automation_cycle_count != 0:
		failures.append("A stalled automation device must not count as an operated cycle")


func _assert_dungeon(failures: PackedStringArray) -> void:
	var dungeon: RefCounted = load("res://runtime/dungeon/dungeon_system.gd").new()
	dungeon.reset()
	for floor_number in range(1, 41):
		if not dungeon.enter_floor(floor_number):
			failures.append("Could not enter sequential dungeon floor %d" % floor_number)
			return
		dungeon.clear_current_floor()
	if dungeon.seals.size() != 4 or not dungeon.can_challenge_final_boss():
		failures.append("Four seasonal dungeon seals were not awarded")
	if not dungeon.defeat_final_boss() or not dungeon.endless_unlocked:
		failures.append("Final boss did not unlock endless mode")
	if dungeon.rescue_cost(999) != 100:
		failures.append("Clinic rescue must charge rounded-up 10 percent")


func _assert_eldritch_fishing(registry: Node, state_store: Node, failures: PackedStringArray) -> void:
	var fishing: RefCounted = load("res://runtime/farming/fishing_system.gd").new()
	var location_cases := [
		[&"summer", 12 * 60, "clear", "pond", "sun_bass"],
		[&"summer", 12 * 60, "clear", "river", "blue_mackerel"],
		[&"autumn", 18 * 60, "clear", "pond", "moon_perch"],
		[&"winter", 10 * 60, "snow", "pond", "ice_smelt"],
		[&"winter", 10 * 60, "snow", "river", "snow_cod"],
	]
	for location_case: Array in location_cases:
		var fish_ids: Array[String] = []
		for fish: Dictionary in fishing.available_fish(location_case[0], location_case[1], location_case[2], location_case[3]):
			fish_ids.append(String(fish.get("id", "")))
		if String(location_case[4]) not in fish_ids:
			failures.append("Playable %s fishing location did not expose %s" % [location_case[3], location_case[4]])
	state_store.reset()
	state_store.lifetime_stats["eldritch_fish_caught"] = 4
	state_store.eldritch.eldritch_catches = {"whisper_minnow": 4}
	state_store._check_achievements()
	if "abyssal_angler" in state_store.achievements.unlocked:
		failures.append("Repeated catches of one eldritch fish incorrectly unlocked the four-species achievement")
	state_store.reset()
	state_store.tools.tool_levels["fishing_rod"] = 4
	for season_index in range(4):
		state_store.calendar.season_index = season_index
		state_store.calendar.day = 13
		state_store.calendar.minute_of_day = 19 * 60
		state_store.current_weather = "clear"
		var catch_result: Dictionary = state_store.fish_at("pond")
		if not bool(catch_result.get("ok", false)) or not bool(catch_result.get("eldritch", false)):
			failures.append("Eldritch tide fishing failed in season %d" % season_index)
	if state_store.eldritch.eldritch_catches.size() != 4 or not state_store.eldritch.can_challenge() or "abyssal_angler" not in state_store.achievements.unlocked:
		failures.append("Four seasonal eldritch catches did not unlock the drowned dreamer")
	if state_store.eldritch.sanity >= 100 or int(state_store.lifetime_stats.get("eldritch_fish_caught", 0)) != 4:
		failures.append("Eldritch catches did not update sanity and lifetime metrics")
	var sanity_before: int = state_store.eldritch.sanity
	state_store.eldritch.recover_new_day()
	if state_store.eldritch.sanity <= sanity_before:
		failures.append("Sleeping did not recover eldritch sanity")
	var boss: Dictionary = registry.get_artifact("enemies", &"drowned_dreamer")
	if boss.is_empty() or not bool(boss.get("is_boss", false)) or String(boss.get("sprite", "")).is_empty():
		failures.append("Drowned dreamer boss definition or sprite contract is incomplete")
	var boss_result: Dictionary = state_store.defeat_eldritch_boss()
	if not bool(boss_result.get("ok", false)) or not state_store.eldritch.boss_defeated or int(state_store.inventory.get("abyssal_relic", 0)) != 1:
		failures.append("Eldritch boss completion did not persist its quest relic")


func _assert_multiplayer_rules(failures: PackedStringArray) -> void:
	var variants := [PixelRPGMultiplayerNarrativeSystem.story_variant(1, "shared", "independent").id, PixelRPGMultiplayerNarrativeSystem.story_variant(2, "private", "competitive").id, PixelRPGMultiplayerNarrativeSystem.story_variant(4, "competitive", "competitive").id, PixelRPGMultiplayerNarrativeSystem.story_variant(5, "shared", "independent").id]
	if variants != ["solo_bell", "twin_bell_pact", "four_season_chorus", "mistfall_council"]:
		failures.append("Multiplayer player-count story variants are incomplete")
	var worlds := {
		"a":{"farm":{"rank":2,"plots":{"0:0":{"state":"tilled"}}},"economy":{"total_earned":100},"lifetime_stats":{"crops_harvested":2},"relationships":{"mira":{"friendship":2500,"dating":true}}},
		"b":{"farm":{"rank":1,"plots":{"0:0":{"state":"tilled"}}},"economy":{"total_earned":50},"lifetime_stats":{"crops_harvested":1},"relationships":{"mira":{"friendship":2500,"dating":true}}},
	}
	var leaderboard := PixelRPGMultiplayerNarrativeSystem.farm_leaderboard(worlds, {"a":"甲","b":"乙"})
	if leaderboard.size() != 2 or String(leaderboard[0].player_key) != "a":
		failures.append("Competitive private farm leaderboard is not deterministic")
	var tie := PixelRPGMultiplayerNarrativeSystem.proposal_verdict("a", "mira", worlds, {}, true)
	if bool(tie.get("ok", false)) or "平手" not in String(tie.get("message", "")):
		failures.append("Competitive romance tie should block proposal")
	worlds["a"]["relationships"]["mira"]["friendship"] = 2501
	if not bool(PixelRPGMultiplayerNarrativeSystem.proposal_verdict("a", "mira", worlds, {}, true).get("ok", false)):
		failures.append("Leading romance competitor should be allowed to propose")


func _assert_save_migration(state_store: Node, failures: PackedStringArray) -> void:
	state_store.reset()
	var save_data: Dictionary = state_store.to_save_data()
	if int(save_data.get("schema_version", 0)) != 6 or not save_data.has("world") or not save_data.has("calendar") or not save_data.has("farm") or not save_data.has("dungeon") or not save_data.has("eldritch") or not save_data.has("economy") or not save_data.has("tools"):
		failures.append("SaveGame v6 contract is incomplete")
	var v5_save := save_data.duplicate(true)
	v5_save["schema_version"] = 5
	v5_save.erase("world")
	var v5_player: Dictionary = Dictionary(v5_save.get("player", {})).duplicate(true)
	v5_player.erase("facing")
	v5_save["player"] = v5_player
	if not state_store.load_save_data(v5_save) or state_store.current_portal_id != &"legacy_v5":
		failures.append("SaveGame v5 world-state migration failed")
	var v4_save := save_data.duplicate(true)
	v4_save["schema_version"] = 4
	var v4_farm: Dictionary = Dictionary(v4_save.get("farm", {})).duplicate(true)
	for key in ["automation_devices", "automation_cycle_count", "automation_last_report"]:
		v4_farm.erase(key)
	v4_save["farm"] = v4_farm
	if not state_store.load_save_data(v4_save) or not state_store.farm.automation_devices.is_empty():
		failures.append("SaveGame v4 automation migration failed")
	var v3_save := save_data.duplicate(true)
	v3_save["schema_version"] = 3
	v3_save.erase("eldritch")
	var v3_stats: Dictionary = Dictionary(v3_save.get("lifetime_stats", {})).duplicate(true)
	v3_stats.erase("eldritch_fish_caught")
	v3_stats.erase("eldritch_bosses_defeated")
	v3_save["lifetime_stats"] = v3_stats
	if not state_store.load_save_data(v3_save) or state_store.eldritch.sanity != 100:
		failures.append("SaveGame v3 migration failed")
	var v2_save := save_data.duplicate(true)
	v2_save["schema_version"] = 2
	for key in ["tools", "economy", "achievements", "lifetime_stats", "settings"]:
		v2_save.erase(key)
	if not state_store.load_save_data(v2_save) or state_store.tools.stamina != 100:
		failures.append("SaveGame v2 migration failed")
	var legacy := {"schema_version": 1, "player": {"position": [12, 34], "stats": {"max_health": 100, "health": 80, "attack": 16}}, "map": "sample_arena", "flags": {}, "quests": {}, "inventory": {"health_potion": 1}, "calendar": {"year": 2, "season_index": 2, "day": 28, "minute_of_day": 720, "speed_mode": "relaxed"}}
	if not state_store.load_save_data(legacy):
		failures.append("SaveGame v1 migration failed")
	elif state_store.calendar.day != 28 or state_store.calendar.season_index != 2 or state_store.calendar.year != 2 or state_store.current_map_id != &"mistfall_farm" or state_store.player_position != Vector2(318, 300):
		failures.append("SaveGame v1 migration did not preserve time or safely relocate an unknown legacy map")


func _assert_commercial_systems(state_store: Node, failures: PackedStringArray) -> void:
	state_store.reset()
	state_store.calendar.minute_of_day = 600
	state_store.farm.rank = 6
	state_store.coins = 1000
	if bool(state_store.buy_offer(&"toma_general_store", "glass_10").get("ok", false)):
		failures.append("Rank-seven glass offer was available before its required farm rank")
	state_store.farm.rank = 7
	var glass_purchase: Dictionary = state_store.buy_offer(&"toma_general_store", "glass_10")
	if not bool(glass_purchase.get("ok", false)) or int(state_store.inventory.get("glass", 0)) != 10 or state_store.coins != 0:
		failures.append("Rank-seven Toma offer did not sell ten glass for 1000G")
	state_store.reset()
	state_store.calendar.minute_of_day = 600
	state_store.farm.rank = 2
	state_store.inventory["copper_ore"] = 10
	state_store.coins = 5000
	var upgrade: Dictionary = state_store.buy_offer(&"soren_forge", "hoe_lv2")
	if not bool(upgrade.get("ok", false)) or int(state_store.tools.tool_levels.get("hoe", 1)) != 2 or int(state_store.inventory.get("copper_ore", 0)) != 5:
		failures.append("Tool upgrade purchase did not consume price/materials")
	state_store.farm.produce["spring_turnip"] = 2
	var coins_before: int = int(state_store.coins)
	var shipping: Dictionary = state_store.ship_all_produce()
	if not bool(shipping.get("ok", false)) or int(state_store.economy.pending_value()) != 110:
		failures.append("Shipping bin did not price crop produce")
	state_store.advance_day()
	if state_store.coins != coins_before + 110 or int(state_store.lifetime_stats.get("coins_earned", 0)) != 110:
		failures.append("Overnight shipping settlement failed")
	state_store.lifetime_stats["crops_harvested"] = 1
	state_store._check_achievements()
	if "first_harvest" not in state_store.achievements.unlocked:
		failures.append("Achievement condition did not unlock")
	state_store.reset()
	state_store.calendar.day = 8
	var festival_coins: int = state_store.coins
	var festival_result: Dictionary = state_store.attend_today_festival(80)
	if not bool(festival_result.get("ok", false)) or int(festival_result.get("reward", 0)) != 168 or state_store.coins != festival_coins + 168:
		failures.append("Scored festival activity did not grant the participation and skill reward")
	if bool(state_store.attend_today_festival(100).get("ok", true)):
		failures.append("Festival could be attended twice in the same year")


func _assert_story(registry: Node, state_store: Node, failures: PackedStringArray) -> void:
	state_store.reset()
	var story: RefCounted = load("res://runtime/world/story_progress_system.gd").new()
	var arc: Dictionary = registry.get_artifact("story_arcs", &"mistfall_three_years")
	if Array(arc.get("chapters", [])).size() != 12 or arc.get("deadline", 1) != null:
		failures.append("Story arc must contain 12 no-deadline chapters")
		return
	var completed: Array = []
	var flags: Dictionary = {}
	var complete_metrics := {"crops_harvested":1000,"fish_caught":100,"eldritch_fish_caught":20,"dungeon_floor":40,"bosses_defeated":4,"farm_rank":10,"festivals_attended":12,"days_played":360,"purchases":50,"tool_upgrades":18,"relationship_max_hearts":10,"relationship_unique_villagers":10,"romance_candidates_known":4,"dating_candidates":4,"monsters_defeated":100,"season_seals":4,"final_boss_defeated":1,"eldritch_unique_catches":8,"eldritch_boss_defeated":1,"automation_devices":9,"automation_networks":2,"automation_cycles":100,"automation_items_processed":50}
	for expected_chapter: Dictionary in arc.get("chapters", []):
		var chapter: Dictionary = story.next_available(completed, flags)
		if chapter.get("id", "") != expected_chapter.get("id", ""):
			failures.append("Story chapter prerequisites do not form a continuous 12-chapter chain")
			return
		if not bool(story.requirements_met(chapter, complete_metrics).get("ok", false)):
			failures.append("Story chapter has an unsatisfiable metric: %s" % chapter.get("id", ""))
			return
		story.complete(String(chapter.get("id", "")), completed, flags)
	if not story.next_available(completed, flags).is_empty():
		failures.append("Story did not finish after twelve chapters")
	state_store.reset()
	state_store.lifetime_stats["crops_harvested"] = 1
	state_store.social.add_affection(&"mira", 250)
	state_store.social.add_affection(&"toma", 250)
	var first_result: Dictionary = state_store.try_complete_current_story_chapter()
	if not bool(first_result.get("ok", false)) or String(state_store.quest_states.get("y1_spring_new_soil_quest", "")) != "completed":
		failures.append("Runtime could not complete and reward the first story chapter")


func _finish(failures: PackedStringArray) -> void:
	if failures.is_empty():
		print("PixelRPG farming Godot test suite: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
