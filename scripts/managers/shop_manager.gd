## Gere le catalogue d'items et les transactions. Source de verite sur ce qui
## est achetable, pas quand. L'ouverture/fermeture est decidee par GameScene.
class_name ShopManager
extends Node

signal purchased(item: Resource)
signal purchase_failed(item: Resource)
signal button_purchased(token: TokenData)

## Tags achetables (PatternData avec label + price).
const TAG_PATHS: Array[String] = [
	"res://resources/patterns/line_family_3_diagonal.tres",
	"res://resources/patterns/line_number_4_horizontal.tres",
	"res://resources/patterns/square_family.tres",
	"res://resources/patterns/square_number.tres",
	"res://resources/patterns/diamond_rock.tres",
	"res://resources/patterns/suite_3_diagonal.tres",
]

## Speciaux achetables (SpecialItem).
const SPECIAL_PATHS: Array[String] = [
	"res://resources/specials/special_bombe.tres",
	"res://resources/specials/special_fantome.tres",
	"res://resources/specials/special_maree.tres",
]

## Echoes achetables (EchoData).
const ECHO_PATHS: Array[String] = [
	"res://resources/echoes/echo_flies_cascade.tres",
	"res://resources/echoes/echo_cell_triple.tres",
	"res://resources/echoes/echo_trench.tres",
	"res://resources/echoes/echo_family_unie.tres",
]

## Pools complets, charges une fois. L'offre visible est une curation
## regeneree a chaque visite (regenerate_offer).
var _all_tags: Array[PatternData] = []
var _all_specials: Array[SpecialItem] = []
var _all_echoes: Array[EchoData] = []

## Offre curatee de la visite en cours (colonne A / colonne B).
var _tag_echo_offer: Array[Resource] = []
var _special_offer: Array[SpecialItem] = []
var _button_offer: Array[TokenData] = []


func _ready() -> void:
	_load_pools()


func _load_pools() -> void:
	_all_tags.clear()
	for path in TAG_PATHS:
		var tag: PatternData = load(path) as PatternData
		if tag != null:
			_all_tags.append(tag)

	_all_specials.clear()
	for path in SPECIAL_PATHS:
		var item: SpecialItem = load(path) as SpecialItem
		if item != null:
			_all_specials.append(item)

	_all_echoes.clear()
	for path in ECHO_PATHS:
		var echo: EchoData = load(path) as EchoData
		if echo != null:
			_all_echoes.append(echo)


## A appeler a chaque ouverture du shop (une nouvelle visite = une nouvelle offre).
## Colonne A : Partitions + Echoes melanges, hors items deja possedes.
## Colonne B : boutons unitaires + speciaux, tires au hasard dans le pool complet.
func regenerate_offer(run_manager: RunManager) -> void:
	var equipped_tags: Array[PatternData] = run_manager.get_equipped_tags()
	var equipped_echoes: Array[EchoData] = run_manager.get_equipped_echoes()

	var tag_echo_pool: Array[Resource] = []
	for tag in _all_tags:
		if not equipped_tags.has(tag):
			tag_echo_pool.append(tag)
	for echo in _all_echoes:
		if not equipped_echoes.has(echo):
			tag_echo_pool.append(echo)
	tag_echo_pool.shuffle()
	_tag_echo_offer = tag_echo_pool.slice(0, min(GameRules.SHOP_TAG_ECHO_OFFER_COUNT, tag_echo_pool.size()))

	var specials_pool: Array[SpecialItem] = _all_specials.duplicate()
	specials_pool.shuffle()
	_special_offer = specials_pool.slice(0, min(GameRules.SHOP_SPECIAL_OFFER_COUNT, specials_pool.size()))

	_button_offer.clear()
	for i in range(GameRules.SHOP_BUTTON_OFFER_COUNT):
		var family: int = randi() % GameRules.FAMILY_COUNT
		var value: int = randi() % GameRules.TOKEN_MAX_VALUE + GameRules.TOKEN_MIN_VALUE
		_button_offer.append(TokenData.make_base(family as TokenData.Family, value))


func get_tag_echo_offer() -> Array[Resource]:
	return _tag_echo_offer


func get_special_offer() -> Array[SpecialItem]:
	return _special_offer


func get_button_offer() -> Array[TokenData]:
	return _button_offer


## Retourne le label d'un item (PatternData, SpecialItem ou EchoData).
static func get_label(item: Resource) -> String:
	if item is PatternData:
		return (item as PatternData).label
	if item is SpecialItem:
		return (item as SpecialItem).label
	if item is EchoData:
		return (item as EchoData).label
	return ""


## Retourne le texte de hover d'un item (PatternData, SpecialItem ou EchoData).
static func get_description(item: Resource) -> String:
	if item is PatternData:
		return (item as PatternData).describe()
	if item is SpecialItem:
		return (item as SpecialItem).description
	if item is EchoData:
		return (item as EchoData).description
	return ""


## Retourne le prix d'un item (PatternData, SpecialItem ou EchoData).
static func get_price(item: Resource) -> int:
	if item is PatternData:
		return (item as PatternData).price
	if item is SpecialItem:
		return (item as SpecialItem).price
	if item is EchoData:
		return (item as EchoData).price
	return 0


## Retourne true si le joueur peut acheter (mouches + slots dispo).
func can_purchase(item: Resource, run_manager: RunManager) -> bool:
	if run_manager.get_flies() < get_price(item):
		return false
	if item is PatternData:
		var equipped_tags: Array[PatternData] = run_manager.get_equipped_tags()
		if equipped_tags.size() >= GameRules.MAX_PATTERN_SLOTS:
			return false
		if equipped_tags.has(item):
			return false
	elif item is EchoData:
		var equipped_echoes: Array[EchoData] = run_manager.get_equipped_echoes()
		if equipped_echoes.size() >= GameRules.MAX_ECHO_SLOTS:
			return false
		if equipped_echoes.has(item):
			return false
	return true


## Tente l'achat. Mute le RunManager si succes.
func purchase(item: Resource, run_manager: RunManager) -> bool:
	if not can_purchase(item, run_manager):
		purchase_failed.emit(item)
		return false

	if not run_manager.spend_flies(get_price(item)):
		purchase_failed.emit(item)
		return false

	if item is PatternData:
		run_manager.equip_tag(item as PatternData)
	elif item is SpecialItem:
		run_manager.add_special((item as SpecialItem).special_type)
	elif item is EchoData:
		run_manager.equip_echo(item as EchoData)

	purchased.emit(item)
	return true


## Achat d'un bouton unitaire (TokenData n'est pas une Resource, circuit separe).
func can_purchase_button(run_manager: RunManager) -> bool:
	return run_manager.get_flies() >= GameRules.BUTTON_UNIT_PRICE


func purchase_button(token: TokenData, run_manager: RunManager) -> bool:
	if not can_purchase_button(run_manager):
		return false
	if not run_manager.spend_flies(GameRules.BUTTON_UNIT_PRICE):
		return false
	run_manager.add_button(token.family, token.value)
	button_purchased.emit(token)
	return true
