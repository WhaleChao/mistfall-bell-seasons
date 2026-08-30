class_name PixelRPGRequestBoard
extends RefCounted

var active_requests: Array[Dictionary] = []
var completed_request_ids: Array[String] = []


func generate_for_day(year: int, season_id: StringName, day: int) -> Array[Dictionary]:
	active_requests.clear()
	var templates := ContentRegistry.get_all("request_templates")
	if templates.is_empty():
		return active_requests
	var authored_year := mini(maxi(year, 1), 3)
	var count := mini(3, templates.size())
	var start := posmod(year * 37 + day * 11 + PixelRPGCalendarSystem.SEASON_IDS.find(season_id) * 5, templates.size())
	for offset in range(count):
		var template: Dictionary = templates[(start + offset) % templates.size()]
		var request := template.duplicate(true)
		request["instance_id"] = "y%d_%s_%02d_%s" % [year, season_id, day, template.get("id", "request")]
		request["authored_variant"] = authored_year
		request["expires_absolute_day"] = PixelRPGCalendarSystem.absolute_day_for(year, PixelRPGCalendarSystem.SEASON_IDS.find(season_id), day) + int(template.get("duration_days", 3))
		active_requests.append(request)
	return active_requests


func complete(request_id: String) -> bool:
	for request: Dictionary in active_requests:
		if request.get("instance_id") == request_id:
			if request_id not in completed_request_ids:
				completed_request_ids.append(request_id)
			return true
	return false


func to_data() -> Dictionary:
	return {"active_requests": active_requests.duplicate(true), "completed_request_ids": completed_request_ids.duplicate()}


func load_data(data: Dictionary) -> void:
	active_requests.clear()
	for request: Dictionary in data.get("active_requests", []):
		active_requests.append(request.duplicate(true))
	completed_request_ids.assign(data.get("completed_request_ids", []))
