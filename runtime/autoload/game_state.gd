extends Node

const SAVE_SCHEMA_VERSION := 5
const CalendarSystem := preload("res://runtime/calendar/calendar_system.gd")
const FarmSystem := preload("res://runtime/farming/farm_system.gd")
const SocialSystem := preload("res://runtime/social/social_system.gd")
const FestivalSystem := preload("res://runtime/world/festival_system.gd")
const DungeonSystem := preload("res://runtime/dungeon/dungeon_system.gd")
const RequestBoardSystem := preload("res://runtime/procedural/request_board.gd")
const NPCScheduleSystem := preload("res://runtime/world/npc_schedule_system.gd")
const FishingSystem := preload("res://runtime/farming/fishing_system.gd")
const EldritchTideSystem := preload("res://runtime/farming/eldritch_tide_system.gd")
const CookingSystem := preload("res://runtime/farming/cooking_system.gd")
const StoryProgressSystem := preload("res://runtime/world/story_progress_system.gd")
const ToolSystem := preload("res://runtime/economy/tool_system.gd")
const EconomySystem := preload("res://runtime/economy/economy_system.gd")
const ShopSystem := preload("res://runtime/economy/shop_system.gd")
const AchievementSystem := preload("res://runtime/economy/achievement_system.gd")

var flags: Dictionary = {}
var quest_states: Dictionary = {}
var inventory: Dictionary = {}
var player_profile: Dictionary = {}
var player_stats: Dictionary = {}
var coins := 500
var current_map_id: StringName = &"mistfall_farm"
var player_position := Vector2(320, 180)
var current_weather := "clear"
var story_state: Dictionary = {"chapter": 1, "completed_chapters": [], "season_seals": [], "final_boss_available": false}

var calendar: RefCounted = CalendarSystem.new()
var farm: RefCounted = FarmSystem.new()
var social: RefCounted = SocialSystem.new()
var festivals: RefCounted = FestivalSystem.new()
var dungeon: RefCounted = DungeonSystem.new()
var request_board: RefCounted = RequestBoardSystem.new()
var npc_schedules: RefCounted = NPCScheduleSystem.new()
var fishing: RefCounted = FishingSystem.new()
var eldritch: RefCounted = EldritchTideSystem.new()
var cooking: RefCounted = CookingSystem.new()
var story_progress: RefCounted = StoryProgressSystem.new()
var tools: RefCounted = ToolSystem.new()
var economy: RefCounted = EconomySystem.new()
var shops: RefCounted = ShopSystem.new()
var achievements: RefCounted = AchievementSystem.new()
var lifetime_stats: Dictionary = {}
var settings: Dictionary = {}
var game_time_running := true
var _ending_day := false


func _ready() -> void:
	calendar.time_changed.connect(_on_calendar_time_changed)
	reset()


func _process(delta: float) -> void:
	if game_time_running and not _ending_day and calendar.process(delta):
		advance_day()


func reset() -> void:
	flags.clear()
	quest_states.clear()
	inventory = {"health_potion": 3, "egg": 0, "milk": 0}
	player_profile = {"name": "旅人", "appearance": {"body": "neutral", "skin": 1, "hair": 0, "outfit": 0}}
	player_stats = {"max_health": 100, "health": 100, "attack": 16}
	coins = 500
	current_map_id = &"mistfall_farm"
	player_position = Vector2(320, 180)
	story_state = {"chapter": 1, "completed_chapters": [], "season_seals": [], "final_boss_available": false}
	calendar.reset()
	farm.reset()
	social.reset()
	festivals.attended.clear()
	dungeon.reset()
	request_board.active_requests.clear()
	request_board.completed_request_ids.clear()
	tools.reset()
	eldritch.reset()
	economy.reset()
	achievements.reset()
	lifetime_stats = {"days_played": 0, "crops_harvested": 0, "fish_caught": 0, "eldritch_fish_caught": 0, "resources_gathered": 0, "monsters_defeated": 0, "bosses_defeated": 0, "eldritch_bosses_defeated": 0, "festivals_attended": 0, "relationship_hearts": 0, "marriages": 0, "coins_earned": 0, "purchases": 0, "automation_cycles": 0, "automated_tiles_watered": 0, "automated_crops_planted": 0, "automated_crops_harvested": 0, "automation_animals_fed": 0, "automation_items_processed": 0}
	settings = {"master_volume": 0.8, "text_speed": 1.0, "fullscreen": false, "control_prompts": "auto"}
	current_weather = CalendarSystem.weather_for(calendar.year, calendar.season_index, calendar.day)
	game_time_running = true


func set_flag(flag_id: StringName, value: Variant) -> void:
	flags[String(flag_id)] = value
	EventBus.flag_changed.emit(flag_id, value)


func get_flag(flag_id: StringName, default_value: Variant = false) -> Variant:
	return flags.get(String(flag_id), default_value)


func set_quest_state(quest_id: StringName, state: StringName) -> void:
	quest_states[String(quest_id)] = String(state)
	EventBus.quest_changed.emit(quest_id, state)


func add_item(item_id: StringName, quantity: int = 1) -> int:
	var key := String(item_id)
	var new_quantity := maxi(0, int(inventory.get(key, 0)) + quantity)
	inventory[key] = new_quantity
	EventBus.inventory_changed.emit(item_id, new_quantity)
	return new_quantity


