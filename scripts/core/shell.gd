## Scene racine et persistante du jeu (scene principale du projet). Contient
## le HUD fixe — Partitions, Badges, Deck, et plus tard Settings/Menu — jamais
## detruit entre les ecrans, a des positions toujours identiques. SceneRouter
## instancie l'ecran actif (Game/Shop/PartitionSelect/EndScreen) dans
## content_container au lieu d'un change_scene_to_file complet, qui aurait
## detruit et recree le HUD a chaque transition.
class_name Shell
extends Control

@onready var content_container: Control = $ContentContainer
@onready var sheets_ui: SheetsUI = $SheetsUI
@onready var badges_ui: BadgesUI = $BadgesUI
@onready var deck_button: Button = $DeckButton
@onready var deck_inspector_ui: DeckInspectorUI = $DeckInspectorUI
@onready var special_inventory_ui: SpecialInventoryUI = $SpecialInventoryUI

var _current_content: Node = null


func _ready() -> void:
	SceneRouter.shell = self

	sheets_ui.run_manager = RunService.run_manager
	sheets_ui.setup()
	badges_ui.run_manager = RunService.run_manager
	badges_ui.setup()
	special_inventory_ui.run_manager = RunService.run_manager
	special_inventory_ui.setup()
	# Tilt sur le slot d'un Badge des qu'il ajoute des mouches (Vertige,
	# Pourboire, Un Pour Tous, Mouches en Cascade...) — ces Badges ne passent
	# jamais par la banniere de resolution (qui tilte deja les Badges de score),
	# ils n'avaient donc aucun feedback visuel avant (session 17).
	RunService.badge_manager.badge_triggered.connect(badges_ui.tilt_badge)

	deck_button.pressed.connect(deck_inspector_ui.toggle)
	deck_inspector_ui.run_manager = RunService.run_manager
	# Desactive tant qu'aucune run n'a demarre (ecran de choix du pack de
	# depart) — des qu'une run existe (Game, Shop, ouverture de pack...),
	# DeckInspectorUI sait toujours quoi afficher (voir sa propre logique de
	# fallback deck_manager/run_manager).
	deck_button.disabled = true

	# Shell est la scene principale du projet — premier ecran a charger.
	SceneRouter.go_to_starter_pack_select()


## Remplace l'ecran actif par celui demande. Retourne l'instance pour que
## l'appelant (SceneRouter) puisse la caster et laisser l'ecran se cabler
## lui-meme (managers de manche, etc.) dans son propre _ready().
func load_content(scene_path: String) -> Node:
	if _current_content != null:
		_current_content.queue_free()
		_current_content = null

	deck_button.disabled = true
	deck_inspector_ui.deck_manager = null
	deck_inspector_ui.visible = false
	special_inventory_ui.clear_selection()

	var packed: PackedScene = load(scene_path) as PackedScene
	var instance: Node = packed.instantiate()
	content_container.add_child(instance)
	_current_content = instance
	return instance
