extends SceneTree

const REPORT_DIRECTORY := "res://reports/atlas_preprocessing"
const REPORT_PATH := REPORT_DIRECTORY + "/report.json"
const LIGHT_THRESHOLD := 0.55
const NEUTRAL_SPREAD := 0.14

const ATLASES := [
	{
		"source":"res://assets/source/generated_atlases/character_atlas_checkerboard_source.png",
		"output":"res://assets/runtime/sprites/character_atlas_alpha.png",
		"columns":4,
		"rows":3,
	},
	{
		"source":"res://assets/source/generated_atlases/enemy_atlas_checkerboard_source.png",
		"output":"res://assets/runtime/sprites/enemy_atlas_alpha.png",
		"columns":4,
		"rows":4,
		"diagonal_background":true,
		"clear_enclosed_neutral_min_pixels":100,
		"clear_enclosed_neutral_cells":[12, 14, 15],
		"enclosed_light_threshold":0.76,
	},
	{
		"source":"res://assets/source/generated_atlases/animal_atlas_checkerboard_source.png",
		"output":"res://assets/runtime/sprites/animal_atlas_alpha.png",
		"columns":4,
		"rows":2,
	},
	{
		"source":"res://assets/source/generated_atlases/player_walk_atlas_checkerboard_source.png",
		"output":"res://assets/runtime/sprites/player_walk_atlas_alpha.png",
		"columns":4,
		"rows":4,
	},
	{
		"source":"res://assets/source/generated_atlases/eldritch_drowned_dreamer_source.png",
		"output":"res://assets/runtime/sprites/eldritch_drowned_dreamer_alpha.png",
		"columns":1,
		"rows":1,
		"diagonal_background":true,
		"clear_enclosed_neutral_min_pixels":20,
		"preserve_light_rect":Rect2(520, 200, 220, 650),
	},
]

var results: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIRECTORY))
	var failed := false
	for atlas: Dictionary in ATLASES:
		var result := _convert_atlas(atlas)
		results.append(result)
		if not bool(result.get("passed", false)):
			failed = true
	var payload := {
		"generated_at":Time.get_datetime_string_from_system(true),
		"algorithm":"cell-bounded neutral-matte flood fill (four-neighbour by default; eight-neighbour for safe atlases), then lossless connected-component repack with 16px minimum padding",
		"light_threshold":LIGHT_THRESHOLD,
		"neutral_spread":NEUTRAL_SPREAD,
		"passed":not failed,
		"atlases":results,
	}
	var report := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if report != null:
		report.store_string(JSON.stringify(payload, "\t", false) + "\n")
	if failed:
		for result: Dictionary in results:
			if not bool(result.get("passed", false)):
				push_error("Atlas preprocessing failed: %s" % result)
		quit(1)
	else:
		print("Transparent atlas preprocessing: PASS (%d atlases)" % results.size())
		quit(0)


