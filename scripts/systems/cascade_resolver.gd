class_name CascadeResolver
extends RefCounted

## Types d'evenements dans la timeline
enum EventType { GRAVITY, MATCH, REMOVE, UPGRADE, ROCKIFY, TRANSFORM }


## Resout toutes les cascades sur la grille. `holes` (Vector2i -> true) sont
## les trous de la "grille cabossee" — transparents a la gravite, jamais
## occupables (a ne pas confondre avec les trous laisses par les specials,
## qui sont juste des cases devenues null).
## Retourne une timeline d'evenements pour le visuel + le score total gagne.
func resolve(grid: Array, cols: int, rows: int, context: RunContext, holes: Dictionary = {}) -> Dictionary:
	var timeline: Array[Dictionary] = []
	var total_score: int = 0

	# Passe de gravite initiale (cases videes laissees par les specials)
	var initial_movements: Array[Dictionary] = GravitySystem.apply(grid, cols, rows, holes)
	if initial_movements.size() > 0:
		timeline.append({
			"type": EventType.GRAVITY,
			"movements": initial_movements,
		})

	var cascade_level: int = 0

	while true:
		var candidates: Array[Dictionary] = SheetMatcher.find_all(grid, cols, rows, context)
		if candidates.size() == 0:
			break

		# Capture la famille avant suppression des cellules (utile aux badges
		# qui lisent la timeline apres coup, ex: "Un Pour Tous").
		for group in candidates:
			if group.get("match_rule") == &"family":
				var cells: Array = group["cells"]
				if cells.size() > 0:
					var first_cell: Vector2i = cells[0]
					var first_token: TokenData = grid[first_cell.x][first_cell.y] as TokenData
					if first_token != null:
						group["family"] = first_token.family
			group["score"] = _score_group(group, grid, cascade_level, context)

		# Deux formes differentes peuvent matcher un cluster qui se chevauche.
		# On trie par score decroissant, puis pour chaque candidat on compare
		# son ensemble de cellules a celui de chaque groupe deja retenu :
		# - inclusion totale dans un sens ou l'autre (ex: T contenu dans Plus,
		#   memes jetons) -> simple doublon, on ne garde que le mieux paye
		#   (deja garanti par le tri decroissant) ;
		# - chevauchement partiel (au moins 1 cellule commune, aucune inclusion
		#   totale, ex: Square Rainbow + Brelan qui convergent sur le jeton
		#   qu'on vient de poser) -> "Double Partition" delibere, les deux
		#   scorent et leur total combine est multiplie par PATTERN_COMBO_MULTIPLIER.
		candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return (a["score"] as int) > (b["score"] as int)
		)

		var accepted_cell_sets: Array[Dictionary] = []  # index-aligne avec `groups`
		var groups: Array[Dictionary] = []
		var scores: Array[int] = []
		var earned: int = 0
		var combo_bonus: int = 0
		for group in candidates:
			var group_cells: Array = (group["cells"] as Array).duplicate()
			if group.has("center"):
				group_cells.append(group["center"])
			var cell_set: Dictionary = {}
			for cell in group_cells:
				cell_set[cell] = true

			var contained: bool = false
			var combo_with: Array[int] = []
			for i in range(accepted_cell_sets.size()):
				var other_set: Dictionary = accepted_cell_sets[i]
				var overlap: int = 0
				for cell in cell_set:
					if other_set.has(cell):
						overlap += 1
				if overlap == 0:
					continue
				if overlap == cell_set.size() or overlap == other_set.size():
					contained = true
					break
				combo_with.append(i)

			if contained:
				continue

			var group_score: int = group["score"] as int
			for i in combo_with:
				combo_bonus += int((scores[i] + group_score) * (GameRules.PATTERN_COMBO_MULTIPLIER - 1.0))

			accepted_cell_sets.append(cell_set)
			groups.append(group)
			scores.append(group_score)
			earned += group_score

		earned += combo_bonus

		# Jetons "upgrades" (ex: Poker Face) tires pendant _score_group, mais
		# uniquement pour les groupes retenus (pas les doublons rejetes
		# ci-dessus) — evite de crediter deux fois le meme jeton chevauchant
		# une Double Partition.
		var upgrades: Array = []
		for group in groups:
			upgrades.append_array(group.get("upgrade_candidates", []) as Array)

		# Collecter les cellules a supprimer (dedupliquees, deja garanties
		# sans chevauchement par le filtrage ci-dessus)
		var leaves_rock: bool = not context.rock_leaving_sources.is_empty()
		var rock_replacements: Array[Vector2i] = []  # ex: "Récif vivant"
		var cells_to_remove: Dictionary = {}  # Vector2i -> true
		for group in groups:
			# Diamond Rock "recolte" uniquement son centre : les 4 Rocks du
			# losange ne sont jamais retires. Ils servent d'outil reutilisable
			# (relief de grille, terrain de Badges) tant qu'ils sont sur le
			# plateau, et doivent rester disponibles pour exploser au Dernier
			# Souffle en fin de manche — les detruire a chaque recolte les
			# priverait de ce role. Toutes les autres formes (dont diamond
			# family/rainbow) retirent leurs cellules normalement.
			var is_rock_harvest: bool = group["shape"] == &"diamond" and group.get("match_rule") == &"rock"
			if not is_rock_harvest:
				var group_cells: Array = group["cells"]
				# "Récif vivant" (session 17) : un jeton aleatoire PARMI CEUX QUI
				# VIENNENT DE SCORER echappe a la suppression et devient un rock
				# a la place, plutot que de disparaitre normalement.
				var skip_cell: Vector2i = Vector2i(-1, -1)
				if leaves_rock and group_cells.size() > 0:
					skip_cell = group_cells[randi() % group_cells.size()]
					rock_replacements.append(skip_cell)
				for cell in group_cells:
					if cell == skip_cell:
						continue
					cells_to_remove[cell] = true
			# Diamond Rock "recolte" son centre : il est scorable (voir
			# _score_group) et consomme avec le reste du losange. Les autres
			# formes a centre indifferent (diamond family/rainbow, ring) ne
			# touchent jamais au centre — il n'entrait pas dans le match, il ne
			# doit pas etre efface non plus : il reste en place et tombe
			# normalement a la gravite qui suit si sa colonne s'est videe.
			if group.has("center") and group.get("match_rule") == &"rock":
				cells_to_remove[group["center"] as Vector2i] = true
			# Legendaire "Lost Corners" : son multiplicateur = somme de TOUTE
			# la rangee du bas (_bottom_row_value_sum), pas seulement les 2
			# coins qui declenchent le match. Sans ca, rien n'empeche
			# d'empiler la rangee et de retrigger le combo indefiniment sans
			# jamais le "depenser" — on vide donc la rangee du bas (jetons
			# scorables uniquement, sans les scorer une 2e fois) des qu'elle
			# a servi de carburant au multi.
			if group.get("sheet_name", &"") == &"lost_corners":
				for c in range(cols):
					var bottom_token: TokenData = grid[c][0] as TokenData
					if bottom_token != null and bottom_token.is_scorable():
						cells_to_remove[Vector2i(c, 0)] = true
		var removed_cells: Array[Vector2i] = []
		for cell in cells_to_remove.keys():
			removed_cells.append(cell as Vector2i)

		# Legendaire "Last Trick" (session 20) : son centre n'entre jamais dans
		# cells_to_remove (diamond family, voir plus haut) — il reste en place
		# tel quel normalement. Ici on le transforme en jeton LAST_TRICK_VALUE
		# AJOUTE DEFINITIVEMENT au pool (voir GameRules.LAST_TRICK_VALUE et
		# TurnController pour l'application reelle sur RunManager — meme
		# principe que EventType.UPGRADE, CascadeResolver reste de la logique
		# pure sans reference a RunManager). Un seul jet par match decide de
		# tout l'effet (LAST_TRICK_TRIGGER_CHANCE) — Diamond+famille se
		# declenche trop souvent pour un moteur permanent systematique. Famille
		# prise sur un des 4 BRAS, jamais sur le centre lui-meme : le centre
		# peut etre n'importe quoi (Rock, Entity, Special, Residu, ou un Base
		# d'une autre famille — voir find_diamonds, le centre n'entre jamais
		# dans la condition de match), et TokenData.family vaut BATONS par
		# defaut pour tout ce qui n'est pas Kind.BASE — le lire directement
		# aurait toujours donne BATONS, jamais la vraie famille voulue. Les 4
		# bras, eux, sont deja garantis de la meme famille par la regle
		# "family" elle-meme. Case vide (trou de grille ou autre) au centre :
		# rien a transformer, on saute.
		var last_trick_transforms: Array[Dictionary] = []  # {"cell", "family"}
		for group in groups:
			if group.get("sheet_name", &"") == &"last_trick" and group.has("center"):
				if randf() >= GameRules.LAST_TRICK_TRIGGER_CHANCE:
					continue
				var center: Vector2i = group["center"] as Vector2i
				if grid[center.x][center.y] == null:
					continue
				var arm_cells: Array = group["cells"]
				if arm_cells.is_empty():
					continue
				var arm_cell: Vector2i = arm_cells[0] as Vector2i
				var arm_token: TokenData = grid[arm_cell.x][arm_cell.y] as TokenData
				if arm_token != null:
					last_trick_transforms.append({"cell": center, "family": arm_token.family})

		# Special "Hypercube" (session 22) : si une Partition score en touchant
		# au moins une des 8 cases autour d'un Hypercube pose sur la grille,
		# duplique un jeton scoré au hasard de cette Partition — meme
		# mecanisme que Last Trick (EventType.TRANSFORM, applique plus bas),
		# sauf que family ET value varient ici (voir TurnController._on_
		# resolution_complete, qui lit "value" avec fallback LAST_TRICK_VALUE
		# pour rester compatible avec Last Trick). Un Hypercube donne ne peut
		# declencher qu'une fois (retire du jeu au premier proc, voir
		# triggered_hypercubes).
		var hypercube_transforms: Array[Dictionary] = []  # {"cell", "family", "value"}
		var triggered_hypercubes: Dictionary = {}  # Vector2i -> true
		for group in groups:
			var scored_tokens: Array = group.get("scored_tokens", [])
			if scored_tokens.is_empty():
				continue
			var group_cells: Array = (group["cells"] as Array).duplicate()
			if group.has("center"):
				group_cells.append(group["center"])
			for cell in group_cells:
				var gc: Vector2i = cell as Vector2i
				for dc in range(-1, 2):
					for dr in range(-1, 2):
						var hc: Vector2i = Vector2i(gc.x + dc, gc.y + dr)
						if hc.x < 0 or hc.x >= cols or hc.y < 0 or hc.y >= rows:
							continue
						if triggered_hypercubes.has(hc):
							continue
						var maybe_hypercube: TokenData = grid[hc.x][hc.y] as TokenData
						if maybe_hypercube == null or maybe_hypercube.kind != TokenData.Kind.SPECIAL or maybe_hypercube.special_type != TokenData.SpecialType.HYPERCUBE:
							continue
						var picked: Dictionary = scored_tokens[randi() % scored_tokens.size()] as Dictionary
						hypercube_transforms.append({"cell": hc, "family": picked["family"], "value": picked["value"]})
						triggered_hypercubes[hc] = true

		# Evenement match
		timeline.append({
			"type": EventType.MATCH,
			"groups": groups,
			"scores": scores,
			"cascade_level": cascade_level,
			"total_earned": earned,
			"combo_bonus": combo_bonus,
		})

		# Evenement upgrade (ex: Poker Face) — insere avant la suppression pour
		# que le visuel puisse montrer le jeton monter d'un cran avant de
		# disparaitre. L'upgrade REEL du pool (RunManager.increase_button_value)
		# n'a pas lieu ici : CascadeResolver reste de la logique pure, sans
		# reference a RunManager — TurnController applique l'upgrade en lisant
		# cet evenement (voir conventions, "communication entre systemes = signals").
		if upgrades.size() > 0:
			timeline.append({
				"type": EventType.UPGRADE,
				"upgrades": upgrades,
			})

		# Supprimer les jetons
		for cell in removed_cells:
			grid[cell.x][cell.y] = null

		timeline.append({
			"type": EventType.REMOVE,
			"cells": removed_cells,
		})

		# "Récif vivant" : les jetons epargnes ci-dessus deviennent des rocks
		# APRES la suppression du reste du groupe — pour que le visuel montre
		# clairement "les autres disparaissent, celui-la se petrifie" plutot
		# que tout se meler dans la meme animation.
		if rock_replacements.size() > 0:
			for cell in rock_replacements:
				grid[cell.x][cell.y] = TokenData.make_rock()
			timeline.append({
				"type": EventType.ROCKIFY,
				"cells": rock_replacements,
			})

		if last_trick_transforms.size() > 0:
			for entry in last_trick_transforms:
				var cell: Vector2i = entry["cell"] as Vector2i
				var family: TokenData.Family = entry["family"] as TokenData.Family
				grid[cell.x][cell.y] = TokenData.make_base(family, GameRules.LAST_TRICK_VALUE)
			timeline.append({
				"type": EventType.TRANSFORM,
				"transforms": last_trick_transforms,
			})

		if hypercube_transforms.size() > 0:
			for entry in hypercube_transforms:
				var cell: Vector2i = entry["cell"] as Vector2i
				var family: TokenData.Family = entry["family"] as TokenData.Family
				var value: int = entry["value"] as int
				grid[cell.x][cell.y] = TokenData.make_base(family, value)
			timeline.append({
				"type": EventType.TRANSFORM,
				"transforms": hypercube_transforms,
			})

		total_score += earned

		# Gravite post-removal
		var movements: Array[Dictionary] = GravitySystem.apply(grid, cols, rows, holes)
		if movements.size() > 0:
			timeline.append({
				"type": EventType.GRAVITY,
				"movements": movements,
			})

		cascade_level += 1

	return {
		"timeline": timeline,
		"total_score": total_score,
	}


