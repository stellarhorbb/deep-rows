## Porte les donnees qui evoluent au cours d'un run (tags equipes, deck,
## mouches, plus tard badges/states/niveaux). Mute uniquement par l'orchestration
## (TurnController, ShopManager a venir). Les autres lisent via build_context().
class_name RunManager
extends Node

signal flies_changed(amount: int)
signal tags_changed(equipped: Array[PatternData])
signal badges_changed(equipped: Array[BadgeData])
signal deck_composition_changed()
signal grid_modifiers_changed(modifiers: Dictionary)
signal button_pool_changed()
signal tag_leveled_up(tag_name: StringName, new_level: int)
signal tag_progress_changed(tag_name: StringName)

var _flies: int = 0
var _equipped_tags: Array[PatternData] = []
var _equipped_badges: Array[BadgeData] = []
var _button_pool: Array[TokenData] = []
var _deck_composition: Dictionary = {
	"bombe_count": 0,
	"fantome_count": 0,
	"maree_count": 0,
}
var _grid_modifiers: Dictionary = {}    # Vector2i -> Array[StringName]
var _rule_multipliers: Dictionary = {}  # StringName -> float
var _rule_multiplier_sources: Dictionary = {}  # StringName (rule) -> StringName (badge id)
var _value_bonus_multipliers: Dictionary = {}  # int (value) -> float
var _value_bonus_multiplier_sources: Dictionary = {}  # int (value) -> StringName (badge id)
var _global_multiplier_source: StringName = &""
var _retrigger_values: Dictionary = {}  # int (value) -> true
var _retrigger_value_sources: Dictionary = {}  # int (value) -> StringName (badge id)
var _family_score_bonus: Dictionary = {}  # TokenData.Family -> int
var _family_score_bonus_sources: Dictionary = {}  # TokenData.Family -> StringName (badge id)
var _pair_score_bonus: int = 0
var _pair_score_bonus_source: StringName = &""
var _top_row_score_bonus: int = 0
var _top_row_score_bonus_source: StringName = &""

## Bonus de slots de hold / taille de preview pour la manche (session 17) :
## StringName (id du badge) -> int. Remis a zero chaque manche comme les
## rule_multipliers — repeuples par les badges on_round_start.
var _hold_slot_bonuses: Dictionary = {}
var _preview_size_bonuses: Dictionary = {}
var _rock_leaving_sources: Dictionary = {}  # StringName -> true

## Contribution actuelle de chaque badge "scaling permanent" au facteur
## scaling_mult / au flat_score_bonus : StringName (id du badge) -> float/int.
## Jamais remis a zero a chaque manche (contrairement aux dictionnaires
## ci-dessus) — seul le retrait d'un badge equipe (voir unequip_badge) efface
## son entree. Permet au bonus de rester actif d'une manche a l'autre sans
## attendre un nouveau round_start pour se re-populer.
var _scaling_mult_bonuses: Dictionary = {}  # StringName -> float
var _flat_score_bonuses: Dictionary = {}  # StringName -> int
var _token_upgrade_chances: Dictionary = {}  # StringName -> float

## Etat persistant par badge, JAMAIS remis a zero en cours de run (contrairement
## a _badge_state, reset chaque manche) — sert aux badges "scaling permanent"
## qui grossissent sur toute la run (ex: nombre de speciaux joues, cumulatif
## pour Jetons sacres). Cle = StringName propre a chaque badge. Reset
## uniquement par init_run (nouvelle run).
var _run_badge_state: Dictionary = {}
var _tag_progress: Dictionary = {}      # StringName (tag_name) -> {"cumulative": int, "level": int}

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
## ici : c'est l'ecran de selection de Partition (draft_starter_partitions) qui
## appelle equip_tag() avec le choix du joueur avant le debut de la manche 1.
func init_run() -> void:
	_flies = 0

	_equipped_tags.clear()

	_equipped_badges.clear()
	# DEBUG : equipe au demarrage les badges dont debug_start_equipped == true.
	# Flag a activer dans chaque .tres via l'editeur Godot.
	for path in ShopManager.BADGE_PATHS:
		var badge: BadgeData = load(path) as BadgeData
		if badge != null and badge.debug_start_equipped:
			_equipped_badges.append(badge)

	_button_pool = _generate_starter_buttons()
	_tag_progress.clear()

	_deck_composition = {
		"bombe_count": 0,
		"fantome_count": 0,
		"maree_count": 0,
	}
	_scaling_mult_bonuses.clear()
	_flat_score_bonuses.clear()
	_token_upgrade_chances.clear()
	_run_badge_state.clear()
	_apply_debug_specials_to_deck()

	flies_changed.emit(_flies)
	tags_changed.emit(_equipped_tags)
	badges_changed.emit(_equipped_badges)
	deck_composition_changed.emit()


