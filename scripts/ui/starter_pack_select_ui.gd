## Ecran de choix du pack de demarrage (session 19). Remplace l'ancien tirage
## 3 Partitions/2 choisies (RunManager.draft_starter_partitions, retire) —
## celui-ci etait recommençable a volonte en relançant la run, donc pas un
## vrai choix. Presente RunManager.get_available_starter_packs() (day-one
## pour l'instant, tous debloques), le joueur en choisit un seul, deterministe
## et fixe pour toute la run.
class_name StarterPackSelectUI
extends Control

@onready var cards_container: HBoxContainer = $Panel/VBox/CardsContainer
@onready var confirm_button: Button = $Panel/VBox/ConfirmButton

var _run_manager: RunManager
var _candidate_buttons: Array[Button] = []
var _selected: StarterPackData = null


func _ready() -> void:
	RunService.ensure_run_started()
	_run_manager = RunService.run_manager
	confirm_button.pressed.connect(_on_confirm_pressed)
	_build_cards()
	_update_confirm_state()


func _build_cards() -> void:
	for pack in _run_manager.get_available_starter_packs():
		var btn: RarityButton = RarityButton.new()
		btn.text = pack.pack_name
		btn.tooltip_text = _describe_pack(pack)
		btn.custom_minimum_size = Vector2(320.0, 200.0)
		btn.toggle_mode = true
		btn.pressed.connect(_on_candidate_pressed.bind(pack, btn))
		cards_container.add_child(btn)
		_candidate_buttons.append(btn)


func _describe_pack(pack: StarterPackData) -> String:
	var text: String = pack.pack_name
	if pack.description != "":
		text += "\n" + pack.description
	for tag in pack.get_fixed_tags():
		text += "\n+ " + tag.label
	return text


## Selection exclusive (un seul pack a la fois) — contrairement a l'ancien
## draft qui permettait de cocher 2 candidats independamment.
func _on_candidate_pressed(pack: StarterPackData, btn: Button) -> void:
	if btn.button_pressed:
		for other in _candidate_buttons:
			if other != btn:
				other.button_pressed = false
		_selected = pack
	else:
		_selected = null
	_update_confirm_state()


func _update_confirm_state() -> void:
	confirm_button.disabled = _selected == null


func _on_confirm_pressed() -> void:
	if _selected == null:
		return
	_run_manager.apply_starter_pack(_selected)
	SceneRouter.go_to_game()
