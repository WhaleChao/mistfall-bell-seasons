@tool
extends Control

const CreatorClient := preload("res://addons/pixelrpg_studio/creator_client.gd")
const ContentTools := preload("res://addons/pixelrpg_studio/content_tools.gd")
const PAGE_NAMES := ["專案", "素材／參考庫", "世界", "資料庫", "日曆", "NPC 排程", "農作", "節慶", "農場升級", "家庭", "洞窟", "劇情", "AI", "測試", "匯出"]
const DATA_TYPES := ["角色", "敵人", "物品", "技能", "任務", "對話", "世界事件", "作物", "魚類", "動物", "NPC 排程", "節慶", "農場升級", "洞窟", "委託模板", "料理"]

var editor_plugin: EditorPlugin
var pages: Array[Control] = []
var status_label: Label
var manifest_editor: TextEdit
var asset_list: ItemList
var asset_license: LineEdit
var asset_dialog: FileDialog
var sprite_columns: SpinBox
var sprite_rows: SpinBox
var sprite_fps: SpinBox
var sprite_directions: OptionButton
var database_type: OptionButton
var database_list: ItemList
var database_editor: TextEdit
var database_path := ""
var story_list: OptionButton
var story_graph: GraphEdit
var story_path := ""
var ai_client: PixelRPGCreatorClient
var ai_status: Label
var ai_task: OptionButton
var ai_type: OptionButton
var ai_mode: OptionButton
var ai_prompt: TextEdit
var ai_image_path: LineEdit
var ai_draft: TextEdit
var ai_sources: TextEdit
var ai_diff: TextEdit
var test_output: TextEdit
var export_output: RichTextLabel
var extended_editors: Dictionary = {}


func _ready() -> void:
	_build_interface()
	ai_client = CreatorClient.new()
	add_child(ai_client)
	ai_client.status_changed.connect(_on_ai_status_changed)
	ai_client.event_received.connect(_on_ai_event)
	_reload_assets()
	_reload_database()
	_reload_story_list()
	_load_manifest()


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("151929")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := HBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size.x = 188
	sidebar.add_theme_constant_override("separation", 5)
	root.add_child(sidebar)
	var brand := Label.new()
	brand.text = "  PIXELRPG\n  STUDIO"
	brand.custom_minimum_size.y = 68
	brand.add_theme_font_size_override("font_size", 19)
	brand.add_theme_color_override("font_color", Color("78dcca"))
	sidebar.add_child(brand)

	var page_holder := MarginContainer.new()
	page_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_holder.add_theme_constant_override("margin_left", 20)
	page_holder.add_theme_constant_override("margin_right", 20)
	page_holder.add_theme_constant_override("margin_top", 16)
	page_holder.add_theme_constant_override("margin_bottom", 16)
	root.add_child(page_holder)
	var stack := Control.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_holder.add_child(stack)

	for index in range(PAGE_NAMES.size()):
		var button := Button.new()
		button.text = PAGE_NAMES[index]
		button.custom_minimum_size = Vector2(176, 34)
		button.pressed.connect(_show_page.bind(index))
		sidebar.add_child(button)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_child(spacer)
	status_label = Label.new()
	status_label.text = "schema v1 · offline-first"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(170, 44)
	status_label.add_theme_color_override("font_color", Color("8291aa"))
	sidebar.add_child(status_label)

	pages = [
		_build_project_page(), _build_assets_page(), _build_world_page(), _build_database_page(),
		_build_extended_page("30 日曆預覽", "四季固定各 30 日；速度只影響實際分鐘，不影響模擬結果。", "res://data/seasons/seasons.json", "每年 120 日｜06:00–24:00｜快速 10 分／標準 15 分／悠閒 20 分"),
		_build_extended_page("NPC 排程", "10 名主要 NPC 的平日與雨天位置；戀愛不受玩家外觀限制。", "res://data/npc_schedules/npcs.json", "戀愛候選：Mira、Lian、Soren、Yuna｜好感上限 10 心"),
		_build_extended_page("作物成長", "四季各 12 種作物；季末枯萎、跨季標記與溫室例外由 Runtime 統一處理。", "res://data/crops/crops.json", "每季：快速 3｜中期 4｜長期 2｜再生 2｜稀有 1"),
		_build_extended_page("節慶", "每季 8、18、28 日舉行三場節慶；29、30 日保留整理與角色事件。", "res://data/festivals/festivals.json", "12 場節慶｜前三年各有變體｜錯過不阻斷主線"),
		_build_extended_page("農場升級", "農場等級 1–10，解鎖土地、雞舍、牛舍、加工、溫室與快捷移動。", "res://data/farm_upgrades/upgrades.json", "Lv.3 雞舍｜Lv.6 牛舍｜Lv.8 溫室｜Lv.10 四季鐘塔農莊"),
		_build_extended_page("婚姻與家庭", "婚後 30 日可討論家庭，再過至少 30 日迎接一名孩子。", "res://data/family/family_policy.json", "嬰兒 0–29｜幼兒 30–89｜兒童 90–209｜青少年 210+"),
		_build_extended_page("四季鐘窟", "40 層四季洞窟；每 5 層電梯、每 10 層 Boss，四枚封印後開放最終戰。", "res://data/dungeons/mistfall_depths.json", "Boss：10／20／30／40F｜無主線期限｜通關後無限挑戰"),
		_build_story_page(), _build_ai_page(), _build_test_page(), _build_export_page()
	]
	for page in pages:
		page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		stack.add_child(page)
	_show_page(0)


