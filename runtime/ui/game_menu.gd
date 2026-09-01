class_name PixelRPGGameMenu
extends CanvasLayer

const ItemIconFactory := preload("res://runtime/ui/item_icon_factory.gd")

var panel: PanelContainer
var tabs: TabContainer
var status_label: Label
var inventory_grid: GridContainer
var seed_grid: GridContainer
var produce_grid: GridContainer
var inventory_icon_count := 0
var relationships_label: Label
var calendar_label: Label
var story_label: Label
var achievements_label: Label
var eldritch_label: Label
var volume_slider: HSlider
var fullscreen_toggle: CheckButton
var fullscreen_request_serial := 0
var farm_upgrade_button: Button
var candidate_select: OptionButton
var capture_action := StringName()
var rebind_buttons: Dictionary = {}
var recipe_select: OptionButton
var recipe_label: Label
var recipe_icon: TextureRect


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_build_ui()
	visible = false
	NetworkManager.world_state_received.connect(_on_network_world_received)


func _input(event: InputEvent) -> void:
	if visible and not capture_action.is_empty() and event.is_pressed() and not event.is_echo() and (event is InputEventKey or event is InputEventJoypadButton):
		get_viewport().set_input_as_handled()
		PixelRPGInputBindings.rebind_device(capture_action, event)
		PixelRPGInputBindings.save()
		capture_action = &""
		_refresh_rebind_labels()
		return
	if visible and event.is_action_pressed("pause_menu"):
		get_viewport().set_input_as_handled()
		close()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	refresh()
	visible = true
	get_tree().paused = true
	GameState.pause_game_time(true)
	farm_upgrade_button.grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false
	GameState.pause_game_time(false)


func refresh() -> void:
	status_label.text = "%s\n%s　%s　%dG\nHP %d/%d　體力 %d/100　理智 %d/100\n農場 Lv.%d　鐘窟最深 %dF\n工具：%s" % [GameState.player_profile.get("name", "旅人"), GameState.calendar.date_text(), GameState.calendar.time_text(), GameState.coins, GameState.player_stats.get("health", 100), GameState.player_stats.get("max_health", 100), GameState.tools.stamina, GameState.eldritch.sanity, GameState.farm.rank, GameState.dungeon.max_reached, _tool_summary()]
	_refresh_inventory_icons()
	calendar_label.text = "%s\n本季節慶：8、18、28 日\n今日天氣：%s\n明日預報：%s\n第 29、30 日保留給整理與特殊事件。" % [GameState.calendar.date_text(), GameState.current_weather, PixelRPGCalendarSystem.forecast_for_tomorrow(GameState.calendar.year, GameState.calendar.season_index, GameState.calendar.day).get("weather", "clear")]
	relationships_label.text = _relationship_text()
	var next_chapter: Dictionary = GameState.next_story_chapter()
	story_label.text = "《鐘塔之季》\n已完成章節：%d\n下一章：%s\n季節封印：%d/4\n主線與婚姻沒有日期期限。" % [Array(GameState.story_state.get("completed_chapters", [])).size(), next_chapter.get("title", "等待新的線索"), GameState.dungeon.seals.size()]
	achievements_label.text = _achievement_text()
	eldritch_label.text = _eldritch_journal_text()
	_refresh_recipe()
	volume_slider.value = float(GameState.settings.get("master_volume", 0.8))
	fullscreen_toggle.set_pressed_no_signal(DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN])
	var next_upgrade := ContentRegistry.get_artifact("farm_upgrades", "farm_rank_%d" % (GameState.farm.rank + 1))
	farm_upgrade_button.text = "農場已達最高等級" if GameState.farm.rank >= 10 else "擴建：%s（%dG）" % [next_upgrade.get("display_name", "下一級"), next_upgrade.get("cost", 0)]
	farm_upgrade_button.disabled = GameState.farm.rank >= 10


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.05, 0.82)
	shade.position = Vector2.ZERO
	shade.size = Vector2(640, 360)
	add_child(shade)
	panel = PanelContainer.new()
	panel.position = Vector2(46, 28)
	panel.size = Vector2(548, 304)
	add_child(panel)
	var root_box := VBoxContainer.new()
	panel.add_child(root_box)
	var header := Label.new()
	header.text = "霧落農歌・旅人手冊　　Esc／Start 關閉"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 16)
	root_box.add_child(header)
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(tabs)
	status_label = _add_text_tab("狀態")
	var status_parent := status_label.get_parent()
	farm_upgrade_button = Button.new()
	farm_upgrade_button.text = "擴建農場"
	farm_upgrade_button.pressed.connect(_on_farm_upgrade_pressed)
	status_parent.add_child(farm_upgrade_button)
	_add_inventory_tab()
	_add_relationship_tab()
	calendar_label = _add_text_tab("日曆")
	story_label = _add_text_tab("主線")
	achievements_label = _add_text_tab("成就")
	_add_cooking_tab()
	_add_settings_tab()
	_add_map_tab()
	eldritch_label = _add_text_tab("深潮錄")


