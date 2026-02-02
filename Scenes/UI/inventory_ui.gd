extends CanvasLayer
class_name InventoryUI

## Envanter UI - Surukle birak + sag tik split sistemi.
## Sol tik: item'i sec ve "elde tasi" moduna gec, tekrar sol tikla birak.
## Sag tik basili tut: split slider acar, mouse hareketiyle miktar sec, birakinca elde tasir.

const ITEM_DROP_SCENE := preload("res://Scenes/Items/item_drop.tscn")
const ITEM_ROW_SCRIPT := preload("res://Scenes/UI/inventory_item_row.gd")

var _ship_inventory: InventoryComponent = null
var _base_inventory: InventoryComponent = null
var _base_station: Node2D = null
var _player: Node2D = null
var _is_open: bool = false
var _selected_item_id: String = ""
var _selected_item_is_ship: bool = true

# --- Carry (elde tasima) modu ---
var _carrying: bool = false
var _carry_item_id: String = ""
var _carry_is_ship: bool = true
var _carry_amount: int = 0
var _carry_display_name: String = ""
var _carry_accent: Color = Color.WHITE
var _left_drag_active: bool = false

# --- Split slider modu ---
var _splitting: bool = false
var _split_item_id: String = ""
var _split_is_ship: bool = true
var _split_max: int = 0
var _split_amount: int = 0
var _split_row_rect: Rect2 = Rect2()

# Carry preview (mouse yaninda gosterilen kucuk panel)
var _carry_preview: PanelContainer = null
var _carry_preview_label: Label = null

# Split slider bar (minimal gorsel)
var _split_bar_bg: ColorRect = null  # arka plan
var _split_bar_fill: ColorRect = null  # dolu kisim
var _split_bar_label: Label = null  # miktar yazisi


# UI node referanslari
@onready var _root: Control = $Root
@onready var _ship_panel: PanelContainer = $Root/ShipPanel
@onready var _base_panel: PanelContainer = $Root/BasePanel
@onready var _action_panel: PanelContainer = $Root/ActionPanel
@onready var _ship_list: VBoxContainer = $Root/ShipPanel/Content/ListScroll/List
@onready var _ship_cap_label: Label = $Root/ShipPanel/Content/Header/HeaderRow/CapLabel
@onready var _ship_cap_bar: ProgressBar = $Root/ShipPanel/Content/CapBar/CapProgress
@onready var _base_list: VBoxContainer = $Root/BasePanel/Content/ListScroll/List
@onready var _base_cap_label: Label = $Root/BasePanel/Content/Header/HeaderRow/CapLabel
@onready var _base_cap_bar: ProgressBar = $Root/BasePanel/Content/CapBar/CapProgress
@onready var _btn_close: Button = $Root/ActionPanel/Actions/CloseBtn

## Build mode butonu (dinamik olusturulur)
var _btn_build: Button = null

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
	_create_carry_preview()
	_create_split_bar()
	_create_build_button()

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
	if player.has_node("ShipInventory"):
		var inv := player.get_node("ShipInventory") as InventoryComponent
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

func _open_with_base(player: Node2D, base: Node2D) -> void:
	if _is_open and base == _base_station:
		return
	_player = player
	_base_station = base

	if player.has_node("ShipInventory"):
		_ship_inventory = player.get_node("ShipInventory") as InventoryComponent
		if not _ship_inventory.changed.is_connected(_refresh_ui):
			_ship_inventory.changed.connect(_refresh_ui)

	if base.has_method("get_inventory"):
		_base_inventory = base.get_inventory()
		if _base_inventory and not _base_inventory.changed.is_connected(_refresh_ui):
			_base_inventory.changed.connect(_refresh_ui)

	_base_panel.visible = (_base_inventory != null)
	_action_panel.visible = (_base_inventory != null)
	_btn_close.visible = (_base_inventory != null)
	if _btn_build:
		_btn_build.visible = (_base_inventory != null)

	_is_open = true
	_show_ui()
	_selected_item_id = ""
	_cancel_carry()
	_refresh_ui()

func close_ui() -> void:
	_is_open = false
	_base_panel.visible = false
	_action_panel.visible = false
	_btn_close.visible = false
	if _btn_build:
		_btn_build.visible = false
	if _base_inventory and _base_inventory.changed.is_connected(_refresh_ui):
		_base_inventory.changed.disconnect(_refresh_ui)

	# Build UI'yi de kapat
	if _base_station and _base_station.has_method("hide_build_ui"):
		_base_station.hide_build_ui()

	_base_inventory = null
	_base_station = null
	_selected_item_id = ""
	_selected_item_is_ship = true
	_cancel_carry()
	_refresh_ui()

