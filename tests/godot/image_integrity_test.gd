extends SceneTree

const REPORT_DIRECTORY := "res://reports/image_integrity"
const REPORT_JSON := REPORT_DIRECTORY + "/report.json"
const REPORT_MARKDOWN := REPORT_DIRECTORY + "/REPORT.md"
const CHROMA_THRESHOLD := 0.78
const MATTE_THRESHOLD := 0.55

const IMAGE_RULES := {
	"res://assets/runtime/backgrounds/mistfall_farm_title.png": {"role":"background","width":1672,"height":941},
	"res://assets/runtime/backgrounds/mistfall_farm_commercial.png": {"role":"background","width":1672,"height":941},
	"res://assets/runtime/backgrounds/mistfall_village_commercial.png": {"role":"background","width":1672,"height":941},
	"res://assets/runtime/backgrounds/mistfall_dungeon_commercial.png": {"role":"background","width":1672,"height":941},
	"res://assets/runtime/backgrounds/mistfall_river_commercial.png": {"role":"background","width":1672,"height":941},
	"res://assets/runtime/backgrounds/bellwood_grove_commercial.png": {"role":"background","width":1672,"height":941},
	"res://assets/runtime/backgrounds/clockwork_ruins_commercial.png": {"role":"background","width":1672,"height":941},
	"res://assets/runtime/portraits/romance_candidates_atlas.png": {"role":"opaque_atlas","columns":4,"rows":1,"cells":4},
	"res://assets/runtime/sprites/character_atlas_alpha.png": {"role":"alpha_atlas","columns":4,"rows":3,"cells":12,"max_remainder":0},
	"res://assets/runtime/sprites/enemy_atlas_alpha.png": {"role":"alpha_atlas","columns":4,"rows":4,"cells":16,"max_remainder":2},
	"res://assets/runtime/sprites/animal_atlas_alpha.png": {"role":"alpha_atlas","columns":4,"rows":2,"cells":8,"max_remainder":2,"required_light_cells":[0,2,6,7]},
	"res://assets/runtime/sprites/player_walk_atlas_alpha.png": {"role":"alpha_atlas","columns":4,"rows":4,"cells":16,"max_remainder":2,"unique_rows":true},
	"res://assets/runtime/sprites/eldritch_drowned_dreamer_alpha.png": {"role":"alpha_atlas","columns":1,"rows":1,"cells":1,"max_remainder":0},
}

const SOURCE_ATLASES := {
	"res://assets/runtime/sprites/character_atlas_alpha.png":"res://assets/source/generated_atlases/character_atlas_checkerboard_source.png",
	"res://assets/runtime/sprites/enemy_atlas_alpha.png":"res://assets/source/generated_atlases/enemy_atlas_checkerboard_source.png",
	"res://assets/runtime/sprites/animal_atlas_alpha.png":"res://assets/source/generated_atlases/animal_atlas_checkerboard_source.png",
	"res://assets/runtime/sprites/player_walk_atlas_alpha.png":"res://assets/source/generated_atlases/player_walk_atlas_checkerboard_source.png",
	"res://assets/runtime/sprites/eldritch_drowned_dreamer_alpha.png":"res://assets/source/generated_atlases/eldritch_drowned_dreamer_source.png",
}

const SOURCE_HASHES := {
	"res://assets/source/generated_atlases/character_atlas_checkerboard_source.png":"7354dbd9a0ed60dedb8de633820bc394769f080fd9ef59fcdcf7a2797e33ab02",
	"res://assets/source/generated_atlases/enemy_atlas_checkerboard_source.png":"917759e5fcbbe7df435b3c38a61e9e2dbd5b3b4047efc341dfe416ef10990a65",
	"res://assets/source/generated_atlases/animal_atlas_checkerboard_source.png":"6bdba66c0b8593c8891b3d8a3d5bd14adcc917d1ae0c9d9d4bfc3ab8ba05a725",
	"res://assets/source/generated_atlases/player_walk_atlas_checkerboard_source.png":"ff38826d3054d98b41f16c515e77b7ef493365a465baf10935ffe6b848046c85",
	"res://assets/source/generated_atlases/eldritch_drowned_dreamer_source.png":"5b363d03bd422b136295d220c8a9d9634fab025ec59540cf0fc12f592196b4c9",
}

