class_name SheetMatcher

## Axes de recherche avec leur label de direction.
## Vertical est inclus pour la completude du scan, mais aucun sheet ne le cible.
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

		for rule in [&"family", &"value", &"suite", &"minima", &"maxima"]:
			for c in range(cols):
				for r in range(rows):
					var token: TokenData = grid[c][r] as TokenData
					if token == null or not token.is_scorable():
						continue

					# Le jeton de depart doit lui-meme qualifier pour minima/maxima —
					# sinon la marche en avant (ci-dessous) ne verifie le seuil que sur
					# les jetons ajoutes APRES lui (nxt), jamais sur le premier. Bug
					# corrige en session 23 : un 3 en tete de sequence, suivi de vrais
					# jetons <= MINIMA_MAX_VALUE, se faisait inclure dans le match.
					if rule == &"minima" and token.value > GameRules.MINIMA_MAX_VALUE:
						continue
					if rule == &"maxima" and token.value < GameRules.MAXIMA_MIN_VALUE:
						continue

					# Dedup : sauter si le predecesseur sur le meme axe prolonge deja
					# cette sequence (la ligne sera trouvee depuis son vrai debut).
					# Exclu pour "suite" (session 18, fix bug) : une suite peut changer
					# de sens (ex: colonne 3,4,3,2 — un pic a 4). Le predecesseur "3"
					# peut etendre vers "4", mais la vraie suite a decouvrir part du
					# pic et redescend (4,3,2), dans le sens INVERSE — sauter cette
					# cellule comme depart l'aurait rendue introuvable. Les doublons
					# resultants (ex: sous-groupe [3,4] retrouve en plus de [4,3,2])
					# sont deja geres par la resolution en aval (sous-ensemble strict
					# rejete, chevauchement reel traite comme Double Partition).
					if rule != &"suite":
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
						elif rule == &"minima":
							if nxt.value > GameRules.MINIMA_MAX_VALUE:
								break
						elif rule == &"maxima":
							if nxt.value < GameRules.MAXIMA_MIN_VALUE:
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
				# Le centre est "recolte" (voir CascadeResolver._score_group) : il
				# doit etre scorable, sinon ce n'est pas encore un match valide —
				# sans ce garde-fou, une Entity/un autre Rock/une case vide au
				# centre consommait quand meme les 4 rocks pour 0 point.
				var center_token: TokenData = grid[c][r] as TokenData
				if center_token != null and center_token.is_scorable():
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


## Trouve les 2 coins inferieurs de la grille s'ils sont scorables et de meme
## famille (legendaire "Lost Corners", session 20). Row 0 = bas logique, meme
## convention que le reste du fichier (voir find_diamonds). Contrairement a
## toutes les autres formes, taille fixe a 2 cellules — le trigger reste facile
## a declencher volontairement : la puissance de cette legendaire vient de son
## multiplicateur dynamique (somme de la ligne du bas, voir CascadeResolver),
## pas de la difficulte de la figure.
## Retourne : [{ "cells": Array[Vector2i] (2), "match_rule": &"family",
##               "shape": &"corners", "direction": &"any" }]
static func find_bottom_corners(grid: Array, cols: int, _rows: int) -> Array[Dictionary]:
	var bottom_row: int = 0
	var left: TokenData = grid[0][bottom_row] as TokenData
	var right: TokenData = grid[cols - 1][bottom_row] as TokenData
	if left == null or not left.is_scorable():
		return []
	if right == null or not right.is_scorable():
		return []
	if left.family != right.family:
		return []
	return [{
		"cells": [Vector2i(0, bottom_row), Vector2i(cols - 1, bottom_row)],
		"match_rule": &"family",
		"shape": &"corners",
		"direction": &"any",
	}]


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


## Toutes les fenetres de longueur entre min_window et max_window au sein
## d'une suite de reference — precalculees une fois. Partage par Fibonacci
## (min_window == max_window == FIBONACCI_WINDOW_SIZE, une seule longueur) et
## Nombres premiers (min_window < max_window, plusieurs longueurs valides —
## session 19).
static func _sequence_windows(sequence: Array[int], min_window: int, max_window: int) -> Array[Array]:
	var windows: Array[Array] = []
	for length in range(min_window, max_window + 1):
		for start in range(sequence.size() - length + 1):
			windows.append(sequence.slice(start, start + length))
	return windows


