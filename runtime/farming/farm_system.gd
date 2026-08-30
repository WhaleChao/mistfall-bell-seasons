class_name PixelRPGFarmSystem
extends RefCounted

const MAX_RANK := 10
const AUTOMATION_WIDTH := 6
const AUTOMATION_HEIGHT := 4

var rank := 1
var plots: Dictionary = {}
var seed_stock: Dictionary = {}
var produce: Dictionary = {}
var animals: Array[Dictionary] = []
var greenhouse_unlocked := false
var unlocked_upgrades: Array[String] = []
var automation_devices: Dictionary = {}
var automation_cycle_count := 0
var automation_last_report: Dictionary = {}


func reset() -> void:
	rank = 1
	plots.clear()
	seed_stock = {"spring_turnip": 8, "spring_potato": 4, "spring_strawberry": 2}
	produce.clear()
	animals.clear()
	greenhouse_unlocked = false
	unlocked_upgrades.clear()
	automation_devices.clear()
	automation_cycle_count = 0
	automation_last_report = _empty_automation_report()


func interact_plot(tile: Vector2i, crop_id: StringName, season_id: StringName) -> Dictionary:
	var key := _key(tile)
	var plot: Dictionary = Dictionary(plots.get(key, _new_plot(tile))).duplicate(true)
	if not bool(plot.get("tilled", false)):
		plot.tilled = true
		plots[key] = plot
		return {"ok": true, "action": "tilled", "message": "翻鬆了土地"}
	if String(plot.get("crop_id", "")).is_empty():
		var definition := ContentRegistry.get_artifact("crops", crop_id)
		if definition.is_empty():
			return {"ok": false, "message": "找不到所選種子的作物資料"}
		if int(seed_stock.get(String(crop_id), 0)) <= 0:
			return {"ok": false, "message": "這種種子已經用完"}
		var valid_seasons: Array = definition.get("seasons", [])
		if String(season_id) not in valid_seasons and not greenhouse_unlocked and not bool(definition.get("cross_season", false)):
			return {"ok": false, "message": "這種作物不適合目前季節"}
		seed_stock[String(crop_id)] = int(seed_stock.get(String(crop_id), 0)) - 1
		plot.crop_id = String(crop_id)
		plot.growth_progress = 0
		plot.ready = false
		plot.watered = false
		plot.withered = false
		plots[key] = plot
		return {"ok": true, "action": "planted", "message": "種下了%s" % definition.get("display_name", crop_id)}
	if bool(plot.get("withered", false)):
		plot = _new_plot(tile)
		plot.tilled = true
		plots[key] = plot
		return {"ok": true, "action": "cleared", "message": "清除了枯萎作物"}
	if bool(plot.get("ready", false)):
		return harvest(tile)
	if not bool(plot.get("watered", false)):
		plot.watered = true
		plots[key] = plot
		return {"ok": true, "action": "watered", "message": "澆水完成"}
	return {"ok": false, "message": "今天已經澆過水了"}


func harvest(tile: Vector2i) -> Dictionary:
	var key := _key(tile)
	if not plots.has(key):
		return {"ok": false, "message": "這裡沒有可收成作物"}
	var plot: Dictionary = Dictionary(plots[key]).duplicate(true)
	if not bool(plot.get("ready", false)):
		return {"ok": false, "message": "作物還沒成熟"}
	var crop_id := String(plot.get("crop_id", ""))
	var definition := ContentRegistry.get_artifact("crops", crop_id)
	var amount := 1 + int(rank >= 5 and posmod(plot.get("tile", [0, 0])[0] + plot.get("tile", [0, 0])[1], 3) == 0)
	produce[crop_id] = int(produce.get(crop_id, 0)) + amount
	var regrow_days := int(definition.get("regrow_days", 0))
	if regrow_days > 0:
		plot.growth_progress = maxi(0, int(definition.get("growth_days", 1)) - regrow_days)
		plot.ready = false
		plot.watered = false
	else:
		plot = _new_plot(tile)
		plot.tilled = true
	plots[key] = plot
	return {"ok": true, "action": "harvested", "crop_id": crop_id, "quantity": amount, "message": "收成 %s ×%d" % [definition.get("display_name", crop_id), amount]}


