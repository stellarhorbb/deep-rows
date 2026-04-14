class_name GridVisual
extends Node2D

@export var cell_size: float = 90.0
@export var cell_gap: float = 6.0
@export var empty_cell_color: Color = Color("e8e8e8")
@export var residue_color: Color = Color("b8b3d6")

## Timing des animations
@export var drop_duration: float = 0.25
@export var match_highlight_duration: float = 0.35
@export var remove_duration: float = 0.25
@export var gravity_duration: float = 0.18
@export var cascade_pause: float = 0.15

## Score popup colors
@export var score_color: Color = Color("e2b714")
@export var cascade_score_color: Color = Color("ff6b6b")

@export var grid_manager: GridManager

var _token_sprites: Dictionary = {}  # Vector2i -> Sprite2D
var _is_animating: bool = false
var _popup_font: Font = null

## Hover preview
var _hover_sprite: Sprite2D = null
var _hover_col: int = -1

## Shake
var _base_position: Vector2 = Vector2.ZERO


func setup() -> void:
	grid_manager.grid_reset.connect(_on_grid_reset)
	_popup_font = load("res://assets/fonts/LondrinaSolid-Black.ttf") as Font
	_base_position = position


func _draw() -> void:
	# Dessiner uniquement le fond de grille (cellules vides)
	for c in range(GameRules.COLS):
		for r in range(GameRules.ROWS):
			var visual_row: int = GameRules.ROWS - 1 - r
			var center: Vector2 = _cell_center(c, visual_row)
			draw_circle(center, cell_size / 2.0, empty_cell_color)


## Synchronise les sprites avec l'etat logique de la grille.
func sync_sprites() -> void:
	# Supprimer les sprites orphelins
	var to_remove: Array[Vector2i] = []
	for cell_key in _token_sprites:
		var cell: Vector2i = cell_key as Vector2i
		var token: TokenData = grid_manager.get_cell(cell.x, cell.y)
		if token == null:
			var sprite: Sprite2D = _token_sprites[cell] as Sprite2D
			sprite.queue_free()
			to_remove.append(cell)

	for cell in to_remove:
		_token_sprites.erase(cell)

	# Creer les sprites manquants
	for c in range(GameRules.COLS):
		for r in range(GameRules.ROWS):
			var cell: Vector2i = Vector2i(c, r)
			var token: TokenData = grid_manager.get_cell(c, r)
			if token != null and not _token_sprites.has(cell):
				_create_sprite(cell, token)


## Rebuild complet — detruit tous les sprites et les recree depuis l'etat de la grille.
## A utiliser apres un special qui deplace des jetons (Fantome, Maree).
func rebuild_sprites() -> void:
	for cell in _token_sprites:
		(_token_sprites[cell] as Sprite2D).queue_free()
	_token_sprites.clear()

	for c in range(GameRules.COLS):
		for r in range(GameRules.ROWS):
			var token: TokenData = grid_manager.get_cell(c, r)
			if token != null:
				_create_sprite(Vector2i(c, r), token)


## Place un jeton avec animation de chute.
func animate_drop(col: int, row: int, token: TokenData) -> void:
	var cell: Vector2i = Vector2i(col, row)
	var sprite: Sprite2D = _create_sprite(cell, token)

	# Depart : au-dessus de la grille
	var start_pos: Vector2 = _grid_to_pixel(col, GameRules.ROWS)
	var end_pos: Vector2 = _grid_to_pixel(col, row)
	sprite.position = start_pos

	var tween: Tween = create_tween()
	tween.tween_property(sprite, "position", end_pos, drop_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	# Double bounce a l'arrivee
	tween.tween_property(sprite, "position:y", end_pos.y - 12.0, 0.08).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "position:y", end_pos.y, 0.08).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "position:y", end_pos.y - 4.0, 0.06).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "position:y", end_pos.y, 0.06).set_ease(Tween.EASE_IN)
	await tween.finished