## Calcule le score d'un groupe.
## Toutes les formes (lignes comprises) : multiplicateur fixe defini sur le sheet.
## Cellules modifiees : chaque cellule concernee multiplie le total par son coef (HALF/BOOST/DOUBLE/TRIPLE).
## rule_mult : multiplicateur applique selon la rule du pattern (ex: "family" x2 via badge),
## voir RunContext.get_rule_multiplier — combine par produit si plusieurs badges.
## sheet_level_multipliers : multiplicateur selon le niveau de la Partition qui a matche (level up).
func _score_group(group: Dictionary, grid: Array, cascade_level: int, context: RunContext) -> int:
	var grid_modifiers: Dictionary = context.grid_modifiers
	var sheet_level_multipliers: Dictionary = context.sheet_level_multipliers
	var cascade_mult: float = pow(GameRules.CASCADE_MULTIPLIER_BASE, cascade_level)
	var rule: StringName = group.get("match_rule", &"") as StringName
	var rule_mult: float = context.get_rule_multiplier(rule)
	var sheet_name: StringName = group.get("sheet_name", &"") as StringName
	var level_mult: float = sheet_level_multipliers.get(sheet_name, 1.0) as float
	var global_mult: float = context.get_global_multiplier()
	# Bonus de multiplicateur specifique a CETTE Partition (ex: "Refrain",
	# voir RunContext.get_sheet_multiplier_bonus_sum) — un badge, pas une
	# stat propre au sheet, donc jamais neutralise par PARTITION TERNIE
	# (contrairement a shape_mult/level_mult ci-dessous), meme logique que
	# rule_mult/global_mult/scaling_mult qui restent normaux face a ce malus.
	var sheet_bonus_mult: float = 1.0 + context.get_sheet_multiplier_bonus_sum(sheet_name)

	# Malus de boss PARTITION TERNIE (voir BossMalusManager) : en miroir de
	# FAMILLE TERNIE (qui plafonne chaque JETON a 1, voir _effective_token_value),
	# on neutralise ici le multiplicateur PROPRE a la Partition ciblee (son
	# score_multiplier de base, y compris legendaire dynamique, + son niveau)
	# plutot que le total du groupe — les tickets des jetons et les multi de
	# Badges (rule/global/scaling/etc.) restent normaux.
	var partition_targeted: bool = context.score_capped_sheet_name != &"" and sheet_name == context.score_capped_sheet_name
	if partition_targeted:
		level_mult = 1.0
	# Scaling permanent (session 17) : facteur additif qui grossit sur toute
	# la run (ex: Jetons sacres, +0.1 par special joue), distinct de global_mult
	# pour ne pas entrer en collision avec Dernier Carre/Regularite.
	var scaling_mult: float = 1.0 + context.scaling_mult_bonus

	# Diamond : le centre n'entre jamais dans la condition de match (voir
	# SheetMatcher.find_diamonds), mais son role dans le SCORE depend de la
	# rule. Rock : les 4 jetons du losange sont des rocks, sans valeur — c'est
	# le centre qui est "recolte", il doit donc etre scorable. Family (et
	# futures rules) : les 4 jetons du losange sont deja garantis scorables
	# par le match, le centre est vraiment ignore — on somme les 4 jetons,
	# comme une ligne ou un carre.
	if group["shape"] == &"diamond":
		var sheet_mult: float = group.get("score_multiplier", 4.0) as float
		if partition_targeted:
			sheet_mult = 1.0
		var raw_value: int = 0
		var scored_cells: Array = []

		var rock_roll: int = -1
		if rule == &"rock":
			var center: Vector2i = group["center"] as Vector2i
			var center_token: TokenData = grid[center.x][center.y] as TokenData
			if center_token == null or not center_token.is_scorable():
				return 0
			rock_roll = randi_range(GameRules.DIAMOND_ROCK_ROLL_MIN, GameRules.DIAMOND_ROCK_ROLL_MAX)
			raw_value = _effective_token_value(center_token, context) + rock_roll
			scored_cells = [center]
		else:
			for cell in group["cells"]:
				var token: TokenData = grid[cell.x][cell.y] as TokenData
				if token != null and token.is_scorable():
					raw_value += _effective_token_value(token, context)
			scored_cells = group["cells"]

		var diamond_grid_mult: float = _grid_modifier_multiplier(scored_cells, grid_modifiers)
		var diamond_value_bonus_mult: float = _value_bonus_multiplier(scored_cells, grid, context)
		var diamond_sum_bonus: Dictionary = _value_sum_bonus(group, scored_cells, grid, context)
		var base_value: int = raw_value + (diamond_sum_bonus["amount"] as int)
		group["upgrade_candidates"] = _roll_upgrades(scored_cells, grid, context) + _roll_face_promotions(scored_cells, grid, context)
		group["scored_tokens"] = _snapshot_scored_tokens(scored_cells, grid)
		var diamond_mult_contribs: Dictionary = _mult_contributions(scored_cells, grid, context, rule, sheet_name)
		# cascade_mult exclu du breakdown affiche : la banniere de resolution
		# lui dedie sa propre annonce (voir GridVisual._animate_match), pas
		# noye dans le MULTI generique. Le score reel l'inclut toujours.
		var diamond_base_mult: float = sheet_mult * diamond_grid_mult * level_mult
		_attach_breakdown(group, context, raw_value, base_value, diamond_base_mult, diamond_sum_bonus["contributions"] as Dictionary, diamond_mult_contribs)
		if rock_roll >= 0:
			(group["score_breakdown"] as Dictionary)["roll"] = rock_roll
			(group["score_breakdown"] as Dictionary)["roll_min"] = GameRules.DIAMOND_ROCK_ROLL_MIN
			(group["score_breakdown"] as Dictionary)["roll_max"] = GameRules.DIAMOND_ROCK_ROLL_MAX
		return int(base_value * sheet_mult * cascade_mult * diamond_grid_mult * rule_mult * level_mult * global_mult * diamond_value_bonus_mult * scaling_mult * sheet_bonus_mult)

	var raw_value: int = 0
	for cell in group["cells"]:
		var token: TokenData = grid[cell.x][cell.y] as TokenData
		if token != null and token.is_scorable():
			raw_value += _effective_token_value(token, context)

	var sum_bonus: Dictionary = _value_sum_bonus(group, group["cells"], grid, context)
	var value_sum: int = raw_value + (sum_bonus["amount"] as int)
	group["upgrade_candidates"] = _roll_upgrades(group["cells"], grid, context) + _roll_face_promotions(group["cells"], grid, context)
	group["scored_tokens"] = _snapshot_scored_tokens(group["cells"], grid)

	# Multiplicateur fixe du sheet, meme regle pour toutes les formes (les lignes
	# ne sont plus recompensees selon leur direction de resolution, session 16).
	var shape_mult: float = group.get("score_multiplier", 1.0) as float

	# Legendaires (session 20) : multiplicateur dynamique code en dur par
	# sheet_name plutot que le score_multiplier fixe de la ressource — voir
	# SheetData.is_legendary pour le raisonnement.
	var legendary_roll: int = -1
	if sheet_name == &"lost_corners":
		shape_mult = float(_bottom_row_value_sum(grid))
	elif sheet_name == &"royal_square":
		legendary_roll = randi_range(GameRules.ROYAL_SQUARE_ROLL_MIN, GameRules.ROYAL_SQUARE_ROLL_MAX)
		shape_mult = float(legendary_roll)

	if partition_targeted:
		shape_mult = 1.0

	var grid_mult: float = _grid_modifier_multiplier(group["cells"], grid_modifiers)
	var value_bonus_mult: float = _value_bonus_multiplier(group["cells"], grid, context)
	var mult_contribs: Dictionary = _mult_contributions(group["cells"], grid, context, rule, sheet_name)
	# cascade_mult exclu du breakdown affiche, meme raison que la branche diamond.
	var base_mult: float = shape_mult * grid_mult * level_mult
	_attach_breakdown(group, context, raw_value, value_sum, base_mult, sum_bonus["contributions"] as Dictionary, mult_contribs)
	if legendary_roll >= 0:
		(group["score_breakdown"] as Dictionary)["roll"] = legendary_roll
		(group["score_breakdown"] as Dictionary)["roll_min"] = GameRules.ROYAL_SQUARE_ROLL_MIN
		(group["score_breakdown"] as Dictionary)["roll_max"] = GameRules.ROYAL_SQUARE_ROLL_MAX
	return int(value_sum * shape_mult * cascade_mult * grid_mult * rule_mult * level_mult * global_mult * value_bonus_mult * scaling_mult * sheet_bonus_mult)


