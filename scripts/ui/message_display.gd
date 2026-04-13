class_name MessageDisplay
extends Label

@export var win_color: Color = Color("4ecdc4")
@export var lose_color: Color = Color("ff6b6b")
@export var cascade_color: Color = Color("e2b714")
@export var default_color: Color = Color.WHITE
@export var display_duration: float = 1.5


func show_message(msg: String, msg_type: StringName = &"default") -> void:
	text = msg
	match msg_type:
		&"win":
			add_theme_color_override("font_color", win_color)
		&"lose":
			add_theme_color_override("font_color", lose_color)
		&"cascade":
			add_theme_color_override("font_color", cascade_color)
		_:
			add_theme_color_override("font_color", default_color)
	visible = true


func show_timed_message(msg: String, msg_type: StringName = &"default") -> void:
	show_message(msg, msg_type)
	await get_tree().create_timer(display_duration).timeout
	clear_message()


func clear_message() -> void:
	text = ""
	visible = false
