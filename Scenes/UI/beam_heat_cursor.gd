extends CanvasLayer

@export var ring_radius := 10.0
@export var ring_width := 3.6
@export var ring_segments := 64
@export var heat_width_boost := 2.0
@export var label_offset := Vector2(0.0, 14.0)

@export var ring_bg_color := Color(0.9, 0.9, 0.9, 0.8)
@export var ring_cool_color := Color(1.0, 0.1, 0.1, 0.95)
@export var ring_hot_color := Color(1.0, 0.05, 0.05, 1.0)
@export var ring_overheat_color := Color(1.0, 0.0, 0.0, 1.0)

@export var pulse_speed := 8.0
@export var overheat_pulse_speed := 12.0

@onready var _root: Control = $Root
@onready var _ring: Node2D = $Root/Ring
@onready var _ring_bg: Line2D = $Root/Ring/RingBg
@onready var _ring_fill: Line2D = $Root/Ring/RingFill
@onready var _status_label: Label = $Root/StatusLabel

var _laser_beam: Node = null
var _mouse_hidden := false
var _pulse_time := 0.0

func _ready() -> void:
	_setup_lines()
	_refresh_background_ring()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_label.visible = false

func _exit_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta: float) -> void:
	var mouse_pos := get_viewport().get_mouse_position()
	var over_ui := _is_mouse_over_ui(mouse_pos)
	_set_mouse_hidden(not over_ui)
	_ring.visible = not over_ui
	if over_ui:
		_status_label.visible = false
		return

	_ring.global_position = mouse_pos
	_update_laser_beam()
	_update_ring(delta, mouse_pos)

func _update_ring(delta: float, mouse_pos: Vector2) -> void:
	_pulse_time += delta

	var heat_ratio: float = 0.0
	var overheated: bool = false
	var cooldown_progress: float = 0.0

	if _laser_beam:
		if _laser_beam.has_method("get_heat_ratio"):
			heat_ratio = float(_laser_beam.get_heat_ratio())
		if _laser_beam.has_method("is_overheated"):
			overheated = bool(_laser_beam.is_overheated())
		if _laser_beam.has_method("get_cooldown_progress"):
			cooldown_progress = float(_laser_beam.get_cooldown_progress())

	var ratio: float = heat_ratio
	var color: Color = ring_cool_color.lerp(ring_hot_color, clampf(heat_ratio, 0.0, 1.0))
	var width: float = ring_width + heat_ratio * heat_width_boost
	var label_text := ""

	if overheated:
		ratio = clampf(1.0 - cooldown_progress, 0.0, 1.0)
		var pulse: float = 0.5 + 0.5 * sin(_pulse_time * overheat_pulse_speed)
		color = ring_hot_color.lerp(ring_overheat_color, pulse)
		width = ring_width + heat_width_boost + pulse * 1.5
	elif heat_ratio >= 0.8:
		var pulse_hot: float = 0.5 + 0.5 * sin(_pulse_time * pulse_speed)
		color = color.lerp(ring_hot_color, 0.2 + 0.3 * pulse_hot)

	_ring_fill.default_color = color
	_ring_fill.width = width

	if ratio <= 0.01:
		_ring_fill.visible = false
		_ring_fill.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
	else:
		_ring_fill.visible = true
		_ring_fill.points = _build_arc_points(ring_radius, ratio, ring_segments)

	if label_text == "":
		_status_label.visible = false
	else:
		_status_label.text = label_text
		var label_size := _status_label.get_minimum_size()
		_status_label.size = label_size
		_status_label.position = mouse_pos + label_offset - label_size * 0.5
		_status_label.visible = true

func _setup_lines() -> void:
	_ring_bg.width = ring_width
	_ring_bg.default_color = ring_bg_color
	_ring_bg.closed = true
	_ring_bg.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_ring_bg.end_cap_mode = Line2D.LINE_CAP_ROUND
	_ring_bg.antialiased = true

	_ring_fill.width = ring_width
	_ring_fill.default_color = ring_cool_color
	_ring_fill.closed = false
	_ring_fill.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_ring_fill.end_cap_mode = Line2D.LINE_CAP_ROUND
	_ring_fill.antialiased = true

func _refresh_background_ring() -> void:
	_ring_bg.points = _build_circle_points(ring_radius, ring_segments)

func _build_circle_points(radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var seg_count := maxi(segments, 8)
	for i in range(seg_count):
		var angle := TAU * float(i) / float(seg_count)
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	return pts

func _build_arc_points(radius: float, ratio: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var clamped_ratio := clampf(ratio, 0.0, 1.0)
	if clamped_ratio <= 0.0:
		return pts
	var seg_count := maxi(segments, 8)
	var steps := maxi(int(ceil(seg_count * clamped_ratio)), 2)
	var start_angle := -PI * 0.5
	var end_angle := start_angle + TAU * clamped_ratio
	for i in range(steps):
		var t := float(i) / float(steps - 1)
		var angle: float = lerpf(start_angle, end_angle, t)
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	return pts

func _update_laser_beam() -> void:
	if _laser_beam and is_instance_valid(_laser_beam):
		return
	_laser_beam = null
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player := players[0]
	if player and player.has_node("LaserBeam"):
		_laser_beam = player.get_node("LaserBeam")

func _is_mouse_over_ui(mouse_pos: Vector2) -> bool:
	var inv := _get_inventory_ui()
	if not inv:
		return false
	var ship_panel: Control = inv.get_node_or_null("Root/ShipPanel")
	if ship_panel and ship_panel.visible and ship_panel.get_global_rect().has_point(mouse_pos):
		return true
	var base_panel: Control = inv.get_node_or_null("Root/BasePanel")
	if base_panel and base_panel.visible and base_panel.get_global_rect().has_point(mouse_pos):
		return true
	var action_panel: Control = inv.get_node_or_null("Root/ActionPanel")
	if action_panel and action_panel.visible and action_panel.get_global_rect().has_point(mouse_pos):
		return true
	return false

func _get_inventory_ui() -> Node:
	var tree := get_tree()
	if not tree:
		return null
	var scene := tree.current_scene
	if scene and scene.has_node("InventoryUI"):
		return scene.get_node("InventoryUI")
	return null

func _set_mouse_hidden(hidden: bool) -> void:
	if hidden == _mouse_hidden:
		return
	_mouse_hidden = hidden
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN if hidden else Input.MOUSE_MODE_VISIBLE)
