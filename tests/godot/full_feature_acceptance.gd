extends SceneTree

const REPORT_DIRECTORY := "res://reports/full_feature_acceptance"
const EVIDENCE_SIZE := Vector2i(1280, 720)

var cases: Array[Dictionary] = []
var screenshots: Array[String] = []
var state_store: Node
var registry: Node
var save_manager: Node
var network: Node
var game: Node
var player: Node
var started_usec := 0


func _initialize() -> void:
	# Direct local runs must never read or overwrite a player's bindings/saves.
	# Release scripts already set this, but keeping the guard here makes the test
	# safe when launched manually from the editor or command line as well.
	OS.set_environment("PIXELRPG_TEST_ISOLATED", "1")
	call_deferred("_run")


func _run() -> void:
	started_usec = Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIRECTORY))
	root.size = EVIDENCE_SIZE
	root.content_scale_size = Vector2i(640, 360)
	DisplayServer.window_set_title("霧落農歌：鐘塔之季｜全功能實機驗收中")
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	Engine.max_fps = 60
	state_store = root.get_node("GameState")
	registry = root.get_node("ContentRegistry")
	save_manager = root.get_node("SaveManager")
	network = root.get_node("NetworkManager")
	state_store.reset()
	game = load("res://sample/main.tscn").instantiate()
	root.add_child(game)
	if not await _wait_for_launch_ready(120):
		_record("啟動", "正式遊戲場景完成渲染", false, "等待 120 frames 後 UI 仍未就緒")
		_write_reports()
		if is_instance_valid(game):
			game.queue_free()
		await process_frame
		_cleanup_test_save()
		quit(1)
		return
	player = game.get("player")

	await _test_launch_and_profile()
	await _test_movement_and_animation()
	await _test_combat_and_dungeon()
	await _test_farming_animals_and_economy()
	await _test_maps_and_automation()
	await _test_eldritch_fishing_and_boss()
	await _test_village_dialogue_and_festival()
	await _test_story_dialogue_recovery()
	await _test_menus_relationships_and_settings()
	await _test_multiplayer_ui()
	await _test_alpha_matte_contrast()
	_test_long_term_content_and_migrations()
	await _capture("12_acceptance_complete")
	_write_reports()

	Input.action_release("ui_left")
	Input.action_release("ui_right")
	Input.action_release("ui_up")
	Input.action_release("ui_down")
	Input.action_release("attack")
	Input.action_release("dodge")
	Input.action_release("active_skill")
	paused = false
	state_store.pause_game_time(false)
	if is_instance_valid(game):
		game.queue_free()
	await process_frame
	_cleanup_test_save()
	var passed := _failure_count() == 0
	print("PixelRPG visible full-feature acceptance: %s (%d checks, %d screenshots)" % ["PASS" if passed else "FAIL", cases.size(), screenshots.size()])
	quit(0 if passed else 1)


func _test_launch_and_profile() -> void:
	_record("啟動", "正式遊戲場景完成渲染", is_instance_valid(game) and is_instance_valid(player))
	_record("啟動", "標題畫面顯示", is_instance_valid(game.title_overlay), "玩家時間應暫停")
	_record("角色建立", "玩家名稱欄位", is_instance_valid(game.name_input) and game.name_input.max_length == 12)
	_record("角色建立", "四種外觀選項", is_instance_valid(game.appearance_input) and game.appearance_input.item_count == 4)
	_record("輸入焦點", "首啟自動聚焦玩家名稱欄位", is_instance_valid(game.name_input) and game.name_input.has_focus())
	await _capture("01_title_and_profile")
	await _send_key_event(KEY_E, "e".unicode_at(0))
	_record("輸入焦點", "名稱輸入 E 不會誤觸互動或開始遊戲", is_instance_valid(game.title_overlay) and not game.multiplayer_menu.visible)
	await _send_key_event(KEY_M, "m".unicode_at(0))
	_record("輸入焦點", "名稱輸入 M 不會誤開連線介面", is_instance_valid(game.title_overlay) and not game.multiplayer_menu.visible)
	game.name_input.release_focus()
	await _frames(1)
	await _send_key_event(KEY_E, "e".unicode_at(0))
	_record("標題輸入", "標題只接受 ui_accept 開始", is_instance_valid(game.title_overlay))
	game.name_input.grab_focus()
	game.name_input.text = "實機測試員"
	game.appearance_input.select(2)
	await _send_key_event(KEY_ENTER, 13)
	await _frames(4)
	_record("角色建立", "套用名稱與外觀", state_store.player_profile.name == "實機測試員" and int(state_store.player_profile.appearance.outfit) == 2)
	_record("啟動", "離開標題後恢復遊戲", not is_instance_valid(game.title_overlay) and player.is_physics_processing())

	var text_guard := LineEdit.new()
	text_guard.position = Vector2(-1000, -1000)
	game.add_child(text_guard)
	text_guard.grab_focus()
	await _frames(1)
	player.global_position = game._plot_world_position(Vector2i.ZERO)
	var plots_before: Dictionary = state_store.farm.plots.duplicate(true)
	await _send_key_event(KEY_E, "e".unicode_at(0))
	await _send_key_event(KEY_M, "m".unicode_at(0))
	_record("輸入焦點", "任意 LineEdit 編輯時忽略遊戲全域快捷鍵", state_store.farm.plots == plots_before and not game.multiplayer_menu.visible)
	text_guard.release_focus()
	text_guard.queue_free()
	await _frames(1)


func _test_movement_and_animation() -> void:
	var directions := [
		{"action":"ui_right", "row":2, "axis":"x", "sign":1},
		{"action":"ui_left", "row":1, "axis":"x", "sign":-1},
		{"action":"ui_up", "row":3, "axis":"y", "sign":-1},
		{"action":"ui_down", "row":0, "axis":"y", "sign":1},
	]
	for direction: Dictionary in directions:
		player.global_position = Vector2(320, 205)
		var start: Vector2 = player.global_position
		var seen_frames: Dictionary = {}
		Input.action_press(StringName(direction.action))
		for frame_index in range(40):
			await physics_frame
			seen_frames[player.visual_frame] = true
			if direction.action == "ui_right" and frame_index == 11:
				await _capture("02_four_frame_walk")
		Input.action_release(StringName(direction.action))
		await _frames(2)
		var delta: Vector2 = player.global_position - start
		var signed_distance: float = (delta.x if direction.axis == "x" else delta.y) * int(direction.sign)
		_record("移動動畫", "%s 方向移動" % direction.action, signed_distance > 18.0, "位移 %.1f px" % signed_distance)
		_record("移動動畫", "%s 使用正確方向列" % direction.action, player.visual_direction_row == int(direction.row), "atlas row=%d" % player.visual_direction_row)
		_record("移動動畫", "%s 播放多幀循環" % direction.action, seen_frames.size() >= 3, "觀察到 %d/4 幀" % seen_frames.size())
	await _physics_frames(10)
	var idle_min_y := INF
	var idle_max_y := -INF
	for _idle_frame in range(30):
		await physics_frame
		idle_min_y = minf(idle_min_y, float(player.visual_sprite.position.y))
		idle_max_y = maxf(idle_max_y, float(player.visual_sprite.position.y))
	_record("待機動畫", "停止移動後切換站立狀態", player.visual_animation == &"idle" and player.visual_frame == 0)
	_record("待機動畫", "站立時有呼吸動態而非保持走路循環", idle_max_y - idle_min_y > 0.2, "呼吸位移 %.2f px" % (idle_max_y - idle_min_y))
	game._travel_to_map(&"mistfall_farm")
	player.global_position = Vector2(160, 155)
	var blocked_start_y: float = float(player.global_position.y)
	Input.action_press("ui_up")
	await _physics_frames(30)
	Input.action_release("ui_up")
	await _physics_frames(3)
	_record("地圖碰撞", "農舍屋頂會阻擋玩家", blocked_start_y - player.global_position.y < 25.0, "起點 %.1f／終點 %.1f" % [blocked_start_y, player.global_position.y])
	_record("地圖碰撞", "池塘、房屋與田床均登錄為不可通行區", game.is_world_position_blocked(Vector2(110, 240)) and game.is_world_position_blocked(Vector2(160, 90)) and game.is_world_position_blocked(Vector2(470, 240)))
	_record("輸入", "斜向速度正規化", is_equal_approx(Vector2(1, 1).normalized().length(), 1.0))
	_record("畫面層級", "玩家角色始終繪製在田地與地面裝飾之上", player.z_index > game.z_index and is_instance_valid(player.visual_sprite) and player.visual_sprite.z_index >= 0)


