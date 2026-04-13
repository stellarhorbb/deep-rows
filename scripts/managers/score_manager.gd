class_name ScoreManager
extends Node

signal score_changed(new_score: int, delta: int)
signal target_reached(score: int, target: int)

var _score: int = 0
var _target: int = GameRules.BASE_TARGET
var _round: int = 1


func reset_round(round_number: int) -> void:
	_round = round_number
	_score = 0
	_target = GameRules.BASE_TARGET + (round_number - 1) * GameRules.TARGET_INCREMENT
	score_changed.emit(_score, 0)


func add_score(amount: int) -> void:
	if amount <= 0:
		return
	_score += amount
	score_changed.emit(_score, amount)
	if _score >= _target:
		target_reached.emit(_score, _target)


func get_score() -> int:
	return _score


func get_target() -> int:
	return _target


func is_target_reached() -> bool:
	return _score >= _target
