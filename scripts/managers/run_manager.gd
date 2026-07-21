## Porte les donnees qui evoluent au cours d'un run (sheets equipes, deck,
## mouches, plus tard badges/states/niveaux). Mute uniquement par l'orchestration
## (TurnController, ShopManager a venir). Les autres lisent via build_context().
class_name RunManager
extends Node

signal flies_changed(amount: int)
signal shake_charges_changed(amount: int)
signal sheets_changed(equipped: Array[SheetData])
signal badges_changed(equipped: Array[BadgeData])
signal deck_composition_changed()
signal grid_modifiers_changed(modifiers: Dictionary)
signal button_pool_changed()
signal sheet_leveled_up(sheet_name: StringName, new_level: int)
signal sheet_progress_changed(sheet_name: StringName)
signal sheet_sold(sheet_name: StringName)
signal figure_promoted(new_value: int)

## Chemins des packs de demarrage day-one (session 19) — toujours debloques,
## une save neuve propose donc un vrai choix des la premiere run. Les 6 packs
## a debloquer au Shore (dont 4 servent de vecteur d'unlock pour les 5
## Partitions verrouillees) n'existent pas encore en donnees, voir
## docs/gdd/meta/questions-ouvertes.md.
const STARTER_PACK_PATHS: Array[String] = [
	"res://resources/starter_packs/le_simplet.tres",
	"res://resources/starter_packs/le_genereux.tres",
	"res://resources/starter_packs/le_prevoyant.tres",
	"res://resources/starter_packs/le_collectionneur.tres",
]

var _flies: int = 0
var _shake_charges: int = GameRules.SHAKE_CHARGES_DEFAULT
var _equipped_sheets: Array[SheetData] = []
var _equipped_badges: Array[BadgeData] = []
var _button_pool: Array[TokenData] = []
var _deck_composition: Dictionary = {
	"bombe_count": 0,
	"fantome_count": 0,
	"maree_count": 0,
	"enclume_count": 0,
	"petard_a_meche_count": 0,
	"cavalier_count": 0,
	"frog_count": 0,
	"liane_count": 0,
	"crow_count": 0,
	"underground_count": 0,
	"hypercube_count": 0,
}
var _grid_modifiers: Dictionary = {}    # Vector2i -> Array[StringName]

## Canaux alimentables par plusieurs Badges a la fois (session 18) : un seul
## pattern partout — Dictionary[badge_id] -> valeur pour les canaux "flat",
## Dictionary[cle] -> Dictionary[badge_id] -> valeur pour les canaux "keyed"
## (cle = rule/valeur/famille selon le canal). Remplace 3 patterns
## incoherents (ecrasement pur pour rule/global, source unique pour value_
## bonus/family/pair/top_row) — voir RunContext pour la combinaison (produit
## ou somme selon le canal) et l'attribution complete pour la banniere de
## resolution.
var _rule_multiplier_contributions: Dictionary = {}          # rule -> {badge_id -> float}
var _value_bonus_multiplier_contributions: Dictionary = {}   # value -> {badge_id -> float}
var _retrigger_value_contributions: Dictionary = {}          # value -> {badge_id -> true}
var _family_score_bonus_contributions: Dictionary = {}       # family -> {badge_id -> int}
var _global_multiplier_contributions: Dictionary = {}        # badge_id -> float
var _pair_score_bonus_contributions: Dictionary = {}         # badge_id -> int
var _top_row_score_bonus_contributions: Dictionary = {}      # badge_id -> int

## Bonus de slots de hold / taille de preview pour la manche (session 17) :
## StringName (id du badge) -> int. Remis a zero chaque manche comme les
## canaux ci-dessus — repeuples par les badges on_round_start.
var _hold_slot_bonuses: Dictionary = {}
var _preview_size_bonuses: Dictionary = {}
var _rock_count_bonuses: Dictionary = {}
var _rock_leaving_sources: Dictionary = {}  # StringName -> true

## Verrous poses par le malus de boss actif (voir BossMalusManager). Simples
## booleens, pas de dictionnaire par source : seul le malus de boss les pose
## aujourd'hui, contrairement aux canaux ci-dessus qui combinent plusieurs Badges.
var _hold_locked: bool = false
var _shake_locked: bool = false
var _figure_promotion_locked: bool = false
var _score_capped_family: int = -1
var _score_capped_sheet_name: StringName = &""

## Contribution actuelle de chaque badge "scaling permanent" au facteur
## scaling_mult / au flat_score_bonus : StringName (id du badge) -> float/int.
## Jamais remis a zero a chaque manche (contrairement aux dictionnaires
## ci-dessus) — seul le retrait d'un badge equipe (voir unequip_badge) efface
## son entree. Permet au bonus de rester actif d'une manche a l'autre sans
## attendre un nouveau round_start pour se re-populer.
var _scaling_mult_bonuses: Dictionary = {}  # StringName -> float
var _flat_score_bonuses: Dictionary = {}  # StringName -> int
var _token_upgrade_chances: Dictionary = {}  # StringName -> float

## Meme duree de vie que _scaling_mult_bonuses (jamais remis a zero a chaque
## manche, seul unequip_badge nettoie), mais garde EN PLUS par Partition
## ciblee (ex: "Refrain") — voir add_sheet_multiplier_bonus.
var _sheet_multiplier_bonus_contributions: Dictionary = {}  # sheet_name -> {badge_id -> float}

## Etat persistant par badge, JAMAIS remis a zero en cours de run (contrairement
## a _badge_state, reset chaque manche) — sert aux badges "scaling permanent"
## qui grossissent sur toute la run (ex: nombre de speciaux joues, cumulatif
## pour Jetons sacres). Cle = StringName propre a chaque badge. Reset
## uniquement par init_run (nouvelle run).
var _run_badge_state: Dictionary = {}
var _sheet_progress: Dictionary = {}      # StringName (sheet_name) -> {"cumulative": int, "level": int}

