## Badge "Tickets Estival" : +2 au value_sum par jeton COUPES qui score,
## peu importe le pattern.
## Trigger : on_round_start
extends BadgeEffect

const BONUS: int = 2


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	run_manager.add_family_score_bonus(TokenData.Family.COUPES, BONUS, &"tickets_estival")
