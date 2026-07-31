## Sortilège "Récif vivant" : quand une Partition score, un jeton aléatoire parmi
## ceux qui viennent de scorer laisse place à un rock au lieu de disparaître.
## Trigger : on_round_start
extends SpellEffect


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	run_manager.add_rock_leaving_spell(&"recif_vivant")
