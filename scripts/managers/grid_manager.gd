class_name GridManager
extends Node

signal token_placed(col: int, row: int, token: TokenData)
signal special_landing(col: int, row: int, token: TokenData)
signal special_executed(special_type: TokenData.SpecialType, col: int, row: int, result: Dictionary)
signal resolution_complete(timeline: Array[Dictionary], total_score: int)
signal grid_reset()
signal residues_exploded(positions: Array[Vector2i])
signal holes_changed(holes: Dictionary)
signal blocked_column_changed(col: int)
## Emis quand un special mobile a deplace/reorganise silencieusement des
## jetons sur la grille (voir tick_mobile_specials) — contrairement a
## Fantome/Enclume/Maree (execute_special -> special_executed), ce
## rearrangement n'a pas de point de sortie visuel dedie. Le visuel doit
## faire un rebuild complet des sprites, sync_sprites (creation/destruction
## seulement) ne suffit pas a reconcilier "cette case a maintenant un autre
## contenu" — voir GameScene._on_mobile_specials_ticked.
signal mobile_specials_ticked()

var _grid: Array = []
var _cols: int = GameRules.COLS
var _rows: int = GameRules.ROWS
var _run_context: RunContext = null
var _holes: Dictionary = {}  # Vector2i -> true

## Malus de boss COLONNE MAUDITE (voir BossMalusManager) : colonne injouable
## jusqu'au prochain drop, -1 si aucune. Re-tiree par TurnController.
var _blocked_column: int = -1


func init_grid() -> void:
	_grid.clear()
	for c in range(_cols):
		var column: Array = []
		column.resize(_rows)
		for r in range(_rows):
			column[r] = null
		_grid.append(column)
	_holes.clear()
	set_blocked_column(-1)
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
	if col == _blocked_column:
		return false
	return SpecialEffects.can_play(_grid, token, col, row, _cols, _rows, _holes)


## Voir _blocked_column (COLONNE MAUDITE).
func set_blocked_column(col: int) -> void:
	_blocked_column = col
	blocked_column_changed.emit(col)


func get_blocked_column() -> int:
	return _blocked_column


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
		TokenData.SpecialType.ENCLUME:
			SpecialEffects.execute_enclume(_grid, col, _rows, _holes)
		# A partir d'ici : speciaux qui PERSISTENT sur la grille (contrairement
		# a Fantome/Bombe/Maree/Enclume qui rearrangent puis disparaissent) —
		# se placent eux-memes au sommet de la colonne plutot que d'executer un
		# effet immediat. Voir tick_special_countdowns/tick_mobile_specials.
		TokenData.SpecialType.PETARD_A_MECHE:
			_place_persistent_special(token, col, GameRules.PETARD_A_MECHE_START_COUNTDOWN)
		TokenData.SpecialType.CAVALIER:
			_place_persistent_special(token, col, GameRules.CAVALIER_MOVES)
		TokenData.SpecialType.FROG:
			_place_persistent_special(token, col, GameRules.FROG_MOVES)
		TokenData.SpecialType.LIANE:
			_place_persistent_special(token, col, GameRules.LIANE_GROWTH_TICKS)
		TokenData.SpecialType.CROW:
			_place_persistent_special(token, col, GameRules.CROW_IDLE_TICKS)
		TokenData.SpecialType.UNDERGROUND:
			_place_persistent_special(token, col)
		TokenData.SpecialType.HYPERCUBE:
			_place_persistent_special(token, col)
	special_executed.emit(token.special_type, col, 0, result)


## Place un special "pose" au sommet de la colonne, avec un countdown initial
## optionnel (-1 = aucun, ex: Underground/Hypercube qui n'en ont pas besoin —
## leur fin est positionnelle/reactive, pas un decompte de tours).
func _place_persistent_special(token: TokenData, col: int, initial_countdown: int = -1) -> void:
	var landing_row: int = column_height(col)
	if landing_row >= _rows:
		return
	token.countdown = initial_countdown
	token.just_placed = true
	_grid[col][landing_row] = token


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


## Ajoute des trous fixes en plus de ceux deja generes (grille cabossee),
## sans effacer les existants — voir BossMalusManager (L'ÉTAU, CIEL BAS).
func add_holes(cells: Array[Vector2i]) -> void:
	for cell in cells:
		_holes[cell] = true
	holes_changed.emit(_holes.duplicate())


