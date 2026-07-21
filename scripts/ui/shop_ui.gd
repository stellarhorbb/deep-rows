## Scene autonome du shop. Lit les managers via l'autoload RunService.
## v2 : deux rangees separees, a la Balatro — Packs (nombre fixe, jamais
## regeneres par le reroll) et Unitaires visibles (nombre fixe, regeneres a
## chaque reroll). "Des a coudre" est une categorie d'unitaire parmi d'autres,
## gate un outil de deck (session 16 : tirage de 3 outils distincts pondere
## par rarete, le joueur en choisit 1, generalise l'ancienne Fusion seule —
## voir docs/brainstorms/brainstorm-outils-deck.md).
## Quand le joueur clique "CONTINUER", avance le run et retourne au game.
class_name ShopUI
extends Control

@onready var packs_container: HBoxContainer = $Panel/VBox/PacksContainer
@onready var unitaires_container: HBoxContainer = $Panel/VBox/UnitairesContainer
@onready var flies_label: Label = $FliesLabel
@onready var continue_button: Button = $Panel/VBox/ContinueButton
@onready var reroll_button: Button = $RerollButton

@onready var pack_panel: PackPanelUI = $PackPanel

## Panneau du Des a coudre : candidats et actions visibles en meme temps
## (session 16, revu apres un 1er jet en 2 ecrans separes — voir tooltip du
## user : voir les cibles guide le choix de l'action, et evite de choisir une
## action qui n'aurait finalement aucune cible valide dans le tirage).
## Noms de noeuds herites de l'ancienne Fusion seule (session 12), pas
## renommes dans la scene pour eviter de perturber d'autres references.
@onready var target_panel: Control = $FusionPanel
@onready var target_candidates_container: GridContainer = $FusionPanel/Box/VBox/CandidatesContainer
@onready var tool_actions_container: HBoxContainer = $FusionPanel/Box/VBox/ActionsContainer
@onready var target_close_button: Button = $FusionPanel/Box/VBox/CloseButton

var _run_manager: RunManager
var _shop_manager: ShopManager

## Un entry par slot affiche : {"slot": Dictionary, "button": Button, "consumed": bool}.
## "consumed" reste vrai definitivement (achat fait / pack ouvert / des a coudre
## utilise), independamment du solde de mouches ensuite.
var _pack_entries: Array[Dictionary] = []
var _unitaire_entries: Array[Dictionary] = []
var _reroll_count: int = 0

## Reroll gratuit de cette visite, offert par le badge "Econome" — consomme au
## premier reroll, peu importe lequel (unitaires). Reinitialise a chaque
## nouvelle visite du shop (_ready), le seul endroit qui sait de facon fiable
## qu'une visite commence (aucun signal shop_entered/shop_opened aujourd'hui).
var _free_reroll_available: bool = false

## Etat du panneau Des a coudre : 3 actions tirees + 8 candidats, tous deux
## visibles en meme temps. Selectionner des boutons (jusqu'a 2, le max requis
## par Fusionner) active/desactive les actions selon leur validite — cliquer
## une action activee l'applique immediatement, pas de confirmation separee.
var _tool_choices: Array = []
var _tool_action_buttons: Array[Button] = []
var _target_candidate_buttons: Array[Button] = []
var _target_selected_indices: Array[int] = []
var _target_candidate_tokens: Dictionary = {}  # pool_index -> TokenData


func _ready() -> void:
	_run_manager = RunService.run_manager
	_shop_manager = RunService.shop_manager

	_run_manager.flies_changed.connect(_on_flies_changed)
	_shop_manager.purchased.connect(_on_purchased)
	_shop_manager.button_purchased.connect(_on_purchased)
	continue_button.pressed.connect(_on_continue_pressed)
	reroll_button.pressed.connect(_on_reroll_pressed)
	pack_panel.item_chosen.connect(_on_pack_item_chosen)
	target_close_button.pressed.connect(_on_target_close_pressed)

	# Le deck (apercu prochaine manche) reste consultable au shop, y compris
	# pendant l'ouverture d'un pack (voir DeckInspectorUI.run_manager) — pour
	# que le joueur puisse acheter en connaissance de cause.
	SceneRouter.shell.deck_button.disabled = false

	_reroll_count = 0
	_free_reroll_available = _run_manager.has_badge(&"econome")
	_shop_manager.regenerate_offer(_run_manager)
	if _shop_manager.has_deck_tool_offer():
		RunService.badge_manager.dispatch_deck_tool_shown()
	_refresh_flies()
	_rebuild_packs()
	_rebuild_unitaires()
	_refresh_reroll_button()