const EVIDENCE_SETS := {
	"res://reports/full_feature_acceptance":{"count":20,"width":1280,"height":720},
	"res://reports/studio_ui":{"count":16,"width":1920,"height":1017},
	"res://screenshots":{"count":6,"width":1280,"height":720},
}

const RESOLUTION_EVIDENCE := {
	"640x360.png":Vector2i(640, 360),
	"1280x720.png":Vector2i(1280, 720),
	"1280x800.png":Vector2i(1280, 800),
	"1920x1080.png":Vector2i(1920, 1080),
	"2560x1440.png":Vector2i(2560, 1440),
}

var cases: Array[Dictionary] = []
var image_metrics: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIRECTORY))
	var manifest_paths := _manifest_image_paths()
	var runtime_paths := _runtime_image_paths()
	_check(manifest_paths.size() == runtime_paths.size() + 1, "清單", "所有 Runtime 圖片與應用程式圖示均已登錄", "%d/%d" % [manifest_paths.size(), runtime_paths.size() + 1])
	_check(runtime_paths.size() == IMAGE_RULES.size(), "清單", "自動盤點的所有 Runtime 點陣圖均有完整性規則", "%d/%d" % [runtime_paths.size(), IMAGE_RULES.size()])
	_check("res://icon.svg" in manifest_paths, "清單", "應用程式 SVG 圖示已登錄資產與授權", "res://icon.svg")
	_audit_svg_icon()
	_audit_preprocessing_policy()
	for path: String in IMAGE_RULES:
		_check(path in manifest_paths, "清單", "圖片已登錄資產與授權：%s" % path.get_file(), path)
		_check(path in runtime_paths, "清單", "圖片由 Runtime 自動盤點發現：%s" % path.get_file(), path)
		_audit_image(path, Dictionary(IMAGE_RULES[path]))
	_audit_all_visual_evidence()
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
		if String(record.get("kind", "")) == "image":
			result.append(path)
	result.sort()
	return result


func _runtime_image_paths() -> PackedStringArray:
	var result := PackedStringArray()
	_collect_png_paths("res://assets/runtime", result)
	result.sort()
	return result


func _collect_png_paths(directory_path: String, result: PackedStringArray) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return
	for file_name in directory.get_files():
		if file_name.to_lower().ends_with(".png"):
			result.append(directory_path.path_join(file_name))
	for subdirectory in directory.get_directories():
		_collect_png_paths(directory_path.path_join(subdirectory), result)


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
	_audit_import_settings(path)
	var role := String(rule.role)
	if role == "background":
		_audit_background(path, image, rule)
	elif role in ["alpha_atlas", "opaque_atlas"]:
		_audit_atlas(path, image, rule)
	if role == "alpha_atlas":
		_audit_alpha_source_regression(path, image, String(SOURCE_ATLASES.get(path, "")), rule)


func _audit_svg_icon() -> void:
	var path := "res://icon.svg"
	var text := FileAccess.get_file_as_string(path)
	_check(not text.is_empty(), "圖示", "SVG 應用程式圖示可讀取", "%d bytes" % text.to_utf8_buffer().size())
	_check(text.contains("<svg") and text.contains("viewBox="), "圖示", "SVG 具有根節點與 viewBox", "")
	_check(not text.to_lower().contains("<script") and not text.to_lower().contains("javascript:"), "圖示", "SVG 不含可執行腳本", "")
	var lower := text.to_lower()
	_check(not lower.contains("href=") and not lower.contains("<image") and not lower.contains("url(") and not lower.contains("data:"), "圖示", "SVG 不依賴外部或內嵌遠端資源", "")
	var texture: Texture2D = load(path)
	_check(texture != null and texture.get_width() > 0 and texture.get_height() > 0, "圖示", "Godot 可匯入並解碼 SVG 圖示", "%dx%d" % [texture.get_width(), texture.get_height()] if texture != null else "載入失敗")


