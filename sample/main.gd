extends Node2D

const PlayerSceneScript := preload("res://runtime/actors/player.gd")
const EnemySceneScript := preload("res://runtime/actors/enemy.gd")
const GameMenuScript := preload("res://runtime/ui/game_menu.gd")
const ShopMenuScript := preload("res://runtime/ui/shop_menu.gd")
const DialogueOverlayScript := preload("res://runtime/ui/dialogue_overlay.gd")
const FestivalOverlayScript := preload("res://runtime/ui/festival_overlay.gd")
const MultiplayerMenuScript := preload("res://runtime/ui/multiplayer_menu.gd")
const RemotePlayerScript := preload("res://runtime/network/remote_player.gd")

const PLOT_ORIGIN := Vector2(221, 159)
const PLOT_SPACING := Vector2(36, 26)
const PLOT_COLUMNS := 6
const PLOT_ROWS := 4
const MIRA_POSITION := Vector2(102, 166)
const CHICKEN_POSITION := Vector2(500, 155)
const COW_POSITION := Vector2(532, 188)
const CAVE_POSITION := Vector2(574, 294)
const SHIPPING_POSITION := Vector2(274, 290)
const SHOP_POSITIONS := {
	"mira_seed_shop": Vector2(145, 148),
	"soren_forge": Vector2(310, 112),
	"toma_general_store": Vector2(500, 150),
	"orin_ranch": Vector2(230, 260),
}
const FARM_RESOURCES := {
	"tree_west": {"position": Vector2(42, 92), "kind": "tree"},
	"tree_north": {"position": Vector2(610, 92), "kind": "tree"},
	"stone_south": {"position": Vector2(105, 318), "kind": "stone"},
}
const DUNGEON_ORE_POSITION := Vector2(126, 108)
const VILLAGE_GATE_POSITION := Vector2(24, 224)
const NPC_POSITIONS := {
	"mira": Vector2(110, 115), "lian": Vector2(180, 245), "soren": Vector2(286, 112), "yuna": Vector2(370, 220),
	"orin": Vector2(455, 112), "eira": Vector2(525, 205), "toma": Vector2(555, 104), "nori": Vector2(305, 252),
	"asha": Vector2(220, 174), "piko": Vector2(430, 276),
}

var player: PixelRPGPlayer
var hud_label: Label
var toast_label: Label
var title_label: Label
var controls_label: Label
var title_overlay: CanvasLayer
var mode := "farm"
var selected_seed_index := 0
var seasonal_seed_ids: Array[StringName] = []
var enemies_remaining := 0
var hit_stop_active := false
var floor_cleared := false
var final_challenge_active := false
var eldritch_challenge_active := false
var toast_tween: Tween
var name_input: LineEdit
var appearance_input: OptionButton
var game_menu: PixelRPGGameMenu
var shop_menu: PixelRPGShopMenu
var dialogue_overlay: PixelRPGDialogueOverlay
var festival_overlay: PixelRPGFestivalOverlay
var multiplayer_menu: PixelRPGMultiplayerMenu
var world_background: Sprite2D
var npc_sprites: Dictionary = {}
var animal_sprites: Dictionary = {}
var ui_refresh_timer := 0.0
var weather_refresh_timer := 0.0
var remote_players: Dictionary = {}


func _ready() -> void:
	if "--server" in OS.get_cmdline_user_args():
		hide()
		set_process(false)
		return
	_apply_launch_display_mode()
	seed(1337)
	PixelRPGInputBindings.load_saved()
	mode = "dungeon" if GameState.current_map_id == &"mistfall_depths" else ("village" if GameState.current_map_id == &"mistfall_village" else ("abyss" if GameState.current_map_id == &"dreaming_shore" else "farm"))
	_create_background()
	_create_npc_sprites()
	_create_world_walls()
	_create_player()
	_create_hud()
	_create_commercial_menus()
	_refresh_seasonal_seeds()
	_connect_events()
	if mode == "dungeon":
		_enter_dungeon(false)
	elif mode == "abyss":
		_begin_eldritch_challenge(false)
	elif not bool(GameState.get_flag(&"title_seen", false)):
		_create_title_screen()
	queue_redraw()


func _apply_launch_display_mode() -> void:
	# Steam sets SteamTenfoot=1 when launching from Big Picture. Respect that
	# runtime hint without persisting it over the player's own window setting.
	var steam_big_picture := OS.get_environment("SteamTenfoot") == "1"
	var wants_fullscreen := steam_big_picture or bool(GameState.settings.get("fullscreen", false))
	var target_mode := DisplayServer.WINDOW_MODE_FULLSCREEN if wants_fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != target_mode:
		DisplayServer.window_set_mode(target_mode)


func _exit_tree() -> void:
	GameState.pause_game_time(false)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("multiplayer_menu"):
		multiplayer_menu.toggle()
		return
	if is_instance_valid(title_overlay):
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("interact"):
			_close_title_screen()
		return
	if Input.is_action_just_pressed("pause_menu"):
		game_menu.toggle()
		return
	_animate_world_sprites()
	ui_refresh_timer -= delta
	if ui_refresh_timer <= 0.0:
		ui_refresh_timer = 0.25
		_update_hud()
		_update_environment_tint()
		_update_animal_sprites()
	if mode != "dungeon" and GameState.current_weather in ["rain", "storm", "typhoon", "snow", "blizzard"]:
		weather_refresh_timer -= delta
		if weather_refresh_timer <= 0.0:
			weather_refresh_timer = 1.0 / 30.0
			queue_redraw()
	if Input.is_action_just_pressed("interact"):
		_interact()
	if Input.is_action_just_pressed("cycle_seed") and mode == "farm":
		_cycle_seed()
	if Input.is_action_just_pressed("time_speed"):
		if NetworkManager.is_client():
			_show_toast("連線世界的時間速度由主機決定")
		else:
			GameState.cycle_time_speed()
	if Input.is_action_just_pressed("sleep_day") and mode == "farm":
		if NetworkManager.is_client():
			_show_toast("連線世界由主機決定何時結束今日")
		else:
			GameState.sleep_if_allowed()
	if Input.is_action_just_pressed("toggle_cave"):
		if mode == "farm":
			_enter_dungeon()
		elif mode == "dungeon":
			_leave_dungeon()
		elif mode == "abyss":
			_leave_eldritch_shore()
		else:
			_show_toast("請先由村口返回農場")
	if Input.is_action_just_pressed("attend_festival") and mode == "farm":
		festival_overlay.open_today()
	if Input.is_action_just_pressed("use_potion") and is_instance_valid(player):
		if GameState.consume_item(&"health_potion"):
			player.heal(35)
			_show_toast("使用回復藥水")


