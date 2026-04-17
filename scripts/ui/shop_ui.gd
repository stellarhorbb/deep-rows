## Scene autonome du shop. Lit les managers via l'autoload RunService.
## Quand le joueur clique "CONTINUER", avance le run et retourne au game.
class_name ShopUI
extends Control

@onready var items_container: VBoxContainer = $Panel/VBox/ItemsContainer
@onready var flies_label: Label = $FliesLabel
@onready var continue_button: Button = $Panel/VBox/ContinueButton

var _run_manager: RunManager
var _shop_manager: ShopManager
var _item_buttons: Array[Button] = []


func _ready() -> void:
	_run_manager = RunService.run_manager
	_shop_manager = RunService.shop_manager

	_run_manager.flies_changed.connect(_on_flies_changed)
	_shop_manager.purchased.connect(_on_purchased)
	continue_button.pressed.connect(_on_continue_pressed)

	_refresh_flies()
	_rebuild_items()


func _rebuild_items() -> void:
	for btn in _item_buttons:
		btn.queue_free()
	_item_buttons.clear()

	for item in _shop_manager.get_catalog():
		var btn: Button = Button.new()
		btn.text = _format_item(item)
		btn.disabled = not _shop_manager.can_purchase(item, _run_manager)
		btn.pressed.connect(_on_item_pressed.bind(item))
		items_container.add_child(btn)
		_item_buttons.append(btn)


func _format_item(item: ShopItem) -> String:
	return "%s — %d mouches" % [item.label, item.price]


func _refresh_flies() -> void:
	flies_label.text = "MOUCHES : %d" % _run_manager.get_flies()


func _refresh_buttons_state() -> void:
	var catalog: Array[ShopItem] = _shop_manager.get_catalog()
	for i in range(min(_item_buttons.size(), catalog.size())):
		_item_buttons[i].disabled = not _shop_manager.can_purchase(catalog[i], _run_manager)


func _on_item_pressed(item: ShopItem) -> void:
	_shop_manager.purchase(item, _run_manager)


func _on_purchased(_item: ShopItem) -> void:
	_refresh_buttons_state()


func _on_flies_changed(_amount: int) -> void:
	_refresh_flies()
	_refresh_buttons_state()


func _on_continue_pressed() -> void:
	RunService.advance_round()
	SceneRouter.go_to_game()
