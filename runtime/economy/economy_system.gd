class_name PixelRPGEconomySystem
extends RefCounted

var shipping_bin: Dictionary = {}
var total_earned := 0
var total_spent := 0
var purchase_counts: Dictionary = {}
var last_shipping_total := 0


func reset() -> void:
	shipping_bin.clear()
	total_earned = 0
	total_spent = 0
	purchase_counts.clear()
	last_shipping_total = 0


func ship(item_id: String, quantity: int, unit_price: int) -> Dictionary:
	if item_id.is_empty() or quantity <= 0 or unit_price <= 0:
		return {"ok": false, "message": "無法出貨這項物品"}
	var current: Dictionary = Dictionary(shipping_bin.get(item_id, {"quantity": 0, "unit_price": unit_price})).duplicate(true)
	current.quantity = int(current.get("quantity", 0)) + quantity
	current.unit_price = unit_price
	shipping_bin[item_id] = current
	return {"ok": true, "message": "已放入出貨箱 ×%d" % quantity}


func settle_shipping() -> Dictionary:
	var total := 0
	var item_count := 0
	for record: Dictionary in shipping_bin.values():
		total += int(record.get("quantity", 0)) * int(record.get("unit_price", 0))
		item_count += int(record.get("quantity", 0))
	shipping_bin.clear()
	last_shipping_total = total
	total_earned += total
	return {"coins": total, "items": item_count}


func record_purchase(offer_id: String, cost: int) -> void:
	total_spent += maxi(0, cost)
	purchase_counts[offer_id] = int(purchase_counts.get(offer_id, 0)) + 1


func pending_value() -> int:
	var total := 0
	for record: Dictionary in shipping_bin.values():
		total += int(record.get("quantity", 0)) * int(record.get("unit_price", 0))
	return total


func to_data() -> Dictionary:
	return {"shipping_bin": shipping_bin.duplicate(true), "total_earned": total_earned, "total_spent": total_spent, "purchase_counts": purchase_counts.duplicate(true), "last_shipping_total": last_shipping_total}


func load_data(data: Dictionary) -> void:
	shipping_bin = Dictionary(data.get("shipping_bin", {})).duplicate(true)
	total_earned = maxi(0, int(data.get("total_earned", 0)))
	total_spent = maxi(0, int(data.get("total_spent", 0)))
	purchase_counts = Dictionary(data.get("purchase_counts", {})).duplicate(true)
	last_shipping_total = maxi(0, int(data.get("last_shipping_total", 0)))