## Pack de demarrage choisi pour cette run (voir apply_starter_pack). Ses
## bonus de slots/mouches sont permanents pour toute la run, contrairement
## aux memes canaux alimentes par les Badges (remis a zero chaque manche) —
## voir get_badge_slot_count/get_flies_per_round_bonus et reset_round_modifiers.
var _starter_pack: StarterPackData = null

## Etat libre pour badges a compteur (ex: streak de Regularite, familles deja
## vues de Un Pour Tous). Cle = StringName propre a chaque badge, remis a zero
## a chaque manche. Voir get_badge_state/set_badge_state.
var _badge_state: Dictionary = {}

## Reference vivante vers le RunContext de la manche en cours, pour permettre
## aux badges de muter le multiplicateur global en cours de manche (voir
## set_global_multiplier). Tous les autres champs du contexte restent des
## snapshots figes au round_start.
var _active_context: RunContext = null


## Initialise un nouveau run. Les Partitions de depart ne sont plus auto-equipees
## ici : c'est l'ecran de selection du pack de demarrage (get_available_starter_packs)
## qui appelle apply_starter_pack() avec le choix du joueur avant le debut de la manche 1.
func init_run() -> void:
	_flies = 0
	_shake_charges = GameRules.SHAKE_CHARGES_DEFAULT

	_equipped_sheets.clear()
	_starter_pack = null
	# DEBUG : equipe au demarrage les sheets (dont legendaires) dont
	# debug_start_equipped == true. Flag a activer dans chaque .tres via
	# l'editeur Godot. Avant apply_starter_pack (appele juste apres par
	# StarterPackSelectUI), qui ajoute par-dessus les Partitions fixes du pack
	# choisi — respecte donc MAX_SHEET_SLOTS comme un equipement normal.
	for path in ShopManager.SHEET_PATHS + ShopManager.LEGENDARY_SHEET_PATHS:
		var sheet: SheetData = load(path) as SheetData
		if sheet != null and sheet.debug_start_equipped:
			equip_sheet(sheet)

	_equipped_badges.clear()
	# DEBUG : equipe au demarrage les badges dont debug_start_equipped == true.
	# Flag a activer dans chaque .tres via l'editeur Godot.
	for path in ShopManager.BADGE_PATHS:
		var badge: BadgeData = load(path) as BadgeData
		if badge != null and badge.debug_start_equipped:
			_equipped_badges.append(badge)

	_button_pool = _generate_starter_buttons()
	_sheet_progress.clear()

	_deck_composition = {
		"bombe_count": 0,
		"fantome_count": 0,
		"maree_count": 0,
		"enclume_count": 0,
		"petard_a_meche_count": 0,
		"cavalier_count": 0,
		"frog_count": 0,
		"liane_count": 0,
		"crow_count": 0,
		"underground_count": 0,
		"hypercube_count": 0,
	}
	_scaling_mult_bonuses.clear()
	_flat_score_bonuses.clear()
	_token_upgrade_chances.clear()
	_sheet_multiplier_bonus_contributions.clear()
	_run_badge_state.clear()
	_apply_debug_specials_to_deck()

	flies_changed.emit(_flies)
	shake_charges_changed.emit(_shake_charges)
	sheets_changed.emit(_equipped_sheets)
	badges_changed.emit(_equipped_badges)
	deck_composition_changed.emit()


## Genere le pool de boutons de depart : x copies de chaque (famille, valeur)
## possible (STARTER_COPIES_PER_VALUE), plus une copie additionnelle pour les
## valeurs basses (<= STARTER_LOW_VALUE_EXTRA_COPY_MAX) — pas un tirage
## purement aleatoire — garantit une repartition egale entre les 4 familles,
## pour ne pas saboter un demarrage jouable par un mauvais tirage independant
## du choix de Partition. Ce pool persiste ensuite pour toute la run, seul le
## shop pourra le muter (achat, fusion).
func _generate_starter_buttons() -> Array[TokenData]:
	var buttons: Array[TokenData] = []
	for family in range(GameRules.FAMILY_COUNT):
		for value in range(GameRules.TOKEN_MIN_VALUE, GameRules.TOKEN_MAX_VALUE + 1):
			var copies: int = GameRules.STARTER_COPIES_PER_VALUE
			if value <= GameRules.STARTER_LOW_VALUE_EXTRA_COPY_MAX:
				copies += 1
			for i in range(copies):
				buttons.append(TokenData.make_base(family as TokenData.Family, value))
	return buttons


## Charge le roster des packs de demarrage day-one (STARTER_PACK_PATHS). Ne
## mute rien — pour l'ecran de selection de pack.
func get_available_starter_packs() -> Array[StarterPackData]:
	var packs: Array[StarterPackData] = []
	for path in STARTER_PACK_PATHS:
		var pack: StarterPackData = load(path) as StarterPackData
		if pack != null:
			packs.append(pack)
	return packs


## Applique le pack de demarrage choisi par le joueur : equipe ses Partitions
## fixes et memorise le pack pour ses bonus permanents (hold/badge/preview/
## mouches, voir get_badge_slot_count/get_flies_per_round_bonus et
## reset_round_modifiers, qui repeuple hold/preview a chaque manche).
func apply_starter_pack(pack: StarterPackData) -> void:
	_starter_pack = pack
	for sheet in pack.get_fixed_sheets():
		equip_sheet(sheet)


func get_starter_pack() -> StarterPackData:
	return _starter_pack


