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
## revelee — TurnController applique l'effet reel (valeur/verrou/fusion/
## pierre liberee/petrification/trou/multi), voir _on_mystery_cell_triggered.
## `token` est le jeton qui vient de declencher, present pour compatibilite
## de signature mais les effets qui le concernent le re-recuperent via
## get_cell(col, row) plutot que ce parametre directement.
signal mystery_cell_triggered(col: int, row: int, effect: MysteryCellEffects.Type, token: TokenData)
## Emis quand un ENTITY (skull) atterrit sur une case mystere non encore
## revelee (session 27) -- au lieu de declencher l'effet normalement (voir
## mystery_cell_triggered), la corruption la desamorce : la case est
## consommee mais l'effet n'est JAMAIS applique. Evite qu'un skull ne
## distribue accidentellement un bonus (deja arrive avant ce fix), et
## respecte l'esprit "systemes independants" pose pour roulette/mystere en
## session 25 -- la corruption ne doit jamais accidentellement recompenser.
signal mystery_cell_defused(col: int, row: int, effect: MysteryCellEffects.Type)
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


## Place un jeton basique, rock ou entity-skull sur la grille. Retourne la
## landing row (utile pour TurnController.dropped_token_mutated, voir Pile ou
## Face), -1 si le jeton n'a pas ete place (colonne pleine, ou special -- sa
## landing row passe par special_landing plutot que la valeur de retour).
## ENTITY inclus depuis session 27 (voir EntityManager.
## roll_cursed_column_corruption) : le skull de corruption d'une Colonne
## Convoitée passe par TurnController._drop_token comme un jeton normal
## (animation de chute + notify_drop_complete), plutot que par
## place_token_direct + animation manuelle (reserve a la corruption ambiante
## post-tour, voir GameScene._on_turn_resolved -- sans ce cas ENTITY ici,
## token_placed n'etait jamais emis et l'appelant restait bloque sur
## "await drop_animated" pour toujours).
func place_token(token: TokenData, col: int, _row: int) -> int:
	if token.kind == TokenData.Kind.BASE or token.kind == TokenData.Kind.ROCK or token.kind == TokenData.Kind.ENTITY:
		var landing_row: int = column_height(col)
		if landing_row >= _rows:
			return -1
		_grid[col][landing_row] = token
		token_placed.emit(col, landing_row, token)
		_check_mystery_trigger(col, landing_row, token)
		return landing_row

	elif token.kind == TokenData.Kind.SPECIAL:
		# Calculer la landing row pour l'animation de chute
		var landing_row: int = _get_special_landing_row(token, col)
		special_landing.emit(col, landing_row, token)

	return -1


## Execute l'effet du special APRES l'animation de chute.
## Appele par le TurnController une fois le drop anime.
func execute_special(token: TokenData, col: int) -> int:
	var result: Dictionary = {}
	var score: int = 0
	match token.special_type:
		TokenData.SpecialType.FANTOME:
			SpecialEffects.execute_fantome(_grid, col, _rows, _holes)
		TokenData.SpecialType.MAREE:
			var landing_row: int = column_height(col)
			SpecialEffects.execute_maree(_grid, col, landing_row, _cols, _holes)
		TokenData.SpecialType.ENCLUME:
			SpecialEffects.execute_enclume(_grid, col, _rows, _holes)
		TokenData.SpecialType.CRISTAL:
			var cristal_row: int = column_height(col)
			SpecialEffects.execute_cristal_diamant(_grid, col, cristal_row, _cols, _rows, GameRules.CRISTAL_VALUE, _holes)
		TokenData.SpecialType.DIAMANT:
			var diamant_row: int = column_height(col)
			SpecialEffects.execute_cristal_diamant(_grid, col, diamant_row, _cols, _rows, GameRules.DIAMANT_VALUE, _holes)
		TokenData.SpecialType.COMETE:
			var comete_row: int = column_height(col)
			score = SpecialEffects.execute_comete(_grid, col, comete_row, _cols, _rows, _holes)
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
		TokenData.SpecialType.AMPLIFICATEUR:
			_place_persistent_special(token, col)
		TokenData.SpecialType.SIPHON:
			_place_persistent_special(token, col, GameRules.SIPHON_MAX_EATS)
	special_executed.emit(token.special_type, col, 0, result)
	return score


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
func generate_random_holes() -> void:
	_holes.clear()
	_generate_seafloor()
	var red_count: int = randi_range(GameRules.ROUND_START_RED_HOLES_MIN, GameRules.ROUND_START_RED_HOLES_MAX)
	_scatter_holes(red_count)
	holes_changed.emit(_holes.duplicate())