func advance_day(new_season_id: StringName, weather: String) -> Array[String]:
	var messages: Array[String] = []
	for key: String in plots.keys():
		var plot: Dictionary = Dictionary(plots[key]).duplicate(true)
		var crop_id := String(plot.get("crop_id", ""))
		if crop_id.is_empty() or bool(plot.get("withered", false)):
			plot.watered = false
			plots[key] = plot
			continue
		var definition := ContentRegistry.get_artifact("crops", crop_id)
		var valid_seasons: Array = definition.get("seasons", [])
		if String(new_season_id) not in valid_seasons and not greenhouse_unlocked and not bool(definition.get("cross_season", false)):
			plot.withered = true
			plot.ready = false
			messages.append("換季使%s枯萎" % definition.get("display_name", crop_id))
		else:
			var naturally_watered := weather in ["rain", "storm", "typhoon"]
			if bool(plot.get("watered", false)) or naturally_watered:
				plot.growth_progress = int(plot.get("growth_progress", 0)) + 1
				plot.ready = int(plot.growth_progress) >= int(definition.get("growth_days", 1))
			plot.watered = false
		plots[key] = plot
	_advance_animals(weather)
	return messages


func tend_animal(animal_id: String, feed: bool = true, graze: bool = false) -> Dictionary:
	for index in range(animals.size()):
		if String(animals[index].get("id", "")) != animal_id:
			continue
		var animal: Dictionary = animals[index].duplicate(true)
		animal.fed = bool(animal.get("fed", false)) or feed
		animal.grazed = bool(animal.get("grazed", false)) or graze
		animal.mood = clampi(int(animal.get("mood", 50)) + 4 + (3 if graze else 0), 0, 100)
		animals[index] = animal
		return {"ok": true, "message": "%s看起來很開心" % animal.get("name", animal_id)}
	return {"ok": false, "message": "找不到這隻動物"}


func collect_animal_product(animal_id: String) -> Dictionary:
	for index in range(animals.size()):
		if String(animals[index].get("id", "")) != animal_id:
			continue
		var animal: Dictionary = animals[index].duplicate(true)
		if not bool(animal.get("product_ready", false)):
			return {"ok": false, "message": "今天還沒有產物"}
		var product_id := "egg" if animal.get("species") == "chicken" else "milk"
		var quality := 1 + int(animal.get("hearts", 0)) / 3
		produce[product_id] = int(produce.get(product_id, 0)) + 1
		animal.product_ready = false
		animals[index] = animal
		return {"ok": true, "product_id": product_id, "quality": clampi(quality, 1, 4), "message": "取得%s（品質 %d）" % ["雞蛋" if product_id == "egg" else "牛奶", clampi(quality, 1, 4)]}
	return {"ok": false, "message": "找不到這隻動物"}


func begin_breeding(animal_id: String) -> Dictionary:
	for index in range(animals.size()):
		if String(animals[index].get("id", "")) != animal_id:
			continue
		var animal: Dictionary = animals[index].duplicate(true)
		if int(animal.get("hearts", 0)) < 5:
			return {"ok": false, "message": "動物需要至少 5 心才能繁殖"}
		if int(animal.get("pregnant_days", 0)) > 0:
			return {"ok": false, "message": "已在等待新生命到來"}
		var definition := ContentRegistry.get_artifact("animals", StringName(animal.get("species", "")))
		animal.pregnant_days = int(definition.get("gestation_days", 10))
		animals[index] = animal
		return {"ok": true, "message": "%s開始等待新生命" % animal.get("name", animal_id)}
	return {"ok": false, "message": "找不到這隻動物"}


func purchase_animal(species: String) -> Dictionary:
	var definition := ContentRegistry.get_artifact("animals", species)
	if definition.is_empty():
		return {"ok": false, "message": "找不到動物資料"}
	var required_rank := 3 if species == "chicken" else 6
	if rank < required_rank:
		return {"ok": false, "message": "農場需達 Lv.%d" % required_rank}
	var next_index := 1
	for animal: Dictionary in animals:
		if String(animal.get("species", "")) == species:
			next_index += 1
	var animal_id := "%s_%d" % [species, next_index]
	var display_name := "小霧%d" % next_index if species == "chicken" else "奶鐘%d" % next_index
	animals.append({"id": animal_id, "species": species, "name": display_name, "hearts": 0, "mood": 55, "fed": false, "grazed": false, "product_ready": false, "pregnant_days": 0})
	return {"ok": true, "animal_id": animal_id, "message": "%s加入了農場" % definition.get("display_name", species)}


