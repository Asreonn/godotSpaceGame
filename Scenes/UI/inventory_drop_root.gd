extends Control

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var ui := get_parent()
	return ui and ui.has_method("can_handle_drop") and ui.can_handle_drop(data)

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var ui := get_parent()
	if not ui or not ui.has_method("handle_drop"):
		return
	var screen_pos := get_viewport().get_mouse_position()
	ui.handle_drop(screen_pos, data)
