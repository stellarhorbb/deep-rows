class_name CascadeResolver
extends RefCounted

## Types d'evenements dans la timeline
enum EventType { GRAVITY, MATCH, REMOVE }


## Resout toutes les cascades sur la grille.
## Retourne une timeline d'evenements pour le visuel + le score total gagne.
func resolve(grid: Array, cols: int, rows: int, context: RunContext) -> Dictionary:
	var timeline: Array[Dictionary] = []
	var total_score: int = 0

	# Passe de gravite initiale (trous laisses par les specials)
	var initial_movements: Array[Dictionary] = GravitySystem.apply(grid, cols, rows)
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
			var group_score: int = _score_group(group, grid, cascade_level)
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
		var movements: Array[Dictionary] = GravitySystem.apply(grid, cols, rows)
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
func _score_group(group: Dictionary, grid: Array, cascade_level: int) -> int:
	var cascade_mult: float = pow(GameRules.CASCADE_MULTIPLIER_BASE, cascade_level)

	# Diamond : seul le jeton central est score (multiplicateur fixe du tag).
	if group["shape"] == &"diamond":
		var center: Vector2i = group["center"] as Vector2i
		var center_token: TokenData = grid[center.x][center.y] as TokenData
		if center_token == null or not center_token.is_scorable():
			return 0
		var tag_mult: float = group.get("score_multiplier", 4.0) as float
		return int(center_token.value * tag_mult * cascade_mult)

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

	return int(value_sum * shape_mult * cascade_mult)