func _page(title: String, subtitle: String) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 10)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 24)
	heading.add_theme_color_override("font_color", Color("fff1b6"))
	page.add_child(heading)
	var description := Label.new()
	description.text = subtitle
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", Color("aab7cc"))
	page.add_child(description)
	return page


func _show_page(index: int) -> void:
	for page_index in range(pages.size()):
		pages[page_index].visible = page_index == index


func _build_project_page() -> Control:
	var page := _page("專案首頁", "固定 640×360、32px tiles、60 FPS；所有內容都以版本化 JSON 保存。")
	var buttons := HBoxContainer.new()
	page.add_child(buttons)
	var play := Button.new()
	play.text = "執行《霧落農歌》"
	play.pressed.connect(func() -> void: editor_plugin.get_editor_interface().play_main_scene())
	buttons.add_child(play)
	var reload := Button.new()
	reload.text = "重新載入 Manifest"
	reload.pressed.connect(_load_manifest)
	buttons.add_child(reload)
	var save := Button.new()
	save.text = "保存（可復原）"
	save.pressed.connect(_save_manifest)
	buttons.add_child(save)
	manifest_editor = TextEdit.new()
	manifest_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	manifest_editor.add_theme_font_size_override("font_size", 14)
	page.add_child(manifest_editor)
	return page


func _build_assets_page() -> Control:
	var page := _page("素材／參考庫", "拖入原始檔時保存雜湊、授權與來源；未填授權的素材會阻止 release 檢查。")
	var buttons := HBoxContainer.new()
	page.add_child(buttons)
	var import_button := Button.new()
	import_button.text = "匯入檔案…"
	import_button.pressed.connect(_open_asset_dialog)
	buttons.add_child(import_button)
	var refresh := Button.new()
	refresh.text = "重新整理"
	refresh.pressed.connect(_reload_assets)
	buttons.add_child(refresh)
	var license_label := Label.new()
	license_label.text = "SPDX："
	buttons.add_child(license_label)
	asset_license = LineEdit.new()
	asset_license.placeholder_text = "例如 CC0-1.0 / MIT / Proprietary"
	asset_license.custom_minimum_size.x = 250
	buttons.add_child(asset_license)
	var save_license := Button.new()
	save_license.text = "更新授權"
	save_license.pressed.connect(_save_asset_license)
	buttons.add_child(save_license)
	var sprite_controls := HBoxContainer.new()
	page.add_child(sprite_controls)
	var sprite_hint := Label.new()
	sprite_hint.text = "精靈切割：欄"
	sprite_controls.add_child(sprite_hint)
	sprite_columns = SpinBox.new()
	sprite_columns.min_value = 1
	sprite_columns.max_value = 32
	sprite_columns.value = 4
	sprite_controls.add_child(sprite_columns)
	var row_hint := Label.new()
	row_hint.text = "列"
	sprite_controls.add_child(row_hint)
	sprite_rows = SpinBox.new()
	sprite_rows.min_value = 1
	sprite_rows.max_value = 32
	sprite_rows.value = 5
	sprite_controls.add_child(sprite_rows)
	var fps_hint := Label.new()
	fps_hint.text = "FPS"
	sprite_controls.add_child(fps_hint)
	sprite_fps = SpinBox.new()
	sprite_fps.min_value = 1
	sprite_fps.max_value = 60
	sprite_fps.value = 8
	sprite_controls.add_child(sprite_fps)
	sprite_directions = OptionButton.new()
	sprite_directions.add_item("4 方向")
	sprite_directions.set_item_metadata(0, 4)
	sprite_directions.add_item("8 方向")
	sprite_directions.set_item_metadata(1, 8)
	sprite_controls.add_child(sprite_directions)
	var sprite_import := Button.new()
	sprite_import.text = "建立 runtime 精靈描述"
	sprite_import.pressed.connect(_build_sprite_descriptor)
	sprite_controls.add_child(sprite_import)
	asset_list = ItemList.new()
	asset_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	asset_list.item_selected.connect(_on_asset_selected)
	page.add_child(asset_list)
	asset_dialog = FileDialog.new()
	asset_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	asset_dialog.access = FileDialog.ACCESS_FILESYSTEM
	asset_dialog.use_native_dialog = true
	asset_dialog.filters = PackedStringArray(["*.png,*.jpg,*.jpeg,*.webp ; 圖片", "*.pdf,*.docx,*.pptx,*.xlsx,*.csv,*.md,*.txt ; 文件", "*.* ; 所有檔案"])
	asset_dialog.files_selected.connect(_import_assets)
	page.add_child(asset_dialog)
	return page


