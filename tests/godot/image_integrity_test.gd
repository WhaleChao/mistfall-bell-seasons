extends SceneTree

const REPORT_DIRECTORY := "res://reports/image_integrity"
const REPORT_JSON := REPORT_DIRECTORY + "/report.json"
const REPORT_MARKDOWN := REPORT_DIRECTORY + "/REPORT.md"
const CHROMA_THRESHOLD := 0.78

const IMAGE_RULES := {
	"res://assets/runtime/backgrounds/mistfall_farm_title.png": {"role":"background","width":1672,"height":941},
	"res://assets/runtime/backgrounds/mistfall_farm_commercial.png": {"role":"background","width":1672,"height":941},
	"res://assets/runtime/backgrounds/mistfall_village_commercial.png": {"role":"background","width":1672,"height":941},
	"res://assets/runtime/backgrounds/mistfall_dungeon_commercial.png": {"role":"background","width":1672,"height":941},
	"res://assets/runtime/portraits/romance_candidates_atlas.png": {"role":"opaque_atlas","columns":4,"rows":1,"cells":4},
	"res://assets/runtime/sprites/character_atlas.png": {"role":"chroma_atlas","columns":4,"rows":3,"cells":12,"max_remainder":0},
	"res://assets/runtime/sprites/enemy_atlas.png": {"role":"chroma_atlas","columns":4,"rows":4,"cells":16,"max_remainder":2},
	"res://assets/runtime/sprites/animal_atlas.png": {"role":"chroma_atlas","columns":4,"rows":2,"cells":8,"max_remainder":2},
	"res://assets/runtime/sprites/player_walk_atlas.png": {"role":"chroma_atlas","columns":4,"rows":4,"cells":16,"max_remainder":2,"unique_rows":true},
}

var cases: Array[Dictionary] = []
var image_metrics: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIRECTORY))
	var manifest_paths := _manifest_image_paths()
	_check(manifest_paths.size() == IMAGE_RULES.size(), "清單", "所有 Runtime 點陣圖均有完整性規則", "%d/%d" % [manifest_paths.size(), IMAGE_RULES.size()])
	for path: String in IMAGE_RULES:
		_check(path in manifest_paths, "清單", "圖片已登錄資產與授權：%s" % path.get_file(), path)
		_audit_image(path, Dictionary(IMAGE_RULES[path]))
	_audit_acceptance_screenshots()
	_write_report()
	var failed := cases.filter(func(item: Dictionary) -> bool: return not bool(item.passed)).size()
	if failed == 0:
		print("PixelRPG image integrity gate: PASS (%d checks, %d runtime images)" % [cases.size(), image_metrics.size()])
		quit(0)
	else:
		for item: Dictionary in cases:
			if not bool(item.passed):
				push_error("%s / %s: %s" % [item.category, item.name, item.detail])
		quit(1)


func _manifest_image_paths() -> PackedStringArray:
	var result := PackedStringArray()
	var file := FileAccess.open("res://data/assets/index.json", FileAccess.READ)
	if file == null:
		_check(false, "清單", "可讀取資產清單", "data/assets/index.json")
		return result
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_check(false, "清單", "資產清單是有效 JSON", "解析失敗")
		return result
	for record: Dictionary in parsed.get("assets", []):
		var path := String(record.get("source_path", ""))
		if String(record.get("kind", "")) == "image" and path.ends_with(".png"):
			result.append(path)
	result.sort()
	return result


func _audit_image(path: String, rule: Dictionary) -> void:
	var image := Image.new()
	var error := image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
	_check(error == OK, "解碼", "PNG 可完整解碼：%s" % path.get_file(), error_string(error))
	if error != OK:
		return
	var width := image.get_width()
	var height := image.get_height()
	var metric := {"path":path,"width":width,"height":height,"format":image.get_format(),"has_mipmaps":image.has_mipmaps()}
	image_metrics.append(metric)
	_check(width > 0 and height > 0 and width <= 4096 and height <= 4096, "尺寸", "圖片尺寸在商業發行限制內：%s" % path.get_file(), "%dx%d" % [width, height])
	_check(not image.has_mipmaps(), "格式", "來源 PNG 不攜帶意外 mipmap：%s" % path.get_file(), "")
	var role := String(rule.role)
	if role == "background":
		_audit_background(path, image, rule)
	elif role in ["chroma_atlas", "opaque_atlas"]:
		_audit_atlas(path, image, rule)


