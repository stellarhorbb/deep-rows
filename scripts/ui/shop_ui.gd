## Scene autonome du shop. Lit les managers via l'autoload RunService.
## v2 : deux rangees separees, a la Balatro — Packs (nombre fixe, jamais
## regeneres par le reroll) et Unitaires visibles (nombre fixe, regeneres a
## chaque reroll). "Des a coudre" est une categorie d'unitaire parmi d'autres,
## gate la Fusion (une seule fusion par achat).
## Quand le joueur clique "CONTINUER", avance le run et retourne au game.
class_name ShopUI
extends Control

@onready var packs_container: HBoxContainer = $Panel/VBox/PacksContainer
@onready var unitaires_container: HBoxContainer = $Panel/VBox/UnitairesContainer
@onready var flies_label: Label = $FliesLabel
@onready var continue_button: Button = $Panel/VBox/ContinueButton
@onready var reroll_button: Button = $RerollButton

@onready var pack_panel: PackPanelUI = $PackPanel

@onready var fusion_panel: Control = $FusionPanel
@onready var fusion_candidates_container: GridContainer = $FusionPanel/Box/VBox/CandidatesContainer
@onready var fusion_confirm_button: Button = $FusionPanel/Box/VBox/ConfirmButton
@onready var fusion_close_button: Button = $FusionPanel/Box/VBox/CloseButton

var _run_manager: RunManager
var _shop_manager: ShopManager

## Un entry par slot affiche : {"slot": Dictionary, "button": Button, "consumed": bool}.
## "consumed" reste vrai definitivement (achat fait / pack ouvert / des a coudre
## utilise), independamment du solde de mouches ensuite.
var _pack_entries: Array[Dictionary] = []
var _unitaire_entries: Array[Dictionary] = []
var _reroll_count: int = 0

var _fusion_candidate_buttons: Array[Button] = []
var _fusion_selected_indices: Array[int] = []


func _ready() -> void:
	_run_manager = RunService.run_manager
	_shop_manager = RunService.shop_manager

	_run_manager.flies_changed.connect(_on_flies_changed)
	_shop_manager.purchased.connect(_on_purchased)
	_shop_manager.button_purchased.connect(_on_purchased)
	continue_button.pressed.connect(_on_continue_pressed)
	reroll_button.pressed.connect(_on_reroll_pressed)
	pack_panel.item_chosen.connect(_on_pack_item_chosen)
	fusion_confirm_button.pressed.connect(_on_fusion_confirm_pressed)
	fusion_close_button.pressed.connect(_on_fusion_close_pressed)

	_reroll_count = 0
	_shop_manager.regenerate_offer(_run_manager)
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
	pack_panel.open_with(candidates, "PACK %s — choisis 1" % _category_label(slot["category"]))


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
		btn.text = "DÉS À COUDRE\nFusionne 2 boutons\n%d mouches" % slot["price"]
		btn.tooltip_text = "Débloque une fusion de boutons pour cette visite"
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
		"tag": return "PARTITION"
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
	return GameRules.REROLL_BASE_PRICE + _reroll_count * GameRules.REROLL_INCREMENT


func _refresh_reroll_button() -> void:
	reroll_button.text = "REROLL — %d mouches" % _reroll_price()
	reroll_button.disabled = _run_manager.get_flies() < _reroll_price()


func _on_reroll_pressed() -> void:
	if not _run_manager.spend_flies(_reroll_price()):
		return
	_reroll_count += 1
	_shop_manager.reroll_unitaires(_run_manager)
	_rebuild_unitaires()
	_refresh_reroll_button()


# --- Fusion (gatee par Des a coudre) ---

func _on_des_a_coudre_pressed(entry: Dictionary) -> void:
	if not _shop_manager.purchase_des_a_coudre(_run_manager):
		return
	entry["consumed"] = true
	(entry["button"] as Button).disabled = true
	fusion_panel.visible = true
	_rebuild_fusion_candidates()


func _rebuild_fusion_candidates() -> void:
	for btn in _fusion_candidate_buttons:
		btn.queue_free()
	_fusion_candidate_buttons.clear()
	_fusion_selected_indices.clear()

	for candidate in _run_manager.get_fusion_candidates(GameRules.FUSION_DRAW_SIZE):
		var pool_index: int = candidate["index"] as int
		var token: TokenData = candidate["token"] as TokenData
		var btn: Button = Button.new()
		btn.text = "%s %d" % [TokenData.family_label(token.family), token.value]
		btn.toggle_mode = true
		btn.pressed.connect(_on_fusion_candidate_pressed.bind(pool_index, btn))
		fusion_candidates_container.add_child(btn)
		_fusion_candidate_buttons.append(btn)

	_update_fusion_confirm_state()


func _on_fusion_candidate_pressed(pool_index: int, btn: Button) -> void:
	if btn.button_pressed:
		if _fusion_selected_indices.size() >= 2:
			btn.button_pressed = false
			return
		_fusion_selected_indices.append(pool_index)
	else:
		_fusion_selected_indices.erase(pool_index)
	_update_fusion_confirm_state()


func _update_fusion_confirm_state() -> void:
	fusion_confirm_button.disabled = _fusion_selected_indices.size() != 2
	fusion_confirm_button.text = "FUSIONNER"


## Deja payee a l'achat du Des a coudre — une seule fusion, puis fermeture.
func _on_fusion_confirm_pressed() -> void:
	if _fusion_selected_indices.size() != 2:
		return
	_run_manager.fuse_buttons(_fusion_selected_indices[0], _fusion_selected_indices[1])
	fusion_panel.visible = false


func _on_fusion_close_pressed() -> void:
	fusion_panel.visible = false
