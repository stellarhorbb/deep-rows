## Gere le catalogue d'items et les transactions. Source de verite sur ce qui
## est achetable, pas quand. L'ouverture/fermeture est decidee par GameScene.
##
## v2 : deux rangees separees a la Balatro — Packs (nombre fixe, categorie
## aleatoire, jamais regeneres par le reroll) et Unitaires visibles (nombre
## fixe, regeneres a chaque reroll). Voir regenerate_offer/reroll_unitaires.
class_name ShopManager
extends Node

signal purchased(item: Resource)
signal purchase_failed(item: Resource)
signal button_purchased(token: TokenData)

## Tags achetables (PatternData avec label + price).
## Tags valeur/suite retires du catalogue actif : la valeur ne resout plus de
## patterns, seule la famille (et rock) compte — la valeur reste un levier de
## score pur (voir GameRules.MAX_BUTTON_VALUE). Les .tres restent sur le
## disque au cas ou ces regles reviennent plus tard (Shore, contenu rare...).
const TAG_PATHS: Array[String] = [
	"res://resources/patterns/line_family_3_diagonal.tres",
	# "res://resources/patterns/line_number_4_horizontal.tres",
	"res://resources/patterns/square_family.tres",
	# "res://resources/patterns/square_number.tres",
	"res://resources/patterns/diamond_rock.tres",
	# "res://resources/patterns/suite_3_diagonal.tres",
	"res://resources/patterns/line_family_4.tres",
	# "res://resources/patterns/line_number_3.tres",
	"res://resources/patterns/line_family_5.tres",
	"res://resources/patterns/diamond_family.tres",
]

## Speciaux achetables (SpecialItem).
const SPECIAL_PATHS: Array[String] = [
	"res://resources/specials/special_bombe.tres",
	"res://resources/specials/special_fantome.tres",
	"res://resources/specials/special_maree.tres",
]

## Badges achetables (BadgeData).
## Numerologie retire du catalogue actif : boost la rule "value", plus aucun
## Tag ne l'utilise (voir TAG_PATHS ci-dessus).
const BADGE_PATHS: Array[String] = [
	"res://resources/badges/badge_flies_cascade.tres",
	"res://resources/badges/badge_cell_triple.tres",
	"res://resources/badges/badge_trench.tres",
	"res://resources/badges/badge_family_unie.tres",
	"res://resources/badges/badge_cell_double.tres",
	"res://resources/badges/badge_ecume.tres",
	"res://resources/badges/badge_pourboire.tres",
	# "res://resources/badges/badge_numerologie.tres",
	"res://resources/badges/badge_collectionneur.tres",
	"res://resources/badges/badge_vertige.tres",
	"res://resources/badges/badge_colonne_chanceuse.tres",
]

## Categories tirables pour un pack (pas de "pack de Des a coudre" — ce n'est
## pas un tirage-et-choix-1, juste un deblocage d'action).
const PACK_CATEGORIES: Array[String] = ["tag", "badge", "special", "button"]

## Categories tirables pour un slot unitaire (visible directement).
const UNITAIRE_CATEGORIES: Array[String] = ["tag", "badge", "special", "button", "des_a_coudre"]

## Pools complets, charges une fois. L'offre visible est une curation
## regeneree a chaque visite (regenerate_offer).
var _all_tags: Array[PatternData] = []
var _all_specials: Array[SpecialItem] = []
var _all_badges: Array[BadgeData] = []

## Deux rangees separees. Formats possibles pour un slot (Dictionary) :
##   {"format": "unitaire", "category": String, "item": Resource|TokenData}
##   {"format": "pack", "category": String, "size": int, "price": int}
##   {"format": "des_a_coudre", "price": int}
var _pack_slots: Array[Dictionary] = []
var _unitaire_slots: Array[Dictionary] = []


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


## A appeler a l'ouverture du shop. Regenere les DEUX rangees.
func regenerate_offer(run_manager: RunManager) -> void:
	_regenerate_packs(run_manager)
	_regenerate_unitaires(run_manager)


