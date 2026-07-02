class_name SpecialEffects

## Verifie si un jeton peut etre joue a la position donnee.
static func can_play(grid: Array, token: TokenData, col: int, _row: int, cols: int, rows: int, holes: Dictionary = {}) -> bool:
	if col < 0 or col >= cols:
		return false

	if token.kind == TokenData.Kind.BASE or token.kind == TokenData.Kind.ROCK:
		return _column_height(grid, col, rows, holes) < rows

	if token.kind == TokenData.Kind.SPECIAL:
		match token.special_type:
			TokenData.SpecialType.FANTOME:
				return true  # peut cibler une colonne pleine
			TokenData.SpecialType.BOMBE:
				return _column_height(grid, col, rows, holes) < rows
			TokenData.SpecialType.MAREE:
				return _column_height(grid, col, rows, holes) < rows

	return false


## Fantome : pousse la colonne vers le haut, place un residu sur la case
## utile la plus basse. Les cases trouees de la colonne ne participent jamais
## (jamais videes en jetons, jamais reoccupees) — row 0 est toujours utile,
## les trous ne sont jamais generes dessus.
static func execute_fantome(grid: Array, col: int, rows: int, holes: Dictionary = {}) -> void:
	var usable_rows: Array[int] = []
	for r in range(rows):
		if not holes.has(Vector2i(col, r)):
			usable_rows.append(r)
	if usable_rows.is_empty():
		return

	var col_tokens: Array[TokenData] = []
	for r in usable_rows:
		if grid[col][r] != null:
			col_tokens.append(grid[col][r] as TokenData)

	# Drop le top si la colonne (utile) est pleine
	if col_tokens.size() >= usable_rows.size():
		col_tokens.pop_back()

	# Vider les cases utiles de la colonne
	for r in usable_rows:
		grid[col][r] = null

	# Placer le residu sur la case utile la plus basse
	grid[col][usable_rows[0]] = TokenData.make_residue()

	# Re-placer les jetons existants shiftes de +1, sur les cases utiles suivantes
	for i in range(col_tokens.size()):
		if i + 1 >= usable_rows.size():
			break
		grid[col][usable_rows[i + 1]] = col_tokens[i]


## Bombe : atterrit en haut de colonne, detruit 3x3 autour. Pas de score, juste deblayage.
## Retourne { "score": int, "destroyed": Array[Vector2i] }
static func execute_bombe(grid: Array, col: int, cols: int, rows: int, holes: Dictionary = {}) -> Dictionary:
	var landing_row: int = _column_height(grid, col, rows, holes)
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
## Les cases trouees de la ligne ne recoivent jamais de jeton (le contenu qui
## atterrirait dessus est simplement perdu dans le trou).
static func execute_maree(grid: Array, col: int, row: int, cols: int, holes: Dictionary = {}) -> void:
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

	# Appliquer (sauf sur les cases trouees, toujours laissees vides)
	for c in range(cols):
		if holes.has(Vector2i(c, row)):
			continue
		grid[c][row] = new_row[c]


## Hauteur d'une colonne (nombre de jetons depuis le bas), en ignorant les
## trous (voir GridManager.column_height, meme logique).
static func _column_height(grid: Array, col: int, rows: int, holes: Dictionary = {}) -> int:
	for r in range(rows):
		if holes.has(Vector2i(col, r)):
			continue
		if grid[col][r] == null:
			return r
	return rows
