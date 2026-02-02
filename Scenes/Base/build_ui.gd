class_name BuildUI
extends CanvasLayer

## Build menusu UI - Base'e girildiginde dock'un icinde gosterilir.
## Modul secimi, maliyet gosterimi ve build mode acma/kapama.

signal build_mode_requested(module_def_id: String)
signal build_mode_closed()

var _manager: ModularBaseManager = null
var _base_inventory: InventoryComponent = null
var _is_open: bool = false

## UI node referanslari
var _root: PanelContainer = null
var _title_label: Label = null
var _module_list: VBoxContainer = null
var _close_btn: Button = null
var _info_label: Label = null

# -------------------------------------------------------
#  Baslatma
# -------------------------------------------------------

func _ready() -> void:
	layer = 102
	_build_ui()
	hide_ui()

func setup(manager: ModularBaseManager, inventory: InventoryComponent) -> void:
	_manager = manager
	_base_inventory = inventory
	_refresh_module_list()

# -------------------------------------------------------
#  UI Olusturma
# -------------------------------------------------------

func _build_ui() -> void:
	# Root panel
	_root = PanelContainer.new()
	_root.name = "BuildRoot"
	_root.anchor_left = 0.5
	_root.anchor_right = 0.5
	_root.anchor_top = 0.0
	_root.anchor_bottom = 0.0
	_root.offset_left = -180.0
	_root.offset_right = 180.0
	_root.offset_top = 20.0
	_root.offset_bottom = 0.0
	_root.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_root.mouse_filter = Control.MOUSE_FILTER_STOP

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.1, 0.92)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.0, 0.7, 0.8, 0.6)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.content_margin_left = 14.0
	style.content_margin_top = 12.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 14.0
	_root.add_theme_stylebox_override("panel", style)
	add_child(_root)

	# Ana VBox
	var vbox := VBoxContainer.new()
	vbox.set("theme_override_constants/separation", 10)
	_root.add_child(vbox)

	# Baslik
	var header := HBoxContainer.new()
	header.set("theme_override_constants/separation", 8)
	vbox.add_child(header)

	_title_label = Label.new()
	_title_label.text = "BUILD"
	_title_label.add_theme_color_override("font_color", Color(0.0, 0.85, 0.9))
	_title_label.add_theme_font_size_override("font_size", 16)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)

	_close_btn = Button.new()
	_close_btn.text = "X"
	_close_btn.custom_minimum_size = Vector2(28, 28)
	_close_btn.add_theme_color_override("font_color", UITokens.COLOR_TEXT_MUTED)
	_close_btn.add_theme_font_size_override("font_size", 12)
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color(0.15, 0.08, 0.08, 0.6)
	close_style.corner_radius_top_left = 4
	close_style.corner_radius_top_right = 4
	close_style.corner_radius_bottom_right = 4
	close_style.corner_radius_bottom_left = 4
	_close_btn.add_theme_stylebox_override("normal", close_style)
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Ayirici cizgi
	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", Color(0.0, 0.7, 0.8, 0.3))
	vbox.add_child(sep)

	# Modul listesi
	_module_list = VBoxContainer.new()
	_module_list.set("theme_override_constants/separation", 6)
	vbox.add_child(_module_list)

	# Info label
	_info_label = Label.new()
	_info_label.text = "Modul sec ve yerlestir"
	_info_label.add_theme_color_override("font_color", UITokens.COLOR_TEXT_MUTED)
	_info_label.add_theme_font_size_override("font_size", 11)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_info_label)

# -------------------------------------------------------
#  Modul listesi
# -------------------------------------------------------

func _refresh_module_list() -> void:
	if not _module_list:
		return

	# Mevcut butonlari temizle
	for child in _module_list.get_children():
		child.queue_free()

	if not _manager:
		return

	var defs: Array[ModuleDefinition] = _manager.get_all_module_defs()
	for i in range(defs.size()):
		var definition: ModuleDefinition = defs[i]
		var row: PanelContainer = _create_module_row(definition)
		_module_list.add_child(row)

