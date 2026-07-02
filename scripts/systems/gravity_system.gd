class_name GravitySystem

## Compacte chaque colonne vers le bas (row 0 = bottom). Les cases de `holes`
## (Vector2i -> true) sont transparentes : jamais de jeton ecrit dedans, et
## elles ne comptent pas comme un emplacement occupe pendant la compaction.
## Modifie grid en place, retourne les mouvements pour animation.
static func apply(grid: Array, cols: int, rows: int, holes: Dictionary = {}) -> Array[Dictionary]:
	var movements: Array[Dictionary] = []

	for c in range(cols):
		var write: int = 0
		for r in range(rows):
			if holes.has(Vector2i(c, r)):
				continue
			if grid[c][r] != null:
				while holes.has(Vector2i(c, write)):
					write += 1
				if write != r:
					grid[c][write] = grid[c][r]
					grid[c][r] = null
					movements.append({
						"col": c,
						"from_row": r,
						"to_row": write,
					})
				write += 1

	return movements
