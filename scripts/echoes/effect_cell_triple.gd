## Echo "Cellule triple" : ajoute une cellule TRIPLE aleatoire au debut de chaque manche.
## Trigger : on_round_start
extends EchoEffect


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	var col: int = randi() % GameRules.COLS
	var row: int = randi() % GameRules.ROWS
	run_manager.add_grid_modifier(Vector2i(col, row), GameRules.MODIFIER_TRIPLE)