func consume_item(item_id: StringName, quantity: int = 1) -> bool:
	var key := String(item_id)
	var current := int(inventory.get(key, 0))
	if quantity <= 0 or current < quantity:
		return false
	inventory[key] = current - quantity
	EventBus.inventory_changed.emit(item_id, current - quantity)
	return true


func pause_game_time(value: bool) -> void:
	calendar.paused = value


func cycle_time_speed() -> String:
	var mode: String = calendar.cycle_speed()
	EventBus.toast("時間速度：%s" % speed_display_name(mode))
	return mode


func advance_day(debug_skip: bool = false) -> Dictionary:
	if _ending_day:
		return {}
	_ending_day = true
	var ended: Dictionary = calendar.date_snapshot()
	var shipping: Dictionary = economy.settle_shipping()
	var shipping_coins := int(shipping.get("coins", 0))
	coins += shipping_coins
	lifetime_stats["coins_earned"] = int(lifetime_stats.get("coins_earned", 0)) + shipping_coins
	lifetime_stats["days_played"] = int(lifetime_stats.get("days_played", 0)) + 1
	EventBus.day_ended.emit(calendar.year, calendar.season_id(), calendar.day)
	var elapsed_weather := current_weather
	var automation_report: Dictionary = farm.run_automation_day(calendar.season_id(), inventory)
	if int(automation_report.get("devices", 0)) > 0:
		lifetime_stats["automation_cycles"] = int(lifetime_stats.get("automation_cycles", 0)) + 1
		lifetime_stats["automated_tiles_watered"] = int(lifetime_stats.get("automated_tiles_watered", 0)) + int(automation_report.get("watered", 0))
		lifetime_stats["automated_crops_planted"] = int(lifetime_stats.get("automated_crops_planted", 0)) + int(automation_report.get("planted", 0))
		lifetime_stats["automated_crops_harvested"] = int(lifetime_stats.get("automated_crops_harvested", 0)) + int(automation_report.get("harvested", 0))
		lifetime_stats["automation_animals_fed"] = int(lifetime_stats.get("automation_animals_fed", 0)) + int(automation_report.get("fed", 0))
		lifetime_stats["automation_items_processed"] = int(lifetime_stats.get("automation_items_processed", 0)) + int(automation_report.get("processed", 0))
		lifetime_stats["crops_harvested"] = int(lifetime_stats.get("crops_harvested", 0)) + int(automation_report.get("harvested", 0))
	var transition: Dictionary = calendar.advance_day()
	current_weather = CalendarSystem.weather_for(calendar.year, calendar.season_index, calendar.day)
	var crop_messages: Array = farm.advance_day(calendar.season_id(), elapsed_weather)
	social.update_child_stage(calendar.absolute_day())
	request_board.generate_for_day(calendar.year, calendar.season_id(), calendar.day)
	player_stats["health"] = int(player_stats.get("max_health", 100))
	tools.restore_for_new_day()
	eldritch.recover_new_day()
	for message in crop_messages:
		EventBus.toast(message)
	if int(automation_report.get("devices", 0)) > 0:
		EventBus.toast(String(automation_report.get("message", "")))
	var forecast := CalendarSystem.forecast_for_tomorrow(calendar.year, calendar.season_index, calendar.day)
	EventBus.weather_changed.emit(current_weather, forecast)
	EventBus.request_board_changed.emit(request_board.active_requests)
	EventBus.day_started.emit(calendar.year, calendar.season_id(), calendar.day, current_weather)
	var festival: Dictionary = festivals.festival_on(calendar.season_id(), calendar.day)
	if not festival.is_empty():
		EventBus.festival_available.emit(festival)
	if debug_skip:
		EventBus.toast("測試快轉：%s" % calendar.date_text())
	elif shipping_coins > 0:
		EventBus.toast("昨夜出貨收入 %dG" % shipping_coins)
	_check_achievements()
	_ending_day = false
	return {"ended": ended, "transition": transition, "weather": current_weather, "festival": festival, "automation": automation_report}


func sleep_if_allowed() -> bool:
	if calendar.minute_of_day < 20 * 60:
		EventBus.toast("20:00 後才能就寢")
		return false
	advance_day()
	return true


func resolve_player_defeat() -> Dictionary:
	var lost: int = dungeon.rescue_cost(coins)
	coins = maxi(0, coins - lost)
	player_stats["health"] = int(player_stats.get("max_health", 100))
	current_map_id = &"mistfall_farm"
	player_position = Vector2(320, 230)
	advance_day()
	return {"coins_lost": lost, "coins_remaining": coins, "message": "診所救援完成，損失 %dG；關鍵物品完整保留" % lost}


func interact_farm_plot(tile: Vector2i, crop_id: StringName) -> Dictionary:
	var action := _farm_action_for(tile)
	if not action.is_empty() and not tools.use_for(action):
		return {"ok": false, "message": "體力不足，請休息或睡到隔天"}
	var result: Dictionary = farm.interact_plot(tile, crop_id, calendar.season_id())
	if bool(result.get("ok", false)):
		if String(result.get("action", "")) == "harvested":
			lifetime_stats["crops_harvested"] = int(lifetime_stats.get("crops_harvested", 0)) + int(result.get("quantity", 1))
		_check_achievements()
		EventBus.farm_changed.emit(StringName(result.get("action", "changed")), result)
	return result