func _add_text_tab(tab_name: String) -> Label:
	var margin := MarginContainer.new()
	margin.name = tab_name
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	tabs.add_child(margin)
	var box := VBoxContainer.new()
	margin.add_child(box)
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 14)
	box.add_child(label)
	return label


func _add_inventory_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "背包"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	seed_grid = _add_icon_section(content, "種子袋｜每種種子有對應作物圖示")
	inventory_grid = _add_icon_section(content, "隨身背包｜藥水、素材與任務物")
	produce_grid = _add_icon_section(content, "收成庫｜作物、魚、畜產品與料理")


func _add_icon_section(parent: VBoxContainer, title_text: String) -> GridContainer:
	var heading := Label.new()
	heading.text = title_text
	heading.add_theme_font_size_override("font_size", 12)
	heading.add_theme_color_override("font_color", Color("fff1b6"))
	parent.add_child(heading)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	parent.add_child(grid)
	return grid


func _refresh_inventory_icons() -> void:
	if not is_instance_valid(inventory_grid):
		return
	inventory_icon_count = 0
	_populate_icon_grid(seed_grid, GameState.farm.seed_stock, &"seed", "目前沒有種子")
	_populate_icon_grid(inventory_grid, GameState.inventory, &"auto", "隨身背包是空的")
	_populate_icon_grid(produce_grid, GameState.farm.produce, &"auto", "目前沒有收成")


func _populate_icon_grid(grid: GridContainer, source: Dictionary, kind: StringName, empty_text: String) -> void:
	for child: Node in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	var item_ids: Array = source.keys()
	item_ids.sort()
	for item_id_value: Variant in item_ids:
		var item_id := String(item_id_value)
		var quantity := int(source.get(item_id, 0))
		if quantity <= 0:
			continue
		_add_item_icon_card(grid, item_id, quantity, kind)
		inventory_icon_count += 1
	if grid.get_child_count() == 0:
		var empty := Label.new()
		empty.text = empty_text
		empty.add_theme_font_size_override("font_size", 10)
		grid.add_child(empty)


func _add_item_icon_card(grid: GridContainer, item_id: String, quantity: int, kind: StringName) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(124, 40)
	card.tooltip_text = "%s\n%s" % [ItemIconFactory.display_name_for(item_id), ItemIconFactory.description_for(item_id)]
	card.set_meta("item_id", item_id)
	grid.add_child(card)
	var row := HBoxContainer.new()
	card.add_child(row)
	var icon := TextureRect.new()
	icon.texture = ItemIconFactory.texture_for(StringName(item_id), kind)
	icon.custom_minimum_size = Vector2(36, 36)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var label := Label.new()
	label.text = "%s\n×%d" % [ItemIconFactory.display_name_for(item_id), quantity]
	label.custom_minimum_size = Vector2(82, 36)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9)
	label.clip_text = true
	row.add_child(label)


