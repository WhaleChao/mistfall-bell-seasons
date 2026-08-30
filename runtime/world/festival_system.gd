class_name PixelRPGFestivalSystem
extends RefCounted

var attended: Dictionary = {}


func festival_on(season_id: StringName, day: int) -> Dictionary:
	for festival: Dictionary in ContentRegistry.get_all("festivals"):
		if festival.get("season") == String(season_id) and int(festival.get("day", 0)) == day:
			return festival
	return {}


func mark_attended(festival_id: StringName, year: int) -> bool:
	var key := "%d:%s" % [year, festival_id]
	if attended.has(key):
		return false
	attended[key] = true
	return true


func has_attended(festival_id: StringName, year: int) -> bool:
	return attended.has("%d:%s" % [year, festival_id])


func year_variant(year: int) -> int:
	return mini(maxi(year, 1), 3)


func to_data() -> Dictionary:
	return {"attended": attended.duplicate(true)}


func load_data(data: Dictionary) -> void:
	attended = Dictionary(data.get("attended", {})).duplicate(true)
