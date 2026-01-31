extends Area2D

signal destroyed(asteroid: Area2D)

@export var max_health := 100.0

var velocity := Vector2.ZERO
var rotation_speed := 0.0
var current_health := 100.0
var is_fragment := false

@onready var _sprite: Sprite2D = $Sprite2D

var _flash_tween: Tween

func configure_motion(vel: Vector2, rot_speed: float) -> void:
	velocity = vel
	rotation_speed = rot_speed

func setup(tex: Texture2D, base_scale: float, vel: Vector2, rot_speed: float) -> void:
	configure_motion(vel, rot_speed)
	scale = Vector2.ONE * base_scale

	if _sprite:
		_sprite.texture = tex

	collision_layer = 2
	collision_mask = 0

	max_health = 100.0 * base_scale
	current_health = max_health

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0

func take_damage(amount: float) -> void:
	current_health -= amount
	_flash_white()
	if current_health <= 0.0:
		_explode()

func _flash_white() -> void:
	if _flash_tween and _flash_tween.is_running():
		_flash_tween.kill()
	if _sprite:
		_sprite.modulate = Color.WHITE
		_flash_tween = create_tween()
		_flash_tween.tween_property(_sprite, "modulate", Color(1, 1, 1, 1), 0.15)

func _explode() -> void:
	_spawn_explosion_particles()
	if not is_fragment:
		_spawn_fragments()
	destroyed.emit(self)
	queue_free()

func _spawn_explosion_particles() -> void:
	var particles := GPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 24
	particles.lifetime = 0.6
	particles.explosiveness = 1.0
	particles.global_position = global_position

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 80.0
	mat.initial_velocity_max = 200.0
	mat.gravity = Vector3.ZERO
	mat.damping_min = 100.0
	mat.damping_max = 150.0
	mat.scale_min = 2.0
	mat.scale_max = 5.0
	mat.color = Color(1.0, 0.6, 0.2, 1.0)

	var color_ramp := Gradient.new()
	color_ramp.set_color(0, Color(1.0, 0.8, 0.3, 1.0))
	color_ramp.add_point(0.5, Color(1.0, 0.4, 0.1, 0.8))
	color_ramp.set_color(1, Color(0.5, 0.1, 0.0, 0.0))
	var color_texture := GradientTexture1D.new()
	color_texture.gradient = color_ramp
	mat.color_ramp = color_texture

	particles.process_material = mat

	get_tree().current_scene.add_child(particles)
	var timer := get_tree().create_timer(1.0)
	timer.timeout.connect(particles.queue_free)

func _spawn_fragments() -> void:
	var tex := _sprite.texture
	var scene := load("res://Scenes/Environment/asteroid.tscn") as PackedScene
	for i in 3:
		var fragment := scene.instantiate()

		var angle := (TAU / 3.0) * i + randf_range(-0.3, 0.3)
		var frag_vel := velocity + Vector2.from_angle(angle) * randf_range(60.0, 120.0)
		var frag_scale := scale.x * randf_range(0.35, 0.5)
		var frag_rot := randf_range(-1.0, 1.0)

		fragment.setup(tex, frag_scale, frag_vel, frag_rot)
		fragment.is_fragment = true
		fragment.global_position = global_position + Vector2.from_angle(angle) * 15.0

		get_tree().current_scene.add_child(fragment)

func _process(delta: float) -> void:
	position += velocity * delta
	rotation += rotation_speed * delta