func unlock_rank(new_rank: int) -> bool:
	if new_rank != rank + 1 or new_rank > MAX_RANK:
		return false
	rank = new_rank
	var upgrade := ContentRegistry.get_artifact("farm_upgrades", "farm_rank_%d" % rank)
	if not upgrade.is_empty():
		unlocked_upgrades.append(String(upgrade.get("id")))
		if bool(upgrade.get("unlocks_greenhouse", false)):
			greenhouse_unlocked = true
	return true


func place_automation_device(tile: Vector2i, device_id: StringName, config: Dictionary = {}) -> Dictionary:
	if not _valid_automation_tile(tile):
		return {"ok": false, "message": "設備只能放在 6×4 農場設計格內"}
	var key := _key(tile)
	if automation_devices.has(key):
		return {"ok": false, "message": "這個設計格已有設備"}
	var definition := ContentRegistry.get_artifact("automation_devices", device_id)
	if definition.is_empty():
		return {"ok": false, "message": "找不到自動化設備資料"}
	if rank < int(definition.get("required_rank", MAX_RANK)):
		return {"ok": false, "message": "農場需達 Lv.%d" % definition.get("required_rank", MAX_RANK)}
	var crop_filter := String(config.get("crop_filter", "spring_turnip"))
	if not crop_filter.is_empty() and ContentRegistry.get_artifact("crops", crop_filter).is_empty():
		crop_filter = "spring_turnip"
	automation_devices[key] = {
		"tile": [tile.x, tile.y],
		"device_id": String(device_id),
		"enabled": bool(config.get("enabled", true)),
		"priority": clampi(int(config.get("priority", 50)), 0, 100),
		"crop_filter": crop_filter,
		"direction": String(config.get("direction", "east")),
		"network_id": "",
	}
	automation_networks()
	return {"ok": true, "action": "automation_placed", "tile": [tile.x, tile.y], "device_id": String(device_id), "message": "已放置%s" % definition.get("display_name", device_id)}


func configure_automation_device(tile: Vector2i, config: Dictionary) -> Dictionary:
	var key := _key(tile)
	if not automation_devices.has(key):
		return {"ok": false, "message": "這裡沒有可設定的設備"}
	var device: Dictionary = Dictionary(automation_devices[key]).duplicate(true)
	if config.has("enabled"):
		device.enabled = bool(config.enabled)
	if config.has("priority"):
		device.priority = clampi(int(config.priority), 0, 100)
	if config.has("crop_filter"):
		var crop_filter := String(config.crop_filter)
		if not crop_filter.is_empty() and ContentRegistry.get_artifact("crops", crop_filter).is_empty():
			return {"ok": false, "message": "作物篩選不存在"}
		device.crop_filter = crop_filter
	if config.has("direction") and String(config.direction) in ["north", "east", "south", "west"]:
		device.direction = String(config.direction)
	automation_devices[key] = device
	return {"ok": true, "action": "automation_configured", "message": "設備設定已更新"}


func remove_automation_device(tile: Vector2i) -> Dictionary:
	var key := _key(tile)
	if not automation_devices.has(key):
		return {"ok": false, "message": "這裡沒有設備"}
	var removed: Dictionary = automation_devices[key]
	automation_devices.erase(key)
	automation_networks()
	return {"ok": true, "action": "automation_removed", "device_id": removed.get("device_id", ""), "message": "設備已拆除，材料不退還"}