# --- Packs (fixes pour la visite, pas de reroll) ---

func _rebuild_packs() -> void:
	for entry in _pack_entries:
		(entry["button"] as Button).queue_free()
	_pack_entries.clear()

	for slot in _shop_manager.get_pack_slots():
		var entry: Dictionary = {"slot": slot, "button": null, "consumed": false}
		var btn: Button = _make_pack_button(entry)
		entry["button"] = btn
		packs_container.add_child(btn)
		_pack_entries.append(entry)


func _make_pack_button(entry: Dictionary) -> Button:
	var slot: Dictionary = entry["slot"]
	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(260.0, 140.0)
	btn.text = "PACK %s\n%d mouches" % [_category_label(slot["category"]), slot["price"]]
	btn.tooltip_text = "Contenu révélé à l'ouverture — tu en gardes 1"
	btn.disabled = not _shop_manager.can_purchase_pack(slot, _run_manager)
	btn.pressed.connect(_on_pack_pressed.bind(entry))
	return btn


func _on_pack_pressed(entry: Dictionary) -> void:
	var slot: Dictionary = entry["slot"]
	if not _shop_manager.purchase_pack(slot, _run_manager):
		return
	entry["consumed"] = true
	(entry["button"] as Button).disabled = true
	var candidates: Array = _shop_manager.open_pack(slot, _run_manager)
	pack_panel.open_with(candidates, "PACK %s — choisis 1" % _category_label(slot["category"]), _shop_manager, _run_manager)


func _on_pack_item_chosen(item: Variant) -> void:
	_shop_manager.choose_from_pack(item, _run_manager)


# --- Unitaires visibles (regeneres a chaque reroll) ---

func _rebuild_unitaires() -> void:
	for entry in _unitaire_entries:
		(entry["button"] as Button).queue_free()
	_unitaire_entries.clear()

	for slot in _shop_manager.get_unitaire_slots():
		var entry: Dictionary = {"slot": slot, "button": null, "consumed": false}
		var btn: Button = _make_unitaire_button(entry)
		entry["button"] = btn
		unitaires_container.add_child(btn)
		_unitaire_entries.append(entry)


func _make_unitaire_button(entry: Dictionary) -> Button:
	var slot: Dictionary = entry["slot"]
	var btn: RarityButton = RarityButton.new()
	btn.custom_minimum_size = Vector2(260.0, 140.0)

	if slot["format"] == "des_a_coudre":
		btn.text = "DÉS À COUDRE\nManipule ton deck\n%d mouches" % slot["price"]
		btn.tooltip_text = "Tire 3 outils de deck au hasard, choisis-en un"
		btn.disabled = not _shop_manager.can_purchase_des_a_coudre(_run_manager)
		btn.pressed.connect(_on_des_a_coudre_pressed.bind(entry))
	else:
		var item: Variant = slot["item"]
		btn.text = "%s\n%s\n%d mouches" % [_category_label(slot["category"]), ShopManager.get_label(item), ShopManager.get_price(item)]
		btn.tooltip_text = ShopManager.get_description(item)
		btn.rarity = ShopManager.get_rarity(item)
		btn.disabled = not _shop_manager.can_purchase(item, _run_manager)
		btn.pressed.connect(_on_unitaire_pressed.bind(entry))

	return btn


func _category_label(category: String) -> String:
	match category:
		"sheet": return "PARTITION"
		"badge": return "BADGE"
		"special": return "SPÉCIAL"
		"button": return "BOUTON"
	return category.to_upper()


func _on_unitaire_pressed(entry: Dictionary) -> void:
	var slot: Dictionary = entry["slot"]
	if _shop_manager.purchase(slot["item"], _run_manager):
		entry["consumed"] = true
		(entry["button"] as Button).disabled = true


