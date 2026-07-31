## Sortilège "Saint Pair" : tous les jetons de valeur paire qui scorent recomptent
## leur propre valeur une deuxieme fois dans le calcul du score.
## Trigger : on_round_start
extends SpellEffect


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	for value in range(GameRules.TOKEN_MIN_VALUE, GameRules.TOKEN_MAX_VALUE + 1):
		if value % 2 == 0:
			run_manager.add_retrigger_value(value, &"saint_pair")
