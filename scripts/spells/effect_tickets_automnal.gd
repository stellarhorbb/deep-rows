## Sortilège "Tickets Automnal" : +2 au value_sum par jeton EPEES qui score,
## peu importe le pattern.
## Trigger : on_round_start
extends SpellEffect

const BONUS: int = 2


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	run_manager.add_family_score_bonus(TokenData.Family.EPEES, BONUS, &"tickets_automnal")
