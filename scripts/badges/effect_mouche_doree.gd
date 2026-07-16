## Badge "Mouche dorée" : ajoute au score de chaque Partition qui score un
## bonus de points égal au nombre de mouches actuellement possédées — lecture
## live à chaque tour, pas un compteur qui grossit tout seul (contrairement
## aux Badges scaling permanent).
## Trigger : on_turn_resolved
extends BadgeEffect


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	run_manager.set_flat_score_bonus(&"mouche_doree", run_manager.get_flies())


func get_progress_text(run_manager: RunManager) -> String:
	return "Actuellement +%d tickets (%d mouches)" % [run_manager.get_flies(), run_manager.get_flies()]