## Malus de boss MÈCHE COURTE (voir BossMalusManager) : decompte le countdown
## de chaque entity-skull deja sur la grille, detone ceux qui atteignent 0
## (lui et ses 2 voisins directs sur la meme rangee, sans les scorer). Ne
## regle PAS la gravite ici — appele juste avant resolve() (voir
## TurnController.play_current_to), qui s'en charge et anime la chute comme
## n'importe quelle autre cascade.
func tick_entity_countdowns() -> void:
	var detonated: Array[Vector2i] = []
	for c in range(_cols):
		for r in range(_rows):
			var token: TokenData = _grid[c][r]
			if token == null or token.kind != TokenData.Kind.ENTITY or token.countdown < 0:
				continue
			token.countdown -= 1
			if token.countdown <= 0:
				detonated.append(Vector2i(c, r))
	for cell in detonated:
		_detonate_entity_skull(cell)


func _detonate_entity_skull(cell: Vector2i) -> void:
	for dc in range(-1, 2):
		var cc: int = cell.x + dc
		if cc < 0 or cc >= _cols:
			continue
		_grid[cc][cell.y] = null


## Special "Pétard à mèche" : decompte le countdown de chaque exemplaire pose
## sur la grille, detone ceux qui atteignent 0 (voir _detonate_petard).
## Contrairement a tick_entity_countdowns (gate par le malus de boss MÈCHE
## COURTE), appele inconditionnellement a chaque tour — voir
## TurnController.play_current_to. Retourne le score total gagne.
func tick_special_countdowns() -> int:
	var to_detonate: Array[Vector2i] = []
	for c in range(_cols):
		for r in range(_rows):
			var token: TokenData = _grid[c][r]
			if token == null or token.kind != TokenData.Kind.SPECIAL:
				continue
			if token.special_type != TokenData.SpecialType.PETARD_A_MECHE or token.countdown < 0:
				continue
			if token.just_placed:
				token.just_placed = false
				continue
			token.countdown -= 1
			if token.countdown <= 0:
				to_detonate.append(Vector2i(c, r))
	var total_score: int = 0
	for cell in to_detonate:
		total_score += _detonate_petard(cell)
	return total_score


## Tick des speciaux "mobiles" (Cavalier, Frog, Liane, Crow, Underground) —
## chacun avance sa propre logique d'un cran. Cavalier/Frog/Liane sont des
## "mangeurs/scoreurs" (session 22) : atterrir/grandir sur une case occupee
## mange son contenu et score sa valeur brute, plutot que de la decaler
## (Underground/Crow restent de purs "demenageurs", aucun score). Snapshot
## des positions AVANT mutation (meme raison que tick_special_countdowns) :
## un jeton deplace pendant le scan pourrait sinon etre retraite deux fois
## dans la meme passe. Appele inconditionnellement a chaque tour, avant
## resolve() (comme tick_special_countdowns) — voir TurnController.
## play_current_to. Retourne le score total gagne.
func tick_mobile_specials() -> int:
	var cells: Array[Vector2i] = []
	for c in range(_cols):
		for r in range(_rows):
			var token: TokenData = _grid[c][r]
			if token != null and token.kind == TokenData.Kind.SPECIAL:
				cells.append(Vector2i(c, r))

	var total_score: int = 0
	for cell in cells:
		var token: TokenData = _grid[cell.x][cell.y]
		if token == null or token.kind != TokenData.Kind.SPECIAL:
			continue  # deja deplace/efface par un autre mobile plus tot dans cette passe

		if token.just_placed:
			token.just_placed = false
			continue  # pose ce tour-ci : n'agit qu'a partir du prochain jeton joue

		match token.special_type:
			TokenData.SpecialType.CAVALIER:
				var result: Dictionary = SpecialEffects.move_cavalier(_grid, cell.x, cell.y, _cols, _rows, _holes)
				var dest: Vector2i = result["dest"] as Vector2i
				if dest != cell:
					total_score += result["score"] as int
					token.countdown -= 1
					if token.countdown <= 0:
						_grid[dest.x][dest.y] = null
			TokenData.SpecialType.FROG:
				var result: Dictionary = SpecialEffects.move_frog(_grid, cell.x, cell.y, _cols, _rows, _holes)
				var dest: Vector2i = result["dest"] as Vector2i
				if dest != cell:
					total_score += result["score"] as int
					token.countdown -= 1
					if token.countdown <= 0:
						_grid[dest.x][dest.y] = null
			TokenData.SpecialType.LIANE:
				if token.countdown < 0:
					continue  # segment de corps, pas la tete : rien a piloter ici
				total_score += SpecialEffects.grow_liane(_grid, cell.x, cell.y, _cols, _rows, _holes)
				token.countdown -= 1
				if token.countdown <= 0:
					SpecialEffects.wither_liane(_grid, cell.x, cell.y, _cols)
			TokenData.SpecialType.CROW:
				if token.countdown > 0:
					token.countdown -= 1
				else:
					SpecialEffects.steal_row_token(_grid, cell.x, cell.y, _cols, _rows, _holes)
					_grid[cell.x][cell.y] = null
			TokenData.SpecialType.UNDERGROUND:
				SpecialEffects.dig_underground(_grid, cell.x, cell.y, _rows, _holes)

	if cells.size() > 0:
		mobile_specials_ticked.emit()
	return total_score