## Somme des valeurs des jetons scorables (kind BASE) sur la ligne du bas
## entiere de la grille (row 0, meme convention que _top_row_occupied) —
## multiplicateur dynamique de la legendaire "Lost Corners". Rocks/Residus/
## Speciaux/Entity ne comptent pas (is_scorable() == false), comme partout
## ailleurs dans ce fichier.
func _bottom_row_value_sum(grid: Array) -> int:
	var bottom_row: int = 0
	var sum: int = 0
	for col in range(GameRules.COLS):
		var token: TokenData = grid[col][bottom_row] as TokenData
		if token != null and token.is_scorable():
			sum += token.value
	return sum


## Chaque cellule modifiee dans la liste multiplie le total par son coefficient
## Un type de modificateur ne compte qu'une fois par groupe qui score, peu
## importe combien de ses cellules touchent une case de ce type — toucher
## UNE case suffit a activer le multi (session 18 : corrige un bug ou une
## Partition entierement posee dans une colonne boostee empilait le meme
## coefficient une fois par cellule, ex. x1.5^5 sur une Line 5). Une meme
## case peut en revanche porter plusieurs types DIFFERENTS empiles (ex:
## Tranchee + Bord a Bord, ou Cellule Triple par-dessus un badge colonne) :
## ceux-la restent cumulatifs entre eux.
func _grid_modifier_multiplier(cells: Array, grid_modifiers: Dictionary) -> float:
	if grid_modifiers.is_empty():
		return 1.0
	var types_touched: Dictionary = {}
	for cell in cells:
		var key: Vector2i = cell as Vector2i
		var types: Array = grid_modifiers.get(key, []) as Array
		for type in types:
			types_touched[type] = true
	var mult: float = 1.0
	for type in types_touched.keys():
		mult *= GameRules.get_modifier_multiplier(type as StringName)
	return mult