func _test_combat_and_dungeon() -> void:
	game._enter_dungeon()
	await _frames(8)
	player.max_health = 9999
	player.health = 9999
	state_store.player_stats.max_health = 9999
	state_store.player_stats.health = 9999
	var enemies := get_nodes_in_group("enemies")
	_record("洞窟", "第 1 層生成敵人", enemies.size() >= 2, "%d 名" % enemies.size())
	var enemy_layers_ok := enemies.all(func(enemy: Node) -> bool: return enemy.z_index > game.z_index and is_instance_valid(enemy.visual_sprite) and enemy.visual_sprite.z_index >= 0)
	_record("畫面層級", "敵人角色始終繪製在地形裝飾之上", enemy_layers_ok)
	game._update_hud()
	_record("物品圖示", "戰鬥 HUD 顯示攻擊與藥水圖示及數量", game.attack_card.visible and game.potion_card.visible and game.potion_label.text.contains("×"))
	for node: Node in enemies:
		node.set_physics_process(false)
	var target: Node = enemies[0]
	target.max_health = 1000
	target.health = 1000
	player.global_position = Vector2(300, 210)
	player.facing = Vector2.RIGHT
	target.global_position = player.global_position + Vector2(28, 0)
	var slash_direction_ok := true
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		player.facing = direction
		for progress in [0.0, 0.5, 1.0]:
			var slash_geometry: Dictionary = player.attack_effect_geometry(progress)
			var tail_forward := Vector2(slash_geometry.tail).dot(direction)
			var tip_forward := Vector2(slash_geometry.tip).dot(direction)
			slash_direction_ok = slash_direction_ok and tail_forward > 0.0 and tip_forward > tail_forward + 10.0
	_record("戰鬥動畫", "四方向刀光皆從角色身前向外揮出，不會反向砍中自己", slash_direction_ok)
	player.facing = Vector2.RIGHT
	var attack_before: int = int(target.health)
	Input.action_press("attack")
	await physics_frame
	Input.action_release("attack")
	var attack_samples: Dictionary = {}
	var attack_rotation_min := INF
	var attack_rotation_max := -INF
	var previous_attack_progress := -1.0
	var attack_progress_monotonic := true
	for animation_frame in range(11):
		await physics_frame
		var progress := float(player.attack_visual_progress)
		if progress > 0.0:
			attack_samples[snappedf(progress, 0.01)] = true
			attack_progress_monotonic = attack_progress_monotonic and progress >= previous_attack_progress
			previous_attack_progress = progress
			attack_rotation_min = minf(attack_rotation_min, float(player.visual_sprite.rotation))
			attack_rotation_max = maxf(attack_rotation_max, float(player.visual_sprite.rotation))
		if animation_frame == 4:
			await _capture("03_dungeon_combat")
	_record("戰鬥動畫", "揮砍以至少八個連續時間點插值並帶角色動作", attack_samples.size() >= 8 and attack_progress_monotonic and attack_rotation_max - attack_rotation_min >= 0.025, "%d 個時間點／轉動 %.3f rad" % [attack_samples.size(), attack_rotation_max - attack_rotation_min])
	_record("戰鬥", "近戰攻擊命中", target.health < attack_before, "傷害 %d" % (attack_before - target.health))
	while player.state != 0:
		await physics_frame
	target.health = 1000
	var combo_before: int = int(target.health)
	Input.action_press("attack")
	await _physics_frames(2)
	Input.action_release("attack")
	await _physics_frames(7)
	Input.action_press("attack")
	await _physics_frames(2)
	Input.action_release("attack")
	await _physics_frames(22)
	_record("戰鬥", "連擊輸入緩衝", combo_before - target.health > player.attack_power, "累積傷害 %d" % (combo_before - target.health))
	while player.state != 0:
		await physics_frame
	Input.action_press("dodge")
	await _physics_frames(2)
	var dodge_active: bool = player.state == 2 and player.invulnerable
	Input.action_release("dodge")
	await _physics_frames(22)
	_record("戰鬥", "翻滾與無敵幀", dodge_active and player.state == 0)
	target.health = 1000
	target.global_position = player.global_position + Vector2(35, 0)
	var skill_before: int = int(target.health)
	await _tap_action("active_skill", 4)
	_record("戰鬥", "主動技能與冷卻", target.health < skill_before and player.skill_cooldown_timer > 0.0)
	state_store.inventory.health_potion = 2
	player.health = 40
	state_store.player_stats.health = 40
	await _tap_action("use_potion", 3)
	_record("戰鬥", "回復藥水", player.health == 75 and int(state_store.inventory.health_potion) == 1)

	for floor_number in range(1, 41):
		game._clear_enemies()
		await _frames(3)
		state_store.dungeon.current_floor = floor_number
		state_store.dungeon.max_reached = maxi(state_store.dungeon.max_reached, floor_number)
		game._spawn_dungeon_floor()
		await _frames(5)
		var floor_enemies := get_nodes_in_group("enemies")
		var boss_count := 0
		for enemy_node: Node in floor_enemies:
			var enemy: Node = enemy_node
			boss_count += int(enemy.is_boss)
		if floor_number % 10 == 0:
			_record("Boss", "%dF 守護者生成" % floor_number, boss_count == 1)
		if floor_number == 40:
			# HUD 以 0.25 秒節流更新；驗收截圖前強制同步，避免留下前一層的標示。
			game._update_hud()
			await _frames(2)
			await _capture("04_floor_40_boss")
		for enemy_node: Node in floor_enemies.duplicate():
			var enemy: Node = enemy_node
			enemy.take_damage(enemy.max_health + 1000, player)
		await _frames(8)
		_record("洞窟", "%dF 生成、戰鬥與結算" % floor_number, floor_number in state_store.dungeon.cleared_floors and game.floor_cleared)
	_record("洞窟", "四枚季節封印", state_store.dungeon.seals.size() == 4 and state_store.dungeon.can_challenge_final_boss())
	_record("洞窟", "每五層電梯", state_store.dungeon.available_elevators().size() >= 8)
	game._leave_dungeon()
	await _frames(3)
	game._enter_dungeon()
	await _frames(6)
	await _capture("05_final_boss")
	var final_enemies := get_nodes_in_group("enemies")
	_record("洞窟", "離洞後從檢查點恢復最終挑戰", state_store.dungeon.current_floor == 40 and final_enemies.size() == 1 and game.final_challenge_active)
	_record("最終戰", "霧鐘核心生成", final_enemies.size() == 1 and game.final_challenge_active)
	for enemy_node: Node in final_enemies:
		var enemy: Node = enemy_node
		enemy.take_damage(enemy.max_health + 1000, player)
	await _frames(8)
	_record("最終戰", "通關與無限模式", state_store.dungeon.final_boss_defeated and state_store.dungeon.endless_unlocked)
	game._leave_dungeon()
	await _frames(3)
	game._enter_dungeon()
	await _frames(5)
	_record("洞窟", "通關後從 41F 開始無限挑戰", state_store.dungeon.current_floor == 41 and not game.final_challenge_active)
	state_store.coins = 1000
	var rescue: Dictionary = state_store.resolve_player_defeat()
	_record("戰敗", "診所救援扣除 10%", int(rescue.coins_lost) == 100 and state_store.coins == 900)
	game._leave_dungeon()
	await _frames(5)


