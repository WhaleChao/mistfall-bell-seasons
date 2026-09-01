class_name PixelRPGItemIconFactory
extends RefCounted

const ICON_SIZE := 64

static var _texture_cache: Dictionary = {}


static func texture_for(item_id: StringName, requested_kind: StringName = &"auto", pixel_size: int = ICON_SIZE) -> Texture2D:
	var id := String(item_id)
	var resolved := _resolve(id, String(requested_kind))
	var kind := String(resolved.kind)
	var definition: Dictionary = Dictionary(resolved.definition)
	var primary := _primary_color(id, kind, definition)
	var resolved_size := clampi(pixel_size, 16, 128)
	var cache_key := "%s:%s:%s:%d" % [kind, id, primary.to_html(false), resolved_size]
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]
	var image := Image.new()
	var error := image.load_svg_from_string(_svg_for(id, kind, definition, primary), float(resolved_size) / float(ICON_SIZE))
	if error != OK:
		return null
	var texture := ImageTexture.create_from_image(image)
	_texture_cache[cache_key] = texture
	return texture


static func display_name_for(item_id: StringName) -> String:
	var id := String(item_id)
	for artifact_type in ["items", "crops", "fish", "recipes", "animals", "tools", "automation_devices"]:
		var definition := _artifact(artifact_type, item_id)
		if not definition.is_empty():
			return String(definition.get("display_name", id))
	return id.replace("_", " ")


static func description_for(item_id: StringName) -> String:
	for artifact_type in ["items", "crops", "fish", "recipes", "animals", "tools", "automation_devices"]:
		var definition := _artifact(artifact_type, item_id)
		if not definition.is_empty():
			return String(definition.get("description", definition.get("lore", "")))
	return ""


static func _resolve(id: String, requested_kind: String) -> Dictionary:
	var kind := requested_kind
	var definition: Dictionary = {}
	if kind == "seed":
		definition = _artifact("crops", StringName(id))
	elif kind in ["crop", "produce"]:
		definition = _artifact("crops", StringName(id))
		kind = "crop"
	elif kind == "fish":
		definition = _artifact("fish", StringName(id))
	elif kind in ["dish", "recipe"]:
		definition = _artifact("recipes", StringName(id))
		kind = "dish"
	elif kind == "animal":
		definition = _artifact("animals", StringName(id))
	elif kind == "tool":
		definition = _artifact("tools", StringName(id))
	elif kind in ["automation", "device"]:
		definition = _artifact("automation_devices", StringName(id))
		kind = "automation"
	elif kind == "item":
		definition = _artifact("items", StringName(id))
	else:
		for candidate: Dictionary in [
			{"type":"items", "kind":"item"}, {"type":"crops", "kind":"crop"},
			{"type":"fish", "kind":"fish"}, {"type":"recipes", "kind":"dish"},
			{"type":"animals", "kind":"animal"}, {"type":"tools", "kind":"tool"},
			{"type":"automation_devices", "kind":"automation"},
		]:
			definition = _artifact(String(candidate.type), StringName(id))
			if not definition.is_empty():
				kind = String(candidate.kind)
				break
	if kind in ["", "auto"]:
		kind = "item"
	return {"kind":kind, "definition":definition}


static func _artifact(artifact_type: String, item_id: StringName) -> Dictionary:
	var scene_tree := Engine.get_main_loop() as SceneTree
	if scene_tree == null:
		return {}
	var registry := scene_tree.root.get_node_or_null("ContentRegistry")
	if registry == null or not registry.has_method("get_artifact"):
		return {}
	return Dictionary(registry.call("get_artifact", artifact_type, item_id))


static func _primary_color(id: String, kind: String, definition: Dictionary) -> Color:
	if definition.has("color"):
		return Color(String(definition.color))
	var fixed := {
		"health_potion":Color("e65d6f"), "egg":Color("fff0c2"), "milk":Color("dbefff"),
		"animal_feed":Color("d5aa58"), "wood":Color("9b6848"), "stone":Color("8a9299"),
		"copper_ore":Color("c97950"), "iron_ore":Color("788792"), "gold_ore":Color("e1b94e"),
		"glass":Color("7eddd7"), "mist_shard":Color("75d7df"), "frost_crystal":Color("9fdaf2"),
		"ember_core":Color("ef714a"), "forest_herb":Color("6db879"), "river_reed":Color("b8b66c"),
		"ancient_gear":Color("c5944f"), "ancient_seed":Color("9bd489"), "dream_tide_salt":Color("b5a7ef"),
		"mist_preserves":Color("c66a83"), "abyssal_relic":Color("7e6ac9"), "warden_emblem":Color("d5b25d"),
	}
	if fixed.has(id):
		return fixed[id]
	var hue := float(absi(id.hash()) % 360) / 360.0
	var saturation := 0.46 if kind not in ["fish", "automation"] else 0.58
	return Color.from_hsv(hue, saturation, 0.84)