## Chaque jeton scorable de la figure dont la valeur a un bonus enregistre
## ajoute ce bonus au multiplicateur (additif, pas multiplicatif entre jetons :
## 2 jetons a +0.5 donnent x2.0, pas x2.25). Voir RunContext.
## get_value_bonus_multiplier_sum — combine par somme si plusieurs badges
## ciblent la meme valeur.
func _value_bonus_multiplier(cells: Array, grid: Array, context: RunContext) -> float:
	var mult: float = 1.0
	for cell in cells:
		var c: Vector2i = cell as Vector2i
		var token: TokenData = grid[c.x][c.y] as TokenData
		if token == null or not token.is_scorable():
			continue
		mult += context.get_value_bonus_multiplier_sum(token.value)
	return mult


## Bonus flat ajoute au value_sum d'un groupe qui score, avant la chaine de
## multiplicateurs — traite exactement comme si les jetons concernes valaient
## plus cher, pas comme un multiplicateur a part. Couvre :
## - retrigger : un jeton dont la valeur est marquee recompte sa propre valeur
##   une deuxieme fois (ex: "Vingt-trois" sur un 3 qui score -> +3) ;
## - bonus de famille : chaque jeton scorable d'une famille ciblee ajoute ce
##   bonus (ex: "Tickets Hivernal" sur DENIERS), peu importe la rule du
##   pattern — pas seulement les patterns de rule "family" ;
## - bonus de paire : le groupe contient au moins deux jetons de meme valeur
##   (ex: "Y'en a pas deux"), applique une seule fois peu importe le nombre
##   de paires trouvees ;
## - bonus rangee du haut : au moins une cellule de la derniere rangee de la
##   grille entiere (pas seulement le groupe) est occupee au moment du score
##   (ex: "Sommet").
func _value_sum_bonus(group: Dictionary, cells: Array, grid: Array, context: RunContext) -> Dictionary:
	var amount: int = 0
	var contributions: Dictionary = {}  # StringName source -> int (montant individuel du badge)

	var value_counts: Dictionary = {}  # int (value) -> int (count), pour la paire
	for cell in cells:
		var c: Vector2i = cell as Vector2i
		var token: TokenData = grid[c.x][c.y] as TokenData
		if token == null or not token.is_scorable():
			continue
		value_counts[token.value] = (value_counts.get(token.value, 0) as int) + 1
		if context.is_retrigger_value(token.value):
			amount += token.value
			var retrigger_sources: Dictionary = context.retrigger_value_contributions.get(token.value, {}) as Dictionary
			for source in retrigger_sources:
				if (source as StringName) == &"":
					continue
				contributions[source] = (contributions.get(source, 0) as int) + token.value

		var family_bonus_sources: Dictionary = context.family_score_bonus_contributions.get(token.family, {}) as Dictionary
		for source in family_bonus_sources:
			var v: int = family_bonus_sources[source] as int
			amount += v
			if (source as StringName) != &"":
				contributions[source] = (contributions.get(source, 0) as int) + v

	if context.get_pair_score_bonus() > 0:
		for count in value_counts.values():
			if (count as int) >= 2:
				for source in context.pair_score_bonus_contributions:
					var pv: int = context.pair_score_bonus_contributions[source] as int
					amount += pv
					if (source as StringName) != &"":
						contributions[source] = (contributions.get(source, 0) as int) + pv
				break

	if context.get_top_row_score_bonus() > 0 and _top_row_occupied(grid):
		for source in context.top_row_score_bonus_contributions:
			var tv: int = context.top_row_score_bonus_contributions[source] as int
			amount += tv
			if (source as StringName) != &"":
				contributions[source] = (contributions.get(source, 0) as int) + tv

	# Bonus scaling permanent (session 17) : contrairement aux autres bonus
	# ci-dessus, inconditionnel — s'applique a CHAQUE groupe qui score (ex:
	# Quatre quart, +5 par pattern de 4 jetons scorés cumulés sur la run).
	if context.flat_score_bonus > 0:
		amount += context.flat_score_bonus
		for source in context.flat_score_bonuses:
			var v: int = context.flat_score_bonuses[source] as int
			contributions[source] = (contributions.get(source, 0) as int) + v

	return {"amount": amount, "contributions": contributions}


