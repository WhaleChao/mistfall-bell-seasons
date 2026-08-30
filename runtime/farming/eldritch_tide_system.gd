class_name PixelRPGEldritchTideSystem
extends RefCounted

const MAX_SANITY := 100
const DAILY_SANITY_RECOVERY := 18
const REQUIRED_UNIQUE_CATCHES := 4

var sanity := MAX_SANITY
var insight := 0
var eldritch_catches: Dictionary = {}
var whispers_seen: Array[String] = []
var boss_unlocked := false
var boss_defeated := false


func reset() -> void:
	sanity = MAX_SANITY
	insight = 0
	eldritch_catches.clear()
	whispers_seen.clear()
	boss_unlocked = false
	boss_defeated = false


func is_tide_active(day: int, minute_of_day: int, weather: String) -> bool:
	if minute_of_day < 18 * 60:
		return false
	return day in [13, 23, 30] or weather in ["fog", "storm", "typhoon", "blizzard"]


func apply_catch(fish: Dictionary, quality: int) -> Dictionary:
	if not bool(fish.get("tide_required", false)):
		return {"eldritch": false, "sanity": sanity, "insight": insight, "boss_unlocked": boss_unlocked}
	var fish_id := String(fish.get("id", ""))
	var first_catch := not eldritch_catches.has(fish_id)
	eldritch_catches[fish_id] = int(eldritch_catches.get(fish_id, 0)) + 1
	var sanity_cost := maxi(0, int(fish.get("sanity_cost", 8)))
	sanity = clampi(sanity - sanity_cost, 0, MAX_SANITY)
	insight += maxi(1, quality) + (3 if first_catch else 0)
	if first_catch:
		whispers_seen.append(fish_id)
	boss_unlocked = boss_unlocked or eldritch_catches.size() >= REQUIRED_UNIQUE_CATCHES
	return {
		"eldritch": true,
		"first_catch": first_catch,
		"sanity_cost": sanity_cost,
		"sanity": sanity,
		"insight": insight,
		"unique_catches": eldritch_catches.size(),
		"boss_unlocked": boss_unlocked,
	}


func recover_new_day() -> int:
	var before := sanity
	sanity = mini(MAX_SANITY, sanity + DAILY_SANITY_RECOVERY)
	return sanity - before


func can_challenge() -> bool:
	return boss_unlocked and not boss_defeated


func defeat_boss() -> bool:
	if not can_challenge():
		return false
	boss_defeated = true
	sanity = MAX_SANITY
	insight += 25
	return true


func to_data() -> Dictionary:
	return {
		"sanity": sanity,
		"insight": insight,
		"eldritch_catches": eldritch_catches.duplicate(true),
		"whispers_seen": whispers_seen.duplicate(),
		"boss_unlocked": boss_unlocked,
		"boss_defeated": boss_defeated,
	}


func load_data(data: Dictionary) -> void:
	sanity = clampi(int(data.get("sanity", MAX_SANITY)), 0, MAX_SANITY)
	insight = maxi(0, int(data.get("insight", 0)))
	eldritch_catches = Dictionary(data.get("eldritch_catches", {})).duplicate(true)
	whispers_seen.assign(data.get("whispers_seen", []))
	boss_unlocked = bool(data.get("boss_unlocked", eldritch_catches.size() >= REQUIRED_UNIQUE_CATCHES))
	boss_defeated = bool(data.get("boss_defeated", false))