## Genere le pool de boutons de depart : x copies de chaque (famille, valeur)
## possible (STARTER_COPIES_PER_VALUE), pas un tirage purement aleatoire —
## garantit une repartition egale entre les 4 familles, pour ne pas saboter
## un demarrage jouable par un mauvais tirage independant du choix de Partition.
## Ce pool persiste ensuite pour toute la run, seul le shop pourra le muter
## (achat, fusion).
func _generate_starter_buttons() -> Array[TokenData]:
	var buttons: Array[TokenData] = []
	for family in range(GameRules.FAMILY_COUNT):
		for value in range(GameRules.TOKEN_MIN_VALUE, GameRules.TOKEN_MAX_VALUE + 1):
			for i in range(GameRules.STARTER_COPIES_PER_VALUE):
				buttons.append(TokenData.make_base(family as TokenData.Family, value))
	return buttons


## Tire des Partitions au hasard dans tout le catalogue (ShopManager.TAG_PATHS),
## pour l'ecran de selection de Partition de depart. Ne mute rien.
func draft_starter_partitions(n: int = GameRules.STARTER_PARTITION_DRAFT_SIZE) -> Array[PatternData]:
	var pool: Array[PatternData] = []
	for path in ShopManager.TAG_PATHS:
		var tag: PatternData = load(path) as PatternData
		if tag != null:
			pool.append(tag)
	pool.shuffle()
	return pool.slice(0, min(n, pool.size()))


## Construit un snapshot lu par les systemes.
func build_context() -> RunContext:
	var ctx: RunContext = RunContext.new()
	ctx.equipped_tags = _equipped_tags.duplicate()
	ctx.equipped_badges = _equipped_badges.duplicate()
	ctx.grid_modifiers = _grid_modifiers.duplicate()
	ctx.rule_multipliers = _rule_multipliers.duplicate()
	ctx.rule_multiplier_sources = _rule_multiplier_sources.duplicate()
	ctx.tag_level_multipliers = _build_tag_level_multipliers()
	ctx.value_bonus_multipliers = _value_bonus_multipliers.duplicate()
	ctx.value_bonus_multiplier_sources = _value_bonus_multiplier_sources.duplicate()
	ctx.global_multiplier_source = _global_multiplier_source
	ctx.retrigger_values = _retrigger_values.duplicate()
	ctx.retrigger_value_sources = _retrigger_value_sources.duplicate()
	ctx.family_score_bonus = _family_score_bonus.duplicate()
	ctx.family_score_bonus_sources = _family_score_bonus_sources.duplicate()
	ctx.pair_score_bonus = _pair_score_bonus
	ctx.pair_score_bonus_source = _pair_score_bonus_source
	ctx.top_row_score_bonus = _top_row_score_bonus
	ctx.top_row_score_bonus_source = _top_row_score_bonus_source
	ctx.scaling_mult_bonus = _sum_dict_values(_scaling_mult_bonuses)
	ctx.scaling_mult_bonuses = _scaling_mult_bonuses.duplicate()
	ctx.flat_score_bonus = int(_sum_dict_values(_flat_score_bonuses))
	ctx.flat_score_bonuses = _flat_score_bonuses.duplicate()
	ctx.token_upgrade_chance = _sum_dict_values(_token_upgrade_chances)
	ctx.hold_slot_bonus = int(_sum_dict_values(_hold_slot_bonuses))
	ctx.preview_size_bonus = int(_sum_dict_values(_preview_size_bonuses))
	ctx.rock_leaving_sources = _rock_leaving_sources.duplicate()
	_active_context = ctx
	return ctx


func _sum_dict_values(d: Dictionary) -> float:
	var total: float = 0.0
	for v in d.values():
		total += v as float
	return total


