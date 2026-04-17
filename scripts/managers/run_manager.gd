## Porte les donnees qui evoluent au cours d'un run (tags equipes, deck,
## mouches, plus tard echoes/states/niveaux). Mute uniquement par l'orchestration
## (TurnController, ShopManager a venir). Les autres lisent via build_context().
class_name RunManager
extends Node

signal flies_changed(amount: int)
signal tags_changed(equipped: Array[PatternData])
signal deck_composition_changed()

## Chemins des tags du starter pack (valable pour le proto).
## Plus tard : vient du pack de base choisi par le joueur.
const STARTER_TAG_PATHS: Array[String] = [
	"res://resources/patterns/line_family_4.tres",
	"res://resources/patterns/line_number_3.tres",
]

var _flies: int = 0
var _equipped_tags: Array[PatternData] = []
var _deck_composition: Dictionary = {
	"bombe_count": 0,
	"fantome_count": 0,
	"maree_count": 0,
}


## Initialise un nouveau run : starter pack.
func init_run() -> void:
	_flies = 0

	_equipped_tags.clear()
	for path in STARTER_TAG_PATHS:
		var tag: PatternData = load(path) as PatternData
		if tag != null:
			_equipped_tags.append(tag)

	_deck_composition = {
		"bombe_count": 1,
		"fantome_count": 0,
		"maree_count": 0,
	}

	flies_changed.emit(_flies)
	tags_changed.emit(_equipped_tags)
	deck_composition_changed.emit()


## Construit un snapshot lu par les systemes.
func build_context() -> RunContext:
	var ctx: RunContext = RunContext.new()
	ctx.equipped_tags = _equipped_tags.duplicate()
	return ctx


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
