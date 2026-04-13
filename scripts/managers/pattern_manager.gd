class_name PatternManager
extends Node

signal tags_loaded(tags: Array[PatternData])

var _active_tags: Array[PatternData] = []


## Pour le proto : cree les 4 tags toujours actifs (line/square × family/value).
func load_proto_tags() -> void:
	_active_tags.clear()

	var line_family: PatternData = PatternData.new()
	line_family.tag_name = &"line_family"
	line_family.shape = &"line"
	line_family.rule = &"family"
	line_family.min_size = 3

	var line_value: PatternData = PatternData.new()
	line_value.tag_name = &"line_value"
	line_value.shape = &"line"
	line_value.rule = &"value"
	line_value.min_size = 3

	var square_family: PatternData = PatternData.new()
	square_family.tag_name = &"square_family"
	square_family.shape = &"square"
	square_family.rule = &"family"
	square_family.min_size = 4

	var square_value: PatternData = PatternData.new()
	square_value.tag_name = &"square_value"
	square_value.shape = &"square"
	square_value.rule = &"value"
	square_value.min_size = 4

	_active_tags = [line_family, line_value, square_family, square_value]
	tags_loaded.emit(_active_tags)


func get_active_tags() -> Array[PatternData]:
	return _active_tags
