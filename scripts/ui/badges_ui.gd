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
@export var tilt_flash_color: Color = Color("f0e6c8")
@export var tilt_duration: float = 0.7
@export var tilt_angle_max: float = 0.3  # radians, ~17 degrees

var run_manager: RunManager = null

var _font: Font = null
var _sell_buttons: Array[Button] = []
var _flash_intensity: Dictionary = {}  # int (slot index) -> float 0..1
var _tilt_angle: Dictionary = {}  # int (slot index) -> float (radians)


func _ready() -> void:
	_font = load("res://assets/fonts/LondrinaSolid-Black.ttf") as Font


func setup() -> void:
	if run_manager != null:
		run_manager.badges_changed.connect(_on_badges_changed)
	_create_sell_buttons()
	queue_redraw()


## Un bouton "VENDRE" par slot, cree une seule fois — dimensionne au nombre
## de slots MAX possible (base + plus gros bonus de pack de demarrage connu),
## car appele avant que le pack de la run ne soit choisi (voir Shell._ready).
## Visible/positionne a chaque _draw() selon l'etat du slot correspondant —
## evite tout clic accidentel sur le reste de la carte (cf. retour user
## post-implementation). _draw()/_badge_at_position n'utilisent que les
## get_badge_slot_count() premiers, le reste ne sert jamais tant qu'aucun
## pack n'accorde plus de bonus.
func _create_sell_buttons() -> void:
	for i in range(GameRules.MAX_BADGE_SLOTS + GameRules.STARTER_PACK_MAX_BADGE_SLOT_BONUS):
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

	var max_slots: int = run_manager.get_badge_slot_count() if run_manager != null else GameRules.MAX_BADGE_SLOTS
	var total_width: float = max_slots * slot_width + (max_slots - 1) * horizontal_gap
	var start_x: float = (size.x - total_width) * 0.5

	for i in range(max_slots):
		var x: float = start_x + i * (slot_width + horizontal_gap)
		var is_filled: bool = i < badges.size()
		var bg: Color = slot_bg_color if is_filled else empty_bg_color
		var flash: float = _flash_intensity.get(i, 0.0) as float
		if flash > 0.0:
			bg = bg.lerp(tilt_flash_color, flash)

		# Rotation de tilt (voir tilt_badge) : la carte penche puis revient a
		# plat, en plus du flash de couleur — dessine en coordonnees locales
		# autour du centre du slot, sous une transform reinitialisee juste apres.
		var angle: float = _tilt_angle.get(i, 0.0) as float
		var center: Vector2 = Vector2(x + slot_width * 0.5, y_offset + slot_height * 0.5)
		draw_set_transform(center, angle, Vector2.ONE)
		var local_rect: Rect2 = Rect2(Vector2(-slot_width * 0.5, -slot_height * 0.5), Vector2(slot_width, slot_height))
		draw_rect(local_rect, bg, true)

		if is_filled and _font != null:
			draw_string(
				_font,
				Vector2(-slot_width * 0.5 + 12.0, -slot_height * 0.5 + slot_height * 0.5 + badge_font_size * 0.35),
				badges[i].label,
				HORIZONTAL_ALIGNMENT_LEFT,
				slot_width - 24.0,
				badge_font_size,
				label_color,
			)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

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


## Flash + bascule sur le slot du Badge donne (identifie par id), pour
## signaler qu'il vient de contribuer au score d'une figure (ou de trigger
## hors banniere, voir BadgeManager.badge_triggered). N'attend rien — la
## banniere de resolution qui l'appelle continue sa propre sequence en
## parallele. Deux Tween independants (flash de couleur + angle) tournent en
## meme temps sur le meme node — pas besoin de les synchroniser a la main.
func tilt_badge(badge_id: StringName) -> void:
	if run_manager == null:
		return
	var badges: Array[BadgeData] = run_manager.get_equipped_badges()
	var slot_index: int = -1
	for i in range(badges.size()):
		if badges[i].id == badge_id:
			slot_index = i
			break
	if slot_index == -1:
		return

	var flash_tween: Tween = create_tween()
	flash_tween.tween_method(
		func(v: float) -> void:
			_flash_intensity[slot_index] = v
			queue_redraw(),
		1.0, 0.0, tilt_duration
	).set_ease(Tween.EASE_OUT)

	# Bascule : penche vite d'un cote (overshoot), revient de l'autre cote
	# plus doucement, puis se stabilise a plat.
	var angle_tween: Tween = create_tween()
	angle_tween.tween_method(
		func(a: float) -> void:
			_tilt_angle[slot_index] = a
			queue_redraw(),
		0.0, tilt_angle_max, tilt_duration * 0.2
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	angle_tween.tween_method(
		func(a: float) -> void:
			_tilt_angle[slot_index] = a
			queue_redraw(),
		tilt_angle_max, -tilt_angle_max * 0.6, tilt_duration * 0.3
	).set_ease(Tween.EASE_IN_OUT)
	angle_tween.tween_method(
		func(a: float) -> void:
			_tilt_angle[slot_index] = a
			queue_redraw(),
		-tilt_angle_max * 0.6, 0.0, tilt_duration * 0.5
	).set_ease(Tween.EASE_OUT)


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

	var effect: BadgeEffect = badge.make_effect()
	if effect != null:
		var progress: String = effect.get_progress_text(run_manager)
		if progress != "":
			text += "\n" + progress

	return text


func _make_custom_tooltip(for_text: String) -> Object:
	if run_manager == null:
		return null
	var badge: BadgeData = _badge_at_position(get_local_mouse_position())
	if badge == null:
		return null
	return RarityTooltip.build(for_text, badge.rarity)


func _badge_at_position(pos: Vector2) -> BadgeData:
	var badges: Array[BadgeData] = run_manager.get_equipped_badges()

	var y_offset: float = header_font_size + header_gap
	if pos.y < y_offset or pos.y > y_offset + slot_height:
		return null

	var max_slots: int = run_manager.get_badge_slot_count()
	var total_width: float = max_slots * slot_width + (max_slots - 1) * horizontal_gap
	var start_x: float = (size.x - total_width) * 0.5

	for i in range(max_slots):
		var x: float = start_x + i * (slot_width + horizontal_gap)
		if pos.x >= x and pos.x < x + slot_width:
			if i < badges.size():
				return badges[i]
			return null

	return null
