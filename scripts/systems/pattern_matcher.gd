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

			if _all_families_distinct(tokens):
				results.append({
					"cells": cells,
					"match_rule": &"rainbow",
					"shape": &"square",
					"direction": &"any",
				})

	return results


## Trouve tous les plus (croix orthogonale : centre + haut/bas/gauche/droite,
## les 5 cellules doivent matcher, contrairement au diamond ou le centre est
## indifferent). Retourne : [{ "cells": Array[Vector2i] (5), "match_rule": &"family",
##                             "shape": &"plus", "direction": &"any" }]
static func find_plus(grid: Array, cols: int, rows: int) -> Array[Dictionary]:
	return _find_cross_shape(grid, cols, rows, [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)], &"plus")


## Trouve tous les cross (croix diagonale : centre + les 4 coins). Meme
## principe que plus mais sur les diagonales plutot que les orthogonales.
## Retourne : [{ "cells": Array[Vector2i] (5), "match_rule": &"family",
##               "shape": &"cross", "direction": &"any" }]
static func find_cross(grid: Array, cols: int, rows: int) -> Array[Dictionary]:
	return _find_cross_shape(grid, cols, rows, [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)], &"cross")


## Base commune a find_plus/find_cross : centre + 4 cellules aux offsets
## donnes, toutes scorables et de la meme famille (centre inclus).
static func _find_cross_shape(grid: Array, cols: int, rows: int, offsets: Array, shape: StringName) -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	for c in range(1, cols - 1):
		for r in range(1, rows - 1):
			var center: TokenData = grid[c][r] as TokenData
			if center == null or not center.is_scorable():
				continue

			var cells: Array[Vector2i] = [Vector2i(c, r)]
			var all_match: bool = true
			for offset in offsets:
				var o: Vector2i = offset as Vector2i
				var arm: TokenData = grid[c + o.x][r + o.y] as TokenData
				if arm == null or not arm.is_scorable() or not _tokens_match(arm, center, &"family"):
					all_match = false
					break
				cells.append(Vector2i(c + o.x, r + o.y))

			if all_match:
				results.append({
					"cells": cells,
					"match_rule": &"family",
					"shape": shape,
					"direction": &"any",
				})

	return results


## Trouve tous les rings (cadre 3x3 : les 8 cellules autour d'un centre,
## centre indifferent — le grand frere du diamond). Retourne :
## [{ "cells": Array[Vector2i] (8), "center": Vector2i, "match_rule": &"family",
##    "shape": &"ring", "direction": &"any" }]
static func find_ring(grid: Array, cols: int, rows: int) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var offsets: Array = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0),                   Vector2i(1, 0),
		Vector2i(-1, 1),  Vector2i(0, 1),  Vector2i(1, 1),
	]

	for c in range(1, cols - 1):
		for r in range(1, rows - 1):
			var tokens: Array[TokenData] = []
			var cells: Array[Vector2i] = []
			var all_scorable: bool = true
			for offset in offsets:
				var o: Vector2i = offset as Vector2i
				var cell: Vector2i = Vector2i(c + o.x, r + o.y)
				var token: TokenData = grid[cell.x][cell.y] as TokenData
				if token == null or not token.is_scorable():
					all_scorable = false
					break
				tokens.append(token)
				cells.append(cell)

			if not all_scorable:
				continue

			var ref: TokenData = tokens[0]
			var all_match: bool = true
			for i in range(1, tokens.size()):
				if not _tokens_match(tokens[i], ref, &"family"):
					all_match = false
					break

			if all_match:
				results.append({
					"cells": cells,
					"center": Vector2i(c, r),
					"match_rule": &"family",
					"shape": &"ring",
					"direction": &"any",
				})

	return results


