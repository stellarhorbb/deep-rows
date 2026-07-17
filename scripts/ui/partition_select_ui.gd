## Ecran de selection de Partition de depart. Tire GameRules.STARTER_PARTITION_DRAFT_SIZE
## Partitions au hasard dans tout le catalogue (RunManager.draft_starter_partitions),
## le joueur en choisit 2 gratuitement pour demarrer sa run (filet de securite —
## 1 seule s'est revelee trop punitive si elle ne matche jamais en debut de manche).
class_name PartitionSelectUI
extends Control

const PICK_COUNT: int = 2

@onready var cards_container: HBoxContainer = $Panel/VBox/CardsContainer
@onready var confirm_button: Button = $Panel/VBox/ConfirmButton
@onready var refresh_button: Button = $Panel/VBox/RefreshButton

var _run_manager: RunManager
var _candidate_buttons: Array[Button] = []
var _selected: Array[PatternData] = []


func _ready() -> void:
	RunService.ensure_run_started()
	_run_manager = RunService.run_manager
	confirm_button.pressed.connect(_on_confirm_pressed)
	refresh_button.pressed.connect(_on_refresh_pressed)
	_build_cards()
	_update_confirm_state()


## DEBUG (temporaire) : retire un nouveau tirage sans avoir a relancer le jeu,
## pratique pour tester une Partition specifique qui ne sort pas souvent dans
## le tirage de GameRules.STARTER_PARTITION_DRAFT_SIZE. A retirer une fois le
## besoin de test passe.
func _on_refresh_pressed() -> void:
	_selected.clear()
	_clear_cards()
	_build_cards()
	_update_confirm_state()


func _clear_cards() -> void:
	for btn in _candidate_buttons:
		btn.queue_free()
	_candidate_buttons.clear()


func _build_cards() -> void:
	for candidate in _run_manager.draft_starter_partitions():
		var btn: RarityButton = RarityButton.new()
		btn.text = candidate.label
		btn.tooltip_text = candidate.describe()
		btn.custom_minimum_size = Vector2(320.0, 160.0)
		btn.toggle_mode = true
		btn.pressed.connect(_on_candidate_pressed.bind(candidate, btn))
		cards_container.add_child(btn)
		_candidate_buttons.append(btn)


func _on_candidate_pressed(candidate: PatternData, btn: Button) -> void:
	if btn.button_pressed:
		if _selected.size() >= PICK_COUNT:
			btn.button_pressed = false
			return
		_selected.append(candidate)
	else:
		_selected.erase(candidate)
	_update_confirm_state()


func _update_confirm_state() -> void:
	confirm_button.disabled = _selected.size() != PICK_COUNT
	confirm_button.text = "COMMENCER (%d/%d)" % [_selected.size(), PICK_COUNT]


func _on_confirm_pressed() -> void:
	if _selected.size() != PICK_COUNT:
		return
	for tag in _selected:
		_run_manager.equip_tag(tag)
	SceneRouter.go_to_game()
