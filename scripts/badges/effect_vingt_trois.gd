## Badge "Vingt-trois" : les jetons de valeur 2 et 3 qui scorent recomptent
## leur propre valeur une deuxieme fois dans le calcul du score.
## Trigger : on_round_start
extends BadgeEffect

const RETRIGGER_VALUES: Array[int] = [2, 3]


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	for value in RETRIGGER_VALUES:
		run_manager.add_retrigger_value(value, &"vingt_trois")
