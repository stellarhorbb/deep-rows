## Dispatch les triggers de badges vers les effets des badges equipes.
## Vit dans RunService (persistant entre manches). Se branche sur les signaux
## de TurnController a chaque manche via bind_round().
class_name BadgeManager
extends Node

var run_manager: RunManager
var _deck_manager: DeckManager
var _grid_manager: GridManager


## Connecte tous les hooks de la manche en cours. Les signaux seront
## automatiquement nettoyes quand le turn_controller sera free (fin de scene).
func bind_round(turn_controller: TurnController) -> void:
	_deck_manager = turn_controller.deck_manager
	_grid_manager = turn_controller.grid_manager
	turn_controller.round_started.connect(_on_round_started)
	turn_controller.token_dropped.connect(_on_token_dropped)
	turn_controller.cascade_step_resolved.connect(_on_cascade_step)
	turn_controller.turn_resolved.connect(_on_turn_resolved)
	turn_controller.last_breath_started.connect(_on_last_breath)


func _on_round_started() -> void:
	# Trous deja generes a ce stade (TurnController.start_round, etape 0 avant
	# l'emission de round_started) — les badges a cellule unique (Cellule
	# Double/Triple) s'en servent pour ne jamais cibler une case inaccessible.
	var holes: Dictionary = _grid_manager.get_holes() if _grid_manager != null else {}
	_dispatch(&"on_round_start", {"holes": holes})


func _on_token_dropped(token: TokenData, col: int, row: int) -> void:
	var deck_remaining: int = _deck_manager.get_remaining() if _deck_manager != null else 0
	_dispatch(&"on_token_drop", {"token": token, "col": col, "row": row, "deck_remaining": deck_remaining})


func _on_cascade_step(level: int, earned: int) -> void:
	_dispatch(&"on_cascade_step", {"cascade_level": level, "earned": earned})


func _on_turn_resolved(timeline: Array[Dictionary]) -> void:
	_dispatch(&"on_turn_resolved", {"timeline": timeline})


func _on_last_breath() -> void:
	_dispatch(&"on_last_breath", {})


## Declenche les badges on_round_end (ex : Pourboire) et retourne le detail
## des mouches ajoutees par badge, pour l'ecran de fin de manche (voir
## GameScene._on_round_won / YouWinUI).
func dispatch_round_end() -> Dictionary:
	return _dispatch(&"on_round_end", {})


## Retourne {label_badge: mouches_ajoutees} pour les badges qui ont augmente
## les mouches pendant ce dispatch (diff avant/apres chaque effet) — les
## appelants qui n'en ont pas besoin (tous les autres triggers) ignorent
## simplement la valeur de retour.
func _dispatch(trigger: StringName, event: Dictionary) -> Dictionary:
	var flies_breakdown: Dictionary = {}
	if run_manager == null:
		return flies_breakdown
	for badge in run_manager.get_equipped_badges():
		if badge.trigger != trigger:
			continue
		var effect: BadgeEffect = badge.make_effect()
		if effect == null:
			continue
		var flies_before: int = run_manager.get_flies()
		effect.apply(event, run_manager)
		var flies_delta: int = run_manager.get_flies() - flies_before
		if flies_delta > 0:
			flies_breakdown[badge.label] = (flies_breakdown.get(badge.label, 0) as int) + flies_delta
	return flies_breakdown
