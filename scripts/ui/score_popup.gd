## Label de score flottant qui monte et disparait.
class_name ScorePopup
extends Label

@export var rise_distance: float = 60.0
@export var duration: float = 0.8


func show_at(pos: Vector2, text_value: String, color: Color = Color.WHITE) -> void:
	text = text_value
	position = pos
	add_theme_color_override("font_color", color)
	add_theme_font_size_override("font_size", 28)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modulate.a = 1.0
	visible = true

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", pos.y - rise_distance, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, duration * 0.4).set_delay(duration * 0.6)
	tween.chain().tween_callback(queue_free)
