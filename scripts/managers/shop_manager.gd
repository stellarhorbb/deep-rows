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
	"res://resources/sheets/jackpot_777.tres",
	"res://resources/sheets/jackpot_9999.tres",
	"res://resources/sheets/wedding.tres",
	"res://resources/sheets/royal_court.tres",
]

## Petit pool a part (session 20) — jamais dans SHEET_PATHS/le tirage uniforme
## normal. Chaque slot "sheet" (unitaire ou candidat de pack) a une chance
## independante (GameRules.LEGENDARY_SHEET_CHANCE) de piocher ici plutot que
## dans le pool normal. Voir SheetData.is_legendary et _draw_sheet_candidate.
const LEGENDARY_SHEET_PATHS: Array[String] = [
	"res://resources/sheets/legendary_lost_corners.tres",
	"res://resources/sheets/legendary_royal_square.tres",
	"res://resources/sheets/legendary_skull_line.tres",
	"res://resources/sheets/legendary_shadow_dance.tres",
	"res://resources/sheets/legendary_black_hole.tres",
	"res://resources/sheets/legendary_last_trick.tres",
]

## Speciaux achetables (SpecialItem).
const SPECIAL_PATHS: Array[String] = [
	"res://resources/specials/special_bombe.tres",
	"res://resources/specials/special_fantome.tres",
	"res://resources/specials/special_maree.tres",
	"res://resources/specials/special_enclume.tres",
	"res://resources/specials/special_petard_a_meche.tres",
	"res://resources/specials/special_cavalier.tres",
	"res://resources/specials/special_frog.tres",
	"res://resources/specials/special_liane.tres",
	"res://resources/specials/special_crow.tres",
	"res://resources/specials/special_underground.tres",
	"res://resources/specials/special_hypercube.tres",
	"res://resources/specials/special_armageddon.tres",
	"res://resources/specials/special_cristal.tres",
	"res://resources/specials/special_diamant.tres",
	"res://resources/specials/special_comete.tres",
	"res://resources/specials/special_amplificateur.tres",
	"res://resources/specials/special_siphon.tres",
]