## Trouve n'importe quel alignement qui matche une des fenetres pre-calculees
## (voir _sequence_windows), dans un sens ou dans l'autre le long de l'axe.
## Partage par Fibonacci et Nombres premiers (session 19) — meme mecanique,
## seule la suite de reference et la fenetre min/max changent.
## Retourne : [{ "cells": Array[Vector2i], "match_rule": rule_name,
##               "shape": &"line", "direction": StringName }]
static func _find_sequence_matches(grid: Array, cols: int, rows: int, windows: Array[Array], rule_name: StringName) -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	for axis_entry in AXES:
		var dx: int = (axis_entry[0] as Vector2i).x
		var dy: int = (axis_entry[0] as Vector2i).y
		var dir_name: StringName = axis_entry[1]

		for candidate in windows:
			var window: int = candidate.size()
			var reversed_candidate: Array = candidate.duplicate()
			reversed_candidate.reverse()

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

					if all_scorable and (values == candidate or values == reversed_candidate):
						results.append({
							"cells": cells,
							"match_rule": rule_name,
							"shape": &"line",
							"direction": dir_name,
						})

	return results


## Fenetre fixe unique (FIBONACCI_WINDOW_SIZE) au sein de FIBONACCI_SEQUENCE
## (1,1,2,3,5,8) — pas seulement les 4 premiers termes (session 19, voir la
## discussion "Partitions chiffre" en session 14).
static func find_fibonacci(grid: Array, cols: int, rows: int) -> Array[Dictionary]:
	var windows: Array[Array] = _sequence_windows(GameRules.FIBONACCI_SEQUENCE, GameRules.FIBONACCI_WINDOW_SIZE, GameRules.FIBONACCI_WINDOW_SIZE)
	return _find_sequence_matches(grid, cols, rows, windows, &"fibonacci")


## Fenetre minimale PRIME_MIN_WINDOW (pas fixe, contrairement a Fibonacci) au
## sein de PRIME_SEQUENCE (2,3,5,7) — session 19.
static func find_primes(grid: Array, cols: int, rows: int) -> Array[Dictionary]:
	var windows: Array[Array] = _sequence_windows(GameRules.PRIME_SEQUENCE, GameRules.PRIME_MIN_WINDOW, GameRules.PRIME_SEQUENCE.size())
	return _find_sequence_matches(grid, cols, rows, windows, &"prime")


## Skull Line 4 (tiroir rare/signature, session "Vague 3") : 4+ entity-skulls
## consecutifs sur un axe -- detecteur dedie (les entity-skulls ne sont
## jamais scorables, donc jamais consideres par find_lines/_tokens_match).
## Meme dedup que find_lines : sauter une cellule de depart si son
## predecesseur sur l'axe prolonge deja la meme sequence.
static func find_skull_line(grid: Array, cols: int, rows: int) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for axis_entry in AXES:
		var dx: int = (axis_entry[0] as Vector2i).x
		var dy: int = (axis_entry[0] as Vector2i).y
		var dir_name: StringName = axis_entry[1]
		for c in range(cols):
			for r in range(rows):
				var token: TokenData = grid[c][r] as TokenData
				if token == null or token.kind != TokenData.Kind.ENTITY:
					continue
				var pc: int = c - dx
				var pr: int = r - dy
				if pc >= 0 and pc < cols and pr >= 0 and pr < rows:
					var prev_t: TokenData = grid[pc][pr] as TokenData
					if prev_t != null and prev_t.kind == TokenData.Kind.ENTITY:
						continue
				var line: Array[Vector2i] = [Vector2i(c, r)]
				var nc: int = c + dx
				var nr: int = r + dy
				while nc >= 0 and nc < cols and nr >= 0 and nr < rows:
					var nt: TokenData = grid[nc][nr] as TokenData
					if nt == null or nt.kind != TokenData.Kind.ENTITY:
						break
					line.append(Vector2i(nc, nr))
					nc += dx
					nr += dy
				if line.size() >= 4:
					results.append({
						"cells": line,
						"match_rule": &"skull_line",
						"shape": &"skull_line",
						"direction": dir_name,
					})
	return results


