class_name GameRules

# Grille
const COLS: int = 6
const ROWS: int = 8

# Patterns — taille minimum
const MIN_MATCH_SIZE: int = 3

# Multiplicateurs lignes (par longueur)
const LINE_MULT_3: float = 1.0
const LINE_MULT_4: float = 2.0
const LINE_MULT_5: float = 3.0
const LINE_MULT_6_PLUS: float = 5.0

# Multiplicateur carre 2x2
const SQUARE_MULTIPLIER: float = 3.0

# Cascade — x2 par niveau (pow(2, cascade_level))
const CASCADE_MULTIPLIER_BASE: float = 2.0

# Deck
const DECK_BASE_COUNT: int = 50
const DECK_ROCK_COUNT: int = 8
const DECK_FANTOME_COUNT: int = 2
const DECK_BOMBE_COUNT: int = 3
const DECK_MAREE_COUNT: int = 1

# Stream
const PREVIEW_SIZE: int = 3

# Scoring
const BASE_TARGET: int = 100
const TARGET_INCREMENT: int = 30

# Bombe
const BOMBE_MULTIPLIER: float = 2.0

# Valeurs des jetons de base
const TOKEN_MIN_VALUE: int = 1
const TOKEN_MAX_VALUE: int = 5
const FAMILY_COUNT: int = 4


static func get_line_multiplier(length: int) -> float:
	if length <= 3:
		return LINE_MULT_3
	if length == 4:
		return LINE_MULT_4
	if length == 5:
		return LINE_MULT_5
	return LINE_MULT_6_PLUS
