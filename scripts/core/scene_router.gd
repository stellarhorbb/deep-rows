## Autoload. Centralise les transitions de scene. Chaque ecran du jeu a sa
## methode ici. Les scenes appellent SceneRouter.go_to_xxx() au lieu de
## change_scene_to_file directement.
extends Node

const GAME_SCENE_PATH: String = "res://scenes/game/game.tscn"
const SHOP_SCENE_PATH: String = "res://scenes/shop/shop.tscn"
const END_SCREEN_PATH: String = "res://scenes/end/end_screen.tscn"
const PARTITION_SELECT_SCENE_PATH: String = "res://scenes/partition_select/partition_select.tscn"


func go_to_game() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func go_to_partition_select() -> void:
	get_tree().change_scene_to_file(PARTITION_SELECT_SCENE_PATH)


func go_to_shop() -> void:
	get_tree().change_scene_to_file(SHOP_SCENE_PATH)


func go_to_end_screen() -> void:
	get_tree().change_scene_to_file(END_SCREEN_PATH)
