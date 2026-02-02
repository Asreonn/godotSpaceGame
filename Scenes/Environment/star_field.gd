extends ParallaxBackground

@export var spawn_rect_size := Vector2(12000, 8000)
@export var auto_calculate_spawn_area := true
@export var layer_counts := PackedInt32Array([170, 120, 85])
@export var layer_motion_scales: Array[Vector2] = [
	Vector2(0.2, 0.2),
	Vector2(0.45, 0.45),
	Vector2(0.7, 0.7)
]
@export var layer_scale_ranges: Array[Vector2] = [
	Vector2(0.2, 0.6),
	Vector2(0.3, 1.0),
	Vector2(0.5, 1.5)
]
@export var center_bias := 1.6
@export var twinkle_speed_range := Vector2(0.5, 1.0)
@export var rotation_speed_range := Vector2(-0.4, 0.4)
@export var brightness_range := Vector2(0.45, 0.8)
@export var seed := 0
@export var player_path: NodePath
@export var star_scene: PackedScene = preload("res://Scenes/Environment/star.tscn")
@export var star_texture: Texture2D = preload("res://Assets/Environment/Star.png")

var _rng := RandomNumberGenerator.new()
var _rect_size := Vector2.ZERO

func _ready() -> void:
	if seed != 0:
		_rng.seed = seed
	else:
		_rng.randomize()

	# Spawn alanini kamera max zoom'una gore hesapla
	if auto_calculate_spawn_area:
		var viewport := get_viewport()
		var viewport_size: Vector2 = viewport.get_visible_rect().size
		var max_zoom_factor: float = 5.0
		# Max zoom'da gorunur alan + %50 margin
		spawn_rect_size = viewport_size * max_zoom_factor * 1.5

	_rect_size = spawn_rect_size
	if star_texture == null:
		star_texture = preload("res://Assets/Environment/Star.png")

	var layers := _get_layers()
	for i in range(layers.size()):
		var layer := layers[i]
		layer.motion_scale = layer_motion_scales[i] if i < layer_motion_scales.size() else Vector2(0.5, 0.5)
		layer.motion_mirroring = Vector2.ZERO
		var container := _get_or_create_container(layer)
		_spawn_stars(container, _rect_size, Vector2.ZERO, layer_counts[i] if i < layer_counts.size() else 100, layer_scale_ranges[i] if i < layer_scale_ranges.size() else Vector2(0.2, 0.4), layer)

func _process(_delta: float) -> void:
	# ParallaxBackground scroll_offset'ini kamera pozisyonuyla senkronize et
	var camera := get_viewport().get_camera_2d()
	if camera:
		scroll_offset = -camera.global_position

func _get_layers() -> Array[ParallaxLayer]:
	var layers: Array[ParallaxLayer] = []
	for child in get_children():
		if child is ParallaxLayer:
			layers.append(child)
	return layers

func _get_or_create_container(layer: ParallaxLayer) -> Node2D:
	return layer.get_node("Stars") as Node2D

func _spawn_stars(
		container: Node2D,
		rect_size: Vector2,
		center: Vector2,
		count: int,
		scale_range: Vector2,
		layer: ParallaxLayer
	) -> void:
	for i in range(count):
		_spawn_single_star(container, rect_size, center, scale_range, layer)

func _spawn_single_star(
		container: Node2D,
		rect_size: Vector2,
		center: Vector2,
		scale_range: Vector2,
		layer: ParallaxLayer
	) -> void:
	var star := star_scene.instantiate()
	# Yildizlari merkeze daha yogun dagit
	star.position = center + Vector2(
		_get_biased_unit() * rect_size.x * 0.5,
		_get_biased_unit() * rect_size.y * 0.5
	)

	var base_scale := _rng.randf_range(scale_range.x, scale_range.y)
	var twinkle_speed := _rng.randf_range(twinkle_speed_range.x, twinkle_speed_range.y)
	var rotation_speed := _rng.randf_range(rotation_speed_range.x, rotation_speed_range.y)
	star.setup(star_texture, base_scale, twinkle_speed, rotation_speed)
	star.rotation = _rng.randf() * TAU

	var brightness := _rng.randf_range(brightness_range.x, brightness_range.y)
	star.modulate = Color(brightness, brightness, brightness, 1.0)
	container.add_child(star)
	star.loop_completed.connect(_on_star_loop_completed.bind(container, scale_range, layer))

func _get_biased_unit() -> float:
	var value := _rng.randf() * 2.0 - 1.0
	var sign_value := 1.0 if value >= 0.0 else -1.0
	var bias := maxf(center_bias, 0.1)
	return sign_value * pow(abs(value), bias)

func _on_star_loop_completed(star: Node, container: Node2D, scale_range: Vector2, layer: ParallaxLayer) -> void:
	if not is_instance_valid(container):
		return
	_spawn_single_star(container, _rect_size, Vector2.ZERO, scale_range, layer)