func _build_tag_level_multipliers() -> Dictionary:
	var result: Dictionary = {}
	for tag in _equipped_tags:
		result[tag.tag_name] = GameRules.get_pattern_level_multiplier(get_tag_level(tag.tag_name))
	return result


# --- Level up des Partitions ---

## Ajoute du score cumule a une Partition (par tag_name) et met a jour son
## niveau. Appele par TurnController a chaque groupe resolu. Le multiplicateur
## resultant n'est lu par le scoring qu'a la prochaine manche (snapshot dans
## build_context, comme rule_multipliers).
func add_tag_score(tag_name: StringName, amount: int) -> void:
	if amount <= 0 or tag_name == &"":
		return
	if not _tag_progress.has(tag_name):
		_tag_progress[tag_name] = {"cumulative": 0, "level": 1}

	var progress: Dictionary = _tag_progress[tag_name]
	var cumulative: int = (progress["cumulative"] as int) + amount
	var old_level: int = progress["level"] as int
	var new_level: int = GameRules.compute_pattern_level(cumulative)

	progress["cumulative"] = cumulative
	progress["level"] = new_level
	_tag_progress[tag_name] = progress

	tag_progress_changed.emit(tag_name)
	if new_level != old_level:
		tag_leveled_up.emit(tag_name, new_level)


func get_tag_level(tag_name: StringName) -> int:
	if not _tag_progress.has(tag_name):
		return 1
	return (_tag_progress[tag_name] as Dictionary)["level"] as int


func get_tag_cumulative_score(tag_name: StringName) -> int:
	if not _tag_progress.has(tag_name):
		return 0
	return (_tag_progress[tag_name] as Dictionary)["cumulative"] as int


## Reset la couche "modifiers de manche" : grid modifiers + rule multipliers.
## Appele au start_round avant que les badges on_round_start ne peuplent.
func reset_round_modifiers() -> void:
	_grid_modifiers.clear()
	_rule_multipliers.clear()
	_rule_multiplier_sources.clear()
	_value_bonus_multipliers.clear()
	_value_bonus_multiplier_sources.clear()
	_global_multiplier_source = &""
	_retrigger_values.clear()
	_retrigger_value_sources.clear()
	_family_score_bonus.clear()
	_family_score_bonus_sources.clear()
	_pair_score_bonus = 0
	_pair_score_bonus_source = &""
	_top_row_score_bonus = 0
	_top_row_score_bonus_source = &""
	_hold_slot_bonuses.clear()
	_preview_size_bonuses.clear()
	_rock_leaving_sources.clear()
	_badge_state.clear()
	_active_context = null


## Ajoute un modifier sur une cellule. Appele par les badges. Les modifiers
## s'empilent sur une meme case (ex: Tranchee + Bord a Bord, ou Cellule Triple
## par-dessus un badge colonne) : chaque type ajoute son propre multiplicateur
## au lieu d'ecraser les precedents, voir CascadeResolver._modifier_multiplier.
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
func set_rule_multiplier(rule: StringName, mult: float, source: StringName = &"") -> void:
	_rule_multipliers[rule] = mult
	_rule_multiplier_sources[rule] = source


func get_grid_modifiers() -> Dictionary:
	return _grid_modifiers.duplicate()


func get_rule_multipliers() -> Dictionary:
	return _rule_multipliers.duplicate()


## Pose un bonus additif au multiplicateur d'une figure par occurrence d'une
## valeur de jeton donnee (ex: 1 -> 0.5 pour "Petites Mains"). Appele par les
## badges au round_start, qui passent leur propre id (attribution pour la
## bannière de résolution).
func add_value_bonus_multiplier(value: int, bonus: float, source: StringName = &"") -> void:
	_value_bonus_multipliers[value] = bonus
	_value_bonus_multiplier_sources[value] = source


## Marque une valeur de jeton comme "retrigger" : un jeton scorable de cette
## valeur recompte sa propre valeur une deuxieme fois dans le value_sum du
## groupe qui score (ex: un 3 qui score vaut 6 points). Idempotent — deux
## badges qui ciblent la meme valeur ne la font pas compter trois fois.
func add_retrigger_value(value: int, source: StringName = &"") -> void:
	_retrigger_values[value] = true
	_retrigger_value_sources[value] = source


