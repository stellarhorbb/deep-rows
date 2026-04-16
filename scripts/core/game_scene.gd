## Scene racine du jeu. Cable les managers et l'UI.
## Les nodes UI sont dans le scene tree (game.tscn), editables dans l'editeur.
class_name GameScene
extends Node2D

# --- UI (places dans la scene, references par @onready) ---
@onready var grid_visual: GridVisual = $GridVisual
@onready var stream_ui: StreamUI = $StreamUI
@onready var tags_ui: TagsUI = $TagsUI
@onready var message_display: MessageDisplay = $MessageDisplay
@onready var input_handler: InputHandler = $InputHandler
@onready var score_label: Label = $ScoreLabel
@onready var target_label: Label = $TargetLabel
@onready var zone_label: Label = $ZoneLabel

# --- Managers (crees en code, pas de representation visuelle) ---
var turn_controller: TurnController
var grid_manager: GridManager
var deck_manager: DeckManager
var score_manager: ScoreManager
var pattern_manager: PatternManager

enum RunState { PLAYING, ROUND_WON, ROUND_LOST, RUN_WON }

var _current_round: int = 1
var _run_state: RunState = RunState.PLAYING
var _displayed_score: int = 0
var _score_tween: Tween = null


func _ready() -> void:
	_create_managers()
	_wire_references()
	_wire_signals()
	_start_new_run()


func _create_managers() -> void:
	grid_manager = GridManager.new()
	grid_manager.name = "GridManager"
	add_child(grid_manager)

	deck_manager = DeckManager.new()
	deck_manager.name = "DeckManager"
	add_child(deck_manager)

	score_manager = ScoreManager.new()
	score_manager.name = "ScoreManager"
	add_child(score_manager)

	pattern_manager = PatternManager.new()
	pattern_manager.name = "PatternManager"
	add_child(pattern_manager)

	turn_controller = TurnController.new()
	turn_controller.name = "TurnController"
	turn_controller.grid_manager = grid_manager
	turn_controller.deck_manager = deck_manager
	turn_controller.score_manager = score_manager
	turn_controller.pattern_manager = pattern_manager
	add_child(turn_controller)


func _wire_references() -> void:
	grid_visual.grid_manager = grid_manager
	grid_visual.setup()
	stream_ui.deck_manager = deck_manager
	stream_ui.setup()
	tags_ui.pattern_manager = pattern_manager
	tags_ui.setup()
	input_handler.grid_visual = grid_visual
	input_handler.stream_ui = stream_ui
	input_handler.turn_controller = turn_controller
	input_handler.deck_manager = deck_manager
	input_handler.grid_manager = grid_manager


func _wire_signals() -> void:
	score_manager.score_changed.connect(_on_score_changed)
	turn_controller.turn_resolved.connect(_on_turn_resolved)
	turn_controller.last_breath_started.connect(_on_last_breath_started)
	turn_controller.round_won.connect(_on_round_won)
	turn_controller.round_lost.connect(_on_round_lost)
	grid_manager.token_placed.connect(_on_token_placed)
	grid_manager.special_landing.connect(_on_special_landing)
	grid_manager.special_executed.connect(_on_special_executed)
	grid_manager.residues_exploded.connect(_on_residues_exploded)


func _start_new_run() -> void:
	_current_round = 1
	_displayed_score = 0
	_run_state = RunState.PLAYING
	message_display.clear_message()
	# Centrer le pivot du score label pour le scale bump
	score_label.pivot_offset = score_label.size * 0.5
	turn_controller.start_round(_current_round)
	_update_score_display()
	_update_zone_display()
	grid_visual.refresh()
	stream_ui.queue_redraw()


func _advance_to_next_round() -> void:
	_current_round += 1
	_displayed_score = 0
	_run_state = RunState.PLAYING
	message_display.clear_message()
	turn_controller.start_round(_current_round)
	_update_score_display()
	_update_zone_display()
	grid_visual.refresh()
	stream_ui.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		if key_event.keycode == KEY_SPACE or key_event.keycode == KEY_ENTER:
			match _run_state:
				RunState.ROUND_WON:
					_advance_to_next_round()
					get_viewport().set_input_as_handled()
				RunState.ROUND_LOST, RunState.RUN_WON:
					_start_new_run()
					get_viewport().set_input_as_handled()
				_:
					pass


