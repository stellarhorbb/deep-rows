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

## Sheets achetables (SheetData avec label + price).
## square_number.tres reste hors catalogue : l'axe chiffre (session 14) est
## volontairement confine a la Ligne, jamais au Carre (voir axes-de-regles.md).
const SHEET_PATHS: Array[String] = [
	"res://resources/sheets/line_family_3.tres",
	"res://resources/sheets/square_family.tres",
	# "res://resources/sheets/square_number.tres",
	"res://resources/sheets/diamond_rock.tres",
	"res://resources/sheets/line_family_4.tres",
	"res://resources/sheets/line_family_5.tres",
	"res://resources/sheets/diamond_family.tres",
	"res://resources/sheets/plus_family.tres",
	"res://resources/sheets/cross_family.tres",
	"res://resources/sheets/ring_family.tres",
	"res://resources/sheets/t_family.tres",
	"res://resources/sheets/square_rainbow.tres",
	"res://resources/sheets/diamond_rainbow.tres",
	"res://resources/sheets/line_4_rainbow.tres",
	"res://resources/sheets/suite.tres",
	"res://resources/sheets/brelan.tres",
	"res://resources/sheets/carre_poker.tres",
	"res://resources/sheets/fibonacci.tres",
	"res://resources/sheets/minima.tres",
	"res://resources/sheets/maxima.tres",
	"res://resources/sheets/prime.tres",
]

## Petit pool a part (session 20) — jamais dans SHEET_PATHS/le tirage uniforme
## normal. Chaque slot "sheet" (unitaire ou candidat de pack) a une chance
## independante (GameRules.LEGENDARY_SHEET_CHANCE) de piocher ici plutot que
## dans le pool normal. Voir SheetData.is_legendary et _draw_sheet_candidate.
const LEGENDARY_SHEET_PATHS: Array[String] = [
	"res://resources/sheets/legendary_lost_corners.tres",
	"res://resources/sheets/legendary_royal_square.tres",
	"res://resources/sheets/legendary_last_trick.tres",
]

## Speciaux achetables (SpecialItem).
const SPECIAL_PATHS: Array[String] = [
	"res://resources/specials/special_bombe.tres",
	"res://resources/specials/special_fantome.tres",
	"res://resources/specials/special_maree.tres",
]

## Badges achetables (BadgeData).
## Numerologie retire du catalogue actif : boost la rule "value", plus aucun
## Sheet ne l.utilise (voir SHEET_PATHS ci-dessus).
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
	"res://resources/badges/badge_bord_a_bord.tres",
	"res://resources/badges/badge_un_pour_tous.tres",
	"res://resources/badges/badge_regularite.tres",
	"res://resources/badges/badge_dernier_carre.tres",
	"res://resources/badges/badge_petites_mains.tres",
	"res://resources/badges/badge_vingt_trois.tres",
	"res://resources/badges/badge_saint_pair.tres",
	"res://resources/badges/badge_impair_profane.tres",
	"res://resources/badges/badge_yen_a_pas_deux.tres",
	"res://resources/badges/badge_sommet.tres",
	"res://resources/badges/badge_tickets_hivernal.tres",
	"res://resources/badges/badge_tickets_automnal.tres",
	"res://resources/badges/badge_tickets_estival.tres",
	"res://resources/badges/badge_tickets_printanier.tres",
	"res://resources/badges/badge_jetons_sacres.tres",
	"res://resources/badges/badge_quatre_quart.tres",
	"res://resources/badges/badge_poker_face.tres",
	"res://resources/badges/badge_mouche_cubique.tres",
	"res://resources/badges/badge_visionnaire.tres",
	"res://resources/badges/badge_benediction.tres",
	"res://resources/badges/badge_recif_vivant.tres",
	"res://resources/badges/badge_mouche_doree.tres",
	"res://resources/badges/badge_mouche_melomane.tres",
	"res://resources/badges/badge_escalade_musicale.tres",
	"res://resources/badges/badge_amelioration_continue.tres",
	"res://resources/badges/badge_gourmand.tres",
	"res://resources/badges/badge_econome.tres",
]

## Outils de deck achetables (DeckToolData) — voir docs/brainstorms/brainstorm-outils-deck.md.
## Duplication et jeton arc-en-ciel volontairement absents (tier Epic vide,
## mis de cote pour plus tard).
const DECK_TOOL_PATHS: Array[String] = [
	"res://resources/deck_tools/increase.tres",
	"res://resources/deck_tools/decrease.tres",
	"res://resources/deck_tools/change_batons.tres",
	"res://resources/deck_tools/change_coupes.tres",
	"res://resources/deck_tools/change_epees.tres",
	"res://resources/deck_tools/change_deniers.tres",
	"res://resources/deck_tools/split.tres",
	"res://resources/deck_tools/fuse.tres",
	"res://resources/deck_tools/remove.tres",
	"res://resources/deck_tools/fix_figure.tres",
]