## Slots de Badge disponibles pour cette run (base + bonus permanent du pack
## de demarrage, ex: Le Collectionneur +1). Remplace les usages directs de
## GameRules.MAX_BADGE_SLOTS partout ou le choix de pack doit compter.
func get_badge_slot_count() -> int:
	var bonus: int = _starter_pack.badge_slot_bonus if _starter_pack != null else 0
	return GameRules.MAX_BADGE_SLOTS + bonus


## Bonus de mouches par manche gagnee accorde par le pack de demarrage (ex:
## Le Genereux, +2) — ajoute a GameRules.FLIES_PER_ROUND_WON par l'appelant.
func get_flies_per_round_bonus() -> int:
	return _starter_pack.flies_per_round_bonus if _starter_pack != null else 0


## Construit un snapshot lu par les systemes.
func build_context() -> RunContext:
	var ctx: RunContext = RunContext.new()
	ctx.equipped_sheets = _equipped_sheets.duplicate()
	ctx.equipped_badges = _equipped_badges.duplicate()
	ctx.grid_modifiers = _grid_modifiers.duplicate()
	ctx.rule_multiplier_contributions = _rule_multiplier_contributions.duplicate(true)
	ctx.sheet_level_multipliers = _build_sheet_level_multipliers()
	ctx.value_bonus_multiplier_contributions = _value_bonus_multiplier_contributions.duplicate(true)
	ctx.global_multiplier_contributions = _global_multiplier_contributions.duplicate()
	ctx.retrigger_value_contributions = _retrigger_value_contributions.duplicate(true)
	ctx.family_score_bonus_contributions = _family_score_bonus_contributions.duplicate(true)
	ctx.pair_score_bonus_contributions = _pair_score_bonus_contributions.duplicate()
	ctx.top_row_score_bonus_contributions = _top_row_score_bonus_contributions.duplicate()
	ctx.scaling_mult_bonus = _sum_dict_values(_scaling_mult_bonuses)
	ctx.scaling_mult_bonuses = _scaling_mult_bonuses.duplicate()
	ctx.flat_score_bonus = int(_sum_dict_values(_flat_score_bonuses))
	ctx.flat_score_bonuses = _flat_score_bonuses.duplicate()
	ctx.token_upgrade_chance = _sum_dict_values(_token_upgrade_chances)
	ctx.sheet_multiplier_bonus_contributions = _sheet_multiplier_bonus_contributions.duplicate(true)
	ctx.hold_slot_bonus = int(_sum_dict_values(_hold_slot_bonuses))
	ctx.preview_size_bonus = int(_sum_dict_values(_preview_size_bonuses))
	ctx.rock_count_bonus = int(_sum_dict_values(_rock_count_bonuses))
	ctx.rock_leaving_sources = _rock_leaving_sources.duplicate()
	ctx.hold_locked = _hold_locked
	ctx.figure_promotion_locked = _figure_promotion_locked
	ctx.score_capped_family = _score_capped_family
	ctx.score_capped_sheet_name = _score_capped_sheet_name
	_active_context = ctx
	return ctx


func _sum_dict_values(d: Dictionary) -> float:
	var total: float = 0.0
	for v in d.values():
		total += v as float
	return total


func _build_sheet_level_multipliers() -> Dictionary:
	var result: Dictionary = {}
	for sheet in _equipped_sheets:
		result[sheet.sheet_name] = GameRules.get_sheet_level_multiplier(get_sheet_level(sheet.sheet_name))
	return result


# --- Level up des Partitions ---

## Ajoute du score cumule a une Partition (par sheet_name) et met a jour son
## niveau. Appele par TurnController a chaque groupe resolu. Le multiplicateur
## resultant n'est lu par le scoring qu'a la prochaine manche (snapshot dans
## build_context, comme rule_multipliers). Les legendaires (session 20) ne
## level up jamais — voir SheetData.is_legendary, leur puissance vient de la
## rarete/d'un effet code en dur, pas d'un investissement en plus.
func add_sheet_score(sheet_name: StringName, amount: int) -> void:
	if amount <= 0 or sheet_name == &"":
		return
	if _is_legendary_sheet(sheet_name):
		return
	if not _sheet_progress.has(sheet_name):
		_sheet_progress[sheet_name] = {"cumulative": 0, "level": 1}

	var progress: Dictionary = _sheet_progress[sheet_name]
	var cumulative: int = (progress["cumulative"] as int) + amount
	var old_level: int = progress["level"] as int
	var new_level: int = GameRules.compute_sheet_level(cumulative)

	progress["cumulative"] = cumulative
	progress["level"] = new_level
	_sheet_progress[sheet_name] = progress

	sheet_progress_changed.emit(sheet_name)
	if new_level != old_level:
		sheet_leveled_up.emit(sheet_name, new_level)


func get_sheet_level(sheet_name: StringName) -> int:
	if not _sheet_progress.has(sheet_name):
		return 1
	return (_sheet_progress[sheet_name] as Dictionary)["level"] as int


func _is_legendary_sheet(sheet_name: StringName) -> bool:
	for sheet in _equipped_sheets:
		if sheet.sheet_name == sheet_name:
			return sheet.is_legendary
	return false


func get_sheet_cumulative_score(sheet_name: StringName) -> int:
	if not _sheet_progress.has(sheet_name):
		return 0
	return (_sheet_progress[sheet_name] as Dictionary)["cumulative"] as int