func _convert_atlas(config: Dictionary) -> Dictionary:
	var source_path := String(config.source)
	var output_path := String(config.output)
	var source := Image.new()
	var load_error := source.load_png_from_buffer(FileAccess.get_file_as_bytes(source_path))
	if load_error != OK:
		return {"passed":false,"source":source_path,"output":output_path,"error":error_string(load_error)}
	source.convert(Image.FORMAT_RGBA8)
	var output := source.duplicate()
	var width: int = output.get_width()
	var height: int = output.get_height()
	var columns := int(config.columns)
	var rows := int(config.rows)
	var cell_width: int = width / columns
	var cell_height: int = height / rows
	var removed := 0
	var connected_removed_total := 0
	var enclosed_removed_total := 0
	var removed_per_cell: Array[int] = []
	var enclosed_removed_per_cell: Array[int] = []
	for row in rows:
		for column in columns:
			var left: int = column * cell_width
			var top: int = row * cell_height
			var right: int = width if column == columns - 1 else (column + 1) * cell_width
			var bottom: int = height if row == rows - 1 else (row + 1) * cell_height
			var connected_removed := _clear_connected_background(output, left, top, right, bottom, bool(config.get("diagonal_background", false)))
			var cell_removed := connected_removed
			var enclosed_removed := 0
			connected_removed_total += connected_removed
			var cell_index := row * columns + column
			var enclosed_threshold := int(config.get("clear_enclosed_neutral_min_pixels", 0))
			var enclosed_cells: Array = config.get("clear_enclosed_neutral_cells", [])
			if enclosed_threshold > 0 and (enclosed_cells.is_empty() or cell_index in enclosed_cells):
				enclosed_removed = _clear_large_neutral_components(
					output,
					left,
					top,
					right,
					bottom,
					enclosed_threshold,
					Rect2(config.get("preserve_light_rect", Rect2())),
					float(config.get("enclosed_light_threshold", LIGHT_THRESHOLD)),
					float(config.get("enclosed_neutral_spread", NEUTRAL_SPREAD))
				)
				cell_removed += enclosed_removed
				enclosed_removed_total += enclosed_removed
			removed += cell_removed
			removed_per_cell.append(cell_removed)
			enclosed_removed_per_cell.append(enclosed_removed)
	var repacked: Dictionary = _repack_components(output, columns, rows)
	output = repacked.image as Image
	width = output.get_width()
	height = output.get_height()
	var save_error: Error = output.save_png(output_path)
	var transparent := 0
	var preserved := 0
	for y in height:
		for x in width:
			if output.get_pixel(x, y).a < 0.02:
				transparent += 1
			else:
				preserved += 1
	var total: int = width * height
	var every_cell_removed := removed_per_cell.all(func(value: int) -> bool: return value > 0)
	return {
		"passed":save_error == OK and removed > 0 and preserved > 0 and every_cell_removed,
		"source":source_path,
		"output":output_path,
		"width":width,
		"height":height,
		"columns":columns,
		"rows":rows,
		"background_neighbourhood":"eight" if bool(config.get("diagonal_background", false)) else "four",
		"removed_pixels":removed,
		"connected_background_removed_pixels":connected_removed_total,
		"enclosed_neutral_removed_pixels":enclosed_removed_total,
		"transparent_pixels":transparent,
		"preserved_pixels":preserved,
		"transparent_ratio":float(transparent) / float(total),
		"removed_per_cell":removed_per_cell,
		"enclosed_removed_per_cell":enclosed_removed_per_cell,
		"component_count":int(repacked.component_count),
		"cell_components":repacked.cell_components,
		"cell_bounds":repacked.cell_bounds,
		"foreground_pixels_before_repack":int(repacked.foreground_pixels_before),
		"foreground_pixels_after_repack":preserved,
		"save_error":error_string(save_error),
	}


