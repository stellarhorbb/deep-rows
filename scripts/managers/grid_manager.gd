class_name GridManager
extends Node

signal token_placed(col: int, row: int, token: TokenData)
signal special_landing(col: int, row: int, token: TokenData)
signal special_executed(special_type: TokenData.SpecialType, col: int, row: int, result: Dictionary)
signal resolution_complete(timeline: Array[Dictionary], total_score: int)
signal grid_reset()
signal residues_exploded(positions: Array[Vector2i])

var _grid: Array = []
var _cols: int = GameRules.COLS
var _rows: int = GameRules.ROWS
var _active_tags: Array[PatternData] = []


func init_grid() -> void:
	_grid.clear()
	for c in range(_cols):
		var column: Array = []
		column.resize(_rows)
		for r in range(_rows):
			column[r] = null
		_grid.append(column)
	grid_reset.emit()


func set_active_tags(tags: Array[PatternData]) -> void:
	_active_tags = tags


func column_height(col: int) -> int:
	for r in range(_rows - 1, -1, -1):
		if _grid[col][r] != null:
			return r + 1
	return 0


func can_play_token(token: TokenData, col: int, row: int) -> bool:
	return SpecialEffects.can_play(_grid, token, col, row, _cols, _rows)


## Place un jeton basique ou rock sur la grille.
func place_token(token: TokenData, col: int, _row: int) -> void:
	if token.kind == TokenData.Kind.BASE or token.kind == TokenData.Kind.ROCK:
		var landing_row: int = column_height(col)
		if landing_row >= _rows:
			return
		_grid[col][landing_row] = token
		token_placed.emit(col, landing_row, token)

	elif token.kind == TokenData.Kind.SPECIAL:
		# Calculer la landing row pour l'animation de chute
		var landing_row: int = _get_special_landing_row(token, col)
		special_landing.emit(col, landing_row, token)


## Execute l'effet du special APRES l'animation de chute.
## Appele par le TurnController une fois le drop anime.
func execute_special(token: TokenData, col: int) -> void:
	var result: Dictionary = {}
	match token.special_type:
		TokenData.SpecialType.FANTOME:
			SpecialEffects.execute_fantome(_grid, col, _rows)
		TokenData.SpecialType.BOMBE:
			result = SpecialEffects.execute_bombe(_grid, col, _cols, _rows)
		TokenData.SpecialType.MAREE:
			var landing_row: int = column_height(col)
			SpecialEffects.execute_maree(_grid, col, landing_row, _cols)
	special_executed.emit(token.special_type, col, 0, result)


## Lance la resolution des cascades.
func resolve() -> void:
	var resolver: CascadeResolver = CascadeResolver.new()
	var resolve_result: Dictionary = resolver.resolve(_grid, _cols, _rows, _active_tags)
	resolution_complete.emit(resolve_result["timeline"], resolve_result["total_score"])


func get_cell(col: int, row: int) -> TokenData:
	if col < 0 or col >= _cols or row < 0 or row >= _rows:
		return null
	return _grid[col][row] as TokenData


func explode_residues() -> void:
	var positions: Array[Vector2i] = []
	for c in range(_cols):
		for r in range(_rows):
			if _grid[c][r] != null and (_grid[c][r] as TokenData).kind == TokenData.Kind.RESIDUE:
				positions.append(Vector2i(c, r))
				_grid[c][r] = null
	residues_exploded.emit(positions)


func get_grid() -> Array:
	return _grid


func _get_special_landing_row(token: TokenData, col: int) -> int:
	match token.special_type:
		TokenData.SpecialType.FANTOME:
			# Le fantome cible toute la colonne, atterrit visuellement en bas
			return 0
		TokenData.SpecialType.BOMBE:
			return column_height(col)
		TokenData.SpecialType.MAREE:
			return column_height(col)
	return column_height(col)