## Tire, pour chaque jeton scorable du groupe, une chance de gagner +1 de
## valeur dans le deck (ex: "Poker Face"). Le tirage a lieu ici, PENDANT le
## scoring — donc avant la suppression du jeton de la grille — pour que le
## visuel puisse animer la montee en valeur avant que le jeton disparaisse
## (voir GridVisual._animate_upgrade, EventType.UPGRADE). L'upgrade REEL du
## pool (RunManager.increase_button_value) n'a pas lieu ici : CascadeResolver
## reste de la logique pure sans reference a RunManager (voir conventions,
## "communication entre systemes = signals uniquement") — c'est TurnController
## qui l'applique en lisant ces candidats dans la timeline.
func _roll_upgrades(cells: Array, grid: Array, context: RunContext) -> Array:
	var chance: float = context.token_upgrade_chance
	if chance <= 0.0:
		return []
	var upgrades: Array = []
	for cell in cells:
		var c: Vector2i = cell as Vector2i
		var token: TokenData = grid[c.x][c.y] as TokenData
		if token == null or not token.is_scorable():
			continue
		# >= MAX_BUTTON_VALUE : plafond normal atteint, relève de la suite des
		# figures (_roll_face_promotions) plutôt que de ce chemin probabiliste.
		if token.value >= GameRules.MAX_BUTTON_VALUE:
			continue
		if randf() < chance:
			upgrades.append({"cell": c, "family": token.family, "value": token.value, "next_value": token.value + 1})
	return upgrades


