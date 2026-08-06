## Sortilège "Gourmand" (session 28, reprend le nom laissé libre par le
## renommage de l'ancien Gourmand en "Avidité") : chaque bouchée d'un
## spécial "mangeur" (Cavalier/Frog/Liane/Siphon, voir GridManager.
## tick_mobile_specials) cumule +2 points, appliqués à toutes les
## résolutions suivantes (scaling permanent, jamais remis à zéro sur la
## run) -- même forme qu'Avidité, juste un trigger différent.
## Trigger : on_special_ate
extends SpellEffect

const BONUS_PER_BITE: int = 2
const STATE_KEY: StringName = &"gourmand_specials_eaten"


func apply(event: Dictionary, run_manager: RunManager) -> void:
	var eaten: int = event.get("count", 0) as int
	if eaten <= 0:
		return
	var total: int = (run_manager.get_run_spell_state(STATE_KEY, 0) as int) + eaten
	run_manager.set_run_spell_state(STATE_KEY, total)
	run_manager.set_flat_score_bonus(&"gourmand", total * BONUS_PER_BITE)


func get_progress_text(run_manager: RunManager) -> String:
	var total: int = run_manager.get_run_spell_state(STATE_KEY, 0) as int
	return "+%d points (%d bouchées)" % [total * BONUS_PER_BITE, total]