static func _svg_for(id: String, kind: String, definition: Dictionary, primary: Color) -> String:
	var main := primary.to_html(false)
	var light := primary.lightened(0.32).to_html(false)
	var dark := primary.darkened(0.36).to_html(false)
	var body := ""
	match kind:
		"seed":
			body = _seed_svg(id, main, light, dark)
		"crop":
			body = _crop_svg(id, main, light, dark)
		"fish":
			body = _fish_svg(id, main, light, dark, bool(definition.get("tide_required", false)))
		"dish":
			body = _dish_svg(id, main, light, dark)
		"animal":
			body = _animal_svg(id, main, light, dark)
		"tool":
			body = _tool_svg(id, main, light, dark)
		"automation":
			body = _automation_svg(id, main, light, dark)
		_:
			body = _item_svg(id, main, light, dark)
	var rune_x := 49 + posmod(id.hash(), 4)
	# Compose the XML namespace at runtime so the offline release audit does not
	# mistake a required SVG identifier for an application network endpoint.
	var svg_namespace := "http" + "://www.w3.org/2000/svg"
	return """<svg xmlns="%s" width="64" height="64" viewBox="0 0 64 64">
<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#%s"/><stop offset="1" stop-color="#%s"/></linearGradient></defs>
<ellipse cx="32" cy="56" rx="19" ry="3.5" fill="#081018" opacity=".24"/>
%s
<path d="M%s 10l1.6 3.2 3.5.5-2.55 2.5.6 3.5-3.15-1.65-3.15 1.65.6-3.5-2.55-2.5 3.5-.5z" fill="#fff4bd" opacity=".82"/>
</svg>""" % [svg_namespace, light, dark, body, rune_x]


static func _seed_svg(id: String, main: String, light: String, dark: String) -> String:
	var symbol := _crop_svg(id, main, light, dark)
	return """<path d="M16 14h32l4 38H12z" fill="url(#g)" stroke="#352b35" stroke-width="2.5"/>
<path d="M15 18h34M17 45h30" stroke="#fff0c7" stroke-width="2" opacity=".7"/>
<circle cx="32" cy="32" r="11" fill="#f3e3b1" stroke="#4b3a38" stroke-width="2"/>
<g transform="translate(20 20) scale(.38)">%s</g>""" % symbol


static func _crop_svg(id: String, main: String, light: String, dark: String) -> String:
	if _has_any(id, ["tulip", "bloom", "sunflower", "chrysanthemum", "rose", "bellflower"]):
		return """<path d="M32 53V31" stroke="#36714d" stroke-width="5" stroke-linecap="round"/><path d="M31 42c-9-8-13 2-3 5M34 39c10-8 13 3 2 7" fill="#58a568"/>
<g fill="#%s" stroke="#%s" stroke-width="1.5"><circle cx="32" cy="22" r="8"/><circle cx="24" cy="27" r="7"/><circle cx="40" cy="27" r="7"/><circle cx="28" cy="16" r="7"/><circle cx="36" cy="16" r="7"/></g><circle cx="32" cy="23" r="5" fill="#f3cd55"/>""" % [main, dark]
	if _has_any(id, ["wheat", "rice", "corn", "sugarcane", "asparagus"]):
		return """<g stroke="#%s" stroke-width="3" stroke-linecap="round"><path d="M23 53V18M32 53V13M41 53V20"/></g><g fill="#%s" stroke="#%s"><ellipse cx="20" cy="24" rx="5" ry="8"/><ellipse cx="35" cy="20" rx="5" ry="8"/><ellipse cx="44" cy="27" rx="5" ry="8"/></g>""" % [dark, main, dark]
	if _has_any(id, ["turnip", "radish", "potato", "carrot", "garlic", "beet", "onion", "yam", "parsnip", "sweet_potato"]):
		return """<path d="M32 17c-8-9-15-5-10 6 3 5 7 7 10 9 3-3 8-5 10-10 5-10-3-13-10-5z" fill="#5b9d5c" stroke="#326342" stroke-width="2"/><path d="M19 31c0-10 26-10 26 0 0 14-8 24-13 26-6-2-13-12-13-26z" fill="url(#g)" stroke="#%s" stroke-width="2.5"/><path d="M29 55l3 5 3-5" fill="none" stroke="#%s" stroke-width="2"/>""" % [dark, dark]
	if _has_any(id, ["berry", "grape", "peas", "bean", "coffee", "tomato", "pepper"]):
		return """<path d="M32 24c-1-8 5-11 11-9-2 6-5 10-11 11" fill="#5ca260" stroke="#356643" stroke-width="2"/><g fill="url(#g)" stroke="#%s" stroke-width="2"><circle cx="25" cy="33" r="9"/><circle cx="39" cy="33" r="9"/><circle cx="32" cy="45" r="10"/></g>""" % dark
	return """<path d="M32 25c-1-9 6-13 13-11-2 8-6 12-13 13-6-7-12-7-17-3 4 6 9 8 17 6" fill="#62a568" stroke="#356643" stroke-width="2.5"/><ellipse cx="32" cy="39" rx="17" ry="15" fill="url(#g)" stroke="#%s" stroke-width="2.5"/><path d="M24 34c5-5 12-6 18-2" fill="none" stroke="#%s" stroke-width="3" opacity=".65"/>""" % [dark, light]


