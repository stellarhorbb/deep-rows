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
		var groups: Array[Dictionary] = PatternMatcher.find_all(grid, cols, rows, context)
		if groups.size() == 0:
			break

		# Calculer le score de chaque groupe
		var scores: Array[int] = []
		var earned: int = 0
		for group in groups:
			var group_score: int = _score_group(group, grid, cascade_level, context)
			scores.append(group_score)
			earned += group_score

		# Collecter les cellules a supprimer (dedupliquees)
		var cells_to_remove: Dictionary = {}  # Vector2i -> true
		for group in groups:
			for cell in group["cells"]:
				cells_to_remove[cell] = true
			# Les diamonds detruisent aussi la cellule centrale
			if group["shape"] == &"diamond":
				cells_to_remove[group["center"]] = true
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
	var cascade_mult: float = pow(GameRules.CASCADE_MULTIPLIER_BASE, cascade_level)
	var rule: StringName = group.get("match_rule", &"") as StringName
	var rule_mult: float = rule_multipliers.get(rule, 1.0) as float
	var tag_name: StringName = group.get("tag_name", &"") as StringName
	var level_mult: float = tag_level_multipliers.get(tag_name, 1.0) as float

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

		if rule == &"rock":
			var center: Vector2i = group["center"] as Vector2i
			var center_token: TokenData = grid[center.x][center.y] as TokenData
			if center_token == null or not center_token.is_scorable():
				return 0
			base_value = center_token.value
			scored_cells = [center]
		else:
			for cell in group["cells"]:
				var token: TokenData = grid[cell.x][cell.y] as TokenData
				if token != null and token.is_scorable():
					base_value += token.value
			scored_cells = group["cells"]

		var diamond_mod_mult: float = _modifier_multiplier(scored_cells, grid_modifiers)
		return int(base_value * tag_mult * cascade_mult * diamond_mod_mult * rule_mult * level_mult)

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
	return int(value_sum * shape_mult * cascade_mult * mod_mult * rule_mult * level_mult)


## Chaque cellule modifiee dans la liste multiplie le total par son coefficient (cumulatif).
func _modifier_multiplier(cells: Array, grid_modifiers: Dictionary) -> float:
	if grid_modifiers.is_empty():
		return 1.0
	var mult: float = 1.0
	for cell in cells:
		var key: Vector2i = cell as Vector2i
		var type: StringName = grid_modifiers.get(key, &"") as StringName
		if type != &"":
			mult *= GameRules.get_modifier_multiplier(type)
	return mult