func _add_relationship_tab() -> void:
	var box := VBoxContainer.new()
	box.name = "關係"
	tabs.add_child(box)
	var portrait_row := HBoxContainer.new()
	portrait_row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(portrait_row)
	var atlas_texture: Texture2D = load("res://assets/runtime/portraits/romance_candidates_atlas.png")
	for index in range(4):
		var portrait := TextureRect.new()
		var region := AtlasTexture.new()
		region.atlas = atlas_texture
		region.region = Rect2(index * 512, 0, 512, 768)
		portrait.texture = region
		portrait.custom_minimum_size = Vector2(108, 150)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait_row.add_child(portrait)
	relationships_label = Label.new()
	relationships_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relationships_label.add_theme_font_size_override("font_size", 13)
	box.add_child(relationships_label)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(actions)
	candidate_select = OptionButton.new()
	for candidate_id in ["mira", "lian", "soren", "yuna"]:
		candidate_select.add_item(String(ContentRegistry.get_artifact("characters", candidate_id).get("display_name", candidate_id)))
		candidate_select.set_item_metadata(candidate_select.item_count - 1, candidate_id)
	actions.add_child(candidate_select)
	var date_button := Button.new()
	date_button.text = "告白"
	date_button.pressed.connect(_on_date_pressed)
	actions.add_child(date_button)
	var propose_button := Button.new()
	propose_button.text = "求婚"
	propose_button.pressed.connect(_on_propose_pressed)
	actions.add_child(propose_button)
	var family_button := Button.new()
	family_button.text = "家庭事件"
	family_button.pressed.connect(_on_family_pressed)
	actions.add_child(family_button)


func _add_settings_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "設定"
	tabs.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	var volume_label := Label.new()
	volume_label.text = "主音量"
	box.add_child(volume_label)
	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.value_changed.connect(_on_volume_changed)
	box.add_child(volume_slider)
	fullscreen_toggle = CheckButton.new()
	fullscreen_toggle.text = "全螢幕"
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	box.add_child(fullscreen_toggle)
	var speed_button := Button.new()
	speed_button.text = "切換每日速度（10／15／20 分鐘）"
	speed_button.pressed.connect(_on_speed_pressed)
	box.add_child(speed_button)
	var save_button := Button.new()
	save_button.text = "快速存檔"
	save_button.pressed.connect(SaveManager.save_quick)
	box.add_child(save_button)
	var load_button := Button.new()
	load_button.text = "快速讀檔"
	load_button.pressed.connect(_load_and_refresh)
	box.add_child(load_button)
	var controls_title := Label.new()
	controls_title.text = "按鍵／手把重新綁定（按按鈕後輸入新按鍵）"
	box.add_child(controls_title)
	var control_grid := GridContainer.new()
	control_grid.columns = 2
	box.add_child(control_grid)
	var configurable_actions := {
		"attack":"攻擊", "dodge":"翻滾", "active_skill":"技能", "interact":"互動", "use_potion":"藥水",
		"cycle_seed":"換種子", "sleep_day":"睡覺", "time_speed":"時間速度", "toggle_cave":"洞窟",
		"attend_festival":"節慶", "pause_menu":"手冊", "multiplayer_menu":"連線", "quick_save":"快速存檔", "quick_load":"快速讀檔",
	}
	for action_id: String in configurable_actions:
		var action_label := Label.new()
		action_label.text = configurable_actions[action_id]
		control_grid.add_child(action_label)
		var rebind_button := Button.new()
		rebind_button.pressed.connect(_begin_rebind.bind(StringName(action_id)))
		control_grid.add_child(rebind_button)
		rebind_buttons[action_id] = rebind_button
	var reset_controls := Button.new()
	reset_controls.text = "恢復預設操作"
	reset_controls.pressed.connect(_reset_controls)
	box.add_child(reset_controls)
	_refresh_rebind_labels()


