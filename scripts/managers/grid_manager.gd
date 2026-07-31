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
## Cases mystere (session 24) : visibles-mais-inconnues (voir _mystery_cells)
## jusqu'a declenchement. Emis avec les positions ENCORE CACHEES uniquement
## (juste les cles, jamais l'effet lui-meme) — le visuel dessine un marqueur
## "?" dessus, rien de plus. Une case qui se declenche disparait de ce dict.
signal mystery_cells_changed(pending_cells: Array[Vector2i])
## Emis quand un jeton/rock/special atterrit sur une case mystere non encore
## revelee — TurnController applique l'effet reel (score/mouches/trou/
## famille/teleport/multi), voir _on_mystery_cell_triggered. `token` est le
## jeton qui vient de declencher, pour les effets qui le concernent
## directement (FAMILY_SHUFFLE, TELEPORT).
signal mystery_cell_triggered(col: int, row: int, effect: MysteryCellEffects.Type, token: TokenData)
## Emis quand un special mobile a deplace/reorganise silencieusement des
## jetons sur la grille (voir tick_mobile_specials) — contrairement a
## Fantome/Enclume/Maree (execute_special -> special_executed), ce
## rearrangement n'a pas de point de sortie visuel dedie. Le visuel doit
## faire un rebuild complet des sprites, sync_sprites (creation/destruction
## seulement) ne suffit pas a reconcilier "cette case a maintenant un autre
## contenu" — voir GameScene._on_mobile_specials_ticked.
signal mobile_specials_ticked()
## Emis quand un explosif de la famille Petard/Bombe/Armageddon detone (voir
## tick_special_countdowns / detonate_remaining_explosives, session 25) —
## meme raison que mobile_specials_ticked : _detonate_explosive vide
## directement les cases touchees dans _grid, sans passer par un event de
## CascadeResolver, donc rien ne previent le visuel qu'il doit retirer les
## sprites. Voir GameScene._on_petard_detonated. Nom du signal garde tel quel
## (herite de l'epoque ou seul Petard existait) pour eviter de re-cabler
## tous les points d'ecoute pour un renommage cosmetique.
signal petard_detonated()
## Legendaire "Souffle Obscur" (session 23) : emis quand la deuxieme vague du
## Dernier Souffle vide les entity-skulls (voir clear_entity_skulls) — meme
## pattern que residues_exploded, pour que le visuel sache reconstruire les
## sprites avant de relancer la resolution. Voir GameScene._on_entity_skulls_
## cleared / TurnController._trigger_second_wave.
signal entity_skulls_cleared(positions: Array[Vector2i])

var _grid: Array = []
var _cols: int = GameRules.COLS
var _rows: int = GameRules.ROWS
var _run_context: RunContext = null
var _holes: Dictionary = {}  # Vector2i -> true

## Cases mystere : contenu cache jusqu'a declenchement (Vector2i -> Type),
## jamais expose tel quel a l'UI — voir mystery_cells_changed, qui n'envoie
## que les positions encore cachees.
var _mystery_cells: Dictionary = {}

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
	_mystery_cells.clear()
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
		_check_mystery_trigger(col, landing_row, token)

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
		TokenData.SpecialType.MAREE:
			var landing_row: int = column_height(col)
			SpecialEffects.execute_maree(_grid, col, landing_row, _cols, _holes)
		TokenData.SpecialType.ENCLUME:
			SpecialEffects.execute_enclume(_grid, col, _rows, _holes)
		# A partir d'ici : speciaux qui PERSISTENT sur la grille (contrairement
		# a Fantome/Maree/Enclume qui rearrangent puis disparaissent) —
		# se placent eux-memes au sommet de la colonne plutot que d'executer un
		# effet immediat. Voir tick_special_countdowns/tick_mobile_specials.
		# Famille des explosifs a retardement (Petard/Bombe/Armageddon,
		# session 25 — Bombe etait instantanee avant, voir _explosive_offsets) :
		# countdown croissant avec la taille de la zone d'impact.
		TokenData.SpecialType.PETARD_A_MECHE:
			_place_persistent_special(token, col, GameRules.PETARD_A_MECHE_START_COUNTDOWN)
		TokenData.SpecialType.BOMBE:
			_place_persistent_special(token, col, GameRules.BOMBE_START_COUNTDOWN)
		TokenData.SpecialType.ARMAGEDDON:
			_place_persistent_special(token, col, GameRules.ARMAGEDDON_START_COUNTDOWN)
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
	_check_mystery_trigger(col, landing_row, token)