## A appeler au reroll : les packs restent fixes pour toute la visite (comme
## Balatro), seule la rangee des unitaires visibles est regeneree.
func reroll_unitaires(run_manager: RunManager) -> void:
	_regenerate_unitaires(run_manager)


func _regenerate_packs(run_manager: RunManager) -> void:
	_pack_slots.clear()
	for i in range(GameRules.SHOP_PACK_SLOT_COUNT):
		var category: String = PACK_CATEGORIES[randi() % PACK_CATEGORIES.size()]
		_pack_slots.append({
			"format": "pack",
			"category": category,
			"size": GameRules.PACK_SIZE_BUTTON if category == "button" else GameRules.PACK_SIZE_DEFAULT,
			"price": _pack_price(category),
		})


func _regenerate_unitaires(run_manager: RunManager) -> void:
	_unitaire_slots.clear()
	for i in range(GameRules.SHOP_UNITAIRE_SLOT_COUNT):
		var category: String = UNITAIRE_CATEGORIES[randi() % UNITAIRE_CATEGORIES.size()]
		var slot: Dictionary = _build_unitaire_slot(category, run_manager)
		if not slot.is_empty():
			_unitaire_slots.append(slot)


func _build_unitaire_slot(category: String, run_manager: RunManager) -> Dictionary:
	if category == "des_a_coudre":
		return {"format": "des_a_coudre", "price": GameRules.DES_A_COUDRE_PRICE}

	var item: Variant = _draw_unitaire(category, run_manager)
	if item == null:
		return {}
	return {"format": "unitaire", "category": category, "item": item}


func _pack_price(category: String) -> int:
	match category:
		"tag": return GameRules.PACK_PRICE_TAG
		"badge": return GameRules.PACK_PRICE_BADGE
		"special": return GameRules.PACK_PRICE_SPECIAL
		"button": return GameRules.PACK_PRICE_BUTTON
	return 0


func _draw_unitaire(category: String, run_manager: RunManager) -> Variant:
	match category:
		"tag":
			var pool: Array[PatternData] = _available_tags(run_manager)
			return pool[randi() % pool.size()] if not pool.is_empty() else null
		"badge":
			var pool: Array[BadgeData] = _available_badges(run_manager)
			return pool[randi() % pool.size()] if not pool.is_empty() else null
		"special":
			return _all_specials[randi() % _all_specials.size()] if not _all_specials.is_empty() else null
		"button":
			return _random_button()
	return null


func _available_tags(run_manager: RunManager) -> Array[PatternData]:
	var equipped: Array[PatternData] = run_manager.get_equipped_tags()
	var pool: Array[PatternData] = []
	for tag in _all_tags:
		if not equipped.has(tag):
			pool.append(tag)
	return pool


func _available_badges(run_manager: RunManager) -> Array[BadgeData]:
	var equipped: Array[BadgeData] = run_manager.get_equipped_badges()
	var pool: Array[BadgeData] = []
	for badge in _all_badges:
		if not equipped.has(badge):
			pool.append(badge)
	return pool


func _random_button() -> TokenData:
	var family: int = randi() % GameRules.FAMILY_COUNT
	var value: int = randi() % GameRules.TOKEN_MAX_VALUE + GameRules.TOKEN_MIN_VALUE
	return TokenData.make_base(family as TokenData.Family, value)


func get_pack_slots() -> Array[Dictionary]:
	return _pack_slots


func get_unitaire_slots() -> Array[Dictionary]:
	return _unitaire_slots


## Retourne le label d'un item (PatternData, SpecialItem, BadgeData ou TokenData).
static func get_label(item: Variant) -> String:
	if item is PatternData:
		return (item as PatternData).label
	if item is SpecialItem:
		return (item as SpecialItem).label
	if item is BadgeData:
		return (item as BadgeData).label
	if item is TokenData:
		var token: TokenData = item as TokenData
		return "%s %d" % [TokenData.family_label(token.family), token.value]
	return ""


