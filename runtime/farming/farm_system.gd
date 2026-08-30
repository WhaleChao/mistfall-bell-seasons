class_name PixelRPGFarmSystem
extends RefCounted

const MAX_RANK := 10

var rank := 1
var plots: Dictionary = {}
var seed_stock: Dictionary = {}
var produce: Dictionary = {}
var animals: Array[Dictionary] = []
var greenhouse_unlocked := false
var unlocked_upgrades: Array[String] = []


func reset() -> void:
	rank = 1
	plots.clear()
	seed_stock = {"spring_turnip": 8, "spring_potato": 4, "spring_strawberry": 2}
	produce.clear()
	animals.clear()
	greenhouse_unlocked = false
	unlocked_upgrades.clear()


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


func to_data() -> Dictionary:
	return {"rank": rank, "plots": plots.duplicate(true), "seed_stock": seed_stock.duplicate(true), "produce": produce.duplicate(true), "animals": animals.duplicate(true), "greenhouse_unlocked": greenhouse_unlocked, "unlocked_upgrades": unlocked_upgrades.duplicate()}


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
