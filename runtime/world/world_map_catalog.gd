class_name PixelRPGWorldMapCatalog
extends RefCounted

const MAP_IDS: Array[StringName] = [
	&"mistfall_farm", &"mistfall_village", &"mistfall_river", &"bellwood_grove",
	&"clockwork_ruins", &"mistfall_depths", &"dreaming_shore",
	&"mistfall_farmhouse", &"mistfall_barn", &"mistfall_greenhouse",
]

const INTERIOR_MAP_IDS: Array[StringName] = [
	&"mistfall_farmhouse", &"mistfall_barn", &"mistfall_greenhouse",
]

const MAP_DATA := {
	"mistfall_farm": {"mode":"farm", "name":"霧落農場", "scene":"res://runtime/world/maps/mistfall_farm.tscn", "background":"res://assets/runtime/backgrounds/maps/mistfall_farm_640.png", "spawn":Vector2(318, 300)},
	"mistfall_village": {"mode":"village", "name":"霧落村", "scene":"res://runtime/world/maps/mistfall_village.tscn", "background":"res://assets/runtime/backgrounds/maps/mistfall_village_640.png", "spawn":Vector2(260, 300)},
	"mistfall_river": {"mode":"river", "name":"鳴鐘河畔", "scene":"res://runtime/world/maps/mistfall_river.tscn", "background":"res://assets/runtime/backgrounds/maps/mistfall_river_640.png", "spawn":Vector2(105, 210)},
	"bellwood_grove": {"mode":"grove", "name":"古鐘林", "scene":"res://runtime/world/maps/bellwood_grove.tscn", "background":"res://assets/runtime/backgrounds/maps/bellwood_grove_640.png", "spawn":Vector2(390, 270)},
	"clockwork_ruins": {"mode":"ruins", "name":"古鐘機械遺跡", "scene":"res://runtime/world/maps/clockwork_ruins.tscn", "background":"res://assets/runtime/backgrounds/maps/clockwork_ruins_640.png", "spawn":Vector2(100, 235)},
	"mistfall_depths": {"mode":"dungeon", "name":"四季鐘窟", "scene":"res://runtime/world/maps/mistfall_depths.tscn", "background":"res://assets/runtime/backgrounds/maps/mistfall_dungeon_640.png", "spawn":Vector2(320, 142)},
	"dreaming_shore": {"mode":"abyss", "name":"夢岸", "scene":"res://runtime/world/maps/dreaming_shore.tscn", "background":"res://assets/runtime/backgrounds/maps/mistfall_dungeon_640.png", "spawn":Vector2(320, 142)},
	"mistfall_farmhouse": {"mode":"farmhouse", "name":"農舍", "scene":"res://runtime/world/maps/mistfall_farmhouse.tscn", "background":"res://assets/runtime/backgrounds/interiors/farmhouse_interior.png", "spawn":Vector2(320, 286)},
	"mistfall_barn": {"mode":"barn", "name":"畜舍", "scene":"res://runtime/world/maps/mistfall_barn.tscn", "background":"res://assets/runtime/backgrounds/interiors/barn_interior.png", "spawn":Vector2(320, 286)},
	"mistfall_greenhouse": {"mode":"greenhouse", "name":"溫室", "scene":"res://runtime/world/maps/mistfall_greenhouse.tscn", "background":"res://assets/runtime/backgrounds/interiors/greenhouse_interior.png", "spawn":Vector2(320, 286)},
}

