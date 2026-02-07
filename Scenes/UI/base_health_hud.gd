class_name BaseHealthHUD
extends CanvasLayer

## Base icindeyken ekranin ustunde gozuken can paneli.
## Events bus uzerinden player_entered/exited ve base_health_changed dinler.

var _current_base: BaseStation = null

@onready var _panel: PanelContainer = $Panel
@onready var _title_label: Label = $Panel/Content/Header/HeaderRow/Title
@onready var _health_label: Label = $Panel/Content/Header/HeaderRow/HealthLabel
@onready var _health_bar: ProgressBar = $Panel/Content/HealthBar/HealthProgress

func _ready() -> void:
	layer = 100
	_panel.visible = false
	Events.player_entered_base_station.connect(_on_player_entered)
	Events.player_exited_base_station.connect(_on_player_exited)
	Events.base_health_changed.connect(_on_health_changed)

func _on_player_entered(base: Node2D, _player: Node2D) -> void:
	if not base is BaseStation:
		return
	_current_base = base as BaseStation
	_update_health_display()
	_show_hud()

func _on_player_exited(base: Node2D, _player: Node2D) -> void:
	if base == _current_base:
		_current_base = null
		_hide_hud()

func _on_health_changed(base: Node2D, current_hp: float, max_hp: float) -> void:
	if base == _current_base:
		_update_bar(current_hp, max_hp)

func _update_health_display() -> void:
	if not _current_base:
		return
	var current := _current_base.get_current_health()
	var max_hp := _current_base.get_max_health()
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
	var color := Color(0.32, 0.85, 0.65)  # Yesil - saglam
	if ratio <= 0.25:
		color = Color(0.95, 0.25, 0.2)  # Kirmizi - kritik
	elif ratio <= 0.5:
		color = Color(0.95, 0.4, 0.25)  # Turuncu - hasarli
	elif ratio <= 0.75:
		color = Color(0.98, 0.74, 0.25)  # Sari - orta
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.corner_radius_top_left = 6
	fill.corner_radius_top_right = 6
	fill.corner_radius_bottom_right = 6
	fill.corner_radius_bottom_left = 6
	_health_bar.add_theme_stylebox_override("fill", fill)

func _show_hud() -> void:
	_panel.visible = true
	_panel.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_panel, "modulate", Color(1, 1, 1, 1), 0.25)

func _hide_hud() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(_panel, "modulate", Color(1, 1, 1, 0), 0.2)
	tween.tween_callback(func() -> void: _panel.visible = false)
