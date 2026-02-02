extends Node2D

const ASTEROID_SCENE := preload("res://Scenes/Environment/asteroid.tscn")

@export var spawn_interval := 0.8
@export var max_asteroids := 120
@export var initial_pool_size := 15  # Baslangicta olusturulacak pool boyutu
@export var camera_max_zoom := 5.0
@export var spawn_min_distance := 1200.0
@export var spawn_max_distance := 2500.0
@export var despawn_distance := 4000.0
@export var speed_range := Vector2(20.0, 60.0)
@export var rotation_speed_range := Vector2(-0.3, 0.3)
@export var scale_range := Vector2(0.4, 1.2)
@export var player: Node2D

var _active_asteroids: Array[Asteroid] = []
var _pool: Array[Asteroid] = []
var _player: Node2D
var _rng := RandomNumberGenerator.new()
var _spawn_timer := 0.0
var _distance_check_timer := 0.0
@onready var _asteroids_container: Node2D = $Asteroids

func _ready() -> void:
	_rng.randomize()
	_player = player
	_build_pool(initial_pool_size)

func _process(delta: float) -> void:
	if not _player:
		return

	_spawn_timer += delta
	if _spawn_timer >= spawn_interval and _active_asteroids.size() < max_asteroids:
		_spawn_asteroid()
		_spawn_timer = 0.0

	_distance_check_timer += delta
	if _distance_check_timer >= 0.1:
		_check_despawn()
		_distance_check_timer = 0.0

func _spawn_asteroid() -> void:
	var asteroid: Area2D
	if _pool.is_empty():
		asteroid = _create_asteroid()
	else:
		asteroid = _pool.pop_back()

	_place_asteroid_around_player(asteroid)
	_randomize_motion(asteroid)
	_randomize_scale(asteroid)
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
	# SABİT mesafeler - her zaman max zoom (5.0x) için optimize
	var radius := _rng.randf_range(spawn_min_distance, spawn_max_distance)
	asteroid.global_position = _player.global_position + Vector2.from_angle(angle) * radius

func _randomize_motion(asteroid: Asteroid) -> void:
	var velocity := Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(speed_range.x, speed_range.y)
	var rot_speed := _rng.randf_range(rotation_speed_range.x, rotation_speed_range.y)
	asteroid.configure_motion(velocity, rot_speed)

func _randomize_scale(asteroid: Asteroid) -> void:
	# Rastgele boyut ata (1.5 - 8.0 arası)
	var random_scale := _rng.randf_range(scale_range.x, scale_range.y)
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
	_ensure_destroyed_connection(asteroid)

func _deactivate_asteroid(asteroid: Asteroid) -> void:
	asteroid.visible = false
	asteroid.monitoring = false
	asteroid.monitorable = false
	asteroid.collision_layer = 0
	asteroid.collision_mask = 0
	asteroid.set_process(false)

func _ensure_destroyed_connection(asteroid: Asteroid) -> void:
	if not asteroid.has_signal("destroyed"):
		return
	var callable := Callable(self, "_on_asteroid_destroyed")
	if not asteroid.is_connected("destroyed", callable):
		asteroid.connect("destroyed", callable)