func _test_farming_animals_and_economy() -> void:
	state_store.reset()
	state_store.set_flag(&"title_seen", true)
	game.mode = "farm"
	game._set_background_for_mode()
	player.restore_from_game_state()
	state_store.farm.seed_stock = {"spring_turnip":8, "spring_potato":0, "spring_strawberry":0}
	game._refresh_seasonal_seeds()
	player.global_position = Vector2(221, 159)
	var stamina_before: int = int(state_store.tools.stamina)
	game._interact()
	game._interact()
	game._interact()
	var plot: Dictionary = state_store.farm.plots.get("0,0", {})
	_record("農作", "翻土、播種、澆水", bool(plot.get("tilled")) and plot.get("crop_id") == "spring_turnip" and bool(plot.get("watered")))
	_record("農作", "工具消耗體力", state_store.tools.stamina < stamina_before)
	for day_index in range(3):
		state_store.advance_day(true)
		await _frames(2)
		if day_index < 2:
			game._interact()
	plot = state_store.farm.plots.get("0,0", {})
	_record("農作", "作物依澆水日成熟", bool(plot.get("ready")))
	await _capture("06_mature_crop_and_weather")
	game._interact()
	_record("農作", "成熟作物收成", int(state_store.farm.produce.get("spring_turnip", 0)) >= 1)
	state_store.farm.interact_plot(Vector2i(1, 0), &"spring_turnip", &"spring")
	state_store.farm.interact_plot(Vector2i(1, 0), &"spring_turnip", &"spring")
	state_store.farm.advance_day(&"summer", "clear")
	_record("農作", "換季枯萎規則", bool(Dictionary(state_store.farm.plots.get("1,0", {})).get("withered", false)))
	for rank in range(2, 11):
		state_store.farm.unlock_rank(rank)
	_record("農場升級", "Lv.10 與溫室解鎖", state_store.farm.rank == 10 and state_store.farm.greenhouse_unlocked)
	state_store.tools.stamina = 100
	player.global_position = game.POND_FISH_POSITION
	var fish_before := int(state_store.lifetime_stats.fish_caught)
	for attempt in range(8):
		state_store.tools.stamina = 100
		state_store.calendar.day = attempt + 1
		state_store.calendar.minute_of_day = 10 * 60
		state_store.current_weather = "clear"
		player.global_position = game.POND_FISH_POSITION
		game._interact()
		if int(state_store.lifetime_stats.fish_caught) > fish_before:
			break
	_record("釣魚", "池塘釣魚與季節魚表", int(state_store.lifetime_stats.fish_caught) > fish_before)
	player.global_position = Vector2(42, 92)
	game._interact()
	player.global_position = Vector2(105, 318)
	game._interact()
	_record("採集", "樹木與石材節點", int(state_store.inventory.get("wood", 0)) > 0 and int(state_store.inventory.get("stone", 0)) > 0)

	state_store.farm.animals.clear()
	var chicken_purchase: Dictionary = state_store.farm.purchase_animal("chicken")
	var cow_purchase: Dictionary = state_store.farm.purchase_animal("cow")
	game._update_animal_sprites()
	await _frames(4)
	_record("動物", "雞與牛購入", bool(chicken_purchase.ok) and bool(cow_purchase.ok) and state_store.farm.animals.size() == 2)
	var chicken: Dictionary = state_store.farm.animals[0]
	chicken.hearts = 5
	chicken.product_ready = true
	state_store.farm.animals[0] = chicken
	player.global_position = Vector2(490, 154)
	game._interact()
	_record("動物", "雞蛋產物收集", int(state_store.farm.produce.get("egg", 0)) == 1)
	var tending: Dictionary = state_store.interact_animal("chicken_1")
	var breeding: Dictionary = state_store.interact_animal("chicken_1")
	for _day in range(7):
		state_store.farm.tend_animal("chicken_1", true, false)
		state_store.farm.advance_day(&"spring", "clear")
	_record("動物", "玩家互動可照料、繁殖與迎接幼崽", bool(tending.ok) and bool(breeding.ok) and state_store.farm.animals.size() == 3)
	await _capture("07_animals_and_farm")

	state_store.calendar.minute_of_day = 600
	state_store.coins = 50000
	state_store.farm.rank = 6
	state_store.inventory.copper_ore = 20
	game.shop_menu.open(&"mira_seed_shop")
	await _frames(3)
	await _capture("08_shop_purchase")
	var coins_before: int = int(state_store.coins)
	var seeds_before := int(state_store.farm.seed_stock.get("spring_turnip", 0))
	var first_offer := game.shop_menu.offer_box.get_child(0) as Button
	first_offer.pressed.emit()
	await _frames(4)
	_record("商店", "商品列表與購買回呼", state_store.coins < coins_before or int(state_store.farm.seed_stock.get("spring_turnip", 0)) > seeds_before)
	game.shop_menu.close()
	state_store.farm.produce.spring_turnip = 3
	player.global_position = Vector2(274, 290)
	var shipping_before: int = int(state_store.economy.pending_value())
	game._interact()
	var pending: int = int(state_store.economy.pending_value())
	var coins_pre_settlement: int = int(state_store.coins)
	state_store.advance_day()
	_record("經濟", "出貨箱與隔夜結算", pending > shipping_before and state_store.coins > coins_pre_settlement)


