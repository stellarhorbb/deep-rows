class_name PatternMatcher

## Axes de recherche avec leur label de direction.
## Vertical est inclus pour la completude du scan, mais aucun tag ne le cible.
const AXES: Array = [
	[Vector2i(1, 0),  &"horizontal"],
	[Vector2i(0, 1),  &"vertical"],
	[Vector2i(1, 1),  &"diagonal"],
	[Vector2i(1, -1), &"diagonal"],
]


## Trouve toutes les lignes droites de 3+ jetons scorables.
## Retourne : [{ "cells": Array[Vector2i], "match_rule": StringName,
##               "shape": &"line", "direction": StringName }]
static func find_lines(grid: Array, cols: int, rows: int) -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	for axis_entry in AXES:
		var dx: int = (axis_entry[0] as Vector2i).x
		var dy: int = (axis_entry[0] as Vector2i).y
		var dir_name: StringName = axis_entry[1]

		for rule in [&"family", &"value", &"suite"]:
			for c in range(cols):
				for r in range(rows):
					var token: TokenData = grid[c][r] as TokenData
					if token == null or not token.is_scorable():
						continue

					# Dedup : sauter si le predecesseur sur le meme axe prolonge deja
					# cette sequence (la ligne sera trouvee depuis son vrai debut).
					var pc: int = c - dx
					var pr: int = r - dy
					if pc >= 0 and pc < cols and pr >= 0 and pr < rows:
						var prev_t: TokenData = grid[pc][pr] as TokenData
						if prev_t != null and prev_t.is_scorable() and _can_extend(token, prev_t, rule):
							continue

					# Marche en avant
					var line: Array[Vector2i] = [Vector2i(c, r)]
					var prev: TokenData = token
					var suite_step: int = 0   # direction numerique de la suite (0 = pas encore fixee)

					var nc: int = c + dx
					var nr: int = r + dy
					while nc >= 0 and nc < cols and nr >= 0 and nr < rows:
						var nxt: TokenData = grid[nc][nr] as TokenData
						if nxt == null or not nxt.is_scorable():
							break

						if rule == &"suite":
							var delta: int = nxt.value - prev.value
							if suite_step == 0:
								if abs(delta) != 1:
									break
								suite_step = delta
							elif delta != suite_step:
								break
						elif not _tokens_match(nxt, prev, rule):
							break

						line.append(Vector2i(nc, nr))
						prev = nxt
						nc += dx
						nr += dy

					if line.size() >= GameRules.MIN_MATCH_SIZE:
						results.append({
							"cells": line,
							"match_rule": rule,
							"shape": &"line",
							"direction": dir_name,
						})

	return results


## Trouve tous les carres 2x2 de jetons scorables qui matchent.
## Retourne : [{ "cells": Array[Vector2i], "match_rule": StringName,
##               "shape": &"square", "direction": &"any" }]
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
						"direction": &"any",
					})

	return results


## Trouve tous les diamonds de 4 rocks (losange : haut/bas/gauche/droite autour d'un centre).
## Le centre peut etre n'importe quel jeton.
## Retourne : [{ "cells": Array[Vector2i], "center": Vector2i,
##               "match_rule": &"rock", "shape": &"diamond", "direction": &"any" }]
static func find_diamonds(grid: Array, cols: int, rows: int) -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	for c in range(1, cols - 1):
		for r in range(1, rows - 1):
			var top: TokenData    = grid[c][r - 1] as TokenData
			var bottom: TokenData = grid[c][r + 1] as TokenData
			var left: TokenData   = grid[c - 1][r] as TokenData
			var right: TokenData  = grid[c + 1][r] as TokenData
			if top == null or bottom == null or left == null or right == null:
				continue
			if top.kind    != TokenData.Kind.ROCK: continue
			if bottom.kind != TokenData.Kind.ROCK: continue
			if left.kind   != TokenData.Kind.ROCK: continue
			if right.kind  != TokenData.Kind.ROCK: continue

			results.append({
				"cells": [
					Vector2i(c, r - 1),
					Vector2i(c - 1, r),
					Vector2i(c + 1, r),
					Vector2i(c, r + 1),
				] as Array[Vector2i],
				"center": Vector2i(c, r),
				"match_rule": &"rock",
				"shape": &"diamond",
				"direction": &"any",
			})

	return results


## Trouve tous les groupes et filtre par les Pattern Tags equipes.
## Un groupe passe si au moins un tag matche : shape + rule + min_size + direction.
static func find_all(grid: Array, cols: int, rows: int, context: RunContext) -> Array[Dictionary]:
	var all_groups: Array[Dictionary] = []
	all_groups.append_array(find_lines(grid, cols, rows))
	all_groups.append_array(find_squares(grid, cols, rows))
	all_groups.append_array(find_diamonds(grid, cols, rows))

	var filtered: Array[Dictionary] = []
	for group in all_groups:
		var cell_count: int = (group["cells"] as Array).size()
		var group_dir: StringName = group.get("direction", &"any")

		for tag in context.equipped_tags:
			if tag.shape != group["shape"]:
				continue
			if tag.rule != group["match_rule"]:
				continue
			if cell_count < tag.min_size:
				continue
			# Direction : &"any" cote tag = accepte tout.
			# Sinon les directions doivent correspondre.
			if tag.direction != &"any" and group_dir != &"any" and tag.direction != group_dir:
				continue
			# Enrichir le groupe avec les infos du tag qui l'a valide
			var enriched: Dictionary = group.duplicate()
			enriched["score_multiplier"] = tag.score_multiplier
			enriched["tag_name"] = tag.tag_name
			filtered.append(enriched)
			break

	return filtered


## Verifie si `token` peut prolonger une sequence qui se termine par `prev`.
## Utilise pour le dedup : si le predecesseur sur l'axe peut deja etendre la sequence,
## on ne demarre pas une nouvelle depuis la cellule courante.
static func _can_extend(token: TokenData, prev: TokenData, rule: StringName) -> bool:
	if rule == &"suite":
		return abs(token.value - prev.value) == 1
	return _tokens_match(token, prev, rule)


## Compare deux jetons selon une regle.
static func _tokens_match(a: TokenData, b: TokenData, rule: StringName) -> bool:
	if rule == &"family":
		return a.family == b.family
	if rule == &"value":
		return a.value == b.value
	return false