func _draw() -> void:
	if mode == "farm":
		_draw_farm()
	elif mode == "village":
		_draw_village()
	elif mode == "dungeon":
		_draw_dungeon()
	else:
		_draw_abyss()
	_draw_weather()


func _draw_farm() -> void:
	draw_rect(Rect2(SHIPPING_POSITION - Vector2(16, 13), Vector2(32, 26)), Color(0.47, 0.86, 0.79, 0.78), false, 2.0)
	draw_string(ThemeDB.fallback_font, SHIPPING_POSITION + Vector2(-25, 27), "出貨箱", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("fff1b6"))
	# Farm plots and crop growth stages.
	for y in range(PLOT_ROWS):
		for x in range(PLOT_COLUMNS):
			var tile := Vector2i(x, y)
			var center := _plot_world_position(tile)
			var key := "%d,%d" % [x, y]
			var plot: Dictionary = Dictionary(GameState.farm.plots.get(key, {}))
			var tilled := bool(plot.get("tilled", false))
			if tilled:
				draw_rect(Rect2(center - Vector2(12, 10), Vector2(24, 20)), Color(0.35, 0.20, 0.12, 0.34), true)
			draw_rect(Rect2(center - Vector2(12, 10), Vector2(24, 20)), Color(0.85, 0.71, 0.43, 0.42), false, 1.0)
			if bool(plot.get("watered", false)):
				draw_rect(Rect2(center - Vector2(11, 9), Vector2(22, 18)), Color(0.25, 0.58, 0.72, 0.42))
			var crop_id := String(plot.get("crop_id", ""))
			if not crop_id.is_empty():
				var crop := ContentRegistry.get_artifact("crops", crop_id)
				var crop_color := Color(String(crop.get("color", "78dcca")))
				if bool(plot.get("withered", false)):
					crop_color = Color("625747")
				var progress := float(plot.get("growth_progress", 0)) / maxf(1.0, float(crop.get("growth_days", 1)))
				var size := lerpf(4.0, 11.0, clampf(progress, 0.0, 1.0))
				draw_line(center + Vector2(0, 7), center - Vector2(0, size), Color("3f6f48"), 3.0)
				draw_circle(center - Vector2(0, size), size * 0.55, crop_color)
	# NPC and animals.
	if _mira_is_on_farm():
		_draw_person(MIRA_POSITION, Color("6b5fa8"), "米拉")
	for index in range(GameState.farm.animals.size()):
		var _animal: Dictionary = GameState.farm.animals[index]
	for node_id: String in FARM_RESOURCES:
		if not bool(GameState.get_flag("gathered_%d_%s" % [GameState.calendar.absolute_day(), node_id], false)):
			var resource: Dictionary = FARM_RESOURCES[node_id]
			_draw_resource(Vector2(resource.position), String(resource.kind))
	draw_string(ThemeDB.fallback_font, CAVE_POSITION + Vector2(-31, 38), "四季鐘窟", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("dce5ee"))
	var festival: Dictionary = GameState.festivals.festival_on(GameState.calendar.season_id(), GameState.calendar.day)
	if not festival.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(242, 86), "★ 今日：%s（F 參加）" % festival.get("display_name"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("fff1b6"))
	var tide_active: bool = GameState.eldritch.is_tide_active(GameState.calendar.day, GameState.calendar.minute_of_day, GameState.current_weather)
	draw_string(ThemeDB.fallback_font, Vector2(25, 322), "池塘 E/Y・%s" % ("無星異潮" if tide_active else "四季釣場"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("b6f3ef") if tide_active else Color("dce5ee"))


func _draw_dungeon() -> void:
	var floor_number := maxi(1, GameState.dungeon.current_floor)
	var zone_index := clampi((floor_number - 1) / 10, 0, 3)
	draw_rect(Rect2(18, 52, 604, 286), [Color("6bbf83"), Color("df704e"), Color("d6a348"), Color("89cfe2")][zone_index], false, 2.0)
	if floor_cleared:
		draw_circle(Vector2(570, 292), 22, Color("78dcca"))
		draw_circle(Vector2(570, 292), 13, Color("171a2b"))
		draw_string(ThemeDB.fallback_font, Vector2(520, 328), "E 前往下一層", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("fff1b6"))
	var ore_id := "ore_%d" % floor_number
	if not bool(GameState.get_flag("gathered_%d_%s" % [GameState.calendar.absolute_day(), ore_id], false)):
		_draw_resource(DUNGEON_ORE_POSITION, "ore")


func _draw_abyss() -> void:
	draw_rect(Rect2(18, 52, 604, 286), Color("34265e"), false, 3.0)
	for ring in range(5):
		draw_arc(Vector2(320, 196), 44.0 + ring * 21.0, 0.0, TAU, 48, Color(0.29, 0.84, 0.78, 0.16), 2.0)
	if floor_cleared:
		draw_circle(Vector2(570, 292), 22, Color("78dcca"))
		draw_circle(Vector2(570, 292), 13, Color("171a2b"))
		draw_string(ThemeDB.fallback_font, Vector2(510, 328), "E/Y 返回農場", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("fff1b6"))


func _draw_village() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(270, 84), "霧落村廣場", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("fff1b6"))
	for npc_id: String in NPC_POSITIONS:
		var character := ContentRegistry.get_artifact("characters", npc_id)
		var color := Color("6b5fa8") if npc_id in ["mira", "lian", "soren", "yuna"] else Color("557a68")
		_draw_person(Vector2(NPC_POSITIONS[npc_id]), color, String(character.get("display_name", npc_id)))
	for shop_id: String in SHOP_POSITIONS:
		var sign_position: Vector2 = SHOP_POSITIONS[shop_id]
		draw_circle(sign_position, 8, Color(0.47, 0.86, 0.79, 0.78), false, 2.0)
		draw_string(ThemeDB.fallback_font, sign_position + Vector2(-22, 24), String(ContentRegistry.get_artifact("shops", shop_id).get("display_name", "商店")), HORIZONTAL_ALIGNMENT_LEFT, 80, 10, Color("fff1b6"))
	draw_string(ThemeDB.fallback_font, VILLAGE_GATE_POSITION + Vector2(-14, 34), "農場", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("fff1b6"))