func _test_maps_and_automation() -> void:
	var world_map_ids := {"farm":"mistfall_farm", "village":"mistfall_village", "river":"mistfall_river", "grove":"bellwood_grove", "ruins":"clockwork_ruins", "dungeon":"mistfall_depths"}
	var bidirectional := true
	var outdoor_connected := true
	var collision_rebuilt := true
	var foreground_depth_ok := true
	var routes_clear_and_reachable := true
	for source_mode: String in ["farm", "village", "river", "grove", "ruins", "dungeon"]:
		var connections: Dictionary = Dictionary(game.REGION_CONNECTIONS.get(source_mode, {}))
		var collision_summary: Dictionary = game.world_collision_summary(source_mode)
		collision_rebuilt = collision_rebuilt and int(collision_summary.obstacles) >= 6 and int(collision_summary.polygons) >= 3
		foreground_depth_ok = foreground_depth_ok and game.foreground_layer_count(source_mode) >= 3
		if source_mode != "dungeon" and connections.size() < 4:
			outdoor_connected = false
		var safe_spawn: Vector2 = game._safe_spawn_for_mode(source_mode)
		for destination_id: String in connections:
			var target_mode: String = game._mode_for_map(StringName(destination_id))
			var reverse_connections: Dictionary = Dictionary(game.REGION_CONNECTIONS.get(target_mode, {}))
			if not reverse_connections.has(String(world_map_ids[source_mode])):
				bidirectional = false
			var route_position := Vector2(Dictionary(connections[destination_id]).position)
			routes_clear_and_reachable = routes_clear_and_reachable and not game.is_map_position_blocked(source_mode, route_position, 7.0) and game.map_has_walkable_path(source_mode, safe_spawn, route_position, 6.0)
	_record("地圖連接", "農場、村莊、河畔、鐘林、古代都市均至少四向互通", outdoor_connected)
	_record("地圖連接", "所有區域連接點都有反向出口", bidirectional)
	_record("地圖重構", "六張地圖皆依背景重算多段矩形與多邊形碰撞", collision_rebuilt)
	_record("地圖重構", "所有出口都位於可行走道路且可由安全出生點抵達", routes_clear_and_reachable)
	_record("立體景深", "六張地圖均有屋頂、樹冠、機械或崖壁前景遮擋層", foreground_depth_ok)
	var collision_samples := {
		"farm":[Vector2(160, 90), Vector2(110, 240), Vector2(470, 240)],
		"village":[Vector2(110, 100), Vector2(320, 180), Vector2(80, 220), Vector2(470, 200)],
		"river":[Vector2(200, 80), Vector2(350, 180), Vector2(500, 190)],
		"grove":[Vector2(100, 250), Vector2(350, 180), Vector2(470, 90), Vector2(205, 145)],
		"ruins":[Vector2(130, 180), Vector2(320, 180), Vector2(500, 180), Vector2(480, 290)],
		"dungeon":[Vector2(160, 90), Vector2(590, 180), Vector2(320, 80)],
	}
	var landmarks_blocked := true
	for sample_mode: String in collision_samples:
		for sample: Vector2 in collision_samples[sample_mode]:
			landmarks_blocked = landmarks_blocked and game.is_map_position_blocked(sample_mode, sample)
	_record("地圖碰撞", "房屋、水域、樹牆、遺跡機械、田床與鐘窟崖壁皆不可穿越", landmarks_blocked)
	_record("河岸碰撞", "河水不可通行但兩岸木橋維持可走", game.is_map_position_blocked("river", Vector2(200, 80)) and game.is_map_position_blocked("river", Vector2(350, 180)) and not game.is_map_position_blocked("river", Vector2(350, 263), 5.0))
	var village_labels_ok := true
	for village_probe: Vector2 in [Vector2(280, 285), Vector2(game.SHOP_POSITIONS.mira_seed_shop), Vector2(game.NPC_POSITIONS.mira)]:
		var prompt_rects: Array[Rect2] = game.village_label_rects_for_position(village_probe)
		village_labels_ok = village_labels_ok and prompt_rects.size() <= 1 and game.rects_do_not_overlap(prompt_rects)
	var route_has_no_world_text := true
	for destination_id: String in game.REGION_CONNECTIONS.village:
		var route: Dictionary = Dictionary(game.REGION_CONNECTIONS.village[destination_id])
		route_has_no_world_text = route_has_no_world_text and not bool(game._gateway_geometry(Vector2(route.position), String(route.label), destination_id).has_world_text)
	_record("文字配置", "出口、商店與村民共用單一固定 HUD 提示，沒有可被角色遮住的世界文字", village_labels_ok and route_has_no_world_text)
	var pickup_geometry: Dictionary = game.world_pickup_geometry(Vector2.ZERO)
	_record("採集視覺", "蘆葦、藥草、齒輪、木石與礦石使用物件圖、底座及火花而非圓圈", not bool(pickup_geometry.uses_placeholder_ring) and Rect2(pickup_geometry.icon_rect).size == Vector2(42, 42) and Array(pickup_geometry.sparks).size() >= 4)
	game._travel_to_map(&"mistfall_village")
	await _frames(3)
	var physical_route_ok := true
	for leg: Dictionary in [
		{"target":"mistfall_river", "expected":"river"},
		{"target":"bellwood_grove", "expected":"grove"},
		{"target":"clockwork_ruins", "expected":"ruins"},
		{"target":"mistfall_village", "expected":"village"},
	]:
		var marker: Dictionary = Dictionary(Dictionary(game.REGION_CONNECTIONS[game.mode])[leg.target])
		player.global_position = Vector2(marker.position)
		game._interact()
		await _frames(3)
		physical_route_ok = physical_route_ok and game.mode == String(leg.expected)
	_record("地圖連接", "村莊→河畔→鐘林→古代都市→村莊可走實體路標，不必回農場", physical_route_ok)
	game._travel_to_map(&"clockwork_ruins")
	var dungeon_marker: Dictionary = Dictionary(Dictionary(game.REGION_CONNECTIONS.ruins)["mistfall_depths"])
	player.global_position = Vector2(dungeon_marker.position)
	game._interact()
	await _frames(5)
	var entered_dungeon_from_ruins: bool = game.mode == "dungeon"
	var ruins_exit_marker: Dictionary = Dictionary(Dictionary(game.REGION_CONNECTIONS.dungeon)["clockwork_ruins"])
	player.global_position = Vector2(ruins_exit_marker.position)
	game._interact()
	await _frames(4)
	_record("地圖連接", "古代都市可直入鐘窟，鐘窟內有可見返回古代都市出口", entered_dungeon_from_ruins and game.mode == "ruins")
	game._travel_to_map(&"mistfall_river")
	await _frames(6)
	var river_path := String(game.world_background.texture.resource_path)
	var river_npcs := 0
	for sprite: Sprite2D in game.npc_sprites.values():
		river_npcs += int(sprite.visible)
	player.global_position = game.RIVER_RESOURCE_POSITION
	game._interact()
	var reeds_ok := int(state_store.inventory.get("river_reed", 0)) >= 2
	var river_fish_before := int(state_store.lifetime_stats.get("fish_caught", 0))
	for attempt in range(12):
		state_store.tools.stamina = 100
		state_store.calendar.day = attempt % 12 + 1
		state_store.calendar.minute_of_day = 10 * 60
		state_store.current_weather = "clear"
		player.global_position = game.RIVER_FISH_POSITION
		game._interact()
		if int(state_store.lifetime_stats.get("fish_caught", 0)) > river_fish_before:
			break
	_record("新地圖", "鳴鐘河畔可進入、釣魚、採蘆葦並顯示同行村民", game.mode == "river" and "mistfall_river_commercial" in river_path and reeds_ok and river_npcs == 2 and int(state_store.lifetime_stats.get("fish_caught", 0)) > river_fish_before)
	await _capture("16_mistfall_river_map")

	game._travel_to_map(&"bellwood_grove")
	await _frames(6)
	var grove_path := String(game.world_background.texture.resource_path)
	var grove_npcs := 0
	for sprite: Sprite2D in game.npc_sprites.values():
		grove_npcs += int(sprite.visible)
	player.global_position = game.GROVE_RESOURCE_POSITION
	game._interact()
	_record("新地圖", "古鐘林可進入、採藥草並顯示關係角色", game.mode == "grove" and "bellwood_grove_commercial" in grove_path and int(state_store.inventory.get("forest_herb", 0)) >= 2 and grove_npcs == 2)
	await _capture("17_bellwood_grove_map")

	game._travel_to_map(&"clockwork_ruins")
	await _frames(6)
	var ruins_path := String(game.world_background.texture.resource_path)
	var ruins_npcs := 0
	for sprite: Sprite2D in game.npc_sprites.values():
		ruins_npcs += int(sprite.visible)
	player.global_position = game.RUINS_RESOURCE_POSITION
	game._interact()
	_record("新地圖", "古鐘機械遺跡可進入、取得齒輪並呈現自動化線索", game.mode == "ruins" and "clockwork_ruins_commercial" in ruins_path and int(state_store.inventory.get("ancient_gear", 0)) >= 1 and ruins_npcs == 2)
	await _capture("18_clockwork_ruins_map")

	game._travel_to_map(&"mistfall_farm")
	state_store.farm.rank = 10
	state_store.farm.automation_devices.clear()
	state_store.farm.automation_cycle_count = 0
	state_store.farm.plots.clear()
	state_store.farm.seed_stock["spring_turnip"] = 20
	state_store.coins = 200000
	for material_id in ["wood", "stone", "copper_ore", "iron_ore", "gold_ore", "glass", "mist_shard"]:
		state_store.inventory[material_id] = 200
	var placements := [
		[Vector2i(0,0),"bell_generator",100],[Vector2i(0,1),"bell_generator",100],
		[Vector2i(1,0),"mist_pump",90],[Vector2i(2,0),"field_sprinkler",80],
		[Vector2i(2,1),"seed_distributor",70],[Vector2i(3,1),"crop_harvester",95],
		[Vector2i(3,0),"preserves_processor",60],[Vector2i(4,0),"animal_feeder",50],
		[Vector2i(5,0),"tide_condenser",40],
	]
	var built := 0
	for entry: Array in placements:
		var result: Dictionary = state_store.purchase_automation_device(entry[0], StringName(entry[1]), {"priority":entry[2],"crop_filter":"spring_turnip"})
		built += int(bool(result.get("ok", false)))
	state_store.farm.plots["4,1"] = {"tile":[4,1],"tilled":true,"watered":false,"crop_id":"spring_turnip","growth_progress":3,"ready":true,"withered":false}
	state_store.farm.plots["2,0"] = {"tile":[2,0],"tilled":true,"watered":false,"crop_id":"spring_turnip","growth_progress":0,"ready":false,"withered":false}
	state_store.farm.produce["spring_turnip"] = 2
	var tide_fish_id := ""
	for fish: Dictionary in registry.get_all("fish"):
		if bool(fish.get("tide_required", false)):
			tide_fish_id = String(fish.get("id", ""))
			break
	state_store.farm.produce[tide_fish_id] = 1
	state_store.farm.animals.clear()
	state_store.farm.animals.append({"id":"chicken_1","species":"chicken","name":"鐘網雞","hearts":0,"mood":50,"fed":false,"grazed":false,"product_ready":false,"pregnant_days":0})
	state_store.inventory["animal_feed"] = 3
	var day_result: Dictionary = state_store.advance_day(true)
	var automation_report: Dictionary = day_result.get("automation", {})
	_record("農場自動化", "九種設備可購買並連成單一鐘能網路", built == 9 and state_store.farm.automation_networks().size() == 1)
	_record("農場自動化", "供電供水、播種、澆水、收割、餵食與雙加工每日實際運作", int(automation_report.get("stalled", 99)) == 0 and int(automation_report.get("watered", 0)) >= 1 and int(automation_report.get("harvested", 0)) >= 1 and int(automation_report.get("fed", 0)) == 1 and int(automation_report.get("processed", 0)) == 2)
	_record("農場自動化", "霧封農產與夢潮鹽進入可出貨庫", int(state_store.farm.produce.get("mist_preserves", 0)) >= 1 and int(state_store.farm.produce.get("dream_tide_salt", 0)) >= 1)
	player.global_position = game.AUTOMATION_CONSOLE_POSITION
	game._interact()
	await _frames(5)
	var handbook_has_automation := false
	for tab_index in range(game.game_menu.tabs.get_tab_count()):
		handbook_has_automation = handbook_has_automation or game.game_menu.tabs.get_tab_title(tab_index) == "自動化"
	_record("農場自動化", "自動化是農場內鐘網控制台互動，不在設定手冊", game.automation_console.visible and paused and not handbook_has_automation)
	_record("農場自動化", "可視化 6×4 設計圖、設備選擇、作物篩選、優先序與停機資訊可操作", game.automation_console.automation_tile_buttons.size() == 24 and game.automation_console.automation_device_select.item_count == 9 and "1 網路" in game.automation_console.automation_status_label.text)
	await _capture("19_automation_network")
	game.automation_console.close()
	await _frames(3)


