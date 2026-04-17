## Affiche les Pattern Tags equipes (4 slots max).
class_name TagsUI
extends Control

const MAX_SLOTS: int = 4

@export var slot_width: float = 260.0
@export var slot_height: float = 56.0
@export var vertical_gap: float = 8.0
@export var header_gap: float = 6.0
@export var corner_radius: float = 8.0
@export var header_font_size: int = 18
@export var tag_font_size: int = 20
@export var label_color: Color = Color("3d3d5c")
@export var slot_bg_color: Color = Color(1, 1, 1, 0.85)
@export var empty_bg_color: Color = Color(1, 1, 1, 0.35)

var pattern_manager: PatternManager = null

var _font: Font = null


func _ready() -> void:
	_font = load("res://assets/fonts/LondrinaSolid-Black.ttf") as Font


func setup() -> void:
	if pattern_manager != null:
		pattern_manager.tags_changed.connect(_on_tags_changed)


func _draw() -> void:
	var y_offset: float = 0.0

	# Header
	if _font != null:
		draw_string(
			_font,
			Vector2(0.0, y_offset + header_font_size),
			"PATTERN TAGS",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			header_font_size,
			label_color,
		)
	y_offset += header_font_size + header_gap

	# Legende direction (pour les lignes)
	if _font != null:
		draw_string(
			_font,
			Vector2(0.0, y_offset + 14),
			"LIGNE : v x1  h x1.5  d x2",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			14,
			Color(label_color, 0.55),
		)
	y_offset += 14 + header_gap + 2.0

	# Slots
	var tags: Array[PatternData] = []
	if pattern_manager != null:
		tags = pattern_manager.get_active_tags()

	for i in range(MAX_SLOTS):
		var is_filled: bool = i < tags.size()
		var bg: Color = slot_bg_color if is_filled else empty_bg_color
		_draw_slot_bg(y_offset, bg)

		if is_filled and _font != null:
			var label: String = _format_tag_label(tags[i])
			draw_string(
				_font,
				Vector2(12.0, y_offset + slot_height * 0.5 + tag_font_size * 0.35),
				label,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				tag_font_size,
				label_color,
			)

		y_offset += slot_height + vertical_gap


func _draw_slot_bg(y_pos: float, color: Color) -> void:
	var rect: Rect2 = Rect2(Vector2(0.0, y_pos), Vector2(slot_width, slot_height))
	draw_rect(rect, color, true)


func _format_tag_label(tag: PatternData) -> String:
	var shape_str: String = "LINE" if tag.shape == &"line" else "SQUARE"
	var rule_str: String
	match tag.rule:
		&"family": rule_str = "FAMILY"
		&"suite":  rule_str = "SUITE"
		&"rock":   rule_str = "ROCK"
		_:         rule_str = "NUMBER"

	# Lines : pas de multiplicateur fixe affiche (varie selon la direction)
	if tag.shape == &"line":
		return shape_str + " " + rule_str + " " + str(tag.min_size)

	# Autres formes : multiplicateur fixe visible
	if tag.shape == &"diamond":
		var raw: String = _format_multiplier(tag.score_multiplier)
		return "DIAMOND ROCK" + ("  " + raw if raw != "" else "")

	var raw_mult: String = _format_multiplier(tag.score_multiplier)
	return shape_str + " " + rule_str + ("  " + raw_mult if raw_mult != "" else "")


func _format_multiplier(mult: float) -> String:
	if mult <= 1.0:
		return ""
	if mult == float(int(mult)):
		return "x" + str(int(mult))
	return "x%.1f" % mult


func _on_tags_changed(_tags: Array[PatternData]) -> void:
	queue_redraw()
