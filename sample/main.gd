extends Node2D

const PlayerSceneScript := preload("res://runtime/actors/player.gd")
const EnemySceneScript := preload("res://runtime/actors/enemy.gd")
const GameMenuScript := preload("res://runtime/ui/game_menu.gd")
const ShopMenuScript := preload("res://runtime/ui/shop_menu.gd")
const DialogueOverlayScript := preload("res://runtime/ui/dialogue_overlay.gd")
const FestivalOverlayScript := preload("res://runtime/ui/festival_overlay.gd")
const MultiplayerMenuScript := preload("res://runtime/ui/multiplayer_menu.gd")
const AutomationConsoleScript := preload("res://runtime/ui/automation_console.gd")
const ItemIconFactory := preload("res://runtime/ui/item_icon_factory.gd")
const RemotePlayerScript := preload("res://runtime/network/remote_player.gd")

const PLOT_ORIGIN := Vector2(221, 159)
const PLOT_SPACING := Vector2(36, 26)
const PLOT_COLUMNS := 6
const PLOT_ROWS := 4
const MIRA_POSITION := Vector2(102, 166)
const CHICKEN_POSITION := Vector2(500, 155)
const COW_POSITION := Vector2(532, 188)
const CAVE_POSITION := Vector2(514, 254)
const SHIPPING_POSITION := Vector2(268, 278)
const POND_FISH_POSITION := Vector2(174, 262)
const DUNGEON_EXIT_POSITION := Vector2(320, 116)
const DUNGEON_ENTRY_SPAWN := Vector2(320, 142)
const DUNGEON_DESCENT_POSITION := Vector2(438, 286)
const FARM_DESTINATIONS := {
	"mistfall_village": {"position": Vector2(54, 138), "label": "霧落村"},
	"mistfall_river": {"position": Vector2(320, 82), "label": "鳴鐘河畔"},
	"bellwood_grove": {"position": Vector2(310, 320), "label": "古鐘林"},
	"clockwork_ruins": {"position": Vector2(580, 138), "label": "古代都市"},
	"mistfall_depths": {"position": CAVE_POSITION, "label": "四季鐘窟"},
}
const REGION_CONNECTIONS := {
	"farm": FARM_DESTINATIONS,
	"village": {
		"mistfall_farm": {"position": Vector2(318, 320), "label": "霧落農場"},
		"mistfall_river": {"position": Vector2(232, 72), "label": "鳴鐘河畔"},
		"bellwood_grove": {"position": Vector2(592, 172), "label": "古鐘林"},
		"clockwork_ruins": {"position": Vector2(606, 300), "label": "古代都市"},
	},
	"river": {
		"mistfall_farm": {"position": Vector2(92, 304), "label": "霧落農場"},
		"mistfall_village": {"position": Vector2(145, 185), "label": "霧落村"},
		"bellwood_grove": {"position": Vector2(545, 72), "label": "古鐘林"},
		"clockwork_ruins": {"position": Vector2(548, 304), "label": "古代都市"},
	},
	"grove": {
		"mistfall_farm": {"position": Vector2(184, 320), "label": "霧落農場"},
		"mistfall_village": {"position": Vector2(122, 72), "label": "霧落村"},
		"mistfall_river": {"position": Vector2(394, 320), "label": "鳴鐘河畔"},
		"clockwork_ruins": {"position": Vector2(574, 156), "label": "古代都市"},
	},
	"ruins": {
		"mistfall_farm": {"position": Vector2(36, 176), "label": "霧落農場"},
		"mistfall_village": {"position": Vector2(320, 64), "label": "霧落村"},
		"mistfall_river": {"position": Vector2(604, 176), "label": "鳴鐘河畔"},
		"bellwood_grove": {"position": Vector2(604, 232), "label": "古鐘林"},
		"mistfall_depths": {"position": Vector2(320, 318), "label": "四季鐘窟"},
	},
	"dungeon": {
		"mistfall_farm": {"position": DUNGEON_EXIT_POSITION, "label": "霧落農場"},
		"clockwork_ruins": {"position": Vector2(204, 304), "label": "古代都市"},
	},
	"abyss": {
		"mistfall_farm": {"position": DUNGEON_EXIT_POSITION, "label": "撤退農場"},
	},
}
const SHOP_POSITIONS := {
	"mira_seed_shop": Vector2(128, 170),
	"soren_forge": Vector2(270, 145),
	"toma_general_store": Vector2(590, 170),
	"orin_ranch": Vector2(270, 300),
}
const SHOP_SIGN_STYLES := {
	# Symbols are used only inside the fixed CanvasLayer prompt, never drawn or
	# rotated in world space.
	"mira_seed_shop":{"symbol":"苗", "color":Color("79c98a")},
	"soren_forge":{"symbol":"鍛", "color":Color("e19b58")},
	"toma_general_store":{"symbol":"雜", "color":Color("78b8cf")},
	"orin_ranch":{"symbol":"牧", "color":Color("d8b66a")},
}
const FARM_RESOURCES := {
	"tree_west": {"position": Vector2(80, 98), "kind": "tree"},
	"tree_north": {"position": Vector2(610, 92), "kind": "tree"},
	"stone_south": {"position": Vector2(105, 318), "kind": "stone"},
}
const DUNGEON_ORE_POSITION := Vector2(230, 145)
const VILLAGE_GATE_POSITION := Vector2(318, 320)
const AUTOMATION_CONSOLE_POSITION := Vector2(360, 294)
const OUTDOOR_EXIT_POSITION := Vector2(92, 304)
const RIVER_FISH_POSITION := Vector2(468, 208)
const RIVER_RESOURCE_POSITION := Vector2(494, 258)
const GROVE_RESOURCE_POSITION := Vector2(254, 224)
const RUINS_RESOURCE_POSITION := Vector2(505, 238)
const NPC_POSITIONS := {
	"mira": Vector2(220, 200), "lian": Vector2(275, 240), "soren": Vector2(280, 155), "yuna": Vector2(380, 235),
	"orin": Vector2(425, 180), "eira": Vector2(590, 240), "toma": Vector2(585, 190), "nori": Vector2(320, 260),
	"asha": Vector2(170, 200), "piko": Vector2(340, 285),
}
const RIVER_NPC_POSITIONS := {"lian": Vector2(420, 165), "nori": Vector2(245, 180)}
const GROVE_NPC_POSITIONS := {"asha": Vector2(475, 150), "piko": Vector2(350, 250)}
const RUINS_NPC_POSITIONS := {"soren": Vector2(245, 230), "toma": Vector2(410, 230)}
const NPC_SPRITE_SCALE := 0.145
const NPC_FOOT_OFFSETS := {
	"mira":18.6, "lian":19.4, "soren":19.6, "yuna":20.4, "orin":20.3,
	"eira":21.0, "toma":20.6, "nori":20.3, "asha":21.6, "piko":17.4,
}

var player: PixelRPGPlayer
var hud_label: Label
var toast_label: Label
var toast_panel: PanelContainer
var title_label: Label
var controls_label: Label
var title_overlay: CanvasLayer
var world_prompt_layer: CanvasLayer
var world_prompt_panel: PanelContainer
var world_prompt_key_panel: PanelContainer
var world_prompt_symbol_label: Label
var world_prompt_action_label: Label
var world_prompt_title_label: Label
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
var automation_console: PixelRPGAutomationConsole
var world_background: Sprite2D
var npc_sprites: Dictionary = {}
var animal_sprites: Dictionary = {}
var ui_refresh_timer := 0.0
var weather_refresh_timer := 0.0
var remote_players: Dictionary = {}
var world_collision_root: Node2D
var npc_collision_root: Node2D
var active_obstacle_rects: Array[Rect2] = []
var active_obstacle_polygons: Array[PackedVector2Array] = []
var world_foreground_root: Node2D
var seed_card: PanelContainer
var seed_icon: TextureRect
var seed_card_label: Label
var attack_card: PanelContainer
var potion_card: PanelContainer
var potion_label: Label


func _ready() -> void:
	if "--server" in OS.get_cmdline_user_args():
		hide()
		set_process(false)
		return
	_apply_launch_display_mode()
	seed(1337)
	PixelRPGInputBindings.load_saved()
	mode = _mode_for_map(GameState.current_map_id)
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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or _is_line_edit_focused():
		return
	if event.is_action_pressed("multiplayer_menu"):
		get_viewport().set_input_as_handled()
		_hide_world_prompt()
		multiplayer_menu.toggle()
		return
	if not is_instance_valid(title_overlay) and event.is_action_pressed("pause_menu"):
		get_viewport().set_input_as_handled()
		_hide_world_prompt()
		game_menu.toggle()


func _process(delta: float) -> void:
	var text_input_focused := _is_line_edit_focused()
	if is_instance_valid(title_overlay):
		_hide_world_prompt()
		if Input.is_action_just_pressed("ui_accept"):
			_close_title_screen()
		return
	_animate_world_sprites()
	_update_world_prompt_ui()
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
	if text_input_focused:
		return
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
		elif mode in ["river", "grove", "ruins"]:
			_travel_to_map(&"mistfall_farm")
		else:
			_show_toast("請先由村口返回農場")
	if Input.is_action_just_pressed("attend_festival") and mode == "farm":
		_hide_world_prompt()
		festival_overlay.open_today()
	if Input.is_action_just_pressed("use_potion") and is_instance_valid(player):
		if GameState.consume_item(&"health_potion"):
			player.heal(35)
			_show_toast("使用回復藥水")


func _is_line_edit_focused() -> bool:
	var focus_owner := get_viewport().gui_get_focus_owner()
	return is_instance_valid(focus_owner) and focus_owner is LineEdit


func _draw() -> void:
	_draw_visible_npc_shadows()
	if mode == "farm":
		_draw_farm()
	elif mode == "village":
		_draw_village()
	elif mode == "dungeon":
		_draw_dungeon()
	elif mode == "river":
		_draw_river()
	elif mode == "grove":
		_draw_grove()
	elif mode == "ruins":
		_draw_ruins()
	else:
		_draw_abyss()
	_draw_weather()


func _draw_farm() -> void:
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
				_draw_crop_visual(center, crop_id, crop, plot)
	# Automation network: adjacent machines are linked visibly on the same farm grid.
	for key: String in GameState.farm.automation_devices:
		var device: Dictionary = GameState.farm.automation_devices[key]
		var tile_data: Array = device.get("tile", [0, 0])
		var tile := Vector2i(int(tile_data[0]), int(tile_data[1]))
		var center := _plot_world_position(tile)
		for offset: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
			if GameState.farm.automation_devices.has("%d,%d" % [tile.x + offset.x, tile.y + offset.y]):
				draw_line(center, _plot_world_position(tile + offset), Color(0.94, 0.71, 0.29, 0.78), 3.0)
	for key: String in GameState.farm.automation_devices:
		var device: Dictionary = GameState.farm.automation_devices[key]
		var tile_data: Array = device.get("tile", [0, 0])
		var center := _plot_world_position(Vector2i(int(tile_data[0]), int(tile_data[1])))
		var definition := ContentRegistry.get_artifact("automation_devices", StringName(device.get("device_id", "")))
		var device_color := Color("e8b54b") if bool(device.get("enabled", true)) else Color("6f6b67")
		draw_circle(center + Vector2(8, -7), 7, Color("171a2b"))
		draw_circle(center + Vector2(8, -7), 6, device_color, false, 2.0)
		draw_string(ThemeDB.fallback_font, center + Vector2(4, -3), String(definition.get("symbol", "?")), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("fff1b6"))
	# NPC and animals.
	for index in range(GameState.farm.animals.size()):
		var _animal: Dictionary = GameState.farm.animals[index]
	for node_id: String in FARM_RESOURCES:
		if not bool(GameState.get_flag("gathered_%d_%s" % [GameState.calendar.absolute_day(), node_id], false)):
			var resource: Dictionary = FARM_RESOURCES[node_id]
			_draw_resource(Vector2(resource.position), String(resource.kind))
	_draw_region_connections()
	_draw_automation_console_marker()
	var tide_active: bool = GameState.eldritch.is_tide_active(GameState.calendar.day, GameState.calendar.minute_of_day, GameState.current_weather)
	_draw_fishing_spot(POND_FISH_POSITION, tide_active)


