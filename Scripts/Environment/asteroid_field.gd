extends Node2D

@export var spawn_interval := 3.0
@export var max_asteroids := 40
@export var spawn_min_distance := 800.0
@export var spawn_max_distance := 1000.0
@export var despawn_distance := 1500.0
@export var speed_range := Vector2(20.0, 60.0)
@export var rotation_speed_range := Vector2(-0.3, 0.3)
@export var player_path: NodePath

var _active_asteroids: Array[Area2D] = []
var _pool: Array[Area2D] = []
var _player: Node2D
var _rng := RandomNumberGenerator.new()
var _spawn_timer := 0.0
var _distance_check_timer := 0.0

func _ready() -> void:
	_rng.randomize()
	_player = get_node(player_path)
	_collect_asteroids(self)
	if _active_asteroids.is_empty():
		push_warning("AsteroidField: No asteroids found. Add asteroid.tscn instances as children.")

func _process(delta: float) -> void:
	if not _player:
		return

	_spawn_timer += delta
	if _spawn_timer >= spawn_interval and _active_asteroids.size() < max_asteroids and _pool.size() > 0:
		_spawn_asteroid()
		_spawn_timer = 0.0

	_distance_check_timer += delta
	if _distance_check_timer >= 0.1:
		_check_despawn()
		_distance_check_timer = 0.0

func _spawn_asteroid() -> void:
	if _pool.is_empty():
		return

	var asteroid = _pool.pop_back()
	_place_asteroid_around_player(asteroid)
	_randomize_motion(asteroid)
	_activate_asteroid(asteroid)

	_active_asteroids.append(asteroid)

func _on_asteroid_destroyed(asteroid: Area2D) -> void:
	var idx := _active_asteroids.find(asteroid)
	if idx >= 0:
		_active_asteroids.remove_at(idx)

func _check_despawn() -> void:
	var player_pos := _player.global_position
	var despawn_distance_sq := despawn_distance * despawn_distance

	for i in range(_active_asteroids.size() - 1, -1, -1):
		var asteroid = _active_asteroids[i]
		if asteroid and player_pos.distance_squared_to(asteroid.global_position) > despawn_distance_sq:
			_active_asteroids.remove_at(i)
			_deactivate_asteroid(asteroid)
			_pool.append(asteroid)

func _collect_asteroids(root: Node) -> void:
	for child in root.get_children():
		if child is Area2D and child.has_method("configure_motion"):
			_activate_asteroid(child)
			_place_asteroid_around_player(child)
			_randomize_motion(child)
			_active_asteroids.append(child)
		_collect_asteroids(child)

func _place_asteroid_around_player(asteroid: Area2D) -> void:
	var angle := _rng.randf() * TAU
	var radius := _rng.randf_range(spawn_min_distance, spawn_max_distance)
	asteroid.global_position = _player.global_position + Vector2.from_angle(angle) * radius

func _randomize_motion(asteroid: Area2D) -> void:
	var velocity := Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(speed_range.x, speed_range.y)
	var rot_speed := _rng.randf_range(rotation_speed_range.x, rotation_speed_range.y)
	asteroid.configure_motion(velocity, rot_speed)

func _activate_asteroid(asteroid: Area2D) -> void:
	asteroid.visible = true
	asteroid.monitoring = true
	asteroid.set_process(true)
	_ensure_destroyed_connection(asteroid)

func _deactivate_asteroid(asteroid: Area2D) -> void:
	asteroid.visible = false
	asteroid.monitoring = false
	asteroid.set_process(false)

func _ensure_destroyed_connection(asteroid: Area2D) -> void:
	if not asteroid.has_signal("destroyed"):
		return
	var callable := Callable(self, "_on_asteroid_destroyed")
	if not asteroid.is_connected("destroyed", callable):
		asteroid.connect("destroyed", callable)