func purchase_automation_device(tile: Vector2i, device_id: StringName, config: Dictionary = {}) -> Dictionary:
	var definition := ContentRegistry.get_artifact("automation_devices", device_id)
	if definition.is_empty():
		return {"ok": false, "message": "找不到自動化設備資料"}
	if farm.rank < int(definition.get("required_rank", 10)):
		return {"ok": false, "message": "農場需達 Lv.%d" % definition.get("required_rank", 10)}
	if farm.automation_devices.has("%d,%d" % [tile.x, tile.y]):
		return {"ok": false, "message": "這個設計格已有設備"}
	var cost := int(definition.get("cost", 0))
	if coins < cost:
		return {"ok": false, "message": "建造需要 %dG" % cost}
	var materials: Dictionary = definition.get("materials", {})
	for material_id: String in materials:
		if int(inventory.get(material_id, 0)) < int(materials[material_id]):
			return {"ok": false, "message": "缺少%s %d 個" % [ContentRegistry.get_artifact("items", material_id).get("display_name", material_id), materials[material_id]]}
	var result: Dictionary = farm.place_automation_device(tile, device_id, config)
	if not bool(result.get("ok", false)):
		return result
	for material_id: String in materials:
		consume_item(material_id, int(materials[material_id]))
	coins -= cost
	economy.record_purchase(String(device_id), cost)
	lifetime_stats["purchases"] = int(lifetime_stats.get("purchases", 0)) + 1
	EventBus.farm_changed.emit(&"automation_placed", result)
	return result


func configure_automation_device(tile: Vector2i, config: Dictionary) -> Dictionary:
	var result: Dictionary = farm.configure_automation_device(tile, config)
	if bool(result.get("ok", false)):
		EventBus.farm_changed.emit(&"automation_configured", result)
	return result


func remove_automation_device(tile: Vector2i) -> Dictionary:
	var result: Dictionary = farm.remove_automation_device(tile)
	if bool(result.get("ok", false)):
		EventBus.farm_changed.emit(&"automation_removed", result)
	return result


func talk_to(npc_id: StringName) -> int:
	var daily_flag := "talked_%d_%s" % [calendar.absolute_day(), npc_id]
	if bool(get_flag(daily_flag, false)):
		return social.hearts(npc_id)
	var new_hearts: int = social.add_affection(npc_id, 25)
	set_flag(daily_flag, true)
	EventBus.relationship_changed.emit(npc_id, new_hearts)
	_update_relationship_metric()
	_check_achievements()
	return new_hearts


func attend_today_festival(score: int = 0) -> Dictionary:
	var festival: Dictionary = festivals.festival_on(calendar.season_id(), calendar.day)
	if festival.is_empty():
		return {"ok": false, "message": "今天沒有節慶"}
	if not festivals.mark_attended(StringName(festival.get("id", "")), calendar.year):
		return {"ok": false, "message": "今年已參加過這場節慶"}
	var clamped_score := clampi(score, 0, 100)
	var base_reward := int(festival.get("participation_reward", 100))
	var skill_bonus := roundi(float(base_reward) * float(clamped_score) / 200.0)
	coins += base_reward + skill_bonus
	lifetime_stats["festivals_attended"] = int(lifetime_stats.get("festivals_attended", 0)) + 1
	_check_achievements()
	return {"ok": true, "festival": festival, "score": clamped_score, "reward": base_reward + skill_bonus, "message": "%s完成：%d 分，獲得 %dG" % [festival.get("display_name", "節慶"), clamped_score, base_reward + skill_bonus]}


func fish_at(location: String) -> Dictionary:
	var tide_active: bool = eldritch.is_tide_active(calendar.day, calendar.minute_of_day, current_weather)
	if tide_active and eldritch.sanity <= 0:
		return {"ok": false, "message": "你的理智已抵達極限；睡一晚，讓鐘聲把名字帶回來"}
	if not tools.use_for("fishing"):
		return {"ok": false, "message": "體力不足，今天無法再拋竿"}
	var rod_level := int(tools.tool_levels.get("fishing_rod", 1))
	var result: Dictionary = fishing.catch_fish(calendar.season_id(), calendar.minute_of_day, current_weather, location, calendar.absolute_day(), tide_active, rod_level)
	if bool(result.get("ok", false)):
		var fish_id := String(result.get("fish_id", ""))
		farm.produce[fish_id] = int(farm.produce.get(fish_id, 0)) + 1
		lifetime_stats["fish_caught"] = int(lifetime_stats.get("fish_caught", 0)) + 1
		if bool(result.get("eldritch", false)):
			var fish_definition := ContentRegistry.get_artifact("fish", fish_id)
			var tide_result: Dictionary = eldritch.apply_catch(fish_definition, int(result.get("quality", 1)))
			lifetime_stats["eldritch_fish_caught"] = int(lifetime_stats.get("eldritch_fish_caught", 0)) + 1
			result["tide"] = tide_result
			result["message"] = "%s 理智 -%d（%d/%d）" % [result.get("message", ""), tide_result.get("sanity_cost", 0), eldritch.sanity, EldritchTideSystem.MAX_SANITY]
			if bool(tide_result.get("first_catch", false)) and String(quest_states.get("whispers_beneath_tide_quest", "inactive")) == "inactive":
				set_quest_state(&"whispers_beneath_tide_quest", &"active")
		_check_achievements()
		EventBus.farm_changed.emit(&"fish_caught", result)
	return result


