class_name DeckManager
extends Node

signal deck_built(size: int)
signal stream_updated(current: TokenData, hold: Array[TokenData], preview: Array[TokenData])
signal shaken()

## Nombre de slots de hold pour la manche — 1 par defaut, augmentable par
## Sortilège (ex: "Benediction", +1 slot). Pose par TurnController.start_round
## juste apres build_context, avant build_deck (voir GameRules.BASE_HOLD_SLOTS).
var hold_capacity: int = GameRules.BASE_HOLD_SLOTS

## Bonus de taille de preview du stream pour la manche — 0 par defaut,
## augmentable par Sortilège (ex: "Visionnaire", +1 jeton visible). Meme timing
## que hold_capacity.
var preview_bonus: int = 0

## Bonus (ou malus) sur le nombre de rocks ajoutes au deck chaque manche —
## 0 par defaut, modifiable par un pack de demarrage (ex: "Le Collectionneur",
## +2). Meme timing que hold_capacity/preview_bonus.
var rock_count_bonus: int = 0

var _deck: Array[TokenData] = []
var _current: TokenData = null
var _hold: Array[TokenData] = []


## button_pool : pool persistant du RunManager (possede pour toute la run).
## On en cree des copies fraiches ici — consommer le deck de la manche ne doit
## jamais muter les instances possedees. Les speciaux ne font plus partie du
## deck depuis la session 25 (voir RunManager._special_inventory) : joues a
## la demande, jamais melanges dans le stream.
## `carried_over` (session 26) : jetons du haut de chaque colonne, deja
## poses sur la grille par la persistance entre manches -- ce sont deja des
## exemplaires du pool possede, pas question de leur en redonner une
## deuxieme copie jouable cette manche (voir GameScene._play_carryover_intro).
func build_deck(button_pool: Array[TokenData], carried_over: Array[TokenData] = []) -> void:
	_deck.clear()
	_current = null
	_hold.clear()
	for i in range(hold_capacity):
		_hold.append(null)

	var carried_counts: Dictionary = {}  # Vector2i(family, value) -> compte
	for token in carried_over:
		if token == null:
			continue
		var key: Vector2i = Vector2i(token.family, token.value)
		carried_counts[key] = carried_counts.get(key, 0) + 1

	# Jetons de base : copies fraiches du pool possede (persistant pour la run).
	# locked propage explicitement (make_base ne le porte pas par defaut).
	for source_token in button_pool:
		var key: Vector2i = Vector2i(source_token.family, source_token.value)
		if carried_counts.get(key, 0) > 0:
			carried_counts[key] -= 1
			continue
		var copy: TokenData = TokenData.make_base(source_token.family, source_token.value)
		copy.locked = source_token.locked
		_deck.append(copy)

	# Rocks
	for i in range(GameRules.DECK_ROCK_COUNT + rock_count_bonus):
		_deck.append(TokenData.make_rock())

	# Shuffle (Fisher-Yates)
	_shuffle()

	deck_built.emit(_deck.size())


func advance_stream() -> void:
	if _current == null and _deck.size() > 0:
		_current = _deck.pop_back()
	_emit_stream_updated()


## slot_index >= 0 (clic sur un slot precis) : stocke/echange avec CE slot.
## slot_index < 0 (touche clavier, defaut) : vise le premier slot vide, sinon
## le slot 0 — swap simple, comme avant l'ajout de slots supplementaires.
## Stocker dans un slot vide exige un current (rien a stocker sinon) ; recuperer
## depuis un slot plein doit marcher meme si current est vide (session 18 : fix
## softlock — avec 2+ slots de hold, enchainer deux holds pendant que le deck
## se vide pouvait laisser current a null avec des jetons en hold inaccessibles,
## le guard bloquant alors tout clic, y compris pour les recuperer).
func do_hold(slot_index: int = -1) -> void:
	var target: int = slot_index
	if target < 0:
		target = _first_empty_hold_slot()
		if target < 0:
			target = 0
	if target < 0 or target >= _hold.size():
		return

	if _hold[target] == null:
		if _current == null:
			return
		_hold[target] = _current
		_current = null
		advance_stream()
	else:
		var tmp: TokenData = _current
		_current = _hold[target]
		_hold[target] = tmp
		_emit_stream_updated()


