## Badge "Cellule triple" : ajoute une cellule TRIPLE aleatoire au debut de chaque manche.
## Trigger : on_round_start
extends BadgeEffect


func apply(event: Dictionary, run_manager: RunManager) -> void:
	var holes: Dictionary = event.get("holes", {}) as Dictionary
	run_manager.add_grid_modifier(random_open_cell(holes), GameRules.MODIFIER_TRIPLE)