func defeat_eldritch_boss() -> Dictionary:
	if not eldritch.defeat_boss():
		return {"ok": false, "message": "異潮尚未顯現，或深海夢行者已被平息"}
	lifetime_stats["eldritch_bosses_defeated"] = int(lifetime_stats.get("eldritch_bosses_defeated", 0)) + 1
	set_quest_state(&"whispers_beneath_tide_quest", &"completed")
	add_item(&"abyssal_relic", 1)
	set_flag(&"eldritch_tide_silenced", true)
	_check_achievements()
	return {"ok": true, "message": "克蘇魯之影沉回無星之海；異潮仍會來，但不再奪走你的名字"}


func cook_recipe(recipe_id: StringName) -> Dictionary:
	var result: Dictionary = cooking.cook(recipe_id, farm.produce)
	if bool(result.get("ok", false)):
		EventBus.farm_changed.emit(&"dish_cooked", result)
	return result


func eat_dish(recipe_id: StringName) -> Dictionary:
	var recipe := ContentRegistry.get_artifact("recipes", recipe_id)
	var key := String(recipe_id)
	if recipe.is_empty() or int(farm.produce.get(key, 0)) <= 0:
		return {"ok": false, "message": "沒有這道料理"}
	farm.produce[key] = int(farm.produce.get(key, 0)) - 1
	var energy := int(recipe.get("energy", 0))
	tools.stamina = mini(ToolSystem.MAX_STAMINA, tools.stamina + energy)
	return {"ok": true, "message": "享用%s，恢復 %d 體力" % [recipe.get("display_name", recipe_id), energy]}


func tend_animal(animal_id: String) -> Dictionary:
	var can_graze := current_weather in ["clear", "fog"]
	var use_feed := not can_graze
	if use_feed and not consume_item(&"animal_feed", 1):
		return {"ok": false, "message": "雨雪天需要動物飼料"}
	return farm.tend_animal(animal_id, use_feed, can_graze)


func next_story_chapter() -> Dictionary:
	return story_progress.next_available(Array(story_state.get("completed_chapters", [])), flags)


func complete_story_chapter(chapter_id: String) -> bool:
	var completed: Array = story_state.get("completed_chapters", [])
	if not story_progress.complete(chapter_id, completed, flags):
		return false
	story_state["completed_chapters"] = completed
	story_state["chapter"] = completed.size() + 1
	return true


func activate_current_story_chapter() -> Dictionary:
	var chapter := next_story_chapter()
	if chapter.is_empty():
		return {"ok": false, "message": "三年主線已完成，鐘聲將陪伴往後每一年"}
	var quest_id := "%s_quest" % chapter.get("id", "")
	if String(quest_states.get(quest_id, "inactive")) == "inactive":
		set_quest_state(quest_id, &"active")
	return {"ok": true, "chapter": chapter, "quest_id": quest_id}


func try_complete_current_story_chapter() -> Dictionary:
	var active := activate_current_story_chapter()
	if not bool(active.get("ok", false)):
		return active
	var chapter: Dictionary = active.get("chapter", {})
	var requirements: Dictionary = story_progress.requirements_met(chapter, story_metrics())
	if not bool(requirements.get("ok", false)):
		return {"ok": false, "message": "章節目標尚未完成", "missing": requirements.get("missing", []), "chapter": chapter}
	var chapter_id := String(chapter.get("id", ""))
	if not complete_story_chapter(chapter_id):
		return {"ok": false, "message": "章節無法結算"}
	var quest_id := "%s_quest" % chapter_id
	set_quest_state(quest_id, &"completed")
	var reward_text := _grant_quest_rewards(ContentRegistry.get_artifact("quests", quest_id))
	return {"ok": true, "message": "章節完成：%s%s" % [chapter.get("title", chapter_id), reward_text], "chapter": chapter}


func story_metrics() -> Dictionary:
	var metrics := lifetime_stats.duplicate(true)
	var maximum_hearts := 0
	var known_villagers := 0
	var known_candidates := 0
	var dating_candidates := 0
	for npc_id: String in social.relationships:
		var hearts: int = social.hearts(npc_id)
		maximum_hearts = maxi(maximum_hearts, hearts)
		known_villagers += int(hearts >= 1)
		if npc_id in ["mira", "lian", "soren", "yuna"]:
			known_candidates += int(hearts >= 2)
			dating_candidates += int(bool(Dictionary(social.relationships[npc_id]).get("dating", false)))
	metrics["relationship_max_hearts"] = maximum_hearts
	metrics["relationship_unique_villagers"] = known_villagers
	metrics["romance_candidates_known"] = known_candidates
	metrics["dating_candidates"] = dating_candidates
	metrics["farm_rank"] = farm.rank
	metrics["dungeon_floor"] = dungeon.max_reached
	metrics["bosses_defeated"] = dungeon.defeated_bosses.size()
	metrics["season_seals"] = dungeon.seals.size()
	metrics["final_boss_defeated"] = 1 if dungeon.final_boss_defeated else 0
	metrics["eldritch_unique_catches"] = eldritch.eldritch_catches.size()
	metrics["eldritch_boss_defeated"] = 1 if eldritch.boss_defeated else 0
	metrics["automation_devices"] = farm.automation_devices.size()
	metrics["automation_networks"] = farm.automation_networks().size()
	metrics["automation_cycles"] = farm.automation_cycle_count
	var upgrade_count := 0
	for level: Variant in tools.tool_levels.values():
		upgrade_count += maxi(0, int(level) - 1)
	metrics["tool_upgrades"] = upgrade_count
	return metrics


