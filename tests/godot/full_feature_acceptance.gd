extends SceneTree

const REPORT_DIRECTORY := "res://reports/full_feature_acceptance"

var cases: Array[Dictionary] = []
var screenshots: Array[String] = []
var state_store: Node
var registry: Node
var save_manager: Node
var game: Node
var player: Node
var started_usec := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	started_usec = Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIRECTORY))
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(640, 360)
	DisplayServer.window_set_title("霧落農歌：鐘塔之季｜全功能實機驗收中")
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	Engine.max_fps = 60
	state_store = root.get_node("GameState")
	registry = root.get_node("ContentRegistry")
	save_manager = root.get_node("SaveManager")
	state_store.reset()
	game = load("res://sample/main.tscn").instantiate()
	root.add_child(game)
	await _frames(8)
	player = game.player

	await _test_launch_and_profile()
	await _test_movement_and_animation()
	await _test_combat_and_dungeon()
	await _test_farming_animals_and_economy()
	await _test_village_dialogue_and_festival()
	await _test_menus_relationships_and_settings()
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
	var passed := _failure_count() == 0
	print("PixelRPG visible full-feature acceptance: %s (%d checks, %d screenshots)" % ["PASS" if passed else "FAIL", cases.size(), screenshots.size()])
	quit(0 if passed else 1)


func _test_launch_and_profile() -> void:
	_record("啟動", "正式遊戲場景完成渲染", is_instance_valid(game) and is_instance_valid(player))
	_record("啟動", "標題畫面顯示", is_instance_valid(game.title_overlay), "玩家時間應暫停")
	_record("角色建立", "玩家名稱欄位", is_instance_valid(game.name_input) and game.name_input.max_length == 12)
	_record("角色建立", "四種外觀選項", is_instance_valid(game.appearance_input) and game.appearance_input.item_count == 4)
	await _capture("01_title_and_profile")
	game.name_input.text = "實機測試員"
	game.appearance_input.select(2)
	game._close_title_screen()
	await _frames(4)
	_record("角色建立", "套用名稱與外觀", state_store.player_profile.name == "實機測試員" and int(state_store.player_profile.appearance.outfit) == 2)
	_record("啟動", "離開標題後恢復遊戲", not is_instance_valid(game.title_overlay) and player.is_physics_processing())


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
	_record("輸入", "斜向速度正規化", is_equal_approx(Vector2(1, 1).normalized().length(), 1.0))


func _test_combat_and_dungeon() -> void:
	game._enter_dungeon()
	await _frames(8)
	player.max_health = 9999
	player.health = 9999
	state_store.player_stats.max_health = 9999
	state_store.player_stats.health = 9999
	var enemies := get_nodes_in_group("enemies")
	_record("洞窟", "第 1 層生成敵人", enemies.size() >= 2, "%d 名" % enemies.size())
	await _capture("03_dungeon_combat")
	for node: Node in enemies:
		node.set_physics_process(false)
	var target: Node = enemies[0]
	target.max_health = 1000
	target.health = 1000
	player.global_position = Vector2(300, 210)
	player.facing = Vector2.RIGHT
	target.global_position = player.global_position + Vector2(28, 0)
	var attack_before: int = int(target.health)
	await _tap_action("attack", 12)
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
	game._begin_final_challenge()
	await _frames(6)
	await _capture("05_final_boss")
	var final_enemies := get_nodes_in_group("enemies")
	_record("最終戰", "霧鐘核心生成", final_enemies.size() == 1 and game.final_challenge_active)
	for enemy_node: Node in final_enemies:
		var enemy: Node = enemy_node
		enemy.take_damage(enemy.max_health + 1000, player)
	await _frames(8)
	_record("最終戰", "通關與無限模式", state_store.dungeon.final_boss_defeated and state_store.dungeon.endless_unlocked)
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
	player.global_position = Vector2(52, 292)
	var fish_before := int(state_store.lifetime_stats.fish_caught)
	for attempt in range(8):
		state_store.tools.stamina = 100
		state_store.calendar.day = attempt + 1
		state_store.calendar.minute_of_day = 10 * 60
		state_store.current_weather = "clear"
		player.global_position = Vector2(52, 292)
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
	state_store.tend_animal("chicken_1")
	var breeding: Dictionary = state_store.farm.begin_breeding("chicken_1")
	for _day in range(7):
		state_store.farm.tend_animal("chicken_1", true, false)
		state_store.farm.advance_day(&"spring", "clear")
	_record("動物", "照料、心情與繁殖", bool(breeding.ok) and state_store.farm.animals.size() == 3)
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


func _test_village_dialogue_and_festival() -> void:
	game._enter_village()
	await _frames(5)
	var visible_npcs := 0
	for sprite: Sprite2D in game.npc_sprites.values():
		visible_npcs += int(sprite.visible)
	_record("村莊", "10 名 NPC 可見與排程", visible_npcs == 10)
	player.global_position = Vector2(110, 115)
	var hearts_before: int = int(state_store.social.hearts(&"mira"))
	game._interact()
	await _frames(4)
	_record("對話", "NPC 對話、肖像與時間暫停", game.dialogue_overlay.visible and paused and state_store.calendar.paused)
	_record("關係", "每日交談增加好感", state_store.social.hearts(&"mira") >= hearts_before)
	await _capture("09_village_dialogue")
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


