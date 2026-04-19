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

## Chemins des tags du starter pack (valable pour le proto).
## Plus tard : vient du pack de base choisi par le joueur.
const STARTER_TAG_PATHS: Array[String] = [
	"res://resources/patterns/line_family_4.tres",
	"res://resources/patterns/line_number_3.tres",
]

var _flies: int = 0
var _equipped_tags: Array[PatternData] = []
var _equipped_echoes: Array[EchoData] = []
var _deck_composition: Dictionary = {
	"bombe_count": 0,
	"fantome_count": 0,
	"maree_count": 0,
}
var _grid_modifiers: Dictionary = {}    # Vector2i -> StringName
var _rule_multipliers: Dictionary = {}  # StringName -> float


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

	_deck_composition = {
		"bombe_count": 1,
		"fantome_count": 0,
		"maree_count": 0,
	}

	flies_changed.emit(_flies)
	tags_changed.emit(_equipped_tags)
	echoes_changed.emit(_equipped_echoes)
	deck_composition_changed.emit()


## Construit un snapshot lu par les systemes.
func build_context() -> RunContext:
	var ctx: RunContext = RunContext.new()
	ctx.equipped_tags = _equipped_tags.duplicate()
	ctx.grid_modifiers = _grid_modifiers.duplicate()
	ctx.rule_multipliers = _rule_multipliers.duplicate()
	return ctx


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

func get_deck_composition() -> Dictionary:
	return _deck_composition.duplicate()


func add_special(type: TokenData.SpecialType) -> void:
	match type:
		TokenData.SpecialType.BOMBE:
			_deck_composition["bombe_count"] += 1
		TokenData.SpecialType.FANTOME:
			_deck_composition["fantome_count"] += 1
		TokenData.SpecialType.MAREE:
			_deck_composition["maree_count"] += 1
		_:
			return
	deck_composition_changed.emit()
