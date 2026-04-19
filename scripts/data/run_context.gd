## Snapshot des donnees du run passe aux systemes (resolver, matcher...).
## Lu, jamais mute par les systemes. Construit par le RunManager a chaque resolution.
class_name RunContext
extends Resource

@export var equipped_tags: Array[PatternData] = []

# Cellules modifiees pour la manche en cours : Vector2i -> StringName (type de modifier).
# Types supportes : MODIFIER_HALF, MODIFIER_BOOST, MODIFIER_DOUBLE, MODIFIER_TRIPLE.
@export var grid_modifiers: Dictionary = {}

# Multiplicateurs de score par rule de pattern : StringName -> float.
# Alimente par les echoes au start_round (ex: "family" -> 2.0 pour "Famille unie").
# Lu par CascadeResolver._score_group.
@export var rule_multipliers: Dictionary = {}

# Extensions futures (ne pas implementer avant d'en avoir besoin) :
# @export var tag_levels: Dictionary = {}        # PatternData -> int
# @export var button_states: Dictionary = {}     # Vector2i -> Array[StateData]
