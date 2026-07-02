## Badge "Ecume" : toute la rangee du bas passe en BOOST (x1.5).
## Trigger : on_round_start
extends BadgeEffect


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	var bottom_row: int = 0  # row 0 = bas logique (destination de la gravite)
	for col in range(GameRules.COLS):
		run_manager.add_grid_modifier(Vector2i(col, bottom_row), GameRules.MODIFIER_BOOST)