## Malus de boss FAMILLE TERNIE : un jeton de la famille ciblee pour la manche
## scort comme s'il valait 1, peu importe sa vraie valeur — le sheet_mult/
## cascade_mult/etc. s'appliquent ensuite normalement sur ce total reduit
## (ex: Line 3 en 5/2/2 sur la famille ciblee -> 1+1+1=3 avant multi, pas 9).
static func _effective_token_value(token: TokenData, context: RunContext) -> int:
	if context.score_capped_family >= 0 and int(token.family) == context.score_capped_family:
		return 1
	return token.value


## Contrairement a _roll_upgrades (Poker Face, probabiliste), la promotion en
## figure (arcanes mineurs) est une regle de base toujours active : un jeton
## deja a MAX_BUTTON_VALUE (ou plus loin dans la suite) qui score avance
## automatiquement d'un cran (voir GameRules.next_face_value). Chemin
## exclusivement accessible par le score. Un jeton verrouille (action "Fixer"
## des Des a coudre) n'est jamais propose ici, meme s'il rescore. Le malus de
## boss "Cour endormie" (voir BossMalusManager) coupe entierement ce chemin
## pour la manche.
func _roll_face_promotions(cells: Array, grid: Array, context: RunContext) -> Array:
	var promotions: Array = []
	if context.figure_promotion_locked:
		return promotions
	for cell in cells:
		var c: Vector2i = cell as Vector2i
		var token: TokenData = grid[c.x][c.y] as TokenData
		if token == null or not token.is_scorable():
			continue
		if token.locked:
			continue
		if token.value < GameRules.MAX_BUTTON_VALUE:
			continue
		var next_value: int = GameRules.next_face_value(token.value)
		if next_value == token.value:
			continue # deja Roi, plafond definitif
		promotions.append({"cell": c, "family": token.family, "value": token.value, "next_value": next_value})
	return promotions