## Categories tirables pour un pack (pas de "pack de Des a coudre" — le
## Des a coudre a deja son propre tirage-et-choix-1 sur les outils de deck,
## voir draw_deck_tool_choices).
const PACK_CATEGORIES: Array[String] = ["sheet", "badge", "special", "button"]

## Categories tirables pour un slot unitaire (visible directement).
const UNITAIRE_CATEGORIES: Array[String] = ["sheet", "badge", "special", "button", "des_a_coudre"]

## Pools complets, charges une fois. L'offre visible est une curation
## regeneree a chaque visite (regenerate_offer).
var _all_sheets: Array[SheetData] = []
var _all_legendary_sheets: Array[SheetData] = []
var _all_specials: Array[SpecialItem] = []
var _all_badges: Array[BadgeData] = []
var _all_deck_tools: Array[DeckToolData] = []

## Deux rangees separees. Formats possibles pour un slot (Dictionary) :
##   {"format": "unitaire", "category": String, "item": Resource|TokenData}
##   {"format": "pack", "category": String, "size": int, "price": int}
##   {"format": "des_a_coudre", "price": int}
var _pack_slots: Array[Dictionary] = []
var _unitaire_slots: Array[Dictionary] = []


func _ready() -> void:
	_load_pools()


func _load_pools() -> void:
	_all_sheets.clear()
	for path in SHEET_PATHS:
		var sheet: SheetData = load(path) as SheetData
		if sheet != null:
			_all_sheets.append(sheet)

	_all_legendary_sheets.clear()
	for path in LEGENDARY_SHEET_PATHS:
		var legendary: SheetData = load(path) as SheetData
		if legendary != null:
			_all_legendary_sheets.append(legendary)

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

	_all_deck_tools.clear()
	for path in DECK_TOOL_PATHS:
		var tool: DeckToolData = load(path) as DeckToolData
		if tool != null:
			_all_deck_tools.append(tool)


## A appeler a l'ouverture du shop. Regenere les DEUX rangees.
func regenerate_offer(run_manager: RunManager) -> void:
	_regenerate_packs(run_manager)
	_regenerate_unitaires(run_manager)


## A appeler au reroll : les packs restent fixes pour toute la visite (comme
## Balatro), seule la rangee des unitaires visibles est regeneree.
func reroll_unitaires(run_manager: RunManager) -> void:
	_regenerate_unitaires(run_manager)


## Categories tirees sans doublon au sein d'une meme rangee (session 19) —
## avant, chaque slot tirait sa categorie independamment (randi() % size),
## donc rien n'empechait de retomber sur "special" sur toute la rangee (voire
## les deux rangees a la fois). Contraire au principe "pas de RNG punitif"
## deja applique ailleurs (deck de depart, Entity). Ponderee par
## GameRules.CATEGORY_WEIGHTS depuis la session 20 (avant : shuffle uniforme) —
## le nombre de slots par rangee reste toujours <= au nombre de categories,
## donc jamais besoin de retirage.
func _regenerate_packs(_run_manager: RunManager) -> void:
	_pack_slots.clear()
	var categories: Array[String] = _weighted_sample_categories(PACK_CATEGORIES, GameRules.SHOP_PACK_SLOT_COUNT)
	for category in categories:
		_pack_slots.append({
			"format": "pack",
			"category": category,
			"size": GameRules.PACK_SIZE_BUTTON if category == "button" else GameRules.PACK_SIZE_DEFAULT,
			"price": _pack_price(category),
		})


func _regenerate_unitaires(run_manager: RunManager) -> void:
	_unitaire_slots.clear()
	var categories: Array[String] = _weighted_sample_categories(UNITAIRE_CATEGORIES, GameRules.SHOP_UNITAIRE_SLOT_COUNT)
	for category in categories:
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
		"sheet": return GameRules.PACK_PRICE_SHEET
		"badge": return GameRules.PACK_PRICE_BADGE
		"special": return GameRules.PACK_PRICE_SPECIAL
		"button": return GameRules.PACK_PRICE_BUTTON
	return 0


