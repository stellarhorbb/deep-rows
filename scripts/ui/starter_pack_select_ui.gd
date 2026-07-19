## Ecran de choix du pack de demarrage (session 19, carrousel session 20).
## Remplace l'ancien tirage 3/2 de Partitions. Presente
## RunManager.get_available_starter_packs() (day-one pour l'instant, tous
## debloques) un a la fois via un carrousel, plutot qu'en grille — le roster
## est prevu pour grandir a une dizaine de packs avec illustration et
## handicaps par pack (session 20), une grille ne tiendrait plus a l'ecran.
class_name StarterPackSelectUI
extends Control

@onready var left_button: Button = $Panel/VBox/CarouselRow/LeftButton
@onready var right_button: Button = $Panel/VBox/CarouselRow/RightButton
@onready var pack_name_label: Label = $Panel/VBox/CarouselRow/CardPanel/CardVBox/PackNameLabel
@onready var pack_description_label: Label = $Panel/VBox/CarouselRow/CardPanel/CardVBox/PackDescriptionLabel
@onready var pack_sheets_label: Label = $Panel/VBox/CarouselRow/CardPanel/CardVBox/PackSheetsLabel
@onready var page_label: Label = $Panel/VBox/PageLabel
@onready var confirm_button: Button = $Panel/VBox/ConfirmButton

var _run_manager: RunManager
var _packs: Array[StarterPackData] = []
var _index: int = 0


func _ready() -> void:
	RunService.ensure_run_started()
	_run_manager = RunService.run_manager
	left_button.pressed.connect(_on_left_pressed)
	right_button.pressed.connect(_on_right_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	_packs = _run_manager.get_available_starter_packs()
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
	pack_name_label.text = pack.pack_name
	pack_description_label.text = pack.description
	var sheets_text: String = ""
	for sheet in pack.get_fixed_sheets():
		sheets_text += "+ " + sheet.label + "\n"
	pack_sheets_label.text = sheets_text.strip_edges()
	page_label.text = "%d / %d" % [_index + 1, _packs.size()]
	var has_choice: bool = _packs.size() > 1
	left_button.disabled = not has_choice
	right_button.disabled = not has_choice


func _on_confirm_pressed() -> void:
	_run_manager.apply_starter_pack(_packs[_index])
	SceneRouter.go_to_game()