## Capture famille/valeur des jetons scores AVANT leur suppression de la
## grille (le groupe ne garde que des positions Vector2i dans "cells", les
## jetons eux-memes disparaissent apres resolution — voir decision
## verrouillee). Attache sur group["scored_tokens"], lu par les badges
## dispatches apres coup sur la timeline (ex: "Mouche cubique" a
## on_turn_resolved, qui ne peut plus relire la grille a ce moment-la).
func _snapshot_scored_tokens(cells: Array, grid: Array) -> Array:
	var snapshot: Array = []
	for cell in cells:
		var c: Vector2i = cell as Vector2i
		var token: TokenData = grid[c.x][c.y] as TokenData
		if token == null or not token.is_scorable():
			continue
		snapshot.append({"family": token.family, "value": token.value})
	return snapshot


## Rangee du haut = ROWS - 1 (row 0 est le bas logique, destination de la
## gravite — meme convention que Ecume sur la rangee du bas).
func _top_row_occupied(grid: Array) -> bool:
	var top_row: int = GameRules.ROWS - 1
	for col in range(GameRules.COLS):
		if grid[col][top_row] != null:
			return true
	return false


## Construit la contribution multiplicative de CHAQUE badge individuellement
## (StringName id -> facteur), plutot qu'un seul "badge_mult" fondu — necessaire
## pour que la banniere de resolution puisse faire resoudre les Badges un par
## un, de gauche a droite (retour de playtest session 17 : impossible de voir
## qui a declenche quoi quand plusieurs Badges contribuent a la meme resolution).
## Couvre les 4 canaux multiplicatifs actionnables par Badge : rule_multipliers,
## global_multiplier, value_bonus_multipliers (par valeur de jeton, peut avoir
## des sources differentes selon la valeur presente dans CE groupe),
## scaling_mult_bonuses (session 17) et sheet_multiplier_bonus_contributions
## (par Partition, ex: "Refrain"). Les modifiers de cellule (Cellule Triple,
## Tranchee...) restent hors de cette attribution — ils vivent sur la grille,
## pas sur une resolution, et ont deja leur propre feedback visuel (bordures
## colorees), pas dans la banniere.
func _mult_contributions(cells: Array, grid: Array, context: RunContext, rule: StringName, sheet_name: StringName) -> Dictionary:
	var contributions: Dictionary = {}  # StringName source -> float (facteur du badge)

	# Chaque canal "keyed"/"flat" est deja garde par badge_id sur le RunContext
	# (session 18) — plus besoin de reconstituer l'attribution via un champ
	# _source separe, le dictionnaire EST l'attribution.
	var rule_sources: Dictionary = context.rule_multiplier_contributions.get(rule, {}) as Dictionary
	for source in rule_sources:
		if (source as StringName) == &"":
			continue
		var rule_source_mult: float = rule_sources[source] as float
		if rule_source_mult > 1.0:
			contributions[source] = rule_source_mult

	for source in context.global_multiplier_contributions:
		if (source as StringName) == &"":
			continue
		var global_source_mult: float = context.global_multiplier_contributions[source] as float
		if global_source_mult > 1.0:
			contributions[source] = global_source_mult

	var partial: Dictionary = {}  # StringName source -> float bonus (avant +1)
	for cell in cells:
		var c: Vector2i = cell as Vector2i
		var token: TokenData = grid[c.x][c.y] as TokenData
		if token == null or not token.is_scorable():
			continue
		var value_sources: Dictionary = context.value_bonus_multiplier_contributions.get(token.value, {}) as Dictionary
		for source in value_sources:
			if (source as StringName) == &"":
				continue
			partial[source] = (partial.get(source, 0.0) as float) + (value_sources[source] as float)
	for source in partial:
		contributions[source] = 1.0 + (partial[source] as float)

	for source in context.scaling_mult_bonuses:
		var b: float = context.scaling_mult_bonuses[source] as float
		if b > 0.0:
			contributions[source] = 1.0 + b

	var sheet_bonus_sources: Dictionary = context.sheet_multiplier_bonus_contributions.get(sheet_name, {}) as Dictionary
	for source in sheet_bonus_sources:
		if (source as StringName) == &"":
			continue
		var sb: float = sheet_bonus_sources[source] as float
		if sb > 0.0:
			contributions[source] = 1.0 + sb

	return contributions


