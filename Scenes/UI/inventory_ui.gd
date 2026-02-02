extends CanvasLayer
class_name InventoryUI

## Envanter UI - Surukle birak + sag tik split sistemi.
## Sol tik: item'i sec ve "elde tasi" moduna gec, tekrar sol tikla birak.
## Sag tik basili tut: split slider acar, mouse hareketiyle miktar sec, birakinca elde tasir.

var _ship_inventory: InventoryComponent = null
var _base_inventory: InventoryComponent = null
var _base_station: BaseStation = null
var _player: Node2D = null
var _is_open: bool = false
var _selected_item_id: String = ""
var _selected_item_is_ship: bool = true

# Bilesenler
var _carry_handler: InventoryCarryHandler = null
var _split_handler: InventorySplitHandler = null
var _row_factory: InventoryRowFactory = null
var _button_factory: InventoryButtonFactory = null

# UI node referanslari
@onready var _root: Control = $Root
@onready var _ship_panel: PanelContainer = $Root/ShipPanel
@onready var _base_panel: PanelContainer = $Root/BasePanel
@onready var _action_panel: PanelContainer = $Root/ActionPanel
@onready var _action_buttons: HBoxContainer = $Root/ActionPanel/Actions
@onready var _ship_list: VBoxContainer = $Root/ShipPanel/Content/ListScroll/List
@onready var _ship_cap_label: Label = $Root/ShipPanel/Content/Header/HeaderRow/CapLabel
@onready var _ship_cap_bar: ProgressBar = $Root/ShipPanel/Content/CapBar/CapProgress
@onready var _base_list: VBoxContainer = $Root/BasePanel/Content/ListScroll/List
@onready var _base_cap_label: Label = $Root/BasePanel/Content/Header/HeaderRow/CapLabel
@onready var _base_cap_bar: ProgressBar = $Root/BasePanel/Content/CapBar/CapProgress
@onready var _btn_close: Button = $Root/ActionPanel/Actions/CloseBtn

func _ready() -> void:
	layer = 101
	_root.visible = true
	_root.mouse_filter = Control.MOUSE_FILTER_PASS
	_root.scale = Vector2.ONE
	_root.modulate = Color(1, 1, 1, 1)
	_base_panel.visible = false
	_action_panel.visible = false
	_btn_close.visible = false
	call_deferred("_update_root_pivot")
	_btn_close.pressed.connect(close_ui)
	call_deferred("_connect_player")
	_connect_bases()
	call_deferred("_connect_bases")
	get_tree().node_added.connect(_on_node_added)
	_setup_components()

func _setup_components() -> void:
	# Carry handler
	_carry_handler = InventoryCarryHandler.new()
	_carry_handler.name = "CarryHandler"
	add_child(_carry_handler)
	_carry_handler.setup(_root)
	_carry_handler.refresh_requested.connect(_refresh_ui)

	# Split handler
	_split_handler = InventorySplitHandler.new()
	_split_handler.name = "SplitHandler"
	add_child(_split_handler)
	_split_handler.setup(_root)
	_split_handler.split_finished.connect(_on_split_finished)

	# Row factory
	_row_factory = InventoryRowFactory.new()
	_row_factory.name = "RowFactory"
	add_child(_row_factory)

	# Button factory
	_button_factory = InventoryButtonFactory.new()
	_button_factory.name = "ButtonFactory"
	add_child(_button_factory)
	_button_factory.create_buttons(_action_buttons, _btn_close)
	_button_factory.transfer_all_pressed.connect(_on_transfer_all_pressed)
	_button_factory.build_pressed.connect(_on_build_pressed)

func _on_split_finished(item_id: String, is_ship: bool, amount: int, source: InventoryComponent) -> void:
	_carry_handler.start_carry(item_id, is_ship, amount, source)
	_selected_item_id = item_id
	_selected_item_is_ship = is_ship

func _on_node_added(node: Node) -> void:
	if node is BaseStation:
		_connect_base(node)
	if node.is_in_group("player"):
		call_deferred("_connect_player")

