class_name InputHandler
extends Node2D

@export var grid_visual: GridVisual
@export var stream_ui: StreamUI
@export var turn_controller: TurnController
@export var deck_manager: DeckManager
@export var grid_manager: GridManager



func _input(event: InputEvent) -> void:
	if grid_visual.is_animating():
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_H:
			turn_controller.request_hold()
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_handle_click(mouse_event.global_position)
			get_viewport().set_input_as_handled()


func _handle_click(global_pos: Vector2) -> void:
	# Check clic sur hold
	var stream_local: Vector2 = stream_ui.get_global_transform().affine_inverse() * global_pos
	if stream_ui.is_hold_click(stream_local):
		turn_controller.request_hold()
		return

	# Check clic sur grille
	var grid_local: Vector2 = grid_visual.get_global_transform().affine_inverse() * global_pos
	var grid_size: Vector2 = grid_visual.get_grid_pixel_size()

	if grid_local.x < 0.0 or grid_local.x > grid_size.x:
		return
	if grid_local.y < 0.0 or grid_local.y > grid_size.y:
		return

	var cell: Vector2i = grid_visual.pixel_to_grid(grid_local)
	turn_controller.play_current_to(cell.x, cell.y)