# Interior object footprints are traced against the 640x360 final backgrounds.
# "blocked" and "spawn_forbidden" share the same source so rendering, movement,
# portal arrival and enemy placement cannot silently disagree.
const INTERIOR_OBSTACLES := {
	"farmhouse": [
		{"name":"HouseNorthWall", "rect":Rect2(20, 54, 600, 66), "semantic":"blocked"},
		{"name":"HouseWestWall", "rect":Rect2(20, 54, 70, 284), "semantic":"blocked"},
		{"name":"HouseEastWall", "rect":Rect2(552, 54, 68, 284), "semantic":"blocked"},
		{"name":"HouseSouthWallLeft", "rect":Rect2(57, 278, 242, 56), "semantic":"blocked"},
		{"name":"HouseSouthWallRight", "rect":Rect2(341, 278, 243, 56), "semantic":"blocked"},
		{"name":"HouseDining", "rect":Rect2(145, 172, 122, 74), "semantic":"blocked"},
		{"name":"HouseBookcase", "rect":Rect2(92, 153, 44, 84), "semantic":"blocked"},
		{"name":"HouseChest", "rect":Rect2(481, 163, 59, 43), "semantic":"blocked"},
	],
	"barn": [
		{"name":"BarnNorthWall", "rect":Rect2(20, 54, 600, 34), "semantic":"blocked"},
		{"name":"BarnWestStalls", "rect":Rect2(22, 58, 160, 237), "semantic":"blocked"},
		{"name":"BarnEastStalls", "rect":Rect2(457, 58, 161, 237), "semantic":"blocked"},
		{"name":"BarnSouthWallLeft", "rect":Rect2(20, 294, 275, 55), "semantic":"blocked"},
		{"name":"BarnSouthWallRight", "rect":Rect2(345, 294, 275, 55), "semantic":"blocked"},
		{"name":"BarnFeedWest", "rect":Rect2(211, 181, 35, 61), "semantic":"blocked"},
		{"name":"BarnFeedEast", "rect":Rect2(379, 181, 35, 61), "semantic":"blocked"},
		{"name":"BarnChest", "rect":Rect2(396, 244, 45, 35), "semantic":"blocked"},
	],
	"greenhouse": [
		{"name":"GreenhouseNorth", "rect":Rect2(36, 8, 568, 82), "semantic":"blocked"},
		{"name":"GreenhouseWest", "rect":Rect2(25, 43, 44, 294), "semantic":"blocked"},
		{"name":"GreenhouseEast", "rect":Rect2(571, 43, 44, 294), "semantic":"blocked"},
		{"name":"GreenhouseSouthLeft", "rect":Rect2(25, 289, 270, 50), "semantic":"blocked"},
		{"name":"GreenhouseSouthRight", "rect":Rect2(345, 289, 270, 50), "semantic":"blocked"},
		{"name":"Bed_0_0", "rect":Rect2(158, 111, 59, 39), "semantic":"interaction"},
		{"name":"Bed_1_0", "rect":Rect2(247, 111, 59, 39), "semantic":"interaction"},
		{"name":"Bed_2_0", "rect":Rect2(337, 111, 59, 39), "semantic":"interaction"},
		{"name":"Bed_3_0", "rect":Rect2(426, 111, 59, 39), "semantic":"interaction"},
		{"name":"Bed_0_1", "rect":Rect2(158, 163, 59, 39), "semantic":"interaction"},
		{"name":"Bed_1_1", "rect":Rect2(247, 163, 59, 39), "semantic":"interaction"},
		{"name":"Bed_2_1", "rect":Rect2(337, 163, 59, 39), "semantic":"interaction"},
		{"name":"Bed_3_1", "rect":Rect2(426, 163, 59, 39), "semantic":"interaction"},
		{"name":"Bed_0_2", "rect":Rect2(158, 216, 59, 39), "semantic":"interaction"},
		{"name":"Bed_1_2", "rect":Rect2(247, 216, 59, 39), "semantic":"interaction"},
		{"name":"Bed_2_2", "rect":Rect2(337, 216, 59, 39), "semantic":"interaction"},
		{"name":"Bed_3_2", "rect":Rect2(426, 216, 59, 39), "semantic":"interaction"},
	],
}

const INTERACTABLES := {
	"mistfall_farmhouse": [
		{"id":"farmhouse_bed", "position":Vector2(156, 112), "radius":38.0, "action":"休息", "title":"農舍床鋪", "action_id":"sleep"},
		{"id":"farmhouse_kitchen", "position":Vector2(450, 112), "radius":42.0, "action":"料理", "title":"農舍廚房", "action_id":"cooking"},
		{"id":"farmhouse_storage", "position":Vector2(510, 184), "radius":38.0, "action":"查看", "title":"家中儲物箱", "action_id":"storage"},
	],
	"mistfall_barn": [
		{"id":"barn_automation", "position":Vector2(329, 88), "radius":45.0, "action":"操作", "title":"畜舍鐘網設備", "action_id":"automation"},
		{"id":"barn_feed", "position":Vector2(228, 212), "radius":38.0, "action":"餵食", "title":"畜舍飼料槽", "action_id":"feed_animals"},
		{"id":"barn_products", "position":Vector2(420, 263), "radius":38.0, "action":"收取", "title":"畜產品收集箱", "action_id":"collect_products"},
	],
	"mistfall_greenhouse": [],
}