func _draw_person(position: Vector2, color: Color, label: String) -> void:
	var _unused_color := color
	draw_string(ThemeDB.fallback_font, position + Vector2(-14, 32), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("fff1b6"))


func _draw_chicken(position: Vector2) -> void:
	draw_circle(position, 9, Color("f4ead3"))
	draw_circle(position + Vector2(7, -7), 5, Color("fff7e8"))
	draw_polygon(PackedVector2Array([position + Vector2(12, -7), position + Vector2(18, -4), position + Vector2(12, -2)]), PackedColorArray([Color("e6b64f")]))


func _draw_cow(position: Vector2) -> void:
	draw_rect(Rect2(position - Vector2(14, 9), Vector2(28, 18)), Color("eee6d8"))
	draw_rect(Rect2(position - Vector2(8, 8), Vector2(9, 8)), Color("514346"))
	draw_circle(position + Vector2(15, -4), 8, Color("eee6d8"))


func _draw_resource(position: Vector2, kind: String) -> void:
	var _unused := [position, kind]


func _create_player() -> void:
	player = PlayerSceneScript.new() as PixelRPGPlayer
	player.name = "Player"
	player.global_position = GameState.player_position
	add_child(player)
	NetworkManager.set_local_player_node(player)


func _create_background() -> void:
	world_background = Sprite2D.new()
	world_background.z_index = -100
	world_background.position = Vector2(320, 180)
	world_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(world_background)
	_set_background_for_mode()


func _set_background_for_mode() -> void:
	if not is_instance_valid(world_background):
		return
	var path := "res://assets/runtime/backgrounds/mistfall_farm_commercial.png"
	if mode == "village":
		path = "res://assets/runtime/backgrounds/mistfall_village_commercial.png"
	elif mode in ["dungeon", "abyss"]:
		path = "res://assets/runtime/backgrounds/mistfall_dungeon_commercial.png"
	world_background.texture = load(path)
	if world_background.texture != null:
		world_background.scale = Vector2(640.0 / world_background.texture.get_width(), 360.0 / world_background.texture.get_height())
	_update_npc_sprites()
	_update_environment_tint()


func _update_environment_tint() -> void:
	if not is_instance_valid(world_background):
		return
	var season_tints := [Color("f0fff1"), Color("fff4d8"), Color("ffd9b2"), Color("dceeff")]
	var tint: Color = season_tints[GameState.calendar.season_index]
	if mode == "abyss":
		world_background.modulate = Color("51427e")
		return
	var hour: float = float(GameState.calendar.minute_of_day) / 60.0
	if hour >= 20.0:
		tint = tint * Color(0.48, 0.55, 0.78)
	elif hour >= 18.0:
		var dusk := clampf((hour - 18.0) / 2.0, 0.0, 1.0)
		tint = tint.lerp(tint * Color(0.52, 0.59, 0.82), dusk)
	world_background.modulate = tint


func _draw_weather() -> void:
	if mode in ["dungeon", "abyss"]:
		return
	var motion := int(Time.get_ticks_msec() / 28)
	match GameState.current_weather:
		"rain", "storm", "typhoon":
			var count := 58 if GameState.current_weather == "rain" else 92
			for index in range(count):
				var x := float(posmod(index * 83 + motion * 3, 680) - 20)
				var y := float(posmod(index * 47 + motion * 7, 330) + 30)
				draw_line(Vector2(x, y), Vector2(x - 4, y + 11), Color(0.55, 0.82, 1.0, 0.58), 1.0)
		"snow", "blizzard":
			var count := 52 if GameState.current_weather == "snow" else 88
			for index in range(count):
				var x := float(posmod(index * 71 + motion, 660) - 10)
				var y := float(posmod(index * 43 + motion * 2, 330) + 30)
				draw_circle(Vector2(x, y), 1.5, Color(0.92, 0.97, 1.0, 0.75))
		"fog":
			draw_rect(Rect2(0, 52, 640, 286), Color(0.75, 0.82, 0.84, 0.18))


func _create_npc_sprites() -> void:
	var atlas: Texture2D = load("res://assets/runtime/sprites/character_atlas_alpha.png")
	if atlas == null:
		return
	var atlas_indices := {"mira":1,"lian":2,"soren":3,"yuna":4,"orin":5,"eira":6,"toma":7,"nori":8,"asha":9,"piko":10}
	for npc_id: String in atlas_indices:
		var index: int = int(atlas_indices[npc_id])
		var region := AtlasTexture.new()
		region.atlas = atlas
		var frame_width := floori(atlas.get_width() / 4.0)
		var frame_height := floori(atlas.get_height() / 3.0)
		region.region = Rect2((index % 4) * frame_width, (index / 4) * frame_height, frame_width, frame_height)
		var sprite := Sprite2D.new()
		sprite.texture = region
		sprite.scale = Vector2(0.145, 0.145)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.z_index = 2
		add_child(sprite)
		npc_sprites[npc_id] = sprite
	_update_npc_sprites()


func _update_npc_sprites() -> void:
	if npc_sprites.is_empty():
		return
	for npc_id: String in npc_sprites:
		var sprite: Sprite2D = npc_sprites[npc_id]
		sprite.visible = false
		if mode == "village":
			sprite.position = Vector2(NPC_POSITIONS[npc_id]) + Vector2(0, -12)
			sprite.visible = true
		elif mode == "farm" and npc_id == "mira" and _mira_is_on_farm():
			sprite.position = MIRA_POSITION + Vector2(0, -12)
			sprite.visible = true


func _create_world_walls() -> void:
	_create_wall(Vector2(320, 46), Vector2(640, 16))
	_create_wall(Vector2(320, 348), Vector2(640, 16))
	_create_wall(Vector2(12, 180), Vector2(16, 360))
	_create_wall(Vector2(628, 180), Vector2(16, 360))


