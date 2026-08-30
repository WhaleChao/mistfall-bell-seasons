extends Node

const QUICK_SAVE_PATH := "user://pixelrpg_quick_save.json"


func save_quick() -> bool:
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		GameState.player_position = player.global_position
		var player_health: Variant = player.get("health")
		if player_health != null:
			GameState.player_stats["health"] = int(player_health)
	var payload := GameState.to_save_data()
	payload["saved_at_unix"] = int(Time.get_unix_time_from_system())
	var temporary_path := QUICK_SAVE_PATH + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		EventBus.toast("無法建立存檔")
		return false
	file.store_string(JSON.stringify(payload, "\t", false))
	file.close()
	var absolute_temp := ProjectSettings.globalize_path(temporary_path)
	var absolute_target := ProjectSettings.globalize_path(QUICK_SAVE_PATH)
	if FileAccess.file_exists(QUICK_SAVE_PATH):
		DirAccess.remove_absolute(absolute_target)
	var rename_error := DirAccess.rename_absolute(absolute_temp, absolute_target)
	if rename_error != OK:
		EventBus.toast("存檔寫入失敗：%s" % error_string(rename_error))
		return false
	EventBus.toast("快速存檔完成")
	return true


func load_quick() -> bool:
	if not FileAccess.file_exists(QUICK_SAVE_PATH):
		EventBus.toast("尚無快速存檔")
		return false
	var file := FileAccess.open(QUICK_SAVE_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not GameState.load_save_data(Dictionary(parsed)):
		EventBus.toast("存檔版本不相容或內容損壞")
		return false
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.global_position = GameState.player_position
		if player.has_method("restore_from_game_state"):
			player.restore_from_game_state()
	EventBus.toast("快速讀檔完成")
	return true
