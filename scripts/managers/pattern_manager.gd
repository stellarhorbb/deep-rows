class_name PatternManager
extends Node

signal tags_loaded(tags: Array[PatternData])

## Chemins des Tags equipes par defaut (proto). A terme : equipage via pack + shop.
const PROTO_TAG_PATHS: Array[String] = [
	"res://resources/patterns/line_number_3.tres",
	"res://resources/patterns/line_family_4.tres",
	"res://resources/patterns/square_family.tres",
	"res://resources/patterns/diamond_rock.tres",
]

var _active_tags: Array[PatternData] = []


## Charge les Tags equipes depuis les .tres.
func load_proto_tags() -> void:
	_active_tags.clear()
	for path in PROTO_TAG_PATHS:
		var tag: PatternData = load(path) as PatternData
		if tag != null:
			_active_tags.append(tag)
	tags_loaded.emit(_active_tags)


func get_active_tags() -> Array[PatternData]:
	return _active_tags
