## Badge "Tickets Printanier" : +5 au value_sum quand une Partition de rule
## "family" de famille BATONS score.
## Trigger : on_round_start
extends BadgeEffect

const BONUS: int = 5


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	run_manager.add_family_score_bonus(TokenData.Family.BATONS, BONUS, &"tickets_printanier")
