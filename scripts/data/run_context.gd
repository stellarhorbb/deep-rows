## Snapshot des donnees du run passe aux systemes (resolver, matcher...).
## Lu, jamais mute par les systemes. Construit par le RunManager a chaque resolution.
class_name RunContext
extends Resource

@export var equipped_tags: Array[PatternData] = []

# Cellules modifiees pour la manche en cours : Vector2i -> Array[StringName]
# (types de modifiers empiles sur cette case, cumulatifs).
# Types supportes : MODIFIER_HALF, MODIFIER_BOOST, MODIFIER_DOUBLE, MODIFIER_TRIPLE.
@export var grid_modifiers: Dictionary = {}

# Multiplicateurs de score par rule de pattern : StringName -> float.
# Alimente par les badges au start_round (ex: "family" -> 2.0 pour "Famille unie").
# Lu par CascadeResolver._score_group.
@export var rule_multipliers: Dictionary = {}

# Quel Badge a pose chaque rule_multiplier : StringName (rule) -> StringName
# (id du badge, ex: "family" -> "famille_unie"). Sert uniquement a la bannière
# de résolution pour savoir quel Badge faire tilter — jamais lu par le scoring.
@export var rule_multiplier_sources: Dictionary = {}

# Multiplicateur de score par Partition (tag_name -> float), selon son niveau
# (score cumule sur le run). Snapshot au debut de la manche — un level up en
# cours de manche ne s'applique qu'a la manche suivante, comme rule_multipliers.
@export var tag_level_multipliers: Dictionary = {}

# Multiplicateur global dynamique : float. Contrairement aux autres champs,
# celui-ci peut etre mute en cours de manche (ex: "Dernier Carre" reagit au
# deck restant a chaque tour) car RunManager garde une reference vivante vers
# le RunContext actif (voir RunManager.set_global_multiplier). Les autres
# champs restent des snapshots figes au round_start.
@export var global_multiplier: float = 1.0

# Id du badge qui a pose le global_multiplier actuel (attribution pour la
# bannière de résolution, meme principe que rule_multiplier_sources).
@export var global_multiplier_source: StringName = &""

# Bonus de multiplicateur additif par valeur de jeton : int (value) -> float.
# Pour chaque jeton scorable de cette valeur present dans la figure qui score,
# ajoute ce bonus au multiplicateur de la figure (ex: {1: 0.5} pour "Petites
# Mains"). Alimente par les badges au start_round. Lu par CascadeResolver._score_group.
@export var value_bonus_multipliers: Dictionary = {}

# Quel Badge a pose chaque value_bonus_multiplier : int (value) -> StringName
# (id du badge). Meme principe que rule_multiplier_sources.
@export var value_bonus_multiplier_sources: Dictionary = {}

# Extension future (ne pas implementer avant d'en avoir besoin) :
# @export var button_states: Dictionary = {}     # Vector2i -> Array[StateData]