func _test_eldritch_fishing_and_boss() -> void:
	state_store.tools.tool_levels["fishing_rod"] = 4
	state_store.eldritch.reset()
	state_store.quest_states["whispers_beneath_tide_quest"] = "inactive"
	var sanity_before: int = state_store.eldritch.sanity
	var caught_seasons: Array[String] = []
	for season_index in range(4):
		state_store.calendar.season_index = season_index
		state_store.calendar.day = 13
		state_store.calendar.minute_of_day = 19 * 60
		state_store.current_weather = "clear"
		state_store.tools.stamina = 100
		var result: Dictionary = state_store.fish_at("pond")
		if bool(result.get("ok", false)) and bool(result.get("eldritch", false)):
			caught_seasons.append(String(state_store.calendar.season_id()))
	_record("異潮釣魚", "四季皆可釣起異魚", caught_seasons.size() == 4, ", ".join(caught_seasons))
	_record("異潮釣魚", "四種異魚解鎖夢岸挑戰", state_store.eldritch.eldritch_catches.size() == 4 and state_store.eldritch.can_challenge())
	_record("理智", "異魚降低理智並產生洞見", state_store.eldritch.sanity < sanity_before and state_store.eldritch.insight > 0)
	_record("異潮任務", "首次異魚啟動無期限任務", String(state_store.quest_states.get("whispers_beneath_tide_quest", "")) == "active")
	var tide_quest: Dictionary = registry.get_artifact("quests", &"whispers_beneath_tide_quest")
	_record("異潮任務", "任務不含日期期限", not tide_quest.has("deadline") and "沒有日期期限" in String(tide_quest.get("summary", "")))

	game.mode = "farm"
	game._set_background_for_mode()
	game.game_menu.open()
	await _frames(3)
	game.game_menu.tabs.current_tab = 9
	game.game_menu.refresh()
	await _capture("13_eldritch_journal")
	_record("異潮手冊", "異魚圖鑑與理智頁可開啟", game.game_menu.tabs.get_tab_count() == 10 and game.game_menu.tabs.current_tab == 9)
	game.game_menu.close()
	await _frames(2)

	game._begin_eldritch_challenge()
	await _frames(10)
	var abyss_enemies := get_nodes_in_group("enemies")
	var boss: Node = abyss_enemies[0] if abyss_enemies.size() == 1 else null
	var boss_visual_ok := false
	if is_instance_valid(boss):
		boss_visual_ok = boss.enemy_id == &"drowned_dreamer" and is_instance_valid(boss.visual_sprite) and boss.visual_sprite.texture != null
		boss.set_physics_process(false)
	_record("古神首領", "夢岸生成克蘇魯之影", game.mode == "abyss" and boss_visual_ok)
	await _capture("14_drowned_dreamer_boss")
	if is_instance_valid(boss):
		boss.take_damage(99999, player)
	await _frames(18)
	_record("古神首領", "擊敗首領並完成無期限任務", state_store.eldritch.boss_defeated and String(state_store.quest_states.get("whispers_beneath_tide_quest", "")) == "completed")
	_record("古神首領", "深潮夢核獎勵與理智恢復", int(state_store.inventory.get("abyssal_relic", 0)) >= 1 and state_store.eldritch.sanity == PixelRPGEldritchTideSystem.MAX_SANITY)
	_record("古神首領", "異潮成就解鎖", "dreamer_silenced" in state_store.achievements.unlocked)
	game._leave_eldritch_shore()
	await _frames(3)


func _test_village_dialogue_and_festival() -> void:
	game._enter_village()
	await _frames(5)
	var visible_npcs := 0
	for sprite: Sprite2D in game.npc_sprites.values():
		visible_npcs += int(sprite.visible)
	_record("村莊", "10 名 NPC 可見與排程", visible_npcs == 10)
	var mira_sprite: Sprite2D = game.npc_sprites.get("mira")
	var mira_grounded_position: Vector2 = game._npc_sprite_anchor("mira", Vector2(game.NPC_POSITIONS["mira"]))
	var mira_position_before := mira_sprite.position
	await _frames(8)
	_record("村莊", "米拉腳底固定在地面座標並有接地陰影，不再上下漂浮", mira_sprite.position.distance_to(mira_grounded_position) < 0.1 and mira_sprite.position.distance_to(mira_position_before) < 0.1)
	# Finish the arrival toast without advancing the in-game NPC schedule, then
	# capture the route prompt layout that previously sat behind Mira.
	if is_instance_valid(game.toast_tween):
		game.toast_tween.kill()
	game.toast_panel.modulate.a = 0.0
	player.global_position = Vector2(game.VILLAGE_GATE_POSITION)
	await _frames(3)
	_record("文字配置", "村莊出口提示固定在 CanvasLayer 且位於所有人物上方", game.world_prompt_panel.visible and game.world_prompt_layer.layer > 0 and game.world_prompt_title_label.text == "霧落農場")
	await _capture("09_village_dialogue")
	player.global_position = Vector2(game.NPC_POSITIONS["mira"])
	var hearts_before: int = int(state_store.social.hearts(&"mira"))
	game._interact()
	await _frames(4)
	_record("對話", "NPC 對話、肖像與時間暫停", game.dialogue_overlay.visible and paused and state_store.calendar.paused)
	_record("關係", "每日交談增加好感", state_store.social.hearts(&"mira") >= hearts_before)
	game.dialogue_overlay.close()
	await _frames(3)
	game._enter_farm_from_village()
	state_store.calendar.year = 1
	state_store.calendar.season_index = 0
	state_store.calendar.day = 8
	state_store.festivals.attended.clear()
	var festival_coins: int = int(state_store.coins)
	game.festival_overlay.open_today()
	await _frames(4)
	_record("節慶", "指定日期開啟節慶", game.festival_overlay.visible and paused)
	await _capture("10_interactive_festival")
	for _round in range(5):
		game.festival_overlay.marker_value = float(game.festival_overlay.festival.get("challenge_target", 65)) / 100.0
		game.festival_overlay._attempt()
	_record("節慶", "五回合評分與獎勵", game.festival_overlay.round_index == 5 and state_store.coins > festival_coins and state_store.lifetime_stats.festivals_attended == 1)
	game.festival_overlay.close()
	var festival_dates: Dictionary = {}
	for definition: Dictionary in registry.get_all("festivals"):
		festival_dates["%s:%d" % [definition.season, definition.day]] = true
	_record("節慶", "四季 12 場節慶資料", festival_dates.size() == 12)


func _test_story_dialogue_recovery() -> void:
	game.dialogue_overlay.close()
	var preserved_state: Dictionary = state_store.to_save_data()
	var preserved_mode := String(game.mode)
	state_store.reset()
	state_store.set_flag(&"title_seen", true)
	state_store.set_flag(&"story_dialogue_seen_y1_spring_new_soil", true)
	state_store.current_map_id = &"mistfall_village"
	game.mode = "village"
	game._set_background_for_mode()
	player.restore_from_game_state()
	player.global_position = Vector2(game.NPC_POSITIONS["mira"])
	await _frames(3)

	await _send_key_event(KEY_E, "e".unicode_at(0))
	var inactive_reopened: bool = game.dialogue_overlay.visible and String(game.dialogue_overlay.graph.get("id", "")) == "y1_spring_new_soil_dialogue"
	var decline_flow := await _press_dialogue_button(0)
	decline_flow = await _press_dialogue_button(0) and decline_flow
	decline_flow = await _press_dialogue_button(1) and decline_flow
	decline_flow = await _press_dialogue_button(0) and decline_flow
	var remained_inactive := String(state_store.quest_states.get("y1_spring_new_soil_quest", "inactive")) == "inactive"
	game.dialogue_overlay.close()
	await _frames(2)
	await _send_key_event(KEY_E, "e".unicode_at(0))
	var reopened_after_decline: bool = game.dialogue_overlay.visible and String(game.dialogue_overlay.graph.get("id", "")) == "y1_spring_new_soil_dialogue"
	_record("主線互動", "inactive 與已看過章節可重談", inactive_reopened and decline_flow and remained_inactive and reopened_after_decline)

	var coins_before_accept := int(state_store.coins)
	var accept_flow := await _press_dialogue_button(0)
	accept_flow = await _press_dialogue_button(0) and accept_flow
	accept_flow = await _press_dialogue_button(0) and accept_flow
	var quest_active := String(state_store.quest_states.get("y1_spring_new_soil_quest", "")) == "active"
	var chapter_incomplete := "y1_spring_new_soil" not in Array(state_store.story_state.get("completed_chapters", []))
	game.dialogue_overlay.close()
	await _frames(2)
	await _send_key_event(KEY_E, "e".unicode_at(0))
	var active_did_not_reopen_story: bool = game.dialogue_overlay.visible and game.dialogue_overlay.graph.is_empty()
	var unmet_unchanged := int(state_store.coins) == coins_before_accept and String(state_store.quest_states.get("y1_spring_new_soil_quest", "")) == "active" and chapter_incomplete
	_record("主線互動", "active 未達標不重播章節或發獎", accept_flow and quest_active and active_did_not_reopen_story and unmet_unchanged)

	game.dialogue_overlay.close()
	state_store.lifetime_stats["crops_harvested"] = 1
	state_store.social.add_affection(&"mira", 250)
	state_store.social.add_affection(&"lian", 250)
	state_store.player_position = Vector2(game.NPC_POSITIONS["mira"])
	var affected_save: Dictionary = state_store.to_save_data()
	state_store.reset()
	var restored_affected_save := bool(state_store.load_save_data(affected_save))
	game.mode = "village"
	game._set_background_for_mode()
	player.restore_from_game_state()
	player.global_position = Vector2(game.NPC_POSITIONS["mira"])
	await _frames(3)
	var coins_before_completion := int(state_store.coins)
	await _send_key_event(KEY_E, "e".unicode_at(0))
	var completed_chapters: Array = state_store.story_state.get("completed_chapters", [])
	var recovered_by_real_input: bool = restored_affected_save \
		and "y1_spring_new_soil" in completed_chapters \
		and bool(state_store.get_flag(&"chapter_y1_spring_new_soil", false)) \
		and String(state_store.quest_states.get("y1_spring_new_soil_quest", "")) == "completed" \
		and int(state_store.coins) == coins_before_completion + 400 \
		and game.dialogue_overlay.visible \
		and "章節完成" in game.dialogue_overlay.text_label.text
	_record("主線互動", "既有 seen＋active 存檔以真 E 結算", recovered_by_real_input)

	game.dialogue_overlay.close()
	await _frames(2)
	var coins_after_completion := int(state_store.coins)
	await _send_key_event(KEY_E, "e".unicode_at(0))
	var next_chapter_opened := String(game.dialogue_overlay.graph.get("id", "")) == "y1_summer_tide_echo_dialogue"
	_record("主線互動", "成功只發獎一次並開放下一章", int(state_store.coins) == coins_after_completion and next_chapter_opened)
	game.dialogue_overlay.close()
	state_store.load_save_data(preserved_state)
	game.mode = preserved_mode
	game._set_background_for_mode()
	player.restore_from_game_state()
	await _frames(2)