## Pose un bonus flat ajoute au value_sum quand un pattern de rule "family" de
## cette famille score (ex: "Encrée" -> INK). Cumulatif entre badges.
func add_family_score_bonus(family: TokenData.Family, bonus: int, source: StringName = &"") -> void:
	_family_score_bonus[family] = (_family_score_bonus.get(family, 0) as int) + bonus
	_family_score_bonus_sources[family] = source


## Pose un bonus flat ajoute au value_sum quand le groupe qui score contient
## au moins deux jetons de meme valeur ("paire", ex: "Y'en a pas deux").
## Cumulatif entre badges.
func add_pair_score_bonus(bonus: int, source: StringName = &"") -> void:
	_pair_score_bonus += bonus
	_pair_score_bonus_source = source


## Pose un bonus flat ajoute au value_sum de chaque pattern qui score tant
## qu'un jeton occupe la rangee du haut de la grille (ex: "Sommet"). Cumulatif
## entre badges.
func add_top_row_score_bonus(bonus: int, source: StringName = &"") -> void:
	_top_row_score_bonus += bonus
	_top_row_score_bonus_source = source


## Ajoute un bonus de slots de hold pour la manche (ex: "Bénédiction", +1).
## Cumulatif entre badges, remis a zero chaque manche (repeuple au round_start).
func add_hold_slot_bonus(bonus: int, source: StringName = &"") -> void:
	_hold_slot_bonuses[source] = bonus


## Meme principe qu'add_hold_slot_bonus, pour la taille de preview du stream
## (ex: "Visionnaire", +1).
func add_preview_size_bonus(bonus: int, source: StringName = &"") -> void:
	_preview_size_bonuses[source] = bonus


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
func set_global_multiplier(mult: float, source: StringName = &"") -> void:
	_global_multiplier_source = source
	if _active_context != null:
		_active_context.global_multiplier = mult
		_active_context.global_multiplier_source = source


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


# --- Tags ---

func get_equipped_tags() -> Array[PatternData]:
	return _equipped_tags


func equip_tag(tag: PatternData) -> bool:
	if _equipped_tags.size() >= GameRules.MAX_PATTERN_SLOTS:
		return false
	if _equipped_tags.has(tag):
		return false
	_equipped_tags.append(tag)
	tags_changed.emit(_equipped_tags)
	return true


## Retire une Partition equipee (vente). Retourne false si elle n'etait pas
## equipee. N'affecte pas la resolution de la manche en cours (deja snapshotee
## dans PatternManager au round_start) — prend effet a la manche suivante,
## comme le level up des Partitions.
func unequip_tag(tag: PatternData) -> bool:
	if not _equipped_tags.has(tag):
		return false
	_equipped_tags.erase(tag)
	tags_changed.emit(_equipped_tags)
	return true


## Vend une Partition equipee contre GameRules.SELL_REFUND_RATIO de son prix
## d'achat, en mouches. Aucun plancher : vendable jusqu'a 0 Partition equipee.
func sell_tag(tag: PatternData) -> bool:
	if not unequip_tag(tag):
		return false
	add_flies(int(tag.price * GameRules.SELL_REFUND_RATIO))
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
	if _equipped_badges.size() >= GameRules.MAX_BADGE_SLOTS:
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
	if _active_context != null:
		_active_context.scaling_mult_bonus = _sum_dict_values(_scaling_mult_bonuses)
		_active_context.scaling_mult_bonuses = _scaling_mult_bonuses.duplicate()
		_active_context.flat_score_bonus = int(_sum_dict_values(_flat_score_bonuses))
		_active_context.flat_score_bonuses = _flat_score_bonuses.duplicate()
		_active_context.token_upgrade_chance = _sum_dict_values(_token_upgrade_chances)
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
## (GameRules.TOKEN_MIN_VALUE).
func decrease_button_value(index: int) -> bool:
	if index < 0 or index >= _button_pool.size():
		return false
	var token: TokenData = _button_pool[index]
	if token.value <= GameRules.TOKEN_MIN_VALUE:
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


func _decrement_special_count(type: TokenData.SpecialType) -> void:
	var key: String = ""
	match type:
		TokenData.SpecialType.BOMBE:
			key = "bombe_count"
		TokenData.SpecialType.FANTOME:
			key = "fantome_count"
		TokenData.SpecialType.MAREE:
			key = "maree_count"
	if key != "":
		_deck_composition[key] = maxi(0, (_deck_composition[key] as int) - 1)