func _connect_player() -> void:
	var player := _get_player()
	if not player:
		return
	if _player != player:
		_player = player
	var inv: InventoryComponent = player.get_inventory()
	if inv and inv != _ship_inventory:
		if _ship_inventory and _ship_inventory.changed.is_connected(_refresh_ui):
			_ship_inventory.changed.disconnect(_refresh_ui)
		_ship_inventory = inv
		if not _ship_inventory.changed.is_connected(_refresh_ui):
			_ship_inventory.changed.connect(_refresh_ui)
	_refresh_ui()

func _connect_bases() -> void:
	for node in get_tree().get_nodes_in_group("base_station"):
		if node is BaseStation:
			_connect_base(node)

func _connect_base(base: BaseStation) -> void:
	if not base.player_entered.is_connected(_on_base_entered):
		base.player_entered.connect(_on_base_entered)
	if not base.player_exited.is_connected(_on_base_exited):
		base.player_exited.connect(_on_base_exited)
	if base.is_player_inside():
		var player := _get_player()
		if player:
			_open_with_base(player, base)

func _on_base_entered(base: BaseStation) -> void:
	var player := _get_player()
	if not player:
		return
	_open_with_base(player, base)

func _on_base_exited(base: BaseStation) -> void:
	if base == _base_station:
		close_ui()

func _open_with_base(player: Node2D, base: BaseStation) -> void:
	if _is_open and base == _base_station:
		return
	_player = player
	_base_station = base

	_ship_inventory = player.get_inventory()
	if _ship_inventory and not _ship_inventory.changed.is_connected(_refresh_ui):
		_ship_inventory.changed.connect(_refresh_ui)

	_base_inventory = base.get_inventory()
	if _base_inventory and not _base_inventory.changed.is_connected(_refresh_ui):
		_base_inventory.changed.connect(_refresh_ui)

	_base_panel.visible = (_base_inventory != null)
	_action_panel.visible = (_base_inventory != null)
	_btn_close.visible = (_base_inventory != null)
	_button_factory.set_buttons_visible(_base_inventory != null)

	_is_open = true
	_show_ui()
	_selected_item_id = ""
	_carry_handler.return_carry_to_source(_ship_inventory, _base_inventory)
	_refresh_ui()

func close_ui() -> void:
	_is_open = false
	_base_panel.visible = false
	_action_panel.visible = false
	_btn_close.visible = false
	_button_factory.set_buttons_visible(false)
	if _base_inventory and _base_inventory.changed.is_connected(_refresh_ui):
		_base_inventory.changed.disconnect(_refresh_ui)

	# Build UI'yi de kapat
	if _base_station:
		_base_station.hide_build_ui()

	_carry_handler.return_carry_to_source(_ship_inventory, _base_inventory)
	_base_inventory = null
	_base_station = null
	_selected_item_id = ""
	_selected_item_is_ship = true
	_refresh_ui()

# ============================================================
#  INPUT
# ============================================================

func _input(event: InputEvent) -> void:
	# --- Split slider: sag tik birakma ---
	if _split_handler.is_splitting() and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			_split_handler.finish_split(_ship_inventory, _base_inventory)
			get_viewport().set_input_as_handled()
			return

	# --- Split slider: mouse hareketiyle miktar ayarla ---
	if _split_handler.is_splitting() and event is InputEventMouseMotion:
		_split_handler.update_split_from_mouse(event.position.x)
		return

	# --- Carry modunda sol tik bas/cek birak ---
	if _carry_handler.is_carrying() and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_carry_handler.set_left_drag_active(true)
				get_viewport().set_input_as_handled()
				return
			if _carry_handler.is_left_drag_active():
				_carry_handler.set_left_drag_active(false)
				var drop_target := _get_drop_target(event.position)
				_carry_handler.place_carried_item(event.position, drop_target, _ship_inventory, _base_inventory, _player, _base_station)
				get_viewport().set_input_as_handled()
				return
		# Sag tikla carry iptal
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_carry_handler.set_left_drag_active(false)
			_carry_handler.return_carry_to_source(_ship_inventory, _base_inventory)
			get_viewport().set_input_as_handled()
			return

	# --- Carry modunda ESC ile iptal ---
	if _carry_handler.is_carrying() and event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_carry_handler.return_carry_to_source(_ship_inventory, _base_inventory)
			get_viewport().set_input_as_handled()
			return