func _build_world_page() -> Control:
	var page := _page("世界", "首版直接使用 Godot TileMapLayer、碰撞、出生點、傳送點與 WorldEvent，不重做地圖渲染器。")
	var open_sample := Button.new()
	open_sample.text = "在 2D 編輯器開啟 sample/main.tscn"
	open_sample.pressed.connect(func() -> void: editor_plugin.get_editor_interface().open_scene_from_path("res://sample/main.tscn"))
	page.add_child(open_sample)
	var help := RichTextLabel.new()
	help.bbcode_enabled = true
	help.fit_content = true
	help.text = "[color=#78dcca]無程式事件[/color]\n觸發器 → 條件 → 白名單動作\n\n支援：對話、旗標、任務、物品、地圖切換、角色生成／移除、動畫、音效、過場。\nWorldEvent 存在 [code]data/world_events/[/code]，執行層只接受 schema 中列出的動作。"
	page.add_child(help)
	return page


func _build_extended_page(title: String, subtitle: String, path: String, summary: String) -> Control:
	var page := _page(title, subtitle)
	var overview := Label.new()
	overview.text = summary
	overview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overview.add_theme_color_override("font_color", Color("78dcca"))
	page.add_child(overview)
	var controls := HBoxContainer.new()
	page.add_child(controls)
	var reload := Button.new()
	reload.text = "重新載入"
	reload.pressed.connect(_reload_extended.bind(path))
	controls.add_child(reload)
	var save := Button.new()
	save.text = "驗證並保存（可復原）"
	save.pressed.connect(_save_extended.bind(path))
	controls.add_child(save)
	var path_label := Label.new()
	path_label.text = path
	path_label.add_theme_color_override("font_color", Color("8291aa"))
	controls.add_child(path_label)
	var editor := TextEdit.new()
	editor.text = ContentTools.read_text(path)
	editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor.add_theme_font_size_override("font_size", 13)
	page.add_child(editor)
	extended_editors[path] = editor
	return page


func _reload_extended(path: String) -> void:
	var editor: TextEdit = extended_editors.get(path)
	if is_instance_valid(editor):
		editor.text = ContentTools.read_text(path)
		_set_status("已重新載入：%s" % path)


func _save_extended(path: String) -> void:
	var editor: TextEdit = extended_editors.get(path)
	if not is_instance_valid(editor):
		return
	var parser := JSON.new()
	if parser.parse(editor.text) != OK:
		_set_status("JSON 無效或缺少 schema_version: 1", true)
		return
	var parsed: Variant = parser.data
	if not parsed is Dictionary or int(parsed.get("schema_version", 0)) != 1:
		_set_status("JSON 無效或缺少 schema_version: 1", true)
		return
	_commit_text(path, JSON.stringify(parsed, "\t", false) + "\n", "更新 %s" % path.get_file())


func _build_database_page() -> Control:
	var page := _page("內容資料庫", "表單採穩定字串 ID；進階欄位可在右側 JSON 編輯，保存時會先檢查基本契約。")
	var controls := HBoxContainer.new()
	page.add_child(controls)
	database_type = OptionButton.new()
	for value in DATA_TYPES:
		database_type.add_item(value)
	database_type.item_selected.connect(func(_index: int) -> void: _reload_database())
	controls.add_child(database_type)
	var new_button := Button.new()
	new_button.text = "新增"
	new_button.pressed.connect(_new_artifact)
	controls.add_child(new_button)
	var save := Button.new()
	save.text = "驗證並保存（可復原）"
	save.pressed.connect(_save_database_artifact)
	controls.add_child(save)
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(split)
	database_list = ItemList.new()
	database_list.custom_minimum_size.x = 250
	database_list.item_selected.connect(_load_database_selection)
	split.add_child(database_list)
	database_editor = TextEdit.new()
	database_editor.add_theme_font_size_override("font_size", 14)
	database_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(database_editor)
	return page


func _build_story_page() -> Control:
	var page := _page("劇情節點圖", "節點圖保存為 DialogueGraph；未知欄位會原樣保留，方便 adapter 編譯成 Dialogue Manager 資源。")
	var controls := HBoxContainer.new()
	page.add_child(controls)
	story_list = OptionButton.new()
	story_list.custom_minimum_size.x = 280
	controls.add_child(story_list)
	var load_button := Button.new()
	load_button.text = "載入"
	load_button.pressed.connect(_load_story)
	controls.add_child(load_button)
	var add_button := Button.new()
	add_button.text = "新增台詞節點"
	add_button.pressed.connect(_add_story_line)
	controls.add_child(add_button)
	var save_button := Button.new()
	save_button.text = "保存圖（可復原）"
	save_button.pressed.connect(_save_story)
	controls.add_child(save_button)
	story_graph = GraphEdit.new()
	story_graph.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story_graph.show_grid = true
	story_graph.minimap_enabled = true
	page.add_child(story_graph)
	return page