func _add_cooking_tab() -> void:
	var box := VBoxContainer.new()
	box.name = "料理"
	tabs.add_child(box)
	var heading := Label.new()
	heading.text = "農舍廚房・40 道四季料理"
	heading.add_theme_font_size_override("font_size", 16)
	box.add_child(heading)
	recipe_select = OptionButton.new()
	var recipes := ContentRegistry.get_all("recipes")
	recipes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.get("id", "")) < String(b.get("id", "")))
	for recipe: Dictionary in recipes:
		recipe_select.add_item(String(recipe.get("display_name", recipe.get("id", ""))))
		var item_index := recipe_select.item_count - 1
		var recipe_id := StringName(recipe.get("id", ""))
		recipe_select.set_item_metadata(item_index, String(recipe_id))
		recipe_select.set_item_icon(item_index, ItemIconFactory.texture_for(recipe_id, &"dish", 28))
	recipe_select.item_selected.connect(_on_recipe_selected)
	box.add_child(recipe_select)
	var recipe_row := HBoxContainer.new()
	recipe_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(recipe_row)
	recipe_icon = TextureRect.new()
	recipe_icon.custom_minimum_size = Vector2(72, 72)
	recipe_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	recipe_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	recipe_row.add_child(recipe_icon)
	recipe_label = Label.new()
	recipe_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recipe_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	recipe_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recipe_row.add_child(recipe_label)
	var action_row := HBoxContainer.new()
	box.add_child(action_row)
	var cook_button := Button.new()
	cook_button.text = "烹調"
	cook_button.pressed.connect(_on_cook_pressed)
	action_row.add_child(cook_button)
	var eat_button := Button.new()
	eat_button.text = "享用（恢復體力）"
	eat_button.pressed.connect(_on_eat_pressed)
	action_row.add_child(eat_button)


func _add_map_tab() -> void:
	var box := VBoxContainer.new()
	box.name = "地圖"
	tabs.add_child(box)
	var heading := Label.new()
	heading.text = "霧落地區旅行圖（所有道路皆為雙向連接）"
	heading.add_theme_font_size_override("font_size", 16)
	box.add_child(heading)
	var description := Label.new()
	description.text = "每張地圖都有發光路標，可直接前往相鄰區域，不必繞回農場。河畔、鐘林、村莊與古代都市彼此相連，古代都市也能直通四季鐘窟。"
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	var grid := GridContainer.new()
	grid.columns = 2
	box.add_child(grid)
	var destinations := [
		["mistfall_farm", "霧落農場｜種植、畜牧、自動化"],
		["mistfall_village", "霧落村｜十名村民、商店、戀愛"],
		["mistfall_river", "鳴鐘河畔｜釣魚、蘆葦、河燈線索"],
		["bellwood_grove", "鐘林｜採集、神龕、關係事件"],
		["clockwork_ruins", "古代都市・機械遺跡｜齒輪、鐘網史"],
		["mistfall_depths", "四季鐘窟｜40 層戰鬥與封印"],
	]
	for destination: Array in destinations:
		var button := Button.new()
		button.text = String(destination[1])
		button.custom_minimum_size = Vector2(245, 42)
		button.pressed.connect(_on_travel_pressed.bind(StringName(destination[0])))
		grid.add_child(button)
	var note := Label.new()
	note.text = "夢岸需先釣齊四種異魚才會在異潮池邊顯現；它不是一般快速旅行地點。"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)


func _on_travel_pressed(map_id: StringName) -> void:
	EventBus.map_change_requested.emit(map_id, &"travel")
	close()


func _dictionary_lines(source: Dictionary, empty_text: String) -> String:
	var lines: PackedStringArray = []
	for item_id: String in source.keys():
		var count := int(source.get(item_id, 0))
		if count <= 0:
			continue
		var item := ContentRegistry.get_artifact("items", item_id)
		lines.append("%s ×%d" % [item.get("display_name", item_id), count])
	return empty_text if lines.is_empty() else "\n".join(lines)


func _relationship_text() -> String:
	var parts: PackedStringArray = []
	for candidate in ["mira", "lian", "soren", "yuna"]:
		parts.append("%s %d♥" % [ContentRegistry.get_artifact("characters", candidate).get("display_name", candidate), GameState.social.hearts(candidate)])
	var lines := PackedStringArray(["　".join(parts)])
	if NetworkManager.is_online():
		var multiplayer_data: Dictionary = NetworkManager.local_world_view().get("multiplayer", {})
		if String(multiplayer_data.get("relationship_mode", "independent")) == "competitive":
			var player_key := String(multiplayer_data.get("local_player_key", ""))
			var competition := PackedStringArray()
			for candidate: String in ["mira", "lian", "soren", "yuna"]:
				var board: Array = Dictionary(multiplayer_data.get("romance_boards", {})).get(candidate, [])
				for entry: Dictionary in board:
					if String(entry.get("player_key", "")) == player_key:
						competition.append("%s 第%d/%d" % [ContentRegistry.get_artifact("characters", candidate).get("display_name", candidate), entry.get("rank", 0), board.size()])
			if not competition.is_empty():
				lines.append("競爭追求：%s" % "　".join(competition))
			else:
				lines.append("競爭追求：和候選人交談後，追求排行會出現在這裡。")
	return "\n".join(lines)