func _audit_import_settings(path: String) -> void:
	var import_path := path + ".import"
	var text := FileAccess.get_file_as_string(import_path)
	_check(not text.is_empty(), "匯入", "Godot 圖片匯入設定存在：%s" % path.get_file(), import_path)
	if text.is_empty():
		return
	_check(text.contains('importer="texture"'), "匯入", "圖片使用 Godot texture importer：%s" % path.get_file(), "")
	_check(text.contains("compress/mode=0"), "匯入", "圖片採無損匯入：%s" % path.get_file(), "")
	_check(text.contains("mipmaps/generate=false"), "匯入", "像素圖片不產生 mipmap：%s" % path.get_file(), "")
	_check(text.contains("process/fix_alpha_border=true"), "匯入", "透明邊緣色彩修正啟用：%s" % path.get_file(), "")


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
	var alpha_atlas := String(rule.role) == "alpha_atlas"
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
					if image.get_pixel(x, y).a < 0.02:
						removable_total += 1
		var removable_ratio := float(removable_total) / maxf(1.0, float(remainder_total))
		_check(removable_ratio > 0.995, "圖集", "未使用餘邊只有可移除背景：%s" % path.get_file(), "%.3f%%" % (removable_ratio * 100.0))
	var signatures := PackedStringArray()
	var occupied_cells := 0
	var atlas_transparent_pixels := 0
	var atlas_partial_alpha_pixels := 0
	var atlas_opaque_light_pixels := 0
	for row in rows:
		for column in columns:
			var stats := _cell_stats(image, column * cell_width, row * cell_height, cell_width, cell_height, String(rule.role))
			var occupied := float(stats.luminance_variance) > 0.004 if not alpha_atlas else float(stats.foreground_ratio) > 0.01 and float(stats.foreground_ratio) < 0.80
			if occupied:
				occupied_cells += 1
			_check(occupied, "圖集", "%s 格 %d,%d 含有效且有邊界的圖像" % [path.get_file(), column, row], "foreground=%.2f%%" % (100.0 * float(stats.foreground_ratio)))
			if alpha_atlas:
				_check(float(stats.corner_background_ratio) > 0.98, "圖集", "%s 格 %d,%d 四角為真透明且沒有切格溢出" % [path.get_file(), column, row], "transparent=%.2f%%" % (100.0 * float(stats.corner_background_ratio)))
				_check(float(stats.edge_background_ratio) > 0.95, "圖集", "%s 格 %d,%d 四邊保留透明安全距離" % [path.get_file(), column, row], "transparent=%.2f%%" % (100.0 * float(stats.edge_background_ratio)))
				_check(int(stats.partial_alpha_pixels) == 0, "透明", "%s 格 %d,%d 不含不確定半透明棋盤殘影" % [path.get_file(), column, row], "%d" % int(stats.partial_alpha_pixels))
				var cell_index := row * columns + column
				if cell_index in Array(rule.get("required_light_cells", [])):
					_check(int(stats.opaque_light_pixels) > 5, "透明", "%s 格 %d,%d 保留白色動物／產物內容" % [path.get_file(), column, row], "%d sampled pixels" % int(stats.opaque_light_pixels))
				atlas_transparent_pixels += int(stats.transparent_pixels)
				atlas_partial_alpha_pixels += int(stats.partial_alpha_pixels)
				atlas_opaque_light_pixels += int(stats.opaque_light_pixels)
			signatures.append(String(stats.signature))
	_check(occupied_cells == int(rule.cells), "圖集", "所有預期圖格均非空白：%s" % path.get_file(), "%d/%d" % [occupied_cells, int(rule.cells)])
	if alpha_atlas:
		_check(atlas_transparent_pixels > 0, "透明", "圖集使用真正 alpha 而非烘焙棋盤格：%s" % path.get_file(), "%d sampled transparent pixels" % atlas_transparent_pixels)
		_check(atlas_partial_alpha_pixels == 0, "透明", "圖集 alpha 為確定的像素級遮罩：%s" % path.get_file(), "%d sampled partial pixels" % atlas_partial_alpha_pixels)
		_check(atlas_opaque_light_pixels > 0, "透明", "圖集仍保留不應被色鍵移除的亮色前景：%s" % path.get_file(), "%d sampled pixels" % atlas_opaque_light_pixels)
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