func automation_networks() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var keys: Array = automation_devices.keys()
	keys.sort()
	var visited: Dictionary = {}
	for start_key: String in keys:
		if visited.has(start_key):
			continue
		var queue: Array[String] = [start_key]
		var component: Array[String] = []
		visited[start_key] = true
		while not queue.is_empty():
			var key: String = queue.pop_front()
			component.append(key)
			var tile := _tile_from_key(key)
			for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var neighbor_key := _key(tile + offset)
				if automation_devices.has(neighbor_key) and not visited.has(neighbor_key):
					visited[neighbor_key] = true
					queue.append(neighbor_key)
		component.sort()
		var network_id := "net_%s" % component[0].replace(",", "_")
		var summary := {"id": network_id, "devices": component.duplicate(), "device_count": component.size(), "power_generation": 0, "power_demand": 0, "water_generation": 0, "water_demand": 0, "enabled_devices": 0}
		for key: String in component:
			var device: Dictionary = Dictionary(automation_devices[key]).duplicate(true)
			device.network_id = network_id
			automation_devices[key] = device
			if not bool(device.get("enabled", true)):
				continue
			var definition := ContentRegistry.get_artifact("automation_devices", StringName(device.get("device_id", "")))
			summary.power_generation += int(definition.get("power_generation", 0))
			summary.power_demand += int(definition.get("power_use", 0))
			summary.water_generation += int(definition.get("water_generation", 0))
			summary.water_demand += int(definition.get("water_use", 0))
			summary.enabled_devices += 1
		summary["powered"] = int(summary.power_generation) > 0
		summary["balanced"] = int(summary.power_generation) >= int(summary.power_demand) and int(summary.water_generation) >= int(summary.water_demand)
		result.append(summary)
	return result


func run_automation_day(season_id: StringName, inventory: Dictionary) -> Dictionary:
	var report := _empty_automation_report()
	var networks := automation_networks()
	report.networks = networks.size()
	report.devices = automation_devices.size()
	var budgets: Dictionary = {}
	for network: Dictionary in networks:
		budgets[String(network.id)] = {"power": int(network.power_generation), "water": 0}
	var keys: Array = automation_devices.keys()
	keys.sort_custom(func(a: String, b: String) -> bool:
		var priority_a := int(Dictionary(automation_devices[a]).get("priority", 50))
		var priority_b := int(Dictionary(automation_devices[b]).get("priority", 50))
		return priority_a > priority_b if priority_a != priority_b else a < b
	)
	# Pumps establish the water budget before field machines are evaluated.
	for key: String in keys:
		var pump: Dictionary = automation_devices[key]
		if not bool(pump.get("enabled", true)) or String(pump.get("device_id", "")) != "mist_pump":
			continue
		var pump_definition := ContentRegistry.get_artifact("automation_devices", &"mist_pump")
		var pump_budget: Dictionary = budgets.get(String(pump.get("network_id", "")), {})
		if pump_budget.is_empty() or int(pump_budget.get("power", 0)) < int(pump_definition.get("power_use", 0)):
			report.stalled += 1
			continue
		pump_budget.power -= int(pump_definition.get("power_use", 0))
		pump_budget.water += int(pump_definition.get("water_generation", 0))
		report.active += 1
	for key: String in keys:
		var device: Dictionary = automation_devices[key]
		if not bool(device.get("enabled", true)):
			continue
		var device_id := String(device.get("device_id", ""))
		if device_id in ["bell_generator", "copper_conveyor", "mist_pump"]:
			if device_id in ["bell_generator", "copper_conveyor"]:
				report.active += 1
			continue
		var definition := ContentRegistry.get_artifact("automation_devices", device_id)
		var budget: Dictionary = budgets.get(String(device.get("network_id", "")), {})
		var power_use := int(definition.get("power_use", 0))
		var water_use := int(definition.get("water_use", 0))
		if budget.is_empty() or int(budget.get("power", 0)) < power_use or int(budget.get("water", 0)) < water_use:
			report.stalled += 1
			continue
		budget.power -= power_use
		budget.water -= water_use
		var tile := _tile_from_key(key)
		var worked := false
		match device_id:
			"field_sprinkler":
				var watered := _automate_watering(tile, int(definition.get("range", 1)))
				report.watered += watered
				worked = watered > 0
			"seed_distributor":
				var planted := _automate_planting(tile, int(definition.get("range", 1)), StringName(device.get("crop_filter", "spring_turnip")), season_id)
				report.planted += planted
				worked = planted > 0
			"crop_harvester":
				var harvest_result := _automate_harvest(tile, int(definition.get("range", 1)))
				report.harvested += int(harvest_result.get("crops", 0))
				worked = int(harvest_result.get("crops", 0)) > 0
			"preserves_processor":
				worked = _automate_processing()
				report.processed += int(worked)
			"animal_feeder":
				var fed := _automate_feeding(inventory)
				report.fed += fed
				worked = fed > 0
			"tide_condenser":
				worked = _automate_tide_condensing(inventory)
				report.processed += int(worked)
		if worked:
			report.active += 1
		else:
			report.idle += 1
	automation_cycle_count += int(not automation_devices.is_empty())
	report.cycle = automation_cycle_count
	report.power_remaining = 0
	report.water_remaining = 0
	for budget: Dictionary in budgets.values():
		report.power_remaining += int(budget.get("power", 0))
		report.water_remaining += int(budget.get("water", 0))
	report.message = "自動鐘網：%d 網路／%d 運作／%d 停機；澆水 %d、播種 %d、收成 %d、餵食 %d、加工 %d" % [report.networks, report.active, report.stalled, report.watered, report.planted, report.harvested, report.fed, report.processed]
	automation_last_report = report.duplicate(true)
	return report


