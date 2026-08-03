## Gere les actions de l'Entity pendant la manche.
## Apres chaque tour resolu, l'Entity peut lacher un jeton entity-skull
## dans une colonne aleatoire non pleine -- chance croissante depuis le
## dernier drop (session 26), voir GameRules.ENTITY_DROP_BASE_CHANCE.
class_name EntityManager
extends Node

var grid_manager: GridManager

## Malus de boss GRANDE FAIM (voir BossMalusManager) : double la vitesse de
## montee de la chance pour la manche (increment x2) -- meme intention que
## l'ancien "intervalle divise par 2", adaptee au systeme probabiliste.
var drop_chance_multiplier: float = 1.0

var _turns_since_drop: int = 0


func reset() -> void:
	_turns_since_drop = 0
	drop_chance_multiplier = 1.0


## Appele apres chaque tour joueur resolu.
## Retourne la colonne ciblee (-1 si pas d'action ce tour).
func on_turn_resolved() -> int:
	_turns_since_drop += 1
	var increment: float = GameRules.ENTITY_DROP_INCREMENT * drop_chance_multiplier
	var chance: float = minf(GameRules.ENTITY_DROP_BASE_CHANCE + float(_turns_since_drop - 1) * increment, 1.0)
	if randf() >= chance:
		return -1
	_turns_since_drop = 0
	return _pick_random_col()


func _pick_random_col() -> int:
	var available: Array[int] = []
	for c in range(GameRules.COLS):
		if grid_manager.column_height(c) < GameRules.ROWS:
			available.append(c)
	if available.is_empty():
		return -1
	return available[randi() % available.size()]
