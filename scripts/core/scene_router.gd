## Autoload. Centralise les transitions d'ecran. Les scenes appellent
## SceneRouter.go_to_xxx() au lieu de manipuler le Shell directement.
##
## Depuis le Shell persistant (session 13), ce n'est plus un change_scene_to_file
## complet — le Shell (HUD fixe : Partitions/Sortilèges/Deck) reste en vie, seul
## le contenu dans son ContentContainer est remplace. Voir scripts/core/shell.gd.
extends Node

const GAME_SCENE_PATH: String = "res://scenes/game/game.tscn"
const SHOP_SCENE_PATH: String = "res://scenes/shop/shop.tscn"
const END_SCREEN_PATH: String = "res://scenes/end/end_screen.tscn"
const STARTER_PACK_SELECT_SCENE_PATH: String = "res://scenes/starter_pack_select/starter_pack_select.tscn"

## Assigne par Shell._ready() — le Shell est la scene principale du projet,
## donc toujours pret avant le premier appel a go_to_xxx().
var shell: Shell = null


func go_to_game() -> void:
	shell.load_content(GAME_SCENE_PATH)


func go_to_starter_pack_select() -> void:
	shell.load_content(STARTER_PACK_SELECT_SCENE_PATH)


func go_to_shop() -> void:
	shell.load_content(SHOP_SCENE_PATH)


func go_to_end_screen() -> void:
	shell.load_content(END_SCREEN_PATH)
