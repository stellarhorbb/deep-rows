## Gere les actions de l'Entity pendant la manche.
## Apres chaque tour resolu, l'Entity peut lacher un jeton entity-skull
## dans une colonne aleatoire non pleine.
class_name EntityManager
extends Node

var grid_manager: GridManager

## Malus de boss GRANDE FAIM (voir BossMalusManager) : override l'intervalle
## de drop pour la manche. 0 = pas d'override, utilise GameRules.ENTITY_DROP_INTERVAL.
var drop_interval_override: int = 0

var _turn_count: int = 0


func reset() -> void:
	_turn_count = 0
	drop_interval_override = 0


## Appele apres chaque tour joueur resolu.
## Retourne la colonne ciblee (-1 si pas d'action ce tour).
func on_turn_resolved() -> int:
	_turn_count += 1
	var interval: int = drop_interval_override if drop_interval_override > 0 else GameRules.ENTITY_DROP_INTERVAL
	if _turn_count % interval != 0:
		return -1
	return _pick_random_col()


func _pick_random_col() -> int:
	var available: Array[int] = []
	for c in range(GameRules.COLS):
		if grid_manager.column_height(c) < GameRules.ROWS:
			available.append(c)
	if available.is_empty():
		return -1
	return available[randi() % available.size()]
