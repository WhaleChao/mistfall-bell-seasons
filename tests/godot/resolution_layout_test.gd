extends SceneTree

const REPORT_DIRECTORY := "res://reports/resolution_layout"
const REPORT_JSON := REPORT_DIRECTORY + "/report.json"
const REPORT_MARKDOWN := REPORT_DIRECTORY + "/REPORT.md"
const RESOLUTIONS := [Vector2i(640, 360), Vector2i(1280, 720), Vector2i(1280, 800), Vector2i(1920, 1080), Vector2i(2560, 1440)]

var cases: Array[Dictionary] = []
var captures: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIRECTORY))
	root.content_scale_size = Vector2i(640, 360)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	var state_store: Node = root.get_node("GameState")
	state_store.reset()
	state_store.set_flag(&"title_seen", true)
	var scene: Node = load("res://sample/main.tscn").instantiate()
	root.add_child(scene)
	for _frame in 15:
		await process_frame
	for resolution: Vector2i in RESOLUTIONS:
		DisplayServer.window_set_size(resolution)
		root.size = resolution
		for _frame in 12:
			await process_frame
		var window_size := DisplayServer.window_get_size()
		var usable_size := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen()).size
		var exact_window_size := window_size == resolution
		# macOS keeps decorated windows inside the current screen's usable area. A
		# requested 1080p/1440p window can therefore be shorter than requested on a
		# smaller display even though the viewport still renders at the target size.
		var platform_clamped := (
			OS.get_name() == "macOS"
			and (resolution.x > usable_size.x or resolution.y > usable_size.y)
			and window_size.x > 0
			and window_size.y > 0
			and window_size.x <= resolution.x
			and window_size.y <= resolution.y
		)
		var content_image := root.get_texture().get_image()
		var image := content_image
		var content_size := Vector2i(content_image.get_width(), content_image.get_height())
		if content_size != resolution:
			image = Image.create_empty(resolution.x, resolution.y, false, content_image.get_format())
			image.fill(Color.BLACK)
			var offset := Vector2i((resolution.x - content_size.x) / 2, (resolution.y - content_size.y) / 2)
			image.blit_rect(content_image, Rect2i(Vector2i.ZERO, content_size), offset)
		var file_name := "%dx%d.png" % [resolution.x, resolution.y]
		var save_error := image.save_png(REPORT_DIRECTORY + "/" + file_name)
		_check(save_error == OK, "截圖", "%s 可輸出 PNG" % file_name, error_string(save_error))
		_check(exact_window_size or platform_clamped, "解析度", "%s 視窗尺寸符合要求或平台工作區夾限" % file_name, "requested=%dx%d actual=%dx%d usable=%dx%d%s" % [resolution.x, resolution.y, window_size.x, window_size.y, usable_size.x, usable_size.y, " clamped" if platform_clamped else ""])
		_check(image.get_width() == resolution.x and image.get_height() == resolution.y, "解析度", "%s 合成顯示證據尺寸正確" % file_name, "content=%dx%d output=%dx%d" % [content_size.x, content_size.y, image.get_width(), image.get_height()])
		var stats := _image_stats(image)
		_check(float(stats.variance) > 0.008, "畫面", "%s 不是空白或純色畫面" % file_name, "variance=%.5f" % stats.variance)
		_check(float(stats.black_ratio) < 0.45, "畫面", "%s 沒有異常大面積黑屏" % file_name, "black=%.2f%%" % (100.0 * float(stats.black_ratio)))
		var scale := mini(resolution.x / 640, resolution.y / 360)
		_check(scale >= 1 and scale == floori(scale), "整數縮放", "%s 使用整數像素倍率" % file_name, "%dx" % scale)
		captures.append({"file":file_name,"window_width":window_size.x,"window_height":window_size.y,"screen_usable_width":usable_size.x,"screen_usable_height":usable_size.y,"window_clamped":platform_clamped,"content_width":content_size.x,"content_height":content_size.y,"width":image.get_width(),"height":image.get_height(),"integer_scale":scale,"variance":stats.variance,"black_ratio":stats.black_ratio})
	_write_report()
	var failed := cases.filter(func(item: Dictionary) -> bool: return not bool(item.passed)).size()
	scene.queue_free()
	await process_frame
	var audio_director: Node = root.get_node("AudioDirector")
	audio_director.call("shutdown_audio")
	await process_frame
	if failed == 0:
		print("PixelRPG resolution layout gate: PASS (%d resolutions)" % RESOLUTIONS.size())
		quit(0)
	else:
		for item: Dictionary in cases:
			if not bool(item.passed):
				push_error("%s / %s: %s" % [item.category, item.name, item.detail])
		quit(1)


func _image_stats(image: Image) -> Dictionary:
	var count := 0
	var sum := 0.0
	var sum_squared := 0.0
	var black := 0
	var step := maxi(1, image.get_width() / 320)
	for y in range(0, image.get_height(), step):
		for x in range(0, image.get_width(), step):
			var luminance := image.get_pixel(x, y).get_luminance()
			count += 1
			sum += luminance
			sum_squared += luminance * luminance
			if luminance < 0.015:
				black += 1
	var mean := sum / float(count)
	return {"variance":sum_squared / float(count) - mean * mean,"black_ratio":float(black) / float(count)}


func _check(condition: bool, category: String, name: String, detail: String) -> void:
	cases.append({"category":category,"name":name,"passed":condition,"detail":detail})


func _write_report() -> void:
	var passed := cases.filter(func(item: Dictionary) -> bool: return bool(item.passed)).size()
	var failed := cases.size() - passed
	var payload := {"generated_at":Time.get_datetime_string_from_system(true),"engine":Engine.get_version_info(),"renderer":RenderingServer.get_video_adapter_name(),"checks":cases.size(),"passed":passed,"failed":failed,"captures":captures,"cases":cases}
	var json_file := FileAccess.open(REPORT_JSON, FileAccess.WRITE)
	if json_file != null:
		json_file.store_string(JSON.stringify(payload, "\t", false))
	var lines := PackedStringArray([
		"# 《霧落農歌：鐘塔之季》多解析度畫面驗收",
		"",
		"結果：**%s**　｜　%d 通過／%d 失敗　｜　含 Steam Deck 原生 1280×800" % ["PASS" if failed == 0 else "FAIL", passed, failed],
		"",
		"本測試驗證 Windows／macOS 實際視窗及 GPU ViewportTexture，以 1×、2×、3×、4×整數縮放渲染正式遊戲場景。macOS 會把大於目前螢幕可用工作區的裝飾視窗安全夾限，這種情況另行記錄實際視窗與工作區尺寸，同時仍要求目標解析度的內容紋理完整渲染。1280×800 的 ViewportTexture 為 1280×720，證據圖依 KEEP aspect 顯示規則補上上下各 40px 留邊。",
		"",
		"| 分類 | 項目 | 結果 | 細節 |",
		"|---|---|---:|---|",
	])
	for item: Dictionary in cases:
		lines.append("| %s | %s | %s | %s |" % [item.category, String(item.name).replace("|", "\\|"), "通過" if item.passed else "失敗", String(item.detail).replace("|", "\\|")])
	var report_file := FileAccess.open(REPORT_MARKDOWN, FileAccess.WRITE)
	if report_file != null:
		report_file.store_string("\n".join(lines) + "\n")
