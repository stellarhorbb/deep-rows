## Badge "Sang-froid" : ajoute au score de chaque Partition qui score un
## bonus de points egal a 5x le nombre de charges de Shake actuellement
## disponibles — lecture live a chaque tour, pas un compteur qui grossit
## tout seul (meme principe que "Mouche dorée" sur les mouches). Recompense
## de GARDER ses charges de Shake, en tension avec "Nouvelle Donne" qui
## recompense de les depenser.
## Trigger : on_turn_resolved
extends BadgeEffect

const TICKETS_PER_CHARGE: int = 5


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	run_manager.set_flat_score_bonus(&"sang_froid", run_manager.get_shake_charges() * TICKETS_PER_CHARGE)


func get_progress_text(run_manager: RunManager) -> String:
	var charges: int = run_manager.get_shake_charges()
	return "Actuellement +%d tickets (%d charges)" % [charges * TICKETS_PER_CHARGE, charges]