func _build_ai_page() -> Control:
	var page := _page("本機 AI 助手", "AI 只產生草稿；引用、差異、驗證都可見，按下套用後才經 Undo/Redo 寫入專案。")
	var controls := HBoxContainer.new()
	page.add_child(controls)
	var connect_button := Button.new()
	connect_button.text = "連接本機服務"
	connect_button.pressed.connect(func() -> void: ai_client.connect_service())
	controls.add_child(connect_button)
	ai_task = OptionButton.new()
	for task in ["世界觀問答", "角色卡草稿", "對話草稿", "任務草稿", "物品描述", "矛盾檢查"]:
		ai_task.add_item(task)
	controls.add_child(ai_task)
	ai_type = OptionButton.new()
	var artifact_types := ["characters", "dialogues", "quests", "items", "skills", "world_events"]
	for artifact_type in artifact_types:
		ai_type.add_item(artifact_type)
		ai_type.set_item_metadata(ai_type.item_count - 1, artifact_type)
	controls.add_child(ai_type)
	ai_mode = OptionButton.new()
	ai_mode.add_item("品質 9B")
	ai_mode.set_item_metadata(0, "quality")
	ai_mode.add_item("快速 4B")
	ai_mode.set_item_metadata(1, "fast")
	controls.add_child(ai_mode)
	var generate := Button.new()
	generate.text = "產生草稿"
	generate.pressed.connect(_request_ai_draft)
	controls.add_child(generate)
	var validate := Button.new()
	validate.text = "驗證草稿"
	validate.pressed.connect(_validate_ai_draft)
	controls.add_child(validate)
	var apply_button := Button.new()
	apply_button.text = "套用（可復原）"
	apply_button.pressed.connect(_apply_ai_draft)
	controls.add_child(apply_button)
	ai_status = Label.new()
	ai_status.text = "尚未連線；遊戲與其他編輯功能不受影響。"
	ai_status.add_theme_color_override("font_color", Color("ffcf5c"))
	page.add_child(ai_status)
	ai_image_path = LineEdit.new()
	ai_image_path.placeholder_text = "選用圖片路徑（專案內）：例如 assets/source/portrait.png"
	page.add_child(ai_image_path)
	ai_prompt = TextEdit.new()
	ai_prompt.placeholder_text = "例：根據世界觀，替米拉產生一段委託玩家調查鐘塔的對話；語氣克制而溫柔。"
	ai_prompt.custom_minimum_size.y = 82
	page.add_child(ai_prompt)
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(split)
	ai_draft = TextEdit.new()
	ai_draft.placeholder_text = "AI 結構化草稿"
	split.add_child(ai_draft)
	var right := VBoxContainer.new()
	split.add_child(right)
	ai_sources = TextEdit.new()
	ai_sources.placeholder_text = "引用來源"
	ai_sources.editable = false
	ai_sources.custom_minimum_size.y = 105
	right.add_child(ai_sources)
	ai_diff = TextEdit.new()
	ai_diff.placeholder_text = "與目前資料的差異"
	ai_diff.editable = false
	ai_diff.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(ai_diff)
	return page


func _build_test_page() -> Control:
	var page := _page("測試與驗證", "檢查 JSON、穩定 ID、跨資料引用與素材授權；命令列測試另見 tests/。")
	var run := Button.new()
	run.text = "執行內容與授權檢查"
	run.pressed.connect(_run_validation)
	page.add_child(run)
	test_output = TextEdit.new()
	test_output.editable = false
	test_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(test_output)
	return page


func _build_export_page() -> Control:
	var page := _page("匯出", "正式遊戲不包含 Creator Service、模型、知識庫、索引或設計原稿。")
	var check := Button.new()
	check.text = "執行 Release Gate"
	check.pressed.connect(_run_export_gate)
	page.add_child(check)
	export_output = RichTextLabel.new()
	export_output.bbcode_enabled = true
	export_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	export_output.text = "[color=#aab7cc]尚未檢查。通過後請使用 Godot 的 Project → Export，並套用 export_presets.cfg 的排除規則。[/color]"
	page.add_child(export_output)
	return page


func _load_manifest() -> void:
	if is_instance_valid(manifest_editor):
		manifest_editor.text = ContentTools.read_text("res://data/project_manifest.json")


func _save_manifest() -> void:
	var parser := JSON.new()
	if parser.parse(manifest_editor.text) != OK:
		_set_status("Manifest JSON 無效或 schema_version 不是 1", true)
		return
	var parsed: Variant = parser.data
	if not parsed is Dictionary or int(parsed.get("schema_version", 0)) != 1:
		_set_status("Manifest JSON 無效或 schema_version 不是 1", true)
		return
	_commit_text("res://data/project_manifest.json", JSON.stringify(parsed, "\t", false) + "\n", "更新 PixelRPG Manifest")


func _open_asset_dialog() -> void:
	asset_dialog.popup_centered_ratio(0.72)


