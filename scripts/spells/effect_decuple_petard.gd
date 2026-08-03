## Sortilège "Décuple Pétard" : les Pétards à mèche scorent leurs jetons avec
## un multi x10. Comme les autres Sortilèges de cette famille, son effet ne
## passe pas par apply() -- TurnController._explosive_multipliers()
## vérifie directement has_spell(&"decuple_petard").
## Trigger : on_round_start (non utilisé, voir ci-dessus)
extends SpellEffect


func apply(_event: Dictionary, _run_manager: RunManager) -> void:
	pass
