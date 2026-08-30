class_name PixelRPGNPCScheduleSystem
extends RefCounted


func location_for(npc_id: StringName, minute_of_day: int, weather: String) -> Dictionary:
	var schedule := ContentRegistry.get_artifact("npc_schedules", npc_id)
	if schedule.is_empty():
		return {}
	var slots: Array = schedule.get("rain", []) if weather in ["rain", "storm", "typhoon"] and schedule.has("rain") else schedule.get("weekday", [])
	for slot: Dictionary in slots:
		if minute_of_day >= int(slot.get("from", 0)) and minute_of_day < int(slot.get("to", 1440)):
			return {"npc_id": String(npc_id), "map": slot.get("map", ""), "marker": slot.get("marker", ""), "romance_candidate": bool(schedule.get("romance_candidate", false))}
	return {}
