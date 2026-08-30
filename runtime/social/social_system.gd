class_name PixelRPGSocialSystem
extends RefCounted

const HEART_POINTS := 250
const MAX_POINTS := HEART_POINTS * 10

var relationships: Dictionary = {}
var marriage: Dictionary = {"spouse_id": "", "married_absolute_day": 0, "family_talk_seen": false}
var child: Dictionary = {"exists": false, "name": "", "born_absolute_day": 0, "stage": "none"}


func reset() -> void:
	relationships.clear()
	marriage = {"spouse_id": "", "married_absolute_day": 0, "family_talk_seen": false}
	child = {"exists": false, "name": "", "born_absolute_day": 0, "stage": "none"}


func ensure_npc(npc_id: StringName) -> Dictionary:
	var key := String(npc_id)
	if not relationships.has(key):
		relationships[key] = {"friendship": 0, "romance": 0, "dating": false, "events_seen": []}
	return Dictionary(relationships[key])


func add_affection(npc_id: StringName, friendship_points: int, romance_points: int = 0) -> int:
	var key := String(npc_id)
	var state := ensure_npc(npc_id).duplicate(true)
	state.friendship = clampi(int(state.get("friendship", 0)) + friendship_points, 0, MAX_POINTS)
	if bool(state.get("dating", false)) or romance_points <= 0:
		state.romance = clampi(int(state.get("romance", 0)) + romance_points, 0, MAX_POINTS)
	relationships[key] = state
	return hearts(npc_id)


func hearts(npc_id: StringName) -> int:
	var state := ensure_npc(npc_id)
	return clampi(int(state.get("friendship", 0)) / HEART_POINTS, 0, 10)


func start_dating(npc_id: StringName) -> bool:
	var key := String(npc_id)
	var state := ensure_npc(npc_id).duplicate(true)
	if hearts(npc_id) < 6:
		return false
	state.dating = true
	relationships[key] = state
	return true


func marry(npc_id: StringName, absolute_day: int) -> bool:
	if not String(marriage.get("spouse_id", "")).is_empty():
		return false
	var state := ensure_npc(npc_id)
	if hearts(npc_id) < 10 or not bool(state.get("dating", false)):
		return false
	marriage = {"spouse_id": String(npc_id), "married_absolute_day": absolute_day, "family_talk_seen": false}
	return true


func can_start_family_talk(absolute_day: int) -> bool:
	return not String(marriage.get("spouse_id", "")).is_empty() and not bool(marriage.get("family_talk_seen", false)) and absolute_day - int(marriage.get("married_absolute_day", absolute_day)) >= 30


func confirm_family_talk() -> bool:
	if String(marriage.get("spouse_id", "")).is_empty():
		return false
	marriage.family_talk_seen = true
	return true


func welcome_child(child_name: String, absolute_day: int) -> bool:
	if bool(child.get("exists", false)) or not bool(marriage.get("family_talk_seen", false)):
		return false
	if absolute_day - int(marriage.get("married_absolute_day", absolute_day)) < 60:
		return false
	child = {"exists": true, "name": child_name.strip_edges() if not child_name.strip_edges().is_empty() else "小鐘", "born_absolute_day": absolute_day, "stage": "baby"}
	return true


func update_child_stage(absolute_day: int) -> String:
	if not bool(child.get("exists", false)):
		return "none"
	var age := maxi(0, absolute_day - int(child.get("born_absolute_day", absolute_day)))
	var stage := "baby" if age <= 29 else "toddler" if age <= 89 else "child" if age <= 209 else "teen"
	child.stage = stage
	return stage


func next_relationship_event(npc_id: StringName, season_id: StringName, weather: String, map_id: String) -> Dictionary:
	var state := ensure_npc(npc_id)
	var seen: Array = state.get("events_seen", [])
	var current_hearts := hearts(npc_id)
	for event: Dictionary in ContentRegistry.get_all("relationship_events"):
		if event.get("npc_id") != String(npc_id) or event.get("id") in seen or int(event.get("hearts", 11)) > current_hearts:
			continue
		if event.get("season") not in ["any", String(season_id)] or event.get("weather") not in ["any", weather] or event.get("map") != map_id:
			continue
		return event
	return {}


func mark_event_seen(npc_id: StringName, event_id: String) -> bool:
	var key := String(npc_id)
	var state := ensure_npc(npc_id).duplicate(true)
	var seen: Array = state.get("events_seen", []).duplicate()
	if event_id in seen:
		return false
	seen.append(event_id)
	state.events_seen = seen
	relationships[key] = state
	return true


func to_data() -> Dictionary:
	return {"relationships": relationships.duplicate(true), "marriage": marriage.duplicate(true), "child": child.duplicate(true)}


func load_data(data: Dictionary) -> void:
	relationships = Dictionary(data.get("relationships", {})).duplicate(true)
	marriage = Dictionary(data.get("marriage", marriage)).duplicate(true)
	child = Dictionary(data.get("child", child)).duplicate(true)
