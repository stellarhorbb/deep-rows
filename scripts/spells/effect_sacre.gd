## Sortilège Legendaire "Sacre" (retravaillé session 28, retour user -- l'ancien
## mécanisme "+100% local par groupe" ne correspondait pas à l'intention :
## chaque figure qui score, dans N'IMPORTE QUELLE Partition, cumule +10% au
## facteur de scaling permanent (jamais remis à zéro, actif sur toute la run
## -- même canal que Jetons Sacrés/Cairn/Escalade Musicale/Rescapé).
## Trigger : on_turn_resolved
extends SpellEffect

const BONUS_PER_FIGURE: float = 0.1
const STATE_KEY: StringName = &"sacre_figures_scored"


func apply(event: Dictionary, run_manager: RunManager) -> void:
	var timeline: Array = event.get("timeline", [])
	var scored_figures: int = 0
	for step in timeline:
		var e: Dictionary = step as Dictionary
		if e.get("type") != CascadeResolver.EventType.MATCH:
			continue
		for group in (e.get("groups", []) as Array):
			for scored in ((group as Dictionary).get("scored_tokens", []) as Array):
				var value: int = (scored as Dictionary).get("value", -1) as int
				if GameRules.FACE_CARD_VALUES.has(value):
					scored_figures += 1
	if scored_figures <= 0:
		return

	var total: int = (run_manager.get_run_spell_state(STATE_KEY, 0) as int) + scored_figures
	run_manager.set_run_spell_state(STATE_KEY, total)
	run_manager.set_scaling_mult_bonus(&"sacre", total * BONUS_PER_FIGURE)


func get_progress_text(run_manager: RunManager) -> String:
	var total: int = run_manager.get_run_spell_state(STATE_KEY, 0) as int
	return "+%d%% mult (%d figures scorées)" % [int(round(total * BONUS_PER_FIGURE * 100)), total]
