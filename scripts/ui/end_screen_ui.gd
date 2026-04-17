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
	match RunService.game_flow:
		RunService.GameFlow.RUN_WON:
			title_label.text = "VICTOIRE"
			result_label.text = "%s / %s" % [_format(score), _format(target)]
		RunService.GameFlow.ROUND_LOST:
			title_label.text = "GAME OVER"
			result_label.text = "%s / %s" % [_format(score), _format(target)]
		_:
			title_label.text = "FIN"
			result_label.text = "%s / %s" % [_format(score), _format(target)]


func _on_restart_pressed() -> void:
	RunService.start_new_run()
	SceneRouter.go_to_game()


func _format(n: int) -> String:
	var s: String = str(n)
	var result: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		result = s[i] + result
		count += 1
		if count % 3 == 0 and i > 0:
			result = " " + result
	return result