## Supprime le sprite a une position donnee (utile pour les specials qui ne restent pas).
func remove_sprite_at(cell: Vector2i) -> void:
	if _token_sprites.has(cell):
		(_token_sprites[cell] as Sprite2D).queue_free()
		_token_sprites.erase(cell)


## Joue la timeline de resolution complete avec animations.
func play_timeline(timeline: Array[Dictionary]) -> void:
	_is_animating = true

	for event in timeline:
		var event_type: int = event["type"] as int

		if event_type == CascadeResolver.EventType.MATCH:
			await _animate_match(event)

		elif event_type == CascadeResolver.EventType.REMOVE:
			await _animate_remove(event)

		elif event_type == CascadeResolver.EventType.GRAVITY:
			await _animate_gravity(event)

	_is_animating = false


func is_animating() -> bool:
	return _is_animating


func refresh() -> void:
	sync_sprites()
	queue_redraw()


## --- Hover preview ---

## Met a jour le fantome de preview sur la colonne survolee.
func update_hover(col: int, token: TokenData) -> void:
	if col == _hover_col and _hover_sprite != null:
		return
	clear_hover()
	if col < 0 or col >= GameRules.COLS or token == null:
		_hover_col = -1
		return

	var landing_row: int = _get_hover_landing_row(col, token)
	if landing_row < 0 or landing_row >= GameRules.ROWS:
		_hover_col = -1
		return

	_hover_col = col
	_hover_sprite = Sprite2D.new()
	_hover_sprite.centered = true

	var tex: Texture2D = null
	if token.kind == TokenData.Kind.SPECIAL:
		match token.special_type:
			TokenData.SpecialType.FANTOME:
				tex = load("res://assets/special-tokens/ghost.png") as Texture2D
			TokenData.SpecialType.BOMBE:
				tex = load("res://assets/special-tokens/bomb.png") as Texture2D
			TokenData.SpecialType.MAREE:
				tex = load("res://assets/special-tokens/tide.png") as Texture2D
	else:
		tex = TokenVisual.get_texture(token)

	if tex == null:
		_hover_sprite.queue_free()
		_hover_sprite = null
		return

	_hover_sprite.texture = tex
	var tex_size: float = maxf(tex.get_width(), tex.get_height())
	var target_scale: float = cell_size / tex_size
	_hover_sprite.scale = Vector2(target_scale, target_scale)
	_hover_sprite.modulate = Color(1.0, 1.0, 1.0, 0.35)
	_hover_sprite.position = _grid_to_pixel(col, landing_row)
	add_child(_hover_sprite)


func _get_hover_landing_row(col: int, token: TokenData) -> int:
	if token.kind == TokenData.Kind.SPECIAL:
		match token.special_type:
			TokenData.SpecialType.FANTOME:
				return 0
			TokenData.SpecialType.BOMBE:
				return grid_manager.column_height(col)
			TokenData.SpecialType.MAREE:
				return grid_manager.column_height(col)
	return grid_manager.column_height(col)


func clear_hover() -> void:
	if _hover_sprite != null:
		_hover_sprite.queue_free()
		_hover_sprite = null
	_hover_col = -1


## --- Shake ---

func apply_shake(cascade_level: int) -> void:
	var intensity: float = 5.0 + cascade_level * 3.0
	var shake_tween: Tween = create_tween()
	shake_tween.tween_method(_set_shake, Vector2.ZERO, Vector2(intensity, intensity), 0.06)
	shake_tween.tween_method(_set_shake, Vector2(intensity, intensity), Vector2(-intensity * 0.7, -intensity * 0.5), 0.05)
	shake_tween.tween_method(_set_shake, Vector2(-intensity * 0.7, -intensity * 0.5), Vector2(intensity * 0.4, intensity * 0.3), 0.04)
	shake_tween.tween_method(_set_shake, Vector2(intensity * 0.4, intensity * 0.3), Vector2.ZERO, 0.05)