func _create_module_row(definition: ModuleDefinition) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 52)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.1, 0.15, 0.85)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(0.0, 0.6, 0.7, 0.3)
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.content_margin_left = 10.0
	panel_style.content_margin_top = 6.0
	panel_style.content_margin_right = 10.0
	panel_style.content_margin_bottom = 6.0
	panel.add_theme_stylebox_override("panel", panel_style)

	var hbox := HBoxContainer.new()
	hbox.set("theme_override_constants/separation", 10)
	panel.add_child(hbox)

	# Sol: Modul bilgisi
	var text_stack := VBoxContainer.new()
	text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_stack.set("theme_override_constants/separation", 2)

	var name_label := Label.new()
	name_label.text = definition.display_name
	name_label.add_theme_color_override("font_color", UITokens.COLOR_TEXT_PRIMARY)
	name_label.add_theme_font_size_override("font_size", 13)
	text_stack.add_child(name_label)

	# Maliyet gosterimi
	var cost_text := ""
	for item_id in definition.build_cost.keys():
		var amount: int = definition.build_cost[item_id]
		if cost_text != "":
			cost_text += ", "
		cost_text += "%s x%d" % [item_id.capitalize(), amount]
	if cost_text == "":
		cost_text = "Free"

	var cost_label := Label.new()
	cost_label.text = cost_text
	cost_label.add_theme_color_override("font_color", UITokens.COLOR_TEXT_MUTED)
	cost_label.add_theme_font_size_override("font_size", 11)
	text_stack.add_child(cost_label)

	hbox.add_child(text_stack)

	# Sag: Build butonu
	var build_btn := Button.new()
	build_btn.text = "BUILD"
	build_btn.custom_minimum_size = Vector2(70, 32)
	build_btn.add_theme_font_size_override("font_size", 11)

	# Yeterli kaynak var mi kontrol et
	var can_afford := definition.can_afford(_base_inventory)

	var btn_style := StyleBoxFlat.new()
	if can_afford:
		btn_style.bg_color = Color(0.0, 0.5, 0.55, 0.7)
		build_btn.add_theme_color_override("font_color", Color(0.0, 0.95, 1.0))
	else:
		btn_style.bg_color = Color(0.2, 0.15, 0.15, 0.5)
		build_btn.add_theme_color_override("font_color", Color(0.5, 0.4, 0.4))
		build_btn.disabled = true

	btn_style.corner_radius_top_left = 4
	btn_style.corner_radius_top_right = 4
	btn_style.corner_radius_bottom_right = 4
	btn_style.corner_radius_bottom_left = 4
	build_btn.add_theme_stylebox_override("normal", btn_style)

	var hover_style := btn_style.duplicate()
	hover_style.bg_color = Color(0.0, 0.6, 0.65, 0.85)
	build_btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := btn_style.duplicate()
	pressed_style.bg_color = Color(0.0, 0.4, 0.45, 0.9)
	build_btn.add_theme_stylebox_override("pressed", pressed_style)

	var disabled_style := btn_style.duplicate()
	disabled_style.bg_color = Color(0.15, 0.1, 0.1, 0.4)
	build_btn.add_theme_stylebox_override("disabled", disabled_style)

	# Butona tiklaninca build mode baslat
	var def_id := definition.id
	build_btn.pressed.connect(func(): _on_build_pressed(def_id))

	hbox.add_child(build_btn)

	return panel

# -------------------------------------------------------
#  Olaylar
# -------------------------------------------------------

func _on_build_pressed(def_id: String) -> void:
	build_mode_requested.emit(def_id)

func _on_close_pressed() -> void:
	build_mode_closed.emit()
	hide_ui()

# -------------------------------------------------------
#  Goster / Gizle
# -------------------------------------------------------

func show_ui() -> void:
	_is_open = true
	_root.visible = true
	_refresh_module_list()

func hide_ui() -> void:
	_is_open = false
	if _root:
		_root.visible = false

func is_open() -> bool:
	return _is_open

func refresh() -> void:
	if _is_open:
		_refresh_module_list()
