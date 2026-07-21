class_name GridVisual
extends Node2D

## Emis quand la banniere de resolution termine sa sequence pour un groupe —
## le compteur de score affiche (game_scene.gd) s'incremente a ce moment,
## pas au moment ou le score est logiquement ajoute au ScoreManager (plus tot).
signal group_score_revealed(amount: int)

@export var cell_size: float = 90.0
@export var cell_gap: float = 6.0
@export var empty_cell_color: Color = Color("e8e8e8")
@export var hole_color: Color = Color("2a2a38")
@export var blocked_column_color: Color = Color(0.15, 0.15, 0.15, 0.5)
@export var entity_blink_interval: float = 0.3  # jetons a countdown (MÈCHE COURTE, PETARD_A_MECHE), voir _setup_countdown_sprite
@export var residue_color: Color = Color("b8b3d6")
@export var modifier_border_width: float = 6.0

## Couleurs par type de modifier (StringName -> Color)
@export var modifier_color_half: Color = Color("b33d3d")    # rouge (x0.5)
@export var modifier_color_boost: Color = Color("3d8b5a")   # vert (x1.5)
@export var modifier_color_double: Color = Color("1a2b5c")  # bleu fonce (x2)
@export var modifier_color_triple: Color = Color("6b1a99")  # violet (x3)

## Timing des animations
@export var drop_duration: float = 0.25
@export var match_highlight_duration: float = 0.35
@export var remove_duration: float = 0.25
@export var gravity_duration: float = 0.18
@export var cascade_pause: float = 0.15
@export var upgrade_hold_duration: float = 0.6
@export var upgrade_fade_duration: float = 0.3
@export var upgrade_pause: float = 0.2
@export var rockify_flash_duration: float = 0.25
@export var rockify_pause: float = 0.15

@export var grid_manager: GridManager
@export var badges_ui: BadgesUI
@export var resolution_banner: ResolutionBanner

var _token_sprites: Dictionary = {}  # Vector2i -> Sprite2D
var _grid_modifiers: Dictionary = {}  # Vector2i -> Array[StringName]
var _holes: Dictionary = {}  # Vector2i -> true
var _blocked_column: int = -1  # COLONNE MAUDITE, voir GridManager
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
			var is_hole: bool = _holes.has(Vector2i(c, r))
			draw_circle(center, cell_size / 2.0, hole_color if is_hole else empty_cell_color)
			if c == _blocked_column:
				draw_circle(center, cell_size / 2.0, blocked_column_color)

	# Contour des cellules modifiees (par dessus le fond, sous les sprites).
	# Plusieurs modifiers empiles sur une meme case = plusieurs anneaux
	# concentriques, du plus large (premier empile) au plus etroit (dernier).
	for cell_key in _grid_modifiers:
		var cell: Vector2i = cell_key as Vector2i
		var types: Array = _grid_modifiers[cell_key] as Array
		var visual_row_m: int = GameRules.ROWS - 1 - cell.y
		var c_center: Vector2 = _cell_center(cell.x, visual_row_m)
		for i in range(types.size()):
			var ring_radius: float = cell_size / 2.0 - i * (modifier_border_width + 2.0)
			if ring_radius <= 0.0:
				break
			draw_arc(c_center, ring_radius, 0.0, TAU, 48, _modifier_color(types[i] as StringName), modifier_border_width)


func _modifier_color(type: StringName) -> Color:
	match type:
		GameRules.MODIFIER_HALF:   return modifier_color_half
		GameRules.MODIFIER_BOOST:  return modifier_color_boost
		GameRules.MODIFIER_DOUBLE: return modifier_color_double
		GameRules.MODIFIER_TRIPLE: return modifier_color_triple
	return modifier_color_double


## Appele par game_scene quand RunManager emet grid_modifiers_changed.
func set_grid_modifiers(modifiers: Dictionary) -> void:
	_grid_modifiers = modifiers
	queue_redraw()


## Appele par game_scene quand GridManager emet holes_changed.
func set_holes(holes: Dictionary) -> void:
	_holes = holes
	queue_redraw()


## Appele par game_scene quand GridManager emet blocked_column_changed.
func set_blocked_column(col: int) -> void:
	_blocked_column = col
	queue_redraw()


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