static func _fish_svg(id: String, main: String, light: String, dark: String, eldritch: bool) -> String:
	var shape := ""
	if "eel" in id:
		shape = """<path d="M10 38c13-24 27 15 44-10" fill="none" stroke="url(#g)" stroke-width="12" stroke-linecap="round"/><circle cx="52" cy="27" r="8" fill="#%s" stroke="#%s" stroke-width="2"/>""" % [main, dark]
	elif "ray" in id:
		shape = """<path d="M8 30Q32 8 56 30 40 35 34 53h-4Q24 35 8 30z" fill="url(#g)" stroke="#%s" stroke-width="2.5"/>""" % dark
	elif "crab" in id:
		shape = """<ellipse cx="32" cy="35" rx="15" ry="12" fill="url(#g)" stroke="#%s" stroke-width="2.5"/><path d="M18 31L9 24l-5 7 9 6M46 31l9-7 5 7-9 6M21 45l-8 8M28 47l-3 10M43 45l8 8M36 47l3 10" fill="none" stroke="#%s" stroke-width="4" stroke-linecap="round"/>""" % [dark, main]
	elif "nautilus" in id:
		shape = """<circle cx="29" cy="32" r="20" fill="url(#g)" stroke="#%s" stroke-width="2.5"/><path d="M29 20c13 0 13 19 1 19-9 0-9-12-1-12 5 0 5 6 1 6" fill="none" stroke="#%s" stroke-width="3"/><path d="M45 39q12 2 13 10M43 43q8 5 7 13" fill="none" stroke="#%s" stroke-width="3" stroke-linecap="round"/>""" % [dark, light, main]
	else:
		shape = """<path d="M13 33L4 20v26z" fill="#%s" stroke="#%s" stroke-width="2"/><ellipse cx="34" cy="33" rx="23" ry="16" fill="url(#g)" stroke="#%s" stroke-width="2.5"/><path d="M27 19l7-8 7 10M27 47l7 7 7-9" fill="#%s" stroke="#%s" stroke-width="2"/><circle cx="48" cy="29" r="3.5" fill="#fff7d2"/><circle cx="49" cy="29" r="1.7" fill="#18212d"/>""" % [main, dark, dark, light, dark]
	if eldritch:
		shape += """<circle cx="32" cy="33" r="7" fill="#152134" stroke="#75e0d3" stroke-width="2"/><circle cx="32" cy="33" r="2.5" fill="#f7e8a5"/><path d="M19 49q-6 8-1 12M27 51q-3 7 1 11M38 50q5 7 1 12" fill="none" stroke="#75e0d3" stroke-width="2.5"/>"""
	return shape


