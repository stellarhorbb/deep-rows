## Ecran de selection de Partition de depart. Tire GameRules.STARTER_PARTITION_DRAFT_SIZE
## Partitions au hasard dans tout le catalogue (RunManager.draft_starter_partitions),
## le joueur en choisit 1 gratuitement pour demarrer sa run.
class_name PartitionSelectUI
extends Control

@onready var cards_container: HBoxContainer = $Panel/VBox/CardsContainer

var _run_manager: RunManager


func _ready() -> void:
	RunService.ensure_run_started()
	_run_manager = RunService.run_manager
	_build_cards()


func _build_cards() -> void:
	for candidate in _run_manager.draft_starter_partitions():
		var btn: Button = Button.new()
		btn.text = candidate.label
		btn.tooltip_text = candidate.describe()
		btn.custom_minimum_size = Vector2(320.0, 160.0)
		btn.pressed.connect(_on_candidate_pressed.bind(candidate))
		cards_container.add_child(btn)


func _on_candidate_pressed(candidate: PatternData) -> void:
	_run_manager.equip_tag(candidate)
	SceneRouter.go_to_game()
