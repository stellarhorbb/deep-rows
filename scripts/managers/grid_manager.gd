class_name GridManager
extends Node

signal token_placed(col: int, row: int, token: TokenData)
signal special_landing(col: int, row: int, token: TokenData)
signal special_executed(special_type: TokenData.SpecialType, col: int, row: int, result: Dictionary)
signal resolution_complete(timeline: Array[Dictionary], total_score: int)
signal grid_reset()
signal residues_exploded(positions: Array[Vector2i])
signal holes_changed(holes: Dictionary)

var _grid: Array = []
var _cols: int = GameRules.COLS
var _rows: int = GameRules.ROWS
var _run_context: RunContext = null
var _holes: Dictionary = {}  # Vector2i -> true


func init_grid() -> void:
	_grid.clear()
	for c in range(_cols):
		var column: Array = []
		column.resize(_rows)
		for r in range(_rows):
			column[r] = null
		_grid.append(column)
	_holes.clear()
	grid_reset.emit()


func set_run_context(context: RunContext) -> void:
	_run_context = context


## Row la plus basse disponible dans la colonne, en ignorant les trous
## (traverses par la gravite, jamais occupables). Retourne _rows si la
## colonne n'a plus aucune case non-trouee de libre.
func column_height(col: int) -> int:
	for r in range(_rows):
		if _holes.has(Vector2i(col, r)):
			continue
		if _grid[col][r] == null:
			return r
	return _rows


func can_play_token(token: TokenData, col: int, row: int) -> bool:
	return SpecialEffects.can_play(_grid, token, col, row, _cols, _rows, _holes)


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
			SpecialEffects.execute_fantome(_grid, col, _rows, _holes)
		TokenData.SpecialType.BOMBE:
			result = SpecialEffects.execute_bombe(_grid, col, _cols, _rows, _holes)
		TokenData.SpecialType.MAREE:
			var landing_row: int = column_height(col)
			SpecialEffects.execute_maree(_grid, col, landing_row, _cols, _holes)
	special_executed.emit(token.special_type, col, 0, result)


## Place un jeton directement dans la grille, sans pipeline de resolution ni
## signal (utilise par l'Entity). Respecte la gravite et les trous : atterrit
## sur la case non-trouee la plus basse libre de la colonne.
## Retourne la row de landing (-1 si colonne pleine ou entierement trouee).
func place_token_direct(col: int, token: TokenData) -> int:
	var row: int = column_height(col)
	if row >= _rows:
		return -1
	_grid[col][row] = token
	return row


## "Grille cabossee" : genere `count` trous a des positions aleatoires,
## jamais en row 0 (le sol reste toujours garanti dans chaque colonne).
## Un jeton qui tombe traverse un trou sans pouvoir s'y arreter — contrairement
## a un Rock, qui bloque et sert d'appui. Appele au debut de chaque manche.
func generate_random_holes(count: int) -> void:
	_holes.clear()
	var attempts: int = 0
	while _holes.size() < count and attempts < count * 20:
		attempts += 1
		var col: int = randi() % _cols
		var row: int = 1 + randi() % (_rows - 1)  # jamais row 0
		_holes[Vector2i(col, row)] = true
	holes_changed.emit(_holes.duplicate())


func get_holes() -> Dictionary:
	return _holes.duplicate()


## Lance la resolution des cascades.
func resolve() -> void:
	var resolver: CascadeResolver = CascadeResolver.new()
	var resolve_result: Dictionary = resolver.resolve(_grid, _cols, _rows, _run_context, _holes)
	resolution_complete.emit(resolve_result["timeline"], resolve_result["total_score"])


func get_cell(col: int, row: int) -> TokenData:
	if col < 0 or col >= _cols or row < 0 or row >= _rows:
		return null
	return _grid[col][row] as TokenData


## Dernier Souffle : supprime les residus ET les rocks, laisse les jetons de base en place.
## Les entity tokens survivent (ils restent obstacles).
func explode_residues() -> void:
	var positions: Array[Vector2i] = []
	for c in range(_cols):
		for r in range(_rows):
			if _grid[c][r] == null:
				continue
			var kind: TokenData.Kind = (_grid[c][r] as TokenData).kind
			if kind == TokenData.Kind.RESIDUE or kind == TokenData.Kind.ROCK:
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