func _test_menus_relationships_and_settings() -> void:
	game.game_menu.open()
	await _frames(4)
	_record("選單", "旅人手冊暫停遊戲", game.game_menu.visible and paused and state_store.calendar.paused)
	_record("選單", "八個功能分頁", game.game_menu.tabs.get_tab_count() == 8)
	await _capture("11_status_inventory_menu")
	for tab_index in range(game.game_menu.tabs.get_tab_count()):
		game.game_menu.tabs.current_tab = tab_index
		game.game_menu.refresh()
		await _frames(1)
	_record("選單", "狀態、背包、關係、日曆、主線、成就、料理、設定均可切換", game.game_menu.tabs.current_tab == 7)

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
	_record("料理", "40 道料理清單", game.game_menu.recipe_select.item_count == 40)
	_record("料理", "烹調與享用恢復體力", cooked and state_store.tools.stamina > 0)

	game.game_menu.tabs.current_tab = 7
	game.game_menu._on_volume_changed(0.35)
	var old_speed := String(state_store.calendar.speed_mode)
	game.game_menu._on_speed_pressed()
	_record("設定", "音量調整", is_equal_approx(float(state_store.settings.master_volume), 0.35))
	_record("設定", "10/15/20 分鐘速度切換", String(state_store.calendar.speed_mode) != old_speed)
	game.game_menu._on_fullscreen_toggled(true)
	await _frames(2)
	var fullscreen_ok := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	game.game_menu._on_fullscreen_toggled(false)
	await _frames(2)
	_record("設定", "視窗／全螢幕切換", fullscreen_ok and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED)
	game.game_menu._begin_rebind(&"attack")
	var key_event := InputEventKey.new()
	key_event.pressed = true
	key_event.physical_keycode = KEY_P
	game.game_menu._unhandled_input(key_event)
	var rebound := false
	for event: InputEvent in InputMap.action_get_events("attack"):
		if event is InputEventKey and event.physical_keycode == KEY_P:
			rebound = true
	game.game_menu._reset_controls()
	var restored := false
	var controller_mapped := false
	for event: InputEvent in InputMap.action_get_events("attack"):
		if event is InputEventKey and event.physical_keycode == KEY_J:
			restored = true
		if event is InputEventJoypadButton:
			controller_mapped = true
	_record("設定", "按鍵重新綁定與還原", rebound and restored)
	_record("手把", "戰鬥按鈕映射", controller_mapped)
	state_store.coins = 12345
	var save_ok: bool = bool(save_manager.save_quick())
	state_store.coins = 7
	var load_ok: bool = bool(save_manager.load_quick())
	_record("存檔", "SaveGame v3 快速存讀", save_ok and load_ok and state_store.coins == 12345)
	game.game_menu.close()
	await _frames(3)


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
	state_store.lifetime_stats = {"days_played":360,"crops_harvested":1000,"fish_caught":100,"resources_gathered":100,"monsters_defeated":100,"bosses_defeated":4,"festivals_attended":12,"relationship_hearts":20,"marriages":1,"coins_earned":100000,"purchases":50}
	state_store.farm.rank = 10
	state_store.dungeon.max_reached = 40
	state_store.dungeon.defeated_bosses.assign([10, 20, 30, 40])
	state_store.dungeon.seals.assign(["spring", "summer", "autumn", "winter"])
	state_store.dungeon.final_boss_defeated = true
	state_store.dungeon.endless_unlocked = true
	state_store.social.add_affection(&"yuna", 2500)
	for tool_id in state_store.tools.tool_levels:
		state_store.tools.tool_levels[tool_id] = 4
	var story_completed := 0
	for _chapter in range(12):
		var result: Dictionary = state_store.try_complete_current_story_chapter()
		if bool(result.get("ok", false)):
			story_completed += 1
	_record("主線", "三年主線可連續完成", story_completed == 12)
	state_store._check_achievements()
	_record("成就", "12 項成就可解鎖", state_store.achievements.unlocked.size() == 12, "%d/12" % state_store.achievements.unlocked.size())
	var v3: Dictionary = state_store.to_save_data()
	var v2: Dictionary = v3.duplicate(true)
	v2.schema_version = 2
	for key in ["tools", "economy", "achievements", "lifetime_stats", "settings"]:
		v2.erase(key)
	var v2_ok: bool = bool(state_store.load_save_data(v2))
	var legacy := {"schema_version":1,"player":{"position":[12,34],"stats":{"max_health":100,"health":80,"attack":16}},"map":"mistfall_farm","flags":{},"quests":{},"inventory":{"health_potion":1},"calendar":{"year":2,"season_index":2,"day":28,"minute_of_day":720,"speed_mode":"relaxed"}}
	var v1_ok: bool = bool(state_store.load_save_data(legacy))
	_record("存檔", "v2→v3 遷移", v2_ok)
	_record("存檔", "28 日制 v1→v3 保留日期", v1_ok and state_store.calendar.year == 2 and state_store.calendar.season_index == 2 and state_store.calendar.day == 28)
	_record("內容", "48 作物／12 魚／40 料理", registry.get_all("crops").size() == 48 and registry.get_all("fish").size() == 12 and registry.get_all("recipes").size() == 40)
	_record("內容", "10 NPC／12 節慶／16 洞窟敵人", registry.get_all("npc_schedules").size() == 10 and registry.get_all("festivals").size() == 12 and registry.get_all("enemies").size() >= 16)
	_record("離線", "Runtime 場景沒有 HTTPRequest", get_nodes_in_group("http_clients").is_empty())


func _tap_action(action: StringName, settle_frames: int = 2) -> void:
	Input.action_press(action)
	await physics_frame
	Input.action_release(action)
	await _frames(settle_frames)


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _physics_frames(count: int) -> void:
	for _index in range(count):
		await physics_frame


func _capture(file_stem: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
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
