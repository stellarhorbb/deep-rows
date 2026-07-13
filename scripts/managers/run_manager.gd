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
	ctx.grid_modifiers = _grid_modifiers.duplicate()
	ctx.rule_multipliers = _rule_multipliers.duplicate()
	ctx.rule_multiplier_sources = _rule_multiplier_sources.duplicate()
	ctx.tag_level_multipliers = _build_tag_level_multipliers()
	ctx.value_bonus_multipliers = _value_bonus_multipliers.duplicate()
	ctx.value_bonus_multiplier_sources = _value_bonus_multiplier_sources.duplicate()
	ctx.global_multiplier_source = _global_multiplier_source
	_active_context = ctx
	return ctx


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
func unequip_badge(badge: BadgeData) -> bool:
	if not _equipped_badges.has(badge):
		return false
	_equipped_badges.erase(badge)
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
