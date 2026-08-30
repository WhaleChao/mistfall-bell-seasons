class_name PixelRPGMultiplayerMenu
extends CanvasLayer

var name_input: LineEdit
var server_name_input: LineEdit
var address_input: LineEdit
var port_input: SpinBox
var max_clients_input: SpinBox
var world_input: LineEdit
var farm_mode_input: OptionButton
var relationship_mode_input: OptionButton
var host_button: Button
var join_button: Button
var disconnect_button: Button
var status_label: Label
var roster_label: Label
var narrative_label: Label


func _ready() -> void:
	layer = 45
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false
	NetworkManager.status_changed.connect(_on_status_changed)
	NetworkManager.roster_changed.connect(_on_roster_changed)
	NetworkManager.world_state_received.connect(_on_world_state_received)
	_refresh_state()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("multiplayer_menu") or event.is_action_pressed("pause_menu")):
		get_viewport().set_input_as_handled()
		close()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	name_input.text = String(GameState.player_profile.get("name", "旅人"))
	visible = true
	get_tree().paused = true
	GameState.pause_game_time(true)
	_refresh_state()
	name_input.grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false
	GameState.pause_game_time(false)


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.045, 0.9)
	shade.position = Vector2.ZERO
	shade.size = Vector2(640, 360)
	add_child(shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(68, 24)
	panel.size = Vector2(504, 312)
	add_child(panel)
	var root_box := VBoxContainer.new()
	panel.add_child(root_box)
	var title := Label.new()
	title.text = "霧落連線世界｜自行開服・IP 直連"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	root_box.add_child(title)
	var security := Label.new()
	security.text = "信任的朋友／LAN 優先。UDP 27180；公開上網需路由器連接埠轉送。"
	security.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	security.add_theme_font_size_override("font_size", 11)
	root_box.add_child(security)
	var grid := GridContainer.new()
	grid.columns = 4
	root_box.add_child(grid)
	_add_grid_label(grid, "玩家名稱")
	name_input = _add_line_edit(grid, "旅人", 16)
	_add_grid_label(grid, "世界名稱")
	world_input = _add_line_edit(grid, "mistfall", 32)
	_add_grid_label(grid, "伺服器名稱")
	server_name_input = _add_line_edit(grid, "朋友的霧落村", 32)
	_add_grid_label(grid, "人數上限")
	max_clients_input = SpinBox.new()
	max_clients_input.min_value = 1
	max_clients_input.max_value = PixelRPGNetworkManager.MAX_CLIENTS_LIMIT
	max_clients_input.value = PixelRPGNetworkManager.DEFAULT_MAX_CLIENTS
	grid.add_child(max_clients_input)
	_add_grid_label(grid, "伺服器 IP")
	address_input = _add_line_edit(grid, "127.0.0.1", 255)
	_add_grid_label(grid, "UDP 埠")
	port_input = SpinBox.new()
	port_input.min_value = 1024
	port_input.max_value = 65535
	port_input.value = PixelRPGNetworkManager.DEFAULT_PORT
	grid.add_child(port_input)
	_add_grid_label(grid, "農場制度")
	farm_mode_input = OptionButton.new()
	for option: Dictionary in [{"id":"shared","text":"共同整合"},{"id":"private","text":"各自獨立"},{"id":"competitive","text":"各自競賽"}]:
		farm_mode_input.add_item(option.text)
		farm_mode_input.set_item_metadata(farm_mode_input.item_count - 1, option.id)
	grid.add_child(farm_mode_input)
	_add_grid_label(grid, "關係制度")
	relationship_mode_input = OptionButton.new()
	for option: Dictionary in [{"id":"independent","text":"每人獨立"},{"id":"competitive","text":"競爭追求"}]:
		relationship_mode_input.add_item(option.text)
		relationship_mode_input.set_item_metadata(relationship_mode_input.item_count - 1, option.id)
	grid.add_child(relationship_mode_input)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	root_box.add_child(actions)
	host_button = Button.new()
	host_button.text = "開設主機"
	host_button.pressed.connect(_on_host_pressed)
	actions.add_child(host_button)
	join_button = Button.new()
	join_button.text = "用 IP 加入"
	join_button.pressed.connect(_on_join_pressed)
	actions.add_child(join_button)
	disconnect_button = Button.new()
	disconnect_button.text = "離線／關服"
	disconnect_button.pressed.connect(_on_disconnect_pressed)
	actions.add_child(disconnect_button)
	var close_button := Button.new()
	close_button.text = "返回遊戲"
	close_button.pressed.connect(close)
	actions.add_child(close_button)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Color("9de7ff"))
	root_box.add_child(status_label)
	roster_label = Label.new()
	roster_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	roster_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	roster_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(roster_label)
	narrative_label = Label.new()
	narrative_label.text = "劇情會依在線人數與農場／關係制度即時分支。"
	narrative_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	narrative_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	narrative_label.add_theme_font_size_override("font_size", 10)
	narrative_label.add_theme_color_override("font_color", Color("ffd99d"))
	root_box.add_child(narrative_label)
	var guide := Label.new()
	guide.text = "專用伺服器：EXE --headless -- --server --port=27180 --world=mistfall\n傳輸不含 TLS／帳號系統；請勿把常用密碼當伺服器名稱或玩家名稱。"
	guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide.add_theme_font_size_override("font_size", 10)
	guide.add_theme_color_override("font_color", Color("c9b8d9"))
	root_box.add_child(guide)


