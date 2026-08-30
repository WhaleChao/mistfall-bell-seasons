class_name PixelRPGCookingSystem
extends RefCounted


func can_cook(recipe_id: StringName, pantry: Dictionary) -> bool:
	var recipe := ContentRegistry.get_artifact("recipes", recipe_id)
	if recipe.is_empty():
		return false
	for ingredient_id: String in Dictionary(recipe.get("ingredients", {})):
		if int(pantry.get(ingredient_id, 0)) < int(recipe.ingredients[ingredient_id]):
			return false
	return true


func cook(recipe_id: StringName, pantry: Dictionary) -> Dictionary:
	var recipe := ContentRegistry.get_artifact("recipes", recipe_id)
	if recipe.is_empty() or not can_cook(recipe_id, pantry):
		return {"ok": false, "message": "食材不足或料理不存在"}
	for ingredient_id: String in Dictionary(recipe.get("ingredients", {})):
		pantry[ingredient_id] = int(pantry.get(ingredient_id, 0)) - int(recipe.ingredients[ingredient_id])
	pantry[String(recipe_id)] = int(pantry.get(String(recipe_id), 0)) + 1
	return {"ok": true, "recipe_id": String(recipe_id), "energy": int(recipe.get("energy", 0)), "message": "完成%s" % recipe.get("display_name", recipe_id)}
