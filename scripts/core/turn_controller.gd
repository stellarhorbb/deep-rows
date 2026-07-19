class_name TurnController
extends Node

signal turn_started()
signal awaiting_input()
signal drop_animated()
signal special_effect_done()
signal last_breath_ready()
signal timeline_done_ack()
signal turn_resolved(timeline: Array[Dictionary])
signal last_breath_started()
signal round_won(score: int, target: int)
signal round_lost(score: int, target: int)

## Hooks consommes par BadgeManager (dispatch vers les BadgeEffect equipes).
signal round_started()
signal token_dropped(token: TokenData, col: int, row: int)
signal cascade_step_resolved(level: int, earned: int)

enum State { AWAITING_INPUT, DROPPING, RESOLVING, LAST_BREATH, ROUND_OVER }

var _state: State = State.AWAITING_INPUT

@export var grid_manager: GridManager
@export var deck_manager: DeckManager
@export var score_manager: ScoreManager
@export var sheet_manager: SheetManager
@export var run_manager: RunManager


func _ready() -> void:
	grid_manager.special_executed.connect(_on_special_executed)
	grid_manager.resolution_complete.connect(_on_resolution_complete)


func start_round(round_number: int) -> void:
	score_manager.reset_round(round_number)
	grid_manager.init_grid()

	# 0. Grille cabossee : trous aleatoires deja en place avant le premier drop,
	# differents a chaque manche.
	var hole_count: int = randi_range(GameRules.ROUND_START_HOLES_MIN, GameRules.ROUND_START_HOLES_MAX)
	grid_manager.generate_random_holes(hole_count)

	# 1. Reset de la couche modifiers de manche.
	run_manager.reset_round_modifiers()

	# 2. Les badges on_round_start peuplent grid_modifiers et rule_multipliers.
	round_started.emit()

	# 3. Publie le dict final pour l'UI et snapshot le contexte.
	run_manager.notify_grid_modifiers_ready()
	var context: RunContext = run_manager.build_context()
	sheet_manager.set_active_sheets(context.equipped_sheets)
	grid_manager.set_run_context(context)

	deck_manager.hold_capacity = GameRules.BASE_HOLD_SLOTS + context.hold_slot_bonus
	deck_manager.preview_bonus = context.preview_size_bonus
	deck_manager.rock_count_bonus = context.rock_count_bonus
	deck_manager.build_deck(run_manager.get_deck_composition(), run_manager.get_button_pool())
	deck_manager.advance_stream()
	_state = State.AWAITING_INPUT
	turn_started.emit()
	awaiting_input.emit()


func play_current_to(col: int, row: int) -> void:
	if _state != State.AWAITING_INPUT:
		return

	var token: TokenData = deck_manager.get_current()
	if token == null:
		return
	if not grid_manager.can_play_token(token, col, row):
		return

	_state = State.DROPPING
	deck_manager.consume_current()

	# Place le jeton (logique + signals)
	grid_manager.place_token(token, col, row)
	token_dropped.emit(token, col, row)

	# Attendre l'animation de chute
	await drop_animated

	# Pour les specials : executer l'effet apres la chute, attendre l'animation
	# d'impact. Consomme le special de l'inventaire persistant a cet instant
	# precis (pas avant) — tant qu'il n'est pas reellement joue, il reste dans
	# le deck manche apres manche (voir RunManager.consume_special).
	if token.kind == TokenData.Kind.SPECIAL:
		run_manager.consume_special(token.special_type)
		grid_manager.execute_special(token, col)
		await special_effect_done

	# Resolution cascade
	_state = State.RESOLVING
	grid_manager.resolve()


func notify_drop_complete() -> void:
	drop_animated.emit()


func notify_special_effect_done() -> void:
	special_effect_done.emit()


func request_hold(slot_index: int = -1) -> void:
	if _state != State.AWAITING_INPUT:
		return
	deck_manager.do_hold(slot_index)


func get_state() -> State:
	return _state


func _on_special_executed(special_type: TokenData.SpecialType, _col: int, _row: int, result: Dictionary) -> void:
	if special_type == TokenData.SpecialType.BOMBE:
		var bombe_score: int = result.get("score", 0) as int
		if bombe_score > 0:
			score_manager.add_score(bombe_score)


