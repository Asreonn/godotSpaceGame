class_name BaseInfoTooltip
extends CanvasLayer

## Base disindayken mouse ile base uzerine hover edildiginde
## gozuken bilgi paneli. Ileride dusman bilgisi de eklenebilir.

const TOOLTIP_OFFSET := Vector2(20.0, 20.0)
const HOVER_CHECK_INTERVAL := 0.05  ## Saniye cinsinden hover kontrolu

var _player_inside_base: bool = false
var _hovered_base: BaseStation = null
var _hover_timer: float = 0.0

@onready var _panel: PanelContainer = $Panel
@onready var _title_label: Label = $Panel/Content/Header/HeaderRow/Title
@onready var _health_label: Label = $Panel/Content/Header/HeaderRow/HealthLabel
@onready var _health_bar: ProgressBar = $Panel/Content/HealthBar/HealthProgress
@onready var _info_list: VBoxContainer = $Panel/Content/InfoList

func _ready() -> void:
	layer = 150
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Events.player_entered_base_station.connect(_on_player_entered)
	Events.player_exited_base_station.connect(_on_player_exited)
	Events.base_health_changed.connect(_on_health_changed)

func _on_player_entered(_base: Node2D, _player: Node2D) -> void:
	_player_inside_base = true
	_hide_tooltip()

func _on_player_exited(_base: Node2D, _player: Node2D) -> void:
	_player_inside_base = false

func _on_health_changed(base: Node2D, current_hp: float, max_hp: float) -> void:
	if base == _hovered_base:
		_update_bar(current_hp, max_hp)

func _process(delta: float) -> void:
	if _player_inside_base:
		return

	_hover_timer += delta
	if _hover_timer >= HOVER_CHECK_INTERVAL:
		_hover_timer = 0.0
		_check_hover()

	if _hovered_base and _panel.visible:
		_update_tooltip_position()

func _check_hover() -> void:
	var mouse_screen := get_viewport().get_mouse_position()
	var camera := get_viewport().get_camera_2d()
	if not camera:
		_clear_hover()
		return

	# Ekran pozisyonunu dunya pozisyonuna cevir
	var canvas_transform := get_viewport().get_canvas_transform()
	var mouse_world := canvas_transform.affine_inverse() * mouse_screen

	# Tum base istasyonlarini kontrol et
	var best_base: BaseStation = null
	for node in get_tree().get_nodes_in_group("base_station"):
		if not node is BaseStation:
			continue
		var base := node as BaseStation
		var dist := mouse_world.distance_to(base.global_position)
		if dist <= base.trigger_radius:
			best_base = base
			break

	if best_base and not _hovered_base:
		_hovered_base = best_base
		_show_tooltip()
	elif not best_base and _hovered_base:
		_clear_hover()

func _show_tooltip() -> void:
	if not _hovered_base:
		return
	_update_health_display()
	_update_tooltip_position()
	_panel.visible = true
	_panel.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_panel, "modulate", Color(1, 1, 1, 1), 0.15)

func _hide_tooltip() -> void:
	if not _panel.visible:
		_hovered_base = null
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(_panel, "modulate", Color(1, 1, 1, 0), 0.12)
	tween.tween_callback(func() -> void:
		_panel.visible = false
		_hovered_base = null
	)

func _clear_hover() -> void:
	if _hovered_base:
		_hide_tooltip()

func _update_tooltip_position() -> void:
	var mouse_pos := get_viewport().get_mouse_position()
	var viewport_size := get_viewport().get_visible_rect().size
	var panel_size := _panel.size

	# Paneli mouse'un sag altina yerlestir, ekrandan tasmamasi icin ayarla
	var pos := mouse_pos + TOOLTIP_OFFSET
	if pos.x + panel_size.x > viewport_size.x:
		pos.x = mouse_pos.x - panel_size.x - TOOLTIP_OFFSET.x
	if pos.y + panel_size.y > viewport_size.y:
		pos.y = mouse_pos.y - panel_size.y - TOOLTIP_OFFSET.y

	_panel.position = pos

func _update_health_display() -> void:
	if not _hovered_base:
		return
	var current := _hovered_base.get_current_health()
	var max_hp := _hovered_base.get_max_health()
	_update_bar(current, max_hp)

func _update_bar(current_hp: float, max_hp: float) -> void:
	_health_bar.max_value = max_hp
	_health_bar.value = current_hp
	_health_label.text = "%s / %s" % [
		UITokens.format_int(int(current_hp)),
		UITokens.format_int(int(max_hp))
	]
	_apply_health_style(current_hp, max_hp)

func _apply_health_style(current_hp: float, max_hp: float) -> void:
	var ratio := 0.0 if max_hp <= 0.0 else current_hp / max_hp
	var color := Color(0.32, 0.85, 0.65)
	if ratio <= 0.25:
		color = Color(0.95, 0.25, 0.2)
	elif ratio <= 0.5:
		color = Color(0.95, 0.4, 0.25)
	elif ratio <= 0.75:
		color = Color(0.98, 0.74, 0.25)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.corner_radius_top_left = 6
	fill.corner_radius_top_right = 6
	fill.corner_radius_bottom_right = 6
	fill.corner_radius_bottom_left = 6
	_health_bar.add_theme_stylebox_override("fill", fill)