## Reset la couche "modifiers de manche" : grid modifiers + rule multipliers.
## Appele au start_round avant que les badges on_round_start ne peuplent.
func reset_round_modifiers() -> void:
	_grid_modifiers.clear()
	_rule_multiplier_contributions.clear()
	_value_bonus_multiplier_contributions.clear()
	_global_multiplier_contributions.clear()
	_retrigger_value_contributions.clear()
	_family_score_bonus_contributions.clear()
	_pair_score_bonus_contributions.clear()
	_top_row_score_bonus_contributions.clear()
	_hold_slot_bonuses.clear()
	_preview_size_bonuses.clear()
	_rock_count_bonuses.clear()
	_rock_leaving_sources.clear()
	_hold_locked = false
	_shake_locked = false
	_figure_promotion_locked = false
	_score_capped_family = -1
	_score_capped_sheet_name = &""
	_badge_state.clear()
	_active_context = null

	# Bonus permanents du pack de demarrage (ex: Le Prevoyant +1 hold/-1 preview,
	# Le Collectionneur +1 badge/+2 rocks) — repeuples ici comme une "source" de
	# plus dans ces memes dictionnaires, au meme titre qu'un Badge on_round_start,
	# plutot que dans un canal a part.
	if _starter_pack != null:
		if _starter_pack.hold_slot_bonus != 0:
			_hold_slot_bonuses[&"starter_pack"] = _starter_pack.hold_slot_bonus
		if _starter_pack.preview_size_bonus != 0:
			_preview_size_bonuses[&"starter_pack"] = _starter_pack.preview_size_bonus
		if _starter_pack.rock_count_bonus != 0:
			_rock_count_bonuses[&"starter_pack"] = _starter_pack.rock_count_bonus


## Ajoute un modifier sur une cellule. Appele par les badges. Les modifiers
## s'empilent sur une meme case (ex: Tranchee + Bord a Bord, ou Cellule Triple
## par-dessus un badge colonne) : chaque type ajoute son propre multiplicateur
## au lieu d'ecraser les precedents, voir CascadeResolver._grid_modifier_multiplier.
func add_grid_modifier(cell: Vector2i, type: StringName) -> void:
	var types: Array = (_grid_modifiers.get(cell, []) as Array).duplicate()
	types.append(type)
	_grid_modifiers[cell] = types


## Emis une fois tous les modifiers de manche peuples (base + badges).
func notify_grid_modifiers_ready() -> void:
	grid_modifiers_changed.emit(_grid_modifiers.duplicate())


## Pose un multiplicateur de score par rule (ex: &"family" -> 2.0). Appele par
## les badges, qui passent leur propre id (ex: &"famille_unie") pour que la
## bannière de résolution puisse identifier — et faire tilter — le bon Badge.
## Deux badges sur la meme rule se multiplient entre eux (voir RunContext.
## get_rule_multiplier) au lieu que le dernier ecrase l'autre.
func set_rule_multiplier(rule: StringName, mult: float, source: StringName = &"") -> void:
	var contributions: Dictionary = (_rule_multiplier_contributions.get(rule, {}) as Dictionary).duplicate()
	contributions[source] = mult
	_rule_multiplier_contributions[rule] = contributions


func get_grid_modifiers() -> Dictionary:
	return _grid_modifiers.duplicate()


## Pose un bonus additif au multiplicateur d'une figure par occurrence d'une
## valeur de jeton donnee (ex: 1 -> 0.25 pour "Petites Mains"). Appele par les
## badges au round_start, qui passent leur propre id (attribution pour la
## bannière de résolution). Cumulatif entre badges ciblant la meme valeur.
func add_value_bonus_multiplier(value: int, bonus: float, source: StringName = &"") -> void:
	var contributions: Dictionary = (_value_bonus_multiplier_contributions.get(value, {}) as Dictionary).duplicate()
	contributions[source] = bonus
	_value_bonus_multiplier_contributions[value] = contributions


## Marque une valeur de jeton comme "retrigger" : un jeton scorable de cette
## valeur recompte sa propre valeur une deuxieme fois dans le value_sum du
## groupe qui score (ex: un 3 qui score vaut 6 points). Idempotent — deux
## badges qui ciblent la meme valeur ne la font pas compter trois fois.
func add_retrigger_value(value: int, source: StringName = &"") -> void:
	var contributions: Dictionary = (_retrigger_value_contributions.get(value, {}) as Dictionary).duplicate()
	contributions[source] = true
	_retrigger_value_contributions[value] = contributions


## Pose un bonus flat ajoute au value_sum par jeton scorable de cette famille
## present dans un groupe qui score (ex: "Tickets Hivernal" -> DENIERS).
## Cumulatif entre badges.
func add_family_score_bonus(family: TokenData.Family, bonus: int, source: StringName = &"") -> void:
	var contributions: Dictionary = (_family_score_bonus_contributions.get(family, {}) as Dictionary).duplicate()
	contributions[source] = bonus
	_family_score_bonus_contributions[family] = contributions


## Pose un bonus flat ajoute au value_sum quand le groupe qui score contient
## au moins deux jetons de meme valeur ("paire", ex: "Y'en a pas deux").
## Cumulatif entre badges.
func add_pair_score_bonus(bonus: int, source: StringName = &"") -> void:
	_pair_score_bonus_contributions[source] = bonus


## Pose un bonus flat ajoute au value_sum de chaque pattern qui score tant
## qu'un jeton occupe la rangee du haut de la grille (ex: "Sommet"). Cumulatif
## entre badges.
func add_top_row_score_bonus(bonus: int, source: StringName = &"") -> void:
	_top_row_score_bonus_contributions[source] = bonus


## Ajoute un bonus de slots de hold pour la manche (ex: "Bénédiction", +1).
## Cumulatif entre badges, remis a zero chaque manche (repeuple au round_start).
func add_hold_slot_bonus(bonus: int, source: StringName = &"") -> void:
	_hold_slot_bonuses[source] = bonus


## Meme principe qu'add_hold_slot_bonus, pour la taille de preview du stream
## (ex: "Visionnaire", +1).
func add_preview_size_bonus(bonus: int, source: StringName = &"") -> void:
	_preview_size_bonuses[source] = bonus


