class_name StreamUI
extends Control

@export var cell_size: float = 80.0
@export var preview_cell_size: float = 64.0
@export var vertical_gap: float = 10.0
@export var label_font_size: int = 18
@export var label_color: Color = Color("3d3d5c")
@export var current_bg_color: Color = Color.WHITE
@export var hold_bg_color: Color = Color.WHITE
@export var corner_radius: float = 12.0

@export var deck_manager: DeckManager

var _font: Font = null


func _ready() -> void:
	_font = load("res://assets/fonts/LondrinaSolid-Black.ttf") as Font


func setup() -> void:
	deck_manager.stream_updated.connect(_on_stream_updated)


func _draw() -> void:
	var y_offset: float = 0.0

	# --- CURRENT ---
	_draw_label("CURRENT", y_offset)
	y_offset += label_font_size + 6.0

	_draw_slot_bg(y_offset, cell_size, current_bg_color)
	var current: TokenData = deck_manager.get_current()
	if current != null:
		_draw_token_in_slot(current, y_offset, cell_size)
	y_offset += cell_size + vertical_gap

	# --- HOLD ---
	_draw_label("HOLD", y_offset)
	y_offset += label_font_size + 6.0

	_draw_slot_bg(y_offset, cell_size, hold_bg_color)
	var hold: TokenData = deck_manager.get_hold()
	if hold != null:
		_draw_token_in_slot(hold, y_offset, cell_size)
	y_offset += cell_size + vertical_gap * 2.0

	# --- PREVIEW (next tokens, vertical, decreasing opacity) ---
	var preview: Array[TokenData] = deck_manager.get_preview()
	for i in range(preview.size()):
		var alpha: float = 1.0 - (i * 0.25)
		draw_set_transform(Vector2.ZERO)
		modulate.a = 1.0  # reset
		var token_pos: float = y_offset + i * (preview_cell_size + vertical_gap)
		# Centrer le preview par rapport au slot current
		var x_offset: float = (cell_size - preview_cell_size) / 2.0
		var tex: Texture2D = TokenVisual.get_texture(preview[i])
		if tex != null:
			var dest: Rect2 = Rect2(
				Vector2(x_offset, token_pos),
				Vector2(preview_cell_size, preview_cell_size),
			)
			draw_texture_rect(tex, dest, false, Color(1, 1, 1, alpha))

	# --- DECK COUNT ---
	var deck_count_y: float = y_offset + preview.size() * (preview_cell_size + vertical_gap) + 10.0
	var count_text: String = str(deck_manager.get_remaining())
	if _font != null:
		draw_string(
			_font,
			Vector2(cell_size / 2.0 - 10.0, deck_count_y + label_font_size),
			count_text,
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			label_font_size,
			label_color,
		)


func _draw_label(text: String, y_pos: float) -> void:
	if _font == null:
		return
	draw_string(
		_font,
		Vector2(0.0, y_pos + label_font_size),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		label_font_size,
		label_color,
	)


func _draw_slot_bg(y_pos: float, slot_size: float, color: Color) -> void:
	var rect: Rect2 = Rect2(Vector2(0.0, y_pos), Vector2(slot_size, slot_size))
	draw_rect(rect, color, true)


func _draw_token_in_slot(token: TokenData, y_pos: float, slot_size: float) -> void:
	var tex: Texture2D = TokenVisual.get_texture(token)
	if tex == null:
		return
	var dest: Rect2 = Rect2(Vector2(0.0, y_pos), Vector2(slot_size, slot_size))
	draw_texture_rect(tex, dest, false)


func _on_stream_updated(_current: TokenData, _hold: TokenData, _preview: Array[TokenData]) -> void:
	queue_redraw()


## Detecte si un clic est sur le hold slot. Retourne true si oui.
func is_hold_click(local_pos: Vector2) -> bool:
	var hold_y: float = label_font_size + 6.0 + cell_size + vertical_gap + label_font_size + 6.0
	var hold_rect: Rect2 = Rect2(Vector2(0.0, hold_y), Vector2(cell_size, cell_size))
	return hold_rect.has_point(local_pos)