## Place un jeton directement dans la grille, sans pipeline de resolution ni
## signal (utilise par l'Entity). Respecte la gravite et les trous : atterrit
## sur la case non-trouee la plus basse libre de la colonne.
## Retourne la row de landing (-1 si colonne pleine ou entierement trouee).
func place_token_direct(col: int, token: TokenData) -> int:
	var row: int = column_height(col)
	if row >= _rows:
		return -1
	_grid[col][row] = token
	_check_mystery_trigger(col, row, token)
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


## Cases mystere (session 24) : genere `count` cases a des positions
## aleatoires, jamais sur un trou (jamais atterrissable de toute facon).
## Appele au debut de chaque manche, sur une grille encore vide — meme
## timing que generate_random_holes. Le contenu (MysteryCellEffects.Type)
## est tire tout de suite mais reste cache jusqu'a declenchement, voir
## _check_mystery_trigger.
func generate_random_mystery_cells(count: int) -> void:
	_mystery_cells.clear()
	var attempts: int = 0
	while _mystery_cells.size() < count and attempts < count * 20:
		attempts += 1
		var cell: Vector2i = Vector2i(randi() % _cols, randi() % _rows)
		if _holes.has(cell) or _mystery_cells.has(cell):
			continue
		_mystery_cells[cell] = MysteryCellEffects.pick_random()
	_notify_mystery_cells_changed()


func get_pending_mystery_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell in _mystery_cells:
		cells.append(cell as Vector2i)
	return cells


func _notify_mystery_cells_changed() -> void:
	mystery_cells_changed.emit(get_pending_mystery_cells())


## Revele et declenche l'effet d'une case mystere si `cell` en porte une,
## appele juste apres qu'un jeton/rock/special y ait atterri (voir
## place_token/_place_persistent_special). Ne fait rien si la case n'a pas
## de mystere ou a deja ete revelee.
func _check_mystery_trigger(col: int, row: int, token: TokenData) -> void:
	var cell: Vector2i = Vector2i(col, row)
	if not _mystery_cells.has(cell):
		return
	var effect: MysteryCellEffects.Type = _mystery_cells[cell] as MysteryCellEffects.Type
	_mystery_cells.erase(cell)
	_notify_mystery_cells_changed()
	mystery_cell_triggered.emit(col, row, effect, token)


## Effet HOLE_ADD (voir MysteryCellEffects) : ajoute un trou sur une case
## actuellement vide, ni trou ni mystere. Ne fait rien si aucune case libre
## (grille pleine) — pas de fallback force.
func add_random_hole() -> void:
	var candidates: Array[Vector2i] = []
	for c in range(_cols):
		for r in range(_rows):
			var cell: Vector2i = Vector2i(c, r)
			if _holes.has(cell) or _mystery_cells.has(cell) or _grid[c][r] != null:
				continue
			candidates.append(cell)
	if candidates.is_empty():
		return
	add_holes([candidates.pick_random()])


## Effet HOLE_REMOVE (voir MysteryCellEffects) : comble un trou existant
## choisi au hasard. Ne fait rien si aucun trou sur la grille.
func remove_random_hole() -> void:
	if _holes.is_empty():
		return
	var cell: Vector2i = (_holes.keys() as Array).pick_random() as Vector2i
	_holes.erase(cell)
	holes_changed.emit(_holes.duplicate())