func _draw_dungeon() -> void:
	var floor_number := maxi(1, GameState.dungeon.current_floor)
	var zone_index := clampi((floor_number - 1) / 10, 0, 3)
	draw_rect(Rect2(18, 52, 604, 286), [Color("6bbf83"), Color("df704e"), Color("d6a348"), Color("89cfe2")][zone_index], false, 2.0)
	_draw_region_connections()
	if floor_cleared:
		_draw_travel_marker(DUNGEON_DESCENT_POSITION, "前往下一層", "next_floor")
	else:
		_draw_locked_gateway(DUNGEON_DESCENT_POSITION)
	var ore_id := "ore_%d" % floor_number
	if not bool(GameState.get_flag("gathered_%d_%s" % [GameState.calendar.absolute_day(), ore_id], false)):
		_draw_resource(DUNGEON_ORE_POSITION, "ore")


func _draw_abyss() -> void:
	draw_rect(Rect2(18, 52, 604, 286), Color("34265e"), false, 3.0)
	for ring in range(5):
		draw_arc(Vector2(320, 196), 44.0 + ring * 21.0, 0.0, TAU, 48, Color(0.29, 0.84, 0.78, 0.16), 2.0)
	_draw_region_connections()
	if floor_cleared:
		_draw_travel_marker(DUNGEON_DESCENT_POSITION, "返回農場", "mistfall_farm")


func _draw_village() -> void:
	# Shops are represented by their authored buildings and resident NPCs. Their
	# names appear in the single bottom prompt when approached; no floating glyph
	# signs are composited over the village artwork.
	_draw_region_connections()


func _draw_river() -> void:
	_draw_fishing_spot(RIVER_FISH_POSITION, false)
	_draw_world_pickup(RIVER_RESOURCE_POSITION, &"river_reed", Color("c5bd6d"))
	_draw_region_connections()


func _draw_grove() -> void:
	_draw_world_pickup(GROVE_RESOURCE_POSITION, &"forest_herb", Color("75c98a"))
	_draw_region_connections()


func _draw_ruins() -> void:
	_draw_world_pickup(RUINS_RESOURCE_POSITION, &"ancient_gear", Color("d39c55"))
	_draw_region_connections()


func _context_prompt_rect() -> Rect2:
	return Rect2(140, 298, 360, 32)


func village_label_rects_for_position(test_position: Vector2) -> Array[Rect2]:
	# World-space destination names were deliberately removed. At most one
	# screen-space prompt can exist, so villagers can never cover or split it.
	for connection: Dictionary in REGION_CONNECTIONS.village.values():
		if test_position.distance_to(Vector2(connection.position)) < 44.0:
			return [_context_prompt_rect()]
	for shop_position: Vector2 in SHOP_POSITIONS.values():
		if test_position.distance_to(shop_position) <= 38.0:
			return [_context_prompt_rect()]
	for npc_position: Vector2 in NPC_POSITIONS.values():
		if test_position.distance_to(npc_position) <= 34.0:
			return [_context_prompt_rect()]
	return []


func rects_do_not_overlap(rects: Array[Rect2]) -> bool:
	for left_index in range(rects.size()):
		for right_index in range(left_index + 1, rects.size()):
			if rects[left_index].intersects(rects[right_index]):
				return false
	return true


func _draw_visible_npc_shadows() -> void:
	var ground_positions: Dictionary = {}
	if mode == "village":
		ground_positions = NPC_POSITIONS
	elif mode == "river":
		ground_positions = RIVER_NPC_POSITIONS
	elif mode == "grove":
		ground_positions = GROVE_NPC_POSITIONS
	elif mode == "ruins":
		ground_positions = RUINS_NPC_POSITIONS
	elif mode == "farm" and _mira_is_on_farm():
		ground_positions = {"mira":MIRA_POSITION}
	for npc_id: String in ground_positions:
		var ground := Vector2(ground_positions[npc_id])
		draw_set_transform(ground + Vector2(0, 1.5), 0.0, Vector2(1.0, 0.34))
		draw_circle(Vector2.ZERO, 10.0, Color(0.02, 0.03, 0.04, 0.42))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_chicken(position: Vector2) -> void:
	draw_circle(position, 9, Color("f4ead3"))
	draw_circle(position + Vector2(7, -7), 5, Color("fff7e8"))
	draw_polygon(PackedVector2Array([position + Vector2(12, -7), position + Vector2(18, -4), position + Vector2(12, -2)]), PackedColorArray([Color("e6b64f")]))


func _draw_cow(position: Vector2) -> void:
	draw_rect(Rect2(position - Vector2(14, 9), Vector2(28, 18)), Color("eee6d8"))
	draw_rect(Rect2(position - Vector2(8, 8), Vector2(9, 8)), Color("514346"))
	draw_circle(position + Vector2(15, -4), 8, Color("eee6d8"))


func _draw_resource(position: Vector2, kind: String) -> void:
	var item_id := &"wood" if kind == "tree" else (&"stone" if kind == "stone" else _dungeon_ore_item_id())
	var accent := Color("9b6848") if kind == "tree" else (Color("8a9299") if kind == "stone" else Color("c97950"))
	_draw_world_pickup(position, item_id, accent)


func _dungeon_ore_item_id() -> StringName:
	var floor_number := maxi(1, GameState.dungeon.current_floor)
	if floor_number >= 31:
		return &"gold_ore"
	if floor_number >= 11:
		return &"iron_ore"
	return &"copper_ore"


func _draw_world_pickup(position: Vector2, item_id: StringName, accent: Color) -> void:
	var geometry := world_pickup_geometry(position)
	# Gatherables are small objects sitting directly on the terrain. The previous
	# 42px icon, target brackets and sparks read as debug geometry at world scale.
	draw_set_transform(position + Vector2(0, 3), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 8.0, Color(0.02, 0.03, 0.04, 0.4))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_polygon(PackedVector2Array([position + Vector2(-8, 1), position + Vector2(8, 1), position + Vector2(6, 5), position + Vector2(-6, 5)]), PackedColorArray([accent.darkened(0.45)]))
	var texture := ItemIconFactory.texture_for(item_id, &"world_item", 20)
	if texture != null:
		draw_texture_rect(texture, Rect2(geometry.icon_rect), false)


func world_pickup_geometry(position: Vector2) -> Dictionary:
	return {
		"icon_rect":Rect2(position - Vector2(10, 19), Vector2(20, 20)),
		"support_rect":Rect2(position - Vector2(8, -1), Vector2(16, 4)),
		"sparks":[],
		"uses_placeholder_ring":false,
		"uses_target_brackets":false,
		"world_scale":20,
	}


func _draw_fishing_spot(position: Vector2, eldritch: bool) -> void:
	var accent := Color("a998dd") if eldritch else Color("64c9dc")
	var motion := sin(float(Time.get_ticks_msec()) * 0.004) * 0.6
	# The painted pier already communicates the activity. A restrained float and
	# two water ripples are enough to identify the exact interaction point.
	draw_line(position + Vector2(-8, -8), position + Vector2(0, -2 + motion), Color("dce5ee"), 0.8)
	draw_rect(Rect2(position + Vector2(-1.5, -4 + motion), Vector2(3, 6)), Color("f0d37a"), true)
	draw_rect(Rect2(position + Vector2(-1.5, -4 + motion), Vector2(3, 2)), Color("d75f5f"), true)
	for radius in [5.0, 10.0]:
		draw_arc(position + Vector2(0, 2), radius, 0.18, PI * 0.82, 10, accent, 1.0)
		draw_arc(position + Vector2(0, 2), radius, PI * 1.18, PI * 1.82, 10, accent, 1.0)
	if eldritch:
		draw_circle(position + Vector2(0, 2), 1.2, accent.lightened(0.25))


func _draw_locked_gateway(position: Vector2) -> void:
	# The authored doorway remains visible. A small chain and padlock communicate
	# its state without placing a large hexagon/X badge over the floor.
	draw_set_transform(position + Vector2(0, 3), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 8.0, Color(0.02, 0.03, 0.04, 0.42))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_line(position + Vector2(-10, -3), position + Vector2(10, 3), Color("777b82"), 1.8)
	draw_line(position + Vector2(-10, 3), position + Vector2(10, -3), Color("777b82"), 1.8)
	draw_rect(Rect2(position + Vector2(-4, -2), Vector2(8, 8)), Color("252a32"), true)
	draw_rect(Rect2(position + Vector2(-4, -2), Vector2(8, 8)), Color("b9a263"), false, 1.2)
	draw_arc(position + Vector2(0, -2), 3.0, PI, TAU, 10, Color("b9a263"), 1.5)


func _draw_crop_visual(center: Vector2, crop_id: String, crop: Dictionary, plot: Dictionary) -> void:
	var crop_color := Color(String(crop.get("color", "78dcca")))
	var withered := bool(plot.get("withered", false))
	if withered:
		crop_color = Color("625747")
	var progress := clampf(float(plot.get("growth_progress", 0)) / maxf(1.0, float(crop.get("growth_days", 1))), 0.0, 1.0)
	var height := lerpf(5.0, 13.0, progress)
	var stem_color := Color("75634b") if withered else Color("356f47")
	draw_line(center + Vector2(0, 7), center - Vector2(0, height), stem_color, 2.5)
	var leaf_size := lerpf(2.5, 5.0, progress)
	draw_polygon(PackedVector2Array([center + Vector2(-1, 1), center + Vector2(-leaf_size - 2, -leaf_size), center + Vector2(-2, -leaf_size - 1)]), PackedColorArray([stem_color]))
	draw_polygon(PackedVector2Array([center + Vector2(1, -2), center + Vector2(leaf_size + 2, -leaf_size - 3), center + Vector2(2, -leaf_size - 4)]), PackedColorArray([stem_color.lightened(0.12)]))
	if progress >= 0.45:
		var is_flower := _crop_id_has_any(crop_id, ["tulip", "bloom", "sunflower", "chrysanthemum", "rose", "bellflower"])
		var is_root := _crop_id_has_any(crop_id, ["turnip", "radish", "potato", "carrot", "garlic", "beet", "onion", "yam", "parsnip"])
		var is_grain := _crop_id_has_any(crop_id, ["wheat", "rice", "corn", "sugarcane"])
		var is_cluster := _crop_id_has_any(crop_id, ["peas", "bean", "grape", "berry", "coffee", "tomato", "pepper"])
		if is_flower:
			var blossom := center - Vector2(0, height)
			for offset: Vector2 in [Vector2(-4, 0), Vector2(4, 0), Vector2(0, -4), Vector2(0, 4)]:
				draw_circle(blossom + offset * 0.55, 3.2, crop_color)
			draw_circle(blossom, 2.4, Color("f4c95d") if not withered else crop_color)
		elif is_root:
			draw_circle(center + Vector2(0, 3), lerpf(3.0, 6.2, progress), crop_color)
			draw_line(center + Vector2(-3, 1), center + Vector2(-6, -5), stem_color, 2.0)
			draw_line(center + Vector2(3, 1), center + Vector2(6, -5), stem_color, 2.0)
		elif is_grain:
			for x_offset in [-5.0, 0.0, 5.0]:
				draw_line(center + Vector2(x_offset, 7), center + Vector2(x_offset, -height), stem_color, 1.8)
				draw_circle(center + Vector2(x_offset, -height), 2.6, crop_color)
		elif is_cluster:
			for offset: Vector2 in [Vector2(-4, -height + 2), Vector2(3, -height), Vector2(0, -height + 5)]:
				draw_circle(center + offset, 3.0, crop_color)
		else:
			draw_circle(center - Vector2(0, height), lerpf(3.5, 6.5, progress), crop_color)


