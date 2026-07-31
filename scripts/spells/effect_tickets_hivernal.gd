## Sortilège "Tickets Hivernal" : +2 au value_sum par jeton DENIERS qui score,
## peu importe le pattern.
## Trigger : on_round_start
extends SpellEffect

const BONUS: int = 2


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	run_manager.add_family_score_bonus(TokenData.Family.DENIERS, BONUS, &"tickets_hivernal")
