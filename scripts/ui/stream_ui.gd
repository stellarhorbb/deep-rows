class_name StreamUI
extends Control

@export var cell_size: float = 80.0
@export var preview_cell_size: float = 64.0
@export var vertical_gap: float = 10.0
@export var horizontal_gap: float = 16.0
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
	_update_size()


## Y du haut des slots CURRENT/HOLD (sous les labels) — partage entre _draw()
## et le hit-test du hover (voir _slot_token_at), pour ne jamais laisser les
## deux calculs diverger.
func _slots_y() -> float:
	return label_font_size + 6.0


## Y du haut de la colonne PREVIEW, sous les slots CURRENT/HOLD.
func _preview_y() -> float:
	return _slots_y() + cell_size + vertical_gap * 2.0


func _hold_x() -> float:
	return cell_size + horizontal_gap


func _draw() -> void:
	var y_offset: float = _slots_y()
	var hold_x: float = _hold_x()

	# --- LABELS (CURRENT a gauche, HOLD a droite) ---
	_draw_label("CURRENT", 0.0, 0.0)
	_draw_label("HOLD", hold_x, 0.0)

	# --- SLOTS (cote a cote) ---
	_draw_slot_bg(0.0, y_offset, cell_size, current_bg_color)
	var current: TokenData = deck_manager.get_current()
	if current != null:
		_draw_token_in_slot(current, 0.0, y_offset, cell_size)

	# Autant de slots de hold que deck_manager.hold_capacity (1 par defaut,
	# +1 par "Benediction" equipee) — cote a cote a droite du current.
	var hold_slots: Array[TokenData] = deck_manager.get_hold_slots()
	for i in range(hold_slots.size()):
		var slot_x: float = hold_x + i * (cell_size + horizontal_gap)
		_draw_slot_bg(slot_x, y_offset, cell_size, hold_bg_color)
		var held: TokenData = hold_slots[i]
		if held != null:
			_draw_token_in_slot(held, slot_x, y_offset, cell_size)

	y_offset = _preview_y()

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
			if preview[i].kind == TokenData.Kind.BASE and _font != null:
				_draw_value(preview[i].value, x_offset, token_pos, preview_cell_size, Color(1, 1, 1, alpha))

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


func _draw_label(text: String, x_pos: float, y_pos: float) -> void:
	if _font == null:
		return
	draw_string(
		_font,
		Vector2(x_pos, y_pos + label_font_size),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		label_font_size,
		label_color,
	)


func _draw_slot_bg(x_pos: float, y_pos: float, slot_size: float, color: Color) -> void:
	var rect: Rect2 = Rect2(Vector2(x_pos, y_pos), Vector2(slot_size, slot_size))
	draw_rect(rect, color, true)


func _draw_token_in_slot(token: TokenData, x_pos: float, y_pos: float, slot_size: float) -> void:
	var tex: Texture2D = TokenVisual.get_texture(token)
	if tex == null:
		return
	var dest: Rect2 = Rect2(Vector2(x_pos, y_pos), Vector2(slot_size, slot_size))
	draw_texture_rect(tex, dest, false)
	if token.kind == TokenData.Kind.BASE and _font != null:
		_draw_value(token.value, x_pos, y_pos, slot_size, Color.WHITE)


## Valeur (ou nom de figure) en Londrina Solid blanc, centree dans un slot carre.
## Police retrecie pour les noms de figure (ex: "CHEVALIER") : trop long pour
## tenir a la taille normale d'un chiffre seul.
func _draw_value(value: int, x_pos: float, y_pos: float, slot_size: float, color: Color) -> void:
	if not GameRules.DEBUG_SHOW_TOKEN_VALUE:
		return
	var text: String = TokenData.value_label(value)
	var size_ratio: float = 0.45 if text.length() <= 2 else 0.2
	var value_font_size: int = int(slot_size * size_ratio)
	draw_string(
		_font,
		Vector2(x_pos, y_pos + slot_size * 0.5 + value_font_size * 0.35),
		text,
		HORIZONTAL_ALIGNMENT_CENTER,
		slot_size,
		value_font_size,
		color,
	)


