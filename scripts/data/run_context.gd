## Snapshot des donnees du run passe aux systemes (resolver, matcher...).
## Lu, jamais mute par les systemes (sauf global_multiplier_contributions, voir
## plus bas). Construit par le RunManager a chaque resolution.
##
## Convention unique (session 18, remplace 3 patterns incoherents qui avaient
## cohabite au fil des sessions — un seul provoquait un vrai bug de score,
## deux autres limitaient juste l'attribution affichee) : CHAQUE canal
## alimentable par un Badge est un dictionnaire garde par source (id du badge),
## jamais un scalaire ecrase. Deux formes seulement :
##   - "flat"  : Dictionary[StringName badge_id] -> valeur
##   - "keyed" : Dictionary[cle] -> Dictionary[StringName badge_id] -> valeur
##     (cle = rule, valeur de jeton, ou famille selon le canal)
## Combiner plusieurs badges sur le meme canal ne perd donc plus jamais une
## contribution — les methodes get_* ci-dessous font la somme ou le produit
## selon la semantique du canal (documente sur chaque champ), et servent aussi
## de attribution complete pour la banniere de resolution (CascadeResolver).
class_name RunContext
extends Resource

@export var equipped_tags: Array[PatternData] = []

# Badges equipes, DANS L'ORDRE DES SLOTS (session 17) — permet a la banniere
# de resolution de faire resoudre les Badges "de gauche a droite" plutot que
# dans un ordre arbitraire de dictionnaire. Snapshot au round_start comme
# equipped_tags.
@export var equipped_badges: Array[BadgeData] = []

# Cellules modifiees pour la manche en cours : Vector2i -> Array[StringName]
# (types de modifiers empiles sur cette case, cumulatifs).
# Types supportes : MODIFIER_HALF, MODIFIER_BOOST, MODIFIER_DOUBLE, MODIFIER_TRIPLE.
@export var grid_modifiers: Dictionary = {}

# Multiplicateurs de score par rule de pattern (ex: "family" -> Famille unie
# -> 2.0), keyed. Combine par PRODUIT : deux badges sur la meme rule
# multiplient leurs facteurs entre eux plutot que le dernier ecraser l'autre.
@export var rule_multiplier_contributions: Dictionary = {} # rule -> {badge_id -> float}

# Multiplicateur global (Dernier Carre, Regularite), flat. Contrairement aux
# autres champs, celui-ci peut etre mute EN COURS de manche (RunManager garde
# une reference vivante vers le RunContext actif, voir
# RunManager.set_global_multiplier) car ces badges reagissent a chaque tour.
# Combine par PRODUIT.
@export var global_multiplier_contributions: Dictionary = {} # badge_id -> float

# Multiplicateur de score par Partition (tag_name -> float), selon son niveau
# (score cumule sur le run). Pas Badge-driven, pas de collision possible —
# une seule source (le niveau du Tag lui-meme), reste un simple dictionnaire.
@export var tag_level_multipliers: Dictionary = {}

# Bonus additif au multiplicateur d'une figure par valeur de jeton presente
# (ex: 1 -> Petites Mains -> 0.25), keyed. Combine par SOMME : chaque jeton
# scorable de cette valeur ajoute la somme des contributions au multi.
@export var value_bonus_multiplier_contributions: Dictionary = {} # value -> {badge_id -> float}

# Valeurs de jeton qui recomptent leur propre valeur une deuxieme fois dans le
# value_sum du groupe qui score ("retrigger"), keyed. Existence pure (pas de
# magnitude a combiner) — deux badges sur la meme valeur ne la font pas
# compter trois fois, voir is_retrigger_value.
@export var retrigger_value_contributions: Dictionary = {} # value -> {badge_id -> true}

# Bonus flat ajoute au value_sum par jeton scorable de cette famille present
# dans un groupe qui score, peu importe la rule du pattern (ex: DENIERS ->
# Tickets Hivernal -> 2 par jeton DENIERS), keyed. Combine par SOMME.
@export var family_score_bonus_contributions: Dictionary = {} # family -> {badge_id -> int}

