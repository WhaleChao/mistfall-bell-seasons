extends SceneTree

const INPUT_BINDINGS_TEST_PATH := "user://pixelrpg_input_smoke_test.json"


func _initialize() -> void:
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
	farm.animals[0]["hearts"] = 5
	var breeding: Dictionary = farm.begin_breeding("chicken_1")
	if not bool(breeding.get("ok", false)):
		failures.append("Five-heart animal could not begin breeding")
	for _day in range(7):
		farm.advance_day(&"summer", "clear")
	if farm.animals.size() != 2:
		failures.append("Chicken gestation did not create an offspring")


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
	var saved: Dictionary = farm.to_data()
	var restored: RefCounted = load("res://runtime/farming/farm_system.gd").new()
	restored.reset()
	restored.load_data(saved)
	if restored.automation_devices.size() != 9 or restored.automation_cycle_count != 1:
		failures.append("Automation network did not survive save round-trip")
	var isolated: RefCounted = load("res://runtime/farming/farm_system.gd").new()
	isolated.reset()
	isolated.rank = 10
	isolated.place_automation_device(Vector2i(5, 3), &"field_sprinkler")
	if int(isolated.run_automation_day(&"spring", {}).get("stalled", 0)) != 1:
		failures.append("Unpowered isolated machine must report a stall")


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
	if state_store.eldritch.eldritch_catches.size() != 4 or not state_store.eldritch.can_challenge():
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
	if int(save_data.get("schema_version", 0)) != 5 or not save_data.has("calendar") or not save_data.has("farm") or not save_data.has("dungeon") or not save_data.has("eldritch") or not save_data.has("economy") or not save_data.has("tools"):
		failures.append("SaveGame v5 contract is incomplete")
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
	elif state_store.calendar.day != 28 or state_store.calendar.season_index != 2 or state_store.calendar.year != 2 or state_store.player_position != Vector2(12, 34):
		failures.append("SaveGame v1 migration did not preserve legacy state")


func _assert_commercial_systems(state_store: Node, failures: PackedStringArray) -> void:
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
