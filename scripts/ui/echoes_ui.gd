## Affiche les Echoes equipes. Ligne horizontale sous la grille, jusqu'a MAX_ECHO_SLOTS.
class_name EchoesUI
extends Control

@export var slot_width: float = 200.0
@export var slot_height: float = 56.0
@export var horizontal_gap: float = 10.0
@export var header_gap: float = 6.0
@export var header_font_size: int = 18
@export var echo_font_size: int = 18
@export var label_color: Color = Color("3d3d5c")
@export var slot_bg_color: Color = Color(1, 1, 1, 0.85)
@export var empty_bg_color: Color = Color(1, 1, 1, 0.35)

var run_manager: RunManager = null

var _font: Font = null


func _ready() -> void:
	_font = load("res://assets/fonts/LondrinaSolid-Black.ttf") as Font


func setup() -> void:
	if run_manager != null:
		run_manager.echoes_changed.connect(_on_echoes_changed)
	queue_redraw()


func _draw() -> void:
	var y_offset: float = 0.0

	if _font != null:
		draw_string(
			_font,
			Vector2(0.0, y_offset + header_font_size),
			"ECHOES",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			header_font_size,
			label_color,
		)
	y_offset += header_font_size + header_gap

	var echoes: Array[EchoData] = []
	if run_manager != null:
		echoes = run_manager.get_equipped_echoes()

	var max_slots: int = GameRules.MAX_ECHO_SLOTS
	var total_width: float = max_slots * slot_width + (max_slots - 1) * horizontal_gap
	var start_x: float = (size.x - total_width) * 0.5

	for i in range(max_slots):
		var x: float = start_x + i * (slot_width + horizontal_gap)
		var is_filled: bool = i < echoes.size()
		var bg: Color = slot_bg_color if is_filled else empty_bg_color
		var rect: Rect2 = Rect2(Vector2(x, y_offset), Vector2(slot_width, slot_height))
		draw_rect(rect, bg, true)

		if is_filled and _font != null:
			draw_string(
				_font,
				Vector2(x + 12.0, y_offset + slot_height * 0.5 + echo_font_size * 0.35),
				echoes[i].label,
				HORIZONTAL_ALIGNMENT_LEFT,
				slot_width - 24.0,
				echo_font_size,
				label_color,
			)


func _on_echoes_changed(_echoes: Array[EchoData]) -> void:
	queue_redraw()