## Remplace le sprite d'une cellule par celui du nouveau jeton (ex: Badge
## "Récif vivant" qui transforme un jeton en rock). _create_sprite supprime
## deja l'ancien sprite avant d'en creer un nouveau.
func replace_sprite(cell: Vector2i, token: TokenData) -> void:
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

		elif event_type == CascadeResolver.EventType.UPGRADE:
			await _animate_upgrade(event)

		elif event_type == CascadeResolver.EventType.REMOVE:
			await _animate_remove(event)

		elif event_type == CascadeResolver.EventType.ROCKIFY:
			await _animate_rockify(event)

		elif event_type == CascadeResolver.EventType.TRANSFORM:
			await _animate_transform(event)

		elif event_type == CascadeResolver.EventType.GRAVITY:
			await _animate_gravity(event)

	_is_animating = false


func is_animating() -> bool:
	return _is_animating


func refresh() -> void:
	sync_sprites()
	_refresh_countdown_labels()
	queue_redraw()


## Les jetons a countdown (entity-skull de MÈCHE COURTE, special PETARD_A_MECHE)
## affichent leur chiffre dans un Label enfant du sprite (voir
## _setup_countdown_sprite), qui ne se met a jour que si on le repousse
## explicitement — sync_sprites ne fait que creer/detruire des sprites,
## jamais rafraichir le contenu d'un sprite deja existant. Sans ca, le
## chiffre affiche reste fige sur sa valeur de creation meme si le countdown
## logique continue de descendre (le jeton explose bien au bon moment, seul
## l'affichage etait fige).
func _refresh_countdown_labels() -> void:
	for cell_key in _token_sprites:
		var cell: Vector2i = cell_key as Vector2i
		var token: TokenData = grid_manager.get_cell(cell.x, cell.y)
		if token == null or token.countdown < 0:
			continue
		var is_countdown_kind: bool = token.kind == TokenData.Kind.ENTITY or (token.kind == TokenData.Kind.SPECIAL and token.special_type == TokenData.SpecialType.PETARD_A_MECHE)
		if not is_countdown_kind:
			continue
		var sprite: Sprite2D = _token_sprites[cell] as Sprite2D
		for child in sprite.get_children():
			if child is Label:
				(child as Label).text = str(token.countdown)


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

	# TokenVisual.SPECIAL_SPRITES couvre deja tous les speciaux (sprite neutre
	# pre-pose) : plus besoin de dupliquer la liste ici comme avant
	# (Fantome/Bombe/Maree en dur), qui laissait tout special ajoute depuis
	# sans preview au hover.
	var tex: Texture2D = TokenVisual.get_texture(token)

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
	if token.kind == TokenData.Kind.BASE:
		_add_value_label(_hover_sprite, token.value, tex.get_size())
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

	# Annonce dediee si ce MATCH event est une vraie cascade (2+ resolutions
	# chainees dans le tour, cascade_level >= 1) — un seul appel ici suffit,
	# _animate_match est deja scope a un seul niveau par le timeline.
	if resolution_banner != null and cascade_level >= 1:
		var cascade_mult: float = pow(GameRules.CASCADE_MULTIPLIER_BASE, cascade_level)
		await resolution_banner.play_cascade_announcement(cascade_mult)

	# Banniere de resolution decomposee, un groupe a la fois (remplace les
	# anciens popups "+X"/labels de pattern par groupe — narration sequentielle
	# unique plutot que du texte disperse sur la grille).
	if resolution_banner != null:
		for i in range(groups.size()):
			var group: Dictionary = groups[i] as Dictionary
			var group_score: int = scores[i] as int
			var breakdown: Dictionary = group.get("score_breakdown", {}) as Dictionary
			if group_score <= 0 or breakdown.is_empty():
				continue
			# Diamond Rock/legendaires (Royal Square) : petite roulette casino
			# avant le detail du score (voir CascadeResolver._score_group —
			# breakdown.roll/roll_min/roll_max, la plage varie selon le sheet).
			if breakdown.has("roll"):
				await resolution_banner.play_roll_announcement(breakdown["roll"] as int, breakdown["roll_min"] as int, breakdown["roll_max"] as int)
			await resolution_banner.play_breakdown(breakdown, group_score, badges_ui)
			group_score_revealed.emit(group_score)

		# "Double Partition" : deux figures distinctes ont matche sur le meme
		# placement sans que l'une contienne l'autre (voir CascadeResolver).
		# Revele apres le detail des groupes, comme un bonus qui recompense le
		# coup delibere plutot que noye dans les MULTI individuels.
		var combo_bonus: int = event.get("combo_bonus", 0) as int
		if combo_bonus > 0:
			await resolution_banner.play_combo_announcement(GameRules.PATTERN_COMBO_MULTIPLIER)
			group_score_revealed.emit(combo_bonus)
	else:
		await get_tree().create_timer(match_highlight_duration * 0.5).timeout


