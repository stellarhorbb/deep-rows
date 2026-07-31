## Sortilège "Refrain" : chaque fois qu'une Partition score, cumule +1 point,
## compte independant par Sheet (recompense de faire scorer une seule
## Partition favorite encore et encore) mais applique comme bonus flat
## global (`set_flat_score_bonus`, meme canal que Brocante/Nouvelle Donne)
## plutot que comme multiplicateur — anciennement +0.1 au multi propre de
## la Sheet, retravaille en session 23 apres playtest (spam d'une seule
## Partition faisait exploser le multi).
## Permanent sur toute la run.
## Trigger : on_turn_resolved
extends SpellEffect

const BONUS_PER_SCORE: int = 1
const STATE_KEY: StringName = &"refrain_sheet_counts"


func apply(event: Dictionary, run_manager: RunManager) -> void:
	var timeline: Array = event.get("timeline", [])
	var counts: Dictionary = (run_manager.get_run_spell_state(STATE_KEY, {}) as Dictionary).duplicate()
	var touched: bool = false
	for step in timeline:
		var e: Dictionary = step as Dictionary
		if e.get("type") != CascadeResolver.EventType.MATCH:
			continue
		for group in (e.get("groups", []) as Array):
			var sheet_name: StringName = (group as Dictionary).get("sheet_name", &"") as StringName
			if sheet_name == &"":
				continue
			counts[sheet_name] = (counts.get(sheet_name, 0) as int) + 1
			touched = true

	if not touched:
		return

	run_manager.set_run_spell_state(STATE_KEY, counts)
	var total: int = 0
	for sheet_name in counts:
		total += counts[sheet_name] as int
	run_manager.set_flat_score_bonus(&"refrain", total * BONUS_PER_SCORE)


func get_progress_text(run_manager: RunManager) -> String:
	var counts: Dictionary = run_manager.get_run_spell_state(STATE_KEY, {}) as Dictionary
	if counts.is_empty():
		return "Aucune Partition scorée pour l'instant"
	var parts: Array[String] = []
	for sheet in run_manager.get_equipped_sheets():
		if counts.has(sheet.sheet_name):
			parts.append("%s +%d" % [sheet.label, (counts[sheet.sheet_name] as int) * BONUS_PER_SCORE])
	return ", ".join(parts)