## "Fond marin" (session 26, quatrieme jet) : plusieurs pics independants
## (GameRules.SEAFLOOR_PEAK_COUNT_MIN/MAX), chacun ancre sur une colonne au
## hasard -- pas forcement centre, peut deborder d'un bord (_carve_peak
## clippe tout seul).
func _generate_seafloor() -> void:
	var peak_count: int = randi_range(GameRules.SEAFLOOR_PEAK_COUNT_MIN, GameRules.SEAFLOOR_PEAK_COUNT_MAX)
	for i in range(peak_count):
		var anchor: int = randi() % _cols
		var height: int = _pick_seafloor_peak_height()
		_carve_peak(anchor, height)


## Pyramide en escalier centree sur `anchor_col` : largeur `height * 2 - 1`
## a la base (row 0), retrecit de 2 cases par row en montant jusqu'a 1 case
## au sommet (row height-1). Colonnes hors-grille simplement ignorees --
## clippe naturellement les pics ancres pres d'un bord.
func _carve_peak(anchor_col: int, height: int) -> void:
	for row in range(height):
		var half_width: int = height - 1 - row
		for col in range(anchor_col - half_width, anchor_col + half_width + 1):
			if col < 0 or col >= _cols:
				continue
			_holes[Vector2i(col, row)] = true


## Tirage a taux fixe par hauteur -- meme principe que
## MysteryCellEffects.pick_random (GameRules.SEAFLOOR_PEAK_HEIGHT_RATES).
func _pick_seafloor_peak_height() -> int:
	var rates: Array[float] = GameRules.SEAFLOOR_PEAK_HEIGHT_RATES
	var roll: float = randf()
	var cumulative: float = 0.0
	for i in range(rates.size()):
		cumulative += rates[i]
		if roll < cumulative:
			return i + 1
	return 1


## Trous "rouges" en plus du fond marin, disperses au hasard sur toute la
## grille (jamais en row 0 -- le sol garde toujours au moins une case
## non-trouee sur ces colonnes-la).
func _scatter_holes(count: int) -> void:
	var target: int = _holes.size() + count
	var attempts: int = 0
	while _holes.size() < target and attempts < count * 20:
		attempts += 1
		var col: int = randi() % _cols
		var row: int = 1 + randi() % (_rows - 1)  # jamais row 0
		_holes[Vector2i(col, row)] = true


## Persistance entre manches (session 26) : pour chaque colonne, le jeton
## qui persiste est celui de la case occupee la plus haute, SEULEMENT si
## c'est un TokenData.Kind.BASE -- si la case occupee la plus haute est un
## Rock/Skull/Special/Residue, la colonne ne persiste rien du tout, meme
## s'il y a un bon jeton juste en dessous. Volontairement tactique : couvrir
## un jeton (avec un Rock par ex.) le protege de la persistance, il reste
## dans le deck possede plutot que d'etre re-pose au hasard la manche
## suivante. Colonne sans aucune case occupee -> null. Appele juste avant
## que la grille de la manche ne soit remplacee (voir GameScene._on_round_won).
## Layout fixe : COLS * GameRules.CARRYOVER_MAX_DEPTH, index = col *
## CARRYOVER_MAX_DEPTH + k (k=0 la case la plus haute, k=1 la suivante en
## dessous). Le slot k+1 n'est rempli que si le slot k l'est deja -- des
## qu'un Rock/Skull/Special/Residue est rencontre (case occupee mais pas
## BASE), le scan de la colonne s'arrete completement, meme pour les slots
## suivants. Toujours calcule jusqu'a CARRYOVER_MAX_DEPTH -- c'est
## GameScene._on_round_won qui decide, selon le Sortilège "Deux étages", de
## garder ou d'effacer les slots k>=1 avant stockage (voir GameRules.
## CARRYOVER_MAX_DEPTH pour pourquoi le layout reste fixe).
func get_top_base_tokens() -> Array[TokenData]:
	var depth: int = GameRules.CARRYOVER_MAX_DEPTH
	var result: Array[TokenData] = []
	result.resize(_cols * depth)
	for c in range(_cols):
		var slot: int = 0
		for r in range(_rows - 1, -1, -1):
			if slot >= depth:
				break
			var token: TokenData = _grid[c][r]
			if token == null:
				continue
			if token.kind != TokenData.Kind.BASE or token.temporary:
				break
			result[c * depth + slot] = token
			slot += 1
	return result


