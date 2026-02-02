extends GPUParticles2D

var _hit_material: ParticleProcessMaterial
var _miss_material: ParticleProcessMaterial
@onready var _shockwave_sprite: Sprite2D = $ShockwaveSprite
var _shockwave_tween: Tween

func _ready() -> void:
	_setup_hit_material()
	_setup_miss_material()
	one_shot = false
	emitting = false
	var glow_mat := CanvasItemMaterial.new()
	glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = glow_mat

func _setup_hit_material() -> void:
	_hit_material = ParticleProcessMaterial.new()
	_hit_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	_hit_material.emission_sphere_radius = 5.0
	_hit_material.direction = Vector3(0, 1, 0)
	_hit_material.spread = 35.0
	_hit_material.initial_velocity_min = 50.0
	_hit_material.initial_velocity_max = 140.0
	_hit_material.gravity = Vector3.ZERO
	_hit_material.damping_min = 50.0
	_hit_material.damping_max = 100.0
	# Belirgin boyut
	_hit_material.scale_min = 0.8
	_hit_material.scale_max = 2.2
	_hit_material.color = Color(0.9, 0.7, 1.0, 0.95)

	# Parlak, belirgin gradient
	var color_ramp := Gradient.new()
	color_ramp.offsets = PackedFloat32Array([0.0, 0.15, 0.4, 0.7, 1.0])
	color_ramp.colors = PackedColorArray([
		Color(1.0, 0.9, 1.0, 1.0),
		Color(0.9, 0.7, 1.0, 0.85),
		Color(0.75, 0.55, 0.9, 0.5),
		Color(0.5, 0.3, 0.75, 0.2),
		Color(0.3, 0.15, 0.5, 0.0)
	])
	var color_tex := GradientTexture1D.new()
	color_tex.gradient = color_ramp
	_hit_material.color_ramp = color_tex

	# Scale curve - smooth fade
	var scale_curve := Curve.new()
	scale_curve.clear_points()
	scale_curve.add_point(Vector2(0.0, 0.3), 0.0, 4.0)
	scale_curve.add_point(Vector2(0.12, 1.0), 0.0, 0.0)
	scale_curve.add_point(Vector2(0.45, 0.75), -0.4, -0.4)
	scale_curve.add_point(Vector2(1.0, 0.0), -1.0, 0.0)
	var scale_tex := CurveTexture.new()
	scale_tex.curve = scale_curve
	_hit_material.scale_curve = scale_tex

func _setup_miss_material() -> void:
	_miss_material = ParticleProcessMaterial.new()
	_miss_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	_miss_material.emission_sphere_radius = 2.0
	_miss_material.direction = Vector3(0, 1, 0)
	_miss_material.spread = 25.0
	_miss_material.initial_velocity_min = 18.0
	_miss_material.initial_velocity_max = 55.0
	_miss_material.gravity = Vector3.ZERO
	_miss_material.damping_min = 30.0
	_miss_material.damping_max = 60.0
	_miss_material.scale_min = 0.5
	_miss_material.scale_max = 1.4
	_miss_material.color = Color(0.7, 0.5, 0.9, 0.6)

	# Yumuşak gradient
	var color_ramp := Gradient.new()
	color_ramp.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	color_ramp.colors = PackedColorArray([
		Color(0.75, 0.55, 0.95, 0.5),
		Color(0.6, 0.4, 0.8, 0.3),
		Color(0.4, 0.25, 0.65, 0.1),
		Color(0.25, 0.12, 0.45, 0.0)
	])
	var color_tex := GradientTexture1D.new()
	color_tex.gradient = color_ramp
	_miss_material.color_ramp = color_tex

func set_hit_mode(hitting: bool) -> void:
	if hitting:
		amount = 55
		lifetime = 0.4
		process_material = _hit_material
	else:
		amount = 20
		lifetime = 0.5
		process_material = _miss_material

func pulse() -> void:
	if not emitting:
		emitting = true
	restart()
	_trigger_shockwave()

func _trigger_shockwave() -> void:
	if _shockwave_tween and _shockwave_tween.is_running():
		_shockwave_tween.kill()

	_shockwave_sprite.scale = Vector2(0.2, 0.2)
	_shockwave_sprite.modulate = Color(0.9, 0.75, 1.0, 0.7)

	_shockwave_tween = create_tween()
	_shockwave_tween.set_parallel(true)

	# Belirgin genisleme
	_shockwave_tween.tween_property(_shockwave_sprite, "scale", Vector2(2.2, 2.2), 0.25) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Fade out
	_shockwave_tween.tween_property(_shockwave_sprite, "modulate:a", 0.0, 0.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
