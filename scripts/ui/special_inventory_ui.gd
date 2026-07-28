## Inventaire de speciaux possede par le joueur (session 25, remplace l'ancien
## systeme "special = jeton du deck", voir RunManager._special_inventory).
## Vit dans Shell (persistant, cable une seule fois comme SheetsUI/BadgesUI)
## pour rester visible/vendable sur tous les ecrans, pas seulement en manche.
## Meme squelette de dessin que StreamUI (Control + _draw(), TokenVisual pour
## les textures) mais empile verticalement plutot qu'horizontalement.
## Cliquer un slot occupe le selectionne (voir InputHandler) ; cliquer une
## colonne de la grille ensuite joue le special a la place du coup normal
## (TurnController.play_special_from_inventory). Bouton VENDRE par slot,
## meme pattern que BadgesUI.
class_name SpecialInventoryUI
extends Control

@export var cell_size: float = 80.0
@export var vertical_gap: float = 12.0
@export var label_font_size: int = 18
@export var label_color: Color = Color("3d3d5c")
@export var slot_bg_color: Color = Color.WHITE
@export var selected_border_color: Color = Color("e2b714")
@export var selected_border_width: float = 4.0
@export var sell_button_size: Vector2 = Vector2(80.0, 24.0)

@export var run_manager: RunManager

var _font: Font = null
var _selected_index: int = -1
var _sell_buttons: Array[Button] = []


func _ready() -> void:
	_font = load("res://assets/fonts/LondrinaSolid-Black.ttf") as Font
	_create_sell_buttons()


func setup() -> void:
	run_manager.special_inventory_changed.connect(_on_inventory_changed)
	queue_redraw()


## Un bouton par slot, cree une seule fois pour la capacite max — meme raison
## que BadgesUI._create_sell_buttons (evite de recreer/detruire des boutons a
## chaque changement d'inventaire).
func _create_sell_buttons() -> void:
	for i in range(GameRules.SPECIAL_INVENTORY_SLOTS):
		var btn: Button = Button.new()
		btn.text = "VENDRE"
		btn.visible = false
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_on_sell_pressed.bind(i))
		add_child(btn)
		_sell_buttons.append(btn)


func _on_sell_pressed(i: int) -> void:
	if run_manager == null:
		return
	var inventory: Array[TokenData.SpecialType] = run_manager.get_special_inventory()
	if i >= inventory.size():
		return
	var item: SpecialItem = RunService.shop_manager.get_special_item(inventory[i])
	var price: int = item.price if item != null else 0
	run_manager.sell_special(i, price)
	if _selected_index == i:
		_selected_index = -1


func _slots_y() -> float:
	return label_font_size + 6.0


func _draw() -> void:
	_draw_label("SPÉCIAUX")

	var y_offset: float = _slots_y()
	var inventory: Array[TokenData.SpecialType] = run_manager.get_special_inventory()
	var capacity: int = run_manager.get_special_inventory_capacity()

	for i in range(capacity):
		var slot_y: float = y_offset + i * (cell_size + vertical_gap + sell_button_size.y)
		var rect: Rect2 = Rect2(Vector2(0.0, slot_y), Vector2(cell_size, cell_size))
		draw_rect(rect, slot_bg_color, true)

		var is_filled: bool = i < inventory.size()
		if is_filled:
			var token: TokenData = TokenData.make_special(inventory[i])
			var tex: Texture2D = TokenVisual.get_texture(token)
			if tex != null:
				draw_texture_rect(tex, rect, false)

		if i == _selected_index:
			draw_rect(rect, selected_border_color, false, selected_border_width)

		_update_sell_button(i, slot_y, is_filled)


func _update_sell_button(i: int, slot_y: float, is_filled: bool) -> void:
	var btn: Button = _sell_buttons[i]
	btn.visible = is_filled
	if not is_filled:
		return
	btn.size = sell_button_size
	btn.position = Vector2(0.0, slot_y + cell_size + 4.0)


func _draw_label(text: String) -> void:
	if _font == null:
		return
	draw_string(_font, Vector2(0.0, label_font_size), text, HORIZONTAL_ALIGNMENT_LEFT, -1, label_font_size, label_color)


func _on_inventory_changed() -> void:
	if _selected_index >= run_manager.get_special_inventory().size():
		_selected_index = -1
	queue_redraw()


## Detecte si un clic (coordonnees locales) est sur un slot -- retourne
## l'index (0-based), ou -1 si aucun slot n'est touche. Ignore la zone du
## bouton VENDRE (gere par son propre signal `pressed`).
func slot_at(local_pos: Vector2) -> int:
	var y_offset: float = _slots_y()
	var capacity: int = run_manager.get_special_inventory_capacity()
	for i in range(capacity):
		var slot_y: float = y_offset + i * (cell_size + vertical_gap + sell_button_size.y)
		var rect: Rect2 = Rect2(Vector2(0.0, slot_y), Vector2(cell_size, cell_size))
		if rect.has_point(local_pos):
			return i
	return -1


## Selectionne/deselectionne un slot occupe -- ignore un clic sur un slot
## vide (rien a jouer). Un 2e clic sur le meme slot deselectionne.
func try_select(index: int) -> void:
	var inventory: Array[TokenData.SpecialType] = run_manager.get_special_inventory()
	if index < 0 or index >= inventory.size():
		return
	_selected_index = -1 if _selected_index == index else index
	queue_redraw()


func get_selected_index() -> int:
	return _selected_index


func clear_selection() -> void:
	if _selected_index != -1:
		_selected_index = -1
		queue_redraw()


## Reconstruit le TokenData du special selectionne (ou null si rien n'est
## selectionne) -- utilise par InputHandler pour montrer le bon fantome de
## preview sur la grille au survol, a la place du jeton du stream.
func get_selected_token() -> TokenData:
	if _selected_index < 0:
		return null
	var inventory: Array[TokenData.SpecialType] = run_manager.get_special_inventory()
	if _selected_index >= inventory.size():
		return null
	return TokenData.make_special(inventory[_selected_index])


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		tooltip_text = _tooltip_for_position((event as InputEventMouseMotion).position)


func _tooltip_for_position(pos: Vector2) -> String:
	if run_manager == null:
		return ""
	var slot: int = slot_at(pos)
	var inventory: Array[TokenData.SpecialType] = run_manager.get_special_inventory()
	if slot < 0 or slot >= inventory.size():
		return ""
	var item: SpecialItem = RunService.shop_manager.get_special_item(inventory[slot])
	if item == null:
		return ""
	var text: String = item.label
	if item.description != "":
		text += "\n" + item.description
	return text
