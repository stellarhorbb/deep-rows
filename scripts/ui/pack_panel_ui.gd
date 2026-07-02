## Reveal generique d'un pack achete (Partition/Badge/Special/Bouton — un seul
## contenant visuel pour toutes les categories, cf. decision "pas de DA avant
## validation du fun"). Affiche les candidats deja tires par
## ShopManager.open_pack, clic sur 1 = le garde et ferme immediatement.
class_name PackPanelUI
extends Control

signal item_chosen(item: Variant)

@onready var title_label: Label = $Box/VBox/Title
@onready var candidates_container: GridContainer = $Box/VBox/CandidatesContainer
@onready var close_button: Button = $Box/VBox/CloseButton

var _candidate_buttons: Array[Button] = []


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	visible = false


## `candidates` : Array de PatternData/BadgeData/SpecialItem/TokenData deja tires.
func open_with(candidates: Array, title: String) -> void:
	title_label.text = title
	_clear_candidates()

	for item in candidates:
		var btn: Button = Button.new()
		btn.text = ShopManager.get_label(item)
		btn.tooltip_text = ShopManager.get_description(item)
		btn.pressed.connect(_on_candidate_pressed.bind(item))
		candidates_container.add_child(btn)
		_candidate_buttons.append(btn)

	visible = true


func _clear_candidates() -> void:
	for btn in _candidate_buttons:
		btn.queue_free()
	_candidate_buttons.clear()


func _on_candidate_pressed(item: Variant) -> void:
	visible = false
	item_chosen.emit(item)


func _on_close_pressed() -> void:
	visible = false
