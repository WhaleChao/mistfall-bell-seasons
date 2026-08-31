extends SceneTree

const REPORT_DIRECTORY := "res://reports/commercial_stress"
const REPORT_JSON := REPORT_DIRECTORY + "/report.json"
const REPORT_MARKDOWN := REPORT_DIRECTORY + "/REPORT.md"
const SIMULATION_DAYS := 12000
const SAVE_CYCLES := 250
var cases: Array[Dictionary] = []
var metrics := {}
var game_state: Node
var save_manager: Node
var quick_save_path := ""
var quick_save_temp_path := ""
var quick_save_backup_path := ""
var quick_save_old_backup_path := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if OS.get_environment("PIXELRPG_TEST_ISOLATED") != "1":
		push_error("Commercial stress test requires an isolated user data directory")
		quit(2)
		return
	game_state = root.get_node_or_null("GameState")
	save_manager = root.get_node_or_null("SaveManager")
	if game_state == null or save_manager == null:
		push_error("Project autoloads were not initialized")
		quit(2)
		return
	quick_save_path = String(save_manager.quick_save_path())
	quick_save_temp_path = quick_save_path + ".tmp"
	quick_save_backup_path = quick_save_path + ".bak"
	quick_save_old_backup_path = quick_save_path + ".bak.old"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIRECTORY))
	var started := Time.get_ticks_msec()
	_test_century_simulation()
	_test_save_roundtrips()
	metrics["elapsed_seconds"] = snappedf((Time.get_ticks_msec() - started) / 1000.0, 0.001)
	_write_report()
	var failed := cases.filter(func(item: Dictionary) -> bool: return not bool(item.passed)).size()
	if failed == 0:
		print("PixelRPG commercial stress gate: PASS (%d days, %d saves, %.3fs)" % [SIMULATION_DAYS, SAVE_CYCLES, metrics.elapsed_seconds])
		quit(0)
	else:
		for item: Dictionary in cases:
			if not bool(item.passed):
				push_error("%s / %s: %s" % [item.category, item.name, item.detail])
		quit(1)


