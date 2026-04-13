class_name GravitySystem

## Compacte chaque colonne vers le bas (row 0 = bottom).
## Modifie grid en place, retourne les mouvements pour animation.
static func apply(grid: Array, cols: int, rows: int) -> Array[Dictionary]:
	var movements: Array[Dictionary] = []

	for c in range(cols):
		var write: int = 0
		for r in range(rows):
			if grid[c][r] != null:
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