# ============================================================
#  INPUT
# ============================================================

func _input(event: InputEvent) -> void:
	# --- Split slider: sag tik birakma ---
	if _splitting and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			_finish_split()
			get_viewport().set_input_as_handled()
			return

	# --- Split slider: mouse hareketiyle miktar ayarla ---
	if _splitting and event is InputEventMouseMotion:
		_update_split_from_mouse(event.position.x)
		return

	# --- Carry modunda sol tik bas/cek birak ---
	if _carrying and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_left_drag_active = true
				get_viewport().set_input_as_handled()
				return
			if _left_drag_active:
				_left_drag_active = false
				_place_carried_item(event.position)
				get_viewport().set_input_as_handled()
				return
		# Sag tikla carry iptal
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_left_drag_active = false
			_return_carry_to_source()
			get_viewport().set_input_as_handled()
			return

	# --- Carry modunda ESC ile iptal ---
	if _carrying and event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_return_carry_to_source()
			get_viewport().set_input_as_handled()
			return

func _process(_delta: float) -> void:
	# Carry preview'i mouse'u takip etsin
	if _carrying and _carry_preview:
		var mouse_pos := get_viewport().get_mouse_position()
		_carry_preview.position = mouse_pos + Vector2(16, 8)
		_carry_preview.visible = true
	elif _carry_preview:
		_carry_preview.visible = false

	# Split bar gorunurlugu
	if _splitting:
		_split_bar_bg.visible = true
		_split_bar_fill.visible = true
		_split_bar_label.visible = true
	else:
		if _split_bar_bg:
			_split_bar_bg.visible = false
		if _split_bar_fill:
			_split_bar_fill.visible = false
		if _split_bar_label:
			_split_bar_label.visible = false

# ============================================================
#  SOL TIK - Tumunu carry moduna al
# ============================================================

func on_item_left_press(item_id: String, is_ship: bool) -> void:
	if _carrying or _splitting:
		return

	var source: InventoryComponent = _ship_inventory if is_ship else _base_inventory
	if not source:
		return
	var count := source.get_item_count(item_id)
	if count <= 0:
		return

	_start_carry(item_id, is_ship, count, source)
	_left_drag_active = _carrying

# ============================================================
#  SAG TIK - Basili tutarak split slider
# ============================================================

func on_item_right_press(item_id: String, is_ship: bool, row_rect: Rect2) -> void:
	if _carrying or _splitting:
		return

	var source: InventoryComponent = _ship_inventory if is_ship else _base_inventory
	if not source:
		return
	var count := source.get_item_count(item_id)
	if count <= 1:
		_start_carry(item_id, is_ship, count, source)
		return

	# Split modunu baslat
	_splitting = true
	_split_item_id = item_id
	_split_is_ship = is_ship
	_split_max = count
	_split_amount = count
	_split_row_rect = row_rect

	# Split bar'i row'un ustune, ortasina konumlandir (sabit genislik)
	var bar_x := row_rect.position.x + (row_rect.size.x - UITokens.SPLIT_BAR_WIDTH) * 0.5
	var bar_y := row_rect.position.y - UITokens.SPLIT_BAR_HEIGHT - 10.0
	_split_bar_bg.position = Vector2(bar_x, bar_y)
	_split_bar_bg.size = Vector2(UITokens.SPLIT_BAR_WIDTH, UITokens.SPLIT_BAR_HEIGHT)
	_split_bar_fill.position = Vector2(bar_x, bar_y)
	_split_bar_fill.size = Vector2(UITokens.SPLIT_BAR_WIDTH, UITokens.SPLIT_BAR_HEIGHT)
	_split_bar_label.position = Vector2(bar_x, bar_y - 18.0)
	_split_bar_label.size = Vector2(UITokens.SPLIT_BAR_WIDTH, 16.0)
	_update_split_visual()

func _update_split_from_mouse(mouse_x: float) -> void:
	var bar_left := _split_bar_bg.position.x
	var ratio := clampf((mouse_x - bar_left) / UITokens.SPLIT_BAR_WIDTH, 0.0, 1.0)
	_split_amount = maxi(ceili(ratio * _split_max), 1)
	_update_split_visual()

