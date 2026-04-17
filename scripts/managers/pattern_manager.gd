class_name PatternManager
extends Node

signal tags_changed(tags: Array[PatternData])

var _active_tags: Array[PatternData] = []


## Definit les tags actifs pour la manche en cours. Appele par le TurnController
## avec les tags equipes du RunManager.
func set_active_tags(tags: Array[PatternData]) -> void:
	_active_tags = tags.duplicate()
	tags_changed.emit(_active_tags)


func get_active_tags() -> Array[PatternData]:
	return _active_tags