const PORTAL_PAIRS: Array[Dictionary] = [
	{"id":"farm_village", "a":&"mistfall_farm", "a_pos":Vector2(54, 138), "b":&"mistfall_village", "b_pos":Vector2(318, 320), "mode":"auto"},
	{"id":"farm_river", "a":&"mistfall_farm", "a_pos":Vector2(320, 82), "b":&"mistfall_river", "b_pos":Vector2(92, 304), "b_spawn":Vector2(105, 210), "mode":"auto"},
	{"id":"farm_grove", "a":&"mistfall_farm", "a_pos":Vector2(310, 320), "b":&"bellwood_grove", "b_pos":Vector2(184, 320), "b_spawn":Vector2(390, 270), "mode":"auto"},
	{"id":"farm_ruins", "a":&"mistfall_farm", "a_pos":Vector2(580, 138), "b":&"clockwork_ruins", "b_pos":Vector2(36, 176), "b_spawn":Vector2(100, 235), "mode":"auto"},
	{"id":"farm_depths", "a":&"mistfall_farm", "a_pos":Vector2(514, 254), "a_spawn":Vector2(318, 300), "b":&"mistfall_depths", "b_pos":Vector2(320, 116), "mode":"interact"},
	{"id":"village_river", "a":&"mistfall_village", "a_pos":Vector2(232, 72), "a_spawn":Vector2(260, 300), "b":&"mistfall_river", "b_pos":Vector2(145, 185), "mode":"auto"},
	{"id":"village_grove", "a":&"mistfall_village", "a_pos":Vector2(592, 172), "a_spawn":Vector2(260, 300), "b":&"bellwood_grove", "b_pos":Vector2(122, 72), "b_spawn":Vector2(390, 270), "mode":"auto"},
	{"id":"village_ruins", "a":&"mistfall_village", "a_pos":Vector2(606, 300), "a_spawn":Vector2(260, 300), "b":&"clockwork_ruins", "b_pos":Vector2(320, 64), "mode":"auto"},
	{"id":"river_grove", "a":&"mistfall_river", "a_pos":Vector2(545, 72), "b":&"bellwood_grove", "b_pos":Vector2(394, 320), "b_spawn":Vector2(390, 270), "mode":"auto"},
	{"id":"river_ruins", "a":&"mistfall_river", "a_pos":Vector2(548, 304), "a_spawn":Vector2(105, 210), "b":&"clockwork_ruins", "b_pos":Vector2(604, 176), "b_spawn":Vector2(100, 235), "mode":"auto"},
	{"id":"grove_ruins", "a":&"bellwood_grove", "a_pos":Vector2(574, 156), "b":&"clockwork_ruins", "b_pos":Vector2(604, 232), "mode":"auto"},
	{"id":"ruins_depths", "a":&"clockwork_ruins", "a_pos":Vector2(320, 318), "a_spawn":Vector2(100, 235), "b":&"mistfall_depths", "b_pos":Vector2(204, 304), "mode":"interact"},
	{"id":"farm_farmhouse", "a":&"mistfall_farm", "a_pos":Vector2(205, 137), "b":&"mistfall_farmhouse", "b_pos":Vector2(320, 316), "mode":"interact"},
	{"id":"farm_barn", "a":&"mistfall_farm", "a_pos":Vector2(478, 137), "b":&"mistfall_barn", "b_pos":Vector2(320, 316), "mode":"interact"},
	{"id":"farm_greenhouse", "a":&"mistfall_farm", "a_pos":Vector2(102, 137), "b":&"mistfall_greenhouse", "b_pos":Vector2(320, 316), "mode":"interact", "unlock_flag":&"greenhouse_unlocked"},
	{"id":"farm_dreaming_shore", "a":&"mistfall_farm", "a_pos":Vector2(174, 262), "b":&"dreaming_shore", "b_pos":Vector2(320, 116), "mode":"interact", "unlock_flag":&"eldritch_shore_unlocked"},
]


static func definition(map_id: StringName) -> PixelRPGWorldMapDefinition:
	var data: Dictionary = Dictionary(MAP_DATA.get(String(map_id), MAP_DATA.mistfall_farm))
	var result := PixelRPGWorldMapDefinition.new()
	result.map_id = map_id if MAP_DATA.has(String(map_id)) else &"mistfall_farm"
	result.mode = StringName(data.mode)
	result.display_name = String(data.name)
	result.scene_path = String(data.scene)
	result.background_path = String(data.background)
	result.safe_spawn = Vector2(data.spawn)
	result.required_targets = [&"portal"]
	return result


