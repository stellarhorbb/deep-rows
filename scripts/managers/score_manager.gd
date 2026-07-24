class_name ScoreManager
extends Node

signal score_changed(new_score: int, delta: int)
signal target_reached(score: int, target: int)

var _score: int = 0
var _target: int = GameRules.ROUND_TARGETS[0]
var _round: int = 1


func reset_round(round_number: int) -> void:
	_round = round_number
	_score = 0
	var targets: Array[int] = GameRules.ROUND_TARGETS
	_target = targets[clampi(round_number - 1, 0, targets.size() - 1)]
	score_changed.emit(_score, 0)


func add_score(amount: int) -> void:
	if amount <= 0:
		return
	_score += amount
	score_changed.emit(_score, amount)
	if _score >= _target:
		target_reached.emit(_score, _target)


## Case mystere SCORE_DOWN (voir MysteryCellEffects) : seul malus capable de
## retirer du score actuel de la manche. Plafonne a 0 plutot que de basculer
## en negatif — aucun autre systeme du jeu ne s'attend a un score negatif.
func subtract_score(amount: int) -> void:
	if amount <= 0:
		return
	var clamped: int = mini(amount, _score)
	_score -= clamped
	score_changed.emit(_score, -clamped)


func get_score() -> int:
	return _score


func get_target() -> int:
	return _target


func is_target_reached() -> bool:
	return _score >= _target
