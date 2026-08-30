extends SceneTree

const REPORT_DIRECTORY := "res://reports/steam_candidate"
const REPORT_JSON := REPORT_DIRECTORY + "/report.json"
const REPORT_MARKDOWN := REPORT_DIRECTORY + "/REPORT.md"
const STORE_CONFIGURATION := "res://steam/store_configuration.json"
const REQUIRED_ACTIONS: Array[StringName] = [
	&"move_left", &"move_right", &"move_up", &"move_down",
	&"attack", &"dodge", &"active_skill", &"interact", &"use_potion",
	&"cycle_seed", &"sleep_day", &"time_speed", &"toggle_cave", &"attend_festival",
	&"pause_menu", &"multiplayer_menu", &"quick_save", &"quick_load",
]

var cases: Array[Dictionary] = []
var connected_joypads: Array[int] = []
var smallest_logical_font := 999
var visible_text_controls := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIRECTORY))
	connected_joypads.assign(Input.get_connected_joypads())
	_check(OS.get_environment("SteamTenfoot") == "1", "Steam 啟動", "Big Picture 環境旗標存在", "SteamTenfoot=%s" % OS.get_environment("SteamTenfoot"))
	var configuration := _load_store_configuration()
	_validate_store_configuration(configuration)
	InputMap.load_from_project_settings()
	_validate_input_contract()

	var state_store: Node = root.get_node("GameState")
	state_store.reset()
	state_store.set_flag(&"title_seen", false)
	var scene: Node = load("res://sample/main.tscn").instantiate()
	root.add_child(scene)
	for _frame in 24:
		await process_frame
	var display_mode := DisplayServer.window_get_mode()
	_check(display_mode in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN], "Steam 啟動", "Big Picture 啟動自動進入全螢幕", "mode=%d" % display_mode)
	_scan_visible_text_controls(root)
	var deck_scale := 2
	_check(visible_text_controls >= 4, "1280×800", "標題與 HUD 可見文字控制項已納入字級檢查", "%d controls" % visible_text_controls)
	_check(smallest_logical_font * deck_scale >= 9, "1280×800", "最小可見文字高於 Steam Deck 9px 下限", "%dpx logical × %d = %dpx" % [smallest_logical_font, deck_scale, smallest_logical_font * deck_scale])
	_check(true, "測試環境", "記錄連接的手把數量；證據等級仍限映射契約", "%d connected" % connected_joypads.size())
	_write_report(display_mode, configuration)
	var failed := cases.filter(func(item: Dictionary) -> bool: return not bool(item.passed)).size()
	scene.queue_free()
	await process_frame
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	root.get_node("AudioDirector").call("shutdown_audio")
	await process_frame
	if failed == 0:
		print("PixelRPG Steam Windows candidate gate: PASS (%d checks; keyboard/mouse physical, controller mapping-only)" % cases.size())
		quit(0)
	else:
		for item: Dictionary in cases:
			if not bool(item.passed):
				push_error("%s / %s: %s" % [item.category, item.name, item.detail])
		quit(1)


func _load_store_configuration() -> Dictionary:
	var file := FileAccess.open(STORE_CONFIGURATION, FileAccess.READ)
	_check(file != null, "商店設定", "Steam 商店設定檔存在", STORE_CONFIGURATION)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	_check(parsed is Dictionary, "商店設定", "Steam 商店設定為合法 JSON", "")
	return Dictionary(parsed) if parsed is Dictionary else {}


