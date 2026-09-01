class_name PixelRPGAutomationConsole
extends CanvasLayer

const ItemIconFactory := preload("res://runtime/ui/item_icon_factory.gd")
const PAUSE_OWNER := &"automation_console"

var panel: PanelContainer
var automation_grid: GridContainer
var automation_status_label: Label
var automation_device_select: OptionButton
var automation_crop_select: OptionButton
var automation_priority: SpinBox
var automation_enabled: CheckButton
var automation_tile_buttons: Dictionary = {}
var selected_automation_tile := Vector2i.ZERO


func _ready() -> void:
	layer = 31
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_build_ui()
	visible = false


func _exit_tree() -> void:
	GameState.set_pause_owner(PAUSE_OWNER, false)


func _input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("pause_menu") or event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		close()


func open() -> void:
	refresh()
	visible = true
	GameState.set_pause_owner(PAUSE_OWNER, true)
	automation_grid.get_child(0).grab_focus()


func close() -> void:
	visible = false
	GameState.set_pause_owner(PAUSE_OWNER, false)


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.05, 0.84)
	shade.position = Vector2.ZERO
	shade.size = Vector2(640, 360)
	add_child(shade)
	panel = PanelContainer.new()
	panel.position = Vector2(38, 24)
	panel.size = Vector2(564, 312)
	add_child(panel)
	var outer := VBoxContainer.new()
	panel.add_child(outer)
	var header := Label.new()
	header.text = "農場鐘網控制台　｜　場內設備建造與調度　｜　Esc／B／Start 關閉"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 15)
	header.add_theme_color_override("font_color", Color("fff1b6"))
	outer.add_child(header)
	var root := HBoxContainer.new()
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(root)
	var design_box := VBoxContainer.new()
	design_box.custom_minimum_size = Vector2(286, 0)
	root.add_child(design_box)
	var title := Label.new()
	title.text = "6×4 農田配置（選格後建造）"
	title.add_theme_font_size_override("font_size", 14)
	design_box.add_child(title)
	automation_grid = GridContainer.new()
	automation_grid.columns = PixelRPGFarmSystem.AUTOMATION_WIDTH
	design_box.add_child(automation_grid)
	for y in range(PixelRPGFarmSystem.AUTOMATION_HEIGHT):
		for x in range(PixelRPGFarmSystem.AUTOMATION_WIDTH):
			var tile := Vector2i(x, y)
			var button := Button.new()
			button.custom_minimum_size = Vector2(43, 30)
			button.text = "·"
			button.tooltip_text = "農田格 %d,%d" % [x + 1, y + 1]
			button.pressed.connect(_select_automation_tile.bind(tile))
			automation_grid.add_child(button)
			automation_tile_buttons["%d,%d" % [x, y]] = button
	automation_status_label = Label.new()
	automation_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	automation_status_label.add_theme_font_size_override("font_size", 11)
	automation_status_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	design_box.add_child(automation_status_label)
	var control_box := VBoxContainer.new()
	control_box.custom_minimum_size = Vector2(242, 0)
	root.add_child(control_box)
	var selected_label := Label.new()
	selected_label.text = "設備／作物／優先序"
	control_box.add_child(selected_label)
	automation_device_select = OptionButton.new()
	var devices := ContentRegistry.get_all("automation_devices")
	devices.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("required_rank", 10)) < int(b.get("required_rank", 10)) if int(a.get("required_rank", 10)) != int(b.get("required_rank", 10)) else String(a.get("id", "")) < String(b.get("id", ""))
	)
	for device: Dictionary in devices:
		automation_device_select.add_item("Lv.%d %s（%dG）" % [device.get("required_rank", 10), device.get("display_name", device.get("id", "")), device.get("cost", 0)])
		var device_index := automation_device_select.item_count - 1
		var device_id := StringName(device.get("id", ""))
		automation_device_select.set_item_metadata(device_index, String(device_id))
		automation_device_select.set_item_icon(device_index, ItemIconFactory.texture_for(device_id, &"automation", 28))
	control_box.add_child(automation_device_select)
	automation_crop_select = OptionButton.new()
	var crops := ContentRegistry.get_all("crops")
	crops.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.get("id", "")) < String(b.get("id", "")))
	for crop: Dictionary in crops:
		automation_crop_select.add_item("播種：%s" % crop.get("display_name", crop.get("id", "")))
		var crop_index := automation_crop_select.item_count - 1
		var crop_id := StringName(crop.get("id", ""))
		automation_crop_select.set_item_metadata(crop_index, String(crop_id))
		automation_crop_select.set_item_icon(crop_index, ItemIconFactory.texture_for(crop_id, &"seed", 28))
	control_box.add_child(automation_crop_select)
	automation_priority = SpinBox.new()
	automation_priority.min_value = 0
	automation_priority.max_value = 100
	automation_priority.step = 10
	automation_priority.value = 50
	automation_priority.prefix = "優先序 "
	control_box.add_child(automation_priority)
	automation_enabled = CheckButton.new()
	automation_enabled.text = "設備啟用"
	automation_enabled.button_pressed = true
	control_box.add_child(automation_enabled)
	var buttons := HBoxContainer.new()
	control_box.add_child(buttons)
	var place_button := Button.new()
	place_button.text = "建造"
	place_button.pressed.connect(_on_automation_place)
	buttons.add_child(place_button)
	var configure_button := Button.new()
	configure_button.text = "套用"
	configure_button.pressed.connect(_on_automation_configure)
	buttons.add_child(configure_button)
	var remove_button := Button.new()
	remove_button.text = "拆除"
	remove_button.pressed.connect(_on_automation_remove)
	buttons.add_child(remove_button)
	var explanation := Label.new()
	explanation.text = "相鄰設備會形成鐘能網。先放發電機與幫浦，再連接灑水、播種、收割、加工或餵食設備；每天睡前依優先序自動運作。"
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.add_theme_font_size_override("font_size", 10)
	control_box.add_child(explanation)
	_select_automation_tile(Vector2i.ZERO)