func _crop_id_has_any(crop_id: String, tokens: Array[String]) -> bool:
	for token: String in tokens:
		if crop_id.contains(token):
			return true
	return false


func _draw_travel_marker(position: Vector2, label: String, destination_id: String = "") -> void:
	var geometry := _gateway_geometry(position, label, destination_id)
	var accent := Color(geometry.accent)
	var nearby := is_instance_valid(player) and player.global_position.distance_to(position) <= 52.0
	var emphasis := 1.0 if nearby else 0.68
	# The background contains the actual door, gate or road. Two low lanterns mark
	# its interaction threshold without arrows, posts, glyphs or rotated text.
	for lantern_position: Vector2 in geometry.lanterns:
		draw_set_transform(lantern_position + Vector2(0, 2), 0.0, Vector2(1.0, 0.32))
		draw_circle(Vector2.ZERO, 4.0, Color(0.02, 0.03, 0.04, 0.4))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_rect(Rect2(lantern_position + Vector2(-2.5, -1), Vector2(5, 4)), Color("49413a"), true)
		draw_line(lantern_position + Vector2(0, -1), lantern_position + Vector2(0, -6), Color("6e6253"), 1.5)
		draw_circle(lantern_position + Vector2(0, -7), 3.2, Color(accent.r, accent.g, accent.b, 0.18 * emphasis))
		draw_circle(lantern_position + Vector2(0, -7), 1.45, Color(1.0, 0.91, 0.58, emphasis))


func _gateway_geometry(position: Vector2, _label: String, destination_id: String = "") -> Dictionary:
	var outward := _gateway_outward_direction(position)
	var perpendicular := outward.rotated(PI * 0.5)
	var style := _gateway_style(destination_id)
	return {
		"outward":outward,
		"accent":style.color,
		"has_world_text":false,
		"uses_rotated_text":false,
		"has_chevrons":false,
		"lanterns":[position + perpendicular * 11.0 - outward * 2.0, position - perpendicular * 11.0 - outward * 2.0],
		"overlay_extent":18.0,
	}


func _gateway_outward_direction(position: Vector2) -> Vector2:
	if position.y >= 290.0:
		return Vector2.DOWN
	if position.y <= 95.0:
		return Vector2.UP
	if position.x <= 70.0:
		return Vector2.LEFT
	if position.x >= 570.0:
		return Vector2.RIGHT
	var from_center := position - Vector2(320, 196)
	if absf(from_center.x) >= absf(from_center.y):
		return Vector2.RIGHT if from_center.x >= 0.0 else Vector2.LEFT
	return Vector2.DOWN if from_center.y >= 0.0 else Vector2.UP


func _gateway_style(destination_id: String) -> Dictionary:
	return {
		"mistfall_farm":{"symbol":"田", "color":Color("d8b66a")},
		"mistfall_village":{"symbol":"村", "color":Color("c98ab1")},
		"mistfall_river":{"symbol":"川", "color":Color("64c9dc")},
		"bellwood_grove":{"symbol":"林", "color":Color("75c98a")},
		"clockwork_ruins":{"symbol":"遺", "color":Color("d39c55")},
		"mistfall_depths":{"symbol":"窟", "color":Color("a998dd")},
		"next_floor":{"symbol":"層", "color":Color("e8b54b")},
	}.get(destination_id, {"symbol":"門", "color":Color("78dcca")})


func _draw_region_connections() -> void:
	var connections: Dictionary = Dictionary(REGION_CONNECTIONS.get(mode, {}))
	for map_id: String in connections:
		var connection: Dictionary = Dictionary(connections[map_id])
		_draw_travel_marker(Vector2(connection.position), String(connection.label), map_id)


func _draw_automation_console_marker() -> void:
	var position := AUTOMATION_CONSOLE_POSITION
	draw_set_transform(position + Vector2(0, 6), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 10.0, Color(0.02, 0.03, 0.04, 0.44))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# A waist-high brass farm terminal, scaled like the surrounding props.
	draw_polygon(PackedVector2Array([position + Vector2(-9, 6), position + Vector2(9, 6), position + Vector2(7, -11), position + Vector2(-7, -11)]), PackedColorArray([Color("3c3935")]))
	draw_rect(Rect2(position + Vector2(-5, -8), Vector2(10, 10)), Color("171a2b"), true)
	draw_rect(Rect2(position + Vector2(-5, -8), Vector2(10, 10)), Color("a98648"), false, 1.0)
	draw_circle(position + Vector2(0, -3), 2.5, Color("d2a94e"), false, 1.0)
	draw_circle(position + Vector2(0, -3), 0.9, Color("fff1b6"))
	draw_line(position + Vector2(6, -4), position + Vector2(10, -10), Color("8f7657"), 1.5)
	draw_circle(position + Vector2(10, -10), 1.8, Color("d2a94e"))


func _create_player() -> void:
	player = PlayerSceneScript.new() as PixelRPGPlayer
	player.name = "Player"
	player.global_position = GameState.player_position
	add_child(player)
	NetworkManager.set_local_player_node(player)
	_sanitize_player_position()


func _create_background() -> void:
	world_background = Sprite2D.new()
	world_background.z_index = -100
	world_background.position = Vector2(320, 180)
	world_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(world_background)
	world_foreground_root = Node2D.new()
	world_foreground_root.name = "WorldForeground"
	world_foreground_root.z_index = 1000
	add_child(world_foreground_root)
	_set_background_for_mode()


func _set_background_for_mode() -> void:
	if not is_instance_valid(world_background):
		return
	var path := "res://assets/runtime/backgrounds/mistfall_farm_commercial.png"
	if mode == "village":
		path = "res://assets/runtime/backgrounds/mistfall_village_commercial.png"
	elif mode == "river":
		path = "res://assets/runtime/backgrounds/mistfall_river_commercial.png"
	elif mode == "grove":
		path = "res://assets/runtime/backgrounds/bellwood_grove_commercial.png"
	elif mode == "ruins":
		path = "res://assets/runtime/backgrounds/clockwork_ruins_commercial.png"
	elif mode in ["dungeon", "abyss"]:
		path = "res://assets/runtime/backgrounds/mistfall_dungeon_commercial.png"
	world_background.texture = load(path)
	if world_background.texture != null:
		world_background.scale = Vector2(640.0 / world_background.texture.get_width(), 360.0 / world_background.texture.get_height())
	_rebuild_world_foreground()
	_update_npc_sprites()
	_update_environment_tint()
	if is_instance_valid(world_collision_root):
		_rebuild_world_collisions()


func _update_environment_tint() -> void:
	if not is_instance_valid(world_background):
		return
	var season_tints := [Color("f0fff1"), Color("fff4d8"), Color("ffd9b2"), Color("dceeff")]
	var tint: Color = season_tints[GameState.calendar.season_index]
	if mode == "abyss":
		world_background.modulate = Color("51427e")
		if is_instance_valid(world_foreground_root):
			world_foreground_root.modulate = Color("51427e")
		return
	var hour: float = float(GameState.calendar.minute_of_day) / 60.0
	if hour >= 20.0:
		tint = tint * Color(0.48, 0.55, 0.78)
	elif hour >= 18.0:
		var dusk := clampf((hour - 18.0) / 2.0, 0.0, 1.0)
		tint = tint.lerp(tint * Color(0.52, 0.59, 0.82), dusk)
	world_background.modulate = tint
	if is_instance_valid(world_foreground_root):
		world_foreground_root.modulate = tint


func _rebuild_world_foreground() -> void:
	if not is_instance_valid(world_foreground_root) or world_background.texture == null:
		return
	for child: Node in world_foreground_root.get_children():
		world_foreground_root.remove_child(child)
		child.queue_free()
	var scale_factor := world_background.scale
	for world_rect: Rect2 in _foreground_regions_for_mode(mode):
		var sprite := Sprite2D.new()
		sprite.texture = world_background.texture
		sprite.region_enabled = true
		sprite.region_rect = Rect2(world_rect.position / scale_factor, world_rect.size / scale_factor)
		sprite.position = world_rect.get_center()
		sprite.scale = scale_factor
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		world_foreground_root.add_child(sprite)


func _foreground_regions_for_mode(map_mode: String) -> Array[Rect2]:
	# These are the upper visual slices of tall landmarks. Re-drawing the exact
	# background pixels above actors creates Stone Age-style walk-behind depth
	# without changing the source palette or adding foreign-looking assets.
	var raw_regions: Array = {
		"farm":[Rect2(94, 54, 151, 55), Rect2(399, 54, 145, 55), Rect2(452, 181, 138, 49)],
		"village":[Rect2(67, 54, 151, 73), Rect2(251, 54, 123, 56), Rect2(440, 54, 139, 70), Rect2(438, 171, 127, 44), Rect2(127, 218, 126, 38), Rect2(371, 257, 221, 35)],
		"river":[Rect2(20, 79, 103, 61), Rect2(70, 54, 52, 49), Rect2(522, 54, 54, 50), Rect2(67, 271, 52, 50), Rect2(522, 273, 54, 49), Rect2(431, 164, 77, 31)],
		"grove":[Rect2(20, 54, 75, 105), Rect2(151, 54, 79, 69), Rect2(265, 54, 156, 63), Rect2(420, 54, 120, 72), Rect2(535, 54, 85, 107), Rect2(214, 268, 150, 70)],
		"ruins":[Rect2(25, 54, 182, 51), Rect2(419, 54, 84, 51), Rect2(530, 54, 90, 64), Rect2(73, 137, 110, 42), Rect2(257, 135, 150, 47), Rect2(443, 140, 125, 42)],
		"dungeon":[Rect2(20, 54, 202, 67), Rect2(281, 54, 79, 37), Rect2(394, 54, 226, 70), Rect2(536, 134, 84, 71)],
		"abyss":[Rect2(20, 54, 202, 67), Rect2(281, 54, 79, 37), Rect2(394, 54, 226, 70), Rect2(536, 134, 84, 71)],
	}.get(map_mode, [])
	var regions: Array[Rect2] = []
	for region: Variant in raw_regions:
		regions.append(Rect2(region))
	return regions


