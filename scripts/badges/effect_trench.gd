## Badge "Tranchee" : les 2 colonnes centrales x1.5, les 2 colonnes exterieures x0.5.
## Trigger : on_round_start
extends BadgeEffect


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	var cols: int = GameRules.COLS
	var rows: int = GameRules.ROWS
	@warning_ignore("integer_division")
	var center_left: int = cols / 2 - 1
	@warning_ignore("integer_division")
	var center_right: int = cols / 2
	var center_cols: Array[int] = [center_left, center_right]
	var outer_cols: Array[int] = [0, cols - 1]
	for c in center_cols:
		for r in range(rows):
			run_manager.add_grid_modifier(Vector2i(c, r), GameRules.MODIFIER_BOOST)
	for c in outer_cols:
		for r in range(rows):
			run_manager.add_grid_modifier(Vector2i(c, r), GameRules.MODIFIER_HALF)