func record_enemy_defeat(enemy_id: StringName) -> void:
	lifetime_stats["monsters_defeated"] = int(lifetime_stats.get("monsters_defeated", 0)) + 1
	var definition := ContentRegistry.get_artifact("enemies", enemy_id)
	if bool(definition.get("is_boss", false)):
		lifetime_stats["bosses_defeated"] = int(lifetime_stats.get("bosses_defeated", 0)) + 1
	_check_achievements()


func ship_all_produce() -> Dictionary:
	var shipped_items := 0
	var shipped_value := 0
	for item_id: String in farm.produce.keys():
		var quantity := int(farm.produce.get(item_id, 0))
		if quantity <= 0:
			continue
		var price := _sell_price(item_id)
		if price <= 0:
			continue
		economy.ship(item_id, quantity, price)
		farm.produce[item_id] = 0
		shipped_items += quantity
		shipped_value += quantity * price
	EventBus.farm_changed.emit(&"shipping_updated", {"items": shipped_items, "value": shipped_value})
	return {"ok": shipped_items > 0, "items": shipped_items, "value": shipped_value, "message": "已放入出貨箱 %d 件，明早收入 %dG" % [shipped_items, shipped_value] if shipped_items > 0 else "收成庫沒有可出貨物品"}


func gather_resource(node_id: String, resource_kind: String) -> Dictionary:
	var flag_id := "gathered_%d_%s" % [calendar.absolute_day(), node_id]
	if bool(get_flag(flag_id, false)):
		return {"ok": false, "message": "這處資源今天已採集"}
	var action := "chopping" if resource_kind == "tree" else "mining"
	if not tools.use_for(action):
		return {"ok": false, "message": "體力不足，無法採集"}
	var item_id := "wood" if resource_kind == "tree" else "stone"
	if resource_kind == "ore":
		var depth := maxi(1, dungeon.current_floor)
		item_id = "gold_ore" if depth >= 31 else ("iron_ore" if depth >= 21 else ("copper_ore" if depth >= 11 else "stone"))
	var tool_id := "axe" if resource_kind == "tree" else "pickaxe"
	var quantity := 1 + int(tools.tool_levels.get(tool_id, 1))
	add_item(item_id, quantity)
	set_flag(flag_id, true)
	lifetime_stats["resources_gathered"] = int(lifetime_stats.get("resources_gathered", 0)) + quantity
	return {"ok": true, "item_id": item_id, "quantity": quantity, "message": "取得%s ×%d" % [ContentRegistry.get_artifact("items", item_id).get("display_name", item_id), quantity]}


func gather_map_resource(node_id: String) -> Dictionary:
	var definitions := {
		"river_reeds": {"item_id": "river_reed", "quantity": 2, "action": "cleared"},
		"bellwood_herbs": {"item_id": "forest_herb", "quantity": 2, "action": "cleared"},
		"ruins_gears": {"item_id": "ancient_gear", "quantity": 1, "action": "mining"},
	}
	if not definitions.has(node_id):
		return {"ok": false, "message": "找不到這處地圖資源"}
	var daily_flag := "map_resource_%d_%s" % [calendar.absolute_day(), node_id]
	if bool(get_flag(daily_flag, false)):
		return {"ok": false, "message": "這處資源今天已採集"}
	var definition: Dictionary = definitions[node_id]
	if not tools.use_for(String(definition.action)):
		return {"ok": false, "message": "體力不足，今天無法採集"}
	var item_id := String(definition.item_id)
	var quantity := int(definition.quantity)
	add_item(item_id, quantity)
	set_flag(daily_flag, true)
	lifetime_stats["resources_gathered"] = int(lifetime_stats.get("resources_gathered", 0)) + quantity
	return {"ok": true, "item_id": item_id, "quantity": quantity, "message": "取得%s ×%d" % [ContentRegistry.get_artifact("items", item_id).get("display_name", item_id), quantity]}


