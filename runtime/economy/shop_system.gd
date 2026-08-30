class_name PixelRPGShopSystem
extends RefCounted


func is_open(shop_id: StringName, minute_of_day: int) -> bool:
	var shop := ContentRegistry.get_artifact("shops", shop_id)
	return not shop.is_empty() and minute_of_day >= int(shop.get("open_minute", 0)) and minute_of_day < int(shop.get("close_minute", 1440))


func offers(shop_id: StringName, season_id: StringName, farm_rank: int, tool_levels: Dictionary) -> Array[Dictionary]:
	var shop := ContentRegistry.get_artifact("shops", shop_id)
	var result: Array[Dictionary] = []
	if shop.is_empty():
		return result
	match String(shop.get("catalog_mode", "fixed")):
		"seasonal_seeds":
			for crop: Dictionary in ContentRegistry.get_all("crops"):
				if String(season_id) in crop.get("seasons", []):
					result.append({"id": "seed_%s" % crop.id, "kind": "seed", "target_id": crop.id, "display_name": "%s種子" % crop.display_name, "quantity": 1, "price": int(crop.seed_price), "required_rank": 1})
		"tool_upgrades":
			for tool: Dictionary in ContentRegistry.get_all("tools"):
				var next_level := int(tool_levels.get(String(tool.id), 1)) + 1
				if next_level <= 4:
					var tier: Dictionary = tool.tiers[next_level - 1]
					if farm_rank >= int(tier.required_rank):
						result.append({"id": "%s_lv%d" % [tool.id, next_level], "kind": "tool_upgrade", "target_id": tool.id, "display_name": "%s Lv.%d" % [tool.display_name, next_level], "quantity": 1, "price": int(tier.price), "required_rank": int(tier.required_rank)})
		_:
			for offer: Dictionary in shop.get("offers", []):
				if farm_rank >= int(offer.get("required_rank", 1)):
					result.append(offer.duplicate(true))
	return result
