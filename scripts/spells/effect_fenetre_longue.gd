## Sortilège "Fenêtre Longue" : la fenêtre de délai pour profiter d'un
## Multiplicateur de roulette passe de GameRules.ROULETTE_MULTI_DROPS (3) à
## GameRules.ROULETTE_MULTI_DROPS_EXTENDED (5). Comme Favoritisme/Bon départ,
## son effet ne passe pas par apply() -- RouletteManager._on_turn_resolved
## vérifie directement has_spell(&"fenetre_longue").
## Trigger : on_round_start (non utilisé, voir ci-dessus)
extends SpellEffect


func apply(_event: Dictionary, _run_manager: RunManager) -> void:
	pass