## Anime les jetons qui viennent de gagner +1 de valeur (ex: "Poker Face") —
## joue juste avant _animate_remove dans la timeline, pour montrer la montee
## en valeur avant que le jeton ne disparaisse. Le label numerique n'existe
## que si GameRules.DEBUG_SHOW_TOKEN_VALUE est actif (voir _add_value_label,
## la valeur des jetons n'est pas encore representee visuellement en dehors
## de ce mode) — le flash dore, lui, joue toujours. Tenu quelques instants
## (upgrade_hold_duration) avant de s'estomper en fondu, pour laisser le temps
## de le voir (retour de playtest : trop rapide en instantane).
func _animate_upgrade(event: Dictionary) -> void:
	var upgrades: Array = event.get("upgrades", []) as Array
	if upgrades.is_empty():
		return

	for entry in upgrades:
		var data: Dictionary = entry as Dictionary
		var cell: Vector2i = data["cell"] as Vector2i
		if not _token_sprites.has(cell):
			continue
		var sprite: Sprite2D = _token_sprites[cell] as Sprite2D
		for child in sprite.get_children():
			if child is Label:
				(child as Label).text = TokenData.value_label(data["next_value"] as int)
		sprite.modulate = Color(2.5, 2.0, 0.4, 1.0)

	await get_tree().create_timer(upgrade_hold_duration).timeout

	var fade_tween: Tween = create_tween().set_parallel(true)
	for entry in upgrades:
		var cell: Vector2i = (entry as Dictionary)["cell"] as Vector2i
		if _token_sprites.has(cell):
			fade_tween.tween_property(_token_sprites[cell] as Sprite2D, "modulate", Color.WHITE, upgrade_fade_duration)
	await fade_tween.finished

	await get_tree().create_timer(upgrade_pause).timeout


## Anime les jetons qui viennent de "se petrifier" (ex: "Récif vivant") — joue
## apres _animate_remove : le reste du groupe a deja disparu, celui-la se
## transforme en rock a la place. Flash grise puis swap du sprite (reutilise
## replace_sprite, meme fonction que _create_sprite).
func _animate_rockify(event: Dictionary) -> void:
	var cells: Array = event.get("cells", []) as Array
	if cells.is_empty():
		return

	for cell_key in cells:
		var cell: Vector2i = cell_key as Vector2i
		if _token_sprites.has(cell):
			(_token_sprites[cell] as Sprite2D).modulate = Color(0.5, 0.5, 0.55, 1.0)

	await get_tree().create_timer(rockify_flash_duration).timeout

	for cell_key in cells:
		var cell: Vector2i = cell_key as Vector2i
		replace_sprite(cell, TokenData.make_rock())

	await get_tree().create_timer(rockify_pause).timeout