func _draw_unitaire(category: String, run_manager: RunManager) -> Variant:
	match category:
		"sheet":
			return _draw_sheet_candidate(run_manager)
		"badge":
			var pool: Array[BadgeData] = _available_badges(run_manager)
			return _weighted_pick(pool)
		"special":
			return _all_specials[randi() % _all_specials.size()] if not _all_specials.is_empty() else null
		"button":
			return _random_button()
	return null


## Tirage pondere par rarete (GameRules.RARITY_WEIGHTS). Marche sur n'importe
## quel pool de Resource exposant un champ "rarity" (BadgeData, DeckToolData) —
## Speciaux, Boutons et Partitions n'en ont pas, ils restent tires uniformement
## ailleurs (session 19 pour les Partitions, voir SheetData).
static func _weighted_pick(pool: Array) -> Variant:
	if pool.is_empty():
		return null
	var weights: Array[float] = []
	var total: float = 0.0
	for item in pool:
		var w: float = GameRules.RARITY_WEIGHTS[int(item.rarity)]
		weights.append(w)
		total += w

	var roll: float = randf() * total
	var cumulative: float = 0.0
	for i in range(pool.size()):
		cumulative += weights[i]
		if roll < cumulative:
			return pool[i]
	return pool[pool.size() - 1]


## Meme pondration que _weighted_pick mais tire `count` items distincts (sans
## remise) — utilise par l'ouverture de pack.
static func _weighted_sample(pool: Array, count: int) -> Array:
	var remaining: Array = pool.duplicate()
	var picked: Array = []
	while remaining.size() > 0 and picked.size() < count:
		var item: Variant = _weighted_pick(remaining)
		picked.append(item)
		remaining.erase(item)
	return picked


## Meme principe que _weighted_pick/_weighted_sample mais pour les categories
## de slot (String), ponderees par GameRules.CATEGORY_WEIGHTS plutot que par
## une rarete portee par la Resource elle-meme.
static func _weighted_sample_categories(categories: Array[String], count: int) -> Array[String]:
	var remaining: Array[String] = categories.duplicate()
	var picked: Array[String] = []
	while remaining.size() > 0 and picked.size() < count:
		var weights: Array[float] = []
		var total: float = 0.0
		for category in remaining:
			var w: float = GameRules.CATEGORY_WEIGHTS.get(category, 1.0) as float
			weights.append(w)
			total += w

		var roll: float = randf() * total
		var cumulative: float = 0.0
		var chosen_index: int = remaining.size() - 1
		for i in range(remaining.size()):
			cumulative += weights[i]
			if roll < cumulative:
				chosen_index = i
				break

		picked.append(remaining[chosen_index])
		remaining.remove_at(chosen_index)
	return picked


func _available_sheets(run_manager: RunManager) -> Array[SheetData]:
	var equipped: Array[SheetData] = run_manager.get_equipped_sheets()
	var pool: Array[SheetData] = []
	for sheet in _all_sheets:
		if not sheet.locked and not equipped.has(sheet):
			pool.append(sheet)
	return pool


func _available_legendary_sheets(run_manager: RunManager) -> Array[SheetData]:
	var equipped: Array[SheetData] = run_manager.get_equipped_sheets()
	var pool: Array[SheetData] = []
	for sheet in _all_legendary_sheets:
		if not equipped.has(sheet):
			pool.append(sheet)
	return pool


## Un slot "sheet" (unitaire ou candidat de pack) a une petite chance
## independante de piocher dans le pool legendaire plutot que le pool normal
## uniforme — voir GameRules.LEGENDARY_SHEET_CHANCE et SheetData.is_legendary.
func _draw_sheet_candidate(run_manager: RunManager) -> SheetData:
	if randf() < GameRules.LEGENDARY_SHEET_CHANCE:
		var legendary_pool: Array[SheetData] = _available_legendary_sheets(run_manager)
		if not legendary_pool.is_empty():
			return legendary_pool[randi() % legendary_pool.size()]
	var pool: Array[SheetData] = _available_sheets(run_manager)
	return pool[randi() % pool.size()] if not pool.is_empty() else null


func _available_badges(run_manager: RunManager) -> Array[BadgeData]:
	var equipped: Array[BadgeData] = run_manager.get_equipped_badges()
	var pool: Array[BadgeData] = []
	for badge in _all_badges:
		if not equipped.has(badge):
			pool.append(badge)
	return pool


func _random_button() -> TokenData:
	var family: int = randi() % GameRules.FAMILY_COUNT
	var value: int
	if randf() < GameRules.SHOP_BUTTON_RARE_VALUE_CHANCE:
		value = GameRules.MAX_BUTTON_VALUE
	else:
		value = randi() % GameRules.TOKEN_MAX_VALUE + GameRules.TOKEN_MIN_VALUE
	return TokenData.make_base(family as TokenData.Family, value)


