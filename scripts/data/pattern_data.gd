class_name PatternData
extends Resource

enum Rarity { COMMON, UNCOMMON, RARE, EPIC }

@export var tag_name: StringName = &""
@export var shape: StringName = &""       # &"line" | &"square" | &"diamond" | &"plus" | &"cross" | &"ring" | &"t"
@export var rule: StringName = &""        # &"family" | &"value" | &"suite" | &"rock"
@export var min_size: int = 3             # 3 pour lignes, 4 pour carres (2x2 = 4 cells)
@export var direction: StringName = &"any"  # &"horizontal" | &"diagonal" | &"any" (jamais &"vertical")
@export var score_multiplier: float = 1.0   # Multiplicateur applique au score du groupe

## Shop
@export var label: String = ""
@export var price: int = 0
@export var rarity: Rarity = Rarity.COMMON


## Texte de hover en langage clair, reutilise en jeu (TagsUI) et au shop.
func describe() -> String:
	var shape_desc: String
	match shape:
		&"line":    shape_desc = "Ligne de %d+ jetons" % min_size
		&"square":  shape_desc = "Carré 2x2"
		&"diamond": shape_desc = "Losange autour d'un centre"
		&"plus":    shape_desc = "Croix orthogonale (centre inclus)"
		&"cross":   shape_desc = "Croix diagonale (centre inclus)"
		&"ring":    shape_desc = "Cadre 3x3 autour d'un centre"
		&"t":       shape_desc = "Tétromino T, 4 jetons, orientation libre"
		_:          shape_desc = "Figure"

	var rule_desc: String
	match rule:
		&"family": rule_desc = "même famille"
		&"value":  rule_desc = "même valeur"
		&"suite":  rule_desc = "valeurs consécutives"
		&"rock":   rule_desc = "autour d'un Rock"
		_:         rule_desc = ""

	var text: String = label
	text += "\n" + shape_desc
	if rule_desc != "":
		text += ", " + rule_desc

	if shape == &"line":
		text += "\nMulti direction : v x1 / h x1.5 / d x2"
	elif score_multiplier > 1.0:
		text += "\nMultiplicateur fixe x%.1f" % score_multiplier

	return text
