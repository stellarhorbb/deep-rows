## Gere le catalogue d'items et les transactions. Source de verite sur ce qui
## est achetable, pas quand. L'ouverture/fermeture est decidee par GameScene.
class_name ShopManager
extends Node

signal purchased(item: Resource)
signal purchase_failed(item: Resource)

## Tags achetables (PatternData avec label + price).
const TAG_PATHS: Array[String] = [
	"res://resources/patterns/line_family_3_diagonal.tres",
	"res://resources/patterns/line_number_4_horizontal.tres",
	"res://resources/patterns/square_family.tres",
	"res://resources/patterns/square_number.tres",
	"res://resources/patterns/diamond_rock.tres",
	"res://resources/patterns/suite_3_diagonal.tres",
]

## Speciaux achetables (ShopItem).
const SPECIAL_PATHS: Array[String] = [
	"res://resources/specials/special_fantome.tres",
	"res://resources/specials/special_maree.tres",
]

## Catalogue unifie : contient des PatternData et des ShopItem.
var _catalog: Array[Resource] = []


func _ready() -> void:
	_load_catalog()


func _load_catalog() -> void:
	_catalog.clear()
	for path in TAG_PATHS:
		var tag: PatternData = load(path) as PatternData
		if tag != null:
			_catalog.append(tag)
	for path in SPECIAL_PATHS:
		var item: ShopItem = load(path) as ShopItem
		if item != null:
			_catalog.append(item)


func get_catalog() -> Array[Resource]:
	return _catalog


## Retourne le label d'un item (PatternData ou ShopItem).
static func get_label(item: Resource) -> String:
	if item is PatternData:
		return (item as PatternData).label
	if item is ShopItem:
		return (item as ShopItem).label
	return ""


## Retourne le prix d'un item (PatternData ou ShopItem).
static func get_price(item: Resource) -> int:
	if item is PatternData:
		return (item as PatternData).price
	if item is ShopItem:
		return (item as ShopItem).price
	return 0


## Retourne true si le joueur peut acheter (mouches + slots dispo).
func can_purchase(item: Resource, run_manager: RunManager) -> bool:
	if run_manager.get_flies() < get_price(item):
		return false
	if item is PatternData:
		var equipped: Array[PatternData] = run_manager.get_equipped_tags()
		if equipped.size() >= GameRules.MAX_PATTERN_SLOTS:
			return false
		if equipped.has(item):
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
	elif item is ShopItem:
		run_manager.add_special((item as ShopItem).special_type)

	purchased.emit(item)
	return true