func _test_century_simulation() -> void:
	game_state.reset()
	game_state.farm.rank = 10
	game_state.farm.greenhouse_unlocked = true
	var chicken: Dictionary = game_state.farm.purchase_animal("chicken")
	var cow: Dictionary = game_state.farm.purchase_animal("cow")
	_check(bool(chicken.get("ok", false)) and bool(cow.get("ok", false)), "百年模擬", "初始雞牛狀態建立成功", "")
	var automation_placements := [
		[Vector2i(0, 0), "bell_generator", 100], [Vector2i(0, 1), "bell_generator", 100],
		[Vector2i(1, 0), "mist_pump", 95], [Vector2i(1, 1), "copper_conveyor", 90],
		[Vector2i(2, 0), "field_sprinkler", 85], [Vector2i(2, 1), "crop_harvester", 80],
		[Vector2i(2, 2), "seed_distributor", 75], [Vector2i(3, 1), "preserves_processor", 70],
		[Vector2i(4, 1), "animal_feeder", 65], [Vector2i(5, 1), "tide_condenser", 60],
	]
	var automation_installed := true
	for placement: Array in automation_placements:
		var placed: Dictionary = game_state.farm.place_automation_device(placement[0], StringName(placement[1]), {"priority":placement[2], "crop_filter":"spring_turnip"})
		automation_installed = automation_installed and bool(placed.get("ok", false))
	_check(automation_installed and game_state.farm.automation_devices.size() == 10 and game_state.farm.automation_networks().size() == 1, "百年自動化", "十台設備與銅軌組成單一能源網", "%d devices / %d network" % [game_state.farm.automation_devices.size(), game_state.farm.automation_networks().size()])
	game_state.farm.seed_stock["spring_turnip"] = SIMULATION_DAYS * 2
	game_state.inventory["animal_feed"] = SIMULATION_DAYS * 2
	game_state.inventory["mist_shard"] = SIMULATION_DAYS
	var tide_fish_id := ""
	for fish: Dictionary in root.get_node("ContentRegistry").get_all("fish"):
		if bool(fish.get("tide_required", false)):
			tide_fish_id = String(fish.get("id", ""))
			break
	game_state.farm.produce[tide_fish_id] = SIMULATION_DAYS
	game_state.social.add_affection(&"mira", 2500)
	game_state.social.start_dating(&"mira")
	game_state.social.marry(&"mira", game_state.calendar.absolute_day())
	var roundtrips := 0
	var festivals_seen := 0
	var severe_forecasts := 0
	var generated_requests := 0
	var automation_stalls := 0
	var automation_roundtrips := 0
	var allowed_weather := ["clear", "rain", "storm", "fog", "typhoon", "snow", "blizzard"]
	for elapsed_day in SIMULATION_DAYS:
		var result: Dictionary = game_state.advance_day(true)
		if result.is_empty():
			_check(false, "百年模擬", "每日結算不會重入失敗", "day=%d" % elapsed_day)
			break
		if game_state.calendar.absolute_day() != elapsed_day + 2:
			_check(false, "百年模擬", "絕對日期無漂移", "day=%d absolute=%d" % [elapsed_day, game_state.calendar.absolute_day()])
			break
		if game_state.current_weather not in allowed_weather:
			_check(false, "百年模擬", "天氣值永遠合法", game_state.current_weather)
			break
		if not Dictionary(result.get("festival", {})).is_empty():
			festivals_seen += 1
		var forecast: Dictionary = PixelRPGCalendarSystem.forecast_for_tomorrow(game_state.calendar.year, game_state.calendar.season_index, game_state.calendar.day)
		if bool(forecast.get("warning", false)):
			severe_forecasts += 1
		if game_state.calendar.year >= 4:
			generated_requests += game_state.request_board.active_requests.size()
		var automation: Dictionary = result.get("automation", {})
		automation_stalls += int(automation.get("stalled", 0))
		if (elapsed_day + 1) % 30 == 0:
			var before_absolute: int = game_state.calendar.absolute_day()
			var before_year: int = game_state.calendar.year
			var before_weather: String = game_state.current_weather
			var encoded := JSON.stringify(game_state.to_save_data(), "", false)
			var decoded: Variant = JSON.parse_string(encoded)
			if not decoded is Dictionary or not game_state.load_save_data(Dictionary(decoded)):
				_check(false, "百年模擬", "每月 SaveGame JSON round-trip", "absolute=%d" % before_absolute)
				break
			if game_state.calendar.absolute_day() != before_absolute or game_state.calendar.year != before_year or game_state.current_weather != before_weather:
				_check(false, "百年模擬", "每月讀檔完整保留日期與天氣", "absolute=%d" % before_absolute)
				break
			roundtrips += 1
			if game_state.farm.automation_devices.size() == 10 and game_state.farm.automation_networks().size() == 1:
				automation_roundtrips += 1
	_check(game_state.calendar.year == 101 and game_state.calendar.season_index == 0 and game_state.calendar.day == 1, "百年模擬", "12,000 日後準確進入第 101 年春 1 日", game_state.calendar.date_text())
	_check(int(game_state.lifetime_stats.get("days_played", 0)) == SIMULATION_DAYS, "百年模擬", "遊玩日數統計無漂移", str(game_state.lifetime_stats.get("days_played", 0)))
	_check(roundtrips == SIMULATION_DAYS / 30, "百年模擬", "400 次每月序列化均成功", "%d/%d" % [roundtrips, SIMULATION_DAYS / 30])
	_check(festivals_seen == SIMULATION_DAYS / 10, "百年模擬", "100 年節慶排程維持每年 12 場", "%d" % festivals_seen)
	_check(severe_forecasts > 0, "百年模擬", "颱風與暴雪預警在長期模擬中可達", "%d" % severe_forecasts)
	_check(generated_requests > 0, "百年模擬", "第 4 年後規則式委託持續生成", "%d" % generated_requests)
	_check(game_state.farm.animals.size() == 2, "百年模擬", "動物資料長期保存且不自行增殖", "%d" % game_state.farm.animals.size())
	_check(game_state.farm.automation_cycle_count == SIMULATION_DAYS and int(game_state.lifetime_stats.get("automation_cycles", 0)) == SIMULATION_DAYS, "百年自動化", "自動鐘網連續執行 12,000 日無漏週期", "%d/%d" % [game_state.farm.automation_cycle_count, SIMULATION_DAYS])
	_check(automation_stalls == 0, "百年自動化", "能源與水量預算百年無停機", "%d stalls" % automation_stalls)
	_check(automation_roundtrips == roundtrips, "百年自動化", "十台設備與單一網路跨 400 次月存檔完整保留", "%d/%d" % [automation_roundtrips, roundtrips])
	_check(int(game_state.lifetime_stats.get("automated_tiles_planted", game_state.lifetime_stats.get("automated_crops_planted", 0))) > 100 and int(game_state.lifetime_stats.get("automated_tiles_watered", 0)) > 100 and int(game_state.lifetime_stats.get("automated_crops_harvested", 0)) > 100, "百年自動化", "播種、澆水與收割形成長期生產循環", "plant=%d water=%d harvest=%d" % [int(game_state.lifetime_stats.get("automated_crops_planted", 0)), int(game_state.lifetime_stats.get("automated_tiles_watered", 0)), int(game_state.lifetime_stats.get("automated_crops_harvested", 0))])
	_check(int(game_state.lifetime_stats.get("automation_animals_fed", 0)) == SIMULATION_DAYS * 2, "百年自動化", "雞與牛每日由餵食鐘照料", "%d/%d" % [int(game_state.lifetime_stats.get("automation_animals_fed", 0)), SIMULATION_DAYS * 2])
	_check(int(game_state.lifetime_stats.get("automation_items_processed", 0)) >= SIMULATION_DAYS and int(game_state.farm.produce.get("dream_tide_salt", 0)) == SIMULATION_DAYS, "百年自動化", "加工槽與深潮凝析器持續產出", "processed=%d salt=%d" % [int(game_state.lifetime_stats.get("automation_items_processed", 0)), int(game_state.farm.produce.get("dream_tide_salt", 0))])
	var final_payload := JSON.stringify(game_state.to_save_data(), "", false)
	_check(final_payload.length() < 1024 * 1024, "百年模擬", "百年存檔維持在 1 MiB 內", "%d bytes" % final_payload.length())
	metrics["simulated_days"] = SIMULATION_DAYS
	metrics["monthly_roundtrips"] = roundtrips
	metrics["festivals_seen"] = festivals_seen
	metrics["severe_forecasts"] = severe_forecasts
	metrics["generated_request_instances"] = generated_requests
	metrics["automation_cycles"] = game_state.farm.automation_cycle_count
	metrics["automation_stalls"] = automation_stalls
	metrics["automation_monthly_roundtrips"] = automation_roundtrips
	metrics["automation_tiles_watered"] = game_state.lifetime_stats.get("automated_tiles_watered", 0)
	metrics["automation_crops_harvested"] = game_state.lifetime_stats.get("automated_crops_harvested", 0)
	metrics["automation_animals_fed"] = game_state.lifetime_stats.get("automation_animals_fed", 0)
	metrics["automation_items_processed"] = game_state.lifetime_stats.get("automation_items_processed", 0)
	metrics["final_save_bytes"] = final_payload.length()