## Meme regle que get_top_base_tokens, mais retourne les rows (pas les
## jetons) pour une seule colonne -- utilise par l'animation d'aspiration
## (GameScene._play_carryover_pickup) pour savoir d'ou faire partir chaque
## sprite. Taille CARRYOVER_MAX_DEPTH, -1 pour un slot qui ne persiste rien
## (vide, bloque par un Rock/Skull/Special, ou au-dela de la profondeur
## reellement occupee).
func get_top_base_token_rows(col: int) -> Array[int]:
	var depth: int = GameRules.CARRYOVER_MAX_DEPTH
	var result: Array[int] = []
	result.resize(depth)
	for k in range(depth):
		result[k] = -1
	var slot: int = 0
	for r in range(_rows - 1, -1, -1):
		if slot >= depth:
			break
		var token: TokenData = _grid[col][r]
		if token == null:
			continue
		if token.kind != TokenData.Kind.BASE or token.temporary:
			break
		result[slot] = r
		slot += 1
	return result


func get_holes() -> Dictionary:
	return _holes.duplicate()


## Ajoute des trous fixes en plus de ceux deja generes (grille cabossee),
## sans effacer les existants — voir BossMalusManager (L'ÉTAU, CIEL BAS).
func add_holes(cells: Array[Vector2i]) -> void:
	for cell in cells:
		_holes[cell] = true
	holes_changed.emit(_holes.duplicate())


## Cases mystere (session 24) : genere `count` cases a des positions
## aleatoires, jamais sur un trou (jamais atterrissable de toute facon) ni
## sur une case deja occupee (session 26 : les jetons persistes entre
## manches sont poses avant cet appel, voir TurnController.start_round).
## Appele au debut de chaque manche. Le contenu (MysteryCellEffects.Type)
## est tire tout de suite mais reste cache jusqu'a declenchement, voir
## _check_mystery_trigger.
func generate_random_mystery_cells(count: int) -> void:
	_mystery_cells.clear()
	var attempts: int = 0
	while _mystery_cells.size() < count and attempts < count * 20:
		attempts += 1
		var cell: Vector2i = Vector2i(randi() % _cols, randi() % _rows)
		if _holes.has(cell) or _mystery_cells.has(cell) or _grid[cell.x][cell.y] != null:
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
	if token.kind == TokenData.Kind.ENTITY:
		mystery_cell_defused.emit(col, row, effect)
		return
	mystery_cell_triggered.emit(col, row, effect, token)


## Effet HOLE_REMOVE (voir MysteryCellEffects) : comble un trou existant
## choisi au hasard. Ne fait rien si aucun trou sur la grille.
func remove_random_hole() -> void:
	if _holes.is_empty():
		return
	var cell: Vector2i = (_holes.keys() as Array).pick_random() as Vector2i
	_holes.erase(cell)
	holes_changed.emit(_holes.duplicate())


## Effets VALUE_UP/VALUE_DOWN (voir MysteryCellEffects) : mute la valeur du
## jeton qui a declenche la case de `delta`, plafonnee entre TOKEN_MIN_VALUE
## et MAX_BUTTON_VALUE. No-op silencieux sur un jeton non-BASE.
func nudge_token_value(col: int, row: int, delta: int) -> void:
	var token: TokenData = get_cell(col, row)
	if token == null or token.kind != TokenData.Kind.BASE:
		return
	token.value = clampi(token.value + delta, GameRules.TOKEN_MIN_VALUE, GameRules.MAX_BUTTON_VALUE)


## Effet LOCK "Verrou" (voir MysteryCellEffects) : verrouille le jeton qui a
## declenche la case contre toute mutation future -- meme flag que l'action
## Fixer des Des a coudre (voir RunManager.lock_button). No-op silencieux sur
## un jeton non-BASE.
func lock_token(col: int, row: int) -> void:
	var token: TokenData = get_cell(col, row)
	if token == null or token.kind != TokenData.Kind.BASE:
		return
	token.locked = true


