extends Area2D
class_name Asteroid

const EXPLOSION_SCENE := preload("res://Scenes/VFX/asteroid_explosion.tscn")

signal destroyed(asteroid: Asteroid)

@export var max_health: float = 100
@export var size_multiplier: float = 0.85

var velocity := Vector2.ZERO
var rotation_speed := 0.0
var current_health: float = 100
var generation := 0  # 0=orijinal, 1=birinci parça, 2=ikinci parça
var _scale_initialized := false



@onready var _sprite: Sprite2D = $Sprite2D

var _flash_tween: Tween
var _impact_tween: Tween
var _fadeout_tween: Tween
var _is_fading_out := false

var _steer_enabled := false
var _steer_target: Node2D = null
var _steer_offset := Vector2.ZERO
var _slow_speed := 0.0
var _fast_speed := 0.0
var _slow_radius := 0.0
var _slow_blend := 1.0
var _drift_strength := 0.0
var _steer_strength := 1.0
var _drift_sign := 1.0
var _flyby_angle := 0.0
var _flyby_dir := Vector2.ZERO

func configure_motion(vel: Vector2, rot_speed: float) -> void:
	velocity = vel
	rotation_speed = rot_speed

func configure_steering(
			target: Node2D,
			offset: Vector2,
			slow_radius: float,
			slow_blend: float,
			slow_speed: float,
			fast_speed: float,
			drift_strength: float,
			steer_strength: float,
			drift_sign: float,
			flyby_angle: float
	) -> void:
	_steer_target = target
	_steer_offset = offset
	_slow_radius = maxf(slow_radius, 0.0)
	_slow_blend = maxf(slow_blend, 1.0)
	_slow_speed = maxf(slow_speed, 0.0)
	_fast_speed = maxf(fast_speed, _slow_speed)
	_drift_strength = drift_strength
	_steer_strength = maxf(steer_strength, 0.1)
	_drift_sign = drift_sign
	_flyby_angle = flyby_angle
	_steer_enabled = (_steer_target != null)
	_flyby_dir = _compute_flyby_dir()
	velocity = _get_desired_velocity()

func setup(tex: Texture2D, base_scale: float, vel: Vector2, rot_speed: float) -> void:
	configure_motion(vel, rot_speed)
	scale = Vector2.ONE * base_scale * size_multiplier
	_scale_initialized = true

	if _sprite:
		_sprite.texture = tex

	collision_layer = 2
	collision_mask = 0

	_apply_health_from_scale(base_scale)
	current_health = max_health

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	Events.laser_damage_requested.connect(_on_laser_damage_requested)
	Events.laser_impact_pulse_requested.connect(_on_laser_impact_pulse_requested)
	if not _scale_initialized:
		var raw_scale: float = scale.x
		scale *= size_multiplier
		_apply_health_from_scale(raw_scale)
		current_health = max_health

func _apply_health_from_scale(base_scale: float) -> void:
	var min_scale: float = 0.4
	var max_scale: float = 1.2
	var ratio: float = clampf((base_scale - min_scale) / (max_scale - min_scale), 0.0, 1.0)
	max_health = roundi(lerpf(20, 100, ratio))

func take_damage(amount: float) -> void:
	current_health -= amount
	_flash_white()
	impact_pulse()
	if current_health <= 0.0:
		_explode()

func _on_laser_damage_requested(target: Node2D, amount: float) -> void:
	if target != self:
		return
	take_damage(amount)

func _on_laser_impact_pulse_requested(target: Node2D) -> void:
	if target != self:
		return
	impact_pulse()

func _flash_white() -> void:
	if _flash_tween and _flash_tween.is_running():
		_flash_tween.kill()
	if _sprite:
		_sprite.modulate = Color(1.0, 0.85, 1.0, 1.0)
		_flash_tween = create_tween()
		_flash_tween.tween_property(_sprite, "modulate", Color(1, 1, 1, 1), 0.15)

func impact_pulse() -> void:
	if not _sprite:
		return
	if _impact_tween and _impact_tween.is_running():
		_impact_tween.kill()
	var base_scale := _sprite.scale
	_impact_tween = create_tween()
	_impact_tween.tween_property(_sprite, "scale", base_scale * 1.08, 0.05).from(base_scale)
	_impact_tween.tween_property(_sprite, "scale", base_scale, 0.12)

func _explode() -> void:
	_spawn_explosion_particles()
	_trigger_screen_shake()
	_play_explosion_sound()  # Placeholder - ses dosyasi eklenince calisacak
	var scene_root := get_tree().current_scene
	AsteroidDeathSpawner.spawn_fragments(global_position, scale.x, velocity, generation, _sprite.texture, scene_root)
	AsteroidDeathSpawner.spawn_item_drops(global_position, scale.x, scene_root)
	destroyed.emit(self)
	queue_free()