func _import_assets(paths: PackedStringArray) -> void:
	var index_path := "res://data/assets/index.json"
	var parsed: Variant = JSON.parse_string(ContentTools.read_text(index_path))
	var index: Dictionary = parsed if parsed is Dictionary else {"schema_version": 1, "assets": []}
	var assets: Array = index.get("assets", [])
	var existing_ids: Dictionary = {}
	for existing_record: Dictionary in assets:
		existing_ids[String(existing_record.get("id", ""))] = true
	var destination_directory := ProjectSettings.globalize_path("res://assets/source")
	DirAccess.make_dir_recursive_absolute(destination_directory)
	for source_path in paths:
		var destination_name := source_path.get_file()
		var destination := destination_directory.path_join(destination_name)
		if FileAccess.file_exists(destination):
			destination_name = "%s_%d.%s" % [source_path.get_file().get_basename(), Time.get_unix_time_from_system(), source_path.get_extension()]
			destination = destination_directory.path_join(destination_name)
		var error := DirAccess.copy_absolute(source_path, destination)
		if error != OK:
			_set_status("匯入失敗：%s" % source_path, true)
			continue
		var extension := source_path.get_extension().to_lower()
		var kind := "image" if extension in ["png", "jpg", "jpeg", "webp"] else "document" if extension in ["pdf", "docx", "pptx", "xlsx", "csv", "md", "txt"] else "other"
		var digest := FileAccess.get_sha256(destination)
		var asset_id := ContentTools.stable_id(destination_name)
		if existing_ids.has(asset_id):
			asset_id = "%s_%s" % [asset_id, digest.left(8)]
		existing_ids[asset_id] = true
		var record := {
			"schema_version": 1,
			"id": asset_id,
			"source_path": "res://assets/source/%s" % destination_name,
			"kind": kind,
			"sha256": digest,
			"license": {"spdx": "UNSPECIFIED", "source": source_path, "author": ""},
			"tags": [], "links": []
		}
		assets.append(record)
	index["assets"] = assets
	_commit_text(index_path, JSON.stringify(index, "\t", false) + "\n", "匯入 PixelRPG 素材")
	_reload_assets()


func _reload_assets() -> void:
	if not is_instance_valid(asset_list):
		return
	asset_list.clear()
	var parsed: Variant = JSON.parse_string(ContentTools.read_text("res://data/assets/index.json"))
	if not parsed is Dictionary:
		return
	for record: Dictionary in parsed.get("assets", []):
		var spdx := String(Dictionary(record.get("license", {})).get("spdx", "UNSPECIFIED"))
		asset_list.add_item("%s  ·  %s  ·  %s" % [record.get("id"), record.get("kind"), spdx])
		asset_list.set_item_metadata(asset_list.item_count - 1, record.get("id"))


func _on_asset_selected(index: int) -> void:
	var asset_id := String(asset_list.get_item_metadata(index))
	var parsed: Variant = JSON.parse_string(ContentTools.read_text("res://data/assets/index.json"))
	if parsed is Dictionary:
		for record: Dictionary in parsed.get("assets", []):
			if record.get("id") == asset_id:
				asset_license.text = String(Dictionary(record.get("license", {})).get("spdx", "UNSPECIFIED"))


func _save_asset_license() -> void:
	var selected := asset_list.get_selected_items()
	if selected.is_empty() or asset_license.text.strip_edges().is_empty():
		_set_status("請選取素材並填入 SPDX 或 Proprietary", true)
		return
	var asset_id := String(asset_list.get_item_metadata(selected[0]))
	var parsed: Variant = JSON.parse_string(ContentTools.read_text("res://data/assets/index.json"))
	if not parsed is Dictionary:
		return
	for record: Dictionary in parsed.get("assets", []):
		if record.get("id") == asset_id:
			var license := Dictionary(record.get("license", {}))
			license["spdx"] = asset_license.text.strip_edges()
			record["license"] = license
	_commit_text("res://data/assets/index.json", JSON.stringify(parsed, "\t", false) + "\n", "更新素材授權")
	_reload_assets()


func _build_sprite_descriptor() -> void:
	var selected := asset_list.get_selected_items()
	if selected.is_empty():
		_set_status("請先選取一張圖片素材", true)
		return
	var asset_id := String(asset_list.get_item_metadata(selected[0]))
	var parsed: Variant = JSON.parse_string(ContentTools.read_text("res://data/assets/index.json"))
	if not parsed is Dictionary:
		return
	var asset: Dictionary = {}
	for record: Dictionary in parsed.get("assets", []):
		if record.get("id") == asset_id:
			asset = record
			break
	if asset.is_empty() or asset.get("kind") != "image":
		_set_status("選取的素材不是支援的圖片", true)
		return
	var source_path := String(asset.get("source_path", ""))
	var source_absolute := ProjectSettings.globalize_path(source_path)
	var image := Image.new()
	var image_error := image.load(source_absolute)
	if image_error != OK:
		_set_status("無法讀取圖片：%s" % error_string(image_error), true)
		return
	var columns := int(sprite_columns.value)
	var rows := int(sprite_rows.value)
	if image.get_width() % columns != 0 or image.get_height() % rows != 0:
		_set_status("圖片尺寸必須可被欄數與列數整除", true)
		return
	var runtime_path := "res://assets/runtime/sprites/%s.%s" % [asset_id, source_path.get_extension().to_lower()]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(runtime_path).get_base_dir())
	var copy_error := DirAccess.copy_absolute(source_absolute, ProjectSettings.globalize_path(runtime_path))
	if copy_error != OK:
		_set_status("無法建立 runtime 圖片：%s" % error_string(copy_error), true)
		return
	var animation_names := ["idle", "run", "attack", "hurt", "death"]
	var animations: Dictionary = {}
	for row in range(mini(rows, animation_names.size())):
		animations[animation_names[row]] = {"row": row, "frames": Array(range(columns)), "fps": sprite_fps.value, "loop": row < 2}
	var frame_width := int(image.get_width() / columns)
	var frame_height := int(image.get_height() / rows)
	var descriptor := {
		"schema_version": 1, "id": asset_id, "source_asset_id": asset_id,
		"runtime_texture": runtime_path,
		"grid": {"columns": columns, "rows": rows, "frame_width": frame_width, "frame_height": frame_height},
		"directions": int(sprite_directions.get_item_metadata(sprite_directions.selected)),
		"animations": animations,
		"collision": {"x": 0.0, "y": frame_height * 0.2, "width": frame_width * 0.55, "height": frame_height * 0.45}
	}
	_commit_text("res://data/sprites/%s.json" % asset_id, JSON.stringify(descriptor, "\t", false) + "\n", "建立 PixelRPG 精靈描述")
	_set_status("已保留原圖，並建立 runtime texture、動畫映射與碰撞框描述")