func _automate_watering(origin: Vector2i, device_range: int) -> int:
	var watered := 0
	for tile: Vector2i in _tiles_in_range(origin, device_range):
		var key := _key(tile)
		if not plots.has(key):
			continue
		var plot: Dictionary = Dictionary(plots[key]).duplicate(true)
		if not String(plot.get("crop_id", "")).is_empty() and not bool(plot.get("withered", false)) and not bool(plot.get("watered", false)):
			plot.watered = true
			plots[key] = plot
			watered += 1
	return watered


func _automate_planting(origin: Vector2i, device_range: int, crop_id: StringName, season_id: StringName) -> int:
	var definition := ContentRegistry.get_artifact("crops", crop_id)
	if definition.is_empty() or int(seed_stock.get(String(crop_id), 0)) <= 0:
		return 0
	if String(season_id) not in Array(definition.get("seasons", [])) and not greenhouse_unlocked and not bool(definition.get("cross_season", false)):
		return 0
	var planted := 0
	for tile: Vector2i in _tiles_in_range(origin, device_range):
		if planted >= 2 or int(seed_stock.get(String(crop_id), 0)) <= 0:
			break
		var key := _key(tile)
		var plot: Dictionary = Dictionary(plots.get(key, _new_plot(tile))).duplicate(true)
		if not String(plot.get("crop_id", "")).is_empty():
			continue
		plot.tilled = true
		plot.crop_id = String(crop_id)
		plot.growth_progress = 0
		plot.ready = false
		plot.watered = false
		plot.withered = false
		plots[key] = plot
		seed_stock[String(crop_id)] = int(seed_stock.get(String(crop_id), 0)) - 1
		planted += 1
	return planted


func _automate_harvest(origin: Vector2i, device_range: int) -> Dictionary:
	var crop_count := 0
	var tile_count := 0
	for tile: Vector2i in _tiles_in_range(origin, device_range):
		var plot: Dictionary = Dictionary(plots.get(_key(tile), {}))
		if not bool(plot.get("ready", false)):
			continue
		var result := harvest(tile)
		if bool(result.get("ok", false)):
			crop_count += int(result.get("quantity", 0))
			tile_count += 1
	return {"crops": crop_count, "tiles": tile_count}


func _automate_processing() -> bool:
	var candidates: Array = produce.keys()
	candidates.sort()
	for item_id: String in candidates:
		if int(produce.get(item_id, 0)) >= 2 and not ContentRegistry.get_artifact("crops", item_id).is_empty():
			produce[item_id] = int(produce[item_id]) - 2
			produce["mist_preserves"] = int(produce.get("mist_preserves", 0)) + 1
			return true
	return false


func _automate_feeding(inventory: Dictionary) -> int:
	var fed := 0
	for index in range(animals.size()):
		if bool(animals[index].get("fed", false)) or int(inventory.get("animal_feed", 0)) <= 0:
			continue
		var animal: Dictionary = animals[index].duplicate(true)
		animal.fed = true
		animal.mood = clampi(int(animal.get("mood", 50)) + 2, 0, 100)
		animals[index] = animal
		inventory["animal_feed"] = int(inventory.get("animal_feed", 0)) - 1
		fed += 1
	return fed


func _automate_tide_condensing(inventory: Dictionary) -> bool:
	if int(inventory.get("mist_shard", 0)) <= 0:
		return false
	var fish_ids: Array = produce.keys()
	fish_ids.sort()
	for fish_id: String in fish_ids:
		var definition := ContentRegistry.get_artifact("fish", fish_id)
		if int(produce.get(fish_id, 0)) > 0 and bool(definition.get("tide_required", false)):
			produce[fish_id] = int(produce[fish_id]) - 1
			inventory["mist_shard"] = int(inventory.get("mist_shard", 0)) - 1
			produce["dream_tide_salt"] = int(produce.get("dream_tide_salt", 0)) + 1
			return true
	return false