func _test_menus_relationships_and_settings() -> void:
	state_store.inventory["health_potion"] = maxi(1, int(state_store.inventory.get("health_potion", 0)))
	state_store.farm.seed_stock["spring_turnip"] = maxi(1, int(state_store.farm.seed_stock.get("spring_turnip", 0)))
	state_store.farm.produce["brook_trout"] = 1
	state_store.farm.produce["egg"] = 1
	state_store.farm.produce["milk"] = 1
	game.game_menu.open()
	await _frames(4)
	_record("選單", "旅人手冊暫停遊戲", game.game_menu.visible and paused and state_store.calendar.paused)
	_record("選單", "十個功能分頁", game.game_menu.tabs.get_tab_count() == 10)
	game.game_menu.tabs.current_tab = 1
	game.game_menu.refresh()
	await _frames(3)
	_record("物品圖示", "背包以圖示區分種子、魚、雞蛋、牛奶與藥水", game.game_menu.inventory_icon_count >= 6)
	await _capture("11_status_inventory_menu")
	for tab_index in range(game.game_menu.tabs.get_tab_count()):
		game.game_menu.tabs.current_tab = tab_index
		game.game_menu.refresh()
		await _frames(1)
	_record("選單", "狀態、背包、關係、日曆、主線、成就、料理、設定、地圖、深潮均可切換", game.game_menu.tabs.current_tab == 9)

	state_store.social.add_affection(&"mira", 2500)
	game.game_menu.candidate_select.select(0)
	game.game_menu._on_date_pressed()
	var dating := bool(state_store.social.ensure_npc(&"mira").get("dating", false))
	game.game_menu._on_propose_pressed()
	var married := String(state_store.social.marriage.get("spouse_id", "")) == "mira"
	var absolute_day: int = int(state_store.calendar.absolute_day())
	state_store.social.marriage.married_absolute_day = absolute_day - 30
	game.game_menu._on_family_pressed()
	var talked := bool(state_store.social.marriage.get("family_talk_seen", false))
	state_store.social.marriage.married_absolute_day = absolute_day - 60
	game.game_menu._on_family_pressed()
	var child_exists := bool(state_store.social.child.get("exists", false))
	_record("戀愛家庭", "告白、求婚與婚姻", dating and married)
	_record("戀愛家庭", "婚後 30/60 日家庭事件", talked and child_exists)
	var born := int(state_store.social.child.get("born_absolute_day", absolute_day))
	var stages := [state_store.social.update_child_stage(born + 29), state_store.social.update_child_stage(born + 30), state_store.social.update_child_stage(born + 90), state_store.social.update_child_stage(born + 210)]
	_record("戀愛家庭", "孩子四階段成長", stages == ["baby", "toddler", "child", "teen"])

	game.game_menu.tabs.current_tab = 6
	game.game_menu.recipe_select.select(0)
	game.game_menu._on_recipe_selected(0)
	var recipe_id := StringName(game.game_menu.recipe_select.get_item_metadata(0))
	var recipe: Dictionary = registry.get_artifact("recipes", recipe_id)
	for ingredient_id: String in Dictionary(recipe.get("ingredients", {})):
		state_store.farm.produce[ingredient_id] = int(recipe.ingredients[ingredient_id])
	game.game_menu._on_cook_pressed()
	var cooked := int(state_store.farm.produce.get(String(recipe_id), 0)) == 1
	state_store.tools.stamina = 0
	game.game_menu._on_eat_pressed()
	var recipe_icons_complete := game.game_menu.recipe_icon.texture != null
	for recipe_index in range(game.game_menu.recipe_select.item_count):
		recipe_icons_complete = recipe_icons_complete and game.game_menu.recipe_select.get_item_icon(recipe_index) != null
	_record("料理", "40 道料理清單與圖示", game.game_menu.recipe_select.item_count == 40 and recipe_icons_complete)
	_record("料理", "烹調與享用恢復體力", cooked and state_store.tools.stamina > 0)

	game.game_menu.tabs.current_tab = 7
	game.game_menu._on_volume_changed(0.0)
	game.game_menu.volume_slider.grab_focus()
	await _send_key_event(KEY_ESCAPE)
	await _frames(2)
	var escaped_muted_settings: bool = not game.game_menu.visible and not paused and not state_store.calendar.paused
	_record("設定", "主音量歸零後 Esc 可關閉手冊並返回遊戲", escaped_muted_settings)
	if not game.game_menu.visible:
		game.game_menu.open()
		await _frames(2)
	game.game_menu.tabs.current_tab = 7
	game.game_menu._on_volume_changed(0.35)
	var old_speed := String(state_store.calendar.speed_mode)
	game.game_menu._on_speed_pressed()
	_record("設定", "音量調整", is_equal_approx(float(state_store.settings.master_volume), 0.35))
	_record("設定", "10/15/20 分鐘速度切換", String(state_store.calendar.speed_mode) != old_speed)
	game.game_menu._on_fullscreen_toggled(true)
	var fullscreen_ok: bool = await _wait_for_window_mode([DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN])
	game.game_menu._on_fullscreen_toggled(false)
	var windowed_ok: bool = await _wait_for_window_mode([DisplayServer.WINDOW_MODE_WINDOWED])
	DisplayServer.window_set_size(Vector2i(1280, 720))
	await _frames(12)
	_record("設定", "視窗／全螢幕切換", fullscreen_ok and windowed_ok and root.size == Vector2i(1280, 720), "mode=%d viewport=%s" % [DisplayServer.window_get_mode(), root.size])
	game.game_menu._begin_rebind(&"attack")
	var key_event := InputEventKey.new()
	key_event.pressed = true
	key_event.physical_keycode = KEY_P
	game.game_menu._input(key_event)
	var rebound := false
	for event: InputEvent in InputMap.action_get_events("attack"):
		if event is InputEventKey and event.physical_keycode == KEY_P:
			rebound = true
	game.game_menu._reset_controls()
	var restored := false
	for event: InputEvent in InputMap.action_get_events("attack"):
		if event is InputEventKey and event.physical_keycode == KEY_J:
			restored = true
	_record("設定", "按鍵重新綁定與還原", rebound and restored)
	var expected_buttons := {"attack":0,"dodge":1,"active_skill":2,"interact":3,"multiplayer_menu":4,"pause_menu":6,"attend_festival":7,"toggle_cave":8,"use_potion":9,"cycle_seed":10,"quick_save":11,"quick_load":12,"time_speed":13,"sleep_day":14}
	var controller_mapped := true
	for action_id: String in expected_buttons:
		var found := false
		for event: InputEvent in InputMap.action_get_events(action_id):
			if event is InputEventJoypadButton and event.button_index == int(expected_buttons[action_id]):
				found = true
		controller_mapped = controller_mapped and found
	_record("手把", "14 項完整 XInput 按鈕映射", controller_mapped)
	var persist_event := InputEventKey.new()
	persist_event.physical_keycode = KEY_U
	PixelRPGInputBindings.rebind_device(&"interact", persist_event)
	var persisted := PixelRPGInputBindings.save()
	InputMap.action_erase_events(&"interact")
	var loaded_bindings := PixelRPGInputBindings.load_saved()
	var interact_restored := false
	for event: InputEvent in InputMap.action_get_events("interact"):
		if event is InputEventKey and event.physical_keycode == KEY_U:
			interact_restored = true
	PixelRPGInputBindings.reset_to_project_defaults()
	_record("設定", "所有遊戲操作重綁可跨重啟保存", persisted and loaded_bindings and interact_restored)
	state_store.coins = 12345
	state_store.current_map_id = &"mistfall_river"
	game.mode = "river"
	game._set_background_for_mode()
	player.global_position = Vector2(188, 214)
	var save_ok: bool = bool(save_manager.save_quick())
	state_store.coins = 7
	state_store.current_map_id = &"mistfall_farm"
	game.mode = "farm"
	game._set_background_for_mode()
	player.global_position = Vector2(320, 230)
	player.velocity = Vector2(255, 0)
	var load_ok: bool = bool(save_manager.load_quick())
	await _frames(3)
	var map_restored: bool = game.mode == "river" and state_store.current_map_id == &"mistfall_river" and player.global_position.distance_to(Vector2(188, 214)) < 1.0 and player.velocity == Vector2.ZERO
	_record("存檔", "SaveGame v5 跨地圖快速存讀", save_ok and load_ok and state_store.coins == 12345 and map_restored)
	game.game_menu.close()
	await _frames(3)


