## Affiche les Sheets equipees (4 slots max).
class_name SheetsUI
extends Control

const MAX_SLOTS: int = 4

@export var slot_width: float = 260.0
@export var slot_height: float = 56.0
@export var vertical_gap: float = 8.0
@export var header_gap: float = 6.0
@export var corner_radius: float = 8.0
@export var header_font_size: int = 18
@export var sheet_font_size: int = 20
@export var label_color: Color = Color("3d3d5c")
@export var slot_bg_color: Color = Color(1, 1, 1, 0.85)
@export var empty_bg_color: Color = Color(1, 1, 1, 0.35)
@export var progress_fill_color: Color = Color("f0e6c8")  # tres legerement different du fond, pour la barre de niveau
@export var sell_button_size: Vector2 = Vector2(64.0, 32.0)

## Lu en direct (pas de snapshot fige de manche, contrairement au
## SheetManager utilise par la resolution) — permet a SheetsUI de s'afficher
## sur n'importe quel ecran, meme hors manche active (Shell persistant).
var run_manager: RunManager = null

var _font: Font = null
var _sell_buttons: Array[Button] = []


func _ready() -> void:
	_font = load("res://assets/fonts/LondrinaSolid-Black.ttf") as Font


func setup() -> void:
	if run_manager != null:
		run_manager.sheets_changed.connect(_on_sheets_changed)
		run_manager.sheet_leveled_up.connect(_on_sheet_leveled_up)
		run_manager.sheet_progress_changed.connect(_on_sheet_progress_changed)
	_create_sell_buttons()


## Un bouton "VENDRE" par slot, cree une seule fois. Visible/positionne a
## chaque _draw() selon l'etat du slot correspondant — evite tout clic
## accidentel sur le reste de la carte (cf. retour user post-implementation).
func _create_sell_buttons() -> void:
	for i in range(MAX_SLOTS):
		var btn: Button = Button.new()
		btn.text = "VENDRE"
		btn.visible = false
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_on_sell_pressed.bind(i))
		add_child(btn)
		_sell_buttons.append(btn)


func _on_sell_pressed(i: int) -> void:
	if run_manager == null:
		return
	var sheets: Array[SheetData] = run_manager.get_equipped_sheets()
	if i >= sheets.size():
		return
	run_manager.sell_sheet(sheets[i])


func _draw() -> void:
	var y_offset: float = 0.0

	# Header
	if _font != null:
		draw_string(
			_font,
			Vector2(0.0, y_offset + header_font_size),
			"SHEETS",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			header_font_size,
			label_color,
		)
	y_offset += header_font_size + header_gap

	# Slots
	var sheets: Array[SheetData] = []
	if run_manager != null:
		sheets = run_manager.get_equipped_sheets()

	for i in range(MAX_SLOTS):
		var is_filled: bool = i < sheets.size()
		if is_filled:
			_draw_slot_progress_bg(y_offset, sheets[i])
		else:
			_draw_slot_bg(y_offset, empty_bg_color)

		if is_filled and _font != null:
			var label: String = _level_prefix(sheets[i]) + _format_sheet_label(sheets[i])
			draw_string(
				_font,
				Vector2(12.0, y_offset + slot_height * 0.5 + sheet_font_size * 0.35),
				label,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				sheet_font_size,
				label_color,
			)

		_update_sell_button(i, y_offset, is_filled, sheets)

		y_offset += slot_height + vertical_gap


## Positionne/affiche le bouton VENDRE du slot i en coin haut-droit de la carte.
func _update_sell_button(i: int, y_pos: float, is_filled: bool, sheets: Array[SheetData]) -> void:
	var btn: Button = _sell_buttons[i]
	btn.visible = is_filled
	if not is_filled:
		return
	btn.size = sell_button_size
	btn.position = Vector2(slot_width - sell_button_size.x - 6.0, y_pos + 6.0)
	btn.tooltip_text = "+%d mouches" % int(sheets[i].price * GameRules.SELL_REFUND_RATIO)


func _draw_slot_bg(y_pos: float, color: Color) -> void:
	var rect: Rect2 = Rect2(Vector2(0.0, y_pos), Vector2(slot_width, slot_height))
	draw_rect(rect, color, true)


## Fond de slot = barre de progression vers le prochain niveau. Le fond plein
## reste slot_bg_color, une bande progress_fill_color avance par dessus a gauche.
func _draw_slot_progress_bg(y_pos: float, sheet: SheetData) -> void:
	_draw_slot_bg(y_pos, slot_bg_color)

	var progress: float = _level_progress(sheet)
	if progress <= 0.0:
		return

	var fill_rect: Rect2 = Rect2(Vector2(0.0, y_pos), Vector2(slot_width * progress, slot_height))
	draw_rect(fill_rect, progress_fill_color, true)


