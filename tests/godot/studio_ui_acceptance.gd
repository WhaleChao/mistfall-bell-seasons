@tool
extends SceneTree

const REPORT_DIRECTORY := "res://reports/studio_ui"
const PAGE_SLUGS := [
	"project", "assets", "world", "database", "calendar", "npc_schedules",
	"crops", "festivals", "farm_upgrades", "family", "dungeon", "story",
	"ai", "tests", "export"
]

var checks: Array[Dictionary] = []
var screenshots: Array[String] = []
var screenshot_hashes: Dictionary = {}
var started_at := Time.get_ticks_msec()


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, category: String, name: String, details: String = "") -> void:
	checks.append({"category": category, "name": name, "passed": condition, "details": details})
	print("[%s] %s｜%s%s" % ["PASS" if condition else "FAIL", category, name, "｜" + details if not details.is_empty() else ""])


func _run() -> void:
	for _frame in range(20):
		await process_frame
	# --editor --script begins before the editor layout progress dialog has
	# completely settled. Wait for the real main window before testing UndoRedo.
	await create_timer(2.0).timeout
	var studio := root.find_child("PixelRPGStudioMain", true, false)
	_check(studio != null, "啟動", "EditorPlugin 已載入 PixelRPG Studio")
	if studio == null:
		_finish()
		return
	studio.editor_plugin.get_editor_interface().set_main_screen_editor("PixelRPG")
	for _frame in range(10):
		await process_frame
	_check(studio.is_visible_in_tree(), "啟動", "Godot 主畫面實際切換到 PixelRPG")

	_check(studio.pages.size() == 15, "導覽", "15 個製作頁面完整", "%d" % studio.pages.size())
	_check(studio.PAGE_NAMES.size() == 15, "導覽", "頁面名稱契約完整")
	_check(studio.manifest_editor != null and not studio.manifest_editor.text.is_empty(), "專案", "Manifest 已載入編輯器")
	var manifest: Variant = JSON.parse_string(studio.manifest_editor.text)
	_check(manifest is Dictionary and int(manifest.get("schema_version", 0)) == 1, "專案", "Manifest JSON 合法")

	var original_manifest := PixelRPGContentTools.read_text("res://data/project_manifest.json")
	if manifest is Dictionary:
		manifest["studio_acceptance_probe"] = true
		studio.manifest_editor.text = JSON.stringify(manifest, "\t", false) + "\n"
		studio._save_manifest()
		await process_frame
		_check("studio_acceptance_probe" in PixelRPGContentTools.read_text("res://data/project_manifest.json"), "UndoRedo", "Studio 保存動作實際寫入")
		var undo_manager: EditorUndoRedoManager = studio.editor_plugin.get_undo_redo()
		var history_id := undo_manager.get_object_history_id(studio)
		var undo_redo: UndoRedo = undo_manager.get_history_undo_redo(history_id)
		undo_redo.undo()
		await process_frame
		_check(PixelRPGContentTools.read_text("res://data/project_manifest.json") == original_manifest, "UndoRedo", "Ctrl+Z 路徑逐位元還原原檔")
		studio._load_manifest()

	var assets_json: Variant = JSON.parse_string(PixelRPGContentTools.read_text("res://data/assets/index.json"))
	var expected_assets := Array(assets_json.get("assets", [])).size() if assets_json is Dictionary else -1
	_check(studio.asset_list.item_count == expected_assets and expected_assets > 0, "素材", "素材庫 UI 與索引數量一致", "%d" % expected_assets)
	_check(studio.sprite_columns.value == 4 and studio.sprite_rows.value == 5 and studio.sprite_fps.value == 8, "素材", "精靈切割預設值可用")

	var database_types_ok := true
	var database_counts: Dictionary = {}
	for type_index in range(studio.DATA_TYPES.size()):
		studio.database_type.select(type_index)
		studio._reload_database()
		var display_type: String = studio.DATA_TYPES[type_index]
		database_counts[display_type] = studio.database_list.item_count
		if studio.database_list.item_count <= 0:
			database_types_ok = false
		var default_artifact := PixelRPGContentTools.default_artifact(display_type)
		if int(default_artifact.get("schema_version", 0)) != 1 or not studio._is_stable_id(String(default_artifact.get("id", ""))):
			database_types_ok = false
	_check(database_types_ok, "資料庫", "16 種資料均可載入並產生合法新建草稿", JSON.stringify(database_counts))

	var extended_ok: bool = studio.extended_editors.size() == 7
	for path: String in studio.extended_editors:
		var parsed: Variant = JSON.parse_string(studio.extended_editors[path].text)
		extended_ok = extended_ok and parsed is Dictionary and int(parsed.get("schema_version", 0)) == 1
	_check(extended_ok, "長期系統", "日曆、排程、作物、節慶、升級、家庭、洞窟頁均載入合法 JSON", "%d" % studio.extended_editors.size())

	var seasons_path := "res://data/seasons/seasons.json"
	var seasons_before := PixelRPGContentTools.read_text(seasons_path)
	studio.extended_editors[seasons_path].text = "{invalid"
	studio._save_extended(seasons_path)
	_check(PixelRPGContentTools.read_text(seasons_path) == seasons_before and "無效" in studio.status_label.text, "安全", "無效 JSON 不會寫入內容")
	studio.extended_editors[seasons_path].text = seasons_before
	studio._reload_extended(seasons_path)

	_check(studio.story_list.item_count >= 13, "劇情", "三年主線對話出現在節點圖清單", "%d" % studio.story_list.item_count)
	studio.story_list.select(0)
	studio._load_story()
	await process_frame
	var story_nodes := 0
	var story_positions: Array[Vector2] = []
	for child in studio.story_graph.get_children():
		if child is GraphNode:
			story_nodes += 1
			story_positions.append(child.position_offset)
	_check(story_nodes >= 2, "劇情", "DialogueGraph 實際轉為視覺節點", "%d" % story_nodes)
	studio._add_story_line()
	var story_nodes_after := 0
	var new_node_clear := false
	for child in studio.story_graph.get_children():
		if child is GraphNode:
			story_nodes_after += 1
			if child.position_offset not in story_positions:
				new_node_clear = true
				for existing_position in story_positions:
					new_node_clear = new_node_clear and child.position_offset.distance_to(existing_position) >= 180.0
	_check(story_nodes_after == story_nodes + 1, "劇情", "新增台詞節點可互動")
	_check(new_node_clear, "劇情", "新增台詞節點自動放在未重疊格位")

	var validation_ok: bool = studio._run_validation()
	_check(validation_ok and "✓" in studio.test_output.text, "測試", "Studio 內容與授權檢查通過")
	studio._run_export_gate()
	_check("Release Gate 通過" in studio.export_output.text, "匯出", "Studio Release Gate 通過")

	for page_index in range(mini(studio.pages.size(), PAGE_SLUGS.size())):
		# The editor restores its previously selected main screen asynchronously
		# after startup. Keep the evidence capture on PixelRPG instead of allowing
		# a late Asset Library restore to replace the tested surface.
		studio.editor_plugin.get_editor_interface().set_main_screen_editor("PixelRPG")
		studio._show_page(page_index)
		studio.move_to_front()
		for _frame in range(4):
			await process_frame
		var visible_count := 0
		for page in studio.pages:
			if page.visible:
				visible_count += 1
		var page: Control = studio.pages[page_index]
		_check(visible_count == 1 and page.visible and page.size.x >= 500 and page.size.y >= 300, "版面", "%02d %s 可顯示且沒有零尺寸" % [page_index + 1, studio.PAGE_NAMES[page_index]], "%sx%s" % [int(page.size.x), int(page.size.y)])
		await _capture("%02d_%s" % [page_index + 1, PAGE_SLUGS[page_index]])
	_check(screenshot_hashes.size() == screenshots.size(), "畫面", "15 個製作頁面像素內容互異", "%d/%d" % [screenshot_hashes.size(), screenshots.size()])

	studio._show_page(12)
	studio.ai_client.connect_service()
	var connected := false
	for _attempt in range(200):
		await create_timer(0.05).timeout
		if studio.ai_client.socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
			connected = true
			break
	_check(connected, "AI UI", "GDScript client 連接 localhost Creator Service")
	if connected:
		studio.ai_task.select(2)
		studio.ai_type.select(1)
		studio.ai_mode.select(1)
		studio.ai_prompt.text = "根據世界觀寫繁體中文短對話。只使用既有角色 hero 與 mira；精確建立 start 與 end 兩個節點，start 是 mira 的 line 並 next 指向 end，end 的 type 必須是 end。"
		studio._request_ai_draft()
		var ai_finished := false
		for _attempt in range(4800):
			await create_timer(0.05).timeout
			if "草稿完成" in studio.ai_status.text or studio.ai_status.text.begins_with("錯誤"):
				ai_finished = true
				break
		var parser := JSON.new()
		var draft: Variant = parser.data if parser.parse(studio.ai_draft.text) == OK else null
		_check(ai_finished and "草稿完成" in studio.ai_status.text, "AI UI", "Studio UI 收到完整 WebSocket 草稿", studio.ai_status.text)
		_check(draft is Dictionary and int(draft.get("schema_version", 0)) == 1, "AI UI", "Studio UI 草稿為合法 JSON")
		_check(not studio.ai_sources.text.is_empty() and not studio.ai_diff.text.is_empty(), "AI UI", "引用來源與差異面板有內容")
		studio._validate_ai_draft()
		_check("基本驗證通過" in studio.ai_status.text, "AI UI", "套用前本機驗證通過")
		studio.editor_plugin.get_editor_interface().set_main_screen_editor("PixelRPG")
		studio._show_page(12)
		studio.move_to_front()
		for _frame in range(5):
			await process_frame
		await _capture("13_ai_completed")
		_check(screenshot_hashes.size() == screenshots.size(), "畫面", "AI 完成畫面與其他頁面像素互異", "%d/%d" % [screenshot_hashes.size(), screenshots.size()])
		studio.ai_client.disconnect_service()

	_finish()


