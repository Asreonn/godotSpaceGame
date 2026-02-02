extends Node
class_name InventoryRowFactory

## Envanter UI item row olusturma fabrikasi.
## Item satirlarini ve stil yardimcilarini yonetir.

const ITEM_ROW_SCRIPT := preload("res://Scenes/UI/inventory_item_row.gd")

func create_item_row(item_id: String, count: int, db: ItemDatabase, is_ship: bool, selected_item_id: String, selected_item_is_ship: bool, inventory_ui: InventoryUI) -> Control:
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

	var is_selected := (selected_item_id == item_id and selected_item_is_ship == is_ship)
	var row_panel := PanelContainer.new()
	row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_panel.custom_minimum_size = Vector2(0, 42)
	row_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	row_panel.set("theme_override_styles/panel", create_row_style(accent, is_selected))
	row_panel.set_script(ITEM_ROW_SCRIPT)
	row_panel.call("configure", inventory_ui, item_id, is_ship, display_name, accent)

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

func create_row_style(accent: Color, is_selected: bool) -> StyleBoxFlat:
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

func add_empty_state(list: VBoxContainer) -> void:
	var empty := Label.new()
	empty.text = "Empty"
	empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty.custom_minimum_size = Vector2(0, 60)
	empty.add_theme_color_override("font_color", UITokens.COLOR_TEXT_MUTED)
	list.add_child(empty)