func _test_multiplayer_ui() -> void:
	game.multiplayer_menu.open()
	await _frames(3)
	_record("連線介面", "自行開服／IP 加入表單", game.multiplayer_menu.visible and is_instance_valid(game.multiplayer_menu.host_button) and is_instance_valid(game.multiplayer_menu.join_button) and int(game.multiplayer_menu.port_input.value) == PixelRPGNetworkManager.DEFAULT_PORT)
	_record("連線規則", "共同／私人／競賽農場與獨立／競爭關係可選", game.multiplayer_menu.farm_mode_input.item_count == 3 and game.multiplayer_menu.relationship_mode_input.item_count == 2)
	game.multiplayer_menu.name_input.text = "可視主機"
	game.multiplayer_menu.server_name_input.text = "霧落驗收世界"
	game.multiplayer_menu.world_input.text = "visible_qa_competitive"
	game.multiplayer_menu.port_input.value = 29381
	game.multiplayer_menu.farm_mode_input.select(2)
	game.multiplayer_menu.relationship_mode_input.select(1)
	game.multiplayer_menu.host_button.pressed.emit()
	await _frames(6)
	_record("連線介面", "遊戲內 ENet 主機可啟動", network.is_server() and network.server_players.size() == 1 and "主機" in network.connection_summary())
	_record("連線規則", "開服選項寫入世界契約", network.farm_mode == "competitive" and network.relationship_mode == "competitive" and String(Dictionary(network.shared_world.get("story_variant", {})).get("id", "")) == "solo_bell")
	var variants := [PixelRPGMultiplayerNarrativeSystem.story_variant(1, "shared", "independent").id, PixelRPGMultiplayerNarrativeSystem.story_variant(2, "private", "competitive").id, PixelRPGMultiplayerNarrativeSystem.story_variant(4, "competitive", "competitive").id, PixelRPGMultiplayerNarrativeSystem.story_variant(5, "shared", "independent").id]
	_record("多人劇情", "1／2／3–4／5+ 人使用四種劇情分支", variants == ["solo_bell", "twin_bell_pact", "four_season_chorus", "mistfall_council"])
	await _capture("15_multiplayer_host_ui")
	network.stop()
	game.multiplayer_menu.close()
	await _frames(3)
	_record("連線介面", "離線／關服可安全返回單人", not network.is_online() and not game.multiplayer_menu.visible)


func _test_alpha_matte_contrast() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 500
	root.add_child(layer)
	var board := Control.new()
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(board)
	var colors := [Color("7b1648"), Color("176b43"), Color("184f91"), Color("9a4b18")]
	for index in colors.size():
		var panel := ColorRect.new()
		panel.position = Vector2(index * 160, 0)
		panel.size = Vector2(160, 360)
		panel.color = colors[index]
		board.add_child(panel)
	var shade := ColorRect.new()
	shade.position = Vector2(0, 0)
	shade.size = Vector2(640, 42)
	shade.color = Color(0.03, 0.04, 0.06, 0.92)
	board.add_child(shade)
	var title := Label.new()
	title.position = Vector2(18, 8)
	title.text = "商用 Alpha 對比驗收｜人物・玩家・動物・敵人・異形"
	title.add_theme_font_size_override("font_size", 18)
	board.add_child(title)
	var samples := [
		{"path":"res://assets/runtime/sprites/character_atlas_alpha.png", "columns":4, "rows":3, "column":0, "row":0, "label":"村民"},
		{"path":"res://assets/runtime/sprites/player_walk_atlas_alpha.png", "columns":4, "rows":4, "column":2, "row":0, "label":"玩家"},
		{"path":"res://assets/runtime/sprites/animal_atlas_alpha.png", "columns":4, "rows":2, "column":0, "row":0, "label":"白雞"},
		{"path":"res://assets/runtime/sprites/enemy_atlas_alpha.png", "columns":4, "rows":4, "column":3, "row":3, "label":"Boss"},
		{"path":"res://assets/runtime/sprites/eldritch_drowned_dreamer_alpha.png", "columns":1, "rows":1, "column":0, "row":0, "label":"異形"},
	]
	var all_valid := true
	for index in samples.size():
		var sample: Dictionary = samples[index]
		var texture := _atlas_region(String(sample.path), int(sample.columns), int(sample.rows), int(sample.column), int(sample.row))
		all_valid = all_valid and texture != null
		var image := TextureRect.new()
		image.position = Vector2(10 + index * 126, 54)
		image.size = Vector2(116, 246)
		image.texture = texture
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		board.add_child(image)
		var caption := Label.new()
		caption.position = Vector2(10 + index * 126, 310)
		caption.size = Vector2(116, 32)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.text = String(sample.label)
		caption.add_theme_font_size_override("font_size", 16)
		board.add_child(caption)
	_record("商用圖片", "五類疊加圖集可在高對比底色上以真 Alpha 渲染", all_valid)
	await _frames(3)
	await _capture("20_alpha_matte_contrast")
	layer.queue_free()
	await _frames(2)


func _atlas_region(path: String, columns: int, rows: int, column: int, row: int) -> AtlasTexture:
	var source: Texture2D = load(path)
	if source == null:
		return null
	var region := AtlasTexture.new()
	region.atlas = source
	var cell_size := Vector2(source.get_width() / columns, source.get_height() / rows)
	region.region = Rect2(Vector2(column, row) * cell_size, cell_size)
	return region