func _tiles_in_range(origin: Vector2i, device_range: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(AUTOMATION_HEIGHT):
		for x in range(AUTOMATION_WIDTH):
			var tile := Vector2i(x, y)
			if absi(tile.x - origin.x) + absi(tile.y - origin.y) <= device_range:
				result.append(tile)
	return result


func _empty_automation_report() -> Dictionary:
	return {"cycle": 0, "networks": 0, "devices": 0, "active": 0, "idle": 0, "stalled": 0, "watered": 0, "planted": 0, "harvested": 0, "fed": 0, "processed": 0, "power_remaining": 0, "water_remaining": 0, "message": "尚未建造自動化網路"}


func to_data() -> Dictionary:
	return {"rank": rank, "plots": plots.duplicate(true), "seed_stock": seed_stock.duplicate(true), "produce": produce.duplicate(true), "animals": animals.duplicate(true), "greenhouse_unlocked": greenhouse_unlocked, "unlocked_upgrades": unlocked_upgrades.duplicate(), "automation_devices": automation_devices.duplicate(true), "automation_cycle_count": automation_cycle_count, "automation_last_report": automation_last_report.duplicate(true)}


func load_data(data: Dictionary) -> void:
	rank = clampi(int(data.get("rank", 1)), 1, MAX_RANK)
	plots = Dictionary(data.get("plots", {})).duplicate(true)
	seed_stock = Dictionary(data.get("seed_stock", {})).duplicate(true)
	produce = Dictionary(data.get("produce", {})).duplicate(true)
	animals.clear()
	for animal: Dictionary in data.get("animals", []):
		animals.append(animal.duplicate(true))
	greenhouse_unlocked = bool(data.get("greenhouse_unlocked", false))
	unlocked_upgrades.assign(data.get("unlocked_upgrades", []))
	automation_devices = Dictionary(data.get("automation_devices", {})).duplicate(true)
	automation_cycle_count = maxi(0, int(data.get("automation_cycle_count", 0)))
	automation_last_report = Dictionary(data.get("automation_last_report", _empty_automation_report())).duplicate(true)
	automation_networks()


func _advance_animals(weather: String) -> void:
	var newborns: Array[Dictionary] = []
	for index in range(animals.size()):
		var animal: Dictionary = animals[index].duplicate(true)
		var was_fed := bool(animal.get("fed", false))
		animal.mood = clampi(int(animal.get("mood", 50)) + (2 if was_fed else -8), 0, 100)
		if was_fed and int(animal.mood) >= 40:
			animal.product_ready = true
		if was_fed and int(animal.mood) >= 75 and weather not in ["storm", "typhoon", "blizzard"]:
			animal.hearts = mini(10, int(animal.get("hearts", 0)) + int(posmod(index + int(animal.mood), 5) == 0))
		animal.fed = false
		animal.grazed = false
		var pregnant_days := int(animal.get("pregnant_days", 0))
		if pregnant_days > 0:
			animal.pregnant_days = pregnant_days - 1
			if int(animal.pregnant_days) == 0:
				var species := String(animal.get("species", "chicken"))
				newborns.append({"id": "%s_%d" % [species, animals.size() + newborns.size() + 1], "species": species, "name": "新生%s" % ("小雞" if species == "chicken" else "小牛"), "hearts": 0, "mood": 55, "fed": false, "grazed": false, "product_ready": false, "pregnant_days": 0})
		animals[index] = animal
	animals.append_array(newborns)


func _new_plot(tile: Vector2i) -> Dictionary:
	return {"tile": [tile.x, tile.y], "tilled": false, "watered": false, "crop_id": "", "growth_progress": 0, "ready": false, "withered": false}


func _key(tile: Vector2i) -> String:
	return "%d,%d" % [tile.x, tile.y]


func _tile_from_key(key: String) -> Vector2i:
	var parts := key.split(",")
	return Vector2i(int(parts[0]), int(parts[1])) if parts.size() == 2 else Vector2i(-1, -1)


func _valid_automation_tile(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.x < AUTOMATION_WIDTH and tile.y >= 0 and tile.y < AUTOMATION_HEIGHT