func _refresh_flies() -> void:
	flies_label.text = "MOUCHES : %d" % _run_manager.get_flies()


## Reevalue l'affordabilite de chaque slot NON consomme (les slots consommes
## restent desactives pour toujours, meme si le solde remonte).
func _refresh_buttons_state() -> void:
	for entry in _pack_entries:
		if entry["consumed"]:
			continue
		(entry["button"] as Button).disabled = not _shop_manager.can_purchase_pack(entry["slot"], _run_manager)

	for entry in _unitaire_entries:
		if entry["consumed"]:
			continue
		var slot: Dictionary = entry["slot"]
		var btn: Button = entry["button"]
		if slot["format"] == "des_a_coudre":
			btn.disabled = not _shop_manager.can_purchase_des_a_coudre(_run_manager)
		else:
			btn.disabled = not _shop_manager.can_purchase(slot["item"], _run_manager)

	_refresh_reroll_button()


func _on_purchased(_item) -> void:
	_refresh_buttons_state()


func _on_flies_changed(_amount: int) -> void:
	_refresh_flies()
	_refresh_buttons_state()


func _on_continue_pressed() -> void:
	RunService.advance_round()
	SceneRouter.go_to_game()


# --- Reroll (uniquement la rangee des unitaires, les packs restent fixes) ---

func _reroll_price() -> int:
	if _free_reroll_available:
		return 0
	return GameRules.REROLL_BASE_PRICE + _reroll_count * GameRules.REROLL_INCREMENT


func _refresh_reroll_button() -> void:
	if _free_reroll_available:
		reroll_button.text = "REROLL — GRATUIT"
		reroll_button.disabled = false
	else:
		reroll_button.text = "REROLL — %d mouches" % _reroll_price()
		reroll_button.disabled = _run_manager.get_flies() < _reroll_price()


func _on_reroll_pressed() -> void:
	if _free_reroll_available:
		_free_reroll_available = false  # consomme le reroll gratuit de la visite
	elif not _run_manager.spend_flies(_reroll_price()):
		return
	_reroll_count += 1
	_shop_manager.reroll_unitaires(_run_manager)
	_rebuild_unitaires()
	_refresh_reroll_button()


# --- Outils de deck (gates par Des a coudre) ---

## Tire les 3 actions ET les 8 candidats en meme temps, affiche tout dans le
## meme panneau — le joueur voit ce qu'il a sous la main avant de choisir
## quelle action appliquer (voir docs/brainstorms/brainstorm-outils-deck.md).
func _on_des_a_coudre_pressed(entry: Dictionary) -> void:
	if not _shop_manager.purchase_des_a_coudre(_run_manager):
		return
	entry["consumed"] = true
	(entry["button"] as Button).disabled = true
	_tool_choices = _shop_manager.draw_deck_tool_choices()
	target_panel.visible = true
	_rebuild_target_candidates()
	_rebuild_tool_actions()


func _rebuild_target_candidates() -> void:
	for btn in _target_candidate_buttons:
		btn.queue_free()
	_target_candidate_buttons.clear()
	_target_selected_indices.clear()
	_target_candidate_tokens.clear()

	for candidate in _run_manager.get_deck_tool_candidates(GameRules.DECK_TOOL_TARGET_DRAW_SIZE):
		var pool_index: int = candidate["index"] as int
		var token: TokenData = candidate["token"] as TokenData
		var btn: Button = Button.new()
		btn.text = "%s %s" % [TokenData.family_label(token.family), TokenData.value_label(token.value)]
		btn.toggle_mode = true
		btn.pressed.connect(_on_target_candidate_pressed.bind(pool_index, btn))
		target_candidates_container.add_child(btn)
		_target_candidate_buttons.append(btn)
		_target_candidate_tokens[pool_index] = token