## Effet FUSION "Fusion spontanee" (voir MysteryCellEffects) : fusionne le
## jeton qui a declenche la case avec un voisin BASE adjacent (4 directions),
## meme formule que RunManager.fuse_buttons (valeur = somme plafonnee a
## MAX_BUTTON_VALUE, famille tiree au hasard entre les deux). Le voisin est
## retire puis la colonne retassee (GravitySystem). No-op silencieux si aucun
## voisin BASE a portee.
func fuse_with_neighbor(col: int, row: int) -> void:
	var token: TokenData = get_cell(col, row)
	if token == null or token.kind != TokenData.Kind.BASE:
		return
	var neighbor_cell: Vector2i = _find_neighbor(col, row, TokenData.Kind.BASE)
	if neighbor_cell.x < 0:
		return
	var neighbor: TokenData = _grid[neighbor_cell.x][neighbor_cell.y]
	token.family = token.family if randi() % 2 == 0 else neighbor.family
	token.value = mini(token.value + neighbor.value, GameRules.MAX_BUTTON_VALUE)
	_grid[neighbor_cell.x][neighbor_cell.y] = null
	GravitySystem.apply(_grid, _cols, _rows, _holes)


## Effet ROCK_FREED "Pierre liberee" (voir MysteryCellEffects) : convertit un
## Rock adjacent (4 directions) en jeton de base frais (famille aleatoire,
## valeur GameRules.MYSTERY_ROCK_FREED_VALUE) -- conversion en place, aucune
## gravite a retasser (le Rock occupait deja cette case). No-op silencieux si
## aucun Rock a portee.
func free_adjacent_rock(col: int, row: int) -> void:
	var rock_cell: Vector2i = _find_neighbor(col, row, TokenData.Kind.ROCK)
	if rock_cell.x < 0:
		return
	var family: TokenData.Family = TokenData.Family.values().pick_random()
	_grid[rock_cell.x][rock_cell.y] = TokenData.make_base(family, GameRules.MYSTERY_ROCK_FREED_VALUE)


## Effet PETRIFICATION (voir MysteryCellEffects) : un Rock surgit SOUS le
## jeton qui a declenche la case -- le jeton lui-meme n'est jamais mute (voir
## discussion de design, session 27 : contrairement a une mutation/
## teleportation qui reviendrait sur le choix du joueur, ceci ajoute un
## obstacle de terrain sans jamais toucher a ce qu'il a decide de poser),
## juste pousse d'une row plus haut. Fizzle silencieux si aucune place au-
## dessus (colonne pleine ou trou) -- meme discipline que free_adjacent_rock.
func petrify_below(col: int, row: int) -> void:
	var token: TokenData = get_cell(col, row)
	if token == null:
		return
	var above: int = row + 1
	if above >= _rows or _holes.has(Vector2i(col, above)) or _grid[col][above] != null:
		return
	_grid[col][above] = token
	_grid[col][row] = TokenData.make_rock()


## Cherche un voisin direct (4 directions, ordre randomise) du type demande.
## Retourne Vector2i(-1,-1) si aucun trouve.
func _find_neighbor(col: int, row: int, kind: TokenData.Kind) -> Vector2i:
	var offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	offsets.shuffle()
	for offset in offsets:
		var c: int = col + offset.x
		var r: int = row + offset.y
		if c < 0 or c >= _cols or r < 0 or r >= _rows:
			continue
		var neighbor: TokenData = _grid[c][r]
		if neighbor != null and neighbor.kind == kind:
			return Vector2i(c, r)
	return Vector2i(-1, -1)


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
## `multiplier_by_type` (SpecialType -> float, defaut 1.0 si absent) : les
## Sortilèges Décuple Pétard/Quintuple Bombe/Triple Armageddon (session
## "Vague 1") multiplient le score d'un seul type d'explosif chacun -- fourni
## par TurnController, qui seul a acces a RunManager.has_spell (GridManager
## reste pure logique de grille, sans notion de Sortilèges).
func tick_special_countdowns(multiplier_by_type: Dictionary = {}) -> int:
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
		var mult: float = multiplier_by_type.get(special_type, 1.0)
		total_score += int(_detonate_explosive(cell, _explosive_offsets(special_type)) * mult)
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
			TokenData.SpecialType.SIPHON:
				var siphon_result: Dictionary = SpecialEffects.siphon_eat(_grid, cell.x, cell.y, _rows)
				total_score += siphon_result["score"] as int
				var eaten: int = siphon_result["eaten"] as int
				if eaten == 0:
					# Plus rien a manger au-dessus/en dessous -- colonne "vide"
					# autour de lui, il disparait meme si son plafond de
					# bouchees n'est pas atteint.
					_grid[cell.x][cell.y] = null
				elif not never_expire:
					token.countdown -= eaten
					if token.countdown <= 0:
						_grid[cell.x][cell.y] = null

	if cells.size() > 0:
		mobile_specials_ticked.emit()
	return total_score


