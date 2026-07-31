## Sortilège "Petit Point" : chaque fois qu'un Dé à coudre apparait dans l'offre
## du shop (au plus une fois par visite, pas a chaque reroll — voir
## ShopUI._ready), cumule +2 points, appliques a toutes les resolutions
## suivantes (scaling permanent, jamais remis a zero sur la run).
## Trigger : on_deck_tool_shown
extends SpellEffect

const BONUS_PER_REVEAL: int = 2
const STATE_KEY: StringName = &"petit_point_reveals"


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	var count: int = (run_manager.get_run_spell_state(STATE_KEY, 0) as int) + 1
	run_manager.set_run_spell_state(STATE_KEY, count)
	run_manager.set_flat_score_bonus(&"petit_point", count * BONUS_PER_REVEAL)


func get_progress_text(run_manager: RunManager) -> String:
	var count: int = run_manager.get_run_spell_state(STATE_KEY, 0) as int
	return "+%d points (%d Dés à coudre vus)" % [count * BONUS_PER_REVEAL, count]
