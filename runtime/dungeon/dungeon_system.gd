class_name PixelRPGDungeonSystem
extends RefCounted

const MAX_FLOOR := 40
const BOSS_FLOORS := [10, 20, 30, 40]
const SEAL_IDS := ["spring_seal", "summer_seal", "autumn_seal", "winter_seal"]

var current_floor := 0
var max_reached := 0
var cleared_floors: Array[int] = []
var defeated_bosses: Array[int] = []
var seals: Array[String] = []
var final_boss_defeated := false
var endless_unlocked := false


func reset() -> void:
	current_floor = 0
	max_reached = 0
	cleared_floors.clear()
	defeated_bosses.clear()
	seals.clear()
	final_boss_defeated = false
	endless_unlocked = false


func enter_floor(target_floor: int) -> bool:
	if target_floor < 1:
		return false
	if target_floor > MAX_FLOOR and not endless_unlocked:
		return false
	if target_floor <= MAX_FLOOR and target_floor > max_reached + 1 and target_floor % 5 != 0:
		return false
	if target_floor % 5 == 0 and target_floor > max_reached and target_floor != max_reached + 1:
		return false
	current_floor = target_floor
	max_reached = maxi(max_reached, target_floor)
	return true


func clear_current_floor() -> Dictionary:
	if current_floor <= 0:
		return {"ok": false}
	if current_floor not in cleared_floors:
		cleared_floors.append(current_floor)
	var result := {"ok": true, "floor": current_floor, "boss": current_floor in BOSS_FLOORS, "seal": ""}
	if current_floor in BOSS_FLOORS and current_floor not in defeated_bosses:
		defeated_bosses.append(current_floor)
		var seal_id: String = SEAL_IDS[BOSS_FLOORS.find(current_floor)]
		if seal_id not in seals:
			seals.append(seal_id)
		result.seal = seal_id
	return result


func available_elevators() -> Array[int]:
	var floors: Array[int] = []
	for floor_number in range(5, mini(MAX_FLOOR, max_reached) + 1, 5):
		if floor_number in cleared_floors:
			floors.append(floor_number)
	return floors


func can_challenge_final_boss() -> bool:
	return seals.size() == 4


func defeat_final_boss() -> bool:
	if not can_challenge_final_boss():
		return false
	final_boss_defeated = true
	endless_unlocked = true
	return true


func rescue_cost(coins: int) -> int:
	return ceili(maxi(0, coins) * 0.1)


func to_data() -> Dictionary:
	return {"current_floor": current_floor, "max_reached": max_reached, "cleared_floors": cleared_floors.duplicate(), "defeated_bosses": defeated_bosses.duplicate(), "seals": seals.duplicate(), "final_boss_defeated": final_boss_defeated, "endless_unlocked": endless_unlocked}


func load_data(data: Dictionary) -> void:
	current_floor = maxi(0, int(data.get("current_floor", 0)))
	max_reached = maxi(0, int(data.get("max_reached", 0)))
	cleared_floors.assign(data.get("cleared_floors", []))
	defeated_bosses.assign(data.get("defeated_bosses", []))
	seals.assign(data.get("seals", []))
	final_boss_defeated = bool(data.get("final_boss_defeated", false))
	endless_unlocked = bool(data.get("endless_unlocked", false))
