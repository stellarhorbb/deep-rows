class_name CascadeResolver
extends RefCounted

## Types d'evenements dans la timeline
enum EventType { GRAVITY, MATCH, REMOVE }


## Resout toutes les cascades sur la grille.
## Retourne une timeline d'evenements pour le visuel + le score total gagne.
func resolve(grid: Array, cols: int, rows: int, active_tags: Array[PatternData]) -> Dictionary:
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
		var groups: Array[Dictionary] = PatternMatcher.find_all(grid, cols, rows, active_tags)
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


## Calcule le score d'un groupe : somme des valeurs × multiplicateur forme × multiplicateur cascade.
func _score_group(group: Dictionary, grid: Array, cascade_level: int) -> int:
	var value_sum: int = 0
	for cell in group["cells"]:
		var token: TokenData = grid[cell.x][cell.y] as TokenData
		if token != null and token.is_scorable():
			value_sum += token.value

	# Diamond de rocks : le centre est resolu avec un multiplicateur x4.
	if group["shape"] == &"diamond":
		var center: Vector2i = group["center"] as Vector2i
		var center_token: TokenData = grid[center.x][center.y] as TokenData
		if center_token == null or not center_token.is_scorable():
			return 0
		var diamond_cascade_mult: float = pow(GameRules.CASCADE_MULTIPLIER_BASE, cascade_level)
		return int(center_token.value * GameRules.DIAMOND_MULTIPLIER * diamond_cascade_mult)

	var shape_mult: float = 0.0
	if group["shape"] == &"square":
		shape_mult = GameRules.SQUARE_MULTIPLIER
	else:
		shape_mult = GameRules.get_line_multiplier(group["cells"].size())

	var cascade_mult: float = pow(GameRules.CASCADE_MULTIPLIER_BASE, cascade_level)

	return int(value_sum * shape_mult * cascade_mult)