## Attache au groupe la decomposition du score pour la banniere de resolution
## (GridVisual.ResolutionBanner) — n'influence jamais le score reellement
## calcule, qui reste le int() de la formule complete. raw_value = somme des
## valeurs des jetons SEULE (avant tout bonus de Badge) ; base_value = apres
## les bonus flat (retrigger/famille/paire/rangee du haut/scaling), c'est cette
## derniere qui entre dans la formule multipliee. badge_steps ordonne les
## contributions par ordre d'equipement (context.equipped_badges) plutot que
## de les fondre — chaque entree {label, kind: "flat"|"mult", amount} est
## jouee individuellement par la banniere, dans l'ordre des slots.
func _attach_breakdown(group: Dictionary, context: RunContext, raw_value: int, base_value: int, base_mult: float, flat_contributions: Dictionary, mult_contributions: Dictionary) -> void:
	var badge_steps: Array = []
	for badge in context.equipped_badges:
		var id: StringName = badge.id
		if flat_contributions.has(id):
			badge_steps.append({"source": id, "label": badge.label, "kind": "flat", "amount": flat_contributions[id]})
		if mult_contributions.has(id):
			badge_steps.append({"source": id, "label": badge.label, "kind": "mult", "amount": mult_contributions[id]})

	group["score_breakdown"] = {
		"label": _sheet_label(group.get("sheet_name", &"") as StringName, context),
		"raw_value": raw_value,
		"base_value": base_value,
		"base_mult": base_mult,
		"badge_steps": badge_steps,
	}


func _sheet_label(sheet_name: StringName, context: RunContext) -> String:
	for sheet in context.equipped_sheets:
		if sheet.sheet_name == sheet_name:
			return sheet.label
	return ""