func _create_wall(wall_position: Vector2, size: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.position = wall_position
	wall.collision_layer = 1
	wall.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	wall.add_child(collision)
	add_child(wall)


func _create_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var top_panel := ColorRect.new()
	top_panel.color = Color(0.055, 0.063, 0.105, 0.93)
	top_panel.position = Vector2.ZERO
	top_panel.size = Vector2(640, 54)
	canvas.add_child(top_panel)
	hud_label = Label.new()
	hud_label.position = Vector2(10, 4)
	hud_label.size = Vector2(620, 48)
	hud_label.add_theme_font_size_override("font_size", 13)
	hud_label.add_theme_color_override("font_color", Color("fff1b6"))
	top_panel.add_child(hud_label)
	var bottom_panel := ColorRect.new()
	bottom_panel.color = Color(0.055, 0.063, 0.105, 0.9)
	bottom_panel.position = Vector2(0, 336)
	bottom_panel.size = Vector2(640, 24)
	canvas.add_child(bottom_panel)
	controls_label = Label.new()
	controls_label.position = Vector2(8, 4)
	controls_label.size = Vector2(624, 18)
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_label.add_theme_font_size_override("font_size", 10)
	controls_label.add_theme_color_override("font_color", Color("b8c4d9"))
	bottom_panel.add_child(controls_label)
	toast_label = Label.new()
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.position = Vector2(120, 304)
	toast_label.size = Vector2(400, 28)
	toast_label.add_theme_font_size_override("font_size", 14)
	toast_label.add_theme_color_override("font_color", Color("fff1b6"))
	canvas.add_child(toast_label)
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2(135, 125)
	title_label.size = Vector2(370, 85)
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color("fff1b6"))
	canvas.add_child(title_label)


func _create_commercial_menus() -> void:
	game_menu = GameMenuScript.new() as PixelRPGGameMenu
	add_child(game_menu)
	shop_menu = ShopMenuScript.new() as PixelRPGShopMenu
	add_child(shop_menu)
	dialogue_overlay = DialogueOverlayScript.new() as PixelRPGDialogueOverlay
	add_child(dialogue_overlay)
	festival_overlay = FestivalOverlayScript.new() as PixelRPGFestivalOverlay
	add_child(festival_overlay)
	multiplayer_menu = MultiplayerMenuScript.new() as PixelRPGMultiplayerMenu
	add_child(multiplayer_menu)


func _create_title_screen() -> void:
	GameState.pause_game_time(true)
	player.set_physics_process(false)
	title_overlay = CanvasLayer.new()
	title_overlay.layer = 20
	add_child(title_overlay)
	var image := TextureRect.new()
	image.texture = load("res://assets/runtime/backgrounds/mistfall_farm_title.png")
	image.position = Vector2.ZERO
	image.size = Vector2(640, 360)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	title_overlay.add_child(image)
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.06, 0.08, 0.42)
	shade.position = Vector2.ZERO
	shade.size = Vector2(640, 360)
	title_overlay.add_child(shade)
	var title := Label.new()
	title.text = "霧落農歌\n鐘塔之季"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(125, 74)
	title.size = Vector2(390, 100)
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("fff1b6"))
	title_overlay.add_child(title)
	var profile_panel := PanelContainer.new()
	profile_panel.position = Vector2(190, 184)
	profile_panel.size = Vector2(260, 92)
	title_overlay.add_child(profile_panel)
	var profile_box := VBoxContainer.new()
	profile_panel.add_child(profile_box)
	name_input = LineEdit.new()
	name_input.placeholder_text = "輸入玩家名字"
	name_input.text = String(GameState.player_profile.get("name", "旅人"))
	name_input.max_length = 12
	profile_box.add_child(name_input)
	appearance_input = OptionButton.new()
	for appearance_name in ["旅人裝束・晨霧", "旅人裝束・松葉", "旅人裝束・晚霞", "旅人裝束・星夜"]:
		appearance_input.add_item(appearance_name)
	appearance_input.selected = int(Dictionary(GameState.player_profile.get("appearance", {})).get("outfit", 0))
	profile_box.add_child(appearance_input)
	var subtitle := Label.new()
	subtitle.text = "30 日 × 四季 × 無限年份　｜　Enter／A 開始　M／Select 連線"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(90, 292)
	subtitle.size = Vector2(460, 35)
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color("f4ead3"))
	title_overlay.add_child(subtitle)


func _close_title_screen() -> void:
	var chosen_name := name_input.text.strip_edges() if is_instance_valid(name_input) else "旅人"
	GameState.player_profile["name"] = chosen_name if not chosen_name.is_empty() else "旅人"
	var appearance := Dictionary(GameState.player_profile.get("appearance", {})).duplicate(true)
	appearance["outfit"] = appearance_input.selected if is_instance_valid(appearance_input) else 0
	GameState.player_profile["appearance"] = appearance
	GameState.set_flag(&"title_seen", true)
	GameState.pause_game_time(false)
	player.set_physics_process(true)
	title_overlay.queue_free()
	title_overlay = null
	_show_toast("歡迎來到霧落村。先走近農地按 E 翻土。")


func _connect_events() -> void:
	EventBus.actor_damaged.connect(_on_actor_damaged)
	EventBus.enemy_defeated.connect(_on_enemy_defeated)
	EventBus.player_defeated.connect(_on_player_defeated)
	EventBus.combat_hit_stop_requested.connect(_on_hit_stop_requested)
	EventBus.toast_requested.connect(_show_toast)
	EventBus.day_started.connect(_on_day_started)
	EventBus.festival_available.connect(_on_festival_available)
	NetworkManager.snapshot_received.connect(_on_network_snapshot)
	NetworkManager.action_result_received.connect(_on_network_action_result)
	NetworkManager.status_changed.connect(_on_network_status_changed)


