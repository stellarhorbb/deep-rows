## Gere les actions de l'Entity pendant la manche.
## Apres chaque tour resolu, l'Entity peut lacher un jeton entity-skull
## dans une colonne aleatoire non pleine.
class_name EntityManager
extends Node

var grid_manager: GridManager

var _turn_count: int = 0


func reset() -> void:
	_turn_count = 0


## Appele apres chaque tour joueur resolu.
## Retourne la colonne ciblee (-1 si pas d'action ce tour).
func on_turn_resolved() -> int:
	_turn_count += 1
	if _turn_count % GameRules.ENTITY_DROP_INTERVAL != 0:
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
