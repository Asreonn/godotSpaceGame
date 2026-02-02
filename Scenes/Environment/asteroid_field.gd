extends Node2D

const ASTEROID_SCENE := preload("res://Scenes/Environment/asteroid.tscn")

@export var spawn_interval := 0.8
@export var max_asteroids := 120
@export var initial_pool_size := 15  # Baslangicta olusturulacak pool boyutu
@export var camera_min_zoom := 1.0
@export var camera_max_zoom := 5.0
@export var slow_zone_zoom := 3.0
@export var spawn_min_distance := 1200.0
@export var spawn_max_distance := 2500.0
@export var despawn_distance := 4000.0
@export var spawn_edge_buffer := 200.0
@export var speed_range := Vector2(80.0, 140.0)
@export var slow_zone_blend := 600.0
@export var steer_strength := 6.0
@export var drift_strength := 0.35
@export var approach_offset_ratio_range := Vector2(0.35, 0.75)
@export var flyby_angle_deg_range := Vector2(20.0, 50.0)
@export var max_area_capacity := 50
@export var weight_min_scale := 0.2125
@export var weight_max_scale := 1.2
@export var weight_steps := 5
@export var rotation_speed_range := Vector2(-0.3, 0.3)
@export var scale_range := Vector2(0.4, 1.2)
@export var player_path: NodePath

var _active_asteroids: Array[Asteroid] = []
var _pool: Array[Asteroid] = []
var _player: Node2D
var _rng := RandomNumberGenerator.new()
var _spawn_timer := 0.0
var _distance_check_timer := 0.0
var _slow_zone_radius := 0.0
var _area_weight := 0
@onready var _asteroids_container: Node2D = $Asteroids

func _ready() -> void:
	_rng.randomize()
	_player = get_node_or_null(player_path)
	_update_spawn_bounds()
	call_deferred("_update_spawn_bounds")
	_build_pool(initial_pool_size)

func _process(delta: float) -> void:
	if not _player:
		return

	_spawn_timer += delta
	if _spawn_timer >= spawn_interval and _active_asteroids.size() < max_asteroids:
		var area_weight := _get_area_weight()
		_spawn_asteroid(area_weight)
		_spawn_timer = 0.0

	_distance_check_timer += delta
	if _distance_check_timer >= 0.1:
		_check_despawn()
		_distance_check_timer = 0.0

func _spawn_asteroid(current_area_weight: int = -1) -> void:
	if current_area_weight < 0:
		current_area_weight = _get_area_weight()
	if current_area_weight >= max_area_capacity:
		return

	var random_scale := _rng.randf_range(scale_range.x, scale_range.y)
	var new_weight := _get_weight_for_scale(random_scale)
	if current_area_weight + new_weight > max_area_capacity:
		return

	var asteroid: Area2D
	if _pool.is_empty():
		asteroid = _create_asteroid()
	else:
		asteroid = _pool.pop_back()

	_place_asteroid_around_player(asteroid)
	_randomize_motion(asteroid)
	_randomize_scale(asteroid, random_scale)
	_activate_asteroid(asteroid)

	_active_asteroids.append(asteroid)

func _on_asteroid_destroyed(asteroid: Asteroid) -> void:
	var idx := _active_asteroids.find(asteroid)
	if idx >= 0:
		_active_asteroids.remove_at(idx)

func _check_despawn() -> void:
	var player_pos := _player.global_position
	# SABİT despawn mesafesi - her zaman max zoom (5.0x) için optimize
	var despawn_distance_sq := despawn_distance * despawn_distance

	for i in range(_active_asteroids.size() - 1, -1, -1):
		var asteroid = _active_asteroids[i]
		if asteroid and player_pos.distance_squared_to(asteroid.global_position) > despawn_distance_sq:
			_active_asteroids.remove_at(i)
			# Fade out animasyonu başlat
			asteroid.start_fadeout()

func _build_pool(count: int) -> void:
	for i in count:
		var asteroid := _create_asteroid()
		_deactivate_asteroid(asteroid)
		_pool.append(asteroid)

func _create_asteroid() -> Asteroid:
	var asteroid: Asteroid = ASTEROID_SCENE.instantiate()
	_asteroids_container.add_child(asteroid)
	_deactivate_asteroid(asteroid)
	return asteroid

func _place_asteroid_around_player(asteroid: Asteroid) -> void:
	var angle := _rng.randf() * TAU
	# Max zoom'da da kameranin disinda kalacak mesafe
	var radius := _rng.randf_range(spawn_min_distance, spawn_max_distance)
	asteroid.global_position = _player.global_position + Vector2.from_angle(angle) * radius

