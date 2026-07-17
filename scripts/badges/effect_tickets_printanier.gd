## Badge "Tickets Printanier" : +2 au value_sum par jeton BATONS qui score,
## peu importe le pattern.
## Trigger : on_round_start
extends BadgeEffect

const BONUS: int = 2


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	run_manager.add_family_score_bonus(TokenData.Family.BATONS, BONUS, &"tickets_printanier")