func get_pack_slots() -> Array[Dictionary]:
	return _pack_slots


func get_unitaire_slots() -> Array[Dictionary]:
	return _unitaire_slots


## Retourne le label d'un item (SheetData, SpecialItem, BadgeData ou TokenData).
static func get_label(item: Variant) -> String:
	if item is SheetData:
		return (item as SheetData).label
	if item is SpecialItem:
		return (item as SpecialItem).label
	if item is BadgeData:
		return (item as BadgeData).label
	if item is DeckToolData:
		return (item as DeckToolData).label
	if item is TokenData:
		var token: TokenData = item as TokenData
		return "%s %d" % [TokenData.family_label(token.family), token.value]
	return ""


## Retourne le texte de hover d'un item.
static func get_description(item: Variant) -> String:
	if item is SheetData:
		return (item as SheetData).describe()
	if item is SpecialItem:
		return (item as SpecialItem).description
	if item is BadgeData:
		return (item as BadgeData).description
	if item is DeckToolData:
		return (item as DeckToolData).description
	return ""


## Retourne la rarete d'un item, -1 si le type n'en a pas (Special, Bouton,
## Partition depuis la session 19) — RarityButton retombe alors sur le
## tooltip texte simple.
static func get_rarity(item: Variant) -> int:
	if item is BadgeData:
		return (item as BadgeData).rarity
	if item is DeckToolData:
		return (item as DeckToolData).rarity
	return -1


## Retourne le prix unitaire d'un item.
static func get_price(item: Variant) -> int:
	if item is SheetData:
		return (item as SheetData).price
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
	return can_equip_slot(item, run_manager)


## Retourne true si l'item a encore un slot dispo pour etre equipe (Partition/
## Badge). Ne verifie pas le prix — utilise par can_purchase (achat unitaire)
## et par choose_from_pack (deja paye, slots seulement).
func can_equip_slot(item: Variant, run_manager: RunManager) -> bool:
	if item is SheetData:
		var equipped_sheets: Array[SheetData] = run_manager.get_equipped_sheets()
		if equipped_sheets.size() >= GameRules.MAX_SHEET_SLOTS:
			return false
		if equipped_sheets.has(item):
			return false
	elif item is BadgeData:
		var equipped_badges: Array[BadgeData] = run_manager.get_equipped_badges()
		if equipped_badges.size() >= run_manager.get_badge_slot_count():
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
	if item is SheetData:
		run_manager.equip_sheet(item as SheetData)
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
		"sheet":
			# Chaque candidat revele a sa propre chance de legendaire (voir
			# _draw_sheet_candidate) — distincts, sans doublon, comme un tirage
			# uniforme classique.
			var candidates: Array[SheetData] = []
			var seen: Dictionary = {}
			var attempts: int = 0
			while candidates.size() < size and attempts < size * 10:
				attempts += 1
				var candidate: SheetData = _draw_sheet_candidate(run_manager)
				if candidate == null or seen.has(candidate):
					continue
				seen[candidate] = true
				candidates.append(candidate)
			return candidates
		"badge":
			var pool: Array[BadgeData] = _available_badges(run_manager)
			return _weighted_sample(pool, size)
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
## Filet de securite : PackPanelUI grise deja les candidats sans slot dispo,
## mais on revalide ici pour ne jamais equiper silencieusement au-dela des slots.
func choose_from_pack(item: Variant, run_manager: RunManager) -> void:
	if not can_equip_slot(item, run_manager):
		purchase_failed.emit(item)
		return
	_apply_item(item, run_manager)
	if item is TokenData:
		button_purchased.emit(item)
	else:
		purchased.emit(item)


## --- Des a coudre (gate un outil de deck) ---

func can_purchase_des_a_coudre(run_manager: RunManager) -> bool:
	return run_manager.get_flies() >= GameRules.DES_A_COUDRE_PRICE


func purchase_des_a_coudre(run_manager: RunManager) -> bool:
	if not can_purchase_des_a_coudre(run_manager):
		return false
	return run_manager.spend_flies(GameRules.DES_A_COUDRE_PRICE)


## Tire DECK_TOOL_ACTION_DRAW_SIZE outils de deck distincts, pondere par
## rarete (meme mecanisme que l'ouverture d'un pack). A appeler une fois le
## Des a coudre paye, voir ShopUI._on_des_a_coudre_pressed.
func draw_deck_tool_choices() -> Array:
	return _weighted_sample(_all_deck_tools, GameRules.DECK_TOOL_ACTION_DRAW_SIZE)
