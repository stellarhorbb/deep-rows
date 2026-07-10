class_name CascadeResolver
extends RefCounted

## Types d'evenements dans la timeline
enum EventType { GRAVITY, MATCH, REMOVE }


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
		var candidates: Array[Dictionary] = PatternMatcher.find_all(grid, cols, rows, context)
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

		# Collecter les cellules a supprimer (dedupliquees, deja garanties
		# sans chevauchement par le filtrage ci-dessus)
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
				for cell in group["cells"]:
					cells_to_remove[cell] = true
			# Diamond Rock "recolte" son centre : il est scorable (voir
			# _score_group) et consomme avec le reste du losange. Les autres
			# formes a centre indifferent (diamond family/rainbow, ring) ne
			# touchent jamais au centre — il n'entrait pas dans le match, il ne
			# doit pas etre efface non plus : il reste en place et tombe
			# normalement a la gravite qui suit si sa colonne s'est videe.
			if group.has("center") and group.get("match_rule") == &"rock":
				cells_to_remove[group["center"] as Vector2i] = true
		var removed_cells: Array[Vector2i] = []
		for cell in cells_to_remove.keys():
			removed_cells.append(cell as Vector2i)

		# Evenement match
		timeline.append({
			"type": EventType.MATCH,
			"groups": groups,
			"scores": scores,
			"cascade_level": cascade_level,
			"total_earned": earned,
			"combo_bonus": combo_bonus,
		})

		# Supprimer les jetons
		for cell in removed_cells:
			grid[cell.x][cell.y] = null

		timeline.append({
			"type": EventType.REMOVE,
			"cells": removed_cells,
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
## Lines : multiplicateur = direction du match (v=x1, h=x1.5, d=x2).
## Autres formes : multiplicateur fixe defini sur le tag.
## Cellules modifiees : chaque cellule concernee multiplie le total par son coef (HALF/BOOST/DOUBLE/TRIPLE).
## rule_multipliers : multiplicateur applique selon la rule du pattern (ex: "family" x2 via badge).
## tag_level_multipliers : multiplicateur selon le niveau de la Partition qui a matche (level up).
func _score_group(group: Dictionary, grid: Array, cascade_level: int, context: RunContext) -> int:
	var grid_modifiers: Dictionary = context.grid_modifiers
	var rule_multipliers: Dictionary = context.rule_multipliers
	var tag_level_multipliers: Dictionary = context.tag_level_multipliers
	var value_bonus_multipliers: Dictionary = context.value_bonus_multipliers
	var cascade_mult: float = pow(GameRules.CASCADE_MULTIPLIER_BASE, cascade_level)
	var rule: StringName = group.get("match_rule", &"") as StringName
	var rule_mult: float = rule_multipliers.get(rule, 1.0) as float
	var tag_name: StringName = group.get("tag_name", &"") as StringName
	var level_mult: float = tag_level_multipliers.get(tag_name, 1.0) as float
	var global_mult: float = context.global_multiplier

	# Diamond : le centre n'entre jamais dans la condition de match (voir
	# PatternMatcher.find_diamonds), mais son role dans le SCORE depend de la
	# rule. Rock : les 4 jetons du losange sont des rocks, sans valeur — c'est
	# le centre qui est "recolte", il doit donc etre scorable. Family (et
	# futures rules) : les 4 jetons du losange sont deja garantis scorables
	# par le match, le centre est vraiment ignore — on somme les 4 jetons,
	# comme une ligne ou un carre.
	if group["shape"] == &"diamond":
		var tag_mult: float = group.get("score_multiplier", 4.0) as float
		var base_value: int = 0
		var scored_cells: Array = []

		var rock_roll: int = -1
		if rule == &"rock":
			var center: Vector2i = group["center"] as Vector2i
			var center_token: TokenData = grid[center.x][center.y] as TokenData
			if center_token == null or not center_token.is_scorable():
				return 0
			rock_roll = randi_range(GameRules.DIAMOND_ROCK_ROLL_MIN, GameRules.DIAMOND_ROCK_ROLL_MAX)
			base_value = center_token.value + rock_roll
			scored_cells = [center]
		else:
			for cell in group["cells"]:
				var token: TokenData = grid[cell.x][cell.y] as TokenData
				if token != null and token.is_scorable():
					base_value += token.value
			scored_cells = group["cells"]

		var diamond_mod_mult: float = _modifier_multiplier(scored_cells, grid_modifiers)
		var diamond_value_bonus_mult: float = _value_bonus_multiplier(scored_cells, grid, value_bonus_multipliers)
		# cascade_mult exclu du breakdown affiche : la banniere de resolution
		# lui dedie sa propre annonce (voir GridVisual._animate_match), pas
		# noye dans le MULTI generique. Le score reel l'inclut toujours.
		var diamond_base_mult: float = tag_mult * diamond_mod_mult * level_mult
		_attach_breakdown(group, context, base_value, diamond_base_mult, rule_mult, global_mult, diamond_value_bonus_mult, rule, scored_cells, grid)
		if rock_roll >= 0:
			(group["score_breakdown"] as Dictionary)["roll"] = rock_roll
		return int(base_value * tag_mult * cascade_mult * diamond_mod_mult * rule_mult * level_mult * global_mult * diamond_value_bonus_mult)

	var value_sum: int = 0
	for cell in group["cells"]:
		var token: TokenData = grid[cell.x][cell.y] as TokenData
		if token != null and token.is_scorable():
			value_sum += token.value

	var shape_mult: float
	if group["shape"] == &"line":
		# Les lignes sont recompensees selon leur direction de resolution
		var dir: StringName = group.get("direction", &"vertical") as StringName
		shape_mult = GameRules.get_direction_multiplier(dir)
	else:
		# Carres et autres : multiplicateur fixe du tag
		shape_mult = group.get("score_multiplier", 1.0) as float

	var mod_mult: float = _modifier_multiplier(group["cells"], grid_modifiers)
	var value_bonus_mult: float = _value_bonus_multiplier(group["cells"], grid, value_bonus_multipliers)
	# cascade_mult exclu du breakdown affiche, meme raison que la branche diamond.
	var base_mult: float = shape_mult * mod_mult * level_mult
	_attach_breakdown(group, context, value_sum, base_mult, rule_mult, global_mult, value_bonus_mult, rule, group["cells"], grid)
	return int(value_sum * shape_mult * cascade_mult * mod_mult * rule_mult * level_mult * global_mult * value_bonus_mult)


## Chaque cellule modifiee dans la liste multiplie le total par son coefficient
## (cumulatif). Une meme case peut porter plusieurs types empiles (ex: Tranchee
## + Bord a Bord, ou Cellule Triple par-dessus un badge colonne) : tous ses
## types se multiplient entre eux plutot que de s'ecraser.
func _modifier_multiplier(cells: Array, grid_modifiers: Dictionary) -> float:
	if grid_modifiers.is_empty():
		return 1.0
	var mult: float = 1.0
	for cell in cells:
		var key: Vector2i = cell as Vector2i
		var types: Array = grid_modifiers.get(key, []) as Array
		for type in types:
			mult *= GameRules.get_modifier_multiplier(type as StringName)
	return mult


## Chaque jeton scorable de la figure dont la valeur a un bonus enregistre
## ajoute ce bonus au multiplicateur (additif, pas multiplicatif entre jetons :
## 2 jetons a +0.5 donnent x2.0, pas x2.25).
func _value_bonus_multiplier(cells: Array, grid: Array, value_bonus_multipliers: Dictionary) -> float:
	if value_bonus_multipliers.is_empty():
		return 1.0
	var mult: float = 1.0
	for cell in cells:
		var c: Vector2i = cell as Vector2i
		var token: TokenData = grid[c.x][c.y] as TokenData
		if token == null or not token.is_scorable():
			continue
		mult += value_bonus_multipliers.get(token.value, 0.0) as float
	return mult


## Attache au groupe la decomposition du score pour la banniere de resolution
## (GridVisual.ResolutionBanner) — n'influence jamais le score reellement
## calcule, qui reste le int() de la formule complete. base_mult regroupe tout
## ce qui est intrinseque a la figure (forme/direction, cascade, niveau de
## Partition, modifiers de cellule) ; badge_mult regroupe ce qui vient d'un
## Badge et peut donc etre attribue (rule/global/value_bonus). Les modifiers
## de cellule contribuent a base_mult sans attribution precise — savoir quel
## Badge a pose quelle case demanderait de tracer la provenance de
## grid_modifiers, hors scope pour l'instant.
func _attach_breakdown(group: Dictionary, context: RunContext, base_value: int, base_mult: float, rule_mult: float, global_mult: float, value_bonus_mult: float, rule: StringName, value_bonus_cells: Array, grid: Array) -> void:
	var sources: Dictionary = {}  # StringName -> true, utilise comme un set

	if rule_mult > 1.0:
		var rule_source: StringName = context.rule_multiplier_sources.get(rule, &"") as StringName
		if rule_source != &"":
			sources[rule_source] = true

	if global_mult > 1.0 and context.global_multiplier_source != &"":
		sources[context.global_multiplier_source] = true

	if value_bonus_mult > 1.0:
		for cell in value_bonus_cells:
			var c: Vector2i = cell as Vector2i
			var token: TokenData = grid[c.x][c.y] as TokenData
			if token == null or not token.is_scorable():
				continue
			var value_source: StringName = context.value_bonus_multiplier_sources.get(token.value, &"") as StringName
			if value_source != &"":
				sources[value_source] = true

	group["score_breakdown"] = {
		"label": _tag_label(group.get("tag_name", &"") as StringName, context),
		"base_value": base_value,
		"base_mult": base_mult,
		"badge_mult": rule_mult * global_mult * value_bonus_mult,
		"badge_sources": sources.keys(),
	}


func _tag_label(tag_name: StringName, context: RunContext) -> String:
	for tag in context.equipped_tags:
		if tag.tag_name == tag_name:
			return tag.label
	return ""