func _update_hud() -> void:
	if not is_instance_valid(player) or not is_instance_valid(hud_label):
		return
	var forecast := PixelRPGCalendarSystem.forecast_for_tomorrow(GameState.calendar.year, GameState.calendar.season_index, GameState.calendar.day)
	var warning := " ⚠明日%s" % _weather_name(String(forecast.weather)) if bool(forecast.warning) else ""
	if mode in ["farm", "village"]:
		var seed_id := _selected_seed_id()
		var crop := ContentRegistry.get_artifact("crops", seed_id)
		var animal_products := int(GameState.farm.produce.get("egg", 0)) + int(GameState.farm.produce.get("milk", 0))
		var tide_text := "異潮" if GameState.eldritch.is_tide_active(GameState.calendar.day, GameState.calendar.minute_of_day, GameState.current_weather) else "平潮"
		hud_label.text = "%s　%s　%s%s　%dG　體力 %d/100　理智 %d/100\n農場 Lv.%d　種子：%s ×%d　收成庫 %d　出貨 %dG　%s" % [GameState.calendar.date_text(), GameState.calendar.time_text(), _weather_name(GameState.current_weather), warning, GameState.coins, GameState.tools.stamina, GameState.eldritch.sanity, GameState.farm.rank, crop.get("display_name", "無"), int(GameState.farm.seed_stock.get(String(seed_id), 0)), GameState.farm.produce.size() + animal_products, GameState.economy.pending_value(), tide_text]
		controls_label.text = "E/Y 互動/釣魚　Q/RB 換種子　Esc/Start 手冊　M/Select 連線　T/D← 速度　C/D→ 睡覺"
	elif mode == "dungeon":
		hud_label.text = "%s　%s　HP %d/%d　四季鐘窟 %dF　敵人 %d\n封印 %d/4　電梯 %s　%s" % [GameState.calendar.date_text(), GameState.calendar.time_text(), player.health, player.max_health, GameState.dungeon.current_floor, enemies_remaining, GameState.dungeon.seals.size(), str(GameState.dungeon.available_elevators()), "無限挑戰已開放" if GameState.dungeon.endless_unlocked else "主線無期限"]
		controls_label.text = "WASD/搖桿 移動　J/A 攻擊　K/B 翻滾　L/X 技能　E/Y 下層　B/RS 返回　H/LB 藥水"
	else:
		hud_label.text = "%s　%s　HP %d/%d　夢岸敵影 %d\n理智 %d/100　異魚 %d/8　洞見 %d　%s" % [GameState.calendar.date_text(), GameState.calendar.time_text(), player.health, player.max_health, enemies_remaining, GameState.eldritch.sanity, GameState.eldritch.eldritch_catches.size(), GameState.eldritch.insight, "古神已沉睡" if GameState.eldritch.boss_defeated else "克蘇魯之影正在凝視"]
		controls_label.text = "WASD/搖桿 移動　J/A 攻擊　K/B 翻滾　L/X 技能　H/LB 藥水　B/RS 撤退"


func _interact() -> void:
	if mode == "abyss":
		if floor_cleared:
			_leave_eldritch_shore()
		else:
			_show_toast("深潮尚未平息")
		return
	if mode == "dungeon":
		if player.global_position.distance_to(DUNGEON_ORE_POSITION) <= 38.0:
			var ore_result := GameState.gather_resource("ore_%d" % GameState.dungeon.current_floor, "ore")
			_show_toast(String(ore_result.get("message", "")))
			return
		if floor_cleared:
			_descend_dungeon()
		else:
			_show_toast("清除本層敵人後才能前進")
		return
	if mode == "village":
		if player.global_position.distance_to(VILLAGE_GATE_POSITION) <= 44.0:
			_enter_farm_from_village()
			return
		var village_shop := _nearby_shop()
		if not village_shop.is_empty():
			shop_menu.open(village_shop)
			return
		var npc_id := _nearby_npc()
		if not npc_id.is_empty():
			_talk_to_npc(npc_id)
			return
	if mode == "farm" and player.global_position.distance_to(VILLAGE_GATE_POSITION) <= 44.0:
		_enter_village()
		return
	if mode == "farm":
		for node_id: String in FARM_RESOURCES:
			var resource: Dictionary = FARM_RESOURCES[node_id]
			if player.global_position.distance_to(Vector2(resource.position)) <= 36.0:
				if NetworkManager.is_online():
					NetworkManager.request_world_action("gather", {"node_id": node_id, "kind": String(resource.kind)})
					return
				var gather_result := GameState.gather_resource(node_id, String(resource.kind))
				_show_toast(String(gather_result.get("message", "")))
				return
	if mode == "village":
		_show_toast("走近村民、商店招牌或村口再互動")
		return
	if player.global_position.distance_to(SHIPPING_POSITION) <= 42.0:
		if NetworkManager.is_online():
			NetworkManager.request_world_action("ship")
			return
		var shipping_result := GameState.ship_all_produce()
		_show_toast(String(shipping_result.get("message", "")))
		return
	if _mira_is_on_farm() and player.global_position.distance_to(MIRA_POSITION) <= 42.0:
		_talk_to_npc("mira")
		return
	if player.global_position.distance_to(Vector2(52, 292)) <= 48.0:
		if GameState.eldritch.can_challenge() and GameState.eldritch.is_tide_active(GameState.calendar.day, GameState.calendar.minute_of_day, GameState.current_weather):
			_begin_eldritch_challenge()
			return
		if NetworkManager.is_online():
			NetworkManager.request_world_action("fish", {"location": "pond"})
			return
		var catch_result := GameState.fish_at("pond")
		_show_toast(String(catch_result.get("message", "")))
		return
	var nearby_animal := _nearby_animal()
	if not nearby_animal.is_empty():
		if NetworkManager.is_online():
			NetworkManager.request_world_action("tend_animal", {"animal_id": nearby_animal})
			return
		_interact_animal(nearby_animal)
		return
	if player.global_position.distance_to(CAVE_POSITION) <= 48.0:
		_enter_dungeon()
		return
	var tile := _nearest_plot()
	if tile.x < 0:
		_show_toast("走近農地、村民、動物或洞窟再互動")
		return
	if NetworkManager.is_online():
		NetworkManager.request_world_action("farm_plot", {"x": tile.x, "y": tile.y, "seed_id": String(_selected_seed_id())})
		return
	var result := GameState.interact_farm_plot(tile, _selected_seed_id())
	_show_toast(String(result.get("message", "")))


func _nearby_shop() -> StringName:
	for shop_id: String in SHOP_POSITIONS:
		if player.global_position.distance_to(Vector2(SHOP_POSITIONS[shop_id])) <= 38.0:
			return StringName(shop_id)
	return &""


func _nearby_animal() -> String:
	for index in range(GameState.farm.animals.size()):
		var animal: Dictionary = GameState.farm.animals[index]
		var animal_position := Vector2(490 + (index % 4) * 31, 154 + (index / 4) * 33)
		if player.global_position.distance_to(animal_position) <= 38.0:
			return String(animal.get("id", ""))
	return ""


func _nearby_npc() -> String:
	for npc_id: String in NPC_POSITIONS:
		if player.global_position.distance_to(Vector2(NPC_POSITIONS[npc_id])) <= 34.0:
			return npc_id
	return ""


