## Badge "Tickets Estival" : +5 au value_sum quand une Partition de rule
## "family" de famille COUPES score.
## Trigger : on_round_start
extends BadgeEffect

const BONUS: int = 5


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	run_manager.add_family_score_bonus(TokenData.Family.COUPES, BONUS, &"tickets_estival")
