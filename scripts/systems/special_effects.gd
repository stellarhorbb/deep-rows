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
			TokenData.SpecialType.ENCLUME:
				return _column_height(grid, col, rows, holes) < rows
			TokenData.SpecialType.PETARD_A_MECHE:
				return _column_height(grid, col, rows, holes) < rows
			TokenData.SpecialType.CAVALIER:
				return _column_height(grid, col, rows, holes) < rows
			TokenData.SpecialType.FROG:
				return _column_height(grid, col, rows, holes) < rows
			TokenData.SpecialType.LIANE:
				return _column_height(grid, col, rows, holes) < rows
			TokenData.SpecialType.CROW:
				return _column_height(grid, col, rows, holes) < rows
			TokenData.SpecialType.UNDERGROUND:
				return _column_height(grid, col, rows, holes) < rows
			TokenData.SpecialType.HYPERCUBE:
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


## Enclume : pousse le premier jeton sur lequel elle tombe (le sommet actuel
## de la colonne) tout au fond de la grille — le reste de la colonne se
## decale d'un cran pour combler l'espace libere. Meme structure que
## execute_fantome (liste des cases utiles, en ignorant les trous), mais une
## rotation plutot qu'un residu + decalage. Colonne vide ou a 1 seul jeton :
## rien a pousser, no-op.
static func execute_enclume(grid: Array, col: int, rows: int, holes: Dictionary = {}) -> void:
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
	if col_tokens.size() <= 1:
		return

	var top_token: TokenData = col_tokens.pop_back()
	col_tokens.insert(0, top_token)

	for r in usable_rows:
		grid[col][r] = null
	for i in range(col_tokens.size()):
		grid[col][usable_rows[i]] = col_tokens[i]


## Mange le contenu d'une case pour un special "mangeur/scoreur" (Cavalier,
## Frog, Liane) : un jeton scorable present y est retire et sa valeur brute
## (sans multiplicateur — meme convention que la Bombe/le Pétard) est
## retournee comme score. Un jeton non scorable (Rock, Special, Entity) est
## quand meme retire (nettoyage de la case), mais ne rapporte rien. Case
## vide : rien a manger, retourne 0.
static func _eat_cell(grid: Array, cell: Vector2i) -> int:
	var token: TokenData = grid[cell.x][cell.y] as TokenData
	if token == null:
		return 0
	var score: int = token.value if token.is_scorable() else 0
	grid[cell.x][cell.y] = null
	return score


## Cavalier : deplacement d'echecs en L (8 destinations possibles), tire au
## hasard parmi celles valides (dans la grille, hors trous). Case occupee :
## mange son contenu (voir _eat_cell) au lieu de le decaler. Retourne
## {"dest": Vector2i, "score": int} — dest = (col, row) inchange si aucune
## destination n'est valide (rarissime, seulement si les 8 sont hors grille
## ou trouees) ; l'appelant (GridManager.tick_mobile_specials) ne consomme un
## des deplacements restants que si la position a reellement change.
static func move_cavalier(grid: Array, col: int, row: int, cols: int, rows: int, holes: Dictionary = {}) -> Dictionary:
	var deltas: Array[Vector2i] = [
		Vector2i(1, 2), Vector2i(1, -2), Vector2i(-1, 2), Vector2i(-1, -2),
		Vector2i(2, 1), Vector2i(2, -1), Vector2i(-2, 1), Vector2i(-2, -1),
	]
	var candidates: Array[Vector2i] = []
	for delta in deltas:
		var c: Vector2i = Vector2i(col + delta.x, row + delta.y)
		if c.x < 0 or c.x >= cols or c.y < 0 or c.y >= rows:
			continue
		if holes.has(c):
			continue
		candidates.append(c)
	if candidates.is_empty():
		return {"dest": Vector2i(col, row), "score": 0}
	var dest: Vector2i = candidates[randi() % candidates.size()]
	var score: int = _eat_cell(grid, dest)
	var token: TokenData = grid[col][row] as TokenData
	grid[col][row] = null
	grid[dest.x][dest.y] = token
	return {"dest": dest, "score": score}


## Frog : saute en diagonale haut-gauche ou haut-droite, tiree au hasard.
## Meme regle de case occupee (mange, voir _eat_cell) et de retour dest
## inchange si aucune des deux n'est valide (bord/trou).
static func move_frog(grid: Array, col: int, row: int, cols: int, rows: int, holes: Dictionary = {}) -> Dictionary:
	var deltas: Array[Vector2i] = [Vector2i(-1, 1), Vector2i(1, 1)]
	var candidates: Array[Vector2i] = []
	for delta in deltas:
		var c: Vector2i = Vector2i(col + delta.x, row + delta.y)
		if c.x < 0 or c.x >= cols or c.y < 0 or c.y >= rows:
			continue
		if holes.has(c):
			continue
		candidates.append(c)
	if candidates.is_empty():
		return {"dest": Vector2i(col, row), "score": 0}
	var dest: Vector2i = candidates[randi() % candidates.size()]
	var score: int = _eat_cell(grid, dest)
	var token: TokenData = grid[col][row] as TokenData
	grid[col][row] = null
	grid[dest.x][dest.y] = token
	return {"dest": dest, "score": score}


