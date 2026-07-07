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
@export var progress_fill_color: Color = Color("f0e6c8")  # tres legerement different du fond, pour la barre de niveau
@export var sell_button_size: Vector2 = Vector2(64.0, 32.0)

var pattern_manager: PatternManager = null
var run_manager: RunManager = null

var _font: Font = null
var _sell_buttons: Array[Button] = []


func _ready() -> void:
	_font = load("res://assets/fonts/LondrinaSolid-Black.ttf") as Font


func setup() -> void:
	if pattern_manager != null:
		pattern_manager.tags_changed.connect(_on_tags_changed)
	if run_manager != null:
		run_manager.tag_leveled_up.connect(_on_tag_leveled_up)
		run_manager.tag_progress_changed.connect(_on_tag_progress_changed)
	_create_sell_buttons()


## Un bouton "VENDRE" par slot, cree une seule fois. Visible/positionne a
## chaque _draw() selon l'etat du slot correspondant — evite tout clic
## accidentel sur le reste de la carte (cf. retour user post-implementation).
func _create_sell_buttons() -> void:
	for i in range(MAX_SLOTS):
		var btn: Button = Button.new()
		btn.text = "VENDRE"
		btn.visible = false
		btn.pressed.connect(_on_sell_pressed.bind(i))
		add_child(btn)
		_sell_buttons.append(btn)


func _on_sell_pressed(i: int) -> void:
	if pattern_manager == null or run_manager == null:
		return
	var tags: Array[PatternData] = pattern_manager.get_active_tags()
	if i >= tags.size():
		return
	run_manager.sell_tag(tags[i])


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
		if is_filled:
			_draw_slot_progress_bg(y_offset, tags[i])
		else:
			_draw_slot_bg(y_offset, empty_bg_color)

		if is_filled and _font != null:
			var label: String = _level_prefix(tags[i]) + _format_tag_label(tags[i])
			draw_string(
				_font,
				Vector2(12.0, y_offset + slot_height * 0.5 + tag_font_size * 0.35),
				label,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				tag_font_size,
				label_color,
			)

		_update_sell_button(i, y_offset, is_filled, tags)

		y_offset += slot_height + vertical_gap


## Positionne/affiche le bouton VENDRE du slot i en coin haut-droit de la carte.
func _update_sell_button(i: int, y_pos: float, is_filled: bool, tags: Array[PatternData]) -> void:
	var btn: Button = _sell_buttons[i]
	btn.visible = is_filled
	if not is_filled:
		return
	btn.size = sell_button_size
	btn.position = Vector2(slot_width - sell_button_size.x - 6.0, y_pos + 6.0)
	btn.tooltip_text = "+%d mouches" % int(tags[i].price * GameRules.SELL_REFUND_RATIO)


func _draw_slot_bg(y_pos: float, color: Color) -> void:
	var rect: Rect2 = Rect2(Vector2(0.0, y_pos), Vector2(slot_width, slot_height))
	draw_rect(rect, color, true)


## Fond de slot = barre de progression vers le prochain niveau. Le fond plein
## reste slot_bg_color, une bande progress_fill_color avance par dessus a gauche.
func _draw_slot_progress_bg(y_pos: float, tag: PatternData) -> void:
	_draw_slot_bg(y_pos, slot_bg_color)

	var progress: float = _level_progress(tag)
	if progress <= 0.0:
		return

	var fill_rect: Rect2 = Rect2(Vector2(0.0, y_pos), Vector2(slot_width * progress, slot_height))
	draw_rect(fill_rect, progress_fill_color, true)


## Fraction (0-1) du chemin parcouru entre le seuil du niveau actuel et celui
## du niveau suivant. 1.0 si niveau max (barre pleine).
func _level_progress(tag: PatternData) -> float:
	if run_manager == null:
		return 0.0

	var level: int = run_manager.get_tag_level(tag.tag_name)
	var next_threshold: int = GameRules.get_next_pattern_threshold(level)
	if next_threshold < 0:
		return 1.0

	var prev_threshold: int = GameRules.get_previous_pattern_threshold(level)
	var span: int = next_threshold - prev_threshold
	if span <= 0:
		return 1.0

	var cumulative: int = run_manager.get_tag_cumulative_score(tag.tag_name)
	return clampf(float(cumulative - prev_threshold) / float(span), 0.0, 1.0)