## Shadow Dance (tiroir rare/signature, session "Vague 3") : alterne 4
## cellules X/Entity/X/Entity sur un axe (X = meme famille, n'importe quelle
## valeur) -- accepte les deux lectures (X en premier ou Entity en premier),
## la meme ligne physique lue depuis l'autre bout doit rester valide.
static func find_shadow_dance(grid: Array, cols: int, rows: int) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for axis_entry in AXES:
		var dx: int = (axis_entry[0] as Vector2i).x
		var dy: int = (axis_entry[0] as Vector2i).y
		var dir_name: StringName = axis_entry[1]
		for c in range(cols):
			for r in range(rows):
				var cells: Array[Vector2i] = []
				var tokens: Array[TokenData] = []
				var in_bounds: bool = true
				for i in range(4):
					var cell: Vector2i = Vector2i(c + dx * i, r + dy * i)
					if cell.x < 0 or cell.x >= cols or cell.y < 0 or cell.y >= rows:
						in_bounds = false
						break
					var token: TokenData = grid[cell.x][cell.y] as TokenData
					if token == null:
						in_bounds = false
						break
					cells.append(cell)
					tokens.append(token)
				if not in_bounds:
					continue
				var pattern_x_first: bool = tokens[1].kind == TokenData.Kind.ENTITY and tokens[3].kind == TokenData.Kind.ENTITY \
					and tokens[0].is_scorable() and tokens[2].is_scorable() and tokens[0].family == tokens[2].family
				var pattern_entity_first: bool = tokens[0].kind == TokenData.Kind.ENTITY and tokens[2].kind == TokenData.Kind.ENTITY \
					and tokens[1].is_scorable() and tokens[3].is_scorable() and tokens[1].family == tokens[3].family
				if not pattern_x_first and not pattern_entity_first:
					continue
				results.append({
					"cells": cells,
					"match_rule": &"shadow_dance",
					"shape": &"shadow_dance",
					"direction": dir_name,
				})
	return results


## Black Hole (tiroir rare/signature, session "Vague 3") : losange autour
## d'un centre qui est un VRAI trou de la grille cabossee (pas juste une
## case inoccupee) -- seul detecteur du jeu a avoir besoin de `holes`, voir
## find_all/CascadeResolver.resolve. Les 4 bras scorent leur vraie valeur
## (pas de "recolte" comme Diamond Rock, le centre n'est pas un jeton).
static func find_black_hole(grid: Array, cols: int, rows: int, holes: Dictionary) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for c in range(1, cols - 1):
		for r in range(1, rows - 1):
			var center: Vector2i = Vector2i(c, r)
			if not holes.has(center):
				continue
			var top: TokenData = grid[c][r - 1] as TokenData
			var bottom: TokenData = grid[c][r + 1] as TokenData
			var left: TokenData = grid[c - 1][r] as TokenData
			var right: TokenData = grid[c + 1][r] as TokenData
			if top == null or bottom == null or left == null or right == null:
				continue
			if not (top.is_scorable() and bottom.is_scorable() and left.is_scorable() and right.is_scorable()):
				continue
			results.append({
				"cells": [Vector2i(c, r - 1), Vector2i(c - 1, r), Vector2i(c + 1, r), Vector2i(c, r + 1)],
				"match_rule": &"black_hole",
				"shape": &"black_hole",
				"direction": &"any",
			})
	return results


## Wedding (tiroir rare/signature figures, session "Vague 2") : Roi +
## Reine sur deux cases orthogonalement adjacentes -- detecteur dedie, pas
## une forme generique (meme esprit que Diamond Rock). Ne double-compte pas
## la meme paire (ne regarde que droite/bas depuis chaque cellule).
static func find_wedding(grid: Array, cols: int, rows: int) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var directions: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1)]
	var queen_value: int = GameRules.FACE_CARD_VALUES[2]  # Reine
	var king_value: int = GameRules.FACE_CARD_VALUES[3]   # Roi
	for c in range(cols):
		for r in range(rows):
			var token: TokenData = grid[c][r] as TokenData
			if token == null or not token.is_scorable():
				continue
			if token.value != queen_value and token.value != king_value:
				continue
			for dir in directions:
				var nc: int = c + dir.x
				var nr: int = r + dir.y
				if nc < 0 or nc >= cols or nr < 0 or nr >= rows:
					continue
				var neighbor: TokenData = grid[nc][nr] as TokenData
				if neighbor == null or not neighbor.is_scorable():
					continue
				var pair_values: Array[int] = [token.value, neighbor.value]
				pair_values.sort()
				if pair_values != [queen_value, king_value]:
					continue
				results.append({
					"cells": [Vector2i(c, r), Vector2i(nc, nr)],
					"match_rule": &"faces",
					"shape": &"wedding",
					"direction": &"any",
				})
	return results