func _on_stream_updated(_current: TokenData, _hold: Array[TokenData], _preview: Array[TokenData]) -> void:
	_update_size()
	queue_redraw()


## _draw() peint au-dela des bornes du node sans s'en soucier (Current + N
## slots de Hold, N variable selon Benediction/Le Prevoyant equipes), mais le
## survol de la souris (_get_tooltip) s'appuie lui sur le vrai `size` du
## Control — sans ca, tout ce qui depasse le rect configure dans la scene
## reste hors de portee du hover (bug trouve en session 23 : Current a peine
## couvert, Hold quasiment jamais). Recalcule a chaque changement de stream,
## la capacite de Hold pouvant varier en cours de run.
func _update_size() -> void:
	var capacity: int = deck_manager.hold_capacity
	var width: float = cell_size
	if capacity > 0:
		width = _hold_x() + (capacity - 1) * (cell_size + horizontal_gap) + cell_size
	size.x = width


## Detecte si un clic est sur un slot de hold. Retourne l'index du slot
## clique (0-based), ou -1 si le clic n'est sur aucun slot de hold.
func is_hold_click(local_pos: Vector2) -> int:
	var hold_x: float = _hold_x()
	var hold_y: float = _slots_y()
	var capacity: int = deck_manager.hold_capacity
	for i in range(capacity):
		var slot_x: float = hold_x + i * (cell_size + horizontal_gap)
		var hold_rect: Rect2 = Rect2(Vector2(slot_x, hold_y), Vector2(cell_size, cell_size))
		if hold_rect.has_point(local_pos):
			return i
	return -1


## Survole du hover (session 23) : quel jeton se trouve sous `local_pos`,
## parmi current/hold/preview — meme geometrie que _draw(), voir _slots_y/
## _preview_y/_hold_x. Retourne null si rien sous le curseur.
func _token_at(local_pos: Vector2) -> TokenData:
	var slots_y: float = _slots_y()
	var current_rect: Rect2 = Rect2(Vector2(0.0, slots_y), Vector2(cell_size, cell_size))
	if current_rect.has_point(local_pos):
		return deck_manager.get_current()

	var hold_x: float = _hold_x()
	var hold_slots: Array[TokenData] = deck_manager.get_hold_slots()
	for i in range(hold_slots.size()):
		var slot_x: float = hold_x + i * (cell_size + horizontal_gap)
		var hold_rect: Rect2 = Rect2(Vector2(slot_x, slots_y), Vector2(cell_size, cell_size))
		if hold_rect.has_point(local_pos):
			return hold_slots[i]

	var preview_y: float = _preview_y()
	var x_offset: float = (cell_size - preview_cell_size) / 2.0
	var preview: Array[TokenData] = deck_manager.get_preview()
	for i in range(preview.size()):
		var token_pos: float = preview_y + i * (preview_cell_size + vertical_gap)
		var preview_rect: Rect2 = Rect2(Vector2(x_offset, token_pos), Vector2(preview_cell_size, preview_cell_size))
		if preview_rect.has_point(local_pos):
			return preview[i]

	return null


## Description au hover (famille + valeur pour un jeton normal, label + effet
## pour un special) — toujours visible, contrairement a l'affichage permanent
## de la valeur qui reste derriere GameRules.DEBUG_SHOW_TOKEN_VALUE (survol =
## action volontaire du joueur, pas de pollution visuelle).
##
## _gui_input + tooltip_text plutot que _get_tooltip (session 23) : le vrai
## bug etait ailleurs (mouse_filter du node reste sur IGNORE dans la scene,
## herite d'avant le hover — voir le fix sur le node lui-meme), mais cette
## version via _gui_input reste la plus standard/eprouvee pour capter la
## souris sur un Control, donc conservee plutot que revenir a _get_tooltip.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var token: TokenData = _token_at((event as InputEventMouseMotion).position)
		tooltip_text = TokenTooltip.describe(token) if token != null else ""
