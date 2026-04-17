## Gere le catalogue d'items et les transactions. Source de verite sur ce qui
## est achetable, pas quand. L'ouverture/fermeture est decidee par GameScene.
class_name ShopManager
extends Node

signal purchased(item: ShopItem)
signal purchase_failed(item: ShopItem)

## Chemins du catalogue (V1 : hardcode, plus tard : dependant de la zone).
const CATALOG_PATHS: Array[String] = [
	# Tags (ordres de prix croissants)
	"res://resources/shop/tags/tag_line_family_3_diagonal.tres",
	"res://resources/shop/tags/tag_line_number_4_horizontal.tres",
	"res://resources/shop/tags/tag_square_family.tres",
	"res://resources/shop/tags/tag_square_number.tres",
	"res://resources/shop/tags/tag_diamond_rock.tres",
	"res://resources/shop/tags/tag_suite_3_diagonal.tres",
	# Speciaux
	"res://resources/shop/specials/special_fantome.tres",
	"res://resources/shop/specials/special_maree.tres",
]

var _catalog: Array[ShopItem] = []


func _ready() -> void:
	_load_catalog()


func _load_catalog() -> void:
	_catalog.clear()
	for path in CATALOG_PATHS:
		var item: ShopItem = load(path) as ShopItem
		if item != null:
			_catalog.append(item)


func get_catalog() -> Array[ShopItem]:
	return _catalog


## Retourne true si le joueur peut acheter (mouches + slots dispo).
func can_purchase(item: ShopItem, run_manager: RunManager) -> bool:
	if run_manager.get_flies() < item.price:
		return false
	if item.item_type == ShopItem.ItemType.TAG:
		var equipped: Array[PatternData] = run_manager.get_equipped_tags()
		if equipped.size() >= GameRules.MAX_PATTERN_SLOTS:
			return false
		if equipped.has(item.tag_data):
			return false
	return true


## Tente l'achat. Mute le RunManager si succes.
func purchase(item: ShopItem, run_manager: RunManager) -> bool:
	if not can_purchase(item, run_manager):
		purchase_failed.emit(item)
		return false

	if not run_manager.spend_flies(item.price):
		purchase_failed.emit(item)
		return false

	match item.item_type:
		ShopItem.ItemType.TAG:
			run_manager.equip_tag(item.tag_data)
		ShopItem.ItemType.SPECIAL:
			run_manager.add_special(item.special_type)

	purchased.emit(item)
	return true
