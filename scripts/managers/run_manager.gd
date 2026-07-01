## Porte les donnees qui evoluent au cours d'un run (tags equipes, deck,
## mouches, plus tard echoes/states/niveaux). Mute uniquement par l'orchestration
## (TurnController, ShopManager a venir). Les autres lisent via build_context().
class_name RunManager
extends Node

signal flies_changed(amount: int)
signal tags_changed(equipped: Array[PatternData])
signal echoes_changed(equipped: Array[EchoData])
signal deck_composition_changed()
signal grid_modifiers_changed(modifiers: Dictionary)
signal button_pool_changed()
signal tag_leveled_up(tag_name: StringName, new_level: int)
signal tag_progress_changed(tag_name: StringName)

## Chemins des tags du starter pack (valable pour le proto).
## Plus tard : vient du pack de base choisi par le joueur.
const STARTER_TAG_PATHS: Array[String] = [
	"res://resources/patterns/line_family_4.tres",
	"res://resources/patterns/line_number_3.tres",
]

var _flies: int = 0
var _equipped_tags: Array[PatternData] = []
var _equipped_echoes: Array[EchoData] = []
var _button_pool: Array[TokenData] = []
var _deck_composition: Dictionary = {
	"bombe_count": 0,
	"fantome_count": 0,
	"maree_count": 0,
}
var _grid_modifiers: Dictionary = {}    # Vector2i -> StringName
var _rule_multipliers: Dictionary = {}  # StringName -> float
var _tag_progress: Dictionary = {}      # StringName (tag_name) -> {"cumulative": int, "level": int}


## Initialise un nouveau run : starter pack.
func init_run() -> void:
	_flies = 0

	_equipped_tags.clear()
	for path in STARTER_TAG_PATHS:
		var tag: PatternData = load(path) as PatternData
		if tag != null:
			_equipped_tags.append(tag)

	_equipped_echoes.clear()
	# DEBUG : equipe au demarrage les echoes dont debug_start_equipped == true.
	# Flag a activer dans chaque .tres via l'editeur Godot.
	for path in ShopManager.ECHO_PATHS:
		var echo: EchoData = load(path) as EchoData
		if echo != null and echo.debug_start_equipped:
			_equipped_echoes.append(echo)

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
	echoes_changed.emit(_equipped_echoes)
	deck_composition_changed.emit()


## Genere le pool de boutons de depart (famille + valeur aleatoires).
## Ce pool persiste ensuite pour toute la run, seul le shop pourra le muter
## (achat, fusion — a venir).
func _generate_starter_buttons() -> Array[TokenData]:
	var buttons: Array[TokenData] = []
	for i in range(GameRules.DECK_BASE_COUNT):
		var family: int = randi() % GameRules.FAMILY_COUNT
		var value: int = randi() % GameRules.TOKEN_MAX_VALUE + GameRules.TOKEN_MIN_VALUE
		buttons.append(TokenData.make_base(family as TokenData.Family, value))
	return buttons


## Construit un snapshot lu par les systemes.
func build_context() -> RunContext:
	var ctx: RunContext = RunContext.new()
	ctx.equipped_tags = _equipped_tags.duplicate()
	ctx.grid_modifiers = _grid_modifiers.duplicate()
	ctx.rule_multipliers = _rule_multipliers.duplicate()
	ctx.tag_level_multipliers = _build_tag_level_multipliers()
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
## Appele au start_round avant que les echoes on_round_start ne peuplent.
func reset_round_modifiers() -> void:
	_grid_modifiers.clear()
	_rule_multipliers.clear()


## Ajoute un modifier sur une cellule. Appele par les echoes.
func add_grid_modifier(cell: Vector2i, type: StringName) -> void:
	_grid_modifiers[cell] = type


## Emis une fois tous les modifiers de manche peuples (base + echoes).
func notify_grid_modifiers_ready() -> void:
	grid_modifiers_changed.emit(_grid_modifiers.duplicate())


## Pose un multiplicateur de score par rule (ex: &"family" -> 2.0). Appele par les echoes.
func set_rule_multiplier(rule: StringName, mult: float) -> void:
	_rule_multipliers[rule] = mult


func get_grid_modifiers() -> Dictionary:
	return _grid_modifiers.duplicate()


func get_rule_multipliers() -> Dictionary:
	return _rule_multipliers.duplicate()


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


# --- Echoes ---

func get_equipped_echoes() -> Array[EchoData]:
	return _equipped_echoes


func equip_echo(echo: EchoData) -> bool:
	if _equipped_echoes.size() >= GameRules.MAX_ECHO_SLOTS:
		return false
	if _equipped_echoes.has(echo):
		return false
	_equipped_echoes.append(echo)
	echoes_changed.emit(_equipped_echoes)
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


## Tire n candidats au hasard dans le pool pour la fusion, avec leur index
## d'origine (necessaire pour fuse_buttons ensuite). Ne mute rien.
func get_fusion_candidates(n: int) -> Array[Dictionary]:
	var indices: Array[int] = []
	for i in range(_button_pool.size()):
		indices.append(i)
	indices.shuffle()

	var picked: Array[Dictionary] = []
	for i in range(min(n, indices.size())):
		var idx: int = indices[i]
		picked.append({"index": idx, "token": _button_pool[idx]})
	return picked


## Fusionne 2 boutons possedes (index dans le pool, cf. get_fusion_candidates).
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
	var result_value: int = token_a.value + token_b.value

	# Retirer le plus grand index d'abord pour ne pas decaler l'autre.
	_button_pool.remove_at(max(index_a, index_b))
	_button_pool.remove_at(min(index_a, index_b))
	_button_pool.append(TokenData.make_base(result_family, result_value))

	button_pool_changed.emit()
	return true


func get_deck_composition() -> Dictionary:
	return _deck_composition.duplicate()


func add_special(type: TokenData.SpecialType) -> void:
	_increment_special_count(type)
	deck_composition_changed.emit()


## One-shot : les specials sont consommes a chaque manche, les compteurs sont
## remis a zero apres le round. Les specials avec debug_always_in_deck == true
## sont re-ajoutes pour le round suivant.
func reset_specials_counts() -> void:
	for key in _deck_composition.keys():
		_deck_composition[key] = 0
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