## Meme principe qu'add_hold_slot_bonus/add_preview_size_bonus, pour le nombre
## de rocks ajoutes au deck chaque manche (voir GameRules.DECK_ROCK_COUNT).
func add_rock_count_bonus(bonus: int, source: StringName = &"") -> void:
	_rock_count_bonuses[source] = bonus


## --- Verrous de malus de boss (voir BossMalusManager) ---------------------

func set_hold_locked(locked: bool) -> void:
	_hold_locked = locked


func set_shake_locked(locked: bool) -> void:
	_shake_locked = locked


func is_shake_locked() -> bool:
	return _shake_locked


func set_figure_promotion_locked(locked: bool) -> void:
	_figure_promotion_locked = locked


func set_score_capped_family(family: int) -> void:
	_score_capped_family = family


func set_score_capped_sheet(sheet_name: StringName) -> void:
	_score_capped_sheet_name = sheet_name


## Active, pour cette manche, l'effet "un jeton aleatoire d'une Partition
## scoree laisse place a un rock" (ex: "Récif vivant"). Remis a zero chaque
## manche, repeuple au round_start.
func add_rock_leaving_badge(source: StringName) -> void:
	_rock_leaving_sources[source] = true


## Pose la contribution actuelle d'un badge "scaling permanent" au facteur
## scaling_mult (ecrase sa propre entree, pas celles des autres sources —
## un badge qui rappelle set_scaling_mult_bonus plusieurs fois dans la meme
## manche, ex a chaque special joue, ne double donc pas son propre bonus).
## Effectif immediatement si appele en cours de manche (comme
## set_global_multiplier), et reste actif a la manche suivante sans qu'un
## nouveau round_start soit necessaire.
func set_scaling_mult_bonus(source: StringName, amount: float) -> void:
	_scaling_mult_bonuses[source] = amount
	if _active_context != null:
		_active_context.scaling_mult_bonus = _sum_dict_values(_scaling_mult_bonuses)
		_active_context.scaling_mult_bonuses = _scaling_mult_bonuses.duplicate()


## Meme principe que set_scaling_mult_bonus, pour le canal flat_score_bonus
## (ajoute au value_sum au lieu de multiplier).
func set_flat_score_bonus(source: StringName, amount: int) -> void:
	_flat_score_bonuses[source] = amount
	if _active_context != null:
		_active_context.flat_score_bonus = int(_sum_dict_values(_flat_score_bonuses))
		_active_context.flat_score_bonuses = _flat_score_bonuses.duplicate()


## Pose la chance (0.0-1.0) qu'un jeton scorable gagne +1 de valeur dans le
## deck au moment ou il score (ex: "Poker Face"). Cumulatif entre badges,
## meme principe que set_scaling_mult_bonus.
func set_token_upgrade_chance(source: StringName, chance: float) -> void:
	_token_upgrade_chances[source] = chance
	if _active_context != null:
		_active_context.token_upgrade_chance = _sum_dict_values(_token_upgrade_chances)


## Pose la contribution actuelle d'un badge au bonus de multiplicateur d'une
## Partition PRECISE (ex: "Refrain", cumule +0.1 par score sur CETTE
## Partition). Meme principe que set_scaling_mult_bonus (le badge recalcule
## et ecrase sa propre entree a chaque appel, pas d'addition en double) mais
## garde EN PLUS par sheet_name : deux Partitions differentes accumulent
## chacune leur propre compteur, independamment.
func add_sheet_multiplier_bonus(sheet_name: StringName, amount: float, source: StringName = &"") -> void:
	var contributions: Dictionary = (_sheet_multiplier_bonus_contributions.get(sheet_name, {}) as Dictionary).duplicate()
	contributions[source] = amount
	_sheet_multiplier_bonus_contributions[sheet_name] = contributions
	if _active_context != null:
		_active_context.sheet_multiplier_bonus_contributions = _sheet_multiplier_bonus_contributions.duplicate(true)


## Cherche dans le pool un bouton de base du meme family/valeur et l'upgrade
## de +1 (meme effet que l'action "Augmenter" des Des a coudre). Essaie tous
## les candidats trouves avant d'abandonner : le premier match peut deja etre
## au plafond (GameRules.MAX_BUTTON_VALUE) sans que ce soit le cas d'un autre
## exemplaire du meme family/valeur. Appele par TurnController en lisant les
## evenements EventType.UPGRADE de la timeline (voir CascadeResolver._roll_upgrades).
func upgrade_matching_button(family: TokenData.Family, value: int) -> bool:
	for i in range(_button_pool.size()):
		var candidate: TokenData = _button_pool[i]
		if candidate.kind == TokenData.Kind.BASE and candidate.family == family and candidate.value == value:
			if increase_button_value(i):
				return true
	return false


## Fait progresser un jeton deja a MAX_BUTTON_VALUE vers la figure suivante
## (arcanes mineurs — voir GameRules.next_face_value). Chemin distinct de
## upgrade_matching_button/increase_button_value (Fusion/Augmenter/Poker
## Face), qui restent plafonnes a MAX_BUTTON_VALUE : celui-ci n'existe QUE
## via le score (voir CascadeResolver._roll_face_promotions).
## Ignore les jetons verrouilles (voir lock_button) : ils gardent leur rang
## meme s'ils rescorent. Si plusieurs exemplaires du meme family/valeur
## existent, seul un exemplaire NON verrouille peut etre promu.
func promote_matching_button(family: TokenData.Family, value: int) -> bool:
	var next_value: int = GameRules.next_face_value(value)
	if next_value == value:
		return false
	for i in range(_button_pool.size()):
		var candidate: TokenData = _button_pool[i]
		if candidate.kind == TokenData.Kind.BASE and candidate.family == family and candidate.value == value and not candidate.locked:
			_button_pool[i] = TokenData.make_base(family, next_value)
			button_pool_changed.emit()
			figure_promoted.emit(next_value)
			return true
	return false