func _talk_to_npc(npc_id: String) -> void:
	if NetworkManager.is_online():
		NetworkManager.request_world_action("talk", {"npc_id": npc_id})
		dialogue_overlay.open_line(StringName(npc_id), _npc_dialogue_line(npc_id, GameState.social.hearts(StringName(npc_id))))
		return
	var hearts := GameState.talk_to(StringName(npc_id))
	if npc_id == "mira":
		var chapter := GameState.next_story_chapter()
		var chapter_flag := "story_dialogue_seen_%s" % chapter.get("id", "")
		if not chapter.is_empty() and not bool(GameState.get_flag(chapter_flag, false)):
			GameState.set_flag(chapter_flag, true)
			DialogueAdapter.start_dialogue("%s_dialogue" % chapter.get("id", ""))
			return
	var heart_event := _next_heart_event(npc_id)
	if not heart_event.is_empty():
		GameState.social.mark_event_seen(npc_id, String(heart_event.get("id", "")))
		dialogue_overlay.open_line(StringName(npc_id), _heart_milestone_line(npc_id, hearts), "羈絆事件・%s　%d♥" % [heart_event.get("title", "新的回憶"), hearts])
	else:
		dialogue_overlay.open_line(StringName(npc_id), _npc_dialogue_line(npc_id, hearts))


func _npc_dialogue_line(npc_id: String, hearts: int) -> String:
	var bank := ContentRegistry.get_artifact("npc_dialogues", npc_id)
	if bank.is_empty():
		return "今天也辛苦了。"
	var festival: Dictionary = GameState.festivals.festival_on(GameState.calendar.season_id(), GameState.calendar.day)
	if not festival.is_empty():
		var festival_lines: Array = bank.get("festival_lines", [])
		return String(festival_lines[mini(GameState.calendar.year, 3) - 1])
	var weather_lines: Dictionary = bank.get("weather_lines", {})
	if weather_lines.has(GameState.current_weather):
		return String(weather_lines[GameState.current_weather])
	if hearts >= 3 and GameState.calendar.day % 7 == 0:
		return _heart_milestone_line(npc_id, hearts)
	var season_lines: Array = Dictionary(bank.get("season_lines", {})).get(String(GameState.calendar.season_id()), [])
	if season_lines.is_empty():
		return "今天也辛苦了。"
	var stable_offset := npc_id.unicode_at(0) if not npc_id.is_empty() else 0
	return String(season_lines[posmod(GameState.calendar.absolute_day() + stable_offset, season_lines.size())])


func _heart_milestone_line(npc_id: String, hearts: int) -> String:
	var milestones: Array = ContentRegistry.get_artifact("npc_dialogues", npc_id).get("heart_milestones", [])
	var result := "能在村裡遇見你，真好。"
	for milestone: Dictionary in milestones:
		if int(milestone.get("hearts", 11)) <= hearts:
			result = String(milestone.get("line", result))
	return result


func _animate_world_sprites() -> void:
	var ticks := float(Time.get_ticks_msec()) / 1000.0
	for npc_id: String in npc_sprites:
		var sprite: Sprite2D = npc_sprites[npc_id]
		if not sprite.visible:
			continue
		var anchor := Vector2(NPC_POSITIONS[npc_id]) + Vector2(0, -12) if mode == "village" else MIRA_POSITION + Vector2(0, -12)
		var phase := float(npc_id.unicode_at(0) % 7)
		sprite.position = anchor + Vector2(0, sin(ticks * 2.2 + phase) * 1.2)


func _on_network_snapshot(players: Dictionary) -> void:
	var local_peer_id := multiplayer.get_unique_id() if NetworkManager.is_online() else -1
	var present: Dictionary = {}
	for key: Variant in players:
		var peer_id := int(key)
		if peer_id == local_peer_id:
			continue
		var state: Dictionary = players[key]
		present[peer_id] = true
		var remote: PixelRPGRemotePlayer = remote_players.get(peer_id)
		if not is_instance_valid(remote):
			var initial := Vector2(320, 205)
			var position_data: Array = state.get("position", [320.0, 205.0])
			if position_data.size() >= 2:
				initial = Vector2(float(position_data[0]), float(position_data[1]))
			remote = RemotePlayerScript.new() as PixelRPGRemotePlayer
			remote.configure(peer_id, String(state.get("name", "旅人")), initial)
			add_child(remote)
			remote_players[peer_id] = remote
		remote.apply_snapshot(state)
	for peer_id: int in remote_players.keys():
		if not present.has(peer_id):
			var stale: Node = remote_players[peer_id]
			if is_instance_valid(stale):
				stale.queue_free()
			remote_players.erase(peer_id)


func _on_network_action_result(_action: String, result: Dictionary) -> void:
	_show_toast(String(result.get("message", "共同世界操作完成")))


func _on_network_status_changed(message: String) -> void:
	if not message.is_empty() and not NetworkManager.is_dedicated_server:
		_show_toast(message)


func _update_animal_sprites() -> void:
	var live_ids: Dictionary = {}
	var atlas: Texture2D = load("res://assets/runtime/sprites/animal_atlas_alpha.png")
	if atlas == null:
		return
	for index in range(GameState.farm.animals.size()):
		var animal: Dictionary = GameState.farm.animals[index]
		var animal_id := String(animal.get("id", "animal_%d" % index))
		live_ids[animal_id] = true
		var sprite: Sprite2D = animal_sprites.get(animal_id)
		if not is_instance_valid(sprite):
			var atlas_index := 1 if String(animal.get("species", "")) == "chicken" else 3
			var region := AtlasTexture.new()
			region.atlas = atlas
			var frame_width := floori(atlas.get_width() / 4.0)
			var frame_height := floori(atlas.get_height() / 2.0)
			region.region = Rect2((atlas_index % 4) * frame_width, (atlas_index / 4) * frame_height, frame_width, frame_height)
			sprite = Sprite2D.new()
			sprite.texture = region
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.scale = Vector2(0.105, 0.105) if String(animal.get("species", "")) == "chicken" else Vector2(0.13, 0.13)
			sprite.z_index = 3
			add_child(sprite)
			animal_sprites[animal_id] = sprite
		var animal_position := Vector2(490 + (index % 4) * 31, 154 + (index / 4) * 33)
		var bob := sin(float(Time.get_ticks_msec()) * 0.0025 + index) * 1.0
		sprite.position = animal_position + Vector2(0, -9 + bob)
		sprite.visible = mode == "farm"
	for animal_id: String in animal_sprites.keys():
		if live_ids.has(animal_id):
			continue
		var stale: Sprite2D = animal_sprites[animal_id]
		if is_instance_valid(stale):
			stale.queue_free()
		animal_sprites.erase(animal_id)