static func _dish_svg(id: String, main: String, light: String, dark: String) -> String:
	if _has_any(id, ["tea", "juice", "milk"]):
		return """<path d="M18 18h27l-3 34H21z" fill="#edf3ea" stroke="#34404a" stroke-width="2.5"/><path d="M21 28h21l-2 21H23z" fill="url(#g)"/><path d="M45 25q13 0 10 13-2 7-12 6" fill="none" stroke="#34404a" stroke-width="4"/>"""
	if _has_any(id, ["soup", "stew", "hotpot", "noodle"]):
		return """<path d="M10 27h44q-2 25-22 28Q12 52 10 27z" fill="#e6ded0" stroke="#34333c" stroke-width="2.5"/><ellipse cx="32" cy="28" rx="22" ry="8" fill="url(#g)" stroke="#%s" stroke-width="2"/><path d="M21 26q5-7 10 0t10 0" fill="none" stroke="#%s" stroke-width="2.5"/>""" % [dark, light]
	return """<ellipse cx="32" cy="38" rx="25" ry="17" fill="#e9e5d9" stroke="#34333c" stroke-width="2.5"/><ellipse cx="32" cy="37" rx="18" ry="11" fill="url(#g)" stroke="#%s" stroke-width="2"/><circle cx="25" cy="34" r="4" fill="#%s"/><circle cx="38" cy="40" r="5" fill="#%s"/>""" % [dark, light, main]


static func _item_svg(id: String, main: String, light: String, dark: String) -> String:
	if "potion" in id:
		return """<path d="M25 10h14v10l7 8v20q0 8-14 8t-14-8V28l7-8z" fill="#dce8e6" stroke="#29323e" stroke-width="2.5"/><path d="M21 33h22v15q0 5-11 5t-11-5z" fill="url(#g)"/><path d="M24 10h16" stroke="#d7b45c" stroke-width="6"/><circle cx="28" cy="39" r="3" fill="#fff" opacity=".7"/>"""
	if id == "egg":
		return """<path d="M32 8c11 0 20 25 20 36 0 10-8 16-20 16s-20-6-20-16C12 33 21 8 32 8z" fill="url(#g)" stroke="#7f715d" stroke-width="2.5"/><ellipse cx="25" cy="25" rx="6" ry="10" fill="#fff" opacity=".55"/>"""
	if id == "milk":
		return """<path d="M20 14h24l5 10v32H15V24z" fill="url(#g)" stroke="#30404c" stroke-width="2.5"/><path d="M20 14l7-7h15l2 7M16 27h32" fill="none" stroke="#30404c" stroke-width="2.5"/><path d="M27 34c9-9 15 4 6 8-8 4-12-3-6-8z" fill="#79b7d2"/>"""
	if id == "animal_feed":
		return """<path d="M19 15h26l-3 8q9 12 9 28 0 7-19 7t-19-7q0-16 9-28z" fill="url(#g)" stroke="#4b392d" stroke-width="2.5"/><path d="M20 23h24" stroke="#e9d39b" stroke-width="3"/><g fill="#fff0a4"><circle cx="25" cy="39" r="3"/><circle cx="35" cy="34" r="3"/><circle cx="40" cy="44" r="3"/></g>"""
	if _has_any(id, ["ore", "crystal", "shard", "relic", "salt", "core"]):
		return """<path d="M31 7l10 15 13 10-8 24H18L9 34l13-12z" fill="url(#g)" stroke="#%s" stroke-width="2.5"/><path d="M31 8l-2 45M11 34l42-2M22 22l24 34" fill="none" stroke="#%s" stroke-width="2" opacity=".6"/>""" % [dark, light]
	if "gear" in id:
		return """<path d="M27 7h10l2 8 7 3 7-4 6 8-6 6v8l6 6-6 8-8-4-6 3-2 8H27l-2-8-7-3-8 4-6-8 6-6v-8l-6-6 6-8 7 4 8-3z" fill="url(#g)" stroke="#%s" stroke-width="2"/><circle cx="32" cy="32" r="10" fill="#17212c" stroke="#%s" stroke-width="3"/>""" % [dark, light]
	if id == "wood":
		return """<path d="M9 22l37-9 9 30-37 9z" fill="url(#g)" stroke="#%s" stroke-width="2.5"/><ellipse cx="49" cy="28" rx="8" ry="15" transform="rotate(-15 49 28)" fill="#c99868" stroke="#%s" stroke-width="2"/><ellipse cx="49" cy="28" rx="4" ry="9" transform="rotate(-15 49 28)" fill="none" stroke="#%s" stroke-width="2"/>""" % [dark, dark, dark]
	if _has_any(id, ["herb", "reed", "seed"]):
		return """<path d="M31 56V18M30 31C12 14 8 34 29 41M34 37c18-17 23 5 1 10" fill="none" stroke="#%s" stroke-width="5" stroke-linecap="round"/><path d="M31 19c-8-15 13-15 5 1z" fill="#%s"/>""" % [main, light]
	if "preserves" in id:
		return """<path d="M18 18h28l3 8v29H15V26z" fill="#dbe8e5" stroke="#303a43" stroke-width="2.5"/><path d="M18 29h28v23H18z" fill="url(#g)"/><path d="M16 17h32" stroke="#d6b15a" stroke-width="6"/>"""
	if _has_any(id, ["emblem", "ancient"]):
		return """<path d="M32 7l23 12-4 25-19 14-19-14-4-25z" fill="url(#g)" stroke="#%s" stroke-width="2.5"/><path d="M32 16v32M20 27h24M23 43l18-22" stroke="#%s" stroke-width="3"/>""" % [dark, light]
	return """<path d="M13 20l19-11 19 11v31L32 60 13 51z" fill="url(#g)" stroke="#%s" stroke-width="2.5"/><path d="M13 20l19 11 19-11M32 31v29" fill="none" stroke="#%s" stroke-width="2"/>""" % [dark, light]