## Trouve tous les tetromino T (4 cellules : une barre de 3 + un pied au
## centre, dans une des 4 orientations). Peu importe l'orientation, meme
## score — une seule orientation retenue par pivot pour eviter le
## sur-comptage quand un plus (5 cellules) contient plusieurs T valides a la fois.
## Retourne : [{ "cells": Array[Vector2i] (4), "match_rule": &"family",
##               "shape": &"t", "direction": &"any" }]
static func find_t(grid: Array, cols: int, rows: int) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var rotations: Array = [
		[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)],   # pied bas
		[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, -1)],  # pied haut
		[Vector2i(0, -1), Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0)],   # pied droite
		[Vector2i(0, -1), Vector2i(0, 0), Vector2i(0, 1), Vector2i(-1, 0)], # pied gauche
	]

	# Contrairement a plus/cross/ring (qui ont besoin d'une marge symetrique
	# des 2 cotes sur les 2 axes), chaque rotation du T n'a besoin de marge que
	# d'un seul cote — donc pas de range(1, cols-1) uniforme ici, on scanne
	# toute la grille et on verifie les bornes cellule par cellule.
	for c in range(cols):
		for r in range(rows):
			for rotation in rotations:
				var tokens: Array[TokenData] = []
				var cells: Array[Vector2i] = []
				var all_scorable: bool = true
				for offset in (rotation as Array):
					var o: Vector2i = offset as Vector2i
					var cell: Vector2i = Vector2i(c + o.x, r + o.y)
					if cell.x < 0 or cell.x >= cols or cell.y < 0 or cell.y >= rows:
						all_scorable = false
						break
					var token: TokenData = grid[cell.x][cell.y] as TokenData
					if token == null or not token.is_scorable():
						all_scorable = false
						break
					tokens.append(token)
					cells.append(cell)

				if not all_scorable:
					continue

				var ref: TokenData = tokens[0]
				var all_match: bool = true
				for i in range(1, tokens.size()):
					if not _tokens_match(tokens[i], ref, &"family"):
						all_match = false
						break

				if all_match:
					results.append({
						"cells": cells,
						"match_rule": &"family",
						"shape": &"t",
						"direction": &"any",
					})
					break  # une seule orientation retenue par pivot

	return results


## Trouve tous les diamonds (losange : haut/bas/gauche/droite autour d'un
## centre). Le centre peut etre n'importe quel jeton — il n'entre jamais dans
## la condition de match, seulement dans le scoring (cf. CascadeResolver,
## qui score le jeton central pour toute forme "diamond").
## Deux variantes : les 4 jetons du losange sont soit tous des Rocks, soit
## tous scorables et de la meme famille.
## Retourne : [{ "cells": Array[Vector2i], "center": Vector2i,
##               "match_rule": &"rock"|&"family", "shape": &"diamond", "direction": &"any" }]
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

			var cells: Array[Vector2i] = [
				Vector2i(c, r - 1),
				Vector2i(c - 1, r),
				Vector2i(c + 1, r),
				Vector2i(c, r + 1),
			]

			var all_rock: bool = top.kind == TokenData.Kind.ROCK and bottom.kind == TokenData.Kind.ROCK \
				and left.kind == TokenData.Kind.ROCK and right.kind == TokenData.Kind.ROCK
			if all_rock:
				results.append({
					"cells": cells,
					"center": Vector2i(c, r),
					"match_rule": &"rock",
					"shape": &"diamond",
					"direction": &"any",
				})
				continue

			var all_scorable: bool = top.is_scorable() and bottom.is_scorable() and left.is_scorable() and right.is_scorable()
			if all_scorable and top.family == bottom.family and top.family == left.family and top.family == right.family:
				results.append({
					"cells": cells,
					"center": Vector2i(c, r),
					"match_rule": &"family",
					"shape": &"diamond",
					"direction": &"any",
				})
				continue

			if all_scorable:
				var arms: Array[TokenData] = [top, bottom, left, right]
				if _all_families_distinct(arms):
					results.append({
						"cells": cells,
						"center": Vector2i(c, r),
						"match_rule": &"rainbow",
						"shape": &"diamond",
						"direction": &"any",
					})

	return results


