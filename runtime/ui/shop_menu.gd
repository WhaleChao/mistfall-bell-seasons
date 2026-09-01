class_name PixelRPGShopMenu
extends CanvasLayer

const ItemIconFactory := preload("res://runtime/ui/item_icon_factory.gd")
const PAUSE_OWNER := &"shop_menu"

var active_shop_id := StringName()
var title_label: Label
var coins_label: Label
var offer_box: VBoxContainer


func _ready() -> void:
	layer = 31
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_build_ui()
	visible = false
	NetworkManager.world_state_received.connect(_on_network_world_received)


func _exit_tree() -> void:
	GameState.set_pause_owner(PAUSE_OWNER, false)


func _input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("pause_menu") or event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		close()


func open(shop_id: StringName) -> void:
	if not GameState.shops.is_open(shop_id, GameState.calendar.minute_of_day):
		EventBus.toast("商店目前沒有營業")
		return
	active_shop_id = shop_id
	refresh()
	visible = true
	GameState.set_pause_owner(PAUSE_OWNER, true)
	if offer_box.get_child_count() > 0:
		offer_box.get_child(0).grab_focus()


func close() -> void:
	visible = false
	GameState.set_pause_owner(PAUSE_OWNER, false)


func refresh() -> void:
	var shop := ContentRegistry.get_artifact("shops", active_shop_id)
	title_label.text = "%s　　Esc／B 關閉" % shop.get("display_name", "商店")
	coins_label.text = "持有 %dG" % GameState.coins
	for child in offer_box.get_children():
		child.queue_free()
	for offer: Dictionary in GameState.shops.offers(active_shop_id, GameState.calendar.season_id(), GameState.farm.rank, GameState.tools.tool_levels):
		var button := Button.new()
		button.text = "%s　%dG" % [offer.get("display_name", "商品"), offer.get("price", 0)]
		var target_id := StringName(offer.get("target_id", ""))
		var offer_kind := StringName(offer.get("kind", "item"))
		button.icon = ItemIconFactory.texture_for(target_id, offer_kind, 32)
		button.expand_icon = true
		button.custom_minimum_size = Vector2(0, 40)
		button.tooltip_text = "%s\n%s" % [ItemIconFactory.display_name_for(target_id), ItemIconFactory.description_for(target_id)]
		button.disabled = GameState.coins < int(offer.get("price", 0))
		if offer_kind == &"animal" and GameState.farm.reserved_animal_slots() >= GameState.farm.animal_capacity():
			button.disabled = true
			button.text += "　（畜舍已滿）"
			button.tooltip_text += "\n目前容量 %d/%d；提升農場等級可擴建。" % [GameState.farm.animals.size(), GameState.farm.animal_capacity()]
		button.pressed.connect(_purchase.bind(String(offer.get("id", ""))))
		offer_box.add_child(button)
	if offer_box.get_child_count() == 0:
		var empty := Label.new()
		empty.text = "目前沒有可購買的商品。提升農場等級後再來看看。"
		offer_box.add_child(empty)


func _purchase(offer_id: String) -> void:
	if NetworkManager.is_online():
		NetworkManager.request_world_action("buy_offer", {"shop_id":String(active_shop_id), "offer_id":offer_id})
		return
	var result := GameState.buy_offer(active_shop_id, offer_id)
	EventBus.toast(String(result.get("message", "")))
	refresh()


func _on_network_world_received(_world: Dictionary) -> void:
	if visible:
		refresh()


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.05, 0.76)
	shade.position = Vector2.ZERO
	shade.size = Vector2(640, 360)
	add_child(shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(132, 40)
	panel.size = Vector2(376, 280)
	add_child(panel)
	var root_box := VBoxContainer.new()
	panel.add_child(root_box)
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 18)
	root_box.add_child(title_label)
	coins_label = Label.new()
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_box.add_child(coins_label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(scroll)
	offer_box = VBoxContainer.new()
	offer_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(offer_box)
