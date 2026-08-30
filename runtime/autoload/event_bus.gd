extends Node

signal actor_damaged(actor: Node, amount: int, remaining_health: int)
signal actor_healed(actor: Node, amount: int, remaining_health: int)
signal enemy_defeated(enemy_id: StringName, position: Vector2)
signal player_defeated
signal combat_hit_stop_requested(duration_seconds: float)
signal flag_changed(flag_id: StringName, value: Variant)
signal quest_changed(quest_id: StringName, state: StringName)
signal inventory_changed(item_id: StringName, quantity: int)
signal toast_requested(message: String)
signal dialogue_requested(dialogue_id: StringName, start_node: StringName)
signal map_change_requested(map_id: StringName, spawn_id: StringName)
signal actor_spawn_requested(actor_id: StringName, marker_id: StringName)
signal actor_remove_requested(actor_id: StringName)
signal animation_requested(target_id: StringName, animation_id: StringName)
signal sound_requested(sound_id: StringName)
signal cutscene_requested(cutscene_id: StringName)
signal calendar_time_changed(year: int, season_id: StringName, day: int, minute_of_day: int)
signal day_started(year: int, season_id: StringName, day: int, weather: String)
signal day_ended(year: int, season_id: StringName, day: int)
signal weather_changed(weather: String, forecast: Dictionary)
signal farm_changed(action: StringName, payload: Dictionary)
signal relationship_changed(npc_id: StringName, hearts: int)
signal festival_available(festival: Dictionary)
signal dungeon_floor_changed(floor_number: int)
signal request_board_changed(requests: Array)


func request_hit_stop(duration_seconds: float = 0.045) -> void:
	combat_hit_stop_requested.emit(clampf(duration_seconds, 0.0, 0.15))


func toast(message: String) -> void:
	toast_requested.emit(message)
