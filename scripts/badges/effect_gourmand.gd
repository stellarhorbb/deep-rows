## Badge "Gourmand" : chaque jeton ajouté au deck (achat au shop ou scission)
## cumule +2 points, appliqués à toutes les résolutions suivantes (scaling
## permanent, jamais remis à zéro sur la run). Retravaillé de +5 à +2 en
## session 23 après playtest (jugé trop fort).
## Trigger : on_deck_grown
extends BadgeEffect

const BONUS_PER_TOKEN: int = 2
const STATE_KEY: StringName = &"gourmand_tokens_added"


func apply(event: Dictionary, run_manager: RunManager) -> void:
	var added: int = event.get("count", 0) as int
	if added <= 0:
		return
	var total: int = (run_manager.get_run_badge_state(STATE_KEY, 0) as int) + added
	run_manager.set_run_badge_state(STATE_KEY, total)
	run_manager.set_flat_score_bonus(&"gourmand", total * BONUS_PER_TOKEN)


func get_progress_text(run_manager: RunManager) -> String:
	var total: int = run_manager.get_run_badge_state(STATE_KEY, 0) as int
	return "+%d points (%d jetons ajoutés)" % [total * BONUS_PER_TOKEN, total]
