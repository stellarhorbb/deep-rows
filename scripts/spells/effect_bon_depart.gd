## Sortilège "Bon départ" : la jauge de roulette démarre déjà remplie à
## GameRules.ROULETTE_HEAD_START_GAUGE en début de manche au lieu de 0.
## Comme Favoritisme/Économe, son effet ne passe pas par apply() --
## RouletteManager.bind_round vérifie directement has_spell(&"bon_depart").
## Trigger : on_round_start (non utilisé, voir ci-dessus)
extends SpellEffect


func apply(_event: Dictionary, _run_manager: RunManager) -> void:
	pass