func _update_score_display() -> void:
	score_label.text = _format_number(score_manager.get_score())
	target_label.text = "TARGET : " + _format_number(score_manager.get_target())


func _update_zone_display() -> void:
	var zone: int = (_current_round - 1) / GameRules.ROUNDS_PER_ZONE + 1
	var round_in_zone: int = (_current_round - 1) % GameRules.ROUNDS_PER_ZONE + 1
	zone_label.text = "ZONE " + str(zone) + "\nMANCHE " + str(round_in_zone) + "/" + str(GameRules.ROUNDS_PER_ZONE)


func _on_score_changed(new_score: int, _delta: int) -> void:
	_animate_score_to(new_score)


func _on_turn_resolved(timeline: Array[Dictionary]) -> void:
	grid_visual.clear_hover()
	if timeline.size() > 0:
		await grid_visual.play_timeline(timeline)
	grid_visual.refresh()
	turn_controller.notify_timeline_done()


func _on_round_won(final_score: int, target: int) -> void:
	var total_rounds: int = GameRules.ROUNDS_PER_ZONE * GameRules.ZONES_PER_RUN
	if _current_round >= total_rounds:
		_run_state = RunState.RUN_WON
		message_display.show_message(
			"RUN TERMINEE ! (" + _format_number(final_score) + "/" + _format_number(target) + ") — ESPACE POUR RECOMMENCER",
			&"win",
		)
		return

	_run_state = RunState.ROUND_WON
	message_display.show_message(
		"MANCHE GAGNEE ! (" + _format_number(final_score) + "/" + _format_number(target) + ") — ESPACE POUR CONTINUER",
		&"win",
	)


func _on_last_breath_started() -> void:
	message_display.show_message("DERNIER SOUFFLE...", &"cascade")


func _on_residues_exploded(positions: Array[Vector2i]) -> void:
	if positions.size() > 0:
		grid_visual.rebuild_sprites()
		await get_tree().create_timer(0.4).timeout
	turn_controller.notify_last_breath_ready()


func _on_round_lost(final_score: int, target: int) -> void:
	_run_state = RunState.ROUND_LOST
	message_display.show_message(
		"GAME OVER — " + _format_number(final_score) + "/" + _format_number(target) + " — ESPACE POUR RECOMMENCER",
		&"lose",
	)


## Jeton basique/rock : anime la chute puis notifie le controller.
func _on_token_placed(col: int, row: int, token: TokenData) -> void:
	await grid_visual.animate_drop(col, row, token)
	turn_controller.notify_drop_complete()


## Special : anime la chute vers la landing row puis notifie le controller.
## L'effet logique n'est pas encore execute a ce stade.
func _on_special_landing(col: int, row: int, token: TokenData) -> void:
	await grid_visual.animate_drop(col, row, token)
	# Supprimer le sprite du special (il ne reste pas sur la grille)
	grid_visual.remove_sprite_at(Vector2i(col, row))
	turn_controller.notify_drop_complete()


## Apres que l'effet special ait ete execute (logique) : rebuild les sprites + petite pause.
func _on_special_executed(special_type: TokenData.SpecialType, _col: int, _row: int, result: Dictionary) -> void:
	if special_type == TokenData.SpecialType.BOMBE:
		var bombe_score: int = result.get("score", 0) as int
		if bombe_score > 0:
			message_display.show_message("BOMBE +" + str(bombe_score), &"cascade")

	# Rebuild les sprites pour montrer l'etat apres l'effet
	grid_visual.rebuild_sprites()
	# Petite pause pour que le joueur voie le resultat de l'impact
	await get_tree().create_timer(0.3).timeout
	turn_controller.notify_special_effect_done()


func _animate_score_to(target: int) -> void:
	var from: int = _displayed_score
	_displayed_score = target

	if _score_tween != null and _score_tween.is_valid():
		_score_tween.kill()

	_score_tween = create_tween()
	_score_tween.tween_method(func(val: float) -> void:
		score_label.text = _format_number(int(val))
	, float(from), float(target), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Scale bump
	_score_tween.tween_property(score_label, "scale", Vector2(1.12, 1.12), 0.08).set_ease(Tween.EASE_OUT)
	_score_tween.tween_property(score_label, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_IN_OUT)


static func _format_number(n: int) -> String:
	var s: String = str(n)
	if n < 1000:
		return s
	var result: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result
