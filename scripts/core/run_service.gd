## Autoload global. Porte l'etat qui persiste entre changements de scene
## (run_manager, shop_manager, numero de manche, game_flow).
## Les scenes (game, shop...) lisent et mutent RunService, pas l'inverse.
extends Node

enum GameFlow { PLAYING, ROUND_WON, ROUND_LOST, RUN_WON, SHOPPING }

var run_manager: RunManager
var shop_manager: ShopManager
var current_round: int = 1
var game_flow: GameFlow = GameFlow.PLAYING

var _run_initialized: bool = false


func _ready() -> void:
	# Managers persistants pour toute la duree du run
	run_manager = RunManager.new()
	run_manager.name = "RunManager"
	add_child(run_manager)

	shop_manager = ShopManager.new()
	shop_manager.name = "ShopManager"
	add_child(shop_manager)


## Appele par la game scene au premier demarrage. Init si pas deja fait.
func ensure_run_started() -> void:
	if not _run_initialized:
		start_new_run()


func start_new_run() -> void:
	run_manager.init_run()
	current_round = 1
	game_flow = GameFlow.PLAYING
	_run_initialized = true


func advance_round() -> void:
	current_round += 1
	game_flow = GameFlow.PLAYING
