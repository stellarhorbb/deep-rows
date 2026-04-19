## Ecran de fin de run — variante victoire ou game over selon RunService.game_flow.
## Minimal pour le moment : titre + score/target + bouton nouveau run.
class_name EndScreenUI
extends Control

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var result_label: Label = $Panel/VBox/ResultLabel
@onready var restart_button: Button = $Panel/VBox/RestartButton


func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	_populate()


func _populate() -> void:
	var score: int = RunService.last_score
	var target: int = RunService.last_target
	var result_text: String = "%s / %s" % [NumberFormat.with_spaces(score), NumberFormat.with_spaces(target)]
	if RunService.game_flow == RunService.GameFlow.RUN_WON:
		title_label.text = "VICTOIRE"
	else:
		title_label.text = "GAME OVER"
	result_label.text = result_text


func _on_restart_pressed() -> void:
	RunService.start_new_run()
	SceneRouter.go_to_game()