func buy_offer(shop_id: StringName, offer_id: String) -> Dictionary:
	if not shops.is_open(shop_id, calendar.minute_of_day):
		return {"ok": false, "message": "商店目前沒有營業"}
	var available: Array[Dictionary] = shops.offers(shop_id, calendar.season_id(), farm.rank, tools.tool_levels)
	var selected: Dictionary = {}
	for offer: Dictionary in available:
		if String(offer.get("id", "")) == offer_id:
			selected = offer
			break
	if selected.is_empty():
		return {"ok": false, "message": "商品不存在或尚未解鎖"}
	var price := int(selected.get("price", 0))
	if coins < price:
		return {"ok": false, "message": "金幣不足"}
	var kind := String(selected.get("kind", ""))
	var target_id := String(selected.get("target_id", ""))
	if kind == "tool_upgrade":
		var definition := ContentRegistry.get_artifact("tools", target_id)
		var next_level := int(tools.tool_levels.get(target_id, 1)) + 1
		var tier: Dictionary = Array(definition.get("tiers", []))[next_level - 1]
		for material_id: String in Dictionary(tier.get("materials", {})).keys():
			if int(inventory.get(material_id, 0)) < int(tier.materials[material_id]):
				return {"ok": false, "message": "缺少升級材料：%s" % ContentRegistry.get_artifact("items", material_id).get("display_name", material_id)}
		for material_id: String in Dictionary(tier.get("materials", {})).keys():
			consume_item(material_id, int(tier.materials[material_id]))
		var upgrade_result: Dictionary = tools.upgrade(target_id)
		if not bool(upgrade_result.get("ok", false)):
			return upgrade_result
	elif kind == "seed":
		farm.seed_stock[target_id] = int(farm.seed_stock.get(target_id, 0)) + int(selected.get("quantity", 1))
	elif kind == "item":
		add_item(target_id, int(selected.get("quantity", 1)))
	elif kind == "animal":
		var animal_result: Dictionary = farm.purchase_animal(target_id)
		if not bool(animal_result.get("ok", false)):
			return animal_result
	else:
		return {"ok": false, "message": "這項商品尚未支援"}
	coins -= price
	economy.record_purchase(offer_id, price)
	lifetime_stats["purchases"] = int(lifetime_stats.get("purchases", 0)) + 1
	return {"ok": true, "message": "購買%s，支付 %dG" % [selected.get("display_name", offer_id), price], "offer": selected}


func marry_candidate(npc_id: StringName) -> bool:
	if not social.marry(npc_id, calendar.absolute_day()):
		return false
	lifetime_stats["marriages"] = 1
	_check_achievements()
	return true


func start_dating_candidate(npc_id: StringName) -> Dictionary:
	if npc_id not in [&"mira", &"lian", &"soren", &"yuna"]:
		return {"ok": false, "message": "這名角色不是戀愛候選人"}
	if not social.start_dating(npc_id):
		return {"ok": false, "message": "需要 6 心才能開始交往"}
	return {"ok": true, "message": "你與%s開始交往" % ContentRegistry.get_artifact("characters", npc_id).get("display_name", npc_id)}


func propose_to_candidate(npc_id: StringName) -> Dictionary:
	if not marry_candidate(npc_id):
		return {"ok": false, "message": "求婚需要 10 心且已經交往"}
	return {"ok": true, "message": "鐘聲見證了你們的婚禮"}


func advance_family() -> Dictionary:
	var absolute_day: int = int(calendar.absolute_day())
	if social.can_start_family_talk(absolute_day):
		social.confirm_family_talk()
		return {"ok": true, "message": "你們談過未來，決定迎接新的家人"}
	if bool(social.marriage.get("family_talk_seen", false)) and not bool(social.child.get("exists", false)):
		if social.welcome_child("小鐘", absolute_day):
			return {"ok": true, "message": "小鐘來到了這個家"}
		return {"ok": false, "message": "家庭討論後還需等待，婚後至少 60 日"}
	return {"ok": false, "message": "結婚滿 30 日後可討論家庭"}


func purchase_next_farm_upgrade() -> Dictionary:
	if farm.rank >= 10:
		return {"ok": false, "message": "農場已達最高等級"}
	var definition := ContentRegistry.get_artifact("farm_upgrades", "farm_rank_%d" % (farm.rank + 1))
	var cost := int(definition.get("cost", 0))
	if coins < cost:
		return {"ok": false, "message": "農場擴建需要 %dG" % cost}
	var materials: Dictionary = definition.get("materials", {})
	for material_id: String in materials:
		if int(inventory.get(material_id, 0)) < int(materials[material_id]):
			return {"ok": false, "message": "缺少%s %d 個" % [ContentRegistry.get_artifact("items", material_id).get("display_name", material_id), materials[material_id]]}
	for material_id: String in materials:
		consume_item(material_id, int(materials[material_id]))
	coins -= cost
	economy.record_purchase("farm_rank_%d" % (farm.rank + 1), cost)
	if not farm.unlock_rank(farm.rank + 1):
		return {"ok": false, "message": "農場擴建失敗"}
	return {"ok": true, "message": "農場升至 Lv.%d：%s" % [farm.rank, definition.get("display_name", "擴建完成")]}


func to_save_data() -> Dictionary:
	return {
		"schema_version": SAVE_SCHEMA_VERSION,
		"player": {"name": player_profile.get("name", "旅人"), "appearance": Dictionary(player_profile.get("appearance", {})).duplicate(true), "position": [player_position.x, player_position.y], "stats": player_stats.duplicate(true), "coins": coins},
		"map": String(current_map_id),
		"flags": flags.duplicate(true),
		"quests": quest_states.duplicate(true),
		"inventory": inventory.duplicate(true),
		"calendar": calendar.date_snapshot(),
		"weather": {"current": current_weather, "forecast": CalendarSystem.forecast_for_tomorrow(calendar.year, calendar.season_index, calendar.day)},
		"farm": farm.to_data(),
		"relationships": social.relationships.duplicate(true),
		"marriage": social.marriage.duplicate(true),
		"child": social.child.duplicate(true),
		"festivals": festivals.to_data(),
		"dungeon": dungeon.to_data(),
		"eldritch": eldritch.to_data(),
		"story": story_state.duplicate(true),
		"procedural": request_board.to_data(),
		"tools": tools.to_data(),
		"economy": economy.to_data(),
		"achievements": achievements.to_data(),
		"lifetime_stats": lifetime_stats.duplicate(true),
		"settings": settings.duplicate(true),
	}


