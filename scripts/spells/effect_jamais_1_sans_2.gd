## Sortilège "Jamais 1 sans 2" : un Boost obtenu à la roulette s'applique à 2
## jetons du pool au lieu d'1 (tirages indépendants, même principe que le
## Boost normal). Comme Favoritisme/Bon départ/Fenêtre Longue, son effet ne
## passe pas par apply() -- RouletteManager._apply_boost vérifie directement
## has_spell(&"jamais_1_sans_2").
## Trigger : on_round_start (non utilisé, voir ci-dessus)
extends SpellEffect


func apply(_event: Dictionary, _run_manager: RunManager) -> void:
	pass