func foreground_layer_count(map_mode: String) -> int:
	return _foreground_regions_for_mode(map_mode).size()


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
	npc_collision_root = Node2D.new()
	npc_collision_root.name = "NPCNavigationCollisions"
	add_child(npc_collision_root)
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
		sprite.scale = Vector2(NPC_SPRITE_SCALE, NPC_SPRITE_SCALE)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
			sprite.position = _npc_sprite_anchor(npc_id, Vector2(NPC_POSITIONS[npc_id]))
			sprite.visible = true
		elif mode == "river" and RIVER_NPC_POSITIONS.has(npc_id):
			sprite.position = _npc_sprite_anchor(npc_id, Vector2(RIVER_NPC_POSITIONS[npc_id]))
			sprite.visible = true
		elif mode == "grove" and GROVE_NPC_POSITIONS.has(npc_id):
			sprite.position = _npc_sprite_anchor(npc_id, Vector2(GROVE_NPC_POSITIONS[npc_id]))
			sprite.visible = true
		elif mode == "ruins" and RUINS_NPC_POSITIONS.has(npc_id):
			sprite.position = _npc_sprite_anchor(npc_id, Vector2(RUINS_NPC_POSITIONS[npc_id]))
			sprite.visible = true
		elif mode == "farm" and npc_id == "mira" and _mira_is_on_farm():
			sprite.position = _npc_sprite_anchor(npc_id, MIRA_POSITION)
			sprite.visible = true
		if sprite.visible:
			var ground := _npc_ground_position(npc_id)
			sprite.z_index = 100 + clampi(roundi(ground.y), 0, 360)
	_rebuild_npc_collisions()


func _npc_ground_position(npc_id: String) -> Vector2:
	if mode == "village":
		return Vector2(NPC_POSITIONS[npc_id])
	if mode == "river" and RIVER_NPC_POSITIONS.has(npc_id):
		return Vector2(RIVER_NPC_POSITIONS[npc_id])
	if mode == "grove" and GROVE_NPC_POSITIONS.has(npc_id):
		return Vector2(GROVE_NPC_POSITIONS[npc_id])
	if mode == "ruins" and RUINS_NPC_POSITIONS.has(npc_id):
		return Vector2(RUINS_NPC_POSITIONS[npc_id])
	return MIRA_POSITION


func _rebuild_npc_collisions() -> void:
	if not is_instance_valid(npc_collision_root):
		return
	for child: Node in npc_collision_root.get_children():
		npc_collision_root.remove_child(child)
		child.queue_free()
	for npc_id: String in npc_sprites:
		var sprite: Sprite2D = npc_sprites[npc_id]
		if not sprite.visible:
			continue
		var body := StaticBody2D.new()
		body.name = "NPC_%s" % npc_id
		body.position = _npc_ground_position(npc_id)
		body.collision_layer = 1
		body.collision_mask = 0
		body.set_meta("npc_id", npc_id)
		var collision := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 9.0
		collision.shape = shape
		collision.position = Vector2(0, -1)
		body.add_child(collision)
		npc_collision_root.add_child(body)


func npc_collision_count() -> int:
	return npc_collision_root.get_child_count() if is_instance_valid(npc_collision_root) else 0


func _create_world_walls() -> void:
	world_collision_root = Node2D.new()
	world_collision_root.name = "WorldCollisions"
	add_child(world_collision_root)
	_rebuild_world_collisions()


func _rebuild_world_collisions() -> void:
	if not is_instance_valid(world_collision_root):
		return
	for child: Node in world_collision_root.get_children():
		world_collision_root.remove_child(child)
		child.queue_free()
	active_obstacle_rects.clear()
	active_obstacle_polygons.clear()
	_add_world_obstacle("BoundaryTop", Rect2(0, 38, 640, 16), false)
	_add_world_obstacle("BoundaryBottom", Rect2(0, 338, 640, 20), false)
	_add_world_obstacle("BoundaryLeft", Rect2(4, 38, 16, 320), false)
	_add_world_obstacle("BoundaryRight", Rect2(620, 38, 16, 320), false)
	for obstacle: Dictionary in _world_obstacle_layout(mode):
		if obstacle.has("rect"):
			_add_world_obstacle(String(obstacle.name), Rect2(obstacle.rect), true)
		else:
			_add_world_polygon(String(obstacle.name), PackedVector2Array(obstacle.polygon), true)
	if is_instance_valid(player):
		_sanitize_player_position()


func _world_obstacle_layout(map_mode: String) -> Array[Dictionary]:
	# Each map is traced against its production background. Rectangles describe
	# architectural footprints; polygons follow shorelines, cliffs and irregular
	# machinery. The open gaps coincide with the paths, bridges and gate mouths.
	match map_mode:
		"farm":
			return [
				{"name":"FarmHouse", "rect":Rect2(94, 54, 151, 76)},
				{"name":"FarmBarn", "rect":Rect2(399, 54, 145, 78)},
				{"name":"FarmPond", "polygon":PackedVector2Array([Vector2(70, 196), Vector2(151, 195), Vector2(181, 209), Vector2(191, 238), Vector2(184, 276), Vector2(151, 292), Vector2(91, 289), Vector2(67, 264), Vector2(64, 225)])},
				{"name":"FarmCaveCrown", "polygon":PackedVector2Array([Vector2(452, 192), Vector2(479, 177), Vector2(558, 180), Vector2(586, 199), Vector2(578, 228), Vector2(548, 224), Vector2(531, 210), Vector2(504, 211), Vector2(486, 228), Vector2(458, 229)])},
				{"name":"FarmCaveLeft", "rect":Rect2(450, 218, 45, 60)},
				{"name":"FarmCaveRight", "rect":Rect2(548, 217, 42, 61)},
				{"name":"FarmWestOrchard", "polygon":PackedVector2Array([Vector2(20, 54), Vector2(83, 54), Vector2(83, 104), Vector2(61, 122), Vector2(20, 122)])},
				{"name":"FarmEastOrchard", "polygon":PackedVector2Array([Vector2(558, 54), Vector2(620, 54), Vector2(620, 119), Vector2(592, 119), Vector2(566, 101)])},
			]
		"village":
			return [
				{"name":"VillageLibrary", "rect":Rect2(67, 54, 151, 101)},
				{"name":"VillageForge", "rect":Rect2(251, 54, 123, 78)},
				{"name":"VillageStore", "rect":Rect2(440, 54, 139, 103)},
				{"name":"VillageClinic", "rect":Rect2(438, 171, 127, 79)},
				{"name":"VillageHome", "rect":Rect2(127, 218, 126, 68)},
				{"name":"VillageBell", "polygon":PackedVector2Array([Vector2(297, 147), Vector2(346, 147), Vector2(365, 177), Vector2(348, 212), Vector2(294, 212), Vector2(276, 178)])},
				{"name":"VillageUpperRiver", "polygon":PackedVector2Array([Vector2(20, 187), Vector2(151, 187), Vector2(157, 216), Vector2(132, 246), Vector2(82, 256), Vector2(20, 245)])},
				{"name":"VillageLowerRiverWest", "polygon":PackedVector2Array([Vector2(20, 245), Vector2(127, 247), Vector2(130, 278), Vector2(112, 302), Vector2(20, 323)])},
				{"name":"VillageLowerRiverEast", "polygon":PackedVector2Array([Vector2(177, 281), Vector2(227, 286), Vector2(244, 317), Vector2(226, 338), Vector2(164, 338), Vector2(164, 308)])},
				{"name":"VillageHarborWater", "polygon":PackedVector2Array([Vector2(20, 287), Vector2(126, 286), Vector2(171, 297), Vector2(171, 338), Vector2(20, 338)])},
				# The shrine's stone path is visible and must remain reachable. Its
				# opening is centered around x=420, not in the old x=447 corridor.
				{"name":"VillageShrineWest", "polygon":PackedVector2Array([Vector2(371, 257), Vector2(399, 250), Vector2(403, 278), Vector2(401, 338), Vector2(370, 338)])},
				{"name":"VillageShrineEast", "polygon":PackedVector2Array([Vector2(443, 260), Vector2(570, 252), Vector2(592, 279), Vector2(592, 338), Vector2(443, 338)])},
			]
		"river":
			return [
				{"name":"RiverMill", "rect":Rect2(20, 79, 103, 92)},
				{"name":"RiverNorthWestCanopy", "rect":Rect2(20, 54, 108, 25)},
				{"name":"RiverUpperWestWater", "polygon":PackedVector2Array([Vector2(128, 54), Vector2(282, 54), Vector2(283, 111), Vector2(255, 119), Vector2(251, 151), Vector2(220, 174), Vector2(165, 177), Vector2(158, 151), Vector2(131, 134)])},
				{"name":"RiverUpperCenterWater", "polygon":PackedVector2Array([Vector2(283, 54), Vector2(382, 54), Vector2(382, 111), Vector2(360, 119), Vector2(313, 114), Vector2(283, 111)])},
				{"name":"RiverCenterChannelNorth", "polygon":PackedVector2Array([Vector2(315, 142), Vector2(395, 143), Vector2(391, 181), Vector2(373, 205), Vector2(379, 240), Vector2(408, 248), Vector2(408, 250), Vector2(317, 250), Vector2(306, 211)])},
				{"name":"RiverCenterChannelSouth", "polygon":PackedVector2Array([Vector2(330, 276), Vector2(408, 276), Vector2(408, 338), Vector2(332, 338)])},
				{"name":"RiverEastChannel", "polygon":PackedVector2Array([Vector2(470, 104), Vector2(535, 100), Vector2(537, 151), Vector2(519, 177), Vector2(526, 216), Vector2(535, 258), Vector2(517, 282), Vector2(480, 273), Vector2(458, 247), Vector2(456, 208), Vector2(470, 178)])},
				{"name":"RiverLowerWestWater", "polygon":PackedVector2Array([Vector2(20, 222), Vector2(76, 226), Vector2(78, 271), Vector2(64, 291), Vector2(61, 338), Vector2(20, 338)])},
				{"name":"RiverLowerBasin", "polygon":PackedVector2Array([Vector2(123, 252), Vector2(190, 247), Vector2(222, 270), Vector2(270, 279), Vector2(296, 313), Vector2(295, 338), Vector2(123, 338)])},
				{"name":"RiverSouthEastWater", "polygon":PackedVector2Array([Vector2(423, 286), Vector2(499, 278), Vector2(526, 299), Vector2(525, 338), Vector2(420, 338)])},
			]
		"grove":
			return [
				{"name":"GroveNorthWestForest", "polygon":PackedVector2Array([Vector2(20, 54), Vector2(91, 54), Vector2(100, 100), Vector2(80, 153), Vector2(20, 166)])},
				{"name":"GroveNorthForest", "polygon":PackedVector2Array([Vector2(148, 54), Vector2(224, 54), Vector2(232, 104), Vector2(205, 126), Vector2(157, 113)])},
				{"name":"GroveNorthCenterForest", "polygon":PackedVector2Array([Vector2(265, 54), Vector2(421, 54), Vector2(421, 113), Vector2(388, 126), Vector2(338, 112), Vector2(294, 124), Vector2(264, 103)])},
				{"name":"GroveShrine", "polygon":PackedVector2Array([Vector2(425, 54), Vector2(528, 54), Vector2(538, 112), Vector2(518, 135), Vector2(438, 134), Vector2(414, 111)])},
				{"name":"GroveWestLog", "polygon":PackedVector2Array([Vector2(169, 122), Vector2(238, 128), Vector2(258, 154), Vector2(239, 180), Vector2(181, 169), Vector2(161, 146)])},
				{"name":"GroveMound", "polygon":PackedVector2Array([Vector2(306, 145), Vector2(391, 144), Vector2(421, 178), Vector2(405, 227), Vector2(326, 235), Vector2(294, 201)])},
				{"name":"GrovePond", "polygon":PackedVector2Array([Vector2(51, 195), Vector2(127, 190), Vector2(171, 215), Vector2(183, 257), Vector2(158, 297), Vector2(84, 302), Vector2(51, 275)])},
				{"name":"GroveSouthForest", "polygon":PackedVector2Array([Vector2(220, 262), Vector2(338, 251), Vector2(374, 288), Vector2(363, 338), Vector2(219, 338), Vector2(204, 304)])},
				{"name":"GroveSouthEastLog", "polygon":PackedVector2Array([Vector2(442, 278), Vector2(535, 277), Vector2(568, 311), Vector2(557, 338), Vector2(431, 338), Vector2(423, 306)])},
			]
		"ruins":
			return [
				{"name":"RuinsNorthWestMachine", "polygon":PackedVector2Array([Vector2(25, 54), Vector2(202, 54), Vector2(207, 113), Vector2(183, 129), Vector2(77, 128), Vector2(25, 110)])},
				{"name":"RuinsNorthFieldWest", "rect":Rect2(250, 54, 55, 62)},
				{"name":"RuinsNorthFieldEast", "rect":Rect2(342, 54, 53, 62)},
				{"name":"RuinsNorthBell", "rect":Rect2(419, 54, 84, 80)},
				{"name":"RuinsNorthEastTank", "polygon":PackedVector2Array([Vector2(530, 54), Vector2(620, 54), Vector2(620, 137), Vector2(547, 137), Vector2(526, 116)])},
				{"name":"RuinsNorthEastChannel", "rect":Rect2(503, 54, 28, 84)},
				{"name":"RuinsWestWheel", "polygon":PackedVector2Array([Vector2(73, 137), Vector2(183, 137), Vector2(190, 207), Vector2(163, 225), Vector2(84, 218), Vector2(69, 178)])},
				{"name":"RuinsCentralMachine", "polygon":PackedVector2Array([Vector2(257, 135), Vector2(389, 135), Vector2(407, 180), Vector2(388, 219), Vector2(264, 218), Vector2(243, 180)])},
				{"name":"RuinsEastMachine", "polygon":PackedVector2Array([Vector2(443, 140), Vector2(555, 140), Vector2(568, 187), Vector2(548, 221), Vector2(453, 218), Vector2(431, 183)])},
				{"name":"RuinsSouthWestField", "rect":Rect2(137, 248, 99, 82)},
				{"name":"RuinsSouthVault", "polygon":PackedVector2Array([Vector2(257, 249), Vector2(388, 249), Vector2(388, 292), Vector2(351, 296), Vector2(320, 279), Vector2(288, 296), Vector2(257, 292)])},
				{"name":"RuinsSouthEastField", "rect":Rect2(430, 250, 126, 82)},
				{"name":"RuinsWestWater", "rect":Rect2(20, 248, 49, 90)},
				{"name":"RuinsEastWater", "rect":Rect2(569, 245, 51, 93)},
			]
		"dungeon", "abyss":
			return [
				{"name":"DungeonWestCliff", "polygon":PackedVector2Array([Vector2(20, 54), Vector2(153, 54), Vector2(165, 98), Vector2(140, 151), Vector2(92, 181), Vector2(62, 248), Vector2(20, 259)])},
				{"name":"DungeonCrystal", "polygon":PackedVector2Array([Vector2(137, 54), Vector2(218, 54), Vector2(222, 103), Vector2(194, 125), Vector2(151, 117), Vector2(130, 86)])},
				{"name":"DungeonDoor", "rect":Rect2(281, 54, 79, 50)},
				{"name":"DungeonNorthEastCliff", "polygon":PackedVector2Array([Vector2(394, 54), Vector2(620, 54), Vector2(620, 139), Vector2(588, 158), Vector2(532, 142), Vector2(493, 114), Vector2(432, 116)])},
				{"name":"DungeonEastCrystal", "polygon":PackedVector2Array([Vector2(536, 134), Vector2(620, 128), Vector2(620, 241), Vector2(568, 244), Vector2(535, 206)])},
				{"name":"DungeonSouthWestCliff", "polygon":PackedVector2Array([Vector2(20, 258), Vector2(83, 243), Vector2(150, 276), Vector2(202, 321), Vector2(197, 338), Vector2(20, 338)])},
				{"name":"DungeonSouthEastCliff", "polygon":PackedVector2Array([Vector2(498, 259), Vector2(555, 235), Vector2(620, 238), Vector2(620, 338), Vector2(495, 338)])},
			]
	return []


