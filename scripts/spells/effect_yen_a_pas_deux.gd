## Sortilège "Y'en a pas deux" : +5 au value_sum quand le groupe qui score
## contient au moins deux jetons de meme valeur (une paire).
## Trigger : on_round_start
extends SpellEffect

const BONUS: int = 5


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	run_manager.add_pair_score_bonus(BONUS, &"yen_a_pas_deux")
