## Badge "Cellule double" : ajoute une cellule DOUBLE aleatoire au debut de chaque manche.
## Trigger : on_round_start
extends BadgeEffect


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	var col: int = randi() % GameRules.COLS
	var row: int = randi() % GameRules.ROWS
	run_manager.add_grid_modifier(Vector2i(col, row), GameRules.MODIFIER_DOUBLE)