func _cell_stats(image: Image, start_x: int, start_y: int, width: int, height: int, role: String) -> Dictionary:
	var foreground := 0
	var samples := 0
	var transparent_pixels := 0
	var partial_alpha_pixels := 0
	var opaque_light_pixels := 0
	var signature_bytes := PackedByteArray()
	var luminance_sum := 0.0
	var luminance_squared_sum := 0.0
	for sample_y in 32:
		for sample_x in 32:
			var x := start_x + mini(width - 1, floori((sample_x + 0.5) * width / 32.0))
			var y := start_y + mini(height - 1, floori((sample_y + 0.5) * height / 32.0))
			var color := image.get_pixel(x, y)
			var is_background := color.a < 0.02 if role == "alpha_atlas" else false
			if not is_background:
				foreground += 1
			if color.a < 0.02:
				transparent_pixels += 1
			elif color.a < 0.98:
				partial_alpha_pixels += 1
			else:
				var channel_min := minf(color.r, minf(color.g, color.b))
				var channel_max := maxf(color.r, maxf(color.g, color.b))
				if channel_min > CHROMA_THRESHOLD and channel_max - channel_min < 0.12:
					opaque_light_pixels += 1
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
				if color.a < 0.02:
					corner_background += 1
				corner_samples += 1
	var edge_background := 0
	var edge_samples := 0
	var edge_step := maxi(1, mini(width, height) / 96)
	for x in range(0, width, edge_step):
		for y in [0, height - 1]:
			if image.get_pixel(start_x + x, start_y + y).a < 0.02:
				edge_background += 1
			edge_samples += 1
	for y in range(0, height, edge_step):
		for x in [0, width - 1]:
			if image.get_pixel(start_x + x, start_y + y).a < 0.02:
				edge_background += 1
			edge_samples += 1
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(signature_bytes)
	var mean := luminance_sum / float(samples)
	return {
		"foreground_ratio": float(foreground) / float(samples),
		"corner_background_ratio": float(corner_background) / float(corner_samples),
		"edge_background_ratio": float(edge_background) / float(edge_samples),
		"transparent_pixels":transparent_pixels,
		"partial_alpha_pixels":partial_alpha_pixels,
		"opaque_light_pixels":opaque_light_pixels,
		"luminance_variance": luminance_squared_sum / float(samples) - mean * mean,
		"signature": hash.finish().hex_encode(),
	}