func _process(_delta: float) -> void:
	var mouse_pos := get_viewport().get_mouse_position()
	_carry_handler.update_process(mouse_pos)
	_split_handler.update_process()

# ============================================================
#  SOL TIK - Tumunu carry moduna al
# ============================================================

func on_item_left_press(item_id: String, is_ship: bool) -> void:
	if _carry_handler.is_carrying() or _split_handler.is_splitting():
		return

	var source: InventoryComponent = _ship_inventory if is_ship else _base_inventory
	if not source:
		return
	var count := source.get_item_count(item_id)
	if count <= 0:
		return

	_carry_handler.start_carry(item_id, is_ship, count, source)
	_selected_item_id = item_id
	_selected_item_is_ship = is_ship
	if _carry_handler.is_carrying():
		_carry_handler.set_left_drag_active(true)

# ============================================================
#  SAG TIK - Basili tutarak split slider
# ============================================================

func on_item_right_press(item_id: String, is_ship: bool, row_rect: Rect2) -> void:
	if _carry_handler.is_carrying() or _split_handler.is_splitting():
		return

	var source: InventoryComponent = _ship_inventory if is_ship else _base_inventory
	if not source:
		return
	var count := source.get_item_count(item_id)
	if count <= 1:
		_carry_handler.start_carry(item_id, is_ship, count, source)
		_selected_item_id = item_id
		_selected_item_is_ship = is_ship
		return

	_split_handler.start_split(item_id, is_ship, count, row_rect)

# ============================================================
#  Eski drag-drop uyumlulugu (inventory_drop_root.gd icin)
# ============================================================

func can_handle_drop(data: Variant) -> bool:
	return data is Dictionary and data.has("item_id") and data.has("is_ship")

func handle_drop(screen_pos: Vector2, data: Dictionary) -> void:
	if not can_handle_drop(data):
		return
	var item_id: String = data.get("item_id", "")
	var is_ship_source: bool = data.get("is_ship", true)
	if item_id == "":
		return
	var target := _get_drop_target(screen_pos)
	if target == "ship":
		if not is_ship_source and _ship_inventory and _base_inventory:
			_transfer_item(_base_inventory, _ship_inventory, item_id)
	elif target == "base":
		if is_ship_source and _ship_inventory and _base_inventory:
			_transfer_item(_ship_inventory, _base_inventory, item_id)
	elif target == "world":
		var source: InventoryComponent = _ship_inventory if is_ship_source else _base_inventory
		if source:
			var count := source.get_item_count(item_id)
			if count > 0:
				var removed := source.remove_item(item_id, count)
				if removed > 0:
					_carry_handler._launch_item_to_world(item_id, removed, screen_pos, is_ship_source, _player, _base_station)
	_refresh_ui()

func notify_drag_start(item_id: String, is_ship: bool) -> void:
	_selected_item_id = item_id
	_selected_item_is_ship = is_ship

# ============================================================
#  Drop target tespiti
# ============================================================

func _get_drop_target(screen_pos: Vector2) -> String:
	if _ship_panel.get_global_rect().has_point(screen_pos):
		return "ship"
	if _base_panel.visible and _base_panel.get_global_rect().has_point(screen_pos):
		return "base"
	if _action_panel.visible and _action_panel.get_global_rect().has_point(screen_pos):
		return "none"
	return "world"

func is_mouse_over_ui(mouse_pos: Vector2) -> bool:
	if _ship_panel.get_global_rect().has_point(mouse_pos):
		return true
	if _base_panel.visible and _base_panel.get_global_rect().has_point(mouse_pos):
		return true
	if _action_panel.visible and _action_panel.get_global_rect().has_point(mouse_pos):
		return true
	return false

func _transfer_item(source: InventoryComponent, target: InventoryComponent, item_id: String) -> void:
	if not source or not target:
		return
	var count := source.get_item_count(item_id)
	if count <= 0:
		return
	source.transfer_to(target, item_id, count)

# ============================================================
#  UI Refresh
# ============================================================