func _test_save_roundtrips() -> void:
	_cleanup_test_saves()
	game_state.reset()
	var successful_cycles := 0
	var expected_backup_coins := 0
	for cycle in SAVE_CYCLES:
		game_state.coins = 1000 + cycle * 17
		game_state.calendar.year = 1 + cycle / 12
		game_state.calendar.season_index = cycle % 4
		game_state.calendar.day = cycle % 30 + 1
		if cycle == SAVE_CYCLES - 2:
			expected_backup_coins = game_state.coins
		if not save_manager.save_quick():
			_check(false, "存檔壓力", "連續存檔不中斷", "cycle=%d" % cycle)
			break
		game_state.coins = -1
		game_state.calendar.year = 999
		if not save_manager.load_quick() or game_state.coins != 1000 + cycle * 17 or game_state.calendar.day != cycle % 30 + 1:
			_check(false, "存檔壓力", "連續存讀完整還原", "cycle=%d coins=%d" % [cycle, game_state.coins])
			break
		successful_cycles += 1
	_check(successful_cycles == SAVE_CYCLES, "存檔壓力", "250 次磁碟存讀 round-trip", "%d/%d" % [successful_cycles, SAVE_CYCLES])
	var corrupt := FileAccess.open(quick_save_path, FileAccess.WRITE)
	if corrupt != null:
		corrupt.store_string("{truncated")
		corrupt.close()
	game_state.coins = -1
	_check(save_manager.load_quick() and game_state.coins == expected_backup_coins, "存檔復原", "主存檔截斷時自動讀取上一份安全備份", "coins=%d expected=%d" % [game_state.coins, expected_backup_coins])
	var recovery_payload: Dictionary = game_state.to_save_data()
	var recovery_player := Dictionary(recovery_payload.get("player", {}))
	recovery_player["coins"] = 77777
	recovery_payload["player"] = recovery_player
	_cleanup_test_saves()
	var temp := FileAccess.open(quick_save_temp_path, FileAccess.WRITE)
	if temp != null:
		temp.store_string(JSON.stringify(recovery_payload, "", false))
		temp.close()
	game_state.coins = -1
	_check(save_manager.load_quick() and game_state.coins == 77777, "存檔復原", "中斷寫入留下的完整暫存檔可復原", "coins=%d" % game_state.coins)
	_cleanup_test_saves()
	var unsupported := FileAccess.open(quick_save_path, FileAccess.WRITE)
	if unsupported != null:
		unsupported.store_string('{"schema_version":999}')
		unsupported.close()
	_check(not save_manager.load_quick(), "存檔復原", "未知 schema 版本會明確拒絕", "")
	_cleanup_test_saves()
	metrics["disk_save_cycles"] = successful_cycles


