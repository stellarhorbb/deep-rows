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
	"res://resources/patterns/line_family_4.tres",
	"res://resources/patterns/line_number_3.tres",
]

## Speciaux achetables (SpecialItem).
const SPECIAL_PATHS: Array[String] = [
	"res://resources/specials/special_bombe.tres",
	"res://resources/specials/special_fantome.tres",
	"res://resources/specials/special_maree.tres",
]

## Badges achetables (BadgeData).
const BADGE_PATHS: Array[String] = [
	"res://resources/badges/badge_flies_cascade.tres",
	"res://resources/badges/badge_cell_triple.tres",
	"res://resources/badges/badge_trench.tres",
	"res://resources/badges/badge_family_unie.tres",
	"res://resources/badges/badge_cell_double.tres",
	"res://resources/badges/badge_ecume.tres",
	"res://resources/badges/badge_pourboire.tres",
	"res://resources/badges/badge_numerologie.tres",
]

## Pools complets, charges une fois. L'offre visible est une curation
## regeneree a chaque visite (regenerate_offer).
var _all_tags: Array[PatternData] = []
var _all_specials: Array[SpecialItem] = []
var _all_badges: Array[BadgeData] = []

## Offre curatee de la visite en cours (colonne A / colonne B).
var _tag_badge_offer: Array[Resource] = []
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

	_all_badges.clear()
	for path in BADGE_PATHS:
		var badge: BadgeData = load(path) as BadgeData
		if badge != null:
			_all_badges.append(badge)


## A appeler a chaque ouverture du shop (une nouvelle visite = une nouvelle offre).
## Colonne A : Partitions + Badges melanges, hors items deja possedes.
## Colonne B : boutons unitaires + speciaux, tires au hasard dans le pool complet.
func regenerate_offer(run_manager: RunManager) -> void:
	var equipped_tags: Array[PatternData] = run_manager.get_equipped_tags()
	var equipped_badges: Array[BadgeData] = run_manager.get_equipped_badges()

	var tag_badge_pool: Array[Resource] = []
	for tag in _all_tags:
		if not equipped_tags.has(tag):
			tag_badge_pool.append(tag)
	for badge in _all_badges:
		if not equipped_badges.has(badge):
			tag_badge_pool.append(badge)
	tag_badge_pool.shuffle()
	_tag_badge_offer = tag_badge_pool.slice(0, min(GameRules.SHOP_TAG_BADGE_OFFER_COUNT, tag_badge_pool.size()))

	var specials_pool: Array[SpecialItem] = _all_specials.duplicate()
	specials_pool.shuffle()
	_special_offer = specials_pool.slice(0, min(GameRules.SHOP_SPECIAL_OFFER_COUNT, specials_pool.size()))

	_button_offer.clear()
	for i in range(GameRules.SHOP_BUTTON_OFFER_COUNT):
		var family: int = randi() % GameRules.FAMILY_COUNT
		var value: int = randi() % GameRules.TOKEN_MAX_VALUE + GameRules.TOKEN_MIN_VALUE
		_button_offer.append(TokenData.make_base(family as TokenData.Family, value))


func get_tag_badge_offer() -> Array[Resource]:
	return _tag_badge_offer


func get_special_offer() -> Array[SpecialItem]:
	return _special_offer


func get_button_offer() -> Array[TokenData]:
	return _button_offer


## Retourne le label d'un item (PatternData, SpecialItem ou BadgeData).
static func get_label(item: Resource) -> String:
	if item is PatternData:
		return (item as PatternData).label
	if item is SpecialItem:
		return (item as SpecialItem).label
	if item is BadgeData:
		return (item as BadgeData).label
	return ""


## Retourne le texte de hover d'un item (PatternData, SpecialItem ou BadgeData).
static func get_description(item: Resource) -> String:
	if item is PatternData:
		return (item as PatternData).describe()
	if item is SpecialItem:
		return (item as SpecialItem).description
	if item is BadgeData:
		return (item as BadgeData).description
	return ""


## Retourne le prix d'un item (PatternData, SpecialItem ou BadgeData).
static func get_price(item: Resource) -> int:
	if item is PatternData:
		return (item as PatternData).price
	if item is SpecialItem:
		return (item as SpecialItem).price
	if item is BadgeData:
		return (item as BadgeData).price
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
	elif item is BadgeData:
		var equipped_badges: Array[BadgeData] = run_manager.get_equipped_badges()
		if equipped_badges.size() >= GameRules.MAX_BADGE_SLOTS:
			return false
		if equipped_badges.has(item):
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
	elif item is BadgeData:
		run_manager.equip_badge(item as BadgeData)

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
