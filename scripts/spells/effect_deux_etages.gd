## Sortilège "Deux étages" : 2 jetons persistent par colonne entre les
## manches au lieu d'1 (voir docs/gdd/manche/persistance-entre-manches.md).
## Comme les autres Sortilèges de persistance/roulette, son effet ne passe
## pas par apply() -- GameScene._on_round_won vérifie directement
## has_spell(&"deux_etages") avant de stocker le snapshot de fin de manche.
## Trigger : on_round_start (non utilisé, voir ci-dessus)
extends SpellEffect


func apply(_event: Dictionary, _run_manager: RunManager) -> void:
	pass