## Dernier Souffle : les jetons speciaux poses explosent (decision verrouillee,
## voir CLAUDE.md) — un Pétard à mèche encore actif detone immediatement,
## countdown ou pas, en miroir de explode_residues pour les Rocks/Residus
## (voir TurnController._trigger_last_breath). Retourne le score gagne.
func detonate_remaining_petards() -> int:
	var to_detonate: Array[Vector2i] = []
	for c in range(_cols):
		for r in range(_rows):
			var token: TokenData = _grid[c][r]
			if token != null and token.kind == TokenData.Kind.SPECIAL and token.special_type == TokenData.SpecialType.PETARD_A_MECHE:
				to_detonate.append(Vector2i(c, r))
	var total_score: int = 0
	for cell in to_detonate:
		total_score += _detonate_petard(cell)
	return total_score


## Dernier Souffle : les speciaux mobiles/reactifs encore actifs (Cavalier,
## Frog, Liane, Crow, Underground, Hypercube) disparaissent silencieusement —
## pas de scoring, contrairement au Pétard à mèche qui explose (voir
## detonate_remaining_petards). Traite a part d'explode_residues pour ne pas
## les confondre avec les Rocks/Residus.
func clear_remaining_mobile_specials() -> void:
	var types: Array = [
		TokenData.SpecialType.CAVALIER, TokenData.SpecialType.FROG,
		TokenData.SpecialType.LIANE, TokenData.SpecialType.CROW,
		TokenData.SpecialType.UNDERGROUND, TokenData.SpecialType.HYPERCUBE,
	]
	for c in range(_cols):
		for r in range(_rows):
			var token: TokenData = _grid[c][r]
			if token != null and token.kind == TokenData.Kind.SPECIAL and types.has(token.special_type):
				_grid[c][r] = null


## Detone un Pétard à mèche : lui + ses 2 voisins directs sur la meme rangee
## disparaissent, les voisins SCORABLES sont scores (leur valeur brute, sans
## multiplicateur — meme logique que la Bombe, un special reste hors de la
## chaine de multiplicateurs des Partitions). Contrairement a
## _detonate_entity_skull (MÈCHE COURTE), qui ne score jamais ses voisins.
func _detonate_petard(cell: Vector2i) -> int:
	var score: int = 0
	for dc in range(-1, 2):
		var cc: int = cell.x + dc
		if cc < 0 or cc >= _cols:
			continue
		if dc != 0:
			var neighbor: TokenData = _grid[cc][cell.y]
			if neighbor != null and neighbor.is_scorable():
				score += neighbor.value
		_grid[cc][cell.y] = null
	return score


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


## Compte les Rocks actuellement sur la grille (ex: badge "Cairn", qui lit ce
## total en fin de manche boss avant que le Dernier Souffle ne les fasse
## disparaitre — voir explode_residues).
func count_rocks() -> int:
	var count: int = 0
	for c in range(_cols):
		for r in range(_rows):
			var token: TokenData = _grid[c][r]
			if token != null and token.kind == TokenData.Kind.ROCK:
				count += 1
	return count


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
