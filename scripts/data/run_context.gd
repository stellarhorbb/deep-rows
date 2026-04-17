## Snapshot des donnees du run passe aux systemes (resolver, matcher...).
## Lu, jamais mute par les systemes. Construit par le RunManager a chaque resolution.
class_name RunContext
extends Resource

@export var equipped_tags: Array[PatternData] = []

# Cellules modifiees pour la manche en cours : Vector2i -> StringName (type de modifier).
# Pour le moment : uniquement GameRules.MODIFIER_DOUBLE.
@export var grid_modifiers: Dictionary = {}

# Extensions futures (ne pas implementer avant d'en avoir besoin) :
# @export var tag_levels: Dictionary = {}        # PatternData -> int
# @export var active_echoes: Array[EchoData] = []
# @export var button_states: Dictionary = {}     # Vector2i -> Array[StateData]
