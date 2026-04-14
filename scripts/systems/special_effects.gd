class_name SpecialEffects

## Verifie si un jeton peut etre joue a la position donnee.
static func can_play(grid: Array, token: TokenData, col: int, _row: int, cols: int, rows: int) -> bool:
	if col < 0 or col >= cols:
		return false

	if token.kind == TokenData.Kind.BASE or token.kind == TokenData.Kind.ROCK:
		return _column_height(grid, col, rows) < rows

	if token.kind == TokenData.Kind.SPECIAL:
		match token.special_type:
			TokenData.SpecialType.FANTOME:
				return true  # peut cibler une colonne pleine
			TokenData.SpecialType.BOMBE:
				return _column_height(grid, col, rows) < rows
			TokenData.SpecialType.MAREE:
				return _column_height(grid, col, rows) < rows

	return false


## Fantome : pousse la colonne vers le haut, place un residu en row 0.
static func execute_fantome(grid: Array, col: int, rows: int) -> void:
	# Collecter les jetons existants de la colonne
	var col_tokens: Array[TokenData] = []
	for r in range(rows):
		if grid[col][r] != null:
			col_tokens.append(grid[col][r] as TokenData)

	# Drop le top si la colonne est pleine
	if col_tokens.size() >= rows:
		col_tokens.pop_back()

	# Vider la colonne
	for r in range(rows):
		grid[col][r] = null

	# Placer le residu en row 0
	grid[col][0] = TokenData.make_residue()

	# Re-placer les jetons existants shiftes de +1
	for i in range(col_tokens.size()):
		grid[col][i + 1] = col_tokens[i]


## Bombe : atterrit en haut de colonne, detruit 3x3 autour. Pas de score, juste deblayage.
## Retourne { "score": int, "destroyed": Array[Vector2i] }
static func execute_bombe(grid: Array, col: int, cols: int, rows: int) -> Dictionary:
	var landing_row: int = _column_height(grid, col, rows)
	if landing_row >= rows:
		return { "score": 0, "destroyed": [] as Array[Vector2i] }

	var destroyed: Array[Vector2i] = []

	for dc in range(-1, 2):
		for dr in range(-1, 2):
			var cc: int = col + dc
			var rr: int = landing_row + dr
			if cc < 0 or cc >= cols or rr < 0 or rr >= rows:
				continue
			if grid[cc][rr] == null:
				continue
			destroyed.append(Vector2i(cc, rr))
			grid[cc][rr] = null

	return { "score": 0, "destroyed": destroyed }


## Maree : vague qui ecarte la ligne autour du point d'impact.
## La cellule cliquee reste. Gauche shift a gauche (col 0 detruite), droite shift a droite (derniere col detruite).
static func execute_maree(grid: Array, col: int, row: int, cols: int) -> void:
	# Sauvegarder la ligne
	var row_tokens: Array = []
	for c in range(cols):
		row_tokens.append(grid[c][row])

	# Construire la nouvelle ligne
	var new_row: Array = []
	new_row.resize(cols)
	for i in range(cols):
		new_row[i] = null

	# La cellule cliquee reste en place
	new_row[col] = row_tokens[col]

	# Moitie gauche : cols 0..col-2 prennent de cols 1..col-1
	for c in range(0, col - 1):
		new_row[c] = row_tokens[c + 1]

	# Moitie droite : cols col+2..end prennent de cols col+1..end-1
	for c in range(col + 2, cols):
		new_row[c] = row_tokens[c - 1]

	# Appliquer
	for c in range(cols):
		grid[c][row] = new_row[c]


## Hauteur d'une colonne (nombre de jetons depuis le bas).
static func _column_height(grid: Array, col: int, rows: int) -> int:
	for r in range(rows - 1, -1, -1):
		if grid[col][r] != null:
			return r + 1
	return 0
