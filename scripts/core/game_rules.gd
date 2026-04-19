class_name GameRules

# Grille
const COLS: int = 6
const ROWS: int = 8

# Patterns — taille minimum
const MIN_MATCH_SIZE: int = 3

# Multiplicateurs de direction (lignes uniquement)
const LINE_MULT_VERTICAL: float = 1.0
const LINE_MULT_HORIZONTAL: float = 1.5
const LINE_MULT_DIAGONAL: float = 2.0

# Cascade — x2 par niveau (pow(2, cascade_level))
const CASCADE_MULTIPLIER_BASE: float = 2.0

# Deck
const DECK_BASE_COUNT: int = 30
const DECK_ROCK_COUNT: int = 4

# Stream
const PREVIEW_SIZE: int = 3

# Scoring
const BASE_TARGET: int = 100
const TARGET_INCREMENT: int = 30

# Structure d'un run
const ROUNDS_PER_ZONE: int = 3
const ZONES_PER_RUN: int = 4

# Pattern tags
const MAX_PATTERN_SLOTS: int = 4

# Echoes
const MAX_ECHO_SLOTS: int = 5

# Recompense par manche gagnee (fixe pour l'instant)
const FLIES_PER_ROUND_WON: int = 10

# Delai avant transition en fin de manche (shop / victoire / defaite) pour
# laisser le temps d'integrer le dernier coup.
const ROUND_END_DELAY: float = 2.0

# Modificateurs de cellules
# Cle stockee dans le dict grid_modifiers : Vector2i -> StringName
const MODIFIER_HALF: StringName = &"half"
const MODIFIER_BOOST: StringName = &"boost"
const MODIFIER_DOUBLE: StringName = &"double"
const MODIFIER_TRIPLE: StringName = &"triple"
const MODIFIER_HALF_MULT: float = 0.5
const MODIFIER_BOOST_MULT: float = 1.5
const MODIFIER_DOUBLE_MULT: float = 2.0
const MODIFIER_TRIPLE_MULT: float = 3.0

# Entity
const ENTITY_DROP_INTERVAL: int = 6  # Un drop tous les N poses joueur

# Valeurs des jetons de base
const TOKEN_MIN_VALUE: int = 1
const TOKEN_MAX_VALUE: int = 5
const FAMILY_COUNT: int = 3


static func get_direction_multiplier(direction: StringName) -> float:
	match direction:
		&"horizontal": return LINE_MULT_HORIZONTAL
		&"diagonal":   return LINE_MULT_DIAGONAL
		_:             return LINE_MULT_VERTICAL  # vertical ou non specifie


static func get_modifier_multiplier(type: StringName) -> float:
	match type:
		MODIFIER_HALF:   return MODIFIER_HALF_MULT
		MODIFIER_BOOST:  return MODIFIER_BOOST_MULT
		MODIFIER_DOUBLE: return MODIFIER_DOUBLE_MULT
		MODIFIER_TRIPLE: return MODIFIER_TRIPLE_MULT
		_:               return 1.0