func _update_split_visual() -> void:
	var ratio := float(_split_amount) / float(maxi(_split_max, 1))
	_split_bar_fill.size.x = maxf(UITokens.SPLIT_BAR_WIDTH * ratio, 2.0)
	_split_bar_label.text = "%s / %s" % [
		UITokens.format_int(_split_amount),
		UITokens.format_int(_split_max)
	]

func _finish_split() -> void:
	if not _splitting:
		return
	var item_id := _split_item_id
	var is_ship := _split_is_ship
	var amount := _split_amount

	_splitting = false

	var source: InventoryComponent = _ship_inventory if is_ship else _base_inventory
	if not source:
		return
	var count := source.get_item_count(item_id)
	if count <= 0:
		return

	amount = mini(amount, count)
	if amount <= 0:
		return

	_start_carry(item_id, is_ship, amount, source)

# ============================================================
#  CARRY (elde tasima) sistemi
# ============================================================

func _start_carry(item_id: String, is_ship: bool, amount: int, source: InventoryComponent) -> void:
	var removed := source.remove_item(item_id, amount)
	if removed <= 0:
		return

	_carrying = true
	_carry_item_id = item_id
	_carry_is_ship = is_ship
	_carry_amount = removed

	var db := _get_db()
	_carry_display_name = item_id
	_carry_accent = Color(0.6, 0.78, 0.92)
	if db and db.has_item(item_id):
		var definition := db.get_item(item_id)
		if definition:
			_carry_display_name = definition.display_name
			_carry_accent = definition.color_hint

	_update_carry_preview()
	_selected_item_id = item_id
	_selected_item_is_ship = is_ship
	_refresh_ui()

func _cancel_carry() -> void:
	if not _carrying:
		return
	_return_carry_to_source()

func _return_carry_to_source() -> void:
	if not _carrying:
		return
	var source: InventoryComponent = _ship_inventory if _carry_is_ship else _base_inventory
	if source:
		source.add_item(_carry_item_id, _carry_amount)

	_carrying = false
	_carry_item_id = ""
	_carry_amount = 0
	_left_drag_active = false
	_carry_preview.visible = false
	_refresh_ui()

func _place_carried_item(screen_pos: Vector2) -> void:
	if not _carrying or _carry_amount <= 0:
		_carrying = false
		return

	var target := _get_drop_target(screen_pos)

	if target == "ship":
		if _ship_inventory:
			var added := _ship_inventory.add_item(_carry_item_id, _carry_amount)
			_carry_amount -= added
			if _carry_amount > 0:
				_return_remaining_to_source()
	elif target == "base":
		if _base_inventory:
			var added := _base_inventory.add_item(_carry_item_id, _carry_amount)
			_carry_amount -= added
			if _carry_amount > 0:
				_return_remaining_to_source()
	elif target == "world":
		_launch_item_to_world(_carry_item_id, _carry_amount, screen_pos, _carry_is_ship)
		_carry_amount = 0
	else:
		_return_remaining_to_source_full()

	if _carry_amount <= 0:
		_carrying = false
		_carry_item_id = ""
		_left_drag_active = false
		_carry_preview.visible = false

	_refresh_ui()

func _return_remaining_to_source() -> void:
	if _carry_amount <= 0:
		return
	var source: InventoryComponent = _ship_inventory if _carry_is_ship else _base_inventory
	if source:
		source.add_item(_carry_item_id, _carry_amount)
	_carry_amount = 0
	_left_drag_active = false

func _return_remaining_to_source_full() -> void:
	_return_remaining_to_source()
	_carrying = false
	_carry_item_id = ""
	_left_drag_active = false
	_carry_preview.visible = false

## Item'i gemiden hedef konuma dogru firlatir (gemiden oraya gider gibi)
func _launch_item_to_world(item_id: String, amount: int, screen_pos: Vector2, source_is_ship: bool) -> void:
	if amount <= 0:
		return
	var player := _get_player()
	var target_world := _screen_to_world(screen_pos)

	# Kaynak pozisyonu: gemiden veya base'den firlat
	var spawn_pos := target_world
	if source_is_ship:
		if player:
			spawn_pos = player.global_position
	elif _base_station:
		spawn_pos = _base_station.global_position

	var drop: Area2D = ITEM_DROP_SCENE.instantiate()
	drop.setup(item_id, amount, spawn_pos, true)  # no_scatter

	# Gemiden hedefe dogru firlatma yonu ve hizi ayarla
	var launch_origin := spawn_pos
	var direction := (target_world - launch_origin)
	var dist := direction.length()
	if dist > 5.0:
		drop.set_meta("launch_velocity", direction.normalized() * clampf(dist * 2.5, 150.0, 600.0))
		drop.set_meta("launch_target", target_world)

	var scene := get_tree().current_scene
	if scene:
		scene.add_child(drop)