## Action "Fixer" des Des a coudre : verrouille une figure (Valet+) contre
## toute promotion future par le score. Gratuit en ressources autres que le
## Des a coudre lui-meme — pas un achat direct de progression, juste un choix
## de timing sur un chemin qui reste entierement gagne par le jeu.
func lock_button(index: int) -> bool:
	if index < 0 or index >= _button_pool.size():
		return false
	var token: TokenData = _button_pool[index]
	if token.value < GameRules.MAX_BUTTON_VALUE or token.locked:
		return false
	var locked_copy: TokenData = TokenData.make_base(token.family, token.value)
	locked_copy.locked = true
	_button_pool[index] = locked_copy
	button_pool_changed.emit()
	return true


## Etat libre par badge, JAMAIS remis a zero en cours de run (voir
## _run_badge_state) — pour les compteurs "scaling permanent" qui doivent
## survivre aux transitions de manche (contrairement a get_badge_state/
## set_badge_state, remis a zero chaque manche).
func get_run_badge_state(key: StringName, default: Variant = null) -> Variant:
	return _run_badge_state.get(key, default)


func set_run_badge_state(key: StringName, value: Variant) -> void:
	_run_badge_state[key] = value


## Change le multiplicateur global de score, effectif des la prochaine
## resolution (mute directement le RunContext actif de la manche en cours).
## Appele par des badges dynamiques (ex: "Dernier Carre", "Regularite"), qui
## passent leur propre id (attribution pour la bannière de résolution).
## NOTE : comme set_rule_multiplier, la derniere ecriture ecrase les
## precedentes — pas de cumul entre deux badges qui viseraient tous les deux
## le multiplicateur global (meme limitation connue que les rule_multipliers,
## voir questions-ouvertes.md).
## Deux badges sur le global_multiplier se multiplient entre eux (voir
## RunContext.get_global_multiplier) — chacun n'ecrase que sa PROPRE entree
## (rappeler set_global_multiplier plusieurs fois pour le meme badge, ex. a
## chaque tour pour Regularite, ne double donc pas son propre facteur).
func set_global_multiplier(mult: float, source: StringName = &"") -> void:
	_global_multiplier_contributions[source] = mult
	if _active_context != null:
		_active_context.global_multiplier_contributions = _global_multiplier_contributions.duplicate()


## Etat libre par badge, remis a zero a chaque manche (voir _badge_state).
func get_badge_state(key: StringName, default: Variant = null) -> Variant:
	return _badge_state.get(key, default)


func set_badge_state(key: StringName, value: Variant) -> void:
	_badge_state[key] = value


# --- Mouches ---

func get_flies() -> int:
	return _flies


func add_flies(n: int) -> void:
	if n <= 0:
		return
	_flies += n
	flies_changed.emit(_flies)


func spend_flies(n: int) -> bool:
	if n < 0 or _flies < n:
		return false
	_flies -= n
	flies_changed.emit(_flies)
	return true


# --- Shake ---

func get_shake_charges() -> int:
	return _shake_charges


## Consomme une charge de Shake (voir DeckManager.shake). Retourne false sans
## rien faire si plus aucune charge -- au consommateur (TurnController) de
## n'appeler deck_manager.shake() que si ceci retourne true.
func spend_shake_charge() -> bool:
	if _shake_charges <= 0:
		return false
	_shake_charges -= 1
	shake_charges_changed.emit(_shake_charges)
	return true


## Ajoute des charges de Shake (ex: "Regain", +1 par level up de Partition).
## Symetrique de spend_shake_charge, pas de plafond.
func add_shake_charges(n: int) -> void:
	if n <= 0:
		return
	_shake_charges += n
	shake_charges_changed.emit(_shake_charges)


# --- Sheets ---

func get_equipped_sheets() -> Array[SheetData]:
	return _equipped_sheets


func equip_sheet(sheet: SheetData) -> bool:
	if _equipped_sheets.size() >= GameRules.MAX_SHEET_SLOTS:
		return false
	if _equipped_sheets.has(sheet):
		return false
	_equipped_sheets.append(sheet)
	sheets_changed.emit(_equipped_sheets)
	return true


## Retire une Partition equipee (vente). Retourne false si elle n'etait pas
## equipee. N'affecte pas la resolution de la manche en cours (deja snapshotee
## dans SheetManager au round_start) — prend effet a la manche suivante,
## comme le level up des Partitions.
func unequip_sheet(sheet: SheetData) -> bool:
	if not _equipped_sheets.has(sheet):
		return false
	_equipped_sheets.erase(sheet)
	sheets_changed.emit(_equipped_sheets)
	return true


## Vend une Partition equipee contre GameRules.SELL_REFUND_RATIO de son prix
## d'achat, en mouches. Aucun plancher : vendable jusqu'a 0 Partition equipee.
func sell_sheet(sheet: SheetData) -> bool:
	if not unequip_sheet(sheet):
		return false
	add_flies(int(sheet.price * GameRules.SELL_REFUND_RATIO))
	sheet_sold.emit(sheet.sheet_name)
	return true


# --- Badges ---

func get_equipped_badges() -> Array[BadgeData]:
	return _equipped_badges


## Verifie si un badge precis (par id) est equipe — pratique pour du code hors
## du pipeline de dispatch habituel (ex: ShopUI qui verifie "Econome" pour un
## reroll gratuit, le shop n'a pas de trigger de manche a lui).
func has_badge(id: StringName) -> bool:
	for badge in _equipped_badges:
		if badge.id == id:
			return true
	return false


func equip_badge(badge: BadgeData) -> bool:
	if _equipped_badges.size() >= get_badge_slot_count():
		return false
	if _equipped_badges.has(badge):
		return false
	_equipped_badges.append(badge)
	badges_changed.emit(_equipped_badges)
	return true