## Anime une case qui se transforme en jeton de base au lieu de disparaitre
## normalement — Diamond "Last Trick" (legendaire, toujours LAST_TRICK_VALUE)
## OU special "Hypercube" (family/value du jeton duplique, voir
## CascadeResolver.resolve) — meme squelette que _animate_rockify (flash puis
## swap de sprite). Last Trick ne porte pas de cle "value" dans son entry
## (fallback LAST_TRICK_VALUE), Hypercube si — meme convention que
## TurnController._on_resolution_complete.
func _animate_transform(event: Dictionary) -> void:
	var transforms: Array = event.get("transforms", []) as Array
	if transforms.is_empty():
		return

	for entry in transforms:
		var data: Dictionary = entry as Dictionary
		var cell: Vector2i = data["cell"] as Vector2i
		if _token_sprites.has(cell):
			(_token_sprites[cell] as Sprite2D).modulate = Color(1.0, 0.9, 0.4, 1.0)

	await get_tree().create_timer(rockify_flash_duration).timeout

	for entry in transforms:
		var data: Dictionary = entry as Dictionary
		var cell: Vector2i = data["cell"] as Vector2i
		var family: TokenData.Family = data["family"] as TokenData.Family
		var value: int = data.get("value", GameRules.LAST_TRICK_VALUE) as int
		replace_sprite(cell, TokenData.make_base(family, value))

	await get_tree().create_timer(rockify_pause).timeout


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
	elif token.kind == TokenData.Kind.ENTITY:
		if token.countdown >= 0:
			_setup_countdown_sprite(sprite, token, "res://assets/entity/skull-red.png", "res://assets/entity/skull-black.png")
		else:
			var tex: Texture2D = load("res://assets/tokens/entity-skull.png") as Texture2D
			if tex != null:
				sprite.texture = tex
				var tex_size: float = maxf(tex.get_width(), tex.get_height())
				var target_scale: float = cell_size / tex_size
				sprite.scale = Vector2(target_scale, target_scale)
	elif token.kind == TokenData.Kind.SPECIAL and token.special_type == TokenData.SpecialType.PETARD_A_MECHE and token.countdown >= 0:
		_setup_countdown_sprite(sprite, token, "res://assets/special-tokens/petard-red.png", "res://assets/special-tokens/petard-black.png")
	else:
		var tex: Texture2D = TokenVisual.get_texture(token)
		if tex != null:
			sprite.texture = tex
			# Ajuster la scale pour que le sprite rentre dans la cellule
			var tex_size: float = maxf(tex.get_width(), tex.get_height())
			var target_scale: float = cell_size / tex_size
			sprite.scale = Vector2(target_scale, target_scale)
			if token.kind == TokenData.Kind.BASE:
				_add_value_label(sprite, token.value, tex.get_size())

	add_child(sprite)
	_token_sprites[cell] = sprite
	return sprite


## Ajoute la valeur en texte blanc par dessus un bouton "nude". Dimensionne
## dans l'espace local de la texture (pas dans l'espace cellule) pour que le
## texte soit downscale avec le sprite plutot qu'upscale depuis une petite
## police — evite le flou.
func _add_value_label(sprite: Sprite2D, value: int, tex_size: Vector2) -> void:
	if not GameRules.DEBUG_SHOW_TOKEN_VALUE:
		return
	var label: Label = Label.new()
	var text: String = TokenData.value_label(value)
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size = tex_size
	label.pivot_offset = tex_size / 2.0
	label.position = -label.pivot_offset
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.WHITE)
	if _popup_font != null:
		label.add_theme_font_override("font", _popup_font)
	# Police retrecie pour les noms de figure (ex: "CHEVALIER") : trop long
	# pour tenir a la taille normale d'un chiffre seul.
	var size_ratio: float = 0.4 if text.length() <= 2 else 0.18
	label.add_theme_font_size_override("font_size", int(tex_size.y * size_ratio))
	sprite.add_child(label)


## Texture qui clignote rouge/noir + countdown toujours visible pour tout
## jeton a decompte (contrairement a _add_value_label, pas derriere le flag
## debug — c'est le telegraphing du danger/de l'imminence, pas un aide-debug
## seulement). Partage par l'entity-skull (malus MÈCHE COURTE) et le special
## PETARD_A_MECHE — seuls les chemins de texture different.
func _setup_countdown_sprite(sprite: Sprite2D, token: TokenData, red_path: String, black_path: String) -> void:
	var red_tex: Texture2D = load(red_path) as Texture2D
	var black_tex: Texture2D = load(black_path) as Texture2D
	var tex: Texture2D = red_tex if red_tex != null else black_tex
	if tex == null:
		return
	sprite.texture = tex
	var tex_size: float = maxf(tex.get_width(), tex.get_height())
	sprite.scale = Vector2(cell_size / tex_size, cell_size / tex_size)

	var label: Label = Label.new()
	label.text = str(token.countdown)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size = tex.get_size()
	label.pivot_offset = label.size / 2.0
	label.position = -label.pivot_offset
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.WHITE)
	if _popup_font != null:
		label.add_theme_font_override("font", _popup_font)
	label.add_theme_font_size_override("font_size", int(tex.get_size().y * 0.4))
	sprite.add_child(label)

	if red_tex == null or black_tex == null:
		return
	var blink: Tween = create_tween().set_loops()
	blink.tween_callback(func() -> void:
		if is_instance_valid(sprite):
			sprite.texture = black_tex
		else:
			blink.kill()
	).set_delay(entity_blink_interval)
	blink.tween_callback(func() -> void:
		if is_instance_valid(sprite):
			sprite.texture = red_tex
		else:
			blink.kill()
	).set_delay(entity_blink_interval)


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