## Retourne le texte de hover d'un item.
static func get_description(item: Variant) -> String:
	if item is PatternData:
		return (item as PatternData).describe()
	if item is SpecialItem:
		return (item as SpecialItem).description
	if item is BadgeData:
		return (item as BadgeData).description
	return ""


## Retourne le prix unitaire d'un item.
static func get_price(item: Variant) -> int:
	if item is PatternData:
		return (item as PatternData).price
	if item is SpecialItem:
		return (item as SpecialItem).price
	if item is BadgeData:
		return (item as BadgeData).price
	if item is TokenData:
		return GameRules.BUTTON_UNIT_PRICE
	return 0


## Retourne true si le joueur peut acheter (mouches + slots dispo).
func can_purchase(item: Variant, run_manager: RunManager) -> bool:
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


## Tente l'achat unitaire. Mute le RunManager si succes.
func purchase(item: Variant, run_manager: RunManager) -> bool:
	if not can_purchase(item, run_manager):
		purchase_failed.emit(item)
		return false

	if not run_manager.spend_flies(get_price(item)):
		purchase_failed.emit(item)
		return false

	_apply_item(item, run_manager)
	if item is TokenData:
		button_purchased.emit(item)
	else:
		purchased.emit(item)
	return true


func _apply_item(item: Variant, run_manager: RunManager) -> void:
	if item is PatternData:
		run_manager.equip_tag(item as PatternData)
	elif item is SpecialItem:
		run_manager.add_special((item as SpecialItem).special_type)
	elif item is BadgeData:
		run_manager.equip_badge(item as BadgeData)
	elif item is TokenData:
		var token: TokenData = item as TokenData
		run_manager.add_button(token.family, token.value)


## --- Packs (achat a l'aveugle) ---

func can_purchase_pack(slot: Dictionary, run_manager: RunManager) -> bool:
	return run_manager.get_flies() >= (slot["price"] as int)


## Debite le prix du pack. Ne tire PAS encore les candidats (voir open_pack) —
## deux etapes distinctes pour matcher les "3 paliers de gratification"
## du GDD (voir le pack, l'ouvrir, choisir).
func purchase_pack(slot: Dictionary, run_manager: RunManager) -> bool:
	if not can_purchase_pack(slot, run_manager):
		return false
	return run_manager.spend_flies(slot["price"] as int)


## Tire les candidats d'un pack deja achete. Ne mute rien d'autre.
func open_pack(slot: Dictionary, run_manager: RunManager) -> Array:
	var category: String = slot["category"] as String
	var size: int = slot["size"] as int
	match category:
		"tag":
			var pool: Array[PatternData] = _available_tags(run_manager)
			pool.shuffle()
			return pool.slice(0, min(size, pool.size()))
		"badge":
			var pool: Array[BadgeData] = _available_badges(run_manager)
			pool.shuffle()
			return pool.slice(0, min(size, pool.size()))
		"special":
			var pool: Array[SpecialItem] = _all_specials.duplicate()
			pool.shuffle()
			return pool.slice(0, min(size, pool.size()))
		"button":
			var pool: Array[TokenData] = []
			for i in range(size):
				pool.append(_random_button())
			return pool
	return []


## Applique le choix du joueur dans un pack ouvert (deja paye a l'achat du pack).
func choose_from_pack(item: Variant, run_manager: RunManager) -> void:
	_apply_item(item, run_manager)
	if item is TokenData:
		button_purchased.emit(item)
	else:
		purchased.emit(item)


## --- Des a coudre (gate la fusion) ---

func can_purchase_des_a_coudre(run_manager: RunManager) -> bool:
	return run_manager.get_flies() >= GameRules.DES_A_COUDRE_PRICE


func purchase_des_a_coudre(run_manager: RunManager) -> bool:
	if not can_purchase_des_a_coudre(run_manager):
		return false
	return run_manager.spend_flies(GameRules.DES_A_COUDRE_PRICE)
