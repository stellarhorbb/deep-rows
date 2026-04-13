class_name PatternData
extends Resource

@export var tag_name: StringName = &""
@export var shape: StringName = &""       # &"line" | &"square"
@export var rule: StringName = &""        # &"family" | &"value"
@export var min_size: int = 3             # 3 pour lignes, 4 pour carres (2x2 = 4 cells)
