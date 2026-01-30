extends ParallaxBackground

const StarTwinkle = preload("res://Scripts/star_twinkle.gd")

@export var spawn_rect_size := Vector2(2400, 1400)
@export var layer_counts := PackedInt32Array([45, 30, 20])
@export var layer_motion_scales: Array[Vector2] = [
	Vector2(0.2, 0.2),
	Vector2(0.45, 0.45),
	Vector2(0.7, 0.7)
]
@export var layer_scale_ranges: Array[Vector2] = [
	Vector2(0.15, 0.35),
	Vector2(0.25, 0.55),
	Vector2(0.4, 0.8)
]
@export var twinkle_speed_range := Vector2(1.6, 2.4)
@export var rotation_speed_range := Vector2(-1.2, 1.2)
@export var brightness_range := Vector2(0.45, 0.8)
@export var seed := 0
@export var use_player_center := true
@export var player_path: NodePath
@export var star_texture: Texture2D = preload("res://Assets/Background/Star.png")

var _rng := RandomNumberGenerator.new()
var _rect_size := Vector2.ZERO

func _ready() -> void:
	if seed != 0:
		_rng.seed = seed
	else:
		_rng.randomize()

	_rect_size = _get_rect_size()
	var center := _get_spawn_center()
	if star_texture == null:
		star_texture = preload("res://Assets/Background/Star.png")

	var layers := _get_layers()
	for i in range(layers.size()):
		var layer := layers[i]
		layer.motion_scale = _get_motion_scale(i)
		layer.motion_mirroring = _rect_size
		var container := _get_or_create_container(layer)
		_spawn_stars(container, _rect_size, center, _get_layer_count(i), _get_scale_range(i), layer.motion_scale)

func _get_layers() -> Array[ParallaxLayer]:
	var layers: Array[ParallaxLayer] = []
	for child in get_children():
		if child is ParallaxLayer:
			layers.append(child)
	return layers

func _get_rect_size() -> Vector2:
	if spawn_rect_size.x > 0.0 and spawn_rect_size.y > 0.0:
		return spawn_rect_size
	var viewport := get_viewport()
	if viewport == null:
		return Vector2(2400, 1400)
	return viewport.get_visible_rect().size * 2.0

func _get_spawn_center() -> Vector2:
	if not use_player_center:
		return Vector2.ZERO
	if player_path == NodePath():
		return Vector2.ZERO
	var player := get_node_or_null(player_path)
	if player is Node2D:
		return (player as Node2D).global_position
	return Vector2.ZERO

func _get_layer_count(index: int) -> int:
	if layer_counts.size() == 0:
		return 0
	if index < layer_counts.size():
		return layer_counts[index]
	return layer_counts[layer_counts.size() - 1]

func _get_motion_scale(index: int) -> Vector2:
	if layer_motion_scales.size() == 0:
		return Vector2(0.5, 0.5)
	if index < layer_motion_scales.size():
		return layer_motion_scales[index]
	return layer_motion_scales[layer_motion_scales.size() - 1]

func _get_scale_range(index: int) -> Vector2:
	if layer_scale_ranges.size() == 0:
		return Vector2(0.3, 0.6)
	if index < layer_scale_ranges.size():
		return layer_scale_ranges[index]
	return layer_scale_ranges[layer_scale_ranges.size() - 1]

func _get_or_create_container(layer: ParallaxLayer) -> Node2D:
	var container := layer.get_node_or_null("Stars")
	if container is Node2D:
		return container as Node2D
	container = Node2D.new()
	container.name = "Stars"
	layer.add_child(container)
	return container

func _spawn_stars(
		container: Node2D,
		rect_size: Vector2,
		center: Vector2,
		count: int,
		scale_range: Vector2,
		motion_scale: Vector2
	) -> void:
	for i in range(count):
		_spawn_star(container, rect_size, center, scale_range, motion_scale)

func _spawn_star(
		container: Node2D,
		rect_size: Vector2,
		center: Vector2,
		scale_range: Vector2,
		motion_scale: Vector2
	) -> void:
	var spawn_center := center
	if use_player_center:
		spawn_center = Vector2(center.x * motion_scale.x, center.y * motion_scale.y)
	var star := StarTwinkle.new()
	star.centered = true
	star.position = spawn_center + Vector2(
		_rng.randf_range(-rect_size.x * 0.5, rect_size.x * 0.5),
		_rng.randf_range(-rect_size.y * 0.5, rect_size.y * 0.5)
	)

	var base_scale := _rng.randf_range(scale_range.x, scale_range.y)
	var twinkle_speed := _rng.randf_range(twinkle_speed_range.x, twinkle_speed_range.y)
	var rotation_speed := _rng.randf_range(rotation_speed_range.x, rotation_speed_range.y)
	star.setup(star_texture, base_scale, twinkle_speed, rotation_speed)

	var brightness := _rng.randf_range(brightness_range.x, brightness_range.y)
	star.modulate = Color(brightness, brightness, brightness, 1.0)
	container.add_child(star)
	star.loop_completed.connect(_on_star_loop_completed.bind(container, scale_range, motion_scale))

func _on_star_loop_completed(star: Node, container: Node2D, scale_range: Vector2, motion_scale: Vector2) -> void:
	if not is_instance_valid(container):
		return
	var center := _get_spawn_center()
	_spawn_star(container, _rect_size, center, scale_range, motion_scale)