func _next_heart_event(npc_id: String) -> Dictionary:
	var relationship: Dictionary = GameState.social.ensure_npc(npc_id)
	for event: Dictionary in ContentRegistry.get_all("relationship_events"):
		if String(event.get("npc_id", "")) != npc_id or String(event.get("id", "")) in relationship.get("events_seen", []):
			continue
		if int(event.get("hearts", 11)) > GameState.social.hearts(npc_id):
			continue
		if String(event.get("season", "any")) not in ["any", String(GameState.calendar.season_id())]:
			continue
		if String(event.get("weather", "any")) not in ["any", GameState.current_weather]:
			continue
		return event
	return {}


func _enter_village() -> void:
	mode = "village"
	_set_background_for_mode()
	GameState.current_map_id = &"mistfall_village"
	player.global_position = Vector2(58, 278)
	_show_toast("來到霧落村。村民與商店都在這裡。")
	queue_redraw()


func _enter_farm_from_village() -> void:
	mode = "farm"
	_set_background_for_mode()
	GameState.current_map_id = &"mistfall_farm"
	player.global_position = Vector2(58, 278)
	_show_toast("返回霧落農場")
	queue_redraw()


func _interact_animal(animal_id: String) -> void:
	var product: Dictionary = GameState.farm.collect_animal_product(animal_id)
	if bool(product.get("ok", false)):
		_show_toast(String(product.message))
	else:
		var tending: Dictionary = GameState.tend_animal(animal_id)
		_show_toast(String(tending.get("message", "")))
	EventBus.farm_changed.emit(&"animal_tended", {"animal_id": animal_id})


func _nearest_plot() -> Vector2i:
	var nearest := Vector2i(-1, -1)
	var best_distance := 46.0
	for y in range(PLOT_ROWS):
		for x in range(PLOT_COLUMNS):
			var tile := Vector2i(x, y)
			var distance := player.global_position.distance_to(_plot_world_position(tile))
			if distance < best_distance:
				best_distance = distance
				nearest = tile
	return nearest


func _plot_world_position(tile: Vector2i) -> Vector2:
	return PLOT_ORIGIN + Vector2(tile.x * PLOT_SPACING.x, tile.y * PLOT_SPACING.y)


func _refresh_seasonal_seeds() -> void:
	seasonal_seed_ids.clear()
	for crop: Dictionary in ContentRegistry.get_all("crops"):
		if String(GameState.calendar.season_id()) in crop.get("seasons", []) and int(GameState.farm.seed_stock.get(String(crop.get("id", "")), 0)) > 0:
			seasonal_seed_ids.append(StringName(crop.get("id", "")))
	seasonal_seed_ids.sort()
	selected_seed_index = clampi(selected_seed_index, 0, maxi(0, seasonal_seed_ids.size() - 1))


func _selected_seed_id() -> StringName:
	return &"" if seasonal_seed_ids.is_empty() else seasonal_seed_ids[selected_seed_index]


func _cycle_seed() -> void:
	if seasonal_seed_ids.is_empty():
		_show_toast("本季沒有可用種子")
		return
	selected_seed_index = (selected_seed_index + 1) % seasonal_seed_ids.size()
	var crop := ContentRegistry.get_artifact("crops", _selected_seed_id())
	_show_toast("選擇種子：%s" % crop.get("display_name", _selected_seed_id()))


func _enter_dungeon(reset_position: bool = true) -> void:
	mode = "dungeon"
	_set_background_for_mode()
	GameState.current_map_id = &"mistfall_depths"
	if GameState.dungeon.current_floor <= 0:
		GameState.dungeon.enter_floor(1)
	if reset_position:
		player.global_position = Vector2(84, 285)
	_clear_enemies()
	_spawn_dungeon_floor()
	_show_toast("進入四季鐘窟 %dF" % GameState.dungeon.current_floor)
	queue_redraw()


func _leave_dungeon() -> void:
	_clear_enemies()
	final_challenge_active = false
	mode = "farm"
	_set_background_for_mode()
	GameState.current_map_id = &"mistfall_farm"
	GameState.dungeon.current_floor = 0
	player.global_position = CAVE_POSITION + Vector2(-45, 0)
	_refresh_seasonal_seeds()
	_show_toast("返回霧落農場")
	queue_redraw()


func _begin_eldritch_challenge(reset_position: bool = true) -> void:
	mode = "abyss"
	GameState.current_map_id = &"dreaming_shore"
	_clear_enemies()
	_set_background_for_mode()
	if reset_position:
		player.global_position = Vector2(84, 285)
	var definition := ContentRegistry.get_artifact("enemies", &"drowned_dreamer")
	var enemy := EnemySceneScript.new() as PixelRPGEnemy
	enemy.configure(definition)
	enemy.global_position = Vector2(430, 178)
	add_child(enemy)
	enemies_remaining = 1
	floor_cleared = false
	final_challenge_active = false
	eldritch_challenge_active = true
	title_label.position = Vector2(76, 126)
	title_label.size = Vector2(330, 85)
	title_label.text = "無星異潮翻過池岸\n克蘇魯之影・溺夢古神"
	_show_toast("守住名字與理智，讓深海的夢退潮。這場挑戰沒有日期期限。")
	queue_redraw()


func _leave_eldritch_shore() -> void:
	_clear_enemies()
	eldritch_challenge_active = false
	mode = "farm"
	GameState.current_map_id = &"mistfall_farm"
	_set_background_for_mode()
	title_label.position = Vector2(135, 125)
	title_label.size = Vector2(370, 85)
	player.global_position = Vector2(82, 288)
	_refresh_seasonal_seeds()
	_show_toast("你循著鐘聲返回霧落農場")
	queue_redraw()


func _spawn_dungeon_floor() -> void:
	floor_cleared = false
	final_challenge_active = false
	title_label.text = ""
	var floor_number: int = GameState.dungeon.current_floor
	var dungeon_definition := ContentRegistry.get_artifact("dungeons", &"mistfall_depths")
	var all_common: Array = dungeon_definition.get("enemy_ids", [])
	var boss_ids: Array = dungeon_definition.get("boss_ids", [])
	var zone_index := clampi((floor_number - 1) / 10, 0, 3)
	var enemy_ids: Array[StringName] = []
	var zone_start := zone_index * 3
	if floor_number % 10 == 0:
		enemy_ids.append(StringName(boss_ids[zone_index]))
		enemy_ids.append(StringName(all_common[zone_start]))
		enemy_ids.append(StringName(all_common[zone_start + 1]))
	else:
		var count := clampi(2 + floor_number / 8, 2, 5)
		for index in range(count):
			enemy_ids.append(StringName(all_common[zone_start + posmod(floor_number + index, 3)]))
	var positions := [Vector2(210, 125), Vector2(455, 120), Vector2(380, 270), Vector2(535, 250), Vector2(290, 255)]
	enemies_remaining = 0
	for index in range(enemy_ids.size()):
		var definition := ContentRegistry.get_artifact("enemies", enemy_ids[index])
		if definition.is_empty():
			continue
		var enemy := EnemySceneScript.new() as PixelRPGEnemy
		enemy.configure(definition)
		enemy.global_position = positions[index]
		add_child(enemy)
		enemies_remaining += 1
	EventBus.dungeon_floor_changed.emit(floor_number)


