class_name PixelRPGAchievementSystem
extends RefCounted

var unlocked: Array[String] = []


func reset() -> void:
	unlocked.clear()


func evaluate(metrics: Dictionary) -> Array[Dictionary]:
	var newly_unlocked: Array[Dictionary] = []
	for achievement: Dictionary in ContentRegistry.get_all("achievements"):
		var achievement_id := String(achievement.get("id", ""))
		if achievement_id in unlocked:
			continue
		var condition: Dictionary = achievement.get("condition", {})
		if int(metrics.get(String(condition.get("metric", "")), 0)) >= int(condition.get("threshold", 1)):
			unlocked.append(achievement_id)
			newly_unlocked.append(achievement)
	return newly_unlocked


func to_data() -> Dictionary:
	return {"unlocked": unlocked.duplicate()}


func load_data(data: Dictionary) -> void:
	unlocked.assign(data.get("unlocked", []))