func _reload_database() -> void:
	if not is_instance_valid(database_list):
		return
	database_list.clear()
	var display_type := database_type.get_item_text(database_type.selected)
	var directory := "res://data/%s" % ContentTools.artifact_directory(display_type)
	for path in ContentTools.list_json(directory):
		var parsed: Variant = JSON.parse_string(ContentTools.read_text(path))
		var label := path.get_file()
		if parsed is Dictionary:
			label = "%s · %s" % [parsed.get("id", "?"), parsed.get("display_name", parsed.get("title", ""))]
		database_list.add_item(label)
		database_list.set_item_metadata(database_list.item_count - 1, path)


func _load_database_selection(index: int) -> void:
	database_path = String(database_list.get_item_metadata(index))
	database_editor.text = ContentTools.read_text(database_path)


func _new_artifact() -> void:
	var display_type := database_type.get_item_text(database_type.selected)
	var artifact := ContentTools.default_artifact(display_type)
	database_editor.text = JSON.stringify(artifact, "\t", false) + "\n"
	database_path = ""


func _save_database_artifact() -> void:
	var parser := JSON.new()
	if parser.parse(database_editor.text) != OK:
		_set_status("資料不是有效 JSON 物件", true)
		return
	var parsed: Variant = parser.data
	if not parsed is Dictionary:
		_set_status("資料不是有效 JSON 物件", true)
		return
	var artifact_id := String(parsed.get("id", ""))
	if int(parsed.get("schema_version", 0)) != 1 or not _is_stable_id(artifact_id):
		_set_status("需要 schema_version: 1，且 id 只能使用小寫英數字與底線", true)
		return
	if database_path.is_empty():
		var display_type := database_type.get_item_text(database_type.selected)
		database_path = "res://data/%s/%s.json" % [ContentTools.artifact_directory(display_type), artifact_id]
	_commit_text(database_path, JSON.stringify(parsed, "\t", false) + "\n", "更新 PixelRPG 內容")
	_reload_database()


func _reload_story_list() -> void:
	if not is_instance_valid(story_list):
		return
	story_list.clear()
	for path in ContentTools.list_json("res://data/dialogues"):
		var parsed: Variant = JSON.parse_string(ContentTools.read_text(path))
		story_list.add_item(String(parsed.get("title", path.get_file())) if parsed is Dictionary else path.get_file())
		story_list.set_item_metadata(story_list.item_count - 1, path)


func _load_story() -> void:
	if story_list.item_count == 0:
		return
	story_path = String(story_list.get_item_metadata(story_list.selected))
	var parsed: Variant = JSON.parse_string(ContentTools.read_text(story_path))
	if not parsed is Dictionary:
		return
	_clear_story_graph()
	var name_by_id: Dictionary = {}
	var nodes: Array = parsed.get("nodes", [])
	for index in range(nodes.size()):
		var node_data: Dictionary = nodes[index]
		var graph_node := _make_story_node(node_data, Vector2(44 + (index % 3) * 310, 44 + (index / 3) * 220))
		story_graph.add_child(graph_node)
		name_by_id[String(node_data.get("id", "node_%d" % index))] = graph_node.name
	for graph_child in story_graph.get_children():
		if graph_child is GraphNode:
			var node_data: Dictionary = graph_child.get_meta("node_data")
			var next_id := String(node_data.get("next", ""))
			if not next_id.is_empty() and name_by_id.has(next_id):
				story_graph.connect_node(graph_child.name, 0, name_by_id[next_id], 0)
			for option: Dictionary in node_data.get("options", []):
				var option_next := String(option.get("next", ""))
				if name_by_id.has(option_next):
					story_graph.connect_node(graph_child.name, 0, name_by_id[option_next], 0)


func _make_story_node(node_data: Dictionary, graph_position: Vector2) -> GraphNode:
	var graph_node := GraphNode.new()
	var node_id := String(node_data.get("id", "node"))
	graph_node.name = "%s_%d" % [node_id.validate_node_name(), randi()]
	graph_node.title = "%s · %s" % [node_id, node_data.get("type", "line")]
	graph_node.position_offset = graph_position
	graph_node.custom_minimum_size = Vector2(260, 150)
	graph_node.set_meta("node_data", node_data.duplicate(true))
	var fields := VBoxContainer.new()
	fields.name = "Fields"
	graph_node.add_child(fields)
	var speaker := LineEdit.new()
	speaker.name = "Speaker"
	speaker.placeholder_text = "說話者"
	speaker.text = String(node_data.get("speaker", ""))
	fields.add_child(speaker)
	var text_edit := TextEdit.new()
	text_edit.name = "Text"
	text_edit.placeholder_text = "台詞／節點摘要"
	text_edit.text = String(node_data.get("text", ""))
	text_edit.custom_minimum_size = Vector2(235, 72)
	fields.add_child(text_edit)
	graph_node.set_slot(0, true, 0, Color("78dcca"), true, 0, Color("ffcf5c"))
	return graph_node