func _first_empty_hold_slot() -> int:
	for i in range(_hold.size()):
		if _hold[i] == null:
			return i
	return -1


func consume_current() -> TokenData:
	var token: TokenData = _current
	_current = null
	return token


func get_current() -> TokenData:
	return _current


## Tous les slots de hold (taille = hold_capacity), certains eventuellement
## vides (null).
func get_hold_slots() -> Array[TokenData]:
	return _hold.duplicate()


## Premier jeton tenu non-vide, ou null si tous les slots sont vides. Pratique
## pour le code qui ne se soucie pas de quel slot precisement (ex: verifier
## qu'un coup legal existe encore).
func get_hold() -> TokenData:
	for h in _hold:
		if h != null:
			return h
	return null


## Malus de boss BOURRASQUE (voir TurnController.play_current_to, retune :
## vise desormais le Hold plutot que le stream) : vide le premier slot de
## hold non vide et retourne son jeton, null si le joueur ne hold rien --
## laisse alors le malus silencieux ce tour-ci plutot que de piocher un
## jeton de remplacement.
func take_first_held() -> TokenData:
	for i in range(_hold.size()):
		if _hold[i] != null:
			var token: TokenData = _hold[i]
			_hold[i] = null
			_emit_stream_updated()
			return token
	return null


func get_preview() -> Array[TokenData]:
	var preview: Array[TokenData] = []
	for i in range(GameRules.PREVIEW_SIZE + preview_bonus):
		var idx: int = _deck.size() - 1 - i
		if idx < 0:
			break
		preview.append(_deck[idx])
	return preview


func get_remaining() -> int:
	return _deck.size()


## Tous les jetons qu'il reste au joueur a jouer cette manche : pioche pas
## encore tiree + current + hold. Pour l'inspecteur de deck : comptes agreges
## uniquement, jamais l'ordre de tirage.
func get_remaining_tokens() -> Array[TokenData]:
	var tokens: Array[TokenData] = _deck.duplicate()
	if _current != null:
		tokens.append(_current)
	for h in _hold:
		if h != null:
			tokens.append(h)
	return tokens


func is_exhausted() -> bool:
	return _deck.size() == 0 and _current == null and get_hold() == null


## Si current est vide, rapatrie le premier jeton tenu non-vide (peu importe
## le slot) — meme principe qu'avant l'ajout de slots supplementaires.
func force_hold_to_current() -> void:
	if _current != null:
		return
	var slot: int = -1
	for i in range(_hold.size()):
		if _hold[i] != null:
			slot = i
			break
	if slot < 0:
		return
	_current = _hold[slot]
	_hold[slot] = null
	_emit_stream_updated()


## "Shake" (bouton d'urgence, charge limitee par run -- voir RunManager.
## spend_shake_charge) : remelange ce qui reste a jouer cette manche --
## current + pioche -- sans jamais changer la composition (get_
## remaining_tokens(), donc l'Inspecteur de deck, n'est pas affecte). Inclure
## le current est deliberement : c'est souvent lui le vrai point de blocage
## (jeton injouable en main), pas l'ordre du reste de la pioche. Le Hold reste
## intact (retire du melange en session 23, playtest : un special mis de cote
## expres s'y faisait perdre au hasard, contraire au but du slot).
func shake() -> void:
	var had_current: bool = _current != null

	var pool: Array[TokenData] = _deck.duplicate()
	if _current != null:
		pool.append(_current)
	pool.shuffle()

	_current = null
	if had_current and pool.size() > 0:
		_current = pool.pop_back()

	_deck = pool

	shaken.emit()
	_emit_stream_updated()


func _shuffle() -> void:
	for i in range(_deck.size() - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var tmp: TokenData = _deck[i]
		_deck[i] = _deck[j]
		_deck[j] = tmp


func _emit_stream_updated() -> void:
	stream_updated.emit(_current, _hold, get_preview())