func _update_spawn_bounds() -> void:
	var view_size: Vector2 = get_viewport().get_visible_rect().size
	var max_view_radius: float = view_size.length() * 0.5 * camera_max_zoom
	var min_needed := max_view_radius + spawn_edge_buffer
	var slow_zoom := clampf(slow_zone_zoom, camera_min_zoom, camera_max_zoom)
	_slow_zone_radius = view_size.length() * 0.5 * slow_zoom

	var spawn_band := maxf(spawn_max_distance - spawn_min_distance, 400.0)
	var despawn_band := maxf(despawn_distance - spawn_max_distance, 1000.0)

	if spawn_min_distance < min_needed:
		spawn_min_distance = min_needed

	spawn_max_distance = maxf(spawn_max_distance, spawn_min_distance + spawn_band)
	despawn_distance = maxf(despawn_distance, spawn_max_distance + despawn_band)

func _randomize_motion(asteroid: Asteroid) -> void:
	var rot_speed := _rng.randf_range(rotation_speed_range.x, rotation_speed_range.y)
	var travel_speed := _rng.randf_range(speed_range.x, speed_range.y)

	var zone_radius := maxf(_slow_zone_radius, 400.0)
	var offset_ratio := _rng.randf_range(approach_offset_ratio_range.x, approach_offset_ratio_range.y)
	var offset_radius := zone_radius * clampf(offset_ratio, 0.1, 1.0)
	var offset_angle := _rng.randf() * TAU
	var offset := Vector2.from_angle(offset_angle) * offset_radius

	var drift_sign := -1.0 if _rng.randi_range(0, 1) == 0 else 1.0
	var flyby_angle_deg := _rng.randf_range(flyby_angle_deg_range.x, flyby_angle_deg_range.y)
	var flyby_angle := deg_to_rad(flyby_angle_deg) * drift_sign

	asteroid.configure_motion(Vector2.ZERO, rot_speed)
	asteroid.configure_steering(
		_player,
		offset,
		zone_radius,
		slow_zone_blend,
		travel_speed,
		travel_speed,
		drift_strength,
		steer_strength,
		drift_sign,
		flyby_angle
	)

func _randomize_scale(asteroid: Asteroid, random_scale: float) -> void:
	# Rastgele boyut ata
	asteroid.scale = Vector2.ONE * random_scale
	
	# Generation'ı sıfırla (bu yeni spawn edilen orijinal asteroid)
	asteroid.generation = 0
	
	# Health'i yeniden hesapla
	asteroid._apply_health_from_scale(random_scale)
	asteroid.current_health = asteroid.max_health

func _activate_asteroid(asteroid: Asteroid) -> void:
	asteroid.visible = true
	asteroid.monitoring = true
	asteroid.monitorable = true
	asteroid.collision_layer = 2
	asteroid.collision_mask = 0
	asteroid.set_process(true)
	asteroid.add_to_group("asteroid_active")
	_ensure_destroyed_connection(asteroid)

func _deactivate_asteroid(asteroid: Asteroid) -> void:
	asteroid.visible = false
	asteroid.monitoring = false
	asteroid.monitorable = false
	asteroid.collision_layer = 0
	asteroid.collision_mask = 0
	asteroid.set_process(false)
	if asteroid.is_in_group("asteroid_active"):
		asteroid.remove_from_group("asteroid_active")

func _ensure_destroyed_connection(asteroid: Asteroid) -> void:
	if not asteroid.has_signal("destroyed"):
		return
	var callable := Callable(self, "_on_asteroid_destroyed")
	if not asteroid.is_connected("destroyed", callable):
		asteroid.connect("destroyed", callable)

func _get_weight_for_scale(scale_value: float) -> int:
	if weight_steps <= 1:
		return 1
	if weight_max_scale <= weight_min_scale:
		return 1
	var ratio := clampf((scale_value - weight_min_scale) / (weight_max_scale - weight_min_scale), 0.0, 1.0)
	var raw := int(floor(ratio * float(weight_steps))) + 1
	return clampi(raw, 1, weight_steps)

func _get_asteroid_weight(asteroid: Asteroid) -> int:
	if not asteroid:
		return 0
	return _get_weight_for_scale(asteroid.scale.x)

func _get_area_weight() -> int:
	if not _player:
		_area_weight = 0
		return 0
	var total := 0
	var player_pos := _player.global_position
	var radius_sq := _slow_zone_radius * _slow_zone_radius
	for node in get_tree().get_nodes_in_group("asteroid_active"):
		var asteroid := node as Asteroid
		if not asteroid:
			continue
		if player_pos.distance_squared_to(asteroid.global_position) <= radius_sq:
			total += _get_asteroid_weight(asteroid)
	_area_weight = total
	return total
