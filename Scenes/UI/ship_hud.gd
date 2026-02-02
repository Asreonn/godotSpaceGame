extends PanelContainer

## Ekranin ust kisminda gemi kapasite bilgisi gosterir.

var _inventory: InventoryComponent = null
@onready var _cap_label: Label = $Content/TopRow/CapLabel
@onready var _cap_bar: ProgressBar = $Content/CapBar
@onready var _items_label: Label = $Content/ItemsLabel

func _ready() -> void:
	_cap_label.text = "0 / 0"
	_items_label.text = ""
	_cap_bar.value = 0
	_cap_bar.max_value = 1
	_apply_bar_style(0, 1)

func _process(_delta: float) -> void:
	if not _inventory:
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			var player = players[0]
			var inv := player.get_inventory()
			if inv:
				_inventory = inv
				_inventory.changed.connect(_update_display)
				_update_display()
		return

func _update_display() -> void:
	if not _inventory:
		_cap_label.text = "0 / 0"
		_items_label.text = ""
		_cap_bar.value = 0
		_cap_bar.max_value = 1
		_apply_bar_style(0, 1)
		return

	var items := _inventory.get_items()
	var parts: Array[String] = []
	var db := _get_db()

	var keys := items.keys()
	keys.sort()
	for item_id in keys:
		var count: int = items.get(item_id, 0)
		var display: String = str(item_id)
		if db and db.has_item(item_id):
			display = db.get_item(item_id).display_name
		parts.append("%s x%d" % [display, count])

	var used := _inventory.get_used_capacity()
	var max_value := _inventory.max_capacity
	_cap_label.text = "%d / %d" % [used, max_value]
	_cap_bar.max_value = max_value
	_cap_bar.value = used
	_apply_bar_style(used, max_value)

	var items_text := "Empty"
	if not parts.is_empty():
		var shown: Array[String] = []
		var limit := mini(parts.size(), 4)
		for i in range(limit):
			shown.append(parts[i])
		if parts.size() > limit:
			shown.append("+%d more" % (parts.size() - limit))
		items_text = " | ".join(shown)
	_items_label.text = items_text

func _get_db() -> ItemDatabase:
	return ItemDB

func _apply_bar_style(used: int, max_value: int) -> void:
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
	_cap_bar.add_theme_stylebox_override("fill", fill)
