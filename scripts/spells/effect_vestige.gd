## Sortilège "Vestige" : chaque jeton persisté (voir persistance entre
## manches) pose une cellule BOOST x1.5 à l'endroit où il atterrit. Comme les
## autres Sortilèges de persistance, son effet ne passe pas par apply() --
## GameScene._play_carryover_intro vérifie directement has_spell(&"vestige")
## au moment où chaque jeton persisté retombe sur la grille.
## Trigger : on_round_start (non utilisé, voir ci-dessus)
extends SpellEffect


func apply(_event: Dictionary, _run_manager: RunManager) -> void:
	pass
