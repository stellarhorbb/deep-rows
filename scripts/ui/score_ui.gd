class_name ScoreUI
extends Control

@export var score_manager: ScoreManager
@export var deck_manager: DeckManager

@onready var target_label: Label = $TargetLabel
@onready var score_label: Label = $ScoreLabel
@onready var zone_label: Label = $ZoneLabel
@onready var salt_label: Label = $SaltLabel


func _ready() -> void:
	score_manager.score_changed.connect(_on_score_changed)
	deck_manager.stream_updated.connect(_on_stream_updated)
	_update_display()


func set_round_info(round_number: int) -> void:
	zone_label.text = "THE SURFACE\n" + str(round_number) + ".1"
	target_label.text = "TARGET : " + _format_number(score_manager.get_target())


func _on_score_changed(new_score: int, _delta: int) -> void:
	score_label.text = _format_number(new_score)


func _on_stream_updated(_current: TokenData, _hold: TokenData, _preview: Array[TokenData]) -> void:
	_update_display()


func _update_display() -> void:
	score_label.text = _format_number(score_manager.get_score())
	target_label.text = "TARGET : " + _format_number(score_manager.get_target())


static func _format_number(n: int) -> String:
	var s: String = str(n)
	if n < 1000:
		return s
	# Ajouter des virgules pour les milliers
	var result: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result
