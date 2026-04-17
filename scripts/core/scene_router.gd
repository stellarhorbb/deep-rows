## Autoload. Centralise les transitions de scene. Chaque ecran du jeu a sa
## methode ici. Les scenes appellent SceneRouter.go_to_xxx() au lieu de
## change_scene_to_file directement.
extends Node

const GAME_SCENE_PATH: String = "res://scenes/game/game.tscn"
const SHOP_SCENE_PATH: String = "res://scenes/shop/shop.tscn"


func go_to_game() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func go_to_shop() -> void:
	get_tree().change_scene_to_file(SHOP_SCENE_PATH)
