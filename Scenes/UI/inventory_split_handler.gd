extends Node
class_name InventorySplitHandler

## Envanter split slider sistemi.
## Sag tik basili tutarak miktar secme islemleri.

signal split_finished(item_id: String, is_ship: bool, amount: int, source: InventoryComponent)

var _splitting: bool = false
var _split_item_id: String = ""
var _split_is_ship: bool = true
var _split_max: int = 0
var _split_amount: int = 0
var _split_row_rect: Rect2 = Rect2()

# Split slider bar (minimal gorsel)
var _split_bar_bg: ColorRect = null  # arka plan
var _split_bar_fill: ColorRect = null  # dolu kisim
var _split_bar_label: Label = null  # miktar yazisi

var _ui_root: Control = null

func setup(ui_root: Control) -> void:
	_ui_root = ui_root
	_create_split_bar()

func is_splitting() -> bool:
	return _splitting

func start_split(item_id: String, is_ship: bool, count: int, row_rect: Rect2) -> void:
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

func update_split_from_mouse(mouse_x: float) -> void:
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

func finish_split(ship_inv: InventoryComponent, base_inv: InventoryComponent) -> void:
	if not _splitting:
		return
	var item_id := _split_item_id
	var is_ship := _split_is_ship
	var amount := _split_amount

	_splitting = false

	var source: InventoryComponent = ship_inv if is_ship else base_inv
	if not source:
		return
	var count := source.get_item_count(item_id)
	if count <= 0:
		return

	amount = mini(amount, count)
	if amount <= 0:
		return

	split_finished.emit(item_id, is_ship, amount, source)

func update_process() -> void:
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
	_ui_root.add_child(_split_bar_bg)

	# Dolu kisim (parlak ince cizgi)
	_split_bar_fill = ColorRect.new()
	_split_bar_fill.color = UITokens.COLOR_SPLIT_FILL
	_split_bar_fill.size = Vector2(UITokens.SPLIT_BAR_WIDTH, UITokens.SPLIT_BAR_HEIGHT)
	_split_bar_fill.visible = false
	_split_bar_fill.z_index = 251
	_split_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_root.add_child(_split_bar_fill)

	# Miktar yazisi (bar'in ustunde, kucuk font)
	_split_bar_label = Label.new()
	_split_bar_label.text = "0 / 0"
	_split_bar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_split_bar_label.add_theme_color_override("font_color", UITokens.COLOR_TEXT_SOFT)
	_split_bar_label.add_theme_font_size_override("font_size", 11)
	_split_bar_label.visible = false
	_split_bar_label.z_index = 252
	_split_bar_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_root.add_child(_split_bar_label)
