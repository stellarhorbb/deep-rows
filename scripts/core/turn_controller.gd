class_name TurnController
extends Node

signal turn_started()
signal awaiting_input()
signal drop_animated()
signal special_effect_done()
signal last_breath_ready()
signal turn_resolved(timeline: Array[Dictionary])
signal last_breath_started()
signal round_won(score: int, target: int)
signal round_lost(score: int, target: int)

enum State { AWAITING_INPUT, DROPPING, RESOLVING, LAST_BREATH, ROUND_OVER }

var _state: State = State.AWAITING_INPUT

@export var grid_manager: GridManager
@export var deck_manager: DeckManager
@export var score_manager: ScoreManager
@export var pattern_manager: PatternManager


func _ready() -> void:
	grid_manager.special_executed.connect(_on_special_executed)
	grid_manager.resolution_complete.connect(_on_resolution_complete)


func start_round(round_number: int) -> void:
	score_manager.reset_round(round_number)
	grid_manager.init_grid()
	pattern_manager.load_proto_tags()
	grid_manager.set_active_tags(pattern_manager.get_active_tags())
	deck_manager.build_deck()
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

	# Attendre l'animation de chute
	await drop_animated

	# Pour les specials : executer l'effet apres la chute, attendre l'animation d'impact
	if token.kind == TokenData.Kind.SPECIAL:
		grid_manager.execute_special(token, col)
		await special_effect_done

	# Resolution cascade
	_state = State.RESOLVING
	grid_manager.resolve()


func notify_drop_complete() -> void:
	drop_animated.emit()


func notify_special_effect_done() -> void:
	special_effect_done.emit()


func request_hold() -> void:
	if _state != State.AWAITING_INPUT:
		return
	deck_manager.do_hold()


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

	turn_resolved.emit(timeline)

	if score_manager.is_target_reached():
		_state = State.ROUND_OVER
		round_won.emit(score_manager.get_score(), score_manager.get_target())
		return

	if _state == State.LAST_BREATH:
		_state = State.ROUND_OVER
		round_lost.emit(score_manager.get_score(), score_manager.get_target())
		return

	deck_manager.advance_stream()

	if deck_manager.is_exhausted():
		_trigger_last_breath()
		return

	deck_manager.force_hold_to_current()

	_state = State.AWAITING_INPUT
	awaiting_input.emit()


func notify_last_breath_ready() -> void:
	last_breath_ready.emit()


func _trigger_last_breath() -> void:
	_state = State.LAST_BREATH
	last_breath_started.emit()
	grid_manager.explode_residues()
	await last_breath_ready
	grid_manager.resolve()