func _rebuild_tool_actions() -> void:
	for btn in _tool_action_buttons:
		btn.queue_free()
	_tool_action_buttons.clear()

	for tool in _tool_choices:
		var btn: RarityButton = RarityButton.new()
		btn.text = tool.label
		btn.tooltip_text = tool.description
		btn.rarity = tool.rarity
		btn.pressed.connect(_on_tool_action_pressed.bind(tool))
		tool_actions_container.add_child(btn)
		_tool_action_buttons.append(btn)

	_refresh_tool_action_states()


## Selection libre : aucune contrainte a la selection elle-meme (contrairement
## au 1er jet), seules les actions se grisent/degrisent en fonction de ce qui
## est selectionne. Jusqu'a 2 boutons (le max requis par Fusionner).
func _on_target_candidate_pressed(pool_index: int, btn: Button) -> void:
	if btn.button_pressed:
		if _target_selected_indices.size() >= 2:
			btn.button_pressed = false
			return
		_target_selected_indices.append(pool_index)
	else:
		_target_selected_indices.erase(pool_index)
	_refresh_tool_action_states()


## Une action n'est activable que si le nombre de boutons selectionnes
## correspond exactement a son besoin (1, ou 2 pour Fusionner/Changer de
## famille) ET que la selection respecte sa contrainte (parite pour Scinder,
## plafond/plancher pour Augmenter/Reduire, famille differente pour Changer
## (les deux jetons cibles), somme <= 10 pour Fusionner).
func _refresh_tool_action_states() -> void:
	var selected_tokens: Array[TokenData] = []
	for idx in _target_selected_indices:
		selected_tokens.append(_target_candidate_tokens[idx] as TokenData)

	for i in range(_tool_choices.size()):
		(_tool_action_buttons[i] as Button).disabled = not _is_action_applicable(_tool_choices[i], selected_tokens)


func _is_action_applicable(tool: DeckToolData, tokens: Array[TokenData]) -> bool:
	if tokens.size() != tool.target_count():
		return false
	match tool.action:
		DeckToolData.Action.DECREASE:
			# Une figure (Valet+) ne se reduit pas : elle ne s'obtient que par
			# le score (voir RunManager.decrease_button_value).
			return tokens[0].value > GameRules.TOKEN_MIN_VALUE and tokens[0].value <= GameRules.MAX_BUTTON_VALUE
		DeckToolData.Action.INCREASE:
			return tokens[0].value < GameRules.MAX_BUTTON_VALUE
		DeckToolData.Action.SPLIT:
			return tokens[0].value % 2 == 0
		DeckToolData.Action.CHANGE_FAMILY:
			return tokens[0].family != tool.target_family and tokens[1].family != tool.target_family
		DeckToolData.Action.FUSE:
			return tokens[0].value + tokens[1].value <= GameRules.MAX_BUTTON_VALUE
		DeckToolData.Action.REMOVE:
			return true
		DeckToolData.Action.FIX_FIGURE:
			return tokens[0].value >= GameRules.MAX_BUTTON_VALUE and not tokens[0].locked
	return false


## Cliquer une action activee l'applique immediatement — pas de confirmation
## separee, le clic sur l'action EST la confirmation. Deja paye a l'achat du
## Des a coudre, un seul outil applique puis fermeture.
func _on_tool_action_pressed(tool: DeckToolData) -> void:
	match tool.action:
		DeckToolData.Action.INCREASE:
			_run_manager.increase_button_value(_target_selected_indices[0])
		DeckToolData.Action.DECREASE:
			_run_manager.decrease_button_value(_target_selected_indices[0])
		DeckToolData.Action.CHANGE_FAMILY:
			_run_manager.change_button_family(_target_selected_indices[0], tool.target_family)
			_run_manager.change_button_family(_target_selected_indices[1], tool.target_family)
		DeckToolData.Action.SPLIT:
			_run_manager.split_button(_target_selected_indices[0])
		DeckToolData.Action.REMOVE:
			_run_manager.remove_button(_target_selected_indices[0])
		DeckToolData.Action.FUSE:
			_run_manager.fuse_buttons(_target_selected_indices[0], _target_selected_indices[1])
		DeckToolData.Action.FIX_FIGURE:
			_run_manager.lock_button(_target_selected_indices[0])
	target_panel.visible = false


func _on_target_close_pressed() -> void:
	target_panel.visible = false
