## Badge "Sommet" : +10 au value_sum de chaque pattern qui score tant qu'un
## jeton occupe la rangee la plus haute de la grille.
## Trigger : on_round_start
extends BadgeEffect

const BONUS: int = 10


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	run_manager.add_top_row_score_bonus(BONUS, &"sommet")