func refresh() -> void:
	if not is_instance_valid(automation_status_label):
		return
	var networks: Array[Dictionary] = GameState.farm.automation_networks()
	for key: String in automation_tile_buttons:
		var button: Button = automation_tile_buttons[key]
		var device: Dictionary = Dictionary(GameState.farm.automation_devices.get(key, {}))
		if device.is_empty():
			button.text = "·"
			button.tooltip_text = "空農田格 %s" % key
			continue
		var definition := ContentRegistry.get_artifact("automation_devices", StringName(device.get("device_id", "")))
		button.text = String(definition.get("symbol", "?"))
		button.tooltip_text = "%s｜%s｜優先 %d｜%s" % [definition.get("display_name", device.get("device_id", "")), device.get("network_id", "未連線"), device.get("priority", 50), "啟用" if bool(device.get("enabled", true)) else "停用"]
	var network_lines := PackedStringArray()
	for network: Dictionary in networks:
		network_lines.append("%s：%d 台｜電 %d/%d｜水 %d/%d｜%s" % [network.get("id", "網路"), network.get("device_count", 0), network.get("power_generation", 0), network.get("power_demand", 0), network.get("water_generation", 0), network.get("water_demand", 0), "平衡" if bool(network.get("balanced", false)) else "待調整"])
	var last: Dictionary = GameState.farm.automation_last_report
	automation_status_label.text = "選取：%d,%d　設備 %d／網路 %d\n%s\n上次：%s" % [selected_automation_tile.x + 1, selected_automation_tile.y + 1, GameState.farm.automation_devices.size(), networks.size(), "\n".join(network_lines) if not network_lines.is_empty() else "尚未配置網路", last.get("message", "尚未運作")]


func _select_automation_tile(tile: Vector2i) -> void:
	selected_automation_tile = tile
	var device: Dictionary = Dictionary(GameState.farm.automation_devices.get("%d,%d" % [tile.x, tile.y], {}))
	if not device.is_empty():
		for index in range(automation_device_select.item_count):
			if String(automation_device_select.get_item_metadata(index)) == String(device.get("device_id", "")):
				automation_device_select.select(index)
				break
		for index in range(automation_crop_select.item_count):
			if String(automation_crop_select.get_item_metadata(index)) == String(device.get("crop_filter", "")):
				automation_crop_select.select(index)
				break
		automation_priority.value = int(device.get("priority", 50))
		automation_enabled.set_pressed_no_signal(bool(device.get("enabled", true)))
	refresh()


func _automation_config() -> Dictionary:
	var crop_filter := ""
	if automation_crop_select.item_count > 0:
		crop_filter = String(automation_crop_select.get_item_metadata(automation_crop_select.selected))
	return {"enabled": automation_enabled.button_pressed, "priority": int(automation_priority.value), "crop_filter": crop_filter}


func _on_automation_place() -> void:
	if automation_device_select.item_count == 0:
		return
	var device_id := String(automation_device_select.get_item_metadata(automation_device_select.selected))
	if NetworkManager.is_online():
		NetworkManager.request_world_action("automation_place", {"x": selected_automation_tile.x, "y": selected_automation_tile.y, "device_id": device_id, "config": _automation_config()})
		return
	var result: Dictionary = GameState.purchase_automation_device(selected_automation_tile, StringName(device_id), _automation_config())
	EventBus.toast(String(result.get("message", "")))
	refresh()


func _on_automation_configure() -> void:
	var config := _automation_config()
	if NetworkManager.is_online():
		NetworkManager.request_world_action("automation_configure", {"x": selected_automation_tile.x, "y": selected_automation_tile.y, "config": config})
		return
	var result: Dictionary = GameState.configure_automation_device(selected_automation_tile, config)
	EventBus.toast(String(result.get("message", "")))
	refresh()


func _on_automation_remove() -> void:
	if NetworkManager.is_online():
		NetworkManager.request_world_action("automation_remove", {"x": selected_automation_tile.x, "y": selected_automation_tile.y})
		return
	var result: Dictionary = GameState.remove_automation_device(selected_automation_tile)
	EventBus.toast(String(result.get("message", "")))
	refresh()
