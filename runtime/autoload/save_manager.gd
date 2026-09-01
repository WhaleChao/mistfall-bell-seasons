extends Node

signal quick_load_completed

const QUICK_SAVE_PATH := "user://pixelrpg_quick_save.json"
const QUICK_SAVE_TEMP_PATH := QUICK_SAVE_PATH + ".tmp"
const QUICK_SAVE_BACKUP_PATH := QUICK_SAVE_PATH + ".bak"
const QUICK_SAVE_OLD_BACKUP_PATH := QUICK_SAVE_PATH + ".bak.old"
const TEST_QUICK_SAVE_PATH_ENV := "PIXELRPG_TEST_QUICK_SAVE_PATH"
const DEFAULT_TEST_QUICK_SAVE_PATH := "user://pixelrpg_test_quick_save.json"


func quick_save_path() -> String:
	if OS.get_environment("PIXELRPG_TEST_ISOLATED") == "1":
		var test_path := OS.get_environment(TEST_QUICK_SAVE_PATH_ENV)
		if test_path.begins_with("user://") and test_path.ends_with(".json") and not test_path.contains(".."):
			return test_path
		return DEFAULT_TEST_QUICK_SAVE_PATH
	return QUICK_SAVE_PATH


func _quick_save_paths() -> Dictionary:
	var target := quick_save_path()
	return {
		"target":target,
		"temp":target + ".tmp",
		"backup":target + ".bak",
		"old_backup":target + ".bak.old",
	}


func has_quick_save_candidate() -> bool:
	var paths := _quick_save_paths()
	for candidate: String in [String(paths.target), String(paths.backup), String(paths.old_backup), String(paths.temp)]:
		if not FileAccess.file_exists(candidate):
			continue
		var payload := _read_save_payload(candidate)
		var schema_version := int(payload.get("schema_version", 0))
		if not payload.is_empty() and schema_version >= 1 and schema_version <= GameState.SAVE_SCHEMA_VERSION:
			return true
	return false


func save_quick() -> bool:
	if NetworkManager.is_online():
		EventBus.toast("連線世界不可快速存檔；世界進度由伺服器保存")
		return false
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		GameState.player_position = player.global_position
		var player_health: Variant = player.get("health")
		if player_health != null:
			GameState.player_stats["health"] = int(player_health)
	var payload := GameState.to_save_data()
	payload["saved_at_unix"] = int(Time.get_unix_time_from_system())
	var paths := _quick_save_paths()
	var target_path := String(paths.target)
	var temp_path := String(paths.temp)
	var backup_path := String(paths.backup)
	var old_backup_path := String(paths.old_backup)
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		EventBus.toast("無法建立存檔")
		return false
	file.store_string(JSON.stringify(payload, "\t", false))
	file.flush()
	file.close()
	if _read_save_payload(temp_path).is_empty():
		EventBus.toast("暫存檔驗證失敗，原存檔未變更")
		return false
	var absolute_temp := ProjectSettings.globalize_path(temp_path)
	var absolute_target := ProjectSettings.globalize_path(target_path)
	var absolute_backup := ProjectSettings.globalize_path(backup_path)
	var absolute_old_backup := ProjectSettings.globalize_path(old_backup_path)
	if FileAccess.file_exists(old_backup_path):
		DirAccess.remove_absolute(absolute_old_backup)
	if FileAccess.file_exists(backup_path):
		var old_backup_error := DirAccess.rename_absolute(absolute_backup, absolute_old_backup)
		if old_backup_error != OK:
			EventBus.toast("無法輪替存檔備份：%s" % error_string(old_backup_error))
			return false
	if FileAccess.file_exists(target_path):
		var backup_error := DirAccess.rename_absolute(absolute_target, absolute_backup)
		if backup_error != OK:
			_restore_old_backup(backup_path, old_backup_path, absolute_backup, absolute_old_backup)
			EventBus.toast("無法建立存檔備份：%s" % error_string(backup_error))
			return false
	var rename_error := DirAccess.rename_absolute(absolute_temp, absolute_target)
	if rename_error != OK:
		if not FileAccess.file_exists(target_path) and FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(absolute_backup, absolute_target)
		_restore_old_backup(backup_path, old_backup_path, absolute_backup, absolute_old_backup)
		EventBus.toast("存檔寫入失敗：%s" % error_string(rename_error))
		return false
	if FileAccess.file_exists(old_backup_path):
		DirAccess.remove_absolute(absolute_old_backup)
	EventBus.toast("快速存檔完成")
	return true


func load_quick() -> bool:
	if NetworkManager.is_online():
		EventBus.toast("連線世界不可快速讀檔；請先離開伺服器")
		return false
	var paths := _quick_save_paths()
	var target_path := String(paths.target)
	var candidates := [target_path, String(paths.backup), String(paths.old_backup), String(paths.temp)]
	var any_file := false
	for candidate: String in candidates:
		if not FileAccess.file_exists(candidate):
			continue
		any_file = true
		var parsed := _read_save_payload(candidate)
		if parsed.is_empty() or not GameState.load_save_data(parsed):
			continue
		var player := get_tree().get_first_node_in_group("player")
		if player != null:
			player.global_position = GameState.player_position
			if player.has_method("restore_from_game_state"):
				player.restore_from_game_state()
		quick_load_completed.emit()
		EventBus.toast("快速讀檔完成" if candidate == target_path else "主存檔損壞，已從安全備份復原")
		return true
	if not any_file:
		EventBus.toast("尚無快速存檔")
	else:
		EventBus.toast("存檔版本不相容或內容損壞")
	return false


func _read_save_payload(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {}
	var parsed: Variant = parser.data
	return Dictionary(parsed) if parsed is Dictionary else {}


func _restore_old_backup(backup_path: String, old_backup_path: String, absolute_backup: String, absolute_old_backup: String) -> void:
	if FileAccess.file_exists(old_backup_path) and not FileAccess.file_exists(backup_path):
		DirAccess.rename_absolute(absolute_old_backup, absolute_backup)