func _set_shake(offset: Vector2) -> void:
	position = _base_position + offset


## --- Pattern label ---

func _spawn_pattern_label(pos: Vector2, pattern_text: String) -> void:
	var label: Label = Label.new()
	label.text = pattern_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = pos - Vector2(100, 40)
	label.custom_minimum_size = Vector2(200, 0)
	if _popup_font != null:
		label.add_theme_font_override("font", _popup_font)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color("3d3d5c"))
	label.modulate.a = 0.0
	add_child(label)

	var tween: Tween = create_tween()
	# Fade in rapide + monte en parallele
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 1.0, 0.1)
	tween.tween_property(label, "position:y", pos.y - 80.0, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	# Fade out apres la montee
	tween.chain().tween_property(label, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(label.queue_free)


## --- Animations internes ---

func _animate_match(event: Dictionary) -> void:
	var groups: Array = event["groups"] as Array
	var scores: Array = event["scores"] as Array
	var cascade_level: int = event["cascade_level"] as int

	# Shake la grille
	apply_shake(cascade_level)

	# Shake les jetons matches
	var all_cells: Dictionary = {}
	for group in groups:
		for cell in group["cells"]:
			all_cells[cell] = true

	# Flash blanc
	for cell_key in all_cells:
		var cell: Vector2i = cell_key as Vector2i
		if _token_sprites.has(cell):
			var sprite: Sprite2D = _token_sprites[cell] as Sprite2D
			sprite.modulate = Color(3.0, 3.0, 3.0, 1.0)
	await get_tree().create_timer(0.04).timeout
	for cell_key in all_cells:
		var cell: Vector2i = cell_key as Vector2i
		if _token_sprites.has(cell):
			var sprite: Sprite2D = _token_sprites[cell] as Sprite2D
			sprite.modulate = Color.WHITE

	# Shake rapide sur chaque sprite matche
	var shake_amount: float = 4.0
	var shake_tw: Tween = create_tween()
	for step in range(3):
		var dir: float = 1.0 if step % 2 == 0 else -1.0
		shake_tw.set_parallel(true)
		for cell_key in all_cells:
			var cell: Vector2i = cell_key as Vector2i
			if _token_sprites.has(cell):
				var sprite: Sprite2D = _token_sprites[cell] as Sprite2D
				var base_pos: Vector2 = _grid_to_pixel(cell.x, cell.y)
				var offset_pos: Vector2 = base_pos + Vector2(shake_amount * dir, 0.0)
				shake_tw.tween_property(sprite, "position", offset_pos, 0.04)
		shake_tw.set_parallel(false)
		shake_tw.tween_interval(0.0)
		shake_amount *= 0.6

	# Retour a la position d'origine
	shake_tw.set_parallel(true)
	for cell_key in all_cells:
		var cell: Vector2i = cell_key as Vector2i
		if _token_sprites.has(cell):
			var sprite: Sprite2D = _token_sprites[cell] as Sprite2D
			var base_pos: Vector2 = _grid_to_pixel(cell.x, cell.y)
			shake_tw.tween_property(sprite, "position", base_pos, 0.03)
	shake_tw.set_parallel(false)

	await shake_tw.finished

	# Pattern labels + score popups par groupe
	for i in range(groups.size()):
		var group: Dictionary = groups[i] as Dictionary
		var group_score: int = scores[i] as int
		var center: Vector2 = _group_center(group["cells"] as Array)

		# Pattern label (ex: "FAMILY LINE x4")
		var pattern_text: String = _build_pattern_text(group)
		_spawn_pattern_label(center, pattern_text)

		if group_score > 0:
			var popup_text: String = "+" + str(group_score)
			if cascade_level > 0:
				popup_text += " x" + str(int(pow(2, cascade_level)))
			var color: Color = score_color if cascade_level == 0 else cascade_score_color
			_spawn_score_popup(center, popup_text, color)

	await get_tree().create_timer(match_highlight_duration * 0.5).timeout


func _animate_remove(event: Dictionary) -> void:
	var cells: Array = event["cells"] as Array

	# Shrink + fade out
	var remove_tween: Tween = create_tween().set_parallel(true)
	for cell_key in cells:
		var cell: Vector2i = cell_key as Vector2i
		if _token_sprites.has(cell):
			var sprite: Sprite2D = _token_sprites[cell] as Sprite2D
			remove_tween.tween_property(sprite, "scale", Vector2.ZERO, remove_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
			remove_tween.tween_property(sprite, "modulate:a", 0.0, remove_duration)

	await remove_tween.finished

	# Supprimer les sprites
	for cell_key in cells:
		var cell: Vector2i = cell_key as Vector2i
		if _token_sprites.has(cell):
			(_token_sprites[cell] as Sprite2D).queue_free()
			_token_sprites.erase(cell)

	await get_tree().create_timer(cascade_pause).timeout


func _animate_gravity(event: Dictionary) -> void:
	var movements: Array = event["movements"] as Array
	if movements.size() == 0:
		return

	var gravity_tween: Tween = create_tween().set_parallel(true)

	for movement in movements:
		var col: int = movement["col"] as int
		var from_row: int = movement["from_row"] as int
		var to_row: int = movement["to_row"] as int
		var from_cell: Vector2i = Vector2i(col, from_row)
		var to_cell: Vector2i = Vector2i(col, to_row)

		if _token_sprites.has(from_cell):
			var sprite: Sprite2D = _token_sprites[from_cell] as Sprite2D
			var target_pos: Vector2 = _grid_to_pixel(col, to_row)

			gravity_tween.tween_property(sprite, "position", target_pos, gravity_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

			# Mettre a jour le dictionnaire
			_token_sprites.erase(from_cell)
			_token_sprites[to_cell] = sprite

	await gravity_tween.finished

	# Petit bounce a l'atterrissage
	var bounce_tween: Tween = create_tween().set_parallel(true)
	for movement in movements:
		var col: int = movement["col"] as int
		var to_row: int = movement["to_row"] as int
		var to_cell: Vector2i = Vector2i(col, to_row)
		if _token_sprites.has(to_cell):
			var sprite: Sprite2D = _token_sprites[to_cell] as Sprite2D
			var base_y: float = _grid_to_pixel(col, to_row).y
			bounce_tween.tween_property(sprite, "position:y", base_y - 6.0, 0.06).set_ease(Tween.EASE_OUT)
	await bounce_tween.finished

	var settle_tween: Tween = create_tween().set_parallel(true)
	for movement in movements:
		var col: int = movement["col"] as int
		var to_row: int = movement["to_row"] as int
		var to_cell: Vector2i = Vector2i(col, to_row)
		if _token_sprites.has(to_cell):
			var sprite: Sprite2D = _token_sprites[to_cell] as Sprite2D
			var base_y: float = _grid_to_pixel(col, to_row).y
			settle_tween.tween_property(sprite, "position:y", base_y, 0.06).set_ease(Tween.EASE_IN)
	await settle_tween.finished


## --- Helpers ---

func _create_sprite(cell: Vector2i, token: TokenData) -> Sprite2D:
	# Supprimer l'ancien sprite s'il existe
	if _token_sprites.has(cell):
		(_token_sprites[cell] as Sprite2D).queue_free()

	var sprite: Sprite2D = Sprite2D.new()
	sprite.centered = true
	sprite.position = _grid_to_pixel(cell.x, cell.y)

	if token.kind == TokenData.Kind.RESIDUE:
		var tex: Texture2D = load("res://assets/special-tokens/ghost.png") as Texture2D
		if tex != null:
			sprite.texture = tex
			var tex_size: float = maxf(tex.get_width(), tex.get_height())
			var target_scale: float = cell_size / tex_size
			sprite.scale = Vector2(target_scale, target_scale)
			sprite.modulate.a = 0.5
	else:
		var tex: Texture2D = TokenVisual.get_texture(token)
		if tex != null:
			sprite.texture = tex
			# Ajuster la scale pour que le sprite rentre dans la cellule
			var tex_size: float = maxf(tex.get_width(), tex.get_height())
			var target_scale: float = cell_size / tex_size
			sprite.scale = Vector2(target_scale, target_scale)

	add_child(sprite)
	_token_sprites[cell] = sprite
	return sprite


func _grid_to_pixel(col: int, row: int) -> Vector2:
	var visual_row: int = GameRules.ROWS - 1 - row
	return Vector2(
		col * (cell_size + cell_gap) + cell_size / 2.0,
		visual_row * (cell_size + cell_gap) + cell_size / 2.0,
	)


func _cell_center(col: int, visual_row: int) -> Vector2:
	return Vector2(
		col * (cell_size + cell_gap) + cell_size / 2.0,
		visual_row * (cell_size + cell_gap) + cell_size / 2.0,
	)


func _group_center(cells: Array) -> Vector2:
	var sum: Vector2 = Vector2.ZERO
	for cell_key in cells:
		var cell: Vector2i = cell_key as Vector2i
		sum += _grid_to_pixel(cell.x, cell.y)
	return sum / cells.size()


func _build_pattern_text(group: Dictionary) -> String:
	var shape: StringName = group["shape"] as StringName
	var rule: StringName = group["match_rule"] as StringName
	var cells: Array = group["cells"] as Array
	var count: int = cells.size()

	if shape == &"diamond":
		return "DIAMOND ROCK"

	var rule_name: String = "FAMILY" if rule == &"family" else "NUMBER"
	var shape_name: String = ""
	if shape == &"square":
		shape_name = "SQUARE"
	else:
		shape_name = "LINE x" + str(count)

	return rule_name + " " + shape_name


func _spawn_score_popup(pos: Vector2, text_value: String, color: Color) -> void:
	var popup: ScorePopup = ScorePopup.new()
	if _popup_font != null:
		popup.add_theme_font_override("font", _popup_font)
	add_child(popup)
	popup.show_at(pos - Vector2(40, 20), text_value, color)


static var _circle_tex_cache: ImageTexture = null

static func _get_circle_texture() -> ImageTexture:
	if _circle_tex_cache != null:
		return _circle_tex_cache
	var size: int = 64
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: float = size / 2.0
	var radius: float = center - 2.0
	for x in range(size):
		for y in range(size):
			var dx: float = x - center
			var dy: float = y - center
			if dx * dx + dy * dy <= radius * radius:
				img.set_pixel(x, y, Color.WHITE)
			else:
				img.set_pixel(x, y, Color.TRANSPARENT)
	_circle_tex_cache = ImageTexture.create_from_image(img)
	return _circle_tex_cache


func _on_grid_reset() -> void:
	# Supprimer tous les sprites
	for cell in _token_sprites:
		(_token_sprites[cell] as Sprite2D).queue_free()
	_token_sprites.clear()
	queue_redraw()


## Convertit une position pixel en coordonnees grille (col, row avec row 0 = bottom).
func pixel_to_grid(local_pos: Vector2) -> Vector2i:
	var col: int = int(local_pos.x / (cell_size + cell_gap))
	var visual_row: int = int(local_pos.y / (cell_size + cell_gap))
	var row: int = GameRules.ROWS - 1 - visual_row
	return Vector2i(col, row)


## Retourne la taille totale de la grille en pixels.
func get_grid_pixel_size() -> Vector2:
	var w: float = GameRules.COLS * (cell_size + cell_gap) - cell_gap
	var h: float = GameRules.ROWS * (cell_size + cell_gap) - cell_gap
	return Vector2(w, h)