func _capture(file_stem: String) -> void:
	RenderingServer.force_draw(false)
	await process_frame
	var image := root.get_texture().get_image()
	var directory := ProjectSettings.globalize_path(REPORT_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(directory)
	var relative := "%s/%s.png" % [REPORT_DIRECTORY, file_stem]
	var error := image.save_png(ProjectSettings.globalize_path(relative))
	var sampled_colors: Dictionary = {}
	for y in range(0, image.get_height(), 24):
		for x in range(0, image.get_width(), 24):
			sampled_colors[image.get_pixel(x, y).to_rgba32()] = true
	var hashing_context := HashingContext.new()
	hashing_context.start(HashingContext.HASH_SHA256)
	hashing_context.update(image.get_data())
	var digest: String = hashing_context.finish().hex_encode()
	var non_blank := sampled_colors.size() >= 20
	_check(error == OK and image.get_width() > 0 and image.get_height() > 0 and non_blank, "畫面", "%s 截圖可解碼且非空白" % file_stem, "%dx%d｜%d sampled colors｜%s" % [image.get_width(), image.get_height(), sampled_colors.size(), digest.left(12)])
	if error == OK:
		screenshots.append(relative)
		screenshot_hashes[digest] = file_stem


func _finish() -> void:
	var failed := 0
	for item in checks:
		if not bool(item.passed):
			failed += 1
	var report := {
		"passed": checks.size() - failed,
		"failed": failed,
		"checks": checks,
		"screenshots": screenshots,
		"elapsed_seconds": (Time.get_ticks_msec() - started_at) / 1000.0,
		"renderer": RenderingServer.get_video_adapter_name(),
		"godot": Engine.get_version_info()
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIRECTORY))
	var report_file := FileAccess.open(REPORT_DIRECTORY + "/report.json", FileAccess.WRITE)
	if report_file:
		report_file.store_string(JSON.stringify(report, "\t", false) + "\n")
	var markdown := "# PixelRPG Studio 編輯器 UI 驗收\n\n結果：**%s**　｜　%d 通過／%d 失敗　｜　%d 張 UI 截圖\n\n| 分類 | 項目 | 結果 | 細節 |\n|---|---|---:|---|\n" % ["PASS" if failed == 0 else "FAIL", checks.size() - failed, failed, screenshots.size()]
	for item in checks:
		markdown += "| %s | %s | %s | %s |\n" % [item.category, String(item.name).replace("|", "\\|"), "通過" if item.passed else "失敗", String(item.details).replace("|", "\\|").replace("\n", " ")]
	var markdown_file := FileAccess.open(REPORT_DIRECTORY + "/REPORT.md", FileAccess.WRITE)
	if markdown_file:
		markdown_file.store_string(markdown)
	print("PixelRPG Studio UI gate: %s (%d/%d, %d screenshots)" % ["PASS" if failed == 0 else "FAIL", checks.size() - failed, checks.size(), screenshots.size()])
	call_deferred("_close_editor_cleanly", 0 if failed == 0 else 1)


func _close_editor_cleanly(exit_code: int) -> void:
	# Give EditorFileSystem time to finish importing the evidence images, then
	# exercise the editor's normal close path so renderer/UI resources teardown
	# in dependency order. The final quit is only a timeout fallback.
	await create_timer(2.0).timeout
	root.close_requested.emit()
	await create_timer(5.0).timeout
	quit(exit_code)
