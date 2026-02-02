extends Node
class_name InventoryCarryHandler

## Envanter carry (elde tasima) sistemi.
## Item'i kaynaktan alip mouse ile tasima ve birakma islemleri.

signal carry_started()
signal carry_ended()
signal refresh_requested()

const ITEM_DROP_SCENE := preload("res://Scenes/Items/item_drop.tscn")

var _carrying: bool = false
var _carry_item_id: String = ""
var _carry_is_ship: bool = true
var _carry_amount: int = 0
var _carry_display_name: String = ""
var _carry_accent: Color = Color.WHITE
var _left_drag_active: bool = false

# Carry preview (mouse yaninda gosterilen kucuk panel)
var _carry_preview: PanelContainer = null
var _carry_preview_label: Label = null

var _ui_root: Control = null

func setup(ui_root: Control) -> void:
	_ui_root = ui_root
	_create_carry_preview()

func is_carrying() -> bool:
	return _carrying

func get_carry_item_id() -> String:
	return _carry_item_id

func get_carry_is_ship() -> bool:
	return _carry_is_ship

func is_left_drag_active() -> bool:
	return _left_drag_active

func set_left_drag_active(active: bool) -> void:
	_left_drag_active = active

# ============================================================
#  CARRY (elde tasima) sistemi
# ============================================================

func start_carry(item_id: String, is_ship: bool, amount: int, source: InventoryComponent) -> void:
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
	carry_started.emit()
	refresh_requested.emit()

func cancel_carry() -> void:
	if not _carrying:
		return
	return_carry_to_source(null, null)

func return_carry_to_source(ship_inv: InventoryComponent, base_inv: InventoryComponent) -> void:
	if not _carrying:
		return
	var source: InventoryComponent = ship_inv if _carry_is_ship else base_inv
	if source:
		source.add_item(_carry_item_id, _carry_amount)

	_carrying = false
	_carry_item_id = ""
	_carry_amount = 0
	_left_drag_active = false
	_carry_preview.visible = false
	carry_ended.emit()
	refresh_requested.emit()

func place_carried_item(screen_pos: Vector2, drop_target: String, ship_inv: InventoryComponent, base_inv: InventoryComponent, player: Node2D, base_station: Node2D) -> void:
	if not _carrying or _carry_amount <= 0:
		_carrying = false
		return

	if drop_target == "ship":
		if ship_inv:
			var added := ship_inv.add_item(_carry_item_id, _carry_amount)
			_carry_amount -= added
			if _carry_amount > 0:
				_return_remaining_to_source(ship_inv, base_inv)
	elif drop_target == "base":
		if base_inv:
			var added := base_inv.add_item(_carry_item_id, _carry_amount)
			_carry_amount -= added
			if _carry_amount > 0:
				_return_remaining_to_source(ship_inv, base_inv)
	elif drop_target == "world":
		_launch_item_to_world(_carry_item_id, _carry_amount, screen_pos, _carry_is_ship, player, base_station)
		_carry_amount = 0
	else:
		_return_remaining_to_source_full(ship_inv, base_inv)

	if _carry_amount <= 0:
		_carrying = false
		_carry_item_id = ""
		_left_drag_active = false
		_carry_preview.visible = false

	refresh_requested.emit()

func _return_remaining_to_source(ship_inv: InventoryComponent, base_inv: InventoryComponent) -> void:
	if _carry_amount <= 0:
		return
	var source: InventoryComponent = ship_inv if _carry_is_ship else base_inv
	if source:
		source.add_item(_carry_item_id, _carry_amount)
	_carry_amount = 0
	_left_drag_active = false

func _return_remaining_to_source_full(ship_inv: InventoryComponent, base_inv: InventoryComponent) -> void:
	_return_remaining_to_source(ship_inv, base_inv)
	_carrying = false
	_carry_item_id = ""
	_left_drag_active = false
	_carry_preview.visible = false

## Item'i gemiden hedef konuma dogru firlatir (gemiden oraya gider gibi)
func _launch_item_to_world(item_id: String, amount: int, screen_pos: Vector2, source_is_ship: bool, player: Node2D, base_station: Node2D) -> void:
	if amount <= 0:
		return
	var target_world := _screen_to_world(screen_pos)

	# Kaynak pozisyonu: gemiden veya base'den firlat
	var spawn_pos := target_world
	if source_is_ship:
		if player:
			spawn_pos = player.global_position
	elif base_station:
		spawn_pos = base_station.global_position

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

func update_process(mouse_pos: Vector2) -> void:
	if _carrying and _carry_preview:
		_carry_preview.position = mouse_pos + Vector2(16, 8)
		_carry_preview.visible = true
	elif _carry_preview:
		_carry_preview.visible = false

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

	_ui_root.add_child(_carry_preview)

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
#  Yardimci
# ============================================================

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	var canvas := get_viewport().get_canvas_transform()
	return canvas.affine_inverse() * screen_pos

func _get_db() -> ItemDatabase:
	return ItemDB
