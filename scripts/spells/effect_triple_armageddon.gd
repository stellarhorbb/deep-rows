## Sortilège "Triple Armageddon" : les Armageddon scorent leurs jetons avec
## un multi x3. Comme les autres Sortilèges de cette famille, son effet ne
## passe pas par apply() -- TurnController._explosive_multipliers() vérifie
## directement has_spell(&"triple_armageddon").
## Trigger : on_round_start (non utilisé, voir ci-dessus)
extends SpellEffect


func apply(_event: Dictionary, _run_manager: RunManager) -> void:
	pass
