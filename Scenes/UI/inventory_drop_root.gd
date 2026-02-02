extends Control

@export var inventory_ui: InventoryUI

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var ui := inventory_ui
	return ui != null and ui.can_handle_drop(data)

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var ui := inventory_ui
	if ui == null:
		return
	var screen_pos := get_viewport().get_mouse_position()
	ui.handle_drop(screen_pos, data)