# ============================================================
#  Carry Preview (mouse yaninda kucuk panel)
# ============================================================

func _create_carry_preview() -> void:
	_carry_preview = PanelContainer.new()
	_carry_preview.visible = false
	_carry_preview.z_index = 300
	_carry_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_carry_preview.custom_minimum_size = Vector2(0, 24)

	var style := StyleBoxFlat.new()
	style.bg_color = UITokens.COLOR_PANEL_BG
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = UITokens.COLOR_PANEL_BORDER
	style.corner_radius_top_left = UITokens.CARRY_PREVIEW_CORNER
	style.corner_radius_top_right = UITokens.CARRY_PREVIEW_CORNER
	style.corner_radius_bottom_right = UITokens.CARRY_PREVIEW_CORNER
	style.corner_radius_bottom_left = UITokens.CARRY_PREVIEW_CORNER
	style.content_margin_left = 8.0
	style.content_margin_top = 4.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 4.0
	_carry_preview.add_theme_stylebox_override("panel", style)

	_carry_preview_label = Label.new()
	_carry_preview_label.add_theme_color_override("font_color", UITokens.COLOR_TEXT_PRIMARY)
	_carry_preview_label.add_theme_font_size_override("font_size", UITokens.CARRY_PREVIEW_FONT_SIZE)
	_carry_preview.add_child(_carry_preview_label)

	_root.add_child(_carry_preview)

func _update_carry_preview() -> void:
	if not _carry_preview_label:
		return
	_carry_preview_label.text = "%s x%s" % [
		_carry_display_name,
		UITokens.format_int(_carry_amount)
	]
	var style: StyleBoxFlat = _carry_preview.get_theme_stylebox("panel").duplicate()
	style.border_color = Color(_carry_accent.r, _carry_accent.g, _carry_accent.b, 0.7)
	_carry_preview.add_theme_stylebox_override("panel", style)

# ============================================================
#  Split Bar (minimal ince bar + label)
# ============================================================

func _create_split_bar() -> void:
	# Arka plan bar (koyu ince cizgi)
	_split_bar_bg = ColorRect.new()
	_split_bar_bg.color = UITokens.COLOR_SPLIT_BG
	_split_bar_bg.size = Vector2(UITokens.SPLIT_BAR_WIDTH, UITokens.SPLIT_BAR_HEIGHT)
	_split_bar_bg.visible = false
	_split_bar_bg.z_index = 250
	_split_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_split_bar_bg)

	# Dolu kisim (parlak ince cizgi)
	_split_bar_fill = ColorRect.new()
	_split_bar_fill.color = UITokens.COLOR_SPLIT_FILL
	_split_bar_fill.size = Vector2(UITokens.SPLIT_BAR_WIDTH, UITokens.SPLIT_BAR_HEIGHT)
	_split_bar_fill.visible = false
	_split_bar_fill.z_index = 251
	_split_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_split_bar_fill)

	# Miktar yazisi (bar'in ustunde, kucuk font)
	_split_bar_label = Label.new()
	_split_bar_label.text = "0 / 0"
	_split_bar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_split_bar_label.add_theme_color_override("font_color", UITokens.COLOR_TEXT_SOFT)
	_split_bar_label.add_theme_font_size_override("font_size", 11)
	_split_bar_label.visible = false
	_split_bar_label.z_index = 252
	_split_bar_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_split_bar_label)

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
					_launch_item_to_world(item_id, removed, screen_pos, is_ship_source)
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
		var row := _create_item_row(item_id, count, db, true)
		_ship_list.add_child(row)
	if keys.is_empty():
		_add_empty_state(_ship_list)

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
		var row := _create_item_row(item_id, count, db, false)
		_base_list.add_child(row)
	if keys.is_empty():
		_add_empty_state(_base_list)