func _audit_background(path: String, image: Image, rule: Dictionary) -> void:
	var width := image.get_width()
	var height := image.get_height()
	_check(width == int(rule.width) and height == int(rule.height), "背景", "背景解析度一致：%s" % path.get_file(), "%dx%d" % [width, height])
	_check(absf(float(width) / float(height) - 16.0 / 9.0) < 0.01, "背景", "背景維持 16:9 安全比例：%s" % path.get_file(), "%.5f" % (float(width) / float(height)))
	var count := 0
	var sum := 0.0
	var sum_squared := 0.0
	var dark := 0
	var bright := 0
	for y in range(0, height, 4):
		for x in range(0, width, 4):
			var color := image.get_pixel(x, y)
			var luminance := color.get_luminance()
			count += 1
			sum += luminance
			sum_squared += luminance * luminance
			if luminance < 0.08:
				dark += 1
			if luminance > 0.92:
				bright += 1
	var mean := sum / maxf(1.0, float(count))
	var variance := sum_squared / maxf(1.0, float(count)) - mean * mean
	_check(variance > 0.006, "背景", "背景不是空白／單色圖片：%s" % path.get_file(), "variance=%.5f" % variance)
	_check(float(dark) / float(count) < 0.72 and float(bright) / float(count) < 0.72, "背景", "背景未大面積過曝或全黑：%s" % path.get_file(), "dark=%.1f%% bright=%.1f%%" % [100.0 * dark / count, 100.0 * bright / count])


func _audit_atlas(path: String, image: Image, rule: Dictionary) -> void:
	var columns := int(rule.columns)
	var rows := int(rule.rows)
	var cell_width := image.get_width() / columns
	var cell_height := image.get_height() / rows
	var remainder_x := image.get_width() - cell_width * columns
	var remainder_y := image.get_height() - cell_height * rows
	var max_remainder := int(rule.get("max_remainder", 0))
	_check(remainder_x <= max_remainder and remainder_y <= max_remainder, "圖集", "圖集切格餘數受控：%s" % path.get_file(), "cell=%dx%d remainder=%dx%d" % [cell_width, cell_height, remainder_x, remainder_y])
	_check(cell_width >= 128 and cell_height >= 128, "圖集", "圖集每格解析度足夠：%s" % path.get_file(), "%dx%d" % [cell_width, cell_height])
	if remainder_x > 0 or remainder_y > 0:
		var remainder_total := 0
		var removable_total := 0
		for y in image.get_height():
			for x in image.get_width():
				if x >= cell_width * columns or y >= cell_height * rows:
					remainder_total += 1
					if _is_chroma_background(image.get_pixel(x, y)):
						removable_total += 1
		var removable_ratio := float(removable_total) / maxf(1.0, float(remainder_total))
		_check(removable_ratio > 0.995, "圖集", "未使用餘邊只有可移除背景：%s" % path.get_file(), "%.3f%%" % (removable_ratio * 100.0))
	var signatures := PackedStringArray()
	var occupied_cells := 0
	for row in rows:
		for column in columns:
			var stats := _cell_stats(image, column * cell_width, row * cell_height, cell_width, cell_height, String(rule.role) == "chroma_atlas")
			var occupied := float(stats.luminance_variance) > 0.004 if String(rule.role) == "opaque_atlas" else float(stats.foreground_ratio) > 0.01 and float(stats.foreground_ratio) < 0.80
			if occupied:
				occupied_cells += 1
			_check(occupied, "圖集", "%s 格 %d,%d 含有效且有邊界的圖像" % [path.get_file(), column, row], "foreground=%.2f%%" % (100.0 * float(stats.foreground_ratio)))
			_check(float(stats.corner_background_ratio) > 0.90, "圖集", "%s 格 %d,%d 四角不含切格溢出" % [path.get_file(), column, row], "background=%.2f%%" % (100.0 * float(stats.corner_background_ratio)))
			signatures.append(String(stats.signature))
	_check(occupied_cells == int(rule.cells), "圖集", "所有預期圖格均非空白：%s" % path.get_file(), "%d/%d" % [occupied_cells, int(rule.cells)])
	var unique_signatures := {}
	for signature: String in signatures:
		unique_signatures[signature] = true
	_check(unique_signatures.size() == signatures.size(), "圖集", "所有圖格內容可區分：%s" % path.get_file(), "%d/%d unique" % [unique_signatures.size(), signatures.size()])
	if bool(rule.get("unique_rows", false)):
		for row in rows:
			var row_unique := {}
			for column in columns:
				row_unique[signatures[row * columns + column]] = true
			_check(row_unique.size() == columns, "動畫", "玩家方向列 %d 含 %d 個不同動畫幀" % [row, columns], "%d/%d unique" % [row_unique.size(), columns])