## Effet FAMILY_SHUFFLE (voir MysteryCellEffects) : mute la famille du jeton
## qui a declenche la case, uniquement s'il est scorable (BASE) — un Rock ou
## un Special n'a pas de famille pertinente, l'effet est alors simplement
## perdu plutot que de forcer un resultat sans le jeton d'origine.
func randomize_token_family(col: int, row: int) -> void:
	var token: TokenData = get_cell(col, row)
	if token == null or token.kind != TokenData.Kind.BASE:
		return
	var choices: Array[TokenData.Family] = []
	for f in TokenData.Family.values():
		if f != token.family:
			choices.append(f as TokenData.Family)
	token.family = choices.pick_random()


## Effet TELEPORT (voir MysteryCellEffects) : deplace le jeton qui a
## declenche la case vers une colonne aleatoire, retasse la colonne
## d'origine (GravitySystem) pour combler le vide laisse. Scope a BASE/ROCK
## (voir randomize_token_family pour le meme raisonnement) — un Special
## mobile/pose garde une logique de position trop specifique pour etre
## deplace sans risque ici. Retourne la colonne de destination, -1 si aucune
## colonne n'avait de place libre (jeton laisse sur place).
func move_token_to_random_column(from_col: int, from_row: int) -> int:
	var token: TokenData = get_cell(from_col, from_row)
	if token == null or (token.kind != TokenData.Kind.BASE and token.kind != TokenData.Kind.ROCK):
		return -1

	# Verifie qu'une colonne de destination a de la place AVANT de toucher a
	# quoi que ce soit — sinon le retrait + la compaction de la colonne
	# d'origine (juste apres) rendrait tout rollback ambigu (une case peut
	# avoir ete comblee entre-temps par un jeton tombe d'au-dessus).
	var order: Array = range(_cols)
	order.shuffle()
	var dest_col: int = -1
	for c in order:
		if column_height(c) < _rows:
			dest_col = c
			break
	if dest_col == -1:
		return -1

	_grid[from_col][from_row] = null
	GravitySystem.apply(_grid, _cols, _rows, _holes)
	var landing_row: int = column_height(dest_col)
	_grid[dest_col][landing_row] = token
	return dest_col


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


## Membres de la famille des explosifs a retardement (session 25) — voir
## _explosive_offsets pour la forme de chacun.
const _EXPLOSIVE_TYPES: Array[TokenData.SpecialType] = [
	TokenData.SpecialType.PETARD_A_MECHE, TokenData.SpecialType.BOMBE, TokenData.SpecialType.ARMAGEDDON,
]


## Offsets relatifs a la case d'impact pour un membre de la famille des
## explosifs. Petard = 2 cases (gauche/droite) + sa propre case (effacee mais
## jamais scorable, c'est un Special) ; Bombe = croix de 4 (haut/bas/gauche/
## droite) ; Armageddon = carre 3x3 complet (8 voisins), l'ancienne forme de
## Bombe avant qu'elle ne soit nerfee. Fonction plutot qu'un const Dictionary
## de Array[Vector2i] : un Array stocke comme valeur de Dictionary perd son
## typage element-par-element, et le caster ensuite via `as Array[Vector2i]`
## plante au runtime des qu'on le passe a une fonction qui exige ce type
## strict (voir _detonate_explosive) -- un retour direct depuis une fonction
## typee, lui, coerce correctement le literal.
func _explosive_offsets(special_type: TokenData.SpecialType) -> Array[Vector2i]:
	match special_type:
		TokenData.SpecialType.PETARD_A_MECHE:
			return [Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0)]
		TokenData.SpecialType.BOMBE:
			return [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
		TokenData.SpecialType.ARMAGEDDON:
			return [
				Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
				Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0),
				Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
			]
		_:
			return []


