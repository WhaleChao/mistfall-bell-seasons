class_name PixelRPGDialogueOverlay
extends CanvasLayer

var graph: Dictionary = {}
var nodes: Dictionary = {}
var current_node_id := ""
var accepted_quest := false
var portrait: TextureRect
var speaker_label: Label
var text_label: Label
var choices: VBoxContainer


func _ready() -> void:
	layer = 32
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_build_ui()
	visible = false
	EventBus.dialogue_requested.connect(open)


func open(dialogue_id: StringName, start_node: StringName = &"") -> void:
	graph = ContentRegistry.get_artifact("dialogues", dialogue_id)
	if graph.is_empty():
		EventBus.toast("找不到對話：%s" % dialogue_id)
		return
	nodes.clear()
	for node: Dictionary in graph.get("nodes", []):
		nodes[String(node.get("id", ""))] = node
	accepted_quest = false
	visible = true
	get_tree().paused = true
	GameState.pause_game_time(true)
	_show_node(String(start_node) if not String(start_node).is_empty() else String(graph.get("start_node", "")))


func open_line(speaker_id: StringName, line: String, heading: String = "") -> void:
	graph = {}
	nodes.clear()
	accepted_quest = false
	visible = true
	get_tree().paused = true
	GameState.pause_game_time(true)
	for child in choices.get_children():
		child.queue_free()
	var character := ContentRegistry.get_artifact("characters", speaker_id)
	speaker_label.text = heading if not heading.is_empty() else String(character.get("display_name", speaker_id))
	text_label.text = line
	_show_portrait(String(speaker_id))
	_add_button("結束對話", close)


func close() -> void:
	visible = false
	get_tree().paused = false
	GameState.pause_game_time(false)


func _show_node(node_id: String) -> void:
	current_node_id = node_id
	for child in choices.get_children():
		child.queue_free()
	var node: Dictionary = nodes.get(node_id, {})
	if node.is_empty():
		text_label.text = "對話節點遺失。"
		_add_button("關閉", close)
		return
	match String(node.get("type", "end")):
		"line":
			var speaker_id := String(node.get("speaker", ""))
			speaker_label.text = String(ContentRegistry.get_artifact("characters", speaker_id).get("display_name", speaker_id))
			text_label.text = String(node.get("text", ""))
			_show_portrait(speaker_id)
			_add_button("繼續", _show_node.bind(String(node.get("next", ""))))
		"choice":
			speaker_label.text = String(graph.get("title", "對話"))
			text_label.text = "你要怎麼回答？"
			for option: Dictionary in node.get("options", []):
				_add_button(String(option.get("text", "繼續")), _show_node.bind(String(option.get("next", ""))))
		"action":
			_execute_actions(node.get("actions", []))
			_show_node(String(node.get("next", "")))
		"end":
			speaker_label.text = "旅程紀錄"
			if accepted_quest:
				var result := GameState.try_complete_current_story_chapter()
				if bool(result.get("ok", false)):
					text_label.text = String(result.get("message", "章節完成"))
				else:
					var chapter: Dictionary = result.get("chapter", {})
					text_label.text = "任務已記入手冊。\n%s\n\n%s" % [chapter.get("title", graph.get("title", "")), "\n".join(PackedStringArray(chapter.get("objectives", [])))]
			else:
				text_label.text = "你決定稍後再談。主線沒有日期期限。"
			_add_button("關閉", close)
		_:
			text_label.text = "尚未支援的對話節點。"
			_add_button("關閉", close)


func _execute_actions(actions: Array) -> void:
	for action: Dictionary in actions:
		match String(action.get("type", "")):
			"quest":
				GameState.set_quest_state(StringName(action.get("quest_id", "")), StringName(action.get("state", "active")))
				accepted_quest = true
			"flag":
				GameState.set_flag(StringName(action.get("flag_id", "")), action.get("value", true))
			"give_item":
				GameState.add_item(StringName(action.get("item_id", "")), int(action.get("quantity", 1)))


func _show_portrait(speaker_id: String) -> void:
	var candidate_index: int = int({"mira": 0, "lian": 1, "soren": 2, "yuna": 3}.get(speaker_id, -1))
	portrait.visible = candidate_index >= 0
	if candidate_index < 0:
		return
	var region := AtlasTexture.new()
	region.atlas = load("res://assets/runtime/portraits/romance_candidates_atlas.png")
	region.region = Rect2(candidate_index * 512, 0, 512, 768)
	portrait.texture = region


func _add_button(label: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = label
	button.pressed.connect(callback)
	choices.add_child(button)
	button.call_deferred("grab_focus")


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.05, 0.46)
	shade.position = Vector2.ZERO
	shade.size = Vector2(640, 360)
	add_child(shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(48, 174)
	panel.size = Vector2(544, 164)
	add_child(panel)
	var row := HBoxContainer.new()
	panel.add_child(row)
	portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(108, 146)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var portrait_chroma := ShaderMaterial.new()
	portrait_chroma.shader = load("res://assets/shaders/chroma_transparency.gdshader")
	portrait.material = portrait_chroma
	row.add_child(portrait)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(body)
	speaker_label = Label.new()
	speaker_label.add_theme_font_size_override("font_size", 17)
	speaker_label.add_theme_color_override("font_color", Color("78dcca"))
	body.add_child(speaker_label)
	text_label = Label.new()
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_label.add_theme_font_size_override("font_size", 14)
	body.add_child(text_label)
	choices = VBoxContainer.new()
	body.add_child(choices)
