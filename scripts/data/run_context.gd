## Snapshot des donnees du run passe aux systemes (resolver, matcher...).
## Lu, jamais mute par les systemes (sauf global_multiplier_contributions, voir
## plus bas). Construit par le RunManager a chaque resolution.
##
## Convention unique (session 18, remplace 3 patterns incoherents qui avaient
## cohabite au fil des sessions — un seul provoquait un vrai bug de score,
## deux autres limitaient juste l'attribution affichee) : CHAQUE canal
## alimentable par un Sortilège est un dictionnaire garde par source (id du sortilège),
## jamais un scalaire ecrase. Deux formes seulement :
##   - "flat"  : Dictionary[StringName spell_id] -> valeur
##   - "keyed" : Dictionary[cle] -> Dictionary[StringName spell_id] -> valeur
##     (cle = rule, valeur de jeton, ou famille selon le canal)
## Combiner plusieurs sortilèges sur le meme canal ne perd donc plus jamais une
## contribution — les methodes get_* ci-dessous font la somme ou le produit
## selon la semantique du canal (documente sur chaque champ), et servent aussi
## de attribution complete pour la banniere de resolution (CascadeResolver).
class_name RunContext
extends Resource

@export var equipped_sheets: Array[SheetData] = []

# Sortilèges equipes, DANS L'ORDRE DES SLOTS (session 17) — permet a la banniere
# de resolution de faire resoudre les Sortilèges "de gauche a droite" plutot que
# dans un ordre arbitraire de dictionnaire. Snapshot au round_start comme
# equipped_sheets.
@export var equipped_spells: Array[SpellData] = []

# Cellules modifiees pour la manche en cours : Vector2i -> Array[StringName]
# (types de modifiers empiles sur cette case, cumulatifs).
# Types supportes : MODIFIER_HALF, MODIFIER_BOOST, MODIFIER_DOUBLE, MODIFIER_TRIPLE.
@export var grid_modifiers: Dictionary = {}

# Multiplicateurs de score par rule de pattern (ex: "family" -> Famille unie
# -> 2.0), keyed. Combine par PRODUIT : deux sortilèges sur la meme rule
# multiplient leurs facteurs entre eux plutot que le dernier ecraser l'autre.
@export var rule_multiplier_contributions: Dictionary = {} # rule -> {spell_id -> float}

# Multiplicateur global (Dernier Carre, Regularite), flat. Contrairement aux
# autres champs, celui-ci peut etre mute EN COURS de manche (RunManager garde
# une reference vivante vers le RunContext actif, voir
# RunManager.set_global_multiplier) car ces sortilèges reagissent a chaque tour.
# Combine par PRODUIT.
@export var global_multiplier_contributions: Dictionary = {} # spell_id -> float

# Multiplicateur de score par Partition (sheet_name -> float), selon son niveau
# (score cumule sur le run). Pas Sortilège-driven, pas de collision possible —
# une seule source (le niveau du Sheet lui-meme), reste un simple dictionnaire.
@export var sheet_level_multipliers: Dictionary = {}

# Bonus additif au multiplicateur d'une figure par valeur de jeton presente
# (ex: 1 -> Petites Mains -> 0.25), keyed. Combine par SOMME : chaque jeton
# scorable de cette valeur ajoute la somme des contributions au multi.
@export var value_bonus_multiplier_contributions: Dictionary = {} # value -> {spell_id -> float}

# Bonus additif au multiplicateur d'une Partition PRECISE, par sheet_name
# (ex: "Refrain", +0.1 cumule a chaque fois que CETTE Partition score,
# independant des autres Partitions equipees), keyed. Combine par SOMME,
# comme value_bonus_multiplier_contributions. Contrairement a
# scaling_mult_bonus (global, toutes Partitions confondues), ne s'applique
# qu'a la Partition dont le sheet_name correspond a la cle.
@export var sheet_multiplier_bonus_contributions: Dictionary = {} # sheet_name -> {spell_id -> float}

# Valeurs de jeton qui recomptent leur propre valeur une deuxieme fois dans le
# value_sum du groupe qui score ("retrigger"), keyed. Existence pure (pas de
# magnitude a combiner) — deux sortilèges sur la meme valeur ne la font pas
# compter trois fois, voir is_retrigger_value.
@export var retrigger_value_contributions: Dictionary = {} # value -> {spell_id -> true}

# Bonus flat ajoute au value_sum par jeton scorable de cette famille present
# dans un groupe qui score, peu importe la rule du pattern (ex: DENIERS ->
# Tickets Hivernal -> 2 par jeton DENIERS), keyed. Combine par SOMME.
@export var family_score_bonus_contributions: Dictionary = {} # family -> {spell_id -> int}

# Bonus flat ajoute au value_sum quand le groupe qui score contient au moins
# deux jetons de meme valeur ("paire", ex: "Y'en a pas deux"), flat. Combine
# par SOMME, applique une seule fois par groupe peu importe le nombre de
# paires trouvees (verifie par CascadeResolver, pas ici).
@export var pair_score_bonus_contributions: Dictionary = {} # spell_id -> int