func _trigger_screen_shake() -> void:
	# Asteroid boyutuna göre shake intensity hesapla
	var shake_intensity := remap(scale.x, 0.4, 1.2, 1.5, 8.0)
	shake_intensity = clampf(shake_intensity, 1.5, 8.0)
	
	# Kamerayı bul ve shake tetikle
	Events.camera_shake_requested.emit(shake_intensity)

func _play_explosion_sound() -> void:
	# TODO: Ses efekti eklendiğinde buraya entegre edilecek
	# Boyuta göre farklı pitch:
	# var pitch := remap(scale.x, 0.4, 1.2, 1.3, 0.7)
	# $AudioStreamPlayer.pitch_scale = pitch
	# $AudioStreamPlayer.play()
	pass

func start_fadeout() -> void:
	if _is_fading_out:
		return
	_is_fading_out = true
	
	# Mevcut scale'i kaydet
	var current_scale := scale
	
	# Boyuta göre fade süresi - büyük asteroidler daha yavaş kaybolur
	var fade_duration := remap(current_scale.x, 0.4, 1.2, 0.3, 0.8)
	fade_duration = clampf(fade_duration, 0.3, 0.8)
	
	# Boyuta göre küçülme oranı - büyük asteroidler daha az küçülür
	var shrink_factor := remap(current_scale.x, 0.4, 1.2, 0.5, 0.75)
	shrink_factor = clampf(shrink_factor, 0.5, 0.75)
	
	if _fadeout_tween and _fadeout_tween.is_running():
		_fadeout_tween.kill()
	
	_fadeout_tween = create_tween()
	_fadeout_tween.set_parallel(true)
	
	# Modulate alpha'yı azalt (fade out)
	if _sprite:
		_fadeout_tween.tween_property(_sprite, "modulate:a", 0.0, fade_duration).from(_sprite.modulate.a)
	
	# Scale'i boyuta göre küçült
	var target_scale := current_scale * shrink_factor
	_fadeout_tween.tween_property(self, "scale", target_scale, fade_duration).from(current_scale)
	
	# Tween bitince queue_free
	_fadeout_tween.set_parallel(false)
	_fadeout_tween.chain().tween_callback(queue_free)

func _spawn_explosion_particles() -> void:
	var scene := get_tree().current_scene
	if not scene:
		return
	var explosion := EXPLOSION_SCENE.instantiate()
	explosion.global_position = global_position
	explosion.z_index = z_index - 1  # Asteroidlerin arkasinda, yildizlarin ustunde
	scene.add_child(explosion)
	# Doğrudan asteroidin gerçek ekran scale'ini gönder
	# play() bu değere göre tüm materyal özelliklerini ayarlayacak
	explosion.play(scale.x)

func _process(delta: float) -> void:
	_apply_steering(delta)
	position += velocity * delta
	rotation += rotation_speed * delta

func _apply_steering(delta: float) -> void:
	if not _steer_enabled or not _steer_target:
		return
	var desired := _get_desired_velocity()
	var lerp_t := 1.0 - exp(-_steer_strength * delta)
	velocity = velocity.lerp(desired, lerp_t)


func _compute_flyby_dir() -> Vector2:
	if not _steer_target:
		return Vector2.ZERO
	var target_pos := _steer_target.global_position + _steer_offset
	var to_target := target_pos - global_position
	var base_dir: Vector2
	if to_target.length() <= 0.001:
		var fallback := global_position - _steer_target.global_position
		if fallback.length() <= 0.001:
			fallback = Vector2.RIGHT
		base_dir = fallback.normalized()
	else:
		base_dir = to_target.normalized()
	base_dir = base_dir.rotated(_flyby_angle)
	var drift := Vector2(-base_dir.y, base_dir.x) * _drift_strength * _drift_sign
	var dir := base_dir + drift
	if dir.length() > 0.001:
		dir = dir.normalized()
	return dir

func _get_desired_velocity() -> Vector2:
	if _flyby_dir.length() <= 0.001:
		_flyby_dir = _compute_flyby_dir()
	if _flyby_dir.length() <= 0.001:
		return velocity
	var desired_dir := _flyby_dir
	var speed := _slow_speed
	if absf(_fast_speed - _slow_speed) > 0.01:
		var dist_to_player := global_position.distance_to(_steer_target.global_position)
		var t := clampf((dist_to_player - _slow_radius) / _slow_blend, 0.0, 1.0)
		var smooth := t * t * (3.0 - 2.0 * t)
		speed = lerpf(_slow_speed, _fast_speed, smooth)
	return desired_dir * speed
