## Ecran de choix du pack de demarrage (session 19, carrousel session 20,
## packs verrouilles visibles session 25). Remplace l'ancien tirage 3/2 de
## Partitions. Presente RunManager.get_all_starter_packs() un a la fois via
## un carrousel, plutot qu'en grille — le roster est prevu pour grandir a une
## dizaine de packs avec illustration et handicaps par pack (session 20), une
## grille ne tiendrait plus a l'ecran. Les packs pas encore debloques au
## Shore restent visibles (pas selectionnables) plutot que masques, pour
## donner un objectif clair — voir RunManager.is_pack_locked.
class_name StarterPackSelectUI
extends Control

@onready var left_button: Button = $Panel/VBox/CarouselRow/LeftButton
@onready var right_button: Button = $Panel/VBox/CarouselRow/RightButton
@onready var pack_name_label: Label = $Panel/VBox/CarouselRow/CardPanel/CardVBox/PackNameLabel
@onready var completed_label: Label = $Panel/VBox/CarouselRow/CardPanel/CardVBox/CompletedLabel
@onready var pack_description_label: Label = $Panel/VBox/CarouselRow/CardPanel/CardVBox/PackDescriptionLabel
@onready var pack_sheets_label: Label = $Panel/VBox/CarouselRow/CardPanel/CardVBox/PackSheetsLabel
@onready var page_label: Label = $Panel/VBox/PageLabel
@onready var confirm_button: Button = $Panel/VBox/ConfirmButton
@onready var debug_unlock_all_button: Button = $Panel/VBox/DebugRow/DebugUnlockAllButton
@onready var debug_reset_save_button: Button = $Panel/VBox/DebugRow/DebugResetSaveButton

var _run_manager: RunManager
var _packs: Array[StarterPackData] = []
var _index: int = 0


func _ready() -> void:
	RunService.ensure_run_started()
	_run_manager = RunService.run_manager
	left_button.pressed.connect(_on_left_pressed)
	right_button.pressed.connect(_on_right_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	debug_unlock_all_button.pressed.connect(_on_debug_unlock_all_pressed)
	debug_reset_save_button.pressed.connect(_on_debug_reset_save_pressed)
	_refresh_packs()


## DEBUG : bypass total du Shore, pour tester tout le roster sans jouer
## chaque unlock un par un.
func _on_debug_unlock_all_pressed() -> void:
	MetaProgression.debug_force_unlock_all = true
	_refresh_packs()


## DEBUG : repart d'une sauvegarde vierge, comme un joueur qui n'a rien
## debloque au Shore.
func _on_debug_reset_save_pressed() -> void:
	MetaProgression.debug_force_unlock_all = false
	MetaProgression.reset_save_debug()
	_refresh_packs()


func _refresh_packs() -> void:
	_packs = _run_manager.get_all_starter_packs()
	_index = 0
	_update_display()


func _on_left_pressed() -> void:
	_index = (_index - 1 + _packs.size()) % _packs.size()
	_update_display()


func _on_right_pressed() -> void:
	_index = (_index + 1) % _packs.size()
	_update_display()


func _update_display() -> void:
	var pack: StarterPackData = _packs[_index]
	var locked: bool = _run_manager.is_pack_locked(pack)
	pack_name_label.text = pack.pack_name
	completed_label.visible = _run_manager.has_won_with_pack(pack)

	if locked:
		pack_description_label.text = _lock_reason(pack)
		pack_sheets_label.text = ""
	else:
		pack_description_label.text = pack.description
		var sheets_text: String = ""
		for sheet in pack.get_fixed_sheets():
			sheets_text += "+ " + sheet.label + "\n"
		pack_sheets_label.text = sheets_text.strip_edges()

	page_label.text = "%d / %d" % [_index + 1, _packs.size()]
	var has_choice: bool = _packs.size() > 1
	left_button.disabled = not has_choice
	right_button.disabled = not has_choice
	confirm_button.disabled = locked
	confirm_button.text = "VERROUILLÉ" if locked else "COMMENCER"


## Texte affiche a la place de la description pour un pack verrouille —
## indique la condition connue si elle existe (voir
## StarterPackData.unlock_requires_win_of), sinon un placeholder generique
## (Le Prevoyant/Le Collectionneur n'ont pas encore de condition tranchee).
func _lock_reason(pack: StarterPackData) -> String:
	if pack.unlock_requires_win_of != null:
		return "Verrouillé — à débloquer en gagnant une run avec %s." % pack.unlock_requires_win_of.pack_name
	return "Verrouillé — condition de déblocage à venir."


func _on_confirm_pressed() -> void:
	if _run_manager.is_pack_locked(_packs[_index]):
		return
	_run_manager.apply_starter_pack(_packs[_index])
	SceneRouter.go_to_game()
