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
var _candidate_items: Array = []
var _shop_manager: ShopManager = null
var _run_manager: RunManager = null


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	visible = false


## `candidates` : Array de SheetData/BadgeData/SpecialItem/TokenData deja tires.
## shop_manager/run_manager servent uniquement a griser les candidats Partition/
## Badge dont les slots sont deja pleins (le pack est deja paye, le joueur ne
## doit pas pouvoir choisir un item qui ne pourra jamais s'equiper).
func open_with(candidates: Array, title: String, shop_manager: ShopManager, run_manager: RunManager) -> void:
	title_label.text = title
	_clear_candidates()

	_shop_manager = shop_manager
	_run_manager = run_manager
	# Le grise initial ne suffit pas : si le joueur vend un Partition/Badge
	# equipe pendant que le pack reste ouvert (liberant un slot), il faut
	# recalculer _disabled_ sur les candidats deja affiches plutot que de
	# figer l'etat au moment de l'ouverture.
	if not run_manager.badges_changed.is_connected(_refresh_disabled_states):
		run_manager.badges_changed.connect(_refresh_disabled_states)
	if not run_manager.sheets_changed.is_connected(_refresh_disabled_states):
		run_manager.sheets_changed.connect(_refresh_disabled_states)

	for item in candidates:
		var btn: RarityButton = RarityButton.new()
		btn.text = ShopManager.get_label(item)
		btn.tooltip_text = ShopManager.get_description(item)
		btn.rarity = ShopManager.get_rarity(item)
		btn.disabled = not shop_manager.can_equip_slot(item, run_manager)
		btn.pressed.connect(_on_candidate_pressed.bind(item))
		candidates_container.add_child(btn)
		_candidate_buttons.append(btn)
		_candidate_items.append(item)

	visible = true


func _refresh_disabled_states(_equipped: Array = []) -> void:
	if not visible or _shop_manager == null or _run_manager == null:
		return
	for i in range(_candidate_buttons.size()):
		_candidate_buttons[i].disabled = not _shop_manager.can_equip_slot(_candidate_items[i], _run_manager)


func _clear_candidates() -> void:
	for btn in _candidate_buttons:
		btn.queue_free()
	_candidate_buttons.clear()
	_candidate_items.clear()


func _on_candidate_pressed(item: Variant) -> void:
	visible = false
	item_chosen.emit(item)


func _on_close_pressed() -> void:
	visible = false
