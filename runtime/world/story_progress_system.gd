class_name PixelRPGStoryProgressSystem
extends RefCounted


func next_available(completed_chapters: Array, flags: Dictionary) -> Dictionary:
	for arc: Dictionary in ContentRegistry.get_all("story_arcs"):
		for chapter: Dictionary in arc.get("chapters", []):
			var chapter_id := String(chapter.get("id", ""))
			if chapter_id in completed_chapters:
				continue
			var requirements_met := true
			for flag_id: String in chapter.get("required_flags", []):
				if not bool(flags.get(flag_id, false)):
					requirements_met = false
					break
			if requirements_met:
				return chapter
	return {}


func complete(chapter_id: String, completed_chapters: Array, flags: Dictionary) -> bool:
	if chapter_id.is_empty() or chapter_id in completed_chapters:
		return false
	completed_chapters.append(chapter_id)
	flags["chapter_%s" % chapter_id] = true
	return true


func requirements_met(chapter: Dictionary, metrics: Dictionary) -> Dictionary:
	var missing: PackedStringArray = []
	for condition: Dictionary in chapter.get("completion_conditions", []):
		var metric_id := String(condition.get("metric", ""))
		var threshold := int(condition.get("threshold", 1))
		var current := int(metrics.get(metric_id, 0))
		if current < threshold:
			missing.append("%s %d/%d" % [metric_id, current, threshold])
	return {"ok": missing.is_empty(), "missing": missing}
