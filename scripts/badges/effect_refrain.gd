## Badge "Refrain" : chaque fois qu'une Partition score, cumule +0.1 a SON
## PROPRE multiplicateur (independant des autres Partitions equipees) —
## contrairement a "Escalade musicale" (global, declenche par level up),
## recompense de faire scorer une seule Partition favorite encore et encore
## plutot que la progression du run dans son ensemble. Permanent sur toute
## la run (voir RunManager.add_sheet_multiplier_bonus).
## Trigger : on_turn_resolved
extends BadgeEffect

const BONUS_PER_SCORE: float = 0.1
const STATE_KEY: StringName = &"refrain_sheet_counts"


func apply(event: Dictionary, run_manager: RunManager) -> void:
	var timeline: Array = event.get("timeline", [])
	var counts: Dictionary = (run_manager.get_run_badge_state(STATE_KEY, {}) as Dictionary).duplicate()
	var touched: Dictionary = {}
	for step in timeline:
		var e: Dictionary = step as Dictionary
		if e.get("type") != CascadeResolver.EventType.MATCH:
			continue
		for group in (e.get("groups", []) as Array):
			var sheet_name: StringName = (group as Dictionary).get("sheet_name", &"") as StringName
			if sheet_name == &"":
				continue
			counts[sheet_name] = (counts.get(sheet_name, 0) as int) + 1
			touched[sheet_name] = true

	if touched.is_empty():
		return

	run_manager.set_run_badge_state(STATE_KEY, counts)
	for sheet_name in touched:
		var count: int = counts[sheet_name] as int
		run_manager.add_sheet_multiplier_bonus(sheet_name as StringName, count * BONUS_PER_SCORE, &"refrain")


func get_progress_text(run_manager: RunManager) -> String:
	var counts: Dictionary = run_manager.get_run_badge_state(STATE_KEY, {}) as Dictionary
	if counts.is_empty():
		return "Aucune Partition scorée pour l'instant"
	var parts: Array[String] = []
	for sheet in run_manager.get_equipped_sheets():
		if counts.has(sheet.sheet_name):
			parts.append("%s +%.1f" % [sheet.label, (counts[sheet.sheet_name] as int) * BONUS_PER_SCORE])
	return ", ".join(parts)