func _create_item_row(item_id: String, count: int, db: ItemDatabase, is_ship: bool) -> Control:
	var display_name := item_id
	var accent := Color(0.6, 0.78, 0.92)
	var unit_cost := 1
	var definition: ItemDefinition = null
	if db and db.has_item(item_id):
		definition = db.get_item(item_id)
		if definition:
			display_name = definition.display_name
			accent = definition.color_hint
			unit_cost = maxi(definition.capacity_cost, 1)

	var is_selected := (_selected_item_id == item_id and _selected_item_is_ship == is_ship)
	var row_panel := PanelContainer.new()
	row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_panel.custom_minimum_size = Vector2(0, 42)
	row_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	row_panel.set("theme_override_styles/panel", _create_row_style(accent, is_selected))
	row_panel.set_script(ITEM_ROW_SCRIPT)
	row_panel.call("configure", self, item_id, is_ship, display_name, accent)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.set("theme_override_constants/separation", 8)
	row_panel.add_child(row)

	var accent_bar := ColorRect.new()
	accent_bar.custom_minimum_size = Vector2(4, 0)
	accent_bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	accent_bar.color = Color(accent.r, accent.g, accent.b, 0.9 if is_selected else 0.35)
	row.add_child(accent_bar)

	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(32, 32)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	if definition and definition.icon:
		icon_rect.texture = definition.icon
	row.add_child(icon_rect)

	var text_stack := VBoxContainer.new()
	text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_stack.set("theme_override_constants/separation", 2)
	var name_label := Label.new()
	name_label.text = display_name
	name_label.add_theme_color_override(
		"font_color",
		accent if is_selected else UITokens.COLOR_TEXT_PRIMARY
	)
	var meta_label := Label.new()
	meta_label.text = "Unit: %s" % UITokens.format_int(unit_cost)
	meta_label.add_theme_color_override("font_color", UITokens.COLOR_TEXT_MUTED)
	text_stack.add_child(name_label)
	text_stack.add_child(meta_label)
	row.add_child(text_stack)

	var count_label := Label.new()
	count_label.text = "x%s" % UITokens.format_int(count)
	count_label.custom_minimum_size = Vector2(72, 0)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.add_theme_color_override("font_color", accent)
	row.add_child(count_label)

	return row_panel

# ============================================================
#  Yardimci fonksiyonlar
# ============================================================

func select_item(item_id: String, is_ship: bool) -> void:
	_selected_item_id = item_id
	_selected_item_is_ship = is_ship
	_refresh_ui()

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	var canvas := get_viewport().get_canvas_transform()
	return canvas.affine_inverse() * screen_pos

func _get_db() -> ItemDatabase:
	var tree := get_tree()
	if tree:
		var root := tree.root
		if root.has_node("ItemDB"):
			return root.get_node("ItemDB") as ItemDatabase
	return null

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

func _create_row_style(accent: Color, is_selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.18, 0.26, 0.95) if is_selected else Color(0.07, 0.1, 0.15, 0.78)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = accent if is_selected else Color(accent.r, accent.g, accent.b, 0.25)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 8.0
	style.content_margin_top = 6.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 6.0
	return style

func _add_empty_state(list: VBoxContainer) -> void:
	var empty := Label.new()
	empty.text = "Empty"
	empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty.custom_minimum_size = Vector2(0, 60)
	empty.add_theme_color_override("font_color", UITokens.COLOR_TEXT_MUTED)
	list.add_child(empty)

func _apply_button_state(button: Button, disabled: bool) -> void:
	button.disabled = disabled
	button.modulate = Color(1, 1, 1, 0.5) if disabled else Color(1, 1, 1, 1)

func _get_player() -> Node2D:
	var tree := get_tree()
	if tree and tree.current_scene:
		var scene_player := tree.current_scene.get_node_or_null("Player")
		if scene_player:
			return scene_player as Node2D
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0] as Node2D

# ============================================================
#  Build Mode
# ============================================================

func _create_build_button() -> void:
	# ActionPanel'in Actions HBox'ina Build butonu ekle
	var actions := _action_panel.get_node_or_null("Actions")
	if not actions:
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
	actions.add_child(_btn_build)
	actions.move_child(_btn_build, 0)

func _on_build_pressed() -> void:
	if not _base_station:
		return
	# BaseStation'daki build UI'yi ac
	if _base_station.has_method("show_build_ui"):
		_base_station.show_build_ui()