func _repack_components(source: Image, columns: int, rows: int) -> Dictionary:
	var source_width := source.get_width()
	var source_height := source.get_height()
	var visited := PackedByteArray()
	visited.resize(source_width * source_height)
	var groups: Array[Dictionary] = []
	for _index in columns * rows:
		groups.append({"pixels":PackedInt32Array(),"min_x":source_width,"min_y":source_height,"max_x":-1,"max_y":-1,"components":0})
	var component_count := 0
	var foreground_pixels := 0
	for y in source_height:
		for x in source_width:
			var start := y * source_width + x
			if visited[start] != 0 or source.get_pixel(x, y).a < 0.02:
				continue
			component_count += 1
			var queue := PackedInt32Array([start])
			visited[start] = 1
			var cursor := 0
			var sum_x := 0
			var sum_y := 0
			while cursor < queue.size():
				var packed := queue[cursor]
				cursor += 1
				var current_x := packed % source_width
				var current_y: int = packed / source_width
				sum_x += current_x
				sum_y += current_y
				for offset_y in range(-1, 2):
					for offset_x in range(-1, 2):
						if offset_x == 0 and offset_y == 0:
							continue
						var next_x := current_x + offset_x
						var next_y := current_y + offset_y
						if next_x < 0 or next_x >= source_width or next_y < 0 or next_y >= source_height:
							continue
						var next := next_y * source_width + next_x
						if visited[next] != 0 or source.get_pixel(next_x, next_y).a < 0.02:
							continue
						visited[next] = 1
						queue.append(next)
			foreground_pixels += queue.size()
			var center_x := float(sum_x) / float(queue.size())
			var center_y := float(sum_y) / float(queue.size())
			var column := clampi(floori(center_x * columns / float(source_width)), 0, columns - 1)
			var row := clampi(floori(center_y * rows / float(source_height)), 0, rows - 1)
			var group_index := row * columns + column
			var group: Dictionary = groups[group_index]
			var pixels: PackedInt32Array = group.pixels
			pixels.append_array(queue)
			group.pixels = pixels
			group.components = int(group.components) + 1
			for packed in queue:
				var pixel_x := packed % source_width
				var pixel_y: int = packed / source_width
				group.min_x = mini(int(group.min_x), pixel_x)
				group.min_y = mini(int(group.min_y), pixel_y)
				group.max_x = maxi(int(group.max_x), pixel_x)
				group.max_y = maxi(int(group.max_y), pixel_y)
			groups[group_index] = group
	var source_cell_width := ceili(float(source_width) / float(columns))
	var source_cell_height := ceili(float(source_height) / float(rows))
	var target_cell_width := source_cell_width
	var target_cell_height := source_cell_height
	for group: Dictionary in groups:
		if PackedInt32Array(group.pixels).is_empty():
			continue
		target_cell_width = maxi(target_cell_width, int(group.max_x) - int(group.min_x) + 33)
		target_cell_height = maxi(target_cell_height, int(group.max_y) - int(group.min_y) + 33)
	var output := Image.create(target_cell_width * columns, target_cell_height * rows, false, Image.FORMAT_RGBA8)
	output.fill(Color(0.0, 0.0, 0.0, 0.0))
	var cell_components: Array[int] = []
	var cell_bounds: Array[Dictionary] = []
	for group_index in groups.size():
		var group: Dictionary = groups[group_index]
		var pixels: PackedInt32Array = group.pixels
		cell_components.append(int(group.components))
		if pixels.is_empty():
			cell_bounds.append({"width":0,"height":0})
			continue
		var bounds_width := int(group.max_x) - int(group.min_x) + 1
		var bounds_height := int(group.max_y) - int(group.min_y) + 1
		cell_bounds.append({"width":bounds_width,"height":bounds_height})
		var target_column := group_index % columns
		var target_row: int = group_index / columns
		var offset_x := target_column * target_cell_width + (target_cell_width - bounds_width) / 2 - int(group.min_x)
		var offset_y := target_row * target_cell_height + (target_cell_height - bounds_height) / 2 - int(group.min_y)
		for packed in pixels:
			var source_x := packed % source_width
			var source_y: int = packed / source_width
			output.set_pixel(source_x + offset_x, source_y + offset_y, source.get_pixel(source_x, source_y))
	return {
		"image":output,
		"component_count":component_count,
		"cell_components":cell_components,
		"cell_bounds":cell_bounds,
		"foreground_pixels_before":foreground_pixels,
	}


