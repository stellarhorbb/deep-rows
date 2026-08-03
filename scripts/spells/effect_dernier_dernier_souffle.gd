## Sortilège "Dernier dernier Souffle" (Va-tout) : au Dernier Souffle, une
## fois le score final connu (après Souffle Obscur s'il est équipé aussi),
## mise tout le score de la manche sur un tirage à 20% : double si gagné,
## sinon tombe à 0. Comme Souffle Obscur, son effet ne passe pas par apply()
## -- TurnController._on_resolution_complete vérifie directement
## has_spell(&"dernier_dernier_souffle") au moment précis du verdict.
## Trigger : on_round_start (non utilisé, voir ci-dessus)
extends SpellEffect


func apply(_event: Dictionary, _run_manager: RunManager) -> void:
	pass