func _audit_alpha_source_regression(path: String, output: Image, source_path: String, _rule: Dictionary) -> void:
	_check(not source_path.is_empty() and FileAccess.file_exists(source_path), "來源", "透明圖集保留可追溯原稿：%s" % path.get_file(), source_path)
	if source_path.is_empty() or not FileAccess.file_exists(source_path):
		return
	var expected_source_hash := String(SOURCE_HASHES.get(source_path, ""))
	var source_bytes := FileAccess.get_file_as_bytes(source_path)
	var source_hash_context := HashingContext.new()
	source_hash_context.start(HashingContext.HASH_SHA256)
	source_hash_context.update(source_bytes)
	var actual_source_hash: String = source_hash_context.finish().hex_encode()
	_check(not expected_source_hash.is_empty() and actual_source_hash == expected_source_hash, "來源", "原稿 SHA-256 與來源證據一致：%s" % source_path.get_file(), actual_source_hash)
	var source := Image.new()
	var error := source.load_png_from_buffer(source_bytes)
	_check(error == OK, "來源", "棋盤格原稿可完整解碼：%s" % source_path.get_file(), error_string(error))
	if error != OK:
		return
	source.convert(Image.FORMAT_RGBA8)
	_check(output.get_width() >= source.get_width() and output.get_height() >= source.get_height(), "來源", "透明衍生圖只增加安全留白、不縮小原稿畫布：%s" % path.get_file(), "%s -> %s" % [source.get_size(), output.get_size()])
	_check(output.get_width() <= 4096 and output.get_height() <= 4096, "來源", "重新排格後仍在商業紋理限制內：%s" % path.get_file(), "%s" % output.get_size())
	var definite_foreground_pixels := 0
	for y in source.get_height():
		for x in source.get_width():
			if not _is_chroma_background(source.get_pixel(x, y)):
				definite_foreground_pixels += 1
	var output_foreground_pixels := 0
	var retained_light_pixels := 0
	var transparent_pixels := 0
	for y in output.get_height():
		for x in output.get_width():
			var after := output.get_pixel(x, y)
			if after.a < 0.02:
				transparent_pixels += 1
			else:
				output_foreground_pixels += 1
				if _is_chroma_background(after):
					retained_light_pixels += 1
	_check(output_foreground_pixels >= definite_foreground_pixels, "來源", "所有明確非背景像素均保留：%s" % path.get_file(), "%d >= %d" % [output_foreground_pixels, definite_foreground_pixels])
	_check(transparent_pixels > 0, "來源", "透明化確實移除與外緣連通的棋盤背景：%s" % path.get_file(), "%d pixels" % transparent_pixels)
	_check(retained_light_pixels > 0, "來源", "透明化保留被輪廓包住的白色內容：%s" % path.get_file(), "%d pixels" % retained_light_pixels)
	var preprocessing := _atlas_preprocessing_entry(path)
	_check(not preprocessing.is_empty() and bool(preprocessing.get("passed", false)), "來源", "透明衍生圖具有成功的可重現預處理紀錄：%s" % path.get_file(), "")
	if preprocessing.is_empty():
		return
	_check(int(preprocessing.get("foreground_pixels_before_repack", -1)) == int(preprocessing.get("foreground_pixels_after_repack", -2)), "來源", "重新排格沒有遺失任何前景像素：%s" % path.get_file(), "%d -> %d" % [int(preprocessing.get("foreground_pixels_before_repack", -1)), int(preprocessing.get("foreground_pixels_after_repack", -2))])
	_check(int(preprocessing.get("foreground_pixels_after_repack", -1)) == output_foreground_pixels, "來源", "預處理紀錄與成品前景像素數一致：%s" % path.get_file(), "%d/%d" % [int(preprocessing.get("foreground_pixels_after_repack", -1)), output_foreground_pixels])
	var cell_components: Array = preprocessing.get("cell_components", [])
	_check(cell_components.size() == int(_rule.cells) and cell_components.all(func(value: Variant) -> bool: return int(value) > 0), "來源", "每個圖格均取得至少一個連通前景元件：%s" % path.get_file(), str(cell_components))


