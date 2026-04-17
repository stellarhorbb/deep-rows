class_name PatternData
extends Resource

@export var tag_name: StringName = &""
@export var shape: StringName = &""       # &"line" | &"square" | &"diamond"
@export var rule: StringName = &""        # &"family" | &"value" | &"suite" | &"rock"
@export var min_size: int = 3             # 3 pour lignes, 4 pour carres (2x2 = 4 cells)
@export var direction: StringName = &"any"  # &"horizontal" | &"diagonal" | &"any" (jamais &"vertical")
@export var score_multiplier: float = 1.0   # Multiplicateur applique au score du groupe

## Shop
@export var label: String = ""
@export var price: int = 0