# Bonus flat ajoute au value_sum de chaque pattern qui score tant qu'un jeton
# occupe la rangee du haut de la grille (ex: "Sommet"), flat. Combine par SOMME.
@export var top_row_score_bonus_contributions: Dictionary = {} # spell_id -> int

# Contribution actuelle de chaque sortilège "scaling permanent" au facteur
# scaling_mult (ex: Jetons sacres, +0.1 par special joue, cumule sur toute la
# run) : spell_id -> float. Combine par SOMME (voir scaling_mult_bonus, cache
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
# sortilège equipe (deja pre-somme par RunManager.build_context).
@export var token_upgrade_chance: float = 0.0

# Bonus de slots de hold / taille de preview / nombre de rocks pour la manche
# (deja pre-sommes par RunManager.build_context, voir
# GameRules.BASE_HOLD_SLOTS/PREVIEW_SIZE/DECK_ROCK_COUNT).
@export var hold_slot_bonus: int = 0
@export var preview_size_bonus: int = 0
@export var rock_count_bonus: int = 0

# Sortilèges qui font qu'un jeton aleatoire parmi ceux d'une Partition scoree
# laisse place a un rock au lieu de disparaitre (ex: "Recif vivant") :
# StringName (id du sortilège) -> true. Non-vide suffit a activer l'effet, peu
# importe combien de sortilèges le partagent.
@export var rock_leaving_sources: Dictionary = {}

# Verrous poses par le malus de boss actif de la manche (voir
# BossMalusManager) : MAIN LIÉE et COUR ENDORMIE. Pas de dictionnaire par
# source, contrairement aux canaux Sortilège ci-dessus — un seul emetteur possible.
@export var hold_locked: bool = false
@export var figure_promotion_locked: bool = false

# Legendaire "Dresseur Fou" (session 23) : vrai si equipe — les speciaux
# mobiles (Cavalier/Frog/Liane/Underground) ne disparaissent plus jamais.
# Simple flag reflete depuis RunManager.has_spell, pas un canal par source
# (un seul sortilège peut porter cet effet). Lu par GridManager.tick_mobile_
# specials, pas par le pipeline de scoring (CascadeResolver).
@export var mobiles_never_expire: bool = false

# Sortilège "Pierre de Famille" (session "Vague 2") : vrai si equipe — un
# Rock peut se convertir en jeton de base (mutation reelle sur la grille,
# voir CascadeResolver._apply_rock_wildcard) pour completer un groupe rule
# "family" qui matcherait sinon a l'identique. Simple flag, meme convention
# que mobiles_never_expire ci-dessus.
@export var rock_wildcard_family: bool = false

# Malus de boss FAMILLE TERNIE / PARTITION TERNIE (voir BossMalusManager),
# deux axes symetriques de la meme formule value_sum * multi :
# - score_capped_family (TokenData.Family, -1 = aucune) : chaque jeton de
#   cette famille scort comme s'il valait 1 (voir CascadeResolver.
#   _effective_token_value) — les multi (sheet + Sortilèges) s'appliquent ensuite
#   normalement sur ce total reduit.
# - score_capped_sheet_name (sheet_name, "" = aucune) : le multiplicateur
#   PROPRE a cette Partition (base + niveau, y compris legendaire dynamique)
#   est neutralise a 1.0 — les tickets des jetons et les multi de Sortilèges
#   restent normaux (voir CascadeResolver._score_group).
@export var score_capped_family: int = -1
@export var score_capped_sheet_name: StringName = &""

# Sortilège "Echo" (Sheet, session 27) : vrai si equipe — chaque groupe qui
# score a GameRules.ECHO_RETRIGGER_CHANCE de se retrigger (score double).
# Simple flag, meme convention que mobiles_never_expire/rock_wildcard_family
# ci-dessus. Lu par CascadeResolver._apply_score_gambles.
@export var has_echo: bool = false

# Sortilège "Quitte ou Double" (session 27) : vrai si equipe — chaque groupe
# qui score joue GameRules.QUITTE_OU_DOUBLE_CHANCE a pile ou face : double ou
# remis a zero. Simple flag, meme convention. Lu par CascadeResolver.
# _apply_score_gambles, applique AVANT Echo (voir ce fichier pour l'ordre).
@export var has_quitte_ou_double: bool = false

# Sortilège "Adjacence Sombre" (session 28) : vrai si equipe -- chaque
# Partition qui score gagne un multiplicateur LOCAL (pas un global_
# multiplier) de GameRules.ADJACENCE_SOMBRE_PER_SKULL par entity-skull
# adjacent orthogonalement a une de ses cellules. Simple flag, meme
# convention que has_echo. Lu par CascadeResolver._score_group.
@export var has_adjacence_sombre: bool = false


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


func get_sheet_multiplier_bonus_sum(sheet_name: StringName) -> float:
	return _sum(sheet_multiplier_bonus_contributions.get(sheet_name, {}) as Dictionary)


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