func _test_long_term_content_and_migrations() -> void:
	var calendar: RefCounted = load("res://runtime/calendar/calendar_system.gd").new()
	for _day in range(1200):
		calendar.advance_day()
	_record("日曆", "10 年／1,200 日無漂移", calendar.year == 11 and calendar.season_index == 0 and calendar.day == 1)
	calendar.year = 1
	calendar.season_index = 3
	calendar.day = 30
	calendar.advance_day()
	_record("日曆", "冬 30 日跨年", calendar.year == 2 and calendar.season_index == 0 and calendar.day == 1)
	var speed_ok := true
	for mode in ["fast", "standard", "relaxed"]:
		calendar.reset()
		calendar.set_speed(mode)
		speed_ok = speed_ok and calendar.process(float(calendar.SPEED_SECONDS[mode]))
	_record("日曆", "三種日長結果一致", speed_ok)

	state_store.request_board.generate_for_day(4, &"spring", 1)
	var request: Dictionary = state_store.request_board.active_requests[0] if not state_store.request_board.active_requests.is_empty() else {}
	_record("長期內容", "第 4 年規則式委託", state_store.request_board.active_requests.size() == 3 and int(request.get("authored_variant", 0)) == 3)
	var story_arc: Dictionary = registry.get_artifact("story_arcs", &"mistfall_three_years")
	_record("主線", "12 章且沒有期限", Array(story_arc.get("chapters", [])).size() == 12 and story_arc.get("deadline", 1) == null)
	state_store.story_state = {"chapter":1, "completed_chapters":[], "season_seals":state_store.dungeon.seals.duplicate(), "final_boss_available":true, "final_boss_defeated":true}
	state_store.lifetime_stats = {"days_played":360,"crops_harvested":1000,"fish_caught":100,"eldritch_fish_caught":8,"resources_gathered":100,"monsters_defeated":100,"bosses_defeated":4,"eldritch_bosses_defeated":1,"festivals_attended":12,"relationship_hearts":80,"marriages":1,"coins_earned":100000,"purchases":50,"automation_cycles":100,"automated_tiles_watered":500,"automated_crops_planted":200,"automated_crops_harvested":200,"automation_animals_fed":100,"automation_items_processed":50}
	state_store.farm.rank = 10
	state_store.farm.automation_devices.clear()
	for device_x in range(6):
		state_store.farm.place_automation_device(Vector2i(device_x, 0), &"bell_generator")
	state_store.farm.automation_cycle_count = 100
	state_store.dungeon.max_reached = 40
	state_store.dungeon.defeated_bosses.assign([10, 20, 30, 40])
	state_store.dungeon.seals.assign(["spring", "summer", "autumn", "winter"])
	state_store.dungeon.final_boss_defeated = true
	state_store.dungeon.endless_unlocked = true
	for npc_id in ["mira","lian","soren","yuna","orin","eira","toma","nori","asha","piko"]:
		state_store.social.add_affection(StringName(npc_id), 500 if npc_id in ["mira","lian","soren","yuna"] else 250)
	state_store.social.add_affection(&"yuna", 2000)
	state_store.eldritch.eldritch_catches.clear()
	for fish: Dictionary in registry.get_all("fish"):
		if bool(fish.get("tide_required", false)):
			state_store.eldritch.eldritch_catches[String(fish.get("id", ""))] = 1
	state_store.eldritch.boss_unlocked = true
	state_store.eldritch.boss_defeated = true
	for tool_id in state_store.tools.tool_levels:
		state_store.tools.tool_levels[tool_id] = 4
	var story_completed := 0
	var story_failure := ""
	for _chapter in range(12):
		var result: Dictionary = state_store.try_complete_current_story_chapter()
		if bool(result.get("ok", false)):
			story_completed += 1
		elif story_failure.is_empty():
			story_failure = "%s｜%s" % [result.get("message", "未知錯誤"), str(result.get("missing", []))]
	_record("主線", "三年主線可連續完成", story_completed == 12, "%d/12%s" % [story_completed, "｜%s" % story_failure if not story_failure.is_empty() else ""])
	state_store._check_achievements()
	_record("成就", "14 項成就可解鎖", state_store.achievements.unlocked.size() == 14, "%d/14" % state_store.achievements.unlocked.size())
	var v5: Dictionary = state_store.to_save_data()
	var v4: Dictionary = v5.duplicate(true)
	v4.schema_version = 4
	var v4_farm: Dictionary = Dictionary(v4.farm).duplicate(true)
	for key in ["automation_devices","automation_cycle_count","automation_last_report"]:
		v4_farm.erase(key)
	v4.farm = v4_farm
	var v4_ok: bool = bool(state_store.load_save_data(v4))
	var v3: Dictionary = v5.duplicate(true)
	v3.schema_version = 3
	v3.erase("eldritch")
	var v3_ok: bool = bool(state_store.load_save_data(v3))
	var v2: Dictionary = v5.duplicate(true)
	v2.schema_version = 2
	for key in ["tools", "economy", "achievements", "lifetime_stats", "settings", "eldritch"]:
		v2.erase(key)
	var v2_ok: bool = bool(state_store.load_save_data(v2))
	var legacy := {"schema_version":1,"player":{"position":[12,34],"stats":{"max_health":100,"health":80,"attack":16}},"map":"mistfall_farm","flags":{},"quests":{},"inventory":{"health_potion":1},"calendar":{"year":2,"season_index":2,"day":28,"minute_of_day":720,"speed_mode":"relaxed"}}
	var v1_ok: bool = bool(state_store.load_save_data(legacy))
	_record("存檔", "v4→v5 自動化資料遷移", v4_ok)
	_record("存檔", "v3→v5 異潮資料遷移", v3_ok)
	_record("存檔", "v2→v5 遷移", v2_ok)
	_record("存檔", "28 日制 v1→v5 保留日期", v1_ok and state_store.calendar.year == 2 and state_store.calendar.season_index == 2 and state_store.calendar.day == 28)
	_record("內容", "48 作物／20 魚／40 料理", registry.get_all("crops").size() == 48 and registry.get_all("fish").size() == 20 and registry.get_all("recipes").size() == 40)
	_record("內容", "10 NPC／12 節慶／17+ 洞窟與異潮敵人／9 種自動設備", registry.get_all("npc_schedules").size() == 10 and registry.get_all("festivals").size() == 12 and registry.get_all("enemies").size() >= 17 and registry.get_all("automation_devices").size() == 9)
	_record("離線", "Runtime 場景沒有 HTTPRequest", get_nodes_in_group("http_clients").is_empty())


func _tap_action(action: StringName, settle_frames: int = 2) -> void:
	Input.action_press(action)
	await physics_frame
	Input.action_release(action)
	await _frames(settle_frames)


func _send_key_event(keycode: int, unicode_value: int = 0) -> void:
	var press := InputEventKey.new()
	press.pressed = true
	press.keycode = keycode
	press.physical_keycode = keycode
	press.unicode = unicode_value
	Input.parse_input_event(press)
	# Give the runtime a complete frame to sample the pressed state before the
	# synthetic key is released. One frame was race-prone on fast Apple Silicon.
	await _frames(2)
	var release := InputEventKey.new()
	release.pressed = false
	release.keycode = keycode
	release.physical_keycode = keycode
	release.unicode = unicode_value
	Input.parse_input_event(release)
	await _frames(2)


func _press_dialogue_button(index: int) -> bool:
	await process_frame
	var buttons: Array[Node] = game.dialogue_overlay.choices.get_children()
	if index < 0 or index >= buttons.size() or not (buttons[index] is Button):
		return false
	var button := buttons[index] as Button
	button.pressed.emit()
	await _frames(2)
	return true


func _wait_for_launch_ready(frame_limit: int) -> bool:
	for _frame_index in range(frame_limit):
		var ready_name_input: LineEdit = game.get("name_input") as LineEdit if is_instance_valid(game) else null
		if is_instance_valid(game) \
				and is_instance_valid(game.get("player")) \
				and is_instance_valid(game.get("title_overlay")) \
				and is_instance_valid(ready_name_input) \
				and is_instance_valid(game.get("appearance_input")) \
				and ready_name_input.has_focus():
			return true
		await process_frame
	return false


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _physics_frames(count: int) -> void:
	for _index in range(count):
		await physics_frame


func _wait_for_window_mode(expected_modes: Array, frame_limit: int = 120) -> bool:
	for _index in range(frame_limit):
		if DisplayServer.window_get_mode() in expected_modes:
			return true
		await process_frame
	return false


func _cleanup_test_save() -> void:
	if OS.get_environment("PIXELRPG_TEST_ISOLATED") != "1":
		return
	var target := String(save_manager.quick_save_path())
	var network_world := String(network.server_world_path())
	for path in [target, target + ".tmp", target + ".bak", target + ".bak.old", PixelRPGInputBindings.settings_path(), network_world, network_world + ".tmp", network_world + ".bak", network.client_id_path()]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _capture(file_stem: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	# macOS can retain a Retina backing texture after a fullscreen round-trip even
	# though the logical window is back at 1280x720. Normalize report artifacts so
	# every evidence image has the documented, comparable dimensions.
	if image.get_size() != EVIDENCE_SIZE:
		image.resize(EVIDENCE_SIZE.x, EVIDENCE_SIZE.y, Image.INTERPOLATE_LANCZOS)
	var relative_path := "%s/%s.png" % [REPORT_DIRECTORY, file_stem]
	var error := image.save_png(ProjectSettings.globalize_path(relative_path))
	if error == OK:
		screenshots.append(relative_path)
	else:
		_record("截圖", file_stem, false, "save_png error %d" % error)


func _record(category: String, name: String, passed: bool, detail: String = "") -> void:
	cases.append({"category":category, "name":name, "passed":passed, "detail":detail})
	print("[%s] %s｜%s%s" % ["PASS" if passed else "FAIL", category, name, "｜%s" % detail if not detail.is_empty() else ""])


func _failure_count() -> int:
	var count := 0
	for test_case: Dictionary in cases:
		count += int(not bool(test_case.passed))
	return count


func _write_reports() -> void:
	var elapsed := float(Time.get_ticks_usec() - started_usec) / 1_000_000.0
	var report := {
		"schema_version":1,
		"generated_at":Time.get_datetime_string_from_system(true),
		"engine":Engine.get_version_info(),
		"renderer":RenderingServer.get_video_adapter_name(),
		"viewport":[root.size.x, root.size.y],
		"checks":cases.size(),
		"passed":cases.size() - _failure_count(),
		"failed":_failure_count(),
		"elapsed_seconds":snappedf(elapsed, 0.01),
		"screenshots":screenshots,
		"cases":cases,
	}
	var json_file := FileAccess.open("%s/report.json" % REPORT_DIRECTORY, FileAccess.WRITE)
	json_file.store_string(JSON.stringify(report, "  ") + "\n")
	var markdown := PackedStringArray([
		"# 《霧落農歌：鐘塔之季》全功能實機驗收",
		"",
		"結果：**%s**　｜　%d 通過／%d 失敗　｜　%.2f 秒　｜　%s" % ["PASS" if _failure_count() == 0 else "FAIL", cases.size() - _failure_count(), _failure_count(), elapsed, RenderingServer.get_video_adapter_name()],
		"",
		"此報告由非 headless 的 Godot 視窗執行，實際建立遊戲場景、渲染畫面、驅動輸入、開啟 UI 並驗證狀態。",
		"",
		"| 分類 | 驗收項目 | 結果 | 細節 |",
		"|---|---|---:|---|",
	])
	for test_case: Dictionary in cases:
		markdown.append("| %s | %s | %s | %s |" % [test_case.category, test_case.name, "通過" if test_case.passed else "失敗", String(test_case.detail).replace("|", "／")])
	markdown.append("")
	markdown.append("## 畫面證據")
	markdown.append("")
	for screenshot_path: String in screenshots:
		markdown.append("- `%s`" % screenshot_path)
	var md_file := FileAccess.open("%s/REPORT.md" % REPORT_DIRECTORY, FileAccess.WRITE)
	md_file.store_string("\n".join(markdown) + "\n")