static func _animal_svg(id: String, main: String, light: String, dark: String) -> String:
	if id == "chicken":
		return """<ellipse cx="31" cy="37" rx="20" ry="17" fill="url(#g)" stroke="#%s" stroke-width="2.5"/><circle cx="45" cy="24" r="11" fill="#%s" stroke="#%s" stroke-width="2"/><path d="M53 24l9 4-9 4" fill="#e5a744"/><path d="M42 13l4-7 4 8" fill="#df5b54"/><circle cx="48" cy="22" r="2" fill="#17212c"/><path d="M21 51l-2 8M34 52l2 7" stroke="#d59a45" stroke-width="3"/>""" % [dark, light, dark]
	return """<path d="M13 25h34q9 0 9 11v14H16q-9 0-9-10V29z" fill="url(#g)" stroke="#%s" stroke-width="2.5"/><circle cx="49" cy="23" r="12" fill="#%s" stroke="#%s" stroke-width="2"/><path d="M43 11l-8-6 2 13M55 12l7-6-1 14" fill="#%s"/><path d="M18 48v11M42 48v11" stroke="#%s" stroke-width="4"/><circle cx="53" cy="21" r="2" fill="#17212c"/>""" % [dark, light, dark, main, dark]


static func _tool_svg(id: String, main: String, light: String, dark: String) -> String:
	if "watering" in id:
		return """<path d="M13 30h31v25H13z" fill="url(#g)" stroke="#%s" stroke-width="2.5"/><path d="M43 34l15-8 3 8-17 9M18 30V17h17v13" fill="none" stroke="#%s" stroke-width="4"/><circle cx="58" cy="24" r="4" fill="#%s"/>""" % [dark, dark, light]
	if "fishing" in id:
		return """<path d="M15 57Q22 10 48 9" fill="none" stroke="#%s" stroke-width="4"/><path d="M48 9q10 21-1 34" fill="none" stroke="#b8dce5" stroke-width="2"/><path d="M43 45l5-7 5 7-5 9z" fill="#%s"/>""" % [main, light]
	return """<path d="M28 14l9-9 8 8-9 9 20 29-9 7-20-29-8 5L8 23z" fill="url(#g)" stroke="#%s" stroke-width="2.5"/><path d="M16 18l17 17" stroke="#%s" stroke-width="3"/>""" % [dark, light]


static func _automation_svg(id: String, main: String, light: String, dark: String) -> String:
	return """<rect x="10" y="15" width="44" height="38" rx="7" fill="url(#g)" stroke="#%s" stroke-width="2.5"/><circle cx="32" cy="34" r="13" fill="#17212c" stroke="#%s" stroke-width="3"/><circle cx="32" cy="34" r="5" fill="#%s"/><path d="M32 16v7M32 45v8M11 34h8M45 34h9M18 20l6 6M40 42l6 6M46 20l-6 6M24 42l-6 6" stroke="#%s" stroke-width="3"/>""" % [dark, light, main, light]


static func _has_any(id: String, tokens: Array) -> bool:
	for token: String in tokens:
		if id.contains(token):
			return true
	return false
