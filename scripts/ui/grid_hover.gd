## Hover sur les jetons de la grille (session 23) + sur le % de la Colonne
## Convoitée (session 27). Les jetons de GridVisual sont des Sprite2D
## (Node2D), qui n'ont pas de tooltip natif — ce Control transparent est
## superpose exactement sur la zone de la grille, en enfant de GridVisual
## (herite donc sa position/transform), juste pour beneficier du systeme de
## tooltip natif de Godot (_get_tooltip) sur la grille. Ne dessine rien.
class_name GridHoverUI
extends Control

@export var grid_manager: GridManager
@export var entity_manager: EntityManager
@export var cell_size: float = 90.0
@export var cell_gap: float = 6.0


func _get_tooltip(at_position: Vector2) -> String:
	var step: float = cell_size + cell_gap
	var col: int = int(at_position.x / step)
	var visual_row: int = int(at_position.y / step)
	var row: int = GameRules.ROWS - 1 - visual_row

	# Colonne Convoitée : le % ne se dessine que sur la case du haut (visual_
	# row == 0, voir GridVisual._draw) -- meme case ici. Priorite sur le
	# tooltip du jeton si la colonne est deja bien remplie jusque-la.
	var cursed_col: int = entity_manager.get_cursed_column()
	if cursed_col >= 0 and col == cursed_col and row == GameRules.ROWS - 1:
		return _cursed_column_tooltip()

	if col < 0 or col >= GameRules.COLS or row < 0 or row >= GameRules.ROWS:
		return ""
	var token: TokenData = grid_manager.get_cell(col, row)
	if token == null:
		return ""
	return TokenTooltip.describe(token)


## Skull = chance absolue de corruption. Bonus/Jackpot = conditionnels ("si
## ca passe") plutot qu'absolus -- voir EntityManager.get_cursed_column_
## jackpot_chance pour pourquoi (l'absolu chute vers 0 avec un risque eleve,
## donnerait l'impression fausse qu'un gros risque paie moins bien).
func _cursed_column_tooltip() -> String:
	var skull: float = entity_manager.get_cursed_column_skull_chance()
	var jackpot: float = entity_manager.get_cursed_column_jackpot_chance()
	var bonus: float = maxf(1.0 - jackpot, 0.0)
	return "COLONNE CONVOITÉE\nSkull : %d%%\nSi ça passe : %d%% bonus, %d%% jackpot" % [
		int(round(skull * 100)), int(round(bonus * 100)), int(round(jackpot * 100)),
	]