func _clear_connected_background(image: Image, left: int, top: int, right: int, bottom: int, diagonal_background: bool = false) -> int:
	var width := image.get_width()
	var visited := PackedByteArray()
	visited.resize(width * image.get_height())
	var queue := PackedInt32Array()
	for x in range(left, right):
		_try_enqueue(image, x, top, visited, queue)
		_try_enqueue(image, x, bottom - 1, visited, queue)
	for y in range(top, bottom):
		_try_enqueue(image, left, y, visited, queue)
		_try_enqueue(image, right - 1, y, visited, queue)
	var cursor := 0
	while cursor < queue.size():
		var packed := queue[cursor]
		cursor += 1
		var x := packed % width
		var y: int = packed / width
		for offset_y in range(-1, 2):
			for offset_x in range(-1, 2):
				if offset_x == 0 and offset_y == 0:
					continue
				if not diagonal_background and offset_x != 0 and offset_y != 0:
					continue
				_try_enqueue_bounded(image, x + offset_x, y + offset_y, left, top, right, bottom, visited, queue)
	for packed in queue:
		var x := packed % width
		var y: int = packed / width
		var color := image.get_pixel(x, y)
		color.a = 0.0
		image.set_pixel(x, y, color)
	return queue.size()


func _clear_large_neutral_components(image: Image, left: int, top: int, right: int, bottom: int, minimum_pixels: int, preserve_light_rect: Rect2, light_threshold: float, neutral_spread: float) -> int:
	var width := image.get_width()
	var visited := PackedByteArray()
	visited.resize(width * image.get_height())
	var removed := 0
	for start_y in range(top, bottom):
		for start_x in range(left, right):
			var start := start_y * width + start_x
			if visited[start] != 0:
				continue
			visited[start] = 1
			if not _is_enclosed_neutral_candidate(image.get_pixel(start_x, start_y), light_threshold, neutral_spread):
				continue
			var component := PackedInt32Array([start])
			var cursor := 0
			while cursor < component.size():
				var packed := component[cursor]
				cursor += 1
				var x := packed % width
				var y: int = packed / width
				for offset_y in range(-1, 2):
					for offset_x in range(-1, 2):
						if offset_x == 0 and offset_y == 0:
							continue
						var next_x := x + offset_x
						var next_y := y + offset_y
						if next_x < left or next_x >= right or next_y < top or next_y >= bottom:
							continue
						var next := next_y * width + next_x
						if visited[next] != 0:
							continue
						visited[next] = 1
						if _is_enclosed_neutral_candidate(image.get_pixel(next_x, next_y), light_threshold, neutral_spread):
							component.append(next)
			if component.size() < minimum_pixels:
				continue
			var center := Vector2.ZERO
			for packed in component:
				center += Vector2(packed % width, packed / width)
			center /= float(component.size())
			if preserve_light_rect.has_area() and preserve_light_rect.has_point(center):
				continue
			for packed in component:
				var x := packed % width
				var y: int = packed / width
				var color := image.get_pixel(x, y)
				color.a = 0.0
				image.set_pixel(x, y, color)
			removed += component.size()
	return removed


func _try_enqueue_bounded(image: Image, x: int, y: int, left: int, top: int, right: int, bottom: int, visited: PackedByteArray, queue: PackedInt32Array) -> void:
	if x < left or x >= right or y < top or y >= bottom:
		return
	_try_enqueue(image, x, y, visited, queue)


func _try_enqueue(image: Image, x: int, y: int, visited: PackedByteArray, queue: PackedInt32Array) -> void:
	var packed := y * image.get_width() + x
	if visited[packed] != 0:
		return
	visited[packed] = 1
	if _is_background_candidate(image.get_pixel(x, y)):
		queue.append(packed)


func _is_background_candidate(color: Color, light_threshold: float = LIGHT_THRESHOLD, neutral_spread: float = NEUTRAL_SPREAD) -> bool:
	if color.a < 0.02:
		return true
	var channel_min := minf(color.r, minf(color.g, color.b))
	var channel_max := maxf(color.r, maxf(color.g, color.b))
	return channel_min > light_threshold and channel_max - channel_min < neutral_spread


func _is_enclosed_neutral_candidate(color: Color, light_threshold: float, neutral_spread: float) -> bool:
	if color.a < 0.02:
		return false
	var channel_min := minf(color.r, minf(color.g, color.b))
	var channel_max := maxf(color.r, maxf(color.g, color.b))
	return channel_min > light_threshold and channel_max - channel_min < neutral_spread