func _clear_story_graph() -> void:
	story_graph.clear_connections()
	for child in story_graph.get_children():
		if child is GraphNode:
			story_graph.remove_child(child)
			child.queue_free()


func _add_story_line() -> void:
	var graph_node_count := 0
	for child in story_graph.get_children():
		if child is GraphNode:
			graph_node_count += 1
	var node_id := "line_%d" % (graph_node_count + 1)
	var node_data := {"id": node_id, "type": "line", "speaker": "", "text": "", "next": null}
	var grid_position := Vector2(44 + (graph_node_count % 3) * 310, 44 + (graph_node_count / 3) * 220)
	story_graph.add_child(_make_story_node(node_data, story_graph.scroll_offset + grid_position))


func _save_story() -> void:
	if story_path.is_empty():
		_set_status("請先載入一份對話圖", true)
		return
	var original: Variant = JSON.parse_string(ContentTools.read_text(story_path))
	if not original is Dictionary:
		return
	var id_by_name: Dictionary = {}
	for child in story_graph.get_children():
		if child is GraphNode:
			id_by_name[child.name] = String(Dictionary(child.get_meta("node_data")).get("id", child.name))
	var next_by_id: Dictionary = {}
	for connection: Dictionary in story_graph.get_connection_list():
		var from_name := StringName(connection.get("from_node", &""))
		var to_name := StringName(connection.get("to_node", &""))
		if id_by_name.has(from_name) and id_by_name.has(to_name) and not next_by_id.has(id_by_name[from_name]):
			next_by_id[id_by_name[from_name]] = id_by_name[to_name]
	var updated_nodes: Array = []
	for child in story_graph.get_children():
		if child is GraphNode:
			var node_data: Dictionary = child.get_meta("node_data").duplicate(true)
			var fields := child.get_node("Fields")
			node_data["speaker"] = fields.get_node("Speaker").text
			node_data["text"] = fields.get_node("Text").text
			if node_data.get("type") not in ["choice", "end"]:
				if next_by_id.has(node_data.get("id")):
					node_data["next"] = next_by_id[node_data.get("id")]
				else:
					node_data.erase("next")
			if node_data.get("type") in ["end", "action", "choice"] and String(node_data["speaker"]).is_empty():
				node_data.erase("speaker")
			if node_data.get("type") in ["end", "action", "choice"] and String(node_data["text"]).is_empty():
				node_data.erase("text")
			updated_nodes.append(node_data)
	original["nodes"] = updated_nodes
	_commit_text(story_path, JSON.stringify(original, "\t", false) + "\n", "更新 PixelRPG 劇情圖")


func _request_ai_draft() -> void:
	if ai_prompt.text.strip_edges().is_empty():
		_set_status("請先輸入 AI 任務", true)
		return
	ai_draft.text = ""
	ai_sources.text = ""
	ai_diff.text = ""
	var payload := {
		"task": ai_task.get_item_text(ai_task.selected),
		"prompt": ai_prompt.text.strip_edges(),
		"artifact_type": ai_type.get_item_metadata(ai_type.selected),
		"mode": ai_mode.get_item_metadata(ai_mode.selected),
		"max_context_tokens": 16000
	}
	if not ai_image_path.text.strip_edges().is_empty():
		payload["image_paths"] = [ai_image_path.text.strip_edges()]
	if ai_client.request_assist(payload):
		ai_status.text = "正在檢索與生成；可在服務端取消。"


func _on_ai_status_changed(message: String, connected: bool) -> void:
	if not is_instance_valid(ai_status):
		return
	ai_status.text = message
	ai_status.add_theme_color_override("font_color", Color("78dcca") if connected else Color("ffcf5c"))


func _on_ai_event(event: Dictionary) -> void:
	match String(event.get("type", "")):
		"source":
			ai_sources.text += "[%s] %s\n%s\n\n" % [event.get("source_id", "?"), event.get("path", ""), event.get("excerpt", "")]
		"token":
			ai_draft.text += String(event.get("content", ""))
		"draft":
			var content: Variant = event.get("content", {})
			ai_draft.text = JSON.stringify(content, "\t", false) if content is Dictionary else String(content)
			_refresh_ai_diff()
		"warning":
			ai_status.text = "警告：%s" % event.get("message", "")
		"done":
			ai_status.text = "草稿完成；請檢查引用與差異後再套用。"
			_refresh_ai_diff()
		"error":
			ai_status.text = "錯誤：%s" % event.get("message", "未知錯誤")
			if event.has("raw"):
				ai_draft.text = String(event.get("raw", ""))