func _achievement_text() -> String:
	var lines := PackedStringArray(["已解鎖 %d / %d" % [GameState.achievements.unlocked.size(), ContentRegistry.get_all("achievements").size()]])
	for achievement_id: String in GameState.achievements.unlocked:
		lines.append("★ %s" % ContentRegistry.get_artifact("achievements", achievement_id).get("display_name", achievement_id))
	if GameState.achievements.unlocked.is_empty():
		lines.append("遊玩、收成、探索與交友即可逐步解鎖。")
	return "\n".join(lines)


func _eldritch_journal_text() -> String:
	var tide_active: bool = GameState.eldritch.is_tide_active(GameState.calendar.day, GameState.calendar.minute_of_day, GameState.current_weather)
	var lines := PackedStringArray([
		"《無星異潮觀測錄》",
		"目前：%s　理智 %d/100　洞見 %d" % ["異潮湧現" if tide_active else "潮聲平穩", GameState.eldritch.sanity, GameState.eldritch.insight],
		"異魚圖鑑：%d/8　古神：%s" % [GameState.eldritch.eldritch_catches.size(), "已沉睡" if GameState.eldritch.boss_defeated else ("可於異潮池塘挑戰" if GameState.eldritch.boss_unlocked else "尚未顯形")],
		"異潮在每季 13、23、30 日 18:00 後，或霧暴夜出現；睡眠恢復理智，事件沒有期限。",
		"",
	])
	var eldritch_fish: Array[Dictionary] = []
	for fish: Dictionary in ContentRegistry.get_all("fish"):
		if bool(fish.get("tide_required", false)):
			eldritch_fish.append(fish)
	eldritch_fish.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.get("id", "")) < String(b.get("id", "")))
	for fish: Dictionary in eldritch_fish:
		var fish_id := String(fish.get("id", ""))
		if GameState.eldritch.eldritch_catches.has(fish_id):
			lines.append("◆ %s ×%d：%s" % [fish.get("display_name", fish_id), GameState.eldritch.eldritch_catches.get(fish_id, 0), fish.get("lore", "")])
		else:
			lines.append("◇ 未知異魚（%s）" % _season_name(Array(fish.get("seasons", ["?"]))[0]))
	return "\n".join(lines)


func _season_name(season_id: Variant) -> String:
	return {"spring":"春","summer":"夏","autumn":"秋","winter":"冬"}.get(String(season_id), String(season_id))


func _tool_summary() -> String:
	var entries := PackedStringArray()
	for tool_id in ["hoe", "watering_can", "axe", "pickaxe", "fishing_rod", "sickle"]:
		entries.append("%s%d" % [ContentRegistry.get_artifact("tools", tool_id).get("display_name", tool_id), GameState.tools.tool_levels.get(tool_id, 1)])
	return "、".join(entries)


func _on_volume_changed(value: float) -> void:
	GameState.settings["master_volume"] = value
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value, 0.001)))


func _on_fullscreen_toggled(enabled: bool) -> void:
	GameState.settings["fullscreen"] = enabled
	fullscreen_request_serial += 1
	_apply_fullscreen_mode(enabled, fullscreen_request_serial)


func _apply_fullscreen_mode(enabled: bool, request_serial: int) -> void:
	var target_mode := DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	# macOS may ignore a second mode request while its native fullscreen Space is
	# still animating. Reapply only the newest intent until the window confirms it.
	for _attempt in range(12):
		if request_serial != fullscreen_request_serial:
			return
		DisplayServer.window_set_mode(target_mode)
		await get_tree().create_timer(0.25, true).timeout
		if request_serial != fullscreen_request_serial:
			return
		if DisplayServer.window_get_mode() == target_mode:
			return