func _cell_stats(image: Image, start_x: int, start_y: int, width: int, height: int, chroma: bool) -> Dictionary:
	var foreground := 0
	var samples := 0
	var signature_bytes := PackedByteArray()
	var luminance_sum := 0.0
	var luminance_squared_sum := 0.0
	for sample_y in 32:
		for sample_x in 32:
			var x := start_x + mini(width - 1, floori((sample_x + 0.5) * width / 32.0))
			var y := start_y + mini(height - 1, floori((sample_y + 0.5) * height / 32.0))
			var color := image.get_pixel(x, y)
			var is_background := _is_chroma_background(color) if chroma else false
			if not is_background:
				foreground += 1
			samples += 1
			var luminance := color.get_luminance()
			luminance_sum += luminance
			luminance_squared_sum += luminance * luminance
			signature_bytes.append(0 if is_background else 1)
			signature_bytes.append(clampi(roundi(color.r * 255.0), 0, 255))
			signature_bytes.append(clampi(roundi(color.g * 255.0), 0, 255))
			signature_bytes.append(clampi(roundi(color.b * 255.0), 0, 255))
	var corner_background := 0
	var corner_samples := 0
	var radius := maxi(4, mini(width, height) / 24)
	for corner in [Vector2i(0, 0), Vector2i(width - radius, 0), Vector2i(0, height - radius), Vector2i(width - radius, height - radius)]:
		for offset_y in range(0, radius, 2):
			for offset_x in range(0, radius, 2):
				var color := image.get_pixel(start_x + corner.x + offset_x, start_y + corner.y + offset_y)
				if (_is_chroma_background(color) if chroma else color.a > 0.0):
					corner_background += 1
				corner_samples += 1
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(signature_bytes)
	var mean := luminance_sum / float(samples)
	return {
		"foreground_ratio": float(foreground) / float(samples),
		"corner_background_ratio": float(corner_background) / float(corner_samples),
		"luminance_variance": luminance_squared_sum / float(samples) - mean * mean,
		"signature": hash.finish().hex_encode(),
	}


func _is_chroma_background(color: Color) -> bool:
	var channel_min := minf(color.r, minf(color.g, color.b))
	var channel_max := maxf(color.r, maxf(color.g, color.b))
	return color.a < 0.02 or (channel_min > CHROMA_THRESHOLD and channel_max - channel_min < 0.12)


func _audit_acceptance_screenshots() -> void:
	var directory := DirAccess.open("res://reports/full_feature_acceptance")
	if directory == null:
		_check(false, "畫面證據", "可讀取全功能驗收畫面", "目錄不存在")
		return
	var names := PackedStringArray()
	for file_name in directory.get_files():
		if file_name.ends_with(".png"):
			names.append(file_name)
	names.sort()
	_check(names.size() == 12, "畫面證據", "全功能驗收保留 12 張畫面", "%d" % names.size())
	for file_name: String in names:
		var image := Image.new()
		var error := image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://reports/full_feature_acceptance/" + file_name))
		_check(error == OK, "畫面證據", "驗收畫面可完整解碼：%s" % file_name, error_string(error))
		if error != OK:
			continue
		_check(image.get_width() == 1280 and image.get_height() == 720, "畫面證據", "驗收畫面解析度正確：%s" % file_name, "%dx%d" % [image.get_width(), image.get_height()])


func _check(condition: bool, category: String, name: String, detail: String) -> void:
	cases.append({"category":category,"name":name,"passed":condition,"detail":detail})


func _write_report() -> void:
	var passed := cases.filter(func(item: Dictionary) -> bool: return bool(item.passed)).size()
	var failed := cases.size() - passed
	var payload := {
		"generated_at":Time.get_datetime_string_from_system(true),
		"engine":Engine.get_version_info(),
		"checks":cases.size(),
		"passed":passed,
		"failed":failed,
		"images":image_metrics,
		"cases":cases,
	}
	var json_file := FileAccess.open(REPORT_JSON, FileAccess.WRITE)
	if json_file != null:
		json_file.store_string(JSON.stringify(payload, "\t", false))
	var lines := PackedStringArray([
		"# 《霧落農歌：鐘塔之季》圖片完整性報告",
		"",
		"結果：**%s**　｜　%d 通過／%d 失敗　｜　%d 張 Runtime 圖片" % ["PASS" if failed == 0 else "FAIL", passed, failed, image_metrics.size()],
		"",
		"本閘門直接解碼原始 PNG，驗證資產登錄、尺寸、比例、圖集格線、未使用餘邊、空白格、重複格、動畫幀差異與 12 張實機畫面證據。",
		"",
		"| 分類 | 項目 | 結果 | 細節 |",
		"|---|---|---:|---|",
	])
	for item: Dictionary in cases:
		lines.append("| %s | %s | %s | %s |" % [item.category, String(item.name).replace("|", "\\|"), "通過" if item.passed else "失敗", String(item.detail).replace("|", "\\|")])
	var report_file := FileAccess.open(REPORT_MARKDOWN, FileAccess.WRITE)
	if report_file != null:
		report_file.store_string("\n".join(lines) + "\n")