## Trouve les Rainbow de Ligne : exactement FAMILY_COUNT jetons consecutifs
## sur un axe, tous de familles differentes. Fenetre fixe (pas d'extension
## incrementale comme find_lines) car la taille est plafonnee par le nombre
## de familles existantes — impossible d'aller au-dela sans repetition.
## Retourne : [{ "cells": Array[Vector2i], "match_rule": &"rainbow",
##               "shape": &"line", "direction": StringName }]
static func find_line_rainbow(grid: Array, cols: int, rows: int) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var window: int = GameRules.FAMILY_COUNT

	for axis_entry in AXES:
		var dx: int = (axis_entry[0] as Vector2i).x
		var dy: int = (axis_entry[0] as Vector2i).y
		var dir_name: StringName = axis_entry[1]

		for c in range(cols):
			for r in range(rows):
				var cells: Array[Vector2i] = []
				var tokens: Array[TokenData] = []
				var all_scorable: bool = true
				for i in range(window):
					var cell: Vector2i = Vector2i(c + dx * i, r + dy * i)
					if cell.x < 0 or cell.x >= cols or cell.y < 0 or cell.y >= rows:
						all_scorable = false
						break
					var token: TokenData = grid[cell.x][cell.y] as TokenData
					if token == null or not token.is_scorable():
						all_scorable = false
						break
					cells.append(cell)
					tokens.append(token)

				if all_scorable and _all_families_distinct(tokens):
					results.append({
						"cells": cells,
						"match_rule": &"rainbow",
						"shape": &"line",
						"direction": dir_name,
					})

	return results


## Trouve la sequence Fibonacci fixe (GameRules.FIBONACCI_SEQUENCE, 1,1,2,3),
## dans un sens ou dans l'autre le long de l'axe. Cible exacte, pas de fenetre
## generique — voir la discussion "Partitions chiffre" en session 14.
## Retourne : [{ "cells": Array[Vector2i], "match_rule": &"fibonacci",
##               "shape": &"line", "direction": StringName }]
static func find_fibonacci(grid: Array, cols: int, rows: int) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var sequence: Array[int] = GameRules.FIBONACCI_SEQUENCE
	var reversed_sequence: Array[int] = sequence.duplicate()
	reversed_sequence.reverse()
	var window: int = sequence.size()

	for axis_entry in AXES:
		var dx: int = (axis_entry[0] as Vector2i).x
		var dy: int = (axis_entry[0] as Vector2i).y
		var dir_name: StringName = axis_entry[1]

		for c in range(cols):
			for r in range(rows):
				var cells: Array[Vector2i] = []
				var values: Array[int] = []
				var all_scorable: bool = true
				for i in range(window):
					var cell: Vector2i = Vector2i(c + dx * i, r + dy * i)
					if cell.x < 0 or cell.x >= cols or cell.y < 0 or cell.y >= rows:
						all_scorable = false
						break
					var token: TokenData = grid[cell.x][cell.y] as TokenData
					if token == null or not token.is_scorable():
						all_scorable = false
						break
					cells.append(cell)
					values.append(token.value)

				if all_scorable and (values == sequence or values == reversed_sequence):
					results.append({
						"cells": cells,
						"match_rule": &"fibonacci",
						"shape": &"line",
						"direction": dir_name,
					})

	return results


## Trouve tous les groupes et filtre par les Pattern Tags equipes.
## Un groupe passe si au moins un tag matche : shape + rule + min_size + direction.
static func find_all(grid: Array, cols: int, rows: int, context: RunContext) -> Array[Dictionary]:
	var all_groups: Array[Dictionary] = []
	all_groups.append_array(find_lines(grid, cols, rows))
	all_groups.append_array(find_squares(grid, cols, rows))
	all_groups.append_array(find_diamonds(grid, cols, rows))
	all_groups.append_array(find_plus(grid, cols, rows))
	all_groups.append_array(find_cross(grid, cols, rows))
	all_groups.append_array(find_ring(grid, cols, rows))
	all_groups.append_array(find_t(grid, cols, rows))
	all_groups.append_array(find_line_rainbow(grid, cols, rows))
	all_groups.append_array(find_fibonacci(grid, cols, rows))

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


## Verifie qu'aucune famille n'apparait deux fois (utilise par Rainbow — le
## nombre de familles existantes plafonne la forme a une taille exacte).
static func _all_families_distinct(tokens: Array[TokenData]) -> bool:
	var seen: Dictionary = {}
	for token in tokens:
		if seen.has(token.family):
			return false
		seen[token.family] = true
	return true
