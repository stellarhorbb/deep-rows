## Sortilège "Colonne chanceuse" : une colonne aleatoire entiere passe en BOOST (x1.5).
## Trigger : on_round_start
extends SpellEffect


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	var col: int = randi() % GameRules.COLS
	for row in range(GameRules.ROWS):
		run_manager.add_grid_modifier(Vector2i(col, row), GameRules.MODIFIER_BOOST)
