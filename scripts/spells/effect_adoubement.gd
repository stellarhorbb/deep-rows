## Sortilège "Adoubement" : chaque promotion de figure (Valet+1, Chevalier+2,
## Dame+3, Roi+4 — voir GameRules.FACE_CARD_VALUES) cumule ce montant en
## points, appliques a toutes les resolutions suivantes (scaling permanent,
## jamais remis a zero sur la run).
## Trigger : on_figure_promoted
extends SpellEffect

const STATE_KEY: StringName = &"adoubement_points"


func apply(event: Dictionary, run_manager: RunManager) -> void:
	var new_value: int = event.get("new_value", -1) as int
	var rank: int = GameRules.FACE_CARD_VALUES.find(new_value)
	if rank < 0:
		return
	var bonus: int = rank + 1
	var total: int = (run_manager.get_run_spell_state(STATE_KEY, 0) as int) + bonus
	run_manager.set_run_spell_state(STATE_KEY, total)
	run_manager.set_flat_score_bonus(&"adoubement", total)


func get_progress_text(run_manager: RunManager) -> String:
	var total: int = run_manager.get_run_spell_state(STATE_KEY, 0) as int
	return "+%d points cumulés" % total
