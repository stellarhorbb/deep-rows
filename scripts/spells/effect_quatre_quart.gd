## Sortilège "Quatre quart" : chaque pattern de 4 jetons scoré cumule +5 au bonus
## flat de score, appliqué à toutes les résolutions suivantes (scaling
## permanent, jamais remis à zéro sur la run).
## Trigger : on_turn_resolved
extends SpellEffect

const BONUS_PER_MATCH: int = 1
const PATTERN_SIZE: int = 4
const STATE_KEY: StringName = &"quatre_quart_matches"


func apply(event: Dictionary, run_manager: RunManager) -> void:
	var timeline: Array = event.get("timeline", [])
	var new_matches: int = 0
	for step in timeline:
		var e: Dictionary = step as Dictionary
		if e.get("type") != CascadeResolver.EventType.MATCH:
			continue
		for group in (e.get("groups", []) as Array):
			var cells: Array = (group as Dictionary).get("cells", []) as Array
			if cells.size() == PATTERN_SIZE:
				new_matches += 1

	if new_matches == 0:
		return

	var total: int = (run_manager.get_run_spell_state(STATE_KEY, 0) as int) + new_matches
	run_manager.set_run_spell_state(STATE_KEY, total)
	run_manager.set_flat_score_bonus(&"quatre_quart", total * BONUS_PER_MATCH)


func get_progress_text(run_manager: RunManager) -> String:
	var total: int = run_manager.get_run_spell_state(STATE_KEY, 0) as int
	return "+%d points (%d patterns de 4 scorés)" % [total * BONUS_PER_MATCH, total]
