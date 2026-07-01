class_name DeckManager
extends Node

signal deck_built(size: int)
signal stream_updated(current: TokenData, hold: TokenData, preview: Array[TokenData])

var _deck: Array[TokenData] = []
var _current: TokenData = null
var _hold: TokenData = null


## button_pool : pool persistant du RunManager (possede pour toute la run).
## On en cree des copies fraiches ici — consommer le deck de la manche ne doit
## jamais muter les instances possedees.
func build_deck(composition: Dictionary, button_pool: Array[TokenData]) -> void:
	_deck.clear()
	_current = null
	_hold = null

	# Jetons de base : copies fraiches du pool possede (persistant pour la run)
	for source_token in button_pool:
		_deck.append(TokenData.make_base(source_token.family, source_token.value))

	# Rocks
	for i in range(GameRules.DECK_ROCK_COUNT):
		_deck.append(TokenData.make_rock())

	# Speciaux issus de la composition du run
	var bombe_count: int = composition.get("bombe_count", 0) as int
	var fantome_count: int = composition.get("fantome_count", 0) as int
	var maree_count: int = composition.get("maree_count", 0) as int

	for i in range(bombe_count):
		_deck.append(TokenData.make_special(TokenData.SpecialType.BOMBE))
	for i in range(fantome_count):
		_deck.append(TokenData.make_special(TokenData.SpecialType.FANTOME))
	for i in range(maree_count):
		_deck.append(TokenData.make_special(TokenData.SpecialType.MAREE))

	# Shuffle (Fisher-Yates)
	_shuffle()

	deck_built.emit(_deck.size())


func advance_stream() -> void:
	if _current == null and _deck.size() > 0:
		_current = _deck.pop_back()
	_emit_stream_updated()


func do_hold() -> void:
	if _current == null:
		return
	if _hold == null:
		_hold = _current
		_current = null
		advance_stream()
	else:
		var tmp: TokenData = _current
		_current = _hold
		_hold = tmp
		_emit_stream_updated()


func consume_current() -> TokenData:
	var token: TokenData = _current
	_current = null
	return token


func get_current() -> TokenData:
	return _current


func get_hold() -> TokenData:
	return _hold


func get_preview() -> Array[TokenData]:
	var preview: Array[TokenData] = []
	for i in range(GameRules.PREVIEW_SIZE):
		var idx: int = _deck.size() - 1 - i
		if idx < 0:
			break
		preview.append(_deck[idx])
	return preview


func get_remaining() -> int:
	return _deck.size()


## Jetons pas encore tires (hors current/hold, deja reveles). Pour l'inspecteur
## de deck : comptes agreges uniquement, jamais l'ordre de tirage.
func get_remaining_tokens() -> Array[TokenData]:
	return _deck.duplicate()


func is_exhausted() -> bool:
	return _deck.size() == 0 and _current == null and _hold == null


func force_hold_to_current() -> void:
	if _current == null and _hold != null:
		_current = _hold
		_hold = null
		_emit_stream_updated()


func _shuffle() -> void:
	for i in range(_deck.size() - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var tmp: TokenData = _deck[i]
		_deck[i] = _deck[j]
		_deck[j] = tmp


func _emit_stream_updated() -> void:
	stream_updated.emit(_current, _hold, get_preview())