func load_save_data(source_data: Dictionary) -> bool:
	var version := int(source_data.get("schema_version", -1))
	var data := _migrate_v1(source_data) if version == 1 else source_data.duplicate(true)
	if int(data.get("schema_version", -1)) == 2:
		data = _migrate_v2(data)
	if int(data.get("schema_version", -1)) == 3:
		data = _migrate_v3(data)
	if int(data.get("schema_version", -1)) == 4:
		data = _migrate_v4(data)
	if int(data.get("schema_version", -1)) != SAVE_SCHEMA_VERSION:
		return false
	flags = Dictionary(data.get("flags", {})).duplicate(true)
	quest_states = Dictionary(data.get("quests", {})).duplicate(true)
	inventory = Dictionary(data.get("inventory", {})).duplicate(true)
	var player_data := Dictionary(data.get("player", {}))
	player_profile = {"name": String(player_data.get("name", "旅人")), "appearance": Dictionary(player_data.get("appearance", {})).duplicate(true)}
	player_stats = Dictionary(player_data.get("stats", {})).duplicate(true)
	coins = maxi(0, int(player_data.get("coins", 500)))
	current_map_id = StringName(data.get("map", "mistfall_farm"))
	var position_data: Array = player_data.get("position", [320.0, 180.0])
	if position_data.size() >= 2:
		player_position = Vector2(float(position_data[0]), float(position_data[1]))
	calendar.load_data(Dictionary(data.get("calendar", {})))
	current_weather = String(Dictionary(data.get("weather", {})).get("current", CalendarSystem.weather_for(calendar.year, calendar.season_index, calendar.day)))
	farm.load_data(Dictionary(data.get("farm", {})))
	social.load_data({"relationships": data.get("relationships", {}), "marriage": data.get("marriage", {}), "child": data.get("child", {})})
	festivals.load_data(Dictionary(data.get("festivals", {})))
	dungeon.load_data(Dictionary(data.get("dungeon", {})))
	eldritch.load_data(Dictionary(data.get("eldritch", {})))
	story_state = Dictionary(data.get("story", {})).duplicate(true)
	request_board.load_data(Dictionary(data.get("procedural", {})))
	tools.load_data(Dictionary(data.get("tools", {})))
	economy.load_data(Dictionary(data.get("economy", {})))
	achievements.load_data(Dictionary(data.get("achievements", {})))
	lifetime_stats = Dictionary(data.get("lifetime_stats", {})).duplicate(true)
	settings = Dictionary(data.get("settings", {})).duplicate(true)
	return true


func _migrate_v1(data: Dictionary) -> Dictionary:
	var old_player := Dictionary(data.get("player", {}))
	var old_calendar := Dictionary(data.get("calendar", {}))
	var migrated_season_index := clampi(int(old_calendar.get("season_index", 0)), 0, 3)
	var migrated_day := clampi(int(old_calendar.get("day", 1)), 1, 30)
	return {
		"schema_version": 2,
		"player": {"name": "旅人", "appearance": {"body": "neutral", "skin": 1, "hair": 0, "outfit": 0}, "position": old_player.get("position", data.get("player_position", [320.0, 180.0])), "stats": old_player.get("stats", data.get("player_stats", {"max_health": 100, "health": 100, "attack": 16})), "coins": 500},
		"map": data.get("map", data.get("current_map_id", "mistfall_farm")),
		"flags": data.get("flags", {}), "quests": data.get("quests", data.get("quest_states", {})), "inventory": data.get("inventory", {}),
		"calendar": {"year": maxi(1, int(old_calendar.get("year", 1))), "season_index": migrated_season_index, "season": String(CalendarSystem.SEASON_IDS[migrated_season_index]), "day": migrated_day, "minute_of_day": clampi(int(old_calendar.get("minute_of_day", 360)), 360, 1440), "speed_mode": String(old_calendar.get("speed_mode", "standard"))},
		"weather": {"current": "clear", "forecast": {}},
		"farm": {"rank": 1, "plots": {}, "seed_stock": {"spring_turnip": 8, "spring_potato": 4, "spring_strawberry": 2}, "produce": {}, "animals": [], "greenhouse_unlocked": false, "unlocked_upgrades": []},
		"relationships": {}, "marriage": {"spouse_id": "", "married_absolute_day": 0, "family_talk_seen": false}, "child": {"exists": false, "name": "", "born_absolute_day": 0, "stage": "none"},
		"festivals": {"attended": {}}, "dungeon": {"current_floor": 0, "max_reached": 0, "cleared_floors": [], "defeated_bosses": [], "seals": [], "final_boss_defeated": false, "endless_unlocked": false},
		"story": {"chapter": 1, "completed_chapters": [], "season_seals": [], "final_boss_available": false}, "procedural": {"active_requests": [], "completed_request_ids": []},
	}