static func map_id_for_mode(mode: String) -> StringName:
	for map_id: StringName in MAP_IDS:
		if String(Dictionary(MAP_DATA[String(map_id)]).mode) == mode:
			return map_id
	return &"mistfall_farm"


static func obstacles_for_mode(mode: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for obstacle: Dictionary in INTERIOR_OBSTACLES.get(mode, []):
		result.append(obstacle.duplicate(true))
	return result


static func interactables_for(map_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for interactable: Dictionary in INTERACTABLES.get(String(map_id), []):
		result.append(interactable.duplicate(true))
	return result


static func portals_for(map_id: StringName) -> Array[PixelRPGMapPortalDefinition]:
	var result: Array[PixelRPGMapPortalDefinition] = []
	for pair: Dictionary in PORTAL_PAIRS:
		if StringName(pair.a) == map_id:
			result.append(_portal_from_pair(pair, true))
		elif StringName(pair.b) == map_id:
			result.append(_portal_from_pair(pair, false))
	return result


static func portal_graph_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var portal_ids: Dictionary = {}
	for map_id: StringName in MAP_IDS:
		for portal: PixelRPGMapPortalDefinition in portals_for(map_id):
			portal_ids[String(portal.portal_id)] = portal
	for portal_id: String in portal_ids:
		var portal: PixelRPGMapPortalDefinition = portal_ids[portal_id]
		if not portal_ids.has(String(portal.reverse_portal_id)):
			errors.append("Portal %s has no reverse %s" % [portal.portal_id, portal.reverse_portal_id])
			continue
		var reverse: PixelRPGMapPortalDefinition = portal_ids[String(portal.reverse_portal_id)]
		if reverse.target_map_id != portal.source_map_id or reverse.source_map_id != portal.target_map_id:
			errors.append("Portal %s reverse endpoints do not match" % portal.portal_id)
	return errors


static func _portal_from_pair(pair: Dictionary, from_a: bool) -> PixelRPGMapPortalDefinition:
	var result := PixelRPGMapPortalDefinition.new()
	var source_key := "a" if from_a else "b"
	var target_key := "b" if from_a else "a"
	var direction_suffix := "a_to_b" if from_a else "b_to_a"
	var reverse_suffix := "b_to_a" if from_a else "a_to_b"
	result.portal_id = StringName("%s_%s" % [pair.id, direction_suffix])
	result.reverse_portal_id = StringName("%s_%s" % [pair.id, reverse_suffix])
	result.source_map_id = StringName(pair[source_key])
	result.target_map_id = StringName(pair[target_key])
	result.position = Vector2(pair["%s_pos" % source_key])
	var target_anchor := Vector2(pair["%s_pos" % target_key])
	result.target_spawn = target_anchor + target_anchor.direction_to(Vector2(320, 190)) * 34.0
	var explicit_spawn_key := "%s_spawn" % target_key
	if pair.has(explicit_spawn_key):
		result.target_spawn = Vector2(pair[explicit_spawn_key])
	if String(pair.id) == "farm_farmhouse":
		result.target_spawn = Vector2(320, 286) if from_a else Vector2(205, 159)
	elif String(pair.id) == "farm_barn":
		result.target_spawn = Vector2(320, 286) if from_a else Vector2(478, 159)
	elif String(pair.id) == "farm_greenhouse":
		result.target_spawn = Vector2(320, 286) if from_a else Vector2(102, 159)
	result.target_facing = result.target_spawn.direction_to(Vector2(320, 190)).normalized()
	result.label = definition(result.target_map_id).display_name
	result.transition_mode = String(pair.get("mode", "interact"))
	result.unlock_flag = StringName(pair.get("unlock_flag", &""))
	return result


static func semantic_at(map_id: StringName, world_position: Vector2) -> StringName:
	var mode := String(definition(map_id).mode)
	for obstacle: Dictionary in obstacles_for_mode(mode):
		if obstacle.has("rect") and Rect2(obstacle.rect).has_point(world_position):
			return StringName(obstacle.get("semantic", "blocked"))
	return &"walkable"