func _add_world_obstacle(obstacle_name: String, rect: Rect2, track_for_safety: bool = true) -> void:
	if track_for_safety:
		active_obstacle_rects.append(rect)
	_create_wall(rect.get_center(), rect.size, obstacle_name)


func _add_world_polygon(obstacle_name: String, polygon: PackedVector2Array, track_for_safety: bool = true) -> void:
	if polygon.size() < 3:
		return
	if track_for_safety:
		active_obstacle_polygons.append(polygon)
	var body := StaticBody2D.new()
	body.name = obstacle_name
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionPolygon2D.new()
	collision.build_mode = CollisionPolygon2D.BUILD_SOLIDS
	collision.polygon = polygon
	body.add_child(collision)
	world_collision_root.add_child(body)


func _create_wall(wall_position: Vector2, size: Vector2, wall_name: String = "WorldWall") -> void:
	var wall := StaticBody2D.new()
	wall.name = wall_name
	wall.position = wall_position
	wall.collision_layer = 1
	wall.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	wall.add_child(collision)
	world_collision_root.add_child(wall)


func is_world_position_blocked(position: Vector2, margin: float = 0.0) -> bool:
	for rect: Rect2 in active_obstacle_rects:
		if rect.grow(margin).has_point(position):
			return true
	for polygon: PackedVector2Array in active_obstacle_polygons:
		if _point_in_or_near_polygon(position, polygon, margin):
			return true
	return false


func is_map_position_blocked(map_mode: String, position: Vector2, margin: float = 0.0) -> bool:
	if position.x < 20.0 + margin or position.x > 620.0 - margin or position.y < 54.0 + margin or position.y > 338.0 - margin:
		return true
	for obstacle: Dictionary in _world_obstacle_layout(map_mode):
		if obstacle.has("rect"):
			if Rect2(obstacle.rect).grow(margin).has_point(position):
				return true
		elif _point_in_or_near_polygon(position, PackedVector2Array(obstacle.polygon), margin):
			return true
	return false


func _point_in_or_near_polygon(position: Vector2, polygon: PackedVector2Array, margin: float) -> bool:
	if Geometry2D.is_point_in_polygon(position, polygon):
		return true
	if margin <= 0.0:
		return false
	for index in range(polygon.size()):
		var edge_start := polygon[index]
		var edge_end := polygon[(index + 1) % polygon.size()]
		if Geometry2D.get_closest_point_to_segment(position, edge_start, edge_end).distance_to(position) <= margin:
			return true
	return false


func map_has_walkable_path(map_mode: String, start: Vector2, target: Vector2, clearance: float = 7.0) -> bool:
	if is_map_position_blocked(map_mode, start, clearance) or is_map_position_blocked(map_mode, target, clearance):
		return false
	var step := 8.0
	var frontier: Array[Vector2] = [start]
	var visited := {"%d,%d" % [roundi(start.x / step), roundi(start.y / step)]:true}
	var cursor := 0
	while cursor < frontier.size() and frontier.size() < 7000:
		var current := frontier[cursor]
		cursor += 1
		if current.distance_to(target) <= step * 1.5:
			return true
		for direction: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
			var next := current + direction * step
			var key := "%d,%d" % [roundi(next.x / step), roundi(next.y / step)]
			if visited.has(key) or is_map_position_blocked(map_mode, next, clearance):
				continue
			visited[key] = true
			frontier.append(next)
	return false


func map_has_reachable_interaction(map_mode: String, start: Vector2, target: Vector2, interaction_radius: float, clearance: float = 7.0) -> bool:
	# Interaction anchors may sit on water, a tree or a building facade. Validate
	# that the player can reach a legal standing point within the real prompt
	# radius instead of teleporting directly onto that anchor in a test.
	if is_map_position_blocked(map_mode, start, clearance):
		return false
	var step := 4.0
	var frontier: Array[Vector2] = [start]
	var visited := {"%d,%d" % [roundi(start.x / step), roundi(start.y / step)]:true}
	var cursor := 0
	while cursor < frontier.size() and frontier.size() < 20000:
		var current := frontier[cursor]
		cursor += 1
		if current.distance_to(target) <= interaction_radius:
			return true
		for direction: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
			var next := current + direction * step
			var key := "%d,%d" % [roundi(next.x / step), roundi(next.y / step)]
			if visited.has(key) or is_map_position_blocked(map_mode, next, clearance):
				continue
			visited[key] = true
			frontier.append(next)
	return false


func interaction_reachability_cases() -> Dictionary:
	var farm_cases: Array[Dictionary] = [
		{"name":"shipping", "position":SHIPPING_POSITION, "radius":42.0},
		{"name":"pond_fishing", "position":POND_FISH_POSITION, "radius":48.0},
		{"name":"automation", "position":AUTOMATION_CONSOLE_POSITION, "radius":44.0},
		{"name":"mira", "position":MIRA_POSITION, "radius":42.0},
	]
	for resource_id: String in FARM_RESOURCES:
		farm_cases.append({"name":resource_id, "position":Vector2(FARM_RESOURCES[resource_id].position), "radius":36.0})
	var village_cases: Array[Dictionary] = []
	for shop_id: String in SHOP_POSITIONS:
		village_cases.append({"name":shop_id, "position":Vector2(SHOP_POSITIONS[shop_id]), "radius":38.0})
	for npc_id: String in NPC_POSITIONS:
		village_cases.append({"name":npc_id, "position":Vector2(NPC_POSITIONS[npc_id]), "radius":34.0})
	var river_cases: Array[Dictionary] = [
		{"name":"fishing", "position":RIVER_FISH_POSITION, "radius":52.0},
		{"name":"reeds", "position":RIVER_RESOURCE_POSITION, "radius":48.0},
	]
	for npc_id: String in RIVER_NPC_POSITIONS:
		river_cases.append({"name":npc_id, "position":Vector2(RIVER_NPC_POSITIONS[npc_id]), "radius":46.0})
	var grove_cases: Array[Dictionary] = [{"name":"herb", "position":GROVE_RESOURCE_POSITION, "radius":48.0}]
	for npc_id: String in GROVE_NPC_POSITIONS:
		grove_cases.append({"name":npc_id, "position":Vector2(GROVE_NPC_POSITIONS[npc_id]), "radius":46.0})
	var ruins_cases: Array[Dictionary] = [{"name":"gear", "position":RUINS_RESOURCE_POSITION, "radius":48.0}]
	for npc_id: String in RUINS_NPC_POSITIONS:
		ruins_cases.append({"name":npc_id, "position":Vector2(RUINS_NPC_POSITIONS[npc_id]), "radius":46.0})
	return {
		"farm":farm_cases,
		"village":village_cases,
		"river":river_cases,
		"grove":grove_cases,
		"ruins":ruins_cases,
		"dungeon":[{"name":"ore", "position":DUNGEON_ORE_POSITION, "radius":38.0}],
	}