func _migrate_v2(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["schema_version"] = 3
	migrated["tools"] = {"stamina": ToolSystem.MAX_STAMINA, "tool_levels": {"hoe": 1, "watering_can": 1, "axe": 1, "pickaxe": 1, "fishing_rod": 1, "sickle": 1}, "equipped_tool": "hoe"}
	migrated["economy"] = {"shipping_bin": {}, "total_earned": 0, "total_spent": 0, "purchase_counts": {}, "last_shipping_total": 0}
	migrated["achievements"] = {"unlocked": []}
	migrated["lifetime_stats"] = {"days_played": 0, "crops_harvested": 0, "fish_caught": 0, "resources_gathered": 0, "monsters_defeated": 0, "bosses_defeated": 0, "festivals_attended": 0, "relationship_hearts": 0, "marriages": 0, "coins_earned": 0, "purchases": 0}
	migrated["settings"] = {"master_volume": 0.8, "text_speed": 1.0, "fullscreen": false, "control_prompts": "auto"}
	return migrated


func _migrate_v3(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["schema_version"] = 4
	migrated["eldritch"] = {"sanity": EldritchTideSystem.MAX_SANITY, "insight": 0, "eldritch_catches": {}, "whispers_seen": [], "boss_unlocked": false, "boss_defeated": false}
	var migrated_stats: Dictionary = Dictionary(migrated.get("lifetime_stats", {})).duplicate(true)
	migrated_stats["eldritch_fish_caught"] = int(migrated_stats.get("eldritch_fish_caught", 0))
	migrated_stats["eldritch_bosses_defeated"] = int(migrated_stats.get("eldritch_bosses_defeated", 0))
	migrated["lifetime_stats"] = migrated_stats
	return migrated


func _migrate_v4(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["schema_version"] = 5
	var migrated_farm: Dictionary = Dictionary(migrated.get("farm", {})).duplicate(true)
	migrated_farm["automation_devices"] = Dictionary(migrated_farm.get("automation_devices", {})).duplicate(true)
	migrated_farm["automation_cycle_count"] = int(migrated_farm.get("automation_cycle_count", 0))
	migrated_farm["automation_last_report"] = Dictionary(migrated_farm.get("automation_last_report", {})).duplicate(true)
	migrated["farm"] = migrated_farm
	var migrated_stats: Dictionary = Dictionary(migrated.get("lifetime_stats", {})).duplicate(true)
	for key in ["automation_cycles", "automated_tiles_watered", "automated_crops_planted", "automated_crops_harvested", "automation_animals_fed", "automation_items_processed"]:
		migrated_stats[key] = int(migrated_stats.get(key, 0))
	migrated["lifetime_stats"] = migrated_stats
	return migrated


func _farm_action_for(tile: Vector2i) -> String:
	var key := "%d,%d" % [tile.x, tile.y]
	var plot: Dictionary = Dictionary(farm.plots.get(key, {}))
	if plot.is_empty() or not bool(plot.get("tilled", false)):
		return "tilled"
	if bool(plot.get("withered", false)):
		return "cleared"
	if bool(plot.get("ready", false)):
		return "harvested"
	if not String(plot.get("crop_id", "")).is_empty() and not bool(plot.get("watered", false)):
		return "watered"
	return ""


func _sell_price(item_id: String) -> int:
	var crop := ContentRegistry.get_artifact("crops", item_id)
	if not crop.is_empty():
		return int(crop.get("sell_price", 0))
	var fish_definition := ContentRegistry.get_artifact("fish", item_id)
	if not fish_definition.is_empty():
		return int(fish_definition.get("sell_price", 0))
	return {"egg": 90, "milk": 260, "mist_preserves": 420, "dream_tide_salt": 1800}.get(item_id, 0)


func _update_relationship_metric() -> void:
	var hearts_total := 0
	for relationship: Dictionary in social.relationships.values():
		hearts_total += int(relationship.get("friendship", 0)) / 250
	lifetime_stats["relationship_hearts"] = hearts_total


func _check_achievements() -> void:
	lifetime_stats["bosses_defeated"] = dungeon.defeated_bosses.size()
	lifetime_stats["marriages"] = 0 if String(social.marriage.get("spouse_id", "")).is_empty() else 1
	for achievement: Dictionary in achievements.evaluate(lifetime_stats):
		var reward := int(achievement.get("reward_coins", 0))
		coins += reward
		EventBus.toast("成就解鎖：%s（+%dG）" % [achievement.get("display_name", "成就"), reward])


func _grant_quest_rewards(quest: Dictionary) -> String:
	var labels := PackedStringArray()
	for reward: Dictionary in quest.get("rewards", []):
		var count := int(reward.get("count", 1))
		match String(reward.get("type", "")):
			"currency":
				coins += count
				labels.append("、%dG" % count)
			"item":
				add_item(StringName(reward.get("id", "")), count)
				labels.append("、%s×%d" % [ContentRegistry.get_artifact("items", reward.get("id", "")).get("display_name", reward.get("id", "")), count])
	return "".join(labels)


func speed_display_name(mode: String) -> String:
	return {"fast": "快速 10 分鐘", "standard": "標準 15 分鐘", "relaxed": "悠閒 20 分鐘"}.get(mode, mode)


func _on_calendar_time_changed(year: int, season_id: StringName, day: int, minute_of_day: int) -> void:
	EventBus.calendar_time_changed.emit(year, season_id, day, minute_of_day)
