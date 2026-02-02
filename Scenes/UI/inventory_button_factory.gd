extends Node
class_name InventoryButtonFactory

## Envanter UI buton olusturma fabrikasi.
## Transfer All ve Build butonlarini olusturur ve yonetir.

signal transfer_all_pressed()
signal build_pressed()

var _btn_build: Button = null
var _btn_transfer_all: Button = null

func get_btn_build() -> Button:
	return _btn_build

func get_btn_transfer_all() -> Button:
	return _btn_transfer_all

func create_buttons(action_buttons: HBoxContainer, close_btn: Button) -> void:
	_create_transfer_all_button(action_buttons)
	_create_build_button(action_buttons, close_btn)

func set_buttons_visible(visible: bool) -> void:
	if _btn_build:
		_btn_build.visible = visible
	if _btn_transfer_all:
		_btn_transfer_all.visible = visible

func update_transfer_all_state(ship_inv: InventoryComponent, base_inv: InventoryComponent) -> void:
	if not _btn_transfer_all:
		return
	var disabled := true
	if ship_inv and base_inv:
		disabled = ship_inv.is_empty() or base_inv.is_full()
	_apply_button_state(_btn_transfer_all, disabled)

func _apply_button_state(button: Button, disabled: bool) -> void:
	button.disabled = disabled
	button.modulate = Color(1, 1, 1, 0.5) if disabled else Color(1, 1, 1, 1)

# ============================================================
#  Transfer All
# ============================================================

func _create_transfer_all_button(action_buttons: HBoxContainer) -> void:
	if not action_buttons:
		return

	_btn_transfer_all = Button.new()
	_btn_transfer_all.text = "Transfer All"
	_btn_transfer_all.custom_minimum_size = Vector2(130, 36)
	_btn_transfer_all.visible = false

	var style := StyleBoxFlat.new()
	style.content_margin_left = 14.0
	style.content_margin_top = 6.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 6.0
	style.bg_color = Color(0.12, 0.52, 0.26, 0.95)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.2, 0.82, 0.45, 1.0)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	_btn_transfer_all.add_theme_stylebox_override("normal", style)

	var hover_style := style.duplicate()
	hover_style.bg_color = Color(0.14, 0.6, 0.3, 0.95)
	_btn_transfer_all.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := style.duplicate()
	pressed_style.bg_color = Color(0.08, 0.4, 0.2, 0.95)
	_btn_transfer_all.add_theme_stylebox_override("pressed", pressed_style)

	_btn_transfer_all.add_theme_color_override("font_color", Color(0.85, 1.0, 0.85))
	_btn_transfer_all.add_theme_font_size_override("font_size", 13)

	_btn_transfer_all.pressed.connect(_on_transfer_all_pressed)

	action_buttons.add_child(_btn_transfer_all)
	action_buttons.move_child(_btn_transfer_all, 0)

func _on_transfer_all_pressed() -> void:
	transfer_all_pressed.emit()

# ============================================================
#  Build Mode
# ============================================================

func _create_build_button(action_buttons: HBoxContainer, _close_btn: Button) -> void:
	if not action_buttons:
		return

	_btn_build = Button.new()
	_btn_build.text = "Build"
	_btn_build.custom_minimum_size = Vector2(110, 36)
	_btn_build.visible = false

	var style := StyleBoxFlat.new()
	style.content_margin_left = 14.0
	style.content_margin_top = 6.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 6.0
	style.bg_color = Color(0.0, 0.45, 0.55, 0.95)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.0, 0.75, 0.85, 1.0)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	_btn_build.add_theme_stylebox_override("normal", style)

	var hover_style := style.duplicate()
	hover_style.bg_color = Color(0.0, 0.55, 0.65, 0.95)
	_btn_build.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := style.duplicate()
	pressed_style.bg_color = Color(0.0, 0.35, 0.45, 0.95)
	_btn_build.add_theme_stylebox_override("pressed", pressed_style)

	_btn_build.add_theme_color_override("font_color", Color(0.0, 0.95, 1.0))
	_btn_build.add_theme_font_size_override("font_size", 13)

	_btn_build.pressed.connect(_on_build_pressed)

	# Close butonundan once ekle
	action_buttons.add_child(_btn_build)
	if _btn_transfer_all:
		action_buttons.move_child(_btn_build, 1)
	else:
		action_buttons.move_child(_btn_build, 0)

func _on_build_pressed() -> void:
	build_pressed.emit()