func _cleanup_test_saves() -> void:
	for path in [quick_save_path, quick_save_temp_path, quick_save_backup_path, quick_save_old_backup_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _check(condition: bool, category: String, name: String, detail: String) -> void:
	cases.append({"category":category,"name":name,"passed":condition,"detail":detail})


func _write_report() -> void:
	var passed := cases.filter(func(item: Dictionary) -> bool: return bool(item.passed)).size()
	var failed := cases.size() - passed
	var payload := {"generated_at":Time.get_datetime_string_from_system(true),"engine":Engine.get_version_info(),"checks":cases.size(),"passed":passed,"failed":failed,"metrics":metrics,"cases":cases}
	var json_file := FileAccess.open(REPORT_JSON, FileAccess.WRITE)
	if json_file != null:
		json_file.store_string(JSON.stringify(payload, "\t", false))
	var lines := PackedStringArray([
		"# 《霧落農歌：鐘塔之季》商業長期壓力測試",
		"",
		"結果：**%s**　｜　%d 通過／%d 失敗　｜　12,000 遊戲日　｜　250 次磁碟存讀" % ["PASS" if failed == 0 else "FAIL", passed, failed],
		"",
		"此測試在隔離的使用者資料目錄執行，覆蓋百年日期／天氣／節慶／委託、十台設備的播種→澆水→收割→加工、每日動物餵食、深潮凝析、400 次自動網月存檔、磁碟存讀、截斷主檔備份復原、暫存檔復原與未知版本拒絕。",
		"",
		"| 分類 | 項目 | 結果 | 細節 |",
		"|---|---|---:|---|",
	])
	for item: Dictionary in cases:
		lines.append("| %s | %s | %s | %s |" % [item.category, String(item.name).replace("|", "\\|"), "通過" if item.passed else "失敗", String(item.detail).replace("|", "\\|")])
	var report_file := FileAccess.open(REPORT_MARKDOWN, FileAccess.WRITE)
	if report_file != null:
		report_file.store_string("\n".join(lines) + "\n")
