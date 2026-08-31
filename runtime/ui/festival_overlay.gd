class_name PixelRPGFestivalOverlay
extends CanvasLayer

var festival: Dictionary = {}
var marker_value := 0.0
var marker_direction := 1.0
var round_index := 0
var score_total := 0
var title_label: Label
var story_label: Label
var instruction_label: Label
var result_label: Label
var track: ColorRect
var target: ColorRect
var marker: ColorRect
var action_button: Button
var close_button: Button


func _ready() -> void:
	layer = 34
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_build_ui()
	visible = false


func open_today() -> void:
	festival = GameState.festivals.festival_on(GameState.calendar.season_id(), GameState.calendar.day)
	if festival.is_empty():
		EventBus.toast("今天沒有節慶")
		return
	if GameState.festivals.has_attended(StringName(festival.get("id", "")), GameState.calendar.year):
		EventBus.toast("今年已參加過這場節慶")
		return
	round_index = 0
	score_total = 0
	marker_value = 0.0
	marker_direction = 1.0
	title_label.text = String(festival.get("display_name", "節慶"))
	var variants: Array = festival.get("year_variants", [])
	story_label.text = "第 %d 年・%s" % [GameState.calendar.year, variants[mini(GameState.calendar.year, 3) - 1]]
	result_label.text = ""
	_update_instruction()
	action_button.visible = true
	close_button.visible = false
	track.visible = true
	target.visible = true
	marker.visible = true
	visible = true
	get_tree().paused = true
	GameState.pause_game_time(true)
	action_button.grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false
	GameState.pause_game_time(false)


func _process(delta: float) -> void:
	if not visible or not action_button.visible:
		return
	marker_value += delta * marker_direction * (0.72 + minf(GameState.calendar.year, 3) * 0.08)
	if marker_value >= 1.0:
		marker_value = 1.0
		marker_direction = -1.0
	elif marker_value <= 0.0:
		marker_value = 0.0
		marker_direction = 1.0
	marker.position.x = track.position.x + marker_value * (track.size.x - marker.size.x)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("attend_festival") or event.is_action_pressed("interact"):
		if action_button.visible:
			_attempt()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and close_button.visible:
		close()
		get_viewport().set_input_as_handled()


func _attempt() -> void:
	var target_value := float(festival.get("challenge_target", 65)) / 100.0
	var distance := absf(marker_value - target_value)
	var round_score := clampi(roundi(100.0 - distance * 190.0), 0, 100)
	score_total += round_score
	round_index += 1
	result_label.text = "第 %d 回合：%d 分　｜　累計 %d" % [round_index, round_score, score_total]
	marker_value = fmod(marker_value + 0.37 + round_index * 0.09, 1.0)
	marker_direction *= -1.0
	if round_index >= 5:
		_finish()
	else:
		_update_instruction()


func _finish() -> void:
	var average_score := roundi(float(score_total) / 5.0)
	var result: Dictionary = GameState.attend_today_festival(average_score)
	instruction_label.text = "活動完成・評價 %d / 100" % average_score
	result_label.text = String(result.get("message", "節慶活動完成"))
	action_button.visible = false
	track.visible = false
	target.visible = false
	marker.visible = false
	close_button.visible = true
	close_button.grab_focus()


func _update_instruction() -> void:
	var activity_text: String = {
		"timing": "看準時機完成動作",
		"rhythm": "跟著鐘聲落點",
		"showcase": "在評審注目時展示成果",
		"cooking": "掌握調味下鍋時機",
	}.get(String(festival.get("activity", "timing")), "看準時機")
	instruction_label.text = "%s：游標進入金色區域時按 F／E／手把 Y（%d / 5）" % [activity_text, round_index + 1]
	var target_value := float(festival.get("challenge_target", 65)) / 100.0
	target.position.x = track.position.x + clampf(target_value * track.size.x - target.size.x * 0.5, 0.0, track.size.x - target.size.x)


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.05, 0.72)
	shade.position = Vector2.ZERO
	shade.size = Vector2(640, 360)
	add_child(shade)
	var panel := Panel.new()
	panel.position = Vector2(72, 58)
	panel.size = Vector2(496, 250)
	add_child(panel)
	title_label = Label.new()
	title_label.position = Vector2(24, 18)
	title_label.size = Vector2(448, 34)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 23)
	title_label.add_theme_color_override("font_color", Color("fff1b6"))
	panel.add_child(title_label)
	story_label = Label.new()
	story_label.position = Vector2(28, 54)
	story_label.size = Vector2(440, 36)
	story_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_label.add_theme_font_size_override("font_size", 13)
	panel.add_child(story_label)
	instruction_label = Label.new()
	instruction_label.position = Vector2(24, 98)
	instruction_label.size = Vector2(448, 28)
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(instruction_label)
	track = ColorRect.new()
	track.position = Vector2(48, 138)
	track.size = Vector2(400, 18)
	track.color = Color("232a46")
	panel.add_child(track)
	target = ColorRect.new()
	target.position = Vector2(250, 136)
	target.size = Vector2(54, 22)
	target.color = Color(1.0, 0.79, 0.28, 0.75)
	panel.add_child(target)
	marker = ColorRect.new()
	marker.position = Vector2(48, 132)
	marker.size = Vector2(6, 30)
	marker.color = Color("78dcca")
	panel.add_child(marker)
	result_label = Label.new()
	result_label.position = Vector2(24, 166)
	result_label.size = Vector2(448, 28)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(result_label)
	action_button = Button.new()
	action_button.text = "就是現在！"
	action_button.position = Vector2(164, 202)
	action_button.size = Vector2(168, 34)
	action_button.pressed.connect(_attempt)
	panel.add_child(action_button)
	close_button = Button.new()
	close_button.text = "回到農場"
	close_button.position = Vector2(164, 202)
	close_button.size = Vector2(168, 34)
	close_button.pressed.connect(close)
	close_button.visible = false
	panel.add_child(close_button)