func walkable_component_summary(map_mode: String, clearance: float = 7.0, step: float = 4.0) -> Dictionary:
	# Scan every walkable grid point, not only the route from spawn to exits. This
	# exposes isolated road pockets that a single start/target test cannot see.
	var walkable: Dictionary = {}
	for y_index in range(ceili(54.0 / step), floori(338.0 / step) + 1):
		for x_index in range(ceili(20.0 / step), floori(620.0 / step) + 1):
			var point := Vector2(float(x_index) * step, float(y_index) * step)
			if not is_map_position_blocked(map_mode, point, clearance):
				walkable[Vector2i(x_index, y_index)] = true
	var remaining := walkable.duplicate()
	var components: Array[Dictionary] = []
	while not remaining.is_empty():
		var start: Vector2i = remaining.keys()[0]
		var frontier: Array[Vector2i] = [start]
		remaining.erase(start)
		var cursor := 0
		while cursor < frontier.size():
			var current := frontier[cursor]
			cursor += 1
			for direction: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
				var next := current + direction
				if remaining.erase(next):
					frontier.append(next)
		var minimum := frontier[0]
		var maximum := frontier[0]
		for grid_point: Vector2i in frontier:
			minimum = Vector2i(mini(minimum.x, grid_point.x), mini(minimum.y, grid_point.y))
			maximum = Vector2i(maxi(maximum.x, grid_point.x), maxi(maximum.y, grid_point.y))
		components.append({
			"size":frontier.size(),
			"sample":Vector2(frontier[0]) * step,
			"bounds":Rect2(Vector2(minimum) * step, Vector2(maximum - minimum + Vector2i.ONE) * step),
		})
	components.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return int(left.size) > int(right.size))
	var component_sizes: Array[int] = []
	for component: Dictionary in components:
		component_sizes.append(int(component.size))
	var largest := component_sizes[0] if not component_sizes.is_empty() else 0
	return {
		"walkable_points":walkable.size(),
		"component_count":component_sizes.size(),
		"component_sizes":component_sizes,
		"components":components,
		"largest_component":largest,
		"disconnected_points":walkable.size() - largest,
	}


func world_collision_summary(map_mode: String) -> Dictionary:
	var layout := _world_obstacle_layout(map_mode)
	var rectangles := 0
	var polygons := 0
	var vertices := 0
	for obstacle: Dictionary in layout:
		if obstacle.has("rect"):
			rectangles += 1
		else:
			polygons += 1
			vertices += PackedVector2Array(obstacle.polygon).size()
	return {"obstacles":layout.size(), "rectangles":rectangles, "polygons":polygons, "vertices":vertices}


func _sanitize_player_position() -> void:
	if not is_instance_valid(player) or not is_world_position_blocked(player.global_position, 9.0):
		return
	player.global_position = _safe_spawn_for_mode()
	GameState.player_position = player.global_position


func _safe_spawn_for_mode(map_mode: String = "") -> Vector2:
	var resolved_mode := mode if map_mode.is_empty() else map_mode
	return {
		"farm": Vector2(318, 300),
		"village": Vector2(260, 300),
		"river": Vector2(105, 285),
		"grove": Vector2(390, 270),
		"ruins": Vector2(100, 235),
		"dungeon": DUNGEON_ENTRY_SPAWN,
		"abyss": DUNGEON_ENTRY_SPAWN,
	}.get(resolved_mode, Vector2(318, 300))


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
	seed_card = PanelContainer.new()
	seed_card.position = Vector2(8, 58)
	seed_card.size = Vector2(204, 38)
	seed_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(seed_card)
	var seed_row := HBoxContainer.new()
	seed_card.add_child(seed_row)
	seed_icon = TextureRect.new()
	seed_icon.texture = ItemIconFactory.texture_for(&"spring_turnip", &"seed")
	seed_icon.custom_minimum_size = Vector2(34, 34)
	seed_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	seed_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	seed_row.add_child(seed_icon)
	seed_card_label = Label.new()
	seed_card_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	seed_card_label.add_theme_font_size_override("font_size", 11)
	seed_card_label.add_theme_color_override("font_color", Color("fff1b6"))
	seed_row.add_child(seed_card_label)
	attack_card = PanelContainer.new()
	attack_card.position = Vector2(510, 58)
	attack_card.size = Vector2(122, 38)
	attack_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(attack_card)
	var attack_row := HBoxContainer.new()
	attack_card.add_child(attack_row)
	var attack_icon := TextureRect.new()
	attack_icon.texture = load("res://assets/runtime/ui/attack_slash_v2.svg")
	attack_icon.custom_minimum_size = Vector2(34, 34)
	attack_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	attack_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	attack_row.add_child(attack_icon)
	var attack_label := Label.new()
	attack_label.text = "J/A 攻擊"
	attack_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	attack_label.add_theme_font_size_override("font_size", 11)
	attack_label.add_theme_color_override("font_color", Color("fff1b6"))
	attack_row.add_child(attack_label)
	potion_card = PanelContainer.new()
	potion_card.position = Vector2(374, 58)
	potion_card.size = Vector2(130, 38)
	potion_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(potion_card)
	var potion_row := HBoxContainer.new()
	potion_card.add_child(potion_row)
	var potion_icon := TextureRect.new()
	potion_icon.texture = ItemIconFactory.texture_for(&"health_potion")
	potion_icon.custom_minimum_size = Vector2(34, 34)
	potion_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	potion_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	potion_row.add_child(potion_icon)
	potion_label = Label.new()
	potion_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	potion_label.add_theme_font_size_override("font_size", 10)
	potion_label.add_theme_color_override("font_color", Color("fff1b6"))
	potion_row.add_child(potion_label)
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
	toast_panel = PanelContainer.new()
	toast_panel.position = Vector2(150, 298)
	toast_panel.size = Vector2(340, 32)
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.modulate.a = 0.0
	toast_panel.add_theme_stylebox_override("panel", _world_prompt_style(Color("d8b66a")))
	canvas.add_child(toast_panel)
	toast_label = Label.new()
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 12)
	toast_label.add_theme_color_override("font_color", Color("fff1b6"))
	toast_panel.add_child(toast_label)
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2(135, 125)
	title_label.size = Vector2(370, 85)
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color("fff1b6"))
	canvas.add_child(title_label)
	_create_world_prompt_ui()


