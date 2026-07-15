class_name GameRules

# Grille
const COLS: int = 7
const ROWS: int = 7

# Patterns — taille minimum
const MIN_MATCH_SIZE: int = 3

# Chevauchement de figures dans un meme tour (CascadeResolver.resolve) : deux
# groupes qui partagent au moins une cellule sans que l'un soit entierement
# inclus dans l'autre sont un "Double Partition" delibere — les deux scorent
# et leur total combine est multiplie par ce facteur. Si l'un des deux groupes
# est un sous-ensemble strict de l'autre (ex: T contenu dans Plus, memes
# jetons), ce n'est pas un combo : seule la mieux payee compte, comme avant.
const PATTERN_COMBO_MULTIPLIER: float = 2.0

# Cascade — x2 par niveau (pow(2, cascade_level))
const CASCADE_MULTIPLIER_BASE: float = 2.0

# Deck
const DECK_ROCK_COUNT: int = 4

# "Grille cabossee" — trous generes au debut de chaque manche (jamais en row 0,
# le sol reste toujours garanti). Un jeton qui tombe les traverse sans pouvoir
# s'y arreter — different d'un Rock, qui bloque et sert d'appui.
const ROUND_START_HOLES_MIN: int = 5
const ROUND_START_HOLES_MAX: int = 8

# Stream
const PREVIEW_SIZE: int = 3
const BASE_HOLD_SLOTS: int = 1

# Scoring
const BASE_TARGET: int = 60
const TARGET_INCREMENT: int = 30

# Structure d'un run
const ROUNDS_PER_ZONE: int = 3
const ZONES_PER_RUN: int = 4

# Pattern tags
const MAX_PATTERN_SLOTS: int = 4

# Selection de Partition de depart
const STARTER_PARTITION_DRAFT_SIZE: int = 3

# Vente de Partitions/Badges — pourcentage du prix d'achat rembourse
const SELL_REFUND_RATIO: float = 0.5

# Badges
const MAX_BADGE_SLOTS: int = 5

# Recompense par manche gagnee (fixe pour l'instant)
const FLIES_PER_ROUND_WON: int = 10

# Bonus de mouches en fin de manche selon les jetons restants dans le deck au
# moment de la victoire. Palier exclusif (pas cumulatif) : seul le palier le
# plus haut atteint s'applique.
const FLIES_BONUS_HIGH_REMAINING: int = 20
const FLIES_BONUS_HIGH: int = 5
const FLIES_BONUS_LOW_REMAINING: int = 10
const FLIES_BONUS_LOW: int = 2

# Delai avant transition en fin de manche (shop / victoire / defaite) pour
# laisser le temps d'integrer le dernier coup.
const ROUND_END_DELAY: float = 2.0


static func get_round_end_flies_bonus(remaining: int) -> int:
	if remaining >= FLIES_BONUS_HIGH_REMAINING:
		return FLIES_BONUS_HIGH
	if remaining >= FLIES_BONUS_LOW_REMAINING:
		return FLIES_BONUS_LOW
	return 0

# Modificateurs de cellules
# Cle stockee dans le dict grid_modifiers : Vector2i -> Array[StringName]
# (plusieurs types peuvent s'empiler sur une meme case, voir RunManager.add_grid_modifier)
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
const FAMILY_COUNT: int = 4

## Sequence Fibonacci fixe retenue pour la Partition "Fibonacci" (session 14) —
## pas de fenetre generique, cette cible exacte, dans un sens ou dans l'autre
## le long de la ligne (voir PatternMatcher.find_fibonacci).
const FIBONACCI_SEQUENCE: Array[int] = [1, 1, 2, 3]

## Roll casino ajoute a la valeur du centre d'un Diamond Rock (session 15) —
## avec seulement DECK_ROCK_COUNT rocks dans tout le deck, ce pattern ne se
## declenche quasiment qu'une fois par run : le roll garantit un plancher
## correct independamment de la valeur (chanceuse ou non) du jeton central,
## et ajoute un moment casino avant que le multiplicateur du tag s'applique.
const DIAMOND_ROCK_ROLL_MIN: int = 1
const DIAMOND_ROCK_ROLL_MAX: int = 5

## Poids de tirage par rarete au shop (unitaires + packs, Tags et Badges
## uniquement — Speciaux et boutons n'ont pas de champ rarity). Index = valeur
## de l'enum Rarity. PatternData.Rarity s'arrete a EPIC (0-3) ; BadgeData.Rarity
## ajoute LEGENDARY (4, session 17) pour une poignee de Badges tres puissants
## debloques au Shore — poids volontairement infime, un Partition n'atteint
## jamais cet index. Voir ShopManager._weighted_pick.
const RARITY_WEIGHTS: Array[float] = [10.0, 5.0, 2.0, 1.0, 0.1]

## Couleurs et noms par rarete, pour le badge colore affiche dans les tooltips
## (voir RarityTooltip). Meme indexation que RARITY_WEIGHTS.
const RARITY_COLORS: Array[Color] = [
	Color("9a9a9a"), # COMMON
	Color("4caf7d"), # UNCOMMON
	Color("4a90d9"), # RARE
	Color("b06fd9"), # EPIC
	Color("e8b923"), # LEGENDARY
]
const RARITY_NAMES: Array[String] = ["COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY"]

# Deck de depart structure : x copies de chaque (famille, valeur) possible,
# plutot qu'un tirage purement aleatoire — garantit une repartition egale
# entre les 4 familles a chaque run (voir RunManager._generate_starter_buttons).
const STARTER_COPIES_PER_VALUE: int = 2
const DECK_BASE_COUNT: int = FAMILY_COUNT * (TOKEN_MAX_VALUE - TOKEN_MIN_VALUE + 1) * STARTER_COPIES_PER_VALUE