func _on_speed_pressed() -> void:
	GameState.cycle_time_speed()
	refresh()


func _load_and_refresh() -> void:
	SaveManager.load_quick()
	refresh()


func _on_farm_upgrade_pressed() -> void:
	if NetworkManager.is_online():
		NetworkManager.request_world_action("farm_upgrade")
		return
	var result := GameState.purchase_next_farm_upgrade()
	EventBus.toast(String(result.get("message", "")))
	refresh()


func _selected_candidate() -> StringName:
	return StringName(candidate_select.get_item_metadata(candidate_select.selected))


func _on_date_pressed() -> void:
	if NetworkManager.is_online():
		NetworkManager.request_world_action("court_npc", {"npc_id":String(_selected_candidate())})
		return
	var result := GameState.start_dating_candidate(_selected_candidate())
	EventBus.toast(String(result.get("message", "")))
	refresh()


func _on_propose_pressed() -> void:
	if NetworkManager.is_online():
		NetworkManager.request_world_action("propose_npc", {"npc_id":String(_selected_candidate())})
		return
	var result := GameState.propose_to_candidate(_selected_candidate())
	EventBus.toast(String(result.get("message", "")))
	refresh()


func _on_family_pressed() -> void:
	if NetworkManager.is_online():
		NetworkManager.request_world_action("family_event")
		return
	var result := GameState.advance_family()
	EventBus.toast(String(result.get("message", "")))
	refresh()


func _on_network_world_received(_world: Dictionary) -> void:
	if visible:
		refresh()


func _begin_rebind(action_id: StringName) -> void:
	capture_action = action_id
	var button: Button = rebind_buttons.get(String(action_id))
	button.text = "請輸入…"


func _refresh_rebind_labels() -> void:
	for action_id: String in rebind_buttons:
		var names := PackedStringArray()
		for event: InputEvent in InputMap.action_get_events(action_id):
			if event is InputEventKey:
				names.append(OS.get_keycode_string(event.physical_keycode if event.physical_keycode != 0 else event.keycode))
			elif event is InputEventJoypadButton:
				names.append("手把 %d" % event.button_index)
		var button: Button = rebind_buttons[action_id]
		button.text = " / ".join(names) if not names.is_empty() else "未設定"


func _reset_controls() -> void:
	PixelRPGInputBindings.reset_to_project_defaults()
	PixelRPGInputBindings.save()
	_refresh_rebind_labels()


func _selected_recipe() -> StringName:
	return &"" if recipe_select.item_count == 0 else StringName(recipe_select.get_item_metadata(recipe_select.selected))


func _refresh_recipe() -> void:
	if not is_instance_valid(recipe_select) or recipe_select.item_count == 0:
		return
	var recipe := ContentRegistry.get_artifact("recipes", _selected_recipe())
	recipe_icon.texture = ItemIconFactory.texture_for(_selected_recipe(), &"dish")
	var ingredients := PackedStringArray()
	for ingredient_id: String in Dictionary(recipe.get("ingredients", {})):
		ingredients.append("%s %d/%d" % [ContentRegistry.get_artifact("crops", ingredient_id).get("display_name", ingredient_id), GameState.farm.produce.get(ingredient_id, 0), recipe.ingredients[ingredient_id]])
	recipe_label.text = "需要：%s\n恢復體力：%d\n已完成：%d 份" % ["、".join(ingredients), recipe.get("energy", 0), GameState.farm.produce.get(String(_selected_recipe()), 0)]


func _on_recipe_selected(_index: int) -> void:
	_refresh_recipe()


func _on_cook_pressed() -> void:
	if NetworkManager.is_online():
		NetworkManager.request_world_action("cook", {"recipe_id":String(_selected_recipe())})
		return
	var result := GameState.cook_recipe(_selected_recipe())
	EventBus.toast(String(result.get("message", "")))
	refresh()


func _on_eat_pressed() -> void:
	if NetworkManager.is_online():
		NetworkManager.request_world_action("eat", {"recipe_id":String(_selected_recipe())})
		return
	var result := GameState.eat_dish(_selected_recipe())
	EventBus.toast(String(result.get("message", "")))
	refresh()
