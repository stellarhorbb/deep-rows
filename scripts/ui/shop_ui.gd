## Scene autonome du shop. Lit les managers via l'autoload RunService.
## Deux colonnes : Partitions+Echoes (A) / Boutons+Speciaux+Fusion (B).
## Quand le joueur clique "CONTINUER", avance le run et retourne au game.
class_name ShopUI
extends Control

@onready var tag_echo_container: VBoxContainer = $Panel/VBox/Columns/ColumnA/TagEchoContainer
@onready var button_offer_container: VBoxContainer = $Panel/VBox/Columns/ColumnB/ButtonOfferContainer
@onready var special_offer_container: VBoxContainer = $Panel/VBox/Columns/ColumnB/SpecialOfferContainer
@onready var fusion_button: Button = $Panel/VBox/Columns/ColumnB/FusionButton
@onready var flies_label: Label = $FliesLabel
@onready var continue_button: Button = $Panel/VBox/ContinueButton

@onready var fusion_panel: Control = $FusionPanel
@onready var fusion_candidates_container: GridContainer = $FusionPanel/Box/VBox/CandidatesContainer
@onready var fusion_confirm_button: Button = $FusionPanel/Box/VBox/ConfirmButton
@onready var fusion_close_button: Button = $FusionPanel/Box/VBox/CloseButton

var _run_manager: RunManager
var _shop_manager: ShopManager

var _resource_buttons: Array[Button] = []
var _button_offer_buttons: Array[Button] = []
var _fusion_candidate_buttons: Array[Button] = []
var _fusion_selected_indices: Array[int] = []


func _ready() -> void:
	_run_manager = RunService.run_manager
	_shop_manager = RunService.shop_manager

	_run_manager.flies_changed.connect(_on_flies_changed)
	_shop_manager.purchased.connect(_on_purchased)
	_shop_manager.button_purchased.connect(_on_button_purchased)
	continue_button.pressed.connect(_on_continue_pressed)
	fusion_button.pressed.connect(_on_fusion_button_pressed)
	fusion_confirm_button.pressed.connect(_on_fusion_confirm_pressed)
	fusion_close_button.pressed.connect(_on_fusion_close_pressed)

	_shop_manager.regenerate_offer(_run_manager)
	_refresh_flies()
	_rebuild_offer()


# --- Colonne A : Partitions + Echoes ---

func _rebuild_offer() -> void:
	for btn in _resource_buttons:
		btn.queue_free()
	_resource_buttons.clear()

	for item in _shop_manager.get_tag_echo_offer():
		var btn: Button = _make_resource_button(item)
		tag_echo_container.add_child(btn)
		_resource_buttons.append(btn)

	for btn in _button_offer_buttons:
		btn.queue_free()
	_button_offer_buttons.clear()

	for token in _shop_manager.get_button_offer():
		var btn: Button = Button.new()
		btn.text = "%s %d — %d mouches" % [TokenData.family_label(token.family), token.value, GameRules.BUTTON_UNIT_PRICE]
		btn.disabled = not _shop_manager.can_purchase_button(_run_manager)
		btn.pressed.connect(_on_button_offer_pressed.bind(token))
		button_offer_container.add_child(btn)
		_button_offer_buttons.append(btn)

	for item in _shop_manager.get_special_offer():
		var btn: Button = _make_resource_button(item)
		special_offer_container.add_child(btn)
		_resource_buttons.append(btn)


func _make_resource_button(item: Resource) -> Button:
	var btn: Button = Button.new()
	btn.text = "%s — %d mouches" % [ShopManager.get_label(item), ShopManager.get_price(item)]
	btn.tooltip_text = ShopManager.get_description(item)
	btn.disabled = not _shop_manager.can_purchase(item, _run_manager)
	btn.set_meta("item", item)
	btn.pressed.connect(_on_item_pressed.bind(item))
	return btn


func _refresh_flies() -> void:
	flies_label.text = "MOUCHES : %d" % _run_manager.get_flies()


## Les items Tags/Echoes/Speciaux achetes restent affiches mais se desactivent
## via can_purchase (deja equipe, plus assez de mouches) — pas de reroll ici,
## une seule visite = une seule offre tiree.
func _refresh_buttons_state() -> void:
	for i in range(_resource_buttons.size()):
		var item: Resource = _resource_buttons[i].get_meta("item") as Resource
		_resource_buttons[i].disabled = not _shop_manager.can_purchase(item, _run_manager)
	for btn in _button_offer_buttons:
		btn.disabled = not _shop_manager.can_purchase_button(_run_manager)


func _on_item_pressed(item: Resource) -> void:
	_shop_manager.purchase(item, _run_manager)


func _on_button_offer_pressed(token: TokenData) -> void:
	_shop_manager.purchase_button(token, _run_manager)


func _on_purchased(_item: Resource) -> void:
	_refresh_buttons_state()


func _on_button_purchased(_token: TokenData) -> void:
	_refresh_buttons_state()


func _on_flies_changed(_amount: int) -> void:
	_refresh_flies()
	_refresh_buttons_state()
	if fusion_panel.visible:
		_update_fusion_confirm_state()


func _on_continue_pressed() -> void:
	RunService.advance_round()
	SceneRouter.go_to_game()


# --- Fusion ---

func _on_fusion_button_pressed() -> void:
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
	var has_pair: bool = _fusion_selected_indices.size() == 2
	fusion_confirm_button.disabled = not has_pair or _run_manager.get_flies() < GameRules.FUSION_PRICE
	fusion_confirm_button.text = "FUSIONNER — %d mouches" % GameRules.FUSION_PRICE


func _on_fusion_confirm_pressed() -> void:
	if _fusion_selected_indices.size() != 2:
		return
	if not _run_manager.spend_flies(GameRules.FUSION_PRICE):
		return
	_run_manager.fuse_buttons(_fusion_selected_indices[0], _fusion_selected_indices[1])
	_rebuild_fusion_candidates()


func _on_fusion_close_pressed() -> void:
	fusion_panel.visible = false