## Famille des explosifs a retardement (Petard à mèche/Bombe/Armageddon,
## session 25) : decompte le countdown de chaque exemplaire pose sur la
## grille, detone ceux qui atteignent 0 (voir _detonate_explosive).
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
			if not _EXPLOSIVE_TYPES.has(token.special_type) or token.countdown < 0:
				continue
			if token.just_placed:
				token.just_placed = false
				continue
			token.countdown -= 1
			if token.countdown <= 0:
				to_detonate.append(Vector2i(c, r))
	var total_score: int = 0
	for cell in to_detonate:
		var special_type: TokenData.SpecialType = (_grid[cell.x][cell.y] as TokenData).special_type
		total_score += _detonate_explosive(cell, _explosive_offsets(special_type))
	if to_detonate.size() > 0:
		petard_detonated.emit()
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

		# Legendaire "Dresseur Fou" (session 23) : Cavalier/Frog/Liane/Underground
		# ne disparaissent plus jamais — countdown gele plutot qu'infini pour ne
		# pas toucher SpecialEffects (Crow exclu, voir spell_dresseur_fou.tres :
		# il s'autodetruit apres une action unique, pas de countdown a geler).
		var never_expire: bool = _run_context != null and _run_context.mobiles_never_expire

		match token.special_type:
			TokenData.SpecialType.CAVALIER:
				var result: Dictionary = SpecialEffects.move_cavalier(_grid, cell.x, cell.y, _cols, _rows, _holes)
				var dest: Vector2i = result["dest"] as Vector2i
				if dest != cell:
					total_score += result["score"] as int
					if not never_expire:
						# Disparait des la premiere bouchee (session 25, retour
						# playtest) plutot que d'attendre la fin du countdown --
						# rester imprevisible sur la grille plusieurs tours de
						# plus apres avoir deja mange rendait le special trop
						# long a lire. Le countdown reste le filet de securite
						# si aucune bouchee n'a lieu (voir SpecialEffects.
						# move_cavalier).
						if result["ate"] as bool:
							_grid[dest.x][dest.y] = null
						else:
							token.countdown -= 1
							if token.countdown <= 0:
								_grid[dest.x][dest.y] = null
			TokenData.SpecialType.FROG:
				var result: Dictionary = SpecialEffects.move_frog(_grid, cell.x, cell.y, _cols, _rows, _holes)
				var dest: Vector2i = result["dest"] as Vector2i
				if dest != cell:
					total_score += result["score"] as int
					if not never_expire:
						# Meme retune que Cavalier ci-dessus.
						if result["ate"] as bool:
							_grid[dest.x][dest.y] = null
						else:
							token.countdown -= 1
							if token.countdown <= 0:
								_grid[dest.x][dest.y] = null
			TokenData.SpecialType.LIANE:
				if token.countdown < 0:
					continue  # segment de corps, pas la tete : rien a piloter ici
				total_score += SpecialEffects.grow_liane(_grid, cell.x, cell.y, _cols, _rows, _holes)
				if not never_expire:
					token.countdown -= 1
					if token.countdown <= 0:
						SpecialEffects.wither_liane(_grid, cell.x, cell.y, _cols)
			TokenData.SpecialType.CROW:
				if token.countdown > 0:
					token.countdown -= 1
				else:
					SpecialEffects.steal_row_token(_grid, cell.x, cell.y, _rows, _holes)
					_grid[cell.x][cell.y] = null
			TokenData.SpecialType.UNDERGROUND:
				SpecialEffects.dig_underground(_grid, cell.x, cell.y, _rows, _holes, never_expire)

	if cells.size() > 0:
		mobile_specials_ticked.emit()
	return total_score


## Dernier Souffle : les jetons speciaux poses explosent (decision verrouillee,
## voir CLAUDE.md) — toute la famille Petard/Bombe/Armageddon encore active
## detone immediatement, countdown ou pas, en miroir de explode_residues pour
## les Rocks/Residus (voir TurnController._trigger_last_breath). Retourne le
## score gagne.
func detonate_remaining_explosives() -> int:
	var to_detonate: Array[Vector2i] = []
	for c in range(_cols):
		for r in range(_rows):
			var token: TokenData = _grid[c][r]
			if token != null and token.kind == TokenData.Kind.SPECIAL and _EXPLOSIVE_TYPES.has(token.special_type):
				to_detonate.append(Vector2i(c, r))
	var total_score: int = 0
	for cell in to_detonate:
		var special_type: TokenData.SpecialType = (_grid[cell.x][cell.y] as TokenData).special_type
		total_score += _detonate_explosive(cell, _explosive_offsets(special_type))
	if to_detonate.size() > 0:
		petard_detonated.emit()
	return total_score


