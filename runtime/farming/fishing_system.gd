class_name PixelRPGFishingSystem
extends RefCounted


func available_fish(season_id: StringName, minute_of_day: int, weather: String, location: String) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	var hour := minute_of_day / 60
	for fish: Dictionary in ContentRegistry.get_all("fish"):
		var hours: Array = fish.get("hours", [0, 24])
		if String(season_id) in fish.get("seasons", []) and location in fish.get("locations", []) and weather in fish.get("weather", []) and hours.size() == 2 and hour >= int(hours[0]) and hour < int(hours[1]):
			available.append(fish)
	return available


func catch_fish(season_id: StringName, minute_of_day: int, weather: String, location: String, absolute_day: int) -> Dictionary:
	var candidates := available_fish(season_id, minute_of_day, weather, location)
	if candidates.is_empty():
		return {"ok": false, "message": "現在沒有魚上鉤"}
	var selected: Dictionary = candidates[posmod(absolute_day + minute_of_day / 30 + location.length(), candidates.size())]
	return {"ok": true, "fish_id": selected.get("id", ""), "display_name": selected.get("display_name", "魚"), "quality": 1 + posmod(absolute_day + minute_of_day, 3), "message": "釣到%s！" % selected.get("display_name", "魚")}
