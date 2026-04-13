class_name DeckManager
extends Node

signal deck_built(size: int)
signal stream_updated(current: TokenData, hold: TokenData, preview: Array[TokenData])

var _deck: Array[TokenData] = []
var _current: TokenData = null
var _hold: TokenData = null


func build_deck() -> void:
	_deck.clear()
	_current = null
	_hold = null

	# Jetons de base : famille aleatoire, valeur 1-5
	for i in range(GameRules.DECK_BASE_COUNT):
		var family: int = randi() % GameRules.FAMILY_COUNT
		var value: int = randi() % GameRules.TOKEN_MAX_VALUE + GameRules.TOKEN_MIN_VALUE
		_deck.append(TokenData.make_base(family as TokenData.Family, value))

	# Rocks
	for i in range(GameRules.DECK_ROCK_COUNT):
		_deck.append(TokenData.make_rock())

	# Speciaux
	for i in range(GameRules.DECK_FANTOME_COUNT):
		_deck.append(TokenData.make_special(TokenData.SpecialType.FANTOME))
	for i in range(GameRules.DECK_BOMBE_COUNT):
		_deck.append(TokenData.make_special(TokenData.SpecialType.BOMBE))
	for i in range(GameRules.DECK_MAREE_COUNT):
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