## Plafond de valeur apres fusion (voir RunManager.fuse_buttons) — la valeur
## ne sert plus a resoudre des patterns (seule la famille compte pour ca),
## juste a amplifier le score une fois un match resolu. Sans plafond elle
## scale sans limite au fil des fusions.
const MAX_BUTTON_VALUE: int = 10

## Valeur affichee sur les jetons (grille + stream) — redevient pertinente
## maintenant qu'elle sert de levier de score, pas juste de bruit visuel.
const DEBUG_SHOW_TOKEN_VALUE: bool = true

# Shop — offre curatee par visite (v2). Deux rangees separees, a la Balatro :
# - Packs : nombre fixe, categorie aleatoire, JAMAIS regeneres par le reroll
#   (fixes pour toute la visite).
# - Unitaires : nombre fixe, categorie aleatoire (incluant Des a coudre),
#   regeneres a chaque reroll.
const SHOP_PACK_SLOT_COUNT: int = 2
const SHOP_UNITAIRE_SLOT_COUNT: int = 2

# Taille des packs a l'ouverture (candidats reveles, le joueur en garde 1).
# Exception boutons (5) deja actee dans le GDD : plus nombreux, individuellement
# moins determinants qu'une Partition ou un Badge.
const PACK_SIZE_DEFAULT: int = 3
const PACK_SIZE_BUTTON: int = 5

# Prix des packs par categorie — plus cher qu'un unitaire equivalent mais
# meilleur ratio par item (voir docs/gdd/shop/economie.md). Premiers jets.
const PACK_PRICE_TAG: int = 8
const PACK_PRICE_BADGE: int = 6
const PACK_PRICE_SPECIAL: int = 4
const PACK_PRICE_BUTTON: int = 4

# Shop — boutons a l'unite
const BUTTON_UNIT_PRICE: int = 3

# Outils de deck ("Des a coudre") — generalise l'ancienne Fusion seule
# (session 16, voir docs/brainstorms/brainstorm-outils-deck.md). Gate derriere
# l'achat d'un "Des a coudre" (slot au meme titre que les autres categories) :
# un achat = tirage de DECK_TOOL_ACTION_DRAW_SIZE actions distinctes ponderees
# par rarete (GameRules.RARITY_WEIGHTS), le joueur en choisit 1, puis cible
# DECK_TOOL_TARGET_DRAW_SIZE boutons tires du pool (meme principe RNG-forward
# que l'ancienne selection de fusion). Remplace l'ancien FUSION_PRICE (bouton
# permanent, spammable).
const DES_A_COUDRE_PRICE: int = 6
const DECK_TOOL_ACTION_DRAW_SIZE: int = 3
const DECK_TOOL_TARGET_DRAW_SIZE: int = 8

# Shop — reroll (prix croissant, reset a chaque nouvelle visite)
const REROLL_BASE_PRICE: int = 2
const REROLL_INCREMENT: int = 1

# Level up des Partitions — regles generiques, identiques pour toutes.
# Seuils de score cumule pour passer au niveau suivant (1->2, 2->3, 3->4, 4->5).
const PATTERN_LEVEL_THRESHOLDS: Array[int] = [150, 500, 1100, 2200]
# Multiplicateur applique au score selon le niveau (index 0 = niveau 1).
const PATTERN_LEVEL_MULTIPLIERS: Array[float] = [1.0, 1.25, 1.5, 1.75, 2.0]
const PATTERN_LEVEL_NAMES: Array[String] = ["Pianissimo", "Piano", "Forte", "Fortissimo", "Maestro"]


## Calcule le niveau (1 a 5) a partir du score cumule sur une Partition.
static func compute_pattern_level(cumulative_score: int) -> int:
	var level: int = 1
	for threshold in PATTERN_LEVEL_THRESHOLDS:
		if cumulative_score >= threshold:
			level += 1
	return level


static func get_pattern_level_multiplier(level: int) -> float:
	var idx: int = clampi(level - 1, 0, PATTERN_LEVEL_MULTIPLIERS.size() - 1)
	return PATTERN_LEVEL_MULTIPLIERS[idx]


static func get_pattern_level_name(level: int) -> String:
	var idx: int = clampi(level - 1, 0, PATTERN_LEVEL_NAMES.size() - 1)
	return PATTERN_LEVEL_NAMES[idx]


## Score cumule requis pour atteindre le PROCHAIN niveau. -1 si deja au max.
static func get_next_pattern_threshold(level: int) -> int:
	if level - 1 >= PATTERN_LEVEL_THRESHOLDS.size():
		return -1
	return PATTERN_LEVEL_THRESHOLDS[level - 1]


## Score cumule qui a fait passer au niveau ACTUEL (0 pour le niveau 1).
static func get_previous_pattern_threshold(level: int) -> int:
	if level <= 1:
		return 0
	return PATTERN_LEVEL_THRESHOLDS[level - 2]


static func get_modifier_multiplier(type: StringName) -> float:
	match type:
		MODIFIER_HALF:   return MODIFIER_HALF_MULT
		MODIFIER_BOOST:  return MODIFIER_BOOST_MULT
		MODIFIER_DOUBLE: return MODIFIER_DOUBLE_MULT
		MODIFIER_TRIPLE: return MODIFIER_TRIPLE_MULT
		_:               return 1.0
