class_name PatternMatcher

## Axes de recherche : horizontal, vertical, diagonale NE, diagonale SE
const AXES: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(1, 1),
	Vector2i(1, -1),
]


## Trouve toutes les lignes droites de 3+ jetons scorables qui matchent.
## Retourne : [{ "cells": Array[Vector2i], "match_rule": StringName, "shape": &"line" }]
static func find_lines(grid: Array, cols: int, rows: int) -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	for axis in AXES:
		var dx: int = axis.x
		var dy: int = axis.y

		for rule in [&"family", &"value"]:
			for c in range(cols):
				for r in range(rows):
					var token: TokenData = grid[c][r] as TokenData
					if token == null or not token.is_scorable():
						continue

					# Skip si le predecesseur sur le meme axe matche deja (dedup)
					var pc: int = c - dx
					var pr: int = r - dy
					if pc >= 0 and pc < cols and pr >= 0 and pr < rows:
						var prev: TokenData = grid[pc][pr] as TokenData
						if prev != null and prev.is_scorable():
							if _tokens_match(prev, token, rule):
								continue

					# Walk forward
					var line: Array[Vector2i] = [Vector2i(c, r)]
					var nc: int = c + dx
					var nr: int = r + dy
					while nc >= 0 and nc < cols and nr >= 0 and nr < rows:
						var next: TokenData = grid[nc][nr] as TokenData
						if next == null or not next.is_scorable():
							break
						if not _tokens_match(next, token, rule):
							break
						line.append(Vector2i(nc, nr))
						nc += dx
						nr += dy

					if line.size() >= GameRules.MIN_MATCH_SIZE:
						results.append({
							"cells": line,
							"match_rule": rule,
							"shape": &"line",
						})

	return results


## Trouve tous les carres 2x2 de jetons scorables qui matchent.
## Retourne : [{ "cells": Array[Vector2i], "match_rule": StringName, "shape": &"square" }]
static func find_squares(grid: Array, cols: int, rows: int) -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	for c in range(cols - 1):
		for r in range(rows - 1):
			var cells: Array[Vector2i] = [
				Vector2i(c, r),
				Vector2i(c + 1, r),
				Vector2i(c, r + 1),
				Vector2i(c + 1, r + 1),
			]

			# Verifier que les 4 sont scorables
			var tokens: Array[TokenData] = []
			var all_scorable: bool = true
			for cell in cells:
				var token: TokenData = grid[cell.x][cell.y] as TokenData
				if token == null or not token.is_scorable():
					all_scorable = false
					break
				tokens.append(token)

			if not all_scorable:
				continue

			var ref: TokenData = tokens[0]

			for rule in [&"family", &"value"]:
				var all_match: bool = true
				for i in range(1, tokens.size()):
					if not _tokens_match(tokens[i], ref, rule):
						all_match = false
						break
				if all_match:
					results.append({
						"cells": cells,
						"match_rule": rule,
						"shape": &"square",
					})

	return results


## Trouve tous les diamonds de 4 rocks (forme losange autour d'une cellule centrale).
## Le centre est ignore (peut etre n'importe quel jeton).
## Retourne : [{ "cells": Array[Vector2i], "match_rule": &"rock", "shape": &"diamond" }]
static func find_diamonds(grid: Array, cols: int, rows: int) -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	for c in range(1, cols - 1):
		for r in range(1, rows - 1):
			var top: TokenData = grid[c][r - 1] as TokenData
			var bottom: TokenData = grid[c][r + 1] as TokenData
			var left: TokenData = grid[c - 1][r] as TokenData
			var right: TokenData = grid[c + 1][r] as TokenData
			if top == null or bottom == null or left == null or right == null:
				continue
			if top.kind != TokenData.Kind.ROCK:
				continue
			if bottom.kind != TokenData.Kind.ROCK:
				continue
			if left.kind != TokenData.Kind.ROCK:
				continue
			if right.kind != TokenData.Kind.ROCK:
				continue

			var cells: Array[Vector2i] = [
				Vector2i(c, r - 1),
				Vector2i(c - 1, r),
				Vector2i(c + 1, r),
				Vector2i(c, r + 1),
			]
			results.append({
				"cells": cells,
				"center": Vector2i(c, r),
				"match_rule": &"rock",
				"shape": &"diamond",
			})

	return results


## Trouve tous les groupes et filtre par les Pattern Tags actifs.
static func find_all(grid: Array, cols: int, rows: int, active_tags: Array[PatternData]) -> Array[Dictionary]:
	var all_groups: Array[Dictionary] = []
	all_groups.append_array(find_lines(grid, cols, rows))
	all_groups.append_array(find_squares(grid, cols, rows))
	all_groups.append_array(find_diamonds(grid, cols, rows))

	# Filtrage par Tags equipes (shape + rule + min_size)
	var filtered: Array[Dictionary] = []
	for group in all_groups:
		var cell_count: int = (group["cells"] as Array).size()
		for tag in active_tags:
			if tag.shape == group["shape"] and tag.rule == group["match_rule"] and cell_count >= tag.min_size:
				filtered.append(group)
				break

	return filtered


## Compare deux jetons selon une regle donnee.
static func _tokens_match(a: TokenData, b: TokenData, rule: StringName) -> bool:
	if rule == &"family":
		return a.family == b.family
	if rule == &"value":
		return a.value == b.value
	return false
