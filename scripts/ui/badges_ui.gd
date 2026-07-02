## Affiche les Badges equipes. Ligne horizontale sous la grille, jusqu'a MAX_BADGE_SLOTS.
class_name BadgesUI
extends Control

@export var slot_width: float = 200.0
@export var slot_height: float = 56.0
@export var horizontal_gap: float = 10.0
@export var header_gap: float = 6.0
@export var header_font_size: int = 18
@export var badge_font_size: int = 18
@export var label_color: Color = Color("3d3d5c")
@export var slot_bg_color: Color = Color(1, 1, 1, 0.85)
@export var empty_bg_color: Color = Color(1, 1, 1, 0.35)
@export var sell_button_size: Vector2 = Vector2(64.0, 32.0)

var run_manager: RunManager = null

var _font: Font = null
var _sell_buttons: Array[Button] = []


func _ready() -> void:
	_font = load("res://assets/fonts/LondrinaSolid-Black.ttf") as Font


func setup() -> void:
	if run_manager != null:
		run_manager.badges_changed.connect(_on_badges_changed)
	_create_sell_buttons()
	queue_redraw()


## Un bouton "VENDRE" par slot, cree une seule fois. Visible/positionne a
## chaque _draw() selon l'etat du slot correspondant — evite tout clic
## accidentel sur le reste de la carte (cf. retour user post-implementation).
func _create_sell_buttons() -> void:
	for i in range(GameRules.MAX_BADGE_SLOTS):
		var btn: Button = Button.new()
		btn.text = "VENDRE"
		btn.visible = false
		btn.pressed.connect(_on_sell_pressed.bind(i))
		add_child(btn)
		_sell_buttons.append(btn)


func _on_sell_pressed(i: int) -> void:
	if run_manager == null:
		return
	var badges: Array[BadgeData] = run_manager.get_equipped_badges()
	if i >= badges.size():
		return
	run_manager.sell_badge(badges[i])


func _draw() -> void:
	var y_offset: float = 0.0

	if _font != null:
		draw_string(
			_font,
			Vector2(0.0, y_offset + header_font_size),
			"BADGES",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			header_font_size,
			label_color,
		)
	y_offset += header_font_size + header_gap

	var badges: Array[BadgeData] = []
	if run_manager != null:
		badges = run_manager.get_equipped_badges()

	var max_slots: int = GameRules.MAX_BADGE_SLOTS
	var total_width: float = max_slots * slot_width + (max_slots - 1) * horizontal_gap
	var start_x: float = (size.x - total_width) * 0.5

	for i in range(max_slots):
		var x: float = start_x + i * (slot_width + horizontal_gap)
		var is_filled: bool = i < badges.size()
		var bg: Color = slot_bg_color if is_filled else empty_bg_color
		var rect: Rect2 = Rect2(Vector2(x, y_offset), Vector2(slot_width, slot_height))
		draw_rect(rect, bg, true)

		if is_filled and _font != null:
			draw_string(
				_font,
				Vector2(x + 12.0, y_offset + slot_height * 0.5 + badge_font_size * 0.35),
				badges[i].label,
				HORIZONTAL_ALIGNMENT_LEFT,
				slot_width - 24.0,
				badge_font_size,
				label_color,
			)

		_update_sell_button(i, x, y_offset, is_filled, badges)


## Positionne/affiche le bouton VENDRE du slot i en coin haut-droit de la carte.
func _update_sell_button(i: int, x_pos: float, y_pos: float, is_filled: bool, badges: Array[BadgeData]) -> void:
	var btn: Button = _sell_buttons[i]
	btn.visible = is_filled
	if not is_filled:
		return
	btn.size = sell_button_size
	btn.position = Vector2(x_pos + slot_width - sell_button_size.x - 6.0, y_pos + 6.0)
	btn.tooltip_text = "+%d mouches" % int(badges[i].price * GameRules.SELL_REFUND_RATIO)


func _on_badges_changed(_badges: Array[BadgeData]) -> void:
	queue_redraw()


## Hover simple : recalcule le tooltip a chaque mouvement de souris selon
## le slot survole. Reutilise le meme calcul de layout que _draw(). La vente
## passe desormais par le bouton VENDRE dedie (voir _create_sell_buttons),
## plus par un clic sur la carte — trop facile a declencher par erreur.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		tooltip_text = _tooltip_for_position(event.position)


func _tooltip_for_position(pos: Vector2) -> String:
	if run_manager == null:
		return ""
	var badge: BadgeData = _badge_at_position(pos)
	if badge == null:
		return ""

	var text: String = badge.label
	if badge.description != "":
		text += "\n" + badge.description
	return text


func _badge_at_position(pos: Vector2) -> BadgeData:
	var badges: Array[BadgeData] = run_manager.get_equipped_badges()

	var y_offset: float = header_font_size + header_gap
	if pos.y < y_offset or pos.y > y_offset + slot_height:
		return null

	var max_slots: int = GameRules.MAX_BADGE_SLOTS
	var total_width: float = max_slots * slot_width + (max_slots - 1) * horizontal_gap
	var start_x: float = (size.x - total_width) * 0.5

	for i in range(max_slots):
		var x: float = start_x + i * (slot_width + horizontal_gap)
		if pos.x >= x and pos.x < x + slot_width:
			if i < badges.size():
				return badges[i]
			return null

	return null
