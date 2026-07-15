## Snapshot des donnees du run passe aux systemes (resolver, matcher...).
## Lu, jamais mute par les systemes. Construit par le RunManager a chaque resolution.
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

# Valeurs de jeton qui recomptent leur propre valeur une deuxieme fois dans le
# value_sum du groupe qui score ("retrigger") : int (value) -> true. Alimente
# par les badges au round_start (ex: {2: true, 3: true} pour "Vingt-trois").
@export var retrigger_values: Dictionary = {}

# Quel badge a pose chaque retrigger_value : int (value) -> StringName.
@export var retrigger_value_sources: Dictionary = {}

# Bonus flat ajoute au value_sum quand un pattern de rule "family" de cette
# famille score : TokenData.Family (int) -> int. Cumulatif si plusieurs badges
# ciblent la meme famille (contrairement a rule_multipliers/value_bonus_multipliers,
# voir questions-ouvertes.md — pas de collision possible aujourd'hui, une seule
# famille par badge dans le catalogue actuel, mais on ne repete pas l'ecrasement).
@export var family_score_bonus: Dictionary = {}
@export var family_score_bonus_sources: Dictionary = {}  # Family -> StringName

# Bonus flat ajoute au value_sum quand le groupe qui score contient au moins
# deux jetons de meme valeur ("paire"). Cumulatif entre badges.
@export var pair_score_bonus: int = 0
@export var pair_score_bonus_source: StringName = &""

# Bonus flat ajoute au value_sum de CHAQUE pattern qui score tant qu'au moins
# une cellule de la rangee du haut (ROWS - 1) est occupee, verifie sur la
# grille entiere au moment du score (pas seulement les cellules du groupe).
# Cumulatif entre badges.
@export var top_row_score_bonus: int = 0
@export var top_row_score_bonus_source: StringName = &""

# Bonus multiplicatif additif "scaling permanent" (session 17) : float, somme
# des contributions actuelles de chaque badge scaling (ex: Jetons sacrés,
# +0.1 par spécial joué, cumulé sur toute la run). Pose un facteur
# (1.0 + scaling_mult_bonus) dans la formule de score. Distinct de
# global_multiplier pour ne pas entrer en collision avec les badges qui s'en
# servent deja (Dernier Carré, Régularité — voir questions-ouvertes.md, bug
# d'ecrasement connu sur ce champ-la).
@export var scaling_mult_bonus: float = 0.0

# Meme donnee que scaling_mult_bonus, mais par badge (StringName id -> float)
# plutot que pre-sommee — necessaire a la banniere de resolution pour
# afficher la contribution individuelle de chaque badge (session 17).
@export var scaling_mult_bonuses: Dictionary = {}

# Bonus flat inconditionnel ajoute au value_sum de CHAQUE pattern qui score
# (session 17) — contrairement a pair/family/top_row_score_bonus qui ont une
# condition, celui-ci s'applique toujours. Somme des contributions actuelles
# de chaque badge scaling (ex: Quatre quart, +5 par pattern de 4 jetons
# scoré, cumulé sur toute la run).
@export var flat_score_bonus: int = 0

# Meme donnee que flat_score_bonus, mais par badge (StringName id -> int),
# meme raison que scaling_mult_bonuses.
@export var flat_score_bonuses: Dictionary = {}

# Chance (0.0-1.0) qu'un jeton scorable gagne +1 de valeur dans le deck au
# moment ou il score (session 17, ex: "Poker Face"). Lu par
# CascadeResolver._roll_upgrades PENDANT le scoring — le tirage doit avoir
# lieu avant que le jeton disparaisse de la grille pour que le visuel puisse
# l'animer (voir GridVisual._animate_upgrade). Somme des contributions de
# chaque badge equipe, comme scaling_mult_bonus/flat_score_bonus.
@export var token_upgrade_chance: float = 0.0

# Bonus de slots de hold pour la manche (session 17, ex: "Bénédiction", +1),
# ajoute a GameRules.BASE_HOLD_SLOTS par TurnController.start_round avant
# DeckManager.build_deck. Cumulatif entre badges.
@export var hold_slot_bonus: int = 0

# Bonus de taille de preview du stream pour la manche (session 17, ex:
# "Visionnaire", +1), ajoute a GameRules.PREVIEW_SIZE. Cumulatif entre badges.
@export var preview_size_bonus: int = 0

# Badges qui font qu'un jeton aleatoire parmi ceux d'une Partition scoree
# laisse place a un rock au lieu de disparaitre (session 17, ex: "Récif
# vivant") : StringName (id du badge) -> true. Lu par CascadeResolver.resolve
# au moment de collecter les cellules a supprimer — non-vide suffit a activer
# l'effet, peu importe combien de badges le partagent.
@export var rock_leaving_sources: Dictionary = {}

# Extension future (ne pas implementer avant d'en avoir besoin) :
# @export var button_states: Dictionary = {}     # Vector2i -> Array[StateData]