# Bonus flat ajoute au value_sum quand le groupe qui score contient au moins
# deux jetons de meme valeur ("paire", ex: "Y'en a pas deux"), flat. Combine
# par SOMME, applique une seule fois par groupe peu importe le nombre de
# paires trouvees (verifie par CascadeResolver, pas ici).
@export var pair_score_bonus_contributions: Dictionary = {} # badge_id -> int

# Bonus flat ajoute au value_sum de chaque pattern qui score tant qu'un jeton
# occupe la rangee du haut de la grille (ex: "Sommet"), flat. Combine par SOMME.
@export var top_row_score_bonus_contributions: Dictionary = {} # badge_id -> int

# Contribution actuelle de chaque badge "scaling permanent" au facteur
# scaling_mult (ex: Jetons sacres, +0.1 par special joue, cumule sur toute la
# run) : badge_id -> float. Combine par SOMME (voir scaling_mult_bonus, cache
# pre-somme pour eviter de resommer a chaque groupe score).
@export var scaling_mult_bonuses: Dictionary = {}
@export var scaling_mult_bonus: float = 0.0

# Meme principe que scaling_mult_bonus/bonuses, pour un bonus flat
# inconditionnel ajoute au value_sum de CHAQUE pattern qui score (ex: Quatre
# quart, +1 par pattern de 4 jetons scored, cumule sur toute la run).
@export var flat_score_bonuses: Dictionary = {}
@export var flat_score_bonus: int = 0

# Chance (0.0-1.0) qu'un jeton scorable gagne +1 de valeur dans le deck au
# moment ou il score (ex: "Poker Face"). Somme des contributions de chaque
# badge equipe (deja pre-somme par RunManager.build_context).
@export var token_upgrade_chance: float = 0.0

# Bonus de slots de hold / taille de preview / nombre de rocks pour la manche
# (deja pre-sommes par RunManager.build_context, voir
# GameRules.BASE_HOLD_SLOTS/PREVIEW_SIZE/DECK_ROCK_COUNT).
@export var hold_slot_bonus: int = 0
@export var preview_size_bonus: int = 0
@export var rock_count_bonus: int = 0

# Badges qui font qu'un jeton aleatoire parmi ceux d'une Partition scoree
# laisse place a un rock au lieu de disparaitre (ex: "Recif vivant") :
# StringName (id du badge) -> true. Non-vide suffit a activer l'effet, peu
# importe combien de badges le partagent.
@export var rock_leaving_sources: Dictionary = {}


## --- Combinaison des contributions --------------------------------------
## Chaque canal "keyed" ou "flat" a une seule methode qui sait le combiner —
## c'est la reponse au "brouillon" de session 18 : plus besoin de deviner
## comment un canal se combine en le lisant au point d'utilisation.

func get_rule_multiplier(rule: StringName) -> float:
	return _product(rule_multiplier_contributions.get(rule, {}) as Dictionary)


func get_global_multiplier() -> float:
	return _product(global_multiplier_contributions)


func get_value_bonus_multiplier_sum(value: int) -> float:
	return _sum(value_bonus_multiplier_contributions.get(value, {}) as Dictionary)


func is_retrigger_value(value: int) -> bool:
	return not (retrigger_value_contributions.get(value, {}) as Dictionary).is_empty()


func get_family_score_bonus(family: int) -> int:
	return int(_sum(family_score_bonus_contributions.get(family, {}) as Dictionary))


func get_pair_score_bonus() -> int:
	return int(_sum(pair_score_bonus_contributions))


func get_top_row_score_bonus() -> int:
	return int(_sum(top_row_score_bonus_contributions))


static func _product(d: Dictionary) -> float:
	var result: float = 1.0
	for v in d.values():
		result *= v as float
	return result


static func _sum(d: Dictionary) -> float:
	var result: float = 0.0
	for v in d.values():
		result += v as float
	return result

# Extension future (ne pas implementer avant d'en avoir besoin) :
# @export var button_states: Dictionary = {}     # Vector2i -> Array[StateData]