func _refresh_ui() -> void:
	_refresh_ship_side()
	_refresh_base_side()
	if _selected_item_id != "":
		var inv := _ship_inventory if _selected_item_is_ship else _base_inventory
		if not inv or inv.get_item_count(_selected_item_id) <= 0:
			_selected_item_id = ""
	_button_factory.update_transfer_all_state(_ship_inventory, _base_inventory)

func _refresh_ship_side() -> void:
	for child in _ship_list.get_children():
		child.queue_free()

	if not _ship_inventory:
		_update_capacity_bar(_ship_cap_bar, _ship_cap_label, 0, 0)
		return

	_update_capacity_bar(
		_ship_cap_bar,
		_ship_cap_label,
		_ship_inventory.get_used_capacity(),
		_ship_inventory.max_capacity
	)

	var items := _ship_inventory.get_items()
	var db := _get_db()
	var keys := items.keys()
	keys.sort()
	for item_id in keys:
		var count: int = items.get(item_id, 0)
		var row := _row_factory.create_item_row(item_id, count, db, true, _selected_item_id, _selected_item_is_ship, self)
		_ship_list.add_child(row)
	if keys.is_empty():
		_row_factory.add_empty_state(_ship_list)

func _refresh_base_side() -> void:
	for child in _base_list.get_children():
		child.queue_free()

	if not _base_inventory:
		_update_capacity_bar(_base_cap_bar, _base_cap_label, 0, 0)
		return

	_update_capacity_bar(
		_base_cap_bar,
		_base_cap_label,
		_base_inventory.get_used_capacity(),
		_base_inventory.max_capacity
	)

	var items := _base_inventory.get_items()
	var db := _get_db()
	var keys := items.keys()
	keys.sort()
	for item_id in keys:
		var count: int = items.get(item_id, 0)
		var row := _row_factory.create_item_row(item_id, count, db, false, _selected_item_id, _selected_item_is_ship, self)
		_base_list.add_child(row)
	if keys.is_empty():
		_row_factory.add_empty_state(_base_list)

# ============================================================
#  Yardimci fonksiyonlar
# ============================================================

func select_item(item_id: String, is_ship: bool) -> void:
	_selected_item_id = item_id
	_selected_item_is_ship = is_ship
	_refresh_ui()

func _get_db() -> ItemDatabase:
	return ItemDB

func _update_root_pivot() -> void:
	_root.pivot_offset = _root.size * 0.5

func _show_ui() -> void:
	if not _base_inventory:
		return
	_base_panel.visible = true
	_action_panel.visible = true
	_base_panel.modulate = Color(1, 1, 1, 0)
	_action_panel.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_base_panel, "modulate", Color(1, 1, 1, 1), 0.2)
	tween.parallel().tween_property(_action_panel, "modulate", Color(1, 1, 1, 1), 0.2)

func _update_capacity_bar(bar: ProgressBar, label: Label, used: int, max_value: int) -> void:
	label.text = "%s / %s" % [
		UITokens.format_int(used),
		UITokens.format_int(max_value)
	]
	bar.max_value = max_value
	bar.value = used
	_apply_capacity_style(bar, used, max_value)

func _apply_capacity_style(bar: ProgressBar, used: int, max_value: int) -> void:
	var ratio := 0.0 if max_value <= 0 else float(used) / float(max_value)
	var color := Color(0.32, 0.85, 0.65)
	if ratio >= 0.85:
		color = Color(0.95, 0.4, 0.25)
	elif ratio >= 0.6:
		color = Color(0.98, 0.74, 0.25)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.corner_radius_top_left = 6
	fill.corner_radius_top_right = 6
	fill.corner_radius_bottom_right = 6
	fill.corner_radius_bottom_left = 6
	bar.add_theme_stylebox_override("fill", fill)

func _get_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0] as Node2D

# ============================================================
#  Buton olaylari
# ============================================================

func _on_transfer_all_pressed() -> void:
	if _carry_handler.is_carrying() or _split_handler.is_splitting():
		return
	if not _ship_inventory or not _base_inventory:
		return
	_ship_inventory.transfer_all_to(_base_inventory)
	_refresh_ui()

func _on_build_pressed() -> void:
	if not _base_station:
		return
	if _base_station:
		_base_station.show_build_ui()