## Dernier Souffle : les speciaux mobiles/reactifs encore actifs (Cavalier,
## Frog, Liane, Crow, Underground, Hypercube) disparaissent silencieusement —
## pas de scoring, contrairement a la famille Petard/Bombe/Armageddon qui
## explose (voir detonate_remaining_explosives). Traite a part
## d'explode_residues pour ne pas les confondre avec les Rocks/Residus.
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


## Detone un explosif de la famille Petard/Bombe/Armageddon (session 25) :
## toutes les cases couvertes par `offsets` (voir _explosive_offsets)
## disparaissent, celles qui sont SCORABLES sont scorees (leur valeur brute,
## sans multiplicateur — un special reste hors de la chaine de multiplicateurs
## des Partitions, y compris sa propre case). Contrairement a
## _detonate_entity_skull (MÈCHE COURTE), qui ne score jamais ses voisins.
func _detonate_explosive(cell: Vector2i, offsets: Array[Vector2i]) -> int:
	var score: int = 0
	for offset in offsets:
		var cc: int = cell.x + offset.x
		var rr: int = cell.y + offset.y
		if cc < 0 or cc >= _cols or rr < 0 or rr >= _rows:
			continue
		var token: TokenData = _grid[cc][rr]
		if token != null and token.is_scorable():
			score += token.value
		_grid[cc][rr] = null
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


## Choisit un jeton de BASE au hasard sur la grille et augmente sa valeur de
## `amount`, plafonnee a GameRules.MAX_BUTTON_VALUE -- jamais retire/deplace,
## zero risque pour un pattern en cours de construction (voir RouletteManager,
## remplace Frog session 25). Exclut les jetons deja a MAX_BUTTON_VALUE (10)
## ou au-dela (Figures, Valet+) -- retune session 25 : un Boost qui tombe sur
## un jeton deja plafonne ne fait rien de visible, gaspillage frustrant pour
## le joueur. Retourne la cellule touchee, ou Vector2i(-1,-1) si aucun jeton
## de base boostable n'est present sur la grille.
func boost_random_token(amount: int) -> Vector2i:
	var candidates: Array[Vector2i] = []
	for c in range(_cols):
		for r in range(_rows):
			var token: TokenData = _grid[c][r]
			if token != null and token.kind == TokenData.Kind.BASE and token.value < GameRules.MAX_BUTTON_VALUE:
				candidates.append(Vector2i(c, r))
	if candidates.is_empty():
		return Vector2i(-1, -1)
	var cell: Vector2i = candidates.pick_random()
	var token: TokenData = _grid[cell.x][cell.y]
	token.value = mini(token.value + amount, GameRules.MAX_BUTTON_VALUE)
	return cell


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


## Legendaire "Souffle Obscur" : deuxieme vague du Dernier Souffle (voir
## TurnController._trigger_second_wave) — les entity-skulls, seul obstacle
## normalement permanent du jeu (ils survivent a explode_residues ci-dessus),
## disparaissent a leur tour. Meme structure que explode_residues.
func clear_entity_skulls() -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for c in range(_cols):
		for r in range(_rows):
			if _grid[c][r] == null:
				continue
			if (_grid[c][r] as TokenData).kind == TokenData.Kind.ENTITY:
				positions.append(Vector2i(c, r))
				_grid[c][r] = null
	entity_skulls_cleared.emit(positions)
	return positions


func get_grid() -> Array:
	return _grid


## Compte les Rocks actuellement sur la grille (ex: sortilège "Cairn", qui lit ce
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