## Sortilèges achetables (SpellData).
## Numerologie retire du catalogue actif : boost la rule "value", plus aucun
## Sheet ne l.utilise (voir SHEET_PATHS ci-dessus).
const SPELL_PATHS: Array[String] = [
	"res://resources/spells/spell_flies_cascade.tres",
	"res://resources/spells/spell_cell_triple.tres",
	"res://resources/spells/spell_trench.tres",
	"res://resources/spells/spell_family_unie.tres",
	"res://resources/spells/spell_cell_double.tres",
	"res://resources/spells/spell_ecume.tres",
	"res://resources/spells/spell_pourboire.tres",
	# "res://resources/spells/spell_numerologie.tres",
	"res://resources/spells/spell_collectionneur.tres",
	"res://resources/spells/spell_vertige.tres",
	"res://resources/spells/spell_colonne_chanceuse.tres",
	"res://resources/spells/spell_bord_a_bord.tres",
	"res://resources/spells/spell_un_pour_tous.tres",
	"res://resources/spells/spell_regularite.tres",
	"res://resources/spells/spell_dernier_carre.tres",
	"res://resources/spells/spell_petites_mains.tres",
	"res://resources/spells/spell_vingt_trois.tres",
	"res://resources/spells/spell_saint_pair.tres",
	"res://resources/spells/spell_impair_profane.tres",
	"res://resources/spells/spell_yen_a_pas_deux.tres",
	"res://resources/spells/spell_sommet.tres",
	"res://resources/spells/spell_tickets_hivernal.tres",
	"res://resources/spells/spell_tickets_automnal.tres",
	"res://resources/spells/spell_tickets_estival.tres",
	"res://resources/spells/spell_tickets_printanier.tres",
	"res://resources/spells/spell_jetons_sacres.tres",
	"res://resources/spells/spell_quatre_quart.tres",
	"res://resources/spells/spell_poker_face.tres",
	"res://resources/spells/spell_mouche_cubique.tres",
	"res://resources/spells/spell_visionnaire.tres",
	"res://resources/spells/spell_benediction.tres",
	"res://resources/spells/spell_recif_vivant.tres",
	"res://resources/spells/spell_mouche_doree.tres",
	"res://resources/spells/spell_mouche_melomane.tres",
	"res://resources/spells/spell_escalade_musicale.tres",
	"res://resources/spells/spell_amelioration_continue.tres",
	"res://resources/spells/spell_gourmand.tres",
	"res://resources/spells/spell_econome.tres",
	"res://resources/spells/spell_couronne.tres",
	"res://resources/spells/spell_diademe.tres",
	"res://resources/spells/spell_regain.tres",
	"res://resources/spells/spell_sang_froid.tres",
	"res://resources/spells/spell_nouvelle_donne.tres",
	"res://resources/spells/spell_brocante.tres",
	"res://resources/spells/spell_adoubement.tres",
	"res://resources/spells/spell_rescape.tres",
	"res://resources/spells/spell_cairn.tres",
	"res://resources/spells/spell_petit_point.tres",
	"res://resources/spells/spell_refrain.tres",
	"res://resources/spells/spell_artificier.tres",
	"res://resources/spells/spell_sacre.tres",
	"res://resources/spells/spell_virtuose.tres",
	"res://resources/spells/spell_dresseur_fou.tres",
	"res://resources/spells/spell_souffle_obscur.tres",
	"res://resources/spells/spell_favoritisme.tres",
	"res://resources/spells/spell_bon_depart.tres",
	"res://resources/spells/spell_fenetre_longue.tres",
	"res://resources/spells/spell_jamais_1_sans_2.tres",
	"res://resources/spells/spell_deux_etages.tres",
	"res://resources/spells/spell_vestige.tres",
	"res://resources/spells/spell_decuple_petard.tres",
	"res://resources/spells/spell_quintuple_bombe.tres",
	"res://resources/spells/spell_triple_armageddon.tres",
	"res://resources/spells/spell_pierre_de_famille.tres",
	"res://resources/spells/spell_pile_ou_face.tres",
	"res://resources/spells/spell_dernier_dernier_souffle.tres",
	"res://resources/spells/spell_miroir.tres",
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
const PACK_CATEGORIES: Array[String] = ["sheet", "spell", "special", "button"]

## Categories tirables pour un slot unitaire (visible directement).
const UNITAIRE_CATEGORIES: Array[String] = ["sheet", "spell", "special", "button", "des_a_coudre"]

## Pools complets, charges une fois. L'offre visible est une curation
## regeneree a chaque visite (regenerate_offer).
var _all_sheets: Array[SheetData] = []
var _all_legendary_sheets: Array[SheetData] = []
var _all_specials: Array[SpecialItem] = []
var _all_spells: Array[SpellData] = []
var _all_deck_tools: Array[DeckToolData] = []

## File d'apparition des Sortilèges, une par palier de rarete (session 23,
## inspire de Balatro — voir docs/gdd/sortileges/sortileges-implementes.md). Contrairement
## a un tirage independant avec remise, un Sortilège vu-et-refuse ne peut pas
## repasser avant d'avoir fait le tour complet des autres du meme palier.
## int (SpellData.Rarity) -> Array[SpellData], melangee ; le pointeur associe
## avance a chaque tirage et ne revient jamais en arriere (sauf remelange une
## fois la file epuisee). Reconstruite a chaque nouvelle run (voir reset_run,
## appele par RunService.start_new_run) — jamais entre deux visites du shop.
var _spell_queues: Dictionary = {}
var _spell_queue_pos: Dictionary = {}

## Meme principe pour les Partitions (session 23) — sans palier de rarete
## (les Partitions n'en ont pas, decision session 19), donc une seule cle
## &"generic" pour le pool normal, une autre &"legendary" pour le petit pool
## a part (voir LEGENDARY_SHEET_PATHS/_draw_sheet_candidate). Les Partitions
## verrouillees n'entrent jamais dans la file consommee (voir _available_
## sheets) — filtrees a chaque tirage exactement comme les equipees.
var _sheet_queues: Dictionary = {}
var _sheet_queue_pos: Dictionary = {}

## Deux rangees separees. Formats possibles pour un slot (Dictionary) :
##   {"format": "unitaire", "category": String, "item": Resource|TokenData}
##   {"format": "pack", "category": String, "size": int, "price": int}
##   {"format": "des_a_coudre", "price": int}
var _pack_slots: Array[Dictionary] = []
var _unitaire_slots: Array[Dictionary] = []


func _ready() -> void:
	_load_pools()


## A appeler par RunService.start_new_run() : repart sur des files de Sortilèges
## fraiches (melangees, pointeur a 0) pour la nouvelle run. Sans ca, l'ordre
## de la run precedente continuerait a avancer d'une run a l'autre (le meme
## ShopManager persiste pour toute la session de jeu, voir RunService).
func reset_run() -> void:
	_spell_queues.clear()
	_spell_queue_pos.clear()
	_sheet_queues.clear()
	_sheet_queue_pos.clear()


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

	_all_spells.clear()
	for path in SPELL_PATHS:
		var spell: SpellData = load(path) as SpellData
		if spell != null:
			_all_spells.append(spell)

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
		"spell": return GameRules.PACK_PRICE_SPELL
		"special": return GameRules.PACK_PRICE_SPECIAL
		"button": return GameRules.PACK_PRICE_BUTTON
	return 0


func _draw_unitaire(category: String, run_manager: RunManager) -> Variant:
	match category:
		"sheet":
			return _draw_sheet_candidate(run_manager)
		"spell":
			return _draw_spell_queued(run_manager)
		"special":
			return _weighted_pick(_all_specials)
		"button":
			return _random_button()
	return null


## Tirage independant pondere par rarete (GameRules.RARITY_WEIGHTS), avec
## remise — un item vu-et-refuse peut ressortir au tirage suivant. Utilise
## pour DeckToolData et SpecialItem, choix delibere (session 23) : on aime
## parfois retomber sur le meme Special/Dé à coudre selon le besoin du moment,
## contrairement aux Sortilèges qui ont une vraie file d'apparition (voir
## _draw_spell_queued). Boutons et Partitions n'ont pas de rarete du tout, ils
## restent tires uniformement ailleurs (session 19 pour les Partitions, voir
## SheetData).
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
		var accessible: bool = not sheet.locked or MetaProgression.is_unlocked(sheet.unlock_id)
		if accessible and not equipped.has(sheet):
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
## Chaque cote (generic/legendary) tire via sa propre file (session 23, voir
## _sheet_queues) plutot qu'un tirage independant.
func _draw_sheet_candidate(run_manager: RunManager) -> SheetData:
	if randf() < GameRules.LEGENDARY_SHEET_CHANCE:
		var legendary_pool: Array[SheetData] = _available_legendary_sheets(run_manager)
		if not legendary_pool.is_empty():
			return _next_sheet_in_queue(&"legendary", _all_legendary_sheets, legendary_pool)
	var pool: Array[SheetData] = _available_sheets(run_manager)
	return _next_sheet_in_queue(&"generic", _all_sheets, pool)


## Meme principe que _next_spell_in_queue, generalise a une cle StringName
## (&"generic"/&"legendary") plutot qu'un palier de rarete — les Partitions
## n'ont qu'un seul pool chacune, pas de ponderation a faire en amont.
func _next_sheet_in_queue(key: StringName, full_pool: Array[SheetData], available: Array[SheetData]) -> SheetData:
	if available.is_empty():
		return null
	if not _sheet_queues.has(key) or (_sheet_queues[key] as Array).is_empty():
		_reshuffle_sheet_queue(key, full_pool)

	var queue: Array = _sheet_queues[key] as Array
	var pos: int = _sheet_queue_pos.get(key, 0) as int
	var scanned: int = 0
	while scanned < queue.size() * 2:  # x2 : au pire un remelange en cours de route
		if pos >= queue.size():
			_reshuffle_sheet_queue(key, full_pool)
			queue = _sheet_queues[key] as Array
			pos = 0
		var candidate: SheetData = queue[pos] as SheetData
		pos += 1
		scanned += 1
		if available.has(candidate):
			_sheet_queue_pos[key] = pos
			return candidate

	return available[0]


func _reshuffle_sheet_queue(key: StringName, full_pool: Array[SheetData]) -> void:
	var pool: Array[SheetData] = full_pool.duplicate()
	pool.shuffle()
	_sheet_queues[key] = pool
	_sheet_queue_pos[key] = 0


## Tirage par file d'apparition (session 23, voir _spell_queues) : choisit
## d'abord un palier de rarete a TAUX FIXE (GameRules.SPELL_RARITY_RATES,
## independant du nombre de Sortilèges dans le palier — contrairement a
## _weighted_pick/RARITY_WEIGHTS utilise par Speciaux/Des a coudre), puis
## prend le prochain Sortilège de la file de ce palier plutot qu'un tirage
## independant. Un palier sans aucun Sortilège disponible (tous equipes/exclus)
## est absent de `tier_weights` et donc jamais tire — les autres se
## renormalisent automatiquement via `total` (meme principe que le "resample"
## de Balatro, sans code dedie). `exclude` sert au tirage multiple d'un pack
## (voir open_pack) pour ne jamais montrer deux fois le meme Sortilège dans les
## candidats d'un seul pack.
func _draw_spell_queued(run_manager: RunManager, exclude: Array[SpellData] = []) -> SpellData:
	var available_by_rarity: Dictionary = {}  # int -> Array[SpellData]
	var equipped: Array[SpellData] = run_manager.get_equipped_spells()
	for spell in _all_spells:
		if equipped.has(spell) or exclude.has(spell):
			continue
		var r: int = int(spell.rarity)
		if not available_by_rarity.has(r):
			available_by_rarity[r] = [] as Array[SpellData]
		(available_by_rarity[r] as Array[SpellData]).append(spell)

	var tier_weights: Dictionary = {}  # int -> float
	var total: float = 0.0
	for r in available_by_rarity:
		var w: float = GameRules.SPELL_RARITY_RATES[r]
		tier_weights[r] = w
		total += w
	if total <= 0.0:
		return null

	var roll: float = randf() * total
	var cumulative: float = 0.0
	var chosen_rarity: int = -1
	for r in tier_weights:
		cumulative += tier_weights[r] as float
		if roll < cumulative:
			chosen_rarity = r
			break
	if chosen_rarity == -1:
		chosen_rarity = (tier_weights.keys() as Array)[tier_weights.size() - 1]

	return _next_spell_in_queue(chosen_rarity, available_by_rarity[chosen_rarity] as Array[SpellData])


## Avance dans la file du palier `rarity`, en sautant les Sortilèges absents de
## `available` (deja equipes ou deja pioches plus tot dans le meme pack) —
## remelange la file quand elle est epuisee. `available` garantit toujours
## au moins un candidat valide (le palier n'est choisi que s'il en a un, voir
## _draw_spell_queued), donc la boucle finit toujours par en trouver un.
func _next_spell_in_queue(rarity: int, available: Array[SpellData]) -> SpellData:
	if not _spell_queues.has(rarity) or (_spell_queues[rarity] as Array).is_empty():
		_reshuffle_spell_queue(rarity)

	var queue: Array = _spell_queues[rarity] as Array
	var pos: int = _spell_queue_pos.get(rarity, 0) as int
	var scanned: int = 0
	while scanned < queue.size() * 2:  # x2 : au pire un remelange en cours de route
		if pos >= queue.size():
			_reshuffle_spell_queue(rarity)
			queue = _spell_queues[rarity] as Array
			pos = 0
		var candidate: SpellData = queue[pos] as SpellData
		pos += 1
		scanned += 1
		if available.has(candidate):
			_spell_queue_pos[rarity] = pos
			return candidate

	return available[0] if not available.is_empty() else null


func _reshuffle_spell_queue(rarity: int) -> void:
	var pool: Array[SpellData] = []
	for spell in _all_spells:
		if int(spell.rarity) == rarity:
			pool.append(spell)
	pool.shuffle()
	_spell_queues[rarity] = pool
	_spell_queue_pos[rarity] = 0


func _random_button() -> TokenData:
	var family: int = randi() % GameRules.FAMILY_COUNT
	var value: int
	if randf() < GameRules.SHOP_BUTTON_RARE_VALUE_CHANCE:
		value = GameRules.MAX_BUTTON_VALUE
	else:
		value = _weighted_button_value()
	return TokenData.make_base(family as TokenData.Family, value)


## Tirage pondere sur 1..TOKEN_MAX_VALUE (voir GameRules.SHOP_BUTTON_VALUE_WEIGHTS) —
## plus une valeur est haute, plus elle est rare. Le jackpot MAX_BUTTON_VALUE
## reste gere a part par SHOP_BUTTON_RARE_VALUE_CHANCE, avant cet appel.
static func _weighted_button_value() -> int:
	var weights: Array[float] = GameRules.SHOP_BUTTON_VALUE_WEIGHTS
	var total: float = 0.0
	for w in weights:
		total += w
	var roll: float = randf() * total
	var cumulative: float = 0.0
	for i in range(weights.size()):
		cumulative += weights[i]
		if roll < cumulative:
			return GameRules.TOKEN_MIN_VALUE + i
	return GameRules.TOKEN_MAX_VALUE


## Retrouve la definition complete (label + description) d'un Special par son
## type — utilise par le hover des jetons (StreamUI) pour reprendre le meme
## texte que le shop plutot que de le dupliquer.
func get_special_item(special_type: TokenData.SpecialType) -> SpecialItem:
	for item in _all_specials:
		if item.special_type == special_type:
			return item
	return null


func get_pack_slots() -> Array[Dictionary]:
	return _pack_slots


func get_unitaire_slots() -> Array[Dictionary]:
	return _unitaire_slots


## Vrai si un slot "Des a coudre" est visible dans l'offre actuelle des
## unitaires — utilise par ShopUI pour declencher le sortilège trigger
## on_deck_tool_shown (ex: "Petit Point") une seule fois par visite, pas a
## chaque reroll (voir ShopUI._ready).
func has_deck_tool_offer() -> bool:
	for slot in _unitaire_slots:
		if (slot as Dictionary).get("format") == "des_a_coudre":
			return true
	return false


## Retourne le label d'un item (SheetData, SpecialItem, SpellData ou TokenData).
static func get_label(item: Variant) -> String:
	if item is SheetData:
		return (item as SheetData).label
	if item is SpecialItem:
		return (item as SpecialItem).label
	if item is SpellData:
		return (item as SpellData).label
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
	if item is SpellData:
		return (item as SpellData).description
	if item is DeckToolData:
		return (item as DeckToolData).description
	return ""


## Retourne la rarete d'un item, -1 si le type n'en a pas (Bouton) —
## RarityButton retombe alors sur le tooltip texte simple. Les Partitions
## normales restent aussi a -1 (tirage uniforme, session 19 : pas de gating
## par rarete) — seules les legendaires (SheetData.is_legendary) remontent en
## LEGENDARY, pour le sortilège colore/dopamine a la reveal (pack et shop),
## sans toucher au tirage lui-meme (LEGENDARY_SHEET_CHANCE inchange).
## Speciaux : rarete reelle depuis la session 23 (SpecialItem.rarity).
static func get_rarity(item: Variant) -> int:
	if item is SpellData:
		return (item as SpellData).rarity
	if item is DeckToolData:
		return (item as DeckToolData).rarity
	if item is SpecialItem:
		return (item as SpecialItem).rarity
	if item is SheetData and (item as SheetData).is_legendary:
		return SpellData.Rarity.LEGENDARY
	return -1


## Retourne le prix unitaire d'un item.
static func get_price(item: Variant) -> int:
	if item is SheetData:
		return (item as SheetData).price
	if item is SpecialItem:
		return (item as SpecialItem).price
	if item is SpellData:
		return (item as SpellData).price
	if item is TokenData:
		return GameRules.BUTTON_UNIT_PRICE
	return 0


## Retourne true si le joueur peut acheter (mouches + slots dispo).
func can_purchase(item: Variant, run_manager: RunManager) -> bool:
	if run_manager.get_flies() < get_price(item):
		return false
	return can_equip_slot(item, run_manager)


## Retourne true si l'item a encore un slot dispo pour etre equipe (Partition/
## Sortilège). Ne verifie pas le prix — utilise par can_purchase (achat unitaire)
## et par choose_from_pack (deja paye, slots seulement).
func can_equip_slot(item: Variant, run_manager: RunManager) -> bool:
	if item is SheetData:
		var equipped_sheets: Array[SheetData] = run_manager.get_equipped_sheets()
		if equipped_sheets.size() >= GameRules.MAX_SHEET_SLOTS:
			return false
		if equipped_sheets.has(item):
			return false
	elif item is SpellData:
		var equipped_spells: Array[SpellData] = run_manager.get_equipped_spells()
		if equipped_spells.size() >= run_manager.get_spell_slot_count():
			return false
		if equipped_spells.has(item):
			return false
	elif item is SpecialItem:
		# Inventaire de speciaux (session 25) : meme logique de slot limite
		# que Sheets/Sortilèges, avant de debiter les mouches.
		if run_manager.get_special_inventory().size() >= run_manager.get_special_inventory_capacity():
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
	elif item is SpellData:
		run_manager.equip_spell(item as SpellData)
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
		"spell":
			var picked: Array[SpellData] = []
			for i in range(size):
				var spell: SpellData = _draw_spell_queued(run_manager, picked)
				if spell == null:
					break
				picked.append(spell)
			return picked
		"special":
			var pool: Array[SpecialItem] = _all_specials.duplicate()
			return _weighted_sample(pool, size)
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
