## Hover sur les jetons de la grille (session 23). Les jetons de GridVisual
## sont des Sprite2D (Node2D), qui n'ont pas de tooltip natif — ce Control
## transparent est superpose exactement sur la zone de la grille, en enfant de
## GridVisual (herite donc sa position/transform), juste pour beneficier du
## systeme de tooltip natif de Godot (_get_tooltip) sur la grille. Ne dessine
## rien, ne lit que GridManager — aucune dependance au rendu visuel des
## jetons, donc valable tel quel apres import des illustrations finales.
class_name GridHoverUI
extends Control

@export var grid_manager: GridManager
@export var cell_size: float = 90.0
@export var cell_gap: float = 6.0


func _get_tooltip(at_position: Vector2) -> String:
	var step: float = cell_size + cell_gap
	var col: int = int(at_position.x / step)
	var visual_row: int = int(at_position.y / step)
	var row: int = GameRules.ROWS - 1 - visual_row
	if col < 0 or col >= GameRules.COLS or row < 0 or row >= GameRules.ROWS:
		return ""
	var token: TokenData = grid_manager.get_cell(col, row)
	if token == null:
		return ""
	return TokenTooltip.describe(token)