func _validate_ai_draft() -> void:
	var parser := JSON.new()
	if parser.parse(ai_draft.text) != OK:
		ai_status.text = "草稿不是 JSON 物件；問答結果不可直接套用。"
		return
	var parsed: Variant = parser.data
	if not parsed is Dictionary:
		ai_status.text = "草稿不是 JSON 物件；問答結果不可直接套用。"
		return
	if int(parsed.get("schema_version", 0)) != 1 or not _is_stable_id(String(parsed.get("id", ""))):
		ai_status.text = "草稿未通過：需要 schema_version: 1 與穩定 id。"
		return
	ai_status.text = "本機基本驗證通過；套用後仍會執行跨引用檢查。"


func _apply_ai_draft() -> void:
	var parser := JSON.new()
	if parser.parse(ai_draft.text) != OK:
		ai_status.text = "草稿驗證失敗，未寫入任何檔案。"
		return
	var parsed: Variant = parser.data
	if not parsed is Dictionary or int(parsed.get("schema_version", 0)) != 1:
		ai_status.text = "草稿驗證失敗，未寫入任何檔案。"
		return
	var artifact_id := String(parsed.get("id", ""))
	if not _is_stable_id(artifact_id):
		ai_status.text = "草稿 id 不合法，未寫入任何檔案。"
		return
	var directory := String(ai_type.get_item_metadata(ai_type.selected))
	var path := "res://data/%s/%s.json" % [directory, artifact_id]
	_commit_text(path, JSON.stringify(parsed, "\t", false) + "\n", "套用 PixelRPG AI 草稿")
	ContentRegistry.reload_all()
	var reference_errors := ContentRegistry.validate_references()
	if reference_errors.is_empty():
		ai_status.text = "草稿已套用，可用 Ctrl+Z 復原。"
	else:
		ai_status.text = "已套用但有引用警告：%s（可 Ctrl+Z）" % reference_errors[0]
	_reload_database()
	_reload_story_list()


func _refresh_ai_diff() -> void:
	var previous := ContentTools.read_text(database_path) if not database_path.is_empty() else ""
	ai_diff.text = _simple_diff(previous, ai_draft.text)


func _simple_diff(before: String, after: String) -> String:
	var before_lines := before.split("\n")
	var after_lines := after.split("\n")
	var result := PackedStringArray()
	for line in before_lines:
		if line not in after_lines:
			result.append("- %s" % line)
	for line in after_lines:
		if line not in before_lines:
			result.append("+ %s" % line)
	return "無差異" if result.is_empty() else "\n".join(result)


func _run_validation() -> bool:
	ContentRegistry.reload_all()
	var errors := PackedStringArray(ContentRegistry.errors)
	errors.append_array(ContentRegistry.validate_references())
	var parsed: Variant = JSON.parse_string(ContentTools.read_text("res://data/assets/index.json"))
	if not parsed is Dictionary:
		errors.append("素材索引不是有效 JSON")
	else:
		for record: Dictionary in parsed.get("assets", []):
			var spdx := String(Dictionary(record.get("license", {})).get("spdx", "UNSPECIFIED"))
			if spdx in ["", "UNSPECIFIED"]:
				errors.append("素材 %s 尚未填寫授權" % record.get("id", "?"))
	if errors.is_empty():
		test_output.text = "✓ 內容 JSON 可載入\n✓ 穩定 ID 與 schema_version 基本檢查通過\n✓ 跨資料引用通過\n✓ 素材授權已填寫"
	else:
		test_output.text = "發現 %d 個問題：\n- %s" % [errors.size(), "\n- ".join(errors)]
	return errors.is_empty()


func _run_export_gate() -> void:
	if _run_validation():
		export_output.text = "[color=#78dcca]✓ Release Gate 通過[/color]\n\n匯出排除：creator_service、knowledge、schemas、tests、launcher、.creator、*.md。\n請使用 Godot 的 Project → Export 產生 Windows x64 build。"
	else:
		export_output.text = "[color=#db5a6b]✗ Release Gate 未通過[/color]\n\n請先到「測試」頁修正資料引用或素材授權。正式匯出已停止。"


func _commit_text(path: String, value: String, action_name: String) -> void:
	var previous := ContentTools.read_text(path)
	var existed := FileAccess.file_exists(path)
	var undo_redo := editor_plugin.get_undo_redo()
	undo_redo.create_action(action_name)
	undo_redo.add_do_method(self, "_restore_text", path, value, false)
	undo_redo.add_undo_method(self, "_restore_text", path, previous, not existed)
	undo_redo.commit_action()
	_set_status("已保存：%s" % path)


func _restore_text(path: String, value: String, remove_file: bool) -> void:
	if remove_file:
		var absolute := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(absolute):
			DirAccess.remove_absolute(absolute)
	else:
		ContentTools.write_text(path, value)
	if editor_plugin != null and OS.get_environment("PIXELRPG_STUDIO_ACCEPTANCE") != "1":
		editor_plugin.get_editor_interface().get_resource_filesystem().scan()


func _is_stable_id(value: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^[a-z][a-z0-9_]*$")
	return regex.search(value) != null


func _set_status(message: String, is_error: bool = false) -> void:
	if not is_instance_valid(status_label):
		return
	status_label.text = message
	status_label.add_theme_color_override("font_color", Color("db5a6b") if is_error else Color("78dcca"))