## Dernier Souffle : les jetons speciaux poses explosent (decision verrouillee,
## voir CLAUDE.md) — toute la famille Petard/Bombe/Armageddon encore active
## detone immediatement, countdown ou pas, en miroir de explode_residues pour
## les Rocks/Residus (voir TurnController._trigger_last_breath). Retourne le
## score gagne. `multiplier_by_type` : voir tick_special_countdowns.
func detonate_remaining_explosives(multiplier_by_type: Dictionary = {}) -> int:
	var to_detonate: Array[Vector2i] = []
	for c in range(_cols):
		for r in range(_rows):
			var token: TokenData = _grid[c][r]
			if token != null and token.kind == TokenData.Kind.SPECIAL and _EXPLOSIVE_TYPES.has(token.special_type):
				to_detonate.append(Vector2i(c, r))
	var total_score: int = 0
	for cell in to_detonate:
		var special_type: TokenData.SpecialType = (_grid[cell.x][cell.y] as TokenData).special_type
		var mult: float = multiplier_by_type.get(special_type, 1.0)
		total_score += int(_detonate_explosive(cell, _explosive_offsets(special_type)) * mult)
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
## le joueur. Exclut aussi les jetons verrouilles (voir RunManager.lock_button,
## action "Fixer") -- meme raison que RunManager.boost_random_button. Retourne
## la cellule touchee, ou Vector2i(-1,-1) si aucun jeton de base boostable
## n'est present sur la grille.
func boost_random_token(amount: int) -> Vector2i:
	var candidates: Array[Vector2i] = []
	for c in range(_cols):
		for r in range(_rows):
			var token: TokenData = _grid[c][r]
			if token != null and token.kind == TokenData.Kind.BASE and token.value < GameRules.MAX_BUTTON_VALUE and not token.locked:
				candidates.append(Vector2i(c, r))
	if candidates.is_empty():
		return Vector2i(-1, -1)
	var cell: Vector2i = candidates.pick_random()
	var token: TokenData = _grid[cell.x][cell.y]
	token.value = mini(token.value + amount, GameRules.MAX_BUTTON_VALUE)
	return cell


## Bouton d'urgence "Shake" (session 27, remplace le remelange invisible du
## stream, jamais utilise en playtest -- "il n'a rien de tres spectaculaire")
## : shuffle physique de tous les jetons de base actuellement sur la grille.
## Meme footprint de cellules (aucune gravite a retasser) -- seul QUEL jeton
## est OU change, holes/rocks/entity-skulls jamais touches (obstacles
## structurels, les deplacer ne debloquerait rien). Les jetons verrouilles
## restent fixes eux aussi -- meme logique que la protection Fixer contre le
## Boost (voir GridManager.boost_random_token) : un joueur qui a verrouille un
## jeton l'a fait pour une raison precise, un shuffle ne doit pas ruiner un
## placement deja soigne sans aucun recours.
func shuffle_base_tokens() -> void:
	var cells: Array[Vector2i] = []
	var tokens: Array[TokenData] = []
	for c in range(_cols):
		for r in range(_rows):
			var token: TokenData = _grid[c][r]
			if token != null and token.kind == TokenData.Kind.BASE and not token.locked:
				cells.append(Vector2i(c, r))
				tokens.append(token)
	tokens.shuffle()
	for i in range(cells.size()):
		_grid[cells[i].x][cells[i].y] = tokens[i]


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