## Fraction (0-1) du chemin parcouru entre le seuil du niveau actuel et celui
## du niveau suivant. 1.0 si niveau max (barre pleine).
func _level_progress(sheet: SheetData) -> float:
	if run_manager == null:
		return 0.0

	var level: int = run_manager.get_sheet_level(sheet.sheet_name)
	var next_threshold: int = GameRules.get_next_sheet_threshold(level)
	if next_threshold < 0:
		return 1.0

	var prev_threshold: int = GameRules.get_previous_sheet_threshold(level)
	var span: int = next_threshold - prev_threshold
	if span <= 0:
		return 1.0

	var cumulative: int = run_manager.get_sheet_cumulative_score(sheet.sheet_name)
	return clampf(float(cumulative - prev_threshold) / float(span), 0.0, 1.0)


## Reprend directement sheet.label (meme nom que shop/hover, ex: "PRIME",
## "BRELAN") plutot que de recomposer forme+regle+taille (ex: l'ancien
## "LINE CASINO 3" pour Brelan) — ce nom compose etait illisible en jeu.
func _format_sheet_label(sheet: SheetData) -> String:
	# Multiplicateur fixe visible pour toutes les formes, lignes comprises
	# depuis la session 16 (la direction ne joue plus sur le score).
	var raw_mult: String = _format_multiplier(sheet.score_multiplier)
	return sheet.label + ("  " + raw_mult if raw_mult != "" else "")


func _format_multiplier(mult: float) -> String:
	if mult <= 1.0:
		return ""
	if mult == float(int(mult)):
		return "x" + str(int(mult))
	return "x%.1f" % mult


## "Lv.2 — " devant le nom de la Partition. Vide tant que run_manager n'est pas
## cable, et pour les legendaires (session 20) qui ne level up jamais — voir
## SheetData.is_legendary.
func _level_prefix(sheet: SheetData) -> String:
	if run_manager == null or sheet.is_legendary:
		return ""
	return "Lv." + str(run_manager.get_sheet_level(sheet.sheet_name)) + " — "


func _on_sheets_changed(_sheets: Array[SheetData]) -> void:
	queue_redraw()


func _on_sheet_leveled_up(_sheet_name: StringName, _new_level: int) -> void:
	queue_redraw()


func _on_sheet_progress_changed(_sheet_name: StringName) -> void:
	queue_redraw()


## Hover simple : recalcule le tooltip a chaque mouvement de souris selon
## le slot survole. Reutilise le meme calcul d'offset que _draw(). La vente
## passe desormais par le bouton VENDRE dedie (voir _create_sell_buttons),
## plus par un clic sur la carte — trop facile a declencher par erreur.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		tooltip_text = _tooltip_for_position(event.position)


func _tooltip_for_position(pos: Vector2) -> String:
	var sheet: SheetData = _sheet_at_position(pos)
	if sheet == null:
		return ""
	return sheet.describe() + _level_tooltip(sheet)


func _sheet_at_position(pos: Vector2) -> SheetData:
	if run_manager == null:
		return null
	var sheets: Array[SheetData] = run_manager.get_equipped_sheets()

	var y_offset: float = header_font_size + header_gap
	y_offset += 14 + header_gap + 2.0

	for i in range(MAX_SLOTS):
		if pos.x >= 0.0 and pos.x <= slot_width and pos.y >= y_offset and pos.y < y_offset + slot_height:
			if i < sheets.size():
				return sheets[i]
			return null
		y_offset += slot_height + vertical_gap

	return null


func _level_tooltip(sheet: SheetData) -> String:
	if run_manager == null:
		return ""
	if sheet.is_legendary:
		return "\nLégendaire — flat, ne level up jamais"
	var level: int = run_manager.get_sheet_level(sheet.sheet_name)
	var cumulative: int = run_manager.get_sheet_cumulative_score(sheet.sheet_name)
	var level_name: String = GameRules.get_sheet_level_name(level)
	var next_threshold: int = GameRules.get_next_sheet_threshold(level)

	var text: String = "\nNiveau %d — %s (x%.2f)" % [level, level_name, GameRules.get_sheet_level_multiplier(level)]
	if next_threshold >= 0:
		text += "\n%d / %d pts vers le niveau suivant" % [cumulative, next_threshold]
	else:
		text += "\nNiveau maximum atteint"
	return text