## Retire un Badge equipe (vente). Retourne false s'il n'etait pas equipe.
## Contrairement aux Partitions, prend effet immediatement : BadgeManager lit
## la liste equipee en direct a chaque dispatch, pas de snapshot de manche.
## Nettoie au passage sa contribution "scaling permanent" (voir
## set_scaling_mult_bonus/set_flat_score_bonus) — sinon un badge revendu
## continuerait de contribuer indefiniment, ces dictionnaires n'etant jamais
## remis a zero a chaque manche comme le reste des modifiers.
func unequip_badge(badge: BadgeData) -> bool:
	if not _equipped_badges.has(badge):
		return false
	_equipped_badges.erase(badge)
	_scaling_mult_bonuses.erase(badge.id)
	_flat_score_bonuses.erase(badge.id)
	_token_upgrade_chances.erase(badge.id)
	for sheet_name in _sheet_multiplier_bonus_contributions.keys():
		var contributions: Dictionary = (_sheet_multiplier_bonus_contributions[sheet_name] as Dictionary).duplicate()
		contributions.erase(badge.id)
		_sheet_multiplier_bonus_contributions[sheet_name] = contributions
	if _active_context != null:
		_active_context.scaling_mult_bonus = _sum_dict_values(_scaling_mult_bonuses)
		_active_context.scaling_mult_bonuses = _scaling_mult_bonuses.duplicate()
		_active_context.flat_score_bonus = int(_sum_dict_values(_flat_score_bonuses))
		_active_context.flat_score_bonuses = _flat_score_bonuses.duplicate()
		_active_context.token_upgrade_chance = _sum_dict_values(_token_upgrade_chances)
		_active_context.sheet_multiplier_bonus_contributions = _sheet_multiplier_bonus_contributions.duplicate(true)
	badges_changed.emit(_equipped_badges)
	return true


## Vend un Badge equipe contre GameRules.SELL_REFUND_RATIO de son prix d'achat,
## en mouches. Aucun plancher.
func sell_badge(badge: BadgeData) -> bool:
	if not unequip_badge(badge):
		return false
	add_flies(int(badge.price * GameRules.SELL_REFUND_RATIO))
	return true


# --- Deck composition ---

## Pool de boutons possedes, persistant pour toute la run. Le DeckManager
## en tire une copie fraiche a chaque manche (build_deck), pour ne pas muter
## les instances possedees en les consommant sur la grille.
func get_button_pool() -> Array[TokenData]:
	return _button_pool.duplicate()


## Deck de la prochaine manche pour l'affichage hors-manche (shop, ouverture
## de pack) — aucun DeckManager de manche n'existe encore a ce moment (il est
## instancie par GameScene a chaque nouvelle manche, voir TurnController.
## start_round). Construit un DeckManager jetable avec la meme logique
## (build_deck) pour ne pas dupliquer la composition ailleurs, puis le libere.
func build_next_round_deck_preview() -> Array[TokenData]:
	var preview: DeckManager = DeckManager.new()
	preview.rock_count_bonus = build_context().rock_count_bonus
	preview.build_deck(get_deck_composition(), get_button_pool())
	var tokens: Array[TokenData] = preview.get_remaining_tokens()
	preview.free()
	return tokens


## Ajoute un bouton possede au pool (achat unitaire au shop).
func add_button(family: TokenData.Family, value: int) -> void:
	_button_pool.append(TokenData.make_base(family, value))
	button_pool_changed.emit()


## Tire n candidats au hasard dans le pool pour un outil de deck (Fusion,
## Augmenter, Scinder...), avec leur index d'origine (necessaire pour les
## methodes de mutation ensuite). Ne mute rien.
func get_deck_tool_candidates(n: int) -> Array[Dictionary]:
	var indices: Array[int] = []
	for i in range(_button_pool.size()):
		indices.append(i)
	indices.shuffle()

	var picked: Array[Dictionary] = []
	for i in range(min(n, indices.size())):
		var idx: int = indices[i]
		picked.append({"index": idx, "token": _button_pool[idx]})
	return picked


## Fusionne 2 boutons possedes (index dans le pool, cf. get_deck_tool_candidates).
## Valeur = somme des deux. Famille = tiree au hasard entre les deux entrees
## (donc deterministe si les deux boutons sont deja de la meme famille).
func fuse_buttons(index_a: int, index_b: int) -> bool:
	if index_a == index_b:
		return false
	if index_a < 0 or index_a >= _button_pool.size():
		return false
	if index_b < 0 or index_b >= _button_pool.size():
		return false

	var token_a: TokenData = _button_pool[index_a]
	var token_b: TokenData = _button_pool[index_b]
	var result_family: TokenData.Family = token_a.family if randi() % 2 == 0 else token_b.family
	var result_value: int = min(token_a.value + token_b.value, GameRules.MAX_BUTTON_VALUE)

	# Retirer le plus grand index d'abord pour ne pas decaler l'autre.
	_button_pool.remove_at(max(index_a, index_b))
	_button_pool.remove_at(min(index_a, index_b))
	_button_pool.append(TokenData.make_base(result_family, result_value))

	button_pool_changed.emit()
	return true


## Augmenter : +1 sur la valeur d'un bouton possede (index dans le pool, cf.
## get_deck_tool_candidates). Refuse si deja au plafond (GameRules.MAX_BUTTON_VALUE).
func increase_button_value(index: int) -> bool:
	if index < 0 or index >= _button_pool.size():
		return false
	var token: TokenData = _button_pool[index]
	if token.value >= GameRules.MAX_BUTTON_VALUE:
		return false
	_button_pool[index] = TokenData.make_base(token.family, token.value + 1)
	button_pool_changed.emit()
	return true


