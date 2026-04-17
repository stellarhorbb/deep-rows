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

# Recompense par manche gagnee (fixe pour l'instant)
const FLIES_PER_ROUND_WON: int = 10

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