func _on_resolution_complete(timeline: Array[Dictionary], total_score: int) -> void:
	if total_score > 0:
		score_manager.add_score(total_score)

	# Emet un hook par MATCH event pour les badges on_cascade_step, et
	# remonte le score de chaque groupe a sa Partition pour le level up.
	# UPGRADE (ex: Poker Face) : le tirage a deja eu lieu dans CascadeResolver
	# (avant que le visuel n'anime la montee en valeur) — ici on applique juste
	# la mutation reelle sur le pool de boutons.
	for event in timeline:
		if event["type"] == CascadeResolver.EventType.MATCH:
			var groups: Array = event["groups"] as Array
			var scores: Array = event["scores"] as Array
			for i in range(groups.size()):
				var group: Dictionary = groups[i] as Dictionary
				var sheet_name: StringName = group.get("sheet_name", &"") as StringName
				run_manager.add_sheet_score(sheet_name, scores[i] as int)
			cascade_step_resolved.emit(event["cascade_level"] as int, event["total_earned"] as int)
		elif event["type"] == CascadeResolver.EventType.UPGRADE:
			for entry in (event["upgrades"] as Array):
				var data: Dictionary = entry as Dictionary
				var family: TokenData.Family = data["family"] as TokenData.Family
				var value: int = data["value"] as int
				# >= MAX_BUTTON_VALUE : suite des figures (arcanes mineurs),
				# chemin distinct du +1 normal (voir GameRules.next_face_value).
				if value >= GameRules.MAX_BUTTON_VALUE:
					run_manager.promote_matching_button(family, value)
				else:
					run_manager.upgrade_matching_button(family, value)
		elif event["type"] == CascadeResolver.EventType.TRANSFORM:
			# Legendaire "Last Trick" : le tirage (chance + famille) a deja eu
			# lieu dans CascadeResolver — ici on ajoute reellement le jeton au
			# pool possede, definitivement (voir GameRules.LAST_TRICK_VALUE).
			for entry in (event["transforms"] as Array):
				var data: Dictionary = entry as Dictionary
				var family: TokenData.Family = data["family"] as TokenData.Family
				run_manager.add_button(family, GameRules.LAST_TRICK_VALUE)

	turn_resolved.emit(timeline)

	if score_manager.is_target_reached():
		# Attend toujours la fin de l'animation (banniere de resolution comprise)
		# avant de declarer la victoire — sinon la transition peut demarrer
		# pendant que le decompte du score est encore en train de se derouler.
		await timeline_done_ack
		_state = State.ROUND_OVER
		round_won.emit(score_manager.get_score(), score_manager.get_target())
		return

	if _state == State.LAST_BREATH:
		await timeline_done_ack
		_state = State.ROUND_OVER
		round_lost.emit(score_manager.get_score(), score_manager.get_target())
		return

	deck_manager.advance_stream()

	if deck_manager.is_exhausted():
		_trigger_last_breath()
		return

	deck_manager.force_hold_to_current()

	# Grille pleine, deck pas vide : aucun coup legal possible (sauf un
	# Fantome en main/hold, qui peut cibler une colonne pleine). Sans lui, le
	# joueur serait bloque indefiniment — meme traitement que le deck vide.
	if not _has_legal_move():
		_trigger_last_breath()
		return

	_state = State.AWAITING_INPUT
	awaiting_input.emit()


## Verifie si le jeton courant ou l'un des jetons tenus (voir hold_capacity,
## potentiellement plusieurs slots depuis "Benediction") a au moins une
## colonne jouable. Utilise pour detecter un plateau bloque (voir
## _on_resolution_complete).
func _has_legal_move() -> bool:
	var current: TokenData = deck_manager.get_current()
	var held: Array[TokenData] = deck_manager.get_hold_slots()
	for col in range(GameRules.COLS):
		if current != null and grid_manager.can_play_token(current, col, 0):
			return true
		for hold in held:
			if hold != null and grid_manager.can_play_token(hold, col, 0):
				return true
	return false


func notify_last_breath_ready() -> void:
	last_breath_ready.emit()


func notify_timeline_done() -> void:
	timeline_done_ack.emit()


func _trigger_last_breath() -> void:
	_state = State.LAST_BREATH
	last_breath_started.emit()
	grid_manager.explode_residues()
	await last_breath_ready
	grid_manager.resolve()