## Reduire : -1 sur la valeur d'un bouton possede. Refuse si deja au plancher
## (GameRules.TOKEN_MIN_VALUE) ou si c'est une figure (Valet+) — celles-ci ne
## s'obtiennent que par le score, elles ne se perdent pas via un outil de deck.
func decrease_button_value(index: int) -> bool:
	if index < 0 or index >= _button_pool.size():
		return false
	var token: TokenData = _button_pool[index]
	if token.value <= GameRules.TOKEN_MIN_VALUE:
		return false
	if token.value > GameRules.MAX_BUTTON_VALUE:
		return false
	_button_pool[index] = TokenData.make_base(token.family, token.value - 1)
	button_pool_changed.emit()
	return true


## Changer de famille : recolore un bouton possede vers la famille donnee.
## Refuse si le bouton est deja de cette famille (rien a faire).
func change_button_family(index: int, family: TokenData.Family) -> bool:
	if index < 0 or index >= _button_pool.size():
		return false
	var token: TokenData = _button_pool[index]
	if token.family == family:
		return false
	_button_pool[index] = TokenData.make_base(family, token.value)
	button_pool_changed.emit()
	return true


## Scinder : inverse de la Fusion, uniquement sur les valeurs paires. 1 bouton
## -> 2 boutons de meme famille, valeur = moitie chacun (ex : 6 -> 3+3).
func split_button(index: int) -> bool:
	if index < 0 or index >= _button_pool.size():
		return false
	var token: TokenData = _button_pool[index]
	if token.value % 2 != 0:
		return false
	@warning_ignore("integer_division")
	var half: int = token.value / 2
	_button_pool.remove_at(index)
	_button_pool.append(TokenData.make_base(token.family, half))
	_button_pool.append(TokenData.make_base(token.family, half))
	button_pool_changed.emit()
	return true


## Suppression : retire un bouton possede du pool, jamais remplace. Le plus
## fort des outils de deck vu le sans-reshuffle (ameliore les probas de
## tirage de tout ce qui reste pour le reste de la manche).
func remove_button(index: int) -> bool:
	if index < 0 or index >= _button_pool.size():
		return false
	_button_pool.remove_at(index)
	button_pool_changed.emit()
	return true


func get_deck_composition() -> Dictionary:
	return _deck_composition.duplicate()


func add_special(type: TokenData.SpecialType) -> void:
	_increment_special_count(type)
	deck_composition_changed.emit()


## Un special achete est un bien persistant (comme un bouton ou un Badge) :
## il reste dans le deck manche apres manche jusqu'a etre reellement joue sur
## la grille (voir TurnController.play_current_to). La seule facon d'en
## obtenir un autre est d'en racheter au shop.
func consume_special(type: TokenData.SpecialType) -> void:
	_decrement_special_count(type)
	deck_composition_changed.emit()


## Re-ajoute au deck les specials dont le flag debug_always_in_deck est actif
## (outil de test, voir SpecialItem — n'affecte jamais les specials achetes).
func apply_debug_specials() -> void:
	_apply_debug_specials_to_deck()
	deck_composition_changed.emit()


## Parcourt tous les SpecialItem connus du ShopManager et ajoute au deck ceux
## dont le flag debug_always_in_deck est actif.
func _apply_debug_specials_to_deck() -> void:
	for path in ShopManager.SPECIAL_PATHS:
		var item: SpecialItem = load(path) as SpecialItem
		if item != null and item.debug_always_in_deck:
			_increment_special_count(item.special_type)


func _increment_special_count(type: TokenData.SpecialType) -> void:
	match type:
		TokenData.SpecialType.BOMBE:
			_deck_composition["bombe_count"] += 1
		TokenData.SpecialType.FANTOME:
			_deck_composition["fantome_count"] += 1
		TokenData.SpecialType.MAREE:
			_deck_composition["maree_count"] += 1
		TokenData.SpecialType.ENCLUME:
			_deck_composition["enclume_count"] += 1
		TokenData.SpecialType.PETARD_A_MECHE:
			_deck_composition["petard_a_meche_count"] += 1
		TokenData.SpecialType.CAVALIER:
			_deck_composition["cavalier_count"] += 1
		TokenData.SpecialType.FROG:
			_deck_composition["frog_count"] += 1
		TokenData.SpecialType.LIANE:
			_deck_composition["liane_count"] += 1
		TokenData.SpecialType.CROW:
			_deck_composition["crow_count"] += 1
		TokenData.SpecialType.UNDERGROUND:
			_deck_composition["underground_count"] += 1
		TokenData.SpecialType.HYPERCUBE:
			_deck_composition["hypercube_count"] += 1


func _decrement_special_count(type: TokenData.SpecialType) -> void:
	var key: String = ""
	match type:
		TokenData.SpecialType.BOMBE:
			key = "bombe_count"
		TokenData.SpecialType.FANTOME:
			key = "fantome_count"
		TokenData.SpecialType.MAREE:
			key = "maree_count"
		TokenData.SpecialType.ENCLUME:
			key = "enclume_count"
		TokenData.SpecialType.PETARD_A_MECHE:
			key = "petard_a_meche_count"
		TokenData.SpecialType.CAVALIER:
			key = "cavalier_count"
		TokenData.SpecialType.FROG:
			key = "frog_count"
		TokenData.SpecialType.LIANE:
			key = "liane_count"
		TokenData.SpecialType.CROW:
			key = "crow_count"
		TokenData.SpecialType.UNDERGROUND:
			key = "underground_count"
		TokenData.SpecialType.HYPERCUBE:
			key = "hypercube_count"
	if key != "":
		_deck_composition[key] = maxi(0, (_deck_composition[key] as int) - 1)