func _add_grid_label(grid: GridContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	grid.add_child(label)


func _add_line_edit(grid: GridContainer, placeholder: String, max_length: int) -> LineEdit:
	var input := LineEdit.new()
	input.placeholder_text = placeholder
	input.max_length = max_length
	input.custom_minimum_size.x = 150
	grid.add_child(input)
	return input


func _on_host_pressed() -> void:
	_apply_player_name()
	var selected_farm_mode := String(farm_mode_input.get_item_metadata(farm_mode_input.selected))
	var selected_relationship_mode := String(relationship_mode_input.get_item_metadata(relationship_mode_input.selected))
	var result := NetworkManager.host_server(int(port_input.value), int(max_clients_input.value), server_name_input.text, name_input.text, false, world_input.text, selected_farm_mode, selected_relationship_mode)
	if not bool(result.get("ok", false)):
		_on_status_changed(String(result.get("message", "開服失敗")))
	_refresh_state()


func _on_join_pressed() -> void:
	_apply_player_name()
	var result := NetworkManager.join_server(address_input.text, int(port_input.value), name_input.text)
	if not bool(result.get("ok", false)):
		_on_status_changed(String(result.get("message", "連線失敗")))
	_refresh_state()


func _on_disconnect_pressed() -> void:
	NetworkManager.stop()
	_refresh_state()


func _apply_player_name() -> void:
	var chosen := name_input.text.strip_edges()
	GameState.player_profile["name"] = chosen if not chosen.is_empty() else "旅人"


func _on_status_changed(message: String) -> void:
	status_label.text = message
	_refresh_state()


func _on_roster_changed(roster: Array[Dictionary]) -> void:
	var names: Array[String] = []
	for player: Dictionary in roster:
		names.append("%s (#%d)" % [player.get("name", "旅人"), player.get("peer_id", 0)])
	roster_label.text = "在線玩家（%d）：%s" % [roster.size(), "、".join(names)] if not roster.is_empty() else "目前沒有連線玩家"


func _on_world_state_received(world: Dictionary) -> void:
	var multiplayer_data: Dictionary = world.get("multiplayer", {})
	var story: Dictionary = multiplayer_data.get("story_variant", world.get("story_variant", {}))
	if story.is_empty():
		return
	var farm_text: String = {"shared":"共同農場","private":"私人農場","competitive":"競賽農場"}.get(String(multiplayer_data.get("farm_mode", NetworkManager.farm_mode)), "共同農場")
	var relationship_text: String = "競爭追求" if String(multiplayer_data.get("relationship_mode", NetworkManager.relationship_mode)) == "competitive" else "獨立關係"
	var leaders := PackedStringArray()
	for entry: Dictionary in Array(multiplayer_data.get("farm_leaderboard", [])).slice(0, 3):
		leaders.append("%d.%s %d" % [entry.get("rank", 0), entry.get("name", "旅人"), entry.get("score", 0)])
	var leaderboard_text: String = "｜排行 %s" % "／".join(leaders) if not leaders.is_empty() else ""
	narrative_label.text = "%s（%d 人）｜%s／%s%s：%s" % [story.get("title", "多人篇章"), story.get("player_count", 1), farm_text, relationship_text, leaderboard_text, story.get("intro", "")]


func _refresh_state() -> void:
	if not is_instance_valid(status_label):
		return
	if status_label.text.is_empty():
		status_label.text = NetworkManager.connection_summary()
	var online := NetworkManager.is_online()
	host_button.disabled = online
	join_button.disabled = online
	disconnect_button.disabled = not online
	farm_mode_input.disabled = online
	relationship_mode_input.disabled = online
