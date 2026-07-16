## Badge "Ecume" : une rangee aleatoire passe en BOOST (x1.5) chaque manche.
## Etait fixe sur la rangee du bas (row 0) — trop fiable puisque la gravite
## y garde toujours des jetons en permanence (session 18, retune equilibrage).
## Trigger : on_round_start
extends BadgeEffect


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	var row: int = randi() % GameRules.ROWS
	for col in range(GameRules.COLS):
		run_manager.add_grid_modifier(Vector2i(col, row), GameRules.MODIFIER_BOOST)