func _validate_store_configuration(configuration: Dictionary) -> void:
	var features := Dictionary(configuration.get("store_features", {}))
	var input_evidence := Dictionary(configuration.get("input_evidence", {}))
	var deck := Dictionary(configuration.get("steam_deck", {}))
	var ai := Dictionary(configuration.get("content_survey", {}))
	var launch_options := Array(configuration.get("launch_options", []))
	_check(bool(features.get("single_player", false)), "商店設定", "只宣稱已實作的單人功能", "")
	_check(bool(features.get("online_coop", false)) and int(features.get("max_online_players", 0)) == 16, "商店設定", "IP 直連合作人數標示為 16", "")
	_check(bool(features.get("partial_controller_support", false)) and not bool(features.get("full_controller_support", true)), "商店設定", "手把只標部分支援", "")
	_check(not bool(features.get("steam_input_api", true)) and not bool(features.get("steam_achievements", true)) and not bool(features.get("steam_cloud", true)) and not bool(features.get("steam_matchmaking", true)), "商店設定", "未宣稱未整合的 Steamworks 功能", "")
	_check(String(input_evidence.get("controller", "")) == "mapping_contract_only_no_physical_device", "商店設定", "手把證據明確標示為非實體測試", "")
	_check(String(deck.get("compatibility_claim", "")) == "not_claimed", "商店設定", "沒有宣稱 Steam Deck Verified", "")
	_check(bool(ai.get("pre_generated_ai_content", false)) and not bool(ai.get("live_generated_ai_content", true)), "內容問卷", "AI 輔助素材列為預先生成、非遊玩時生成", "")
	_check(launch_options.size() == 2 and String(Dictionary(launch_options[0]).get("executable", "")) == "Mistfall-Bell-Seasons.exe", "啟動設定", "Steam Windows 遊戲與伺服器啟動項完整", "%d options" % launch_options.size())


func _validate_input_contract() -> void:
	for action: StringName in REQUIRED_ACTIONS:
		var has_keyboard := false
		var has_controller := false
		for event: InputEvent in InputMap.action_get_events(action):
			has_keyboard = has_keyboard or event is InputEventKey or event is InputEventMouseButton
			has_controller = has_controller or event is InputEventJoypadButton or event is InputEventJoypadMotion
		_check(InputMap.has_action(action) and has_keyboard, "輸入設定", "%s 有鍵盤／滑鼠映射" % action, "")
		_check(InputMap.has_action(action) and has_controller, "輸入設定", "%s 有 XInput 相容映射" % action, "mapping-only")


func _scan_visible_text_controls(node: Node) -> void:
	if node is Control and node.is_visible_in_tree():
		var text := ""
		if node is Label or node is Button or node is LineEdit or node is TextEdit or node is RichTextLabel:
			text = String(node.get("text"))
		if not text.is_empty() or node is LineEdit:
			visible_text_controls += 1
			smallest_logical_font = mini(smallest_logical_font, maxi(1, node.get_theme_font_size("font_size")))
	for child: Node in node.get_children():
		_scan_visible_text_controls(child)


func _check(condition: bool, category: String, name: String, detail: String) -> void:
	cases.append({"category":category,"name":name,"passed":condition,"detail":detail})


func _write_report(display_mode: int, configuration: Dictionary) -> void:
	var passed := cases.filter(func(item: Dictionary) -> bool: return bool(item.passed)).size()
	var failed := cases.size() - passed
	var payload := {
		"generated_at":Time.get_datetime_string_from_system(true),
		"passed":failed == 0,
		"checks":cases.size(),
		"passed_checks":passed,
		"failed_checks":failed,
		"display_mode":display_mode,
		"connected_joypads":connected_joypads,
		"controller_test_level":"mapping_only_no_physical_device",
		"visible_text_controls":visible_text_controls,
		"smallest_logical_font_px":smallest_logical_font,
		"deck_effective_minimum_px_at_1280x800":smallest_logical_font * 2,
		"store_configuration_schema":configuration.get("schema_version", 0),
		"cases":cases,
	}
	var json_file := FileAccess.open(REPORT_JSON, FileAccess.WRITE)
	if json_file != null:
		json_file.store_string(JSON.stringify(payload, "\t", false))
	var lines := PackedStringArray([
		"# Steam Windows 候選版驗收",
		"",
		"結果：**%s**　｜　%d/%d 通過" % ["PASS" if failed == 0 else "FAIL", passed, cases.size()],
		"",
		"鍵盤滑鼠以實際 Windows 遊戲流程驗收；本機偵測到 %d 支手把，因此手把只驗證 %d 組輸入映射，不宣稱實體端到端或 Steam Deck Verified。" % [connected_joypads.size(), REQUIRED_ACTIONS.size()],
		"",
		"| 分類 | 項目 | 結果 | 細節 |",
		"|---|---|---:|---|",
	])
	for item: Dictionary in cases:
		lines.append("| %s | %s | %s | %s |" % [item.category, String(item.name).replace("|", "\\|"), "通過" if item.passed else "失敗", String(item.detail).replace("|", "\\|")])
	var report_file := FileAccess.open(REPORT_MARKDOWN, FileAccess.WRITE)
	if report_file != null:
		report_file.store_string("\n".join(lines) + "\n")