func _descend_dungeon() -> void:
	var current: int = GameState.dungeon.current_floor
	if current >= PixelRPGDungeonSystem.MAX_FLOOR:
		if GameState.dungeon.can_challenge_final_boss() and not GameState.dungeon.final_boss_defeated:
			_begin_final_challenge()
			return
		elif not GameState.dungeon.endless_unlocked:
			_show_toast("已抵達鐘窟最深處")
			return
	if not GameState.dungeon.enter_floor(current + 1):
		_show_toast("下一層尚未開放")
		return
	player.global_position = Vector2(84, 285)
	_spawn_dungeon_floor()


func _begin_final_challenge() -> void:
	_clear_enemies()
	title_label.position = Vector2(135, 125)
	title_label.size = Vector2(370, 85)
	var definition: Dictionary = ContentRegistry.get_artifact("enemies", &"winter_bell_warden").duplicate(true)
	definition["display_name"] = "霧鐘核心・終曲"
	definition["max_health"] = int(definition.get("max_health", 960)) * 2
	definition["damage"] = int(definition.get("damage", 32)) + 8
	definition["attack_cooldown"] = 0.48
	definition["projectile_speed"] = 220
	var enemy := EnemySceneScript.new() as PixelRPGEnemy
	enemy.configure(definition)
	enemy.global_position = Vector2(430, 178)
	add_child(enemy)
	enemies_remaining = 1
	floor_cleared = false
	final_challenge_active = true
	title_label.text = "四枚封印共鳴\n最終戰・霧鐘核心"
	_show_toast("真正的鐘核甦醒了。沒有日期期限，準備好再挑戰。")


func _clear_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	for projectile in get_tree().get_nodes_in_group("enemy_projectiles"):
		projectile.queue_free()
	enemies_remaining = 0


func _on_actor_damaged(actor: Node, amount: int, _remaining: int) -> void:
	if actor == player:
		_show_toast("受到 %d 點傷害" % amount)


func _on_enemy_defeated(enemy_id: StringName, _position: Vector2) -> void:
	GameState.record_enemy_defeat(enemy_id)
	enemies_remaining = maxi(0, enemies_remaining - 1)
	if enemies_remaining > 0:
		return
	if eldritch_challenge_active and enemy_id == &"drowned_dreamer":
		eldritch_challenge_active = false
		floor_cleared = true
		var result := GameState.defeat_eldritch_boss()
		title_label.text = "無星異潮退去\n深潮夢核回應了鐘聲"
		_show_toast(String(result.get("message", "克蘇魯之影沉回深海")))
		queue_redraw()
		return
	if final_challenge_active:
		final_challenge_active = false
		floor_cleared = true
		GameState.dungeon.defeat_final_boss()
		GameState.story_state["final_boss_available"] = false
		GameState.story_state["final_boss_defeated"] = true
		title_label.text = "鐘塔核心復甦！\n無限挑戰模式已開放"
		_show_toast("最終戰完成；主線結束後，農場與年份仍會繼續。")
		queue_redraw()
		return
	floor_cleared = true
	var result: Dictionary = GameState.dungeon.clear_current_floor()
	var seal := String(result.get("seal", ""))
	if not seal.is_empty():
		GameState.story_state["season_seals"] = GameState.dungeon.seals.duplicate()
		GameState.story_state["final_boss_available"] = GameState.dungeon.can_challenge_final_boss()
		if GameState.dungeon.can_challenge_final_boss():
			title_label.text = "四枚封印集齊\n前往傳送門挑戰霧鐘核心"
		else:
			title_label.text = "本層 Boss 擊破\n取得%s" % _seal_name(seal)
	else:
		title_label.text = "%dF 探索完成\n按 E 前往下一層" % GameState.dungeon.current_floor
	queue_redraw()


func _on_player_defeated() -> void:
	var result := GameState.resolve_player_defeat()
	title_label.text = "你在診所醒來\n%s" % result.get("message", "")
	await get_tree().create_timer(1.6).timeout
	get_tree().reload_current_scene()


func _on_hit_stop_requested(duration_seconds: float) -> void:
	if hit_stop_active:
		return
	hit_stop_active = true
	Engine.time_scale = 0.08
	await get_tree().create_timer(duration_seconds, true, false, true).timeout
	Engine.time_scale = 1.0
	hit_stop_active = false


func _on_day_started(_year: int, _season_id: StringName, _day: int, _weather: String) -> void:
	_refresh_seasonal_seeds()
	player.restore_from_game_state()
	_show_toast("新的一天：%s" % GameState.calendar.date_text())
	queue_redraw()


func _on_festival_available(festival: Dictionary) -> void:
	_show_toast("今天是%s，按 F 參加" % festival.get("display_name", "節慶"))


func _show_toast(message: String) -> void:
	if not is_instance_valid(toast_label) or message.is_empty():
		return
	if is_instance_valid(toast_tween):
		toast_tween.kill()
	toast_label.text = message
	toast_label.modulate = Color.WHITE
	toast_tween = create_tween()
	toast_tween.tween_interval(1.4)
	toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.45)


func _weather_name(weather: String) -> String:
	return {"clear":"晴朗","rain":"下雨","storm":"雷雨","fog":"濃霧","typhoon":"颱風","snow":"降雪","blizzard":"暴雪"}.get(weather, weather)


func _seal_name(seal_id: String) -> String:
	return {"spring_seal":"春之封印","summer_seal":"夏之封印","autumn_seal":"秋之封印","winter_seal":"冬之封印"}.get(seal_id, seal_id)


func _mira_is_on_farm() -> bool:
	var location: Dictionary = GameState.npc_schedules.location_for(&"mira", GameState.calendar.minute_of_day, GameState.current_weather)
	return location.get("map", "") == "mistfall_farm"