func _format_tag_label(tag: PatternData) -> String:
	var shape_str: String = _shape_label(tag.shape)
	# "family" n'est plus affiche : c'est la rule de la quasi-totalite du
	# catalogue actif, l'afficher est redondant. Les rules qui distinguent
	# vraiment un Tag (rock, suite) restent visibles.
	var rule_str: String
	match tag.rule:
		&"suite": rule_str = "SUITE"
		&"rock":  rule_str = "ROCK"
		_:        rule_str = ""

	# Lines : pas de multiplicateur fixe affiche (varie selon la direction)
	if tag.shape == &"line":
		var line_label: String = shape_str
		if rule_str != "":
			line_label += " " + rule_str
		return line_label + " " + str(tag.min_size)

	# Autres formes (square, diamond, plus, cross) : multiplicateur fixe visible
	var raw_mult: String = _format_multiplier(tag.score_multiplier)
	var label: String = shape_str
	if rule_str != "":
		label += " " + rule_str
	return label + ("  " + raw_mult if raw_mult != "" else "")


func _shape_label(shape: StringName) -> String:
	match shape:
		&"line":    return "LINE"
		&"square":  return "SQUARE"
		&"diamond": return "DIAMOND"
		&"plus":    return "PLUS"
		&"cross":   return "CROSS"
		&"ring":    return "RING"
		&"t":       return "T"
	return "SHAPE"


func _format_multiplier(mult: float) -> String:
	if mult <= 1.0:
		return ""
	if mult == float(int(mult)):
		return "x" + str(int(mult))
	return "x%.1f" % mult


## "Lv.2 — " devant le nom de la Partition. Vide tant que run_manager n'est pas cable.
func _level_prefix(tag: PatternData) -> String:
	if run_manager == null:
		return ""
	return "Lv." + str(run_manager.get_tag_level(tag.tag_name)) + " — "


func _on_tags_changed(_tags: Array[PatternData]) -> void:
	queue_redraw()


func _on_tag_leveled_up(_tag_name: StringName, _new_level: int) -> void:
	queue_redraw()


func _on_tag_progress_changed(_tag_name: StringName) -> void:
	queue_redraw()


## Hover simple : recalcule le tooltip a chaque mouvement de souris selon
## le slot survole. Reutilise le meme calcul d'offset que _draw(). La vente
## passe desormais par le bouton VENDRE dedie (voir _create_sell_buttons),
## plus par un clic sur la carte — trop facile a declencher par erreur.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		tooltip_text = _tooltip_for_position(event.position)


func _tooltip_for_position(pos: Vector2) -> String:
	var tag: PatternData = _tag_at_position(pos)
	if tag == null:
		return ""
	return tag.describe() + _level_tooltip(tag)


func _tag_at_position(pos: Vector2) -> PatternData:
	if pattern_manager == null:
		return null
	var tags: Array[PatternData] = pattern_manager.get_active_tags()

	var y_offset: float = header_font_size + header_gap
	y_offset += 14 + header_gap + 2.0

	for i in range(MAX_SLOTS):
		if pos.x >= 0.0 and pos.x <= slot_width and pos.y >= y_offset and pos.y < y_offset + slot_height:
			if i < tags.size():
				return tags[i]
			return null
		y_offset += slot_height + vertical_gap

	return null


func _level_tooltip(tag: PatternData) -> String:
	if run_manager == null:
		return ""
	var level: int = run_manager.get_tag_level(tag.tag_name)
	var cumulative: int = run_manager.get_tag_cumulative_score(tag.tag_name)
	var level_name: String = GameRules.get_pattern_level_name(level)
	var next_threshold: int = GameRules.get_next_pattern_threshold(level)

	var text: String = "\nNiveau %d — %s (x%.2f)" % [level, level_name, GameRules.get_pattern_level_multiplier(level)]
	if next_threshold >= 0:
		text += "\n%d / %d pts vers le niveau suivant" % [cumulative, next_threshold]
	else:
		text += "\nNiveau maximum atteint"
	return text
