## Sortilège "Quintuple Bombe" : les Bombes scorent leurs jetons avec un
## multi x5. Comme les autres Sortilèges de cette famille, son effet ne passe
## pas par apply() -- TurnController._explosive_multipliers() vérifie
## directement has_spell(&"quintuple_bombe").
## Trigger : on_round_start (non utilisé, voir ci-dessus)
extends SpellEffect


func apply(_event: Dictionary, _run_manager: RunManager) -> void:
	pass