## Liane : fait grandir la vigne d'un cran vers la droite, a partir de la
## case la plus a droite d'un segment LIANE contigu commencant a (col, row)
## sur la meme rangee. Case occupee : mange son contenu (voir _eat_cell) au
## lieu de le decaler. Retourne le score gagne (0 si rien mange, aussi 0 si
## bloquee par le bord de la grille ou une case trouee — le minuteur continue
## quand meme de descendre cote appelant, voir GridManager.
## tick_mobile_specials).
static func grow_liane(grid: Array, col: int, row: int, cols: int, _rows: int, holes: Dictionary = {}) -> int:
	var tip_col: int = col
	while tip_col + 1 < cols:
		var next_token: TokenData = grid[tip_col + 1][row] as TokenData
		if next_token != null and next_token.kind == TokenData.Kind.SPECIAL and next_token.special_type == TokenData.SpecialType.LIANE:
			tip_col += 1
		else:
			break
	if tip_col + 1 >= cols:
		return 0
	var new_col: int = tip_col + 1
	if holes.has(Vector2i(new_col, row)):
		return 0
	var score: int = _eat_cell(grid, Vector2i(new_col, row))
	grid[new_col][row] = TokenData.make_special(TokenData.SpecialType.LIANE)
	return score


## Fane et efface toute la vigne contigue (tete + segments) a partir de
## (col, row), en scannant vers la droite jusqu'a une case qui n'est plus
## un segment LIANE.
static func wither_liane(grid: Array, col: int, row: int, cols: int) -> void:
	var c: int = col
	while c < cols:
		var token: TokenData = grid[c][row] as TokenData
		if token == null or token.kind != TokenData.Kind.SPECIAL or token.special_type != TokenData.SpecialType.LIANE:
			break
		grid[c][row] = null
		c += 1


## Crow : vole un jeton scorable au hasard sur sa ligne (hors sa propre
## case) et le redepose — drop normal au sommet de sa colonne (column_height),
## sans le scorer : Crow est un "demenageur", pas un "mangeur" (contrairement
## a Cavalier/Frog/Liane, voir _eat_cell). Rien a voler sur la ligne : ne
## fait rien. Le Crow lui-meme est efface par l'appelant juste apres, qu'il
## y ait eu un vol ou non (voir GridManager.tick_mobile_specials).
static func steal_row_token(grid: Array, crow_col: int, crow_row: int, cols: int, rows: int, holes: Dictionary = {}) -> void:
	var candidates: Array[int] = []
	for c in range(cols):
		if c == crow_col:
			continue
		var token: TokenData = grid[c][crow_row] as TokenData
		if token != null and token.is_scorable():
			candidates.append(c)
	if candidates.is_empty():
		return
	var source_col: int = candidates[randi() % candidates.size()]
	var stolen: TokenData = grid[source_col][crow_row] as TokenData
	grid[source_col][crow_row] = null
	var landing_row: int = _column_height(grid, crow_col, rows, holes)
	if landing_row < rows:
		grid[crow_col][landing_row] = stolen
	# Sinon (colonne du Crow deja pleine) : le jeton vole est perdu, cas
	# limite non specifie — coherent avec "redepose" qui suppose une place.


## Underground : creuse d'un cran vers le bas — echange sa position avec la
## case UTILE juste en dessous (trous ignores, comme la gravite normale).
## Une fois la case utile la plus basse de la colonne atteinte, il y reste
## visible un tour (un vrai "atterrissage"), puis disparait au tick suivant
## ("disparait apres avoir touche le bas") — gere sa propre suppression,
## contrairement aux autres mobiles.
## `never_expire` (Legendaire "Dresseur Fou", session 23) : au fond, reste en
## place indefiniment au lieu de disparaitre — devient un obstacle inerte
## permanent plutot qu'un vrai mobile eternel (Underground n'a pas de
## countdown a geler comme les autres, sa fin est positionnelle, pas un
## compteur — voir GridManager.tick_mobile_specials).
static func dig_underground(grid: Array, col: int, row: int, rows: int, holes: Dictionary = {}, never_expire: bool = false) -> void:
	var usable_rows: Array[int] = []
	for r in range(rows):
		if not holes.has(Vector2i(col, r)):
			usable_rows.append(r)
	var index: int = usable_rows.find(row)
	if index <= 0:
		# Deja au fond utile depuis le tick precedent (il y a "atterri" et y
		# est reste visible un tour, voir doc plus haut) : disparait maintenant.
		if not never_expire:
			grid[col][row] = null
		return

	var below_row: int = usable_rows[index - 1]
	var token: TokenData = grid[col][row] as TokenData
	var below_token: TokenData = grid[col][below_row]
	grid[col][below_row] = token
	grid[col][row] = below_token


## Hauteur d'une colonne (nombre de jetons depuis le bas), en ignorant les
## trous (voir GridManager.column_height, meme logique).
static func _column_height(grid: Array, col: int, rows: int, holes: Dictionary = {}) -> int:
	for r in range(rows):
		if holes.has(Vector2i(col, r)):
			continue
		if grid[col][r] == null:
			return r
	return rows