func _atlas_preprocessing_entry(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://reports/atlas_preprocessing/report.json"))
	if not parsed is Dictionary:
		return {}
	for entry: Dictionary in parsed.get("atlases", []):
		if String(entry.get("output", "")) == path:
			return entry
	return {}


func _is_chroma_background(color: Color) -> bool:
	var channel_min := minf(color.r, minf(color.g, color.b))
	var channel_max := maxf(color.r, maxf(color.g, color.b))
	return color.a < 0.02 or (channel_min > MATTE_THRESHOLD and channel_max - channel_min < 0.14)


func _audit_preprocessing_policy() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://reports/atlas_preprocessing/report.json"))
	_check(parsed is Dictionary, "去背", "可讀取可重現的圖集去背報告", "reports/atlas_preprocessing/report.json")
	if not parsed is Dictionary:
		return
	var report: Dictionary = parsed
	_check(bool(report.get("passed", false)), "去背", "五張疊加圖集的去背流程全部成功", str(report.get("passed", false)))
	_check(float(report.get("light_threshold", 1.0)) <= MATTE_THRESHOLD, "去背", "外緣中性淺色去背門檻足以清除灰白光暈", "threshold=%.2f" % float(report.get("light_threshold", 1.0)))
	_check(String(report.get("algorithm", "")).contains("neutral-matte"), "去背", "預處理明確使用中性底色遮罩政策", String(report.get("algorithm", "")))
	var entries: Array = report.get("atlases", [])
	_check(entries.size() == 5, "去背", "所有角色、怪物、玩家、動物與異形圖集均納入去背", "%d/5" % entries.size())
	var by_name := {}
	for entry: Dictionary in entries:
		by_name[String(entry.get("output", "")).get_file()] = entry
	for file_name in ["character_atlas_alpha.png", "player_walk_atlas_alpha.png", "animal_atlas_alpha.png"]:
		var entry: Dictionary = by_name.get(file_name, {})
		_check(String(entry.get("background_neighbourhood", "")) == "four" and int(entry.get("enclosed_neutral_removed_pixels", -1)) == 0, "去背", "%s 保留被輪廓保護的白色內容" % file_name, "four-neighbour, enclosed=%d" % int(entry.get("enclosed_neutral_removed_pixels", -1)))
	var enemy: Dictionary = by_name.get("enemy_atlas_alpha.png", {})
	_check(String(enemy.get("background_neighbourhood", "")) == "eight" and int(enemy.get("enclosed_neutral_removed_pixels", 0)) > 0, "去背", "敵人圖集清除肢體凹槽內封閉的白色棋盤底", "enclosed=%d" % int(enemy.get("enclosed_neutral_removed_pixels", 0)))
	var eldritch: Dictionary = by_name.get("eldritch_drowned_dreamer_alpha.png", {})
	_check(String(eldritch.get("background_neighbourhood", "")) == "eight" and int(eldritch.get("enclosed_neutral_removed_pixels", 0)) > 0, "去背", "異形 Boss 清除外緣與封閉底色且保留中央亮部", "enclosed=%d" % int(eldritch.get("enclosed_neutral_removed_pixels", 0)))


func _audit_all_visual_evidence() -> void:
	var evidence_count := 0
	for directory_path: String in EVIDENCE_SETS:
		var config := Dictionary(EVIDENCE_SETS[directory_path])
		evidence_count += _audit_evidence_set(directory_path, config)
	evidence_count += _audit_resolution_evidence()
	_check(evidence_count == 47, "畫面證據", "所有商業畫面、實機驗收、去背對比與解析度證據均納入統一閘門", "%d/47" % evidence_count)


func _audit_evidence_set(directory_path: String, config: Dictionary) -> int:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		_check(false, "畫面證據", "可讀取畫面集合：%s" % directory_path, "目錄不存在")
		return 0
	var names := PackedStringArray()
	for file_name in directory.get_files():
		if file_name.to_lower().ends_with(".png"):
			names.append(file_name)
	names.sort()
	_check(names.size() == int(config.count), "畫面證據", "畫面集合數量完整：%s" % directory_path, "%d/%d" % [names.size(), int(config.count)])
	var signatures := {}
	for file_name: String in names:
		var signature := _audit_evidence_image(directory_path.path_join(file_name), Vector2i(int(config.width), int(config.height)))
		if not signature.is_empty():
			signatures[signature] = true
	_check(signatures.size() == names.size(), "畫面證據", "同一集合的每張畫面內容均可區分：%s" % directory_path, "%d/%d unique" % [signatures.size(), names.size()])
	return names.size()


func _audit_resolution_evidence() -> int:
	var directory_path := "res://reports/resolution_layout"
	var directory := DirAccess.open(directory_path)
	if directory == null:
		_check(false, "畫面證據", "可讀取多解析度畫面集合", "目錄不存在")
		return 0
	var names := PackedStringArray()
	for file_name in directory.get_files():
		if file_name.to_lower().ends_with(".png"):
			names.append(file_name)
	names.sort()
	_check(names.size() == RESOLUTION_EVIDENCE.size(), "畫面證據", "五種整數縮放解析度畫面齊全（含 1280×800）", "%d/%d" % [names.size(), RESOLUTION_EVIDENCE.size()])
	for file_name: String in names:
		_check(RESOLUTION_EVIDENCE.has(file_name), "畫面證據", "解析度畫面檔名受契約約束：%s" % file_name, "")
		if RESOLUTION_EVIDENCE.has(file_name):
			_audit_evidence_image(directory_path.path_join(file_name), Vector2i(RESOLUTION_EVIDENCE[file_name]))
	return names.size()


func _audit_evidence_image(path: String, expected_size: Vector2i) -> String:
	var image := Image.new()
	var error := image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
	_check(error == OK, "畫面證據", "PNG 可完整解碼：%s" % path.get_file(), error_string(error))
	if error != OK:
		return ""
	_check(image.get_size() == expected_size, "畫面證據", "畫面解析度正確：%s" % path.get_file(), "%s" % image.get_size())
	var stats := _evidence_stats(image)
	_check(float(stats.luminance_variance) > 0.002, "畫面證據", "畫面不是空白或單色：%s" % path.get_file(), "variance=%.5f" % float(stats.luminance_variance))
	_check(int(stats.distinct_colors) >= 16, "畫面證據", "畫面具有足夠視覺內容：%s" % path.get_file(), "%d sampled colors" % int(stats.distinct_colors))
	_check(float(stats.dark_ratio) < 0.95 and float(stats.bright_ratio) < 0.95, "畫面證據", "畫面未全黑或全白：%s" % path.get_file(), "dark=%.1f%% bright=%.1f%%" % [100.0 * float(stats.dark_ratio), 100.0 * float(stats.bright_ratio)])
	_check(int(stats.transparent_pixels) == 0, "畫面證據", "商業截圖為完整不透明畫面：%s" % path.get_file(), "%d sampled transparent pixels" % int(stats.transparent_pixels))
	return String(stats.signature)


func _evidence_stats(image: Image) -> Dictionary:
	var samples := 0
	var luminance_sum := 0.0
	var luminance_squared_sum := 0.0
	var dark := 0
	var bright := 0
	var transparent := 0
	var colors := {}
	var signature_bytes := PackedByteArray()
	for sample_y in 36:
		for sample_x in 64:
			var x := mini(image.get_width() - 1, floori((sample_x + 0.5) * image.get_width() / 64.0))
			var y := mini(image.get_height() - 1, floori((sample_y + 0.5) * image.get_height() / 36.0))
			var color := image.get_pixel(x, y)
			var luminance := color.get_luminance()
			luminance_sum += luminance
			luminance_squared_sum += luminance * luminance
			if luminance < 0.04:
				dark += 1
			if luminance > 0.96:
				bright += 1
			if color.a < 0.98:
				transparent += 1
			var r := clampi(roundi(color.r * 31.0), 0, 31)
			var g := clampi(roundi(color.g * 31.0), 0, 31)
			var b := clampi(roundi(color.b * 31.0), 0, 31)
			colors[(r << 10) | (g << 5) | b] = true
			signature_bytes.append(r)
			signature_bytes.append(g)
			signature_bytes.append(b)
			samples += 1
	var mean := luminance_sum / float(samples)
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(signature_bytes)
	return {
		"luminance_variance":luminance_squared_sum / float(samples) - mean * mean,
		"dark_ratio":float(dark) / float(samples),
		"bright_ratio":float(bright) / float(samples),
		"transparent_pixels":transparent,
		"distinct_colors":colors.size(),
		"signature":hash.finish().hex_encode(),
	}


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
		"本閘門自動盤點並直接解碼全部 Runtime PNG 與 SVG 圖示，驗證資產登錄、無損匯入、真 alpha、可追溯原稿、灰白光暈清除、亮色內容保留、格線安全邊界、動畫幀差異，以及 47 張實機／Studio／解析度／去背對比／商業宣傳畫面。",
		"",
		"| 分類 | 項目 | 結果 | 細節 |",
		"|---|---|---:|---|",
	])
	for item: Dictionary in cases:
		lines.append("| %s | %s | %s | %s |" % [item.category, String(item.name).replace("|", "\\|"), "通過" if item.passed else "失敗", String(item.detail).replace("|", "\\|")])
	var report_file := FileAccess.open(REPORT_MARKDOWN, FileAccess.WRITE)
	if report_file != null:
		report_file.store_string("\n".join(lines) + "\n")
