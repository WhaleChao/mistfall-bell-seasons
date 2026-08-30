class_name PixelRPGFishingSystem
extends RefCounted


func available_fish(season_id: StringName, minute_of_day: int, weather: String, location: String, eldritch_tide: bool = false, rod_level: int = 1) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	var hour := minute_of_day / 60
	for fish: Dictionary in ContentRegistry.get_all("fish"):
		var hours: Array = fish.get("hours", [0, 24])
		var requires_tide := bool(fish.get("tide_required", false))
		if requires_tide != eldritch_tide or rod_level < int(fish.get("min_rod_level", 1)):
			continue
		if String(season_id) in fish.get("seasons", []) and location in fish.get("locations", []) and weather in fish.get("weather", []) and hours.size() == 2 and hour >= int(hours[0]) and hour < int(hours[1]):
			available.append(fish)
	return available


func catch_fish(season_id: StringName, minute_of_day: int, weather: String, location: String, absolute_day: int, eldritch_tide: bool = false, rod_level: int = 1) -> Dictionary:
	var candidates := available_fish(season_id, minute_of_day, weather, location, eldritch_tide, rod_level)
	if candidates.is_empty():
		return {"ok": false, "message": "異潮中沒有能以目前釣竿承受的漁獲" if eldritch_tide else "現在沒有魚上鉤"}
	var selected: Dictionary = candidates[posmod(absolute_day + minute_of_day / 30 + location.length(), candidates.size())]
	var difficulty := int(selected.get("difficulty", 20))
	var quality := clampi(1 + posmod(absolute_day + minute_of_day + rod_level * 11 - difficulty, 3), 1, 3)
	return {
		"ok": true,
		"fish_id": selected.get("id", ""),
		"display_name": selected.get("display_name", "魚"),
		"quality": quality,
		"difficulty": difficulty,
		"rarity": selected.get("rarity", "common"),
		"eldritch": bool(selected.get("tide_required", false)),
		"message": "從異潮釣起%s……它在沒有水的地方仍在呼吸。" % selected.get("display_name", "異魚") if eldritch_tide else "釣到%s！" % selected.get("display_name", "魚"),
	}
