extends PanelContainer

var item_id: String = ""
var is_ship: bool = true
var display_name: String = ""
var accent: Color = Color(0.6, 0.78, 0.92)
var _ui: InventoryUI = null
var _hovered: bool = false

func configure(ui_ref: InventoryUI, new_item_id: String, new_is_ship: bool, p_name: String, color: Color) -> void:
	_ui = ui_ref
	item_id = new_item_id
	is_ship = new_is_ship
	display_name = p_name
	accent = color
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if _ui:
				_ui.on_item_left_press(item_id, is_ship)
				accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if _ui:
				_ui.on_item_right_press(item_id, is_ship, get_global_rect())
				accept_event()

func _on_mouse_entered() -> void:
	_hovered = true
	modulate = UITokens.COLOR_HOVER

func _on_mouse_exited() -> void:
	_hovered = false
	modulate = UITokens.COLOR_NORMAL