func _create_world_prompt_ui() -> void:
	world_prompt_layer = CanvasLayer.new()
	world_prompt_layer.layer = 10
	add_child(world_prompt_layer)
	world_prompt_panel = PanelContainer.new()
	world_prompt_panel.position = _context_prompt_rect().position
	world_prompt_panel.size = _context_prompt_rect().size
	world_prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_prompt_panel.visible = false
	world_prompt_layer.add_child(world_prompt_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	world_prompt_panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	margin.add_child(row)
	world_prompt_key_panel = PanelContainer.new()
	world_prompt_key_panel.custom_minimum_size = Vector2(25, 22)
	row.add_child(world_prompt_key_panel)
	var key_label := Label.new()
	key_label.text = "E"
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key_label.add_theme_font_size_override("font_size", 11)
	key_label.add_theme_color_override("font_color", Color("fff1b6"))
	world_prompt_key_panel.add_child(key_label)
	world_prompt_symbol_label = Label.new()
	world_prompt_symbol_label.custom_minimum_size = Vector2(20, 0)
	world_prompt_symbol_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	world_prompt_symbol_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	world_prompt_symbol_label.add_theme_font_size_override("font_size", 12)
	row.add_child(world_prompt_symbol_label)
	world_prompt_action_label = Label.new()
	world_prompt_action_label.custom_minimum_size = Vector2(42, 0)
	world_prompt_action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	world_prompt_action_label.add_theme_font_size_override("font_size", 10)
	row.add_child(world_prompt_action_label)
	world_prompt_title_label = Label.new()
	world_prompt_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	world_prompt_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	world_prompt_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	world_prompt_title_label.add_theme_font_size_override("font_size", 12)
	world_prompt_title_label.add_theme_color_override("font_color", Color("fff1b6"))
	row.add_child(world_prompt_title_label)


func _world_prompt_style(accent: Color, keycap: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.063, 0.105, 0.98) if not keycap else Color(accent.r * 0.32, accent.g * 0.32, accent.b * 0.32, 0.98)
	style.border_color = accent
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 5 if not keycap else 3
	style.corner_radius_top_right = 5 if not keycap else 3
	style.corner_radius_bottom_left = 5 if not keycap else 3
	style.corner_radius_bottom_right = 5 if not keycap else 3
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
	style.shadow_size = 3 if not keycap else 0
	return style


func _hide_world_prompt() -> void:
	if is_instance_valid(world_prompt_panel):
		world_prompt_panel.visible = false


func _world_prompt_blocked_by_overlay() -> bool:
	if is_instance_valid(title_overlay) or (is_instance_valid(title_label) and not title_label.text.is_empty()):
		return true
	for overlay: CanvasLayer in [game_menu, shop_menu, dialogue_overlay, festival_overlay, multiplayer_menu, automation_console]:
		if is_instance_valid(overlay) and overlay.visible:
			return true
	return false


func _update_world_prompt_ui() -> void:
	if not is_instance_valid(world_prompt_panel) or not is_instance_valid(player):
		return
	if _world_prompt_blocked_by_overlay() or (is_instance_valid(toast_panel) and not toast_label.text.is_empty() and toast_panel.modulate.a > 0.05):
		_hide_world_prompt()
		return
	var prompt := _world_prompt_data()
	if prompt.is_empty():
		_hide_world_prompt()
		return
	var accent := Color(prompt.get("accent", Color("78dcca")))
	world_prompt_symbol_label.text = String(prompt.get("symbol", "◇"))
	world_prompt_symbol_label.add_theme_color_override("font_color", accent.lightened(0.2))
	world_prompt_action_label.text = String(prompt.get("action", "互動"))
	world_prompt_action_label.add_theme_color_override("font_color", accent)
	world_prompt_title_label.text = String(prompt.get("title", ""))
	world_prompt_panel.add_theme_stylebox_override("panel", _world_prompt_style(accent))
	world_prompt_key_panel.add_theme_stylebox_override("panel", _world_prompt_style(accent, true))
	world_prompt_panel.visible = true


func _world_prompt_data() -> Dictionary:
	var route_id := _nearby_region_destination()
	if not route_id.is_empty():
		var connection: Dictionary = Dictionary(Dictionary(REGION_CONNECTIONS.get(mode, {})).get(String(route_id), {}))
		var route_style := _gateway_style(String(route_id))
		return {"symbol":route_style.symbol, "action":"前往", "title":connection.get("label", String(route_id)), "accent":route_style.color}
	if mode == "dungeon":
		if player.global_position.distance_to(DUNGEON_DESCENT_POSITION) <= 52.0:
			if floor_cleared:
				return {"symbol":"層", "action":"前往", "title":"鐘窟下一層", "accent":Color("e8b54b")}
			return {"symbol":"鎖", "action":"封鎖", "title":"擊敗本層敵人解除鐘印", "accent":Color("828894")}
		if player.global_position.distance_to(DUNGEON_ORE_POSITION) <= 38.0:
			return {"symbol":"礦", "action":"採集", "title":"鐘窟礦脈", "accent":Color("d39c55")}
		return {}
	if mode == "village":
		var nearby_shop := _nearby_shop()
		if not nearby_shop.is_empty():
			var shop: Dictionary = ContentRegistry.get_artifact("shops", nearby_shop)
			return {"symbol":Dictionary(SHOP_SIGN_STYLES.get(nearby_shop, {"symbol":"店"})).get("symbol", "店"), "action":"進入", "title":shop.get("display_name", "商店"), "accent":Color("78dcca")}
		var nearby_npc := _nearby_npc()
		if not nearby_npc.is_empty():
			var character: Dictionary = ContentRegistry.get_artifact("characters", nearby_npc)
			return {"symbol":"話", "action":"對話", "title":character.get("display_name", nearby_npc), "accent":Color("d8b66a")}
		return {}
	if mode in ["river", "grove", "ruins"]:
		var npc_id := _nearby_map_npc()
		if not npc_id.is_empty():
			var character: Dictionary = ContentRegistry.get_artifact("characters", npc_id)
			return {"symbol":"話", "action":"對話", "title":character.get("display_name", npc_id), "accent":Color("d8b66a")}
		if mode == "river" and player.global_position.distance_to(RIVER_FISH_POSITION) <= 52.0:
			return {"symbol":"魚", "action":"垂釣", "title":"鳴鐘河木棧", "accent":Color("64c9dc")}
		var item_id := &"river_reed" if mode == "river" else (&"forest_herb" if mode == "grove" else &"ancient_gear")
		var resource_position := RIVER_RESOURCE_POSITION if mode == "river" else (GROVE_RESOURCE_POSITION if mode == "grove" else RUINS_RESOURCE_POSITION)
		if player.global_position.distance_to(resource_position) <= 48.0:
			var resource_accent := Color("75c98a") if mode == "grove" else (Color("d39c55") if mode == "ruins" else Color("c5bd6d"))
			return {"symbol":"取", "action":"採集", "title":ItemIconFactory.display_name_for(item_id), "accent":resource_accent}
		return {}
	if mode == "farm":
		if player.global_position.distance_to(AUTOMATION_CONSOLE_POSITION) <= 44.0:
			return {"symbol":"鐘", "action":"操作", "title":"農場鐘網控制台", "accent":Color("e8b54b")}
		if player.global_position.distance_to(SHIPPING_POSITION) <= 42.0:
			return {"symbol":"箱", "action":"出貨", "title":"農場出貨箱", "accent":Color("78dcca")}
		if _mira_is_on_farm() and player.global_position.distance_to(MIRA_POSITION) <= 42.0:
			return {"symbol":"話", "action":"對話", "title":"米拉", "accent":Color("d8b66a")}
		if player.global_position.distance_to(POND_FISH_POSITION) <= 48.0:
			var tide_active: bool = GameState.eldritch.is_tide_active(GameState.calendar.day, GameState.calendar.minute_of_day, GameState.current_weather)
			return {"symbol":"潮" if tide_active and GameState.eldritch.can_challenge() else "魚", "action":"踏入" if tide_active and GameState.eldritch.can_challenge() else "垂釣", "title":"池塘釣點", "accent":Color("a998dd") if tide_active else Color("64c9dc")}
		for node_id: String in FARM_RESOURCES:
			var resource: Dictionary = FARM_RESOURCES[node_id]
			if player.global_position.distance_to(Vector2(resource.position)) <= 36.0:
				return {"symbol":"木" if String(resource.kind) == "tree" else "礦", "action":"採集", "title":"農場木材" if String(resource.kind) == "tree" else "農場石材", "accent":Color("75c98a") if String(resource.kind) == "tree" else Color("b7a279")}
		if not _nearby_animal().is_empty():
			return {"symbol":"畜", "action":"照料", "title":"農場動物", "accent":Color("d8b66a")}
		var nearby_plot := _nearest_plot()
		if nearby_plot.x >= 0:
			var plot: Dictionary = Dictionary(GameState.farm.plots.get("%d,%d" % [nearby_plot.x, nearby_plot.y], {}))
			var crop_id := String(plot.get("crop_id", ""))
			if not crop_id.is_empty():
				var crop: Dictionary = ContentRegistry.get_artifact("crops", crop_id)
				return {"symbol":"苗", "action":"照料", "title":crop.get("display_name", crop_id), "accent":Color("75c98a")}
	return {}


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
	automation_console = AutomationConsoleScript.new() as PixelRPGAutomationConsole
	add_child(automation_console)


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
	name_input.call_deferred("grab_focus")


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
	EventBus.farm_changed.connect(_on_farm_changed)
	EventBus.map_change_requested.connect(_on_map_change_requested)
	SaveManager.quick_load_completed.connect(_on_quick_load_completed)
	NetworkManager.snapshot_received.connect(_on_network_snapshot)
	NetworkManager.action_result_received.connect(_on_network_action_result)
	NetworkManager.status_changed.connect(_on_network_status_changed)


func _on_quick_load_completed() -> void:
	var restored_mode := _mode_for_map(GameState.current_map_id)
	if restored_mode == "dungeon":
		_enter_dungeon(false)
		return
	if restored_mode == "abyss":
		_begin_eldritch_challenge(false)
		return
	_clear_enemies()
	mode = restored_mode
	final_challenge_active = false
	eldritch_challenge_active = false
	floor_cleared = false
	if is_instance_valid(title_label):
		title_label.position = Vector2(135, 125)
		title_label.size = Vector2(370, 85)
		title_label.text = ""
	_set_background_for_mode()
	_refresh_seasonal_seeds()
	queue_redraw()


func _update_hud() -> void:
	if not is_instance_valid(player) or not is_instance_valid(hud_label):
		return
	var forecast := PixelRPGCalendarSystem.forecast_for_tomorrow(GameState.calendar.year, GameState.calendar.season_index, GameState.calendar.day)
	var warning := " ⚠明日%s" % _weather_name(String(forecast.weather)) if bool(forecast.warning) else ""
	seed_card.visible = mode == "farm"
	attack_card.visible = mode in ["dungeon", "abyss"]
	potion_card.visible = mode in ["dungeon", "abyss"]
	potion_label.text = "H/LB 藥水\n×%d" % int(GameState.inventory.get("health_potion", 0))
	if mode == "farm":
		var seed_id := _selected_seed_id()
		var crop := ContentRegistry.get_artifact("crops", seed_id)
		seed_icon.texture = ItemIconFactory.texture_for(seed_id, &"seed")
		seed_card_label.text = "目前種子\n%s ×%d" % [crop.get("display_name", "無"), int(GameState.farm.seed_stock.get(String(seed_id), 0))]
		var animal_products := int(GameState.farm.produce.get("egg", 0)) + int(GameState.farm.produce.get("milk", 0))
		var tide_text := "異潮" if GameState.eldritch.is_tide_active(GameState.calendar.day, GameState.calendar.minute_of_day, GameState.current_weather) else "平潮"
		var festival: Dictionary = GameState.festivals.festival_on(GameState.calendar.season_id(), GameState.calendar.day)
		var day_status := "祭・%s" % festival.get("display_name") if not festival.is_empty() else tide_text
		hud_label.text = "%s　%s　%s%s　%dG　體力 %d/100　理智 %d/100\n農場 Lv.%d　種子：%s ×%d　收成庫 %d　出貨 %dG　%s" % [GameState.calendar.date_text(), GameState.calendar.time_text(), _weather_name(GameState.current_weather), warning, GameState.coins, GameState.tools.stamina, GameState.eldritch.sanity, GameState.farm.rank, crop.get("display_name", "無"), int(GameState.farm.seed_stock.get(String(seed_id), 0)), GameState.farm.produce.size() + animal_products, GameState.economy.pending_value(), day_status]
		controls_label.text = "E/Y 互動／道路／鐘網　Q/RB 換種子　Esc/Start 手冊　M/Select 連線　T/D← 速度　C/D→ 睡覺"
	elif mode == "village":
		var tide_text := "異潮" if GameState.eldritch.is_tide_active(GameState.calendar.day, GameState.calendar.minute_of_day, GameState.current_weather) else "平潮"
		hud_label.text = "%s　%s　%s%s　%dG　體力 %d/100　理智 %d/100\n霧落村｜廣場、商店與居民｜%s" % [GameState.calendar.date_text(), GameState.calendar.time_text(), _weather_name(GameState.current_weather), warning, GameState.coins, GameState.tools.stamina, GameState.eldritch.sanity, tide_text]
		controls_label.text = "WASD/搖桿 移動　E/Y 道路／商店／對話　Esc/Start 旅行圖　M/Select 連線"
	elif mode in ["river", "grove", "ruins"]:
		var map_title: String = {"river":"鳴鐘河畔","grove":"古鐘林","ruins":"古鐘機械遺跡"}.get(mode, mode)
		var local_hint: String = {"river":"釣魚、蘆葦與河燈線索","grove":"藥草、神龕與同行事件","ruins":"齒輪、鐘能與封印歷史"}.get(mode, "探索")
		var tide_text := "無星異潮可釣" if mode == "river" and GameState.eldritch.is_tide_active(GameState.calendar.day, GameState.calendar.minute_of_day, GameState.current_weather) else "平潮探索"
		hud_label.text = "%s　%s　%s%s　%dG　體力 %d/100\n%s｜%s｜%s" % [GameState.calendar.date_text(), GameState.calendar.time_text(), _weather_name(GameState.current_weather), warning, GameState.coins, GameState.tools.stamina, map_title, local_hint, tide_text]
		controls_label.text = "WASD/搖桿 移動　E/Y 道路／互動／釣魚　Esc/Start 旅行圖　M/Select 連線"
	elif mode == "dungeon":
		hud_label.text = "%s　%s　HP %d/%d　四季鐘窟 %dF　敵人 %d\n封印 %d/4　電梯 %s　%s" % [GameState.calendar.date_text(), GameState.calendar.time_text(), player.health, player.max_health, GameState.dungeon.current_floor, enemies_remaining, GameState.dungeon.seals.size(), str(GameState.dungeon.available_elevators()), "無限挑戰已開放" if GameState.dungeon.endless_unlocked else "主線無期限"]
		controls_label.text = "WASD/搖桿 移動　J/A 攻擊　K/B 翻滾　L/X 技能　E/Y 鐘門／下層　B/RS 返回　H/LB 藥水"
	else:
		hud_label.text = "%s　%s　HP %d/%d　夢岸敵影 %d\n理智 %d/100　異魚 %d/8　洞見 %d　%s" % [GameState.calendar.date_text(), GameState.calendar.time_text(), player.health, player.max_health, enemies_remaining, GameState.eldritch.sanity, GameState.eldritch.eldritch_catches.size(), GameState.eldritch.insight, "古神已沉睡" if GameState.eldritch.boss_defeated else "克蘇魯之影正在凝視"]
		controls_label.text = "WASD/搖桿 移動　J/A 攻擊　K/B 翻滾　L/X 技能　H/LB 藥水　B/RS 撤退"


func _interact() -> void:
	_hide_world_prompt()
	var region_destination := _nearby_region_destination()
	if not region_destination.is_empty():
		_activate_region_destination(region_destination)
		return
	if mode == "abyss":
		if floor_cleared and player.global_position.distance_to(DUNGEON_DESCENT_POSITION) <= 48.0:
			_leave_eldritch_shore()
		else:
			_show_toast("上方鐘門可撤退；擊敗古神後右下傳送門也會開啟")
		return
	if mode == "dungeon":
		if player.global_position.distance_to(DUNGEON_ORE_POSITION) <= 38.0:
			var ore_result := GameState.gather_resource("ore_%d" % GameState.dungeon.current_floor, "ore")
			_show_toast(String(ore_result.get("message", "")))
			return
		if floor_cleared and player.global_position.distance_to(DUNGEON_DESCENT_POSITION) <= 48.0:
			_descend_dungeon()
		elif floor_cleared:
			_show_toast("右下發光鐘台：E 前往下一層；上方鐘門：E 返回農場")
		else:
			_show_toast("清除敵人解鎖右下鐘台；上方鐘門隨時可返回農場")
		return
	if mode in ["river", "grove", "ruins"]:
		var map_npc := _nearby_map_npc()
		if not map_npc.is_empty():
			_talk_to_npc(map_npc)
			return
		if mode == "river" and player.global_position.distance_to(RIVER_FISH_POSITION) <= 52.0:
			if NetworkManager.is_online():
				NetworkManager.request_world_action("fish", {"location":"river"})
			else:
				var catch_result := GameState.fish_at("river")
				_show_toast(String(catch_result.get("message", "")))
			return
		var resource_id := "river_reeds" if mode == "river" else ("bellwood_herbs" if mode == "grove" else "ruins_gears")
		var resource_position := RIVER_RESOURCE_POSITION if mode == "river" else (GROVE_RESOURCE_POSITION if mode == "grove" else RUINS_RESOURCE_POSITION)
		if player.global_position.distance_to(resource_position) <= 48.0:
			if NetworkManager.is_online():
				NetworkManager.request_world_action("map_resource", {"node_id":resource_id})
			else:
				var gather_result := GameState.gather_map_resource(resource_id)
				_show_toast(String(gather_result.get("message", "")))
			return
		_show_toast("走近發光採集點、釣點、同行村民或出口再互動")
		return
	if mode == "village":
		var village_shop := _nearby_shop()
		if not village_shop.is_empty():
			shop_menu.open(village_shop)
			return
		var npc_id := _nearby_npc()
		if not npc_id.is_empty():
			_talk_to_npc(npc_id)
			return
	if mode == "farm":
		if player.global_position.distance_to(AUTOMATION_CONSOLE_POSITION) <= 44.0:
			automation_console.open()
			return
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
	if player.global_position.distance_to(POND_FISH_POSITION) <= 48.0:
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


func _nearby_region_destination() -> StringName:
	var best_id := &""
	var best_distance := 44.0
	var connections: Dictionary = Dictionary(REGION_CONNECTIONS.get(mode, {}))
	for map_id: String in connections:
		var distance := player.global_position.distance_to(Vector2(Dictionary(connections[map_id]).position))
		if distance < best_distance:
			best_id = StringName(map_id)
			best_distance = distance
	return best_id


func _activate_region_destination(map_id: StringName) -> void:
	if map_id == &"mistfall_depths":
		_enter_dungeon()
		return
	if mode == "abyss":
		_leave_eldritch_shore()
		return
	if mode == "dungeon":
		_clear_enemies()
		final_challenge_active = false
		GameState.dungeon.current_floor = 0
	_travel_to_map(map_id)


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
		if not chapter.is_empty():
			var chapter_id := String(chapter.get("id", ""))
			var quest_id := "%s_quest" % chapter_id
			var quest_state := String(GameState.quest_states.get(quest_id, "inactive"))
			if quest_state == "inactive":
				GameState.set_flag("story_dialogue_seen_%s" % chapter_id, true)
				DialogueAdapter.start_dialogue("%s_dialogue" % chapter_id)
				return
			if quest_state == "active":
				var story_result := GameState.try_complete_current_story_chapter()
				if bool(story_result.get("ok", false)):
					dialogue_overlay.open_line(&"mira", String(story_result.get("message", "章節完成")), "主線完成")
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
	for npc_id: String in npc_sprites:
		var sprite: Sprite2D = npc_sprites[npc_id]
		if not sprite.visible:
			continue
		# Keep the alpha silhouette's lowest foot pixel locked to its world
		# ground point. A vertical sine wave made NPCs, especially Mira, hover.
		sprite.position = _npc_anchor(npc_id)
		sprite.z_index = 100 + clampi(roundi(_npc_ground_position(npc_id).y), 0, 360)


func _npc_anchor(npc_id: String) -> Vector2:
	if mode == "village":
		return _npc_sprite_anchor(npc_id, Vector2(NPC_POSITIONS[npc_id]))
	if mode == "river" and RIVER_NPC_POSITIONS.has(npc_id):
		return _npc_sprite_anchor(npc_id, Vector2(RIVER_NPC_POSITIONS[npc_id]))
	if mode == "grove" and GROVE_NPC_POSITIONS.has(npc_id):
		return _npc_sprite_anchor(npc_id, Vector2(GROVE_NPC_POSITIONS[npc_id]))
	if mode == "ruins" and RUINS_NPC_POSITIONS.has(npc_id):
		return _npc_sprite_anchor(npc_id, Vector2(RUINS_NPC_POSITIONS[npc_id]))
	return _npc_sprite_anchor(npc_id, MIRA_POSITION)


func _npc_sprite_anchor(npc_id: String, ground_position: Vector2) -> Vector2:
	return ground_position + Vector2(0, -float(NPC_FOOT_OFFSETS.get(npc_id, 20.0)))


func _nearby_map_npc() -> String:
	var positions: Dictionary = RIVER_NPC_POSITIONS if mode == "river" else (GROVE_NPC_POSITIONS if mode == "grove" else RUINS_NPC_POSITIONS)
	var best_id := ""
	var best_distance := 46.0
	for npc_id: String in positions:
		var distance := player.global_position.distance_to(Vector2(positions[npc_id]))
		if distance < best_distance:
			best_id = npc_id
			best_distance = distance
	return best_id


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
			add_child(sprite)
			animal_sprites[animal_id] = sprite
		var animal_position := Vector2(490 + (index % 4) * 31, 154 + (index / 4) * 33)
		sprite.position = animal_position + Vector2(0, -9)
		sprite.z_index = 100 + clampi(roundi(animal_position.y), 0, 360)
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
	_travel_to_map(&"mistfall_village")


func _mode_for_map(map_id: StringName) -> String:
	return {
		"mistfall_farm":"farm", "mistfall_village":"village", "mistfall_river":"river",
		"bellwood_grove":"grove", "clockwork_ruins":"ruins", "mistfall_depths":"dungeon",
		"dreaming_shore":"abyss",
	}.get(String(map_id), "farm")


func _on_map_change_requested(map_id: StringName, _spawn_id: StringName) -> void:
	_travel_to_map(map_id)


func _travel_to_map(map_id: StringName) -> void:
	if map_id == &"mistfall_depths":
		_enter_dungeon()
		return
	if map_id == &"dreaming_shore":
		if GameState.eldritch.can_challenge():
			_begin_eldritch_challenge()
		else:
			_show_toast("釣齊四種異魚後，夢岸才會顯現")
		return
	var source_map_id := GameState.current_map_id
	_clear_enemies()
	mode = _mode_for_map(map_id)
	GameState.current_map_id = map_id
	_set_background_for_mode()
	player.global_position = _arrival_position_for_mode(mode, source_map_id)
	_sanitize_player_position()
	GameState.player_position = player.global_position
	title_label.text = ""
	var names := {"mistfall_farm":"霧落農場", "mistfall_village":"霧落村", "mistfall_river":"鳴鐘河畔", "bellwood_grove":"古鐘林", "clockwork_ruins":"古鐘機械遺跡"}
	_show_toast("來到%s" % names.get(String(map_id), String(map_id)))
	queue_redraw()


func _enter_farm_from_village() -> void:
	_travel_to_map(&"mistfall_farm")


func _arrival_position_for_mode(target_mode: String, source_map_id: StringName) -> Vector2:
	var connections: Dictionary = Dictionary(REGION_CONNECTIONS.get(target_mode, {}))
	if connections.has(String(source_map_id)):
		var entry_position := Vector2(Dictionary(connections[String(source_map_id)]).position)
		var inward := entry_position.direction_to(Vector2(320, 190))
		var candidate := entry_position + inward * 34.0
		if not is_world_position_blocked(candidate, 9.0):
			return candidate
	return _safe_spawn_for_mode()


func _interact_animal(animal_id: String) -> void:
	var result: Dictionary = GameState.interact_animal(animal_id)
	_show_toast(String(result.get("message", "")))
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
	var resume_final_challenge: bool = GameState.dungeon.current_floor >= PixelRPGDungeonSystem.MAX_FLOOR and GameState.dungeon.can_challenge_final_boss() and not GameState.dungeon.final_boss_defeated
	if GameState.dungeon.current_floor <= 0:
		if GameState.dungeon.can_challenge_final_boss() and not GameState.dungeon.final_boss_defeated:
			GameState.dungeon.enter_floor(PixelRPGDungeonSystem.MAX_FLOOR)
			resume_final_challenge = true
		elif GameState.dungeon.endless_unlocked:
			GameState.dungeon.enter_floor(maxi(PixelRPGDungeonSystem.MAX_FLOOR + 1, GameState.dungeon.max_reached + 1))
		else:
			var elevators: Array[int] = GameState.dungeon.available_elevators()
			var target_floor := 1 if elevators.is_empty() else mini(PixelRPGDungeonSystem.MAX_FLOOR, int(elevators.back()) + 1)
			GameState.dungeon.enter_floor(target_floor)
	if reset_position:
		player.global_position = DUNGEON_ENTRY_SPAWN
		_sanitize_player_position()
	_clear_enemies()
	if resume_final_challenge:
		_begin_final_challenge()
	elif GameState.dungeon.current_floor in GameState.dungeon.cleared_floors:
		floor_cleared = true
		final_challenge_active = false
		title_label.text = "%dF 探索完成\n按 E 前往下一層" % GameState.dungeon.current_floor
		_show_toast("已恢復四季鐘窟 %dF 的清層進度" % GameState.dungeon.current_floor)
	else:
		_spawn_dungeon_floor()
		_show_toast("進入四季鐘窟 %dF" % GameState.dungeon.current_floor)
	queue_redraw()


func _leave_dungeon() -> void:
	_clear_enemies()
	final_challenge_active = false
	GameState.dungeon.current_floor = 0
	mode = "farm"
	GameState.current_map_id = &"mistfall_farm"
	_set_background_for_mode()
	player.global_position = CAVE_POSITION + Vector2(0, 30)
	_sanitize_player_position()
	GameState.player_position = player.global_position
	_refresh_seasonal_seeds()
	_show_toast("返回霧落農場")
	queue_redraw()


func _begin_eldritch_challenge(reset_position: bool = true) -> void:
	mode = "abyss"
	GameState.current_map_id = &"dreaming_shore"
	_clear_enemies()
	_set_background_for_mode()
	if reset_position:
		player.global_position = DUNGEON_ENTRY_SPAWN
		_sanitize_player_position()
	if GameState.eldritch.boss_defeated:
		floor_cleared = true
		final_challenge_active = false
		eldritch_challenge_active = false
		title_label.position = Vector2(76, 126)
		title_label.size = Vector2(330, 85)
		title_label.text = "無星異潮退去\n深潮夢核回應了鐘聲"
		_show_toast("夢岸進度已恢復；按 E 返回農場")
		queue_redraw()
		return
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
	player.global_position = DUNGEON_ENTRY_SPAWN
	_sanitize_player_position()
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


func _on_farm_changed(_action: StringName, _payload: Dictionary) -> void:
	queue_redraw()


func _show_toast(message: String) -> void:
	if not is_instance_valid(toast_label) or message.is_empty():
		return
	_hide_world_prompt()
	if is_instance_valid(toast_tween):
		toast_tween.kill()
	toast_label.text = message
	toast_panel.modulate = Color.WHITE
	toast_tween = create_tween()
	toast_tween.tween_interval(1.4)
	toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.45)


func _weather_name(weather: String) -> String:
	return {"clear":"晴朗","rain":"下雨","storm":"雷雨","fog":"濃霧","typhoon":"颱風","snow":"降雪","blizzard":"暴雪"}.get(weather, weather)


func _seal_name(seal_id: String) -> String:
	return {"spring_seal":"春之封印","summer_seal":"夏之封印","autumn_seal":"秋之封印","winter_seal":"冬之封印"}.get(seal_id, seal_id)


func _mira_is_on_farm() -> bool:
	var location: Dictionary = GameState.npc_schedules.location_for(&"mira", GameState.calendar.minute_of_day, GameState.current_weather)
	return location.get("map", "") == "mistfall_farm"