## Royal Court (tiroir rare/signature figures, session "Vague 2") : meme
## mecanique que Fibonacci/Nombres premiers (_find_sequence_matches),
## fenetre fixe unique -- les 4 figures alignees dans l'ordre J-C-Q-K,
## n'importe quel axe/sens (GameRules.FACE_CARD_VALUES est deja dans cet
## ordre).
static func find_royal_court(grid: Array, cols: int, rows: int) -> Array[Dictionary]:
	return _find_sequence_matches(grid, cols, rows, [GameRules.FACE_CARD_VALUES], &"royal_court")


## 777/9999 (tiroir rare/signature, session "Vague 1") : meme mecanique que
## Fibonacci/Nombres premiers (_find_sequence_matches), fenetre fixe unique
## d'une valeur repetee plutot qu'une suite -- 3 jetons de valeur 7 (777) ou
## 4 jetons de valeur 9 (9999), n'importe quel axe.
static func find_jackpot_777(grid: Array, cols: int, rows: int) -> Array[Dictionary]:
	return _find_sequence_matches(grid, cols, rows, [GameRules.JACKPOT_777_SEQUENCE], &"jackpot_777")


static func find_jackpot_9999(grid: Array, cols: int, rows: int) -> Array[Dictionary]:
	return _find_sequence_matches(grid, cols, rows, [GameRules.JACKPOT_9999_SEQUENCE], &"jackpot_9999")


## Trouve tous les groupes et filtre par les Sheets equipees.
## Un groupe passe si au moins un sheet matche : shape + rule + min_size + direction.
static func find_all(grid: Array, cols: int, rows: int, context: RunContext, holes: Dictionary = {}) -> Array[Dictionary]:
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
	all_groups.append_array(find_primes(grid, cols, rows))
	all_groups.append_array(find_jackpot_777(grid, cols, rows))
	all_groups.append_array(find_jackpot_9999(grid, cols, rows))
	all_groups.append_array(find_wedding(grid, cols, rows))
	all_groups.append_array(find_royal_court(grid, cols, rows))
	all_groups.append_array(find_skull_line(grid, cols, rows))
	all_groups.append_array(find_shadow_dance(grid, cols, rows))
	all_groups.append_array(find_black_hole(grid, cols, rows, holes))
	all_groups.append_array(find_bottom_corners(grid, cols, rows))

	# Legendaires en premier (session 20) : quand un sheet legendaire partage
	# exactement le meme shape+rule qu'un sheet de base (ex: Royal Square et
	# Square Family, tous deux square+family), le "break" ci-dessous ne doit
	# jamais dependre de l'ordre d'equipement des slots — la legendaire doit
	# toujours capter son propre match. sort_custom est stable, l'ordre relatif
	# entre deux legendaires (ou deux sheets normaux) ne change pas.
	var equipped_sheets: Array[SheetData] = context.equipped_sheets.duplicate()
	equipped_sheets.sort_custom(func(a: SheetData, b: SheetData) -> bool:
		return a.is_legendary and not b.is_legendary
	)

	var filtered: Array[Dictionary] = []
	for group in all_groups:
		var cell_count: int = (group["cells"] as Array).size()
		var group_dir: StringName = group.get("direction", &"any")

		for sheet in equipped_sheets:
			if sheet.shape != group["shape"]:
				continue
			if sheet.rule != group["match_rule"]:
				continue
			if cell_count < sheet.min_size:
				continue
			# Direction : &"any" cote sheet = accepte tout.
			# Sinon les directions doivent correspondre.
			if sheet.direction != &"any" and group_dir != &"any" and sheet.direction != group_dir:
				continue
			# Enrichir le groupe avec les infos du sheet qui l'a valide
			var enriched: Dictionary = group.duplicate()
			enriched["score_multiplier"] = sheet.score_multiplier
			enriched["sheet_name"] = sheet.sheet_name
			filtered.append(enriched)
			break

	return filtered


## Verifie si `token` peut prolonger une sequence qui se termine par `prev`.
## Utilise pour le dedup : si le predecesseur sur l'axe peut deja etendre la sequence,
## on ne demarre pas une nouvelle depuis la cellule courante.
static func _can_extend(token: TokenData, prev: TokenData, rule: StringName) -> bool:
	if rule == &"suite":
		return abs(token.value - prev.value) == 1
	# Minima/Maxima (session 19) : seuil sur un jeton individuel, pas une
	# egalite entre deux jetons — c'est PREV qui doit deja qualifier (s'il
	# qualifie, son propre parcours en avant a deja rattrape `token`, qu'il
	# qualifie ou non).
	if rule == &"minima":
		return prev.value <= GameRules.MINIMA_MAX_VALUE
	if rule == &"maxima":
		return prev.value >= GameRules.MAXIMA_MIN_VALUE
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
