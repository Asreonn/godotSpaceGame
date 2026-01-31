extends GPUParticles2D

var _hit_material: ParticleProcessMaterial
var _miss_material: ParticleProcessMaterial
var _shockwave_sprite: Sprite2D
var _shockwave_tween: Tween

func _ready() -> void:
	_setup_hit_material()
	_setup_miss_material()
	_setup_shockwave()
	one_shot = false
	emitting = false
	var glow_mat := CanvasItemMaterial.new()
	glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = glow_mat

func _setup_hit_material() -> void:
	_hit_material = ParticleProcessMaterial.new()
	_hit_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	_hit_material.emission_sphere_radius = 3.5
	_hit_material.direction = Vector3(0, 1, 0)
	_hit_material.spread = 22.0
	# Daha yavaş, yumuşak parçacıklar
	_hit_material.initial_velocity_min = 35.0
	_hit_material.initial_velocity_max = 100.0
	_hit_material.gravity = Vector3.ZERO
	_hit_material.damping_min = 60.0
	_hit_material.damping_max = 110.0
	# Daha küçük boyut
	_hit_material.scale_min = 0.6
	_hit_material.scale_max = 1.8
	_hit_material.color = Color(0.8, 0.6, 0.95, 0.9)

	# Yumuşak 5 noktalı gradient
	var color_ramp := Gradient.new()
	color_ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.5, 0.8, 1.0])
	color_ramp.colors = PackedColorArray([
		Color(0.9, 0.75, 1.0, 0.9),
		Color(0.8, 0.6, 0.95, 0.7),
		Color(0.65, 0.45, 0.85, 0.4),
		Color(0.45, 0.28, 0.7, 0.15),
		Color(0.3, 0.15, 0.5, 0.0)
	])
	var color_tex := GradientTexture1D.new()
	color_tex.gradient = color_ramp
	_hit_material.color_ramp = color_tex

	# Scale curve - smooth fade
	var scale_curve := Curve.new()
	scale_curve.clear_points()
	scale_curve.add_point(Vector2(0.0, 0.2), 0.0, 4.0)
	scale_curve.add_point(Vector2(0.15, 1.0), 0.0, 0.0)
	scale_curve.add_point(Vector2(0.5, 0.7), -0.4, -0.4)
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
		amount = 40
		lifetime = 0.35
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

func _setup_shockwave() -> void:
	_shockwave_sprite = Sprite2D.new()
	add_child(_shockwave_sprite)

	_shockwave_sprite.texture = load("res://Assets/Weapons/glowing_circle.png")

	var shockwave_mat := CanvasItemMaterial.new()
	shockwave_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_shockwave_sprite.material = shockwave_mat

	# Daha yumuşak başlangıç rengi
	_shockwave_sprite.modulate = Color(0.8, 0.65, 0.95, 0.0)
	_shockwave_sprite.scale = Vector2.ZERO
	_shockwave_sprite.z_index = -1

func _trigger_shockwave() -> void:
	if _shockwave_tween and _shockwave_tween.is_running():
		_shockwave_tween.kill()

	# Daha küçük başlangıç, daha az agresif
	_shockwave_sprite.scale = Vector2(0.15, 0.15)
	_shockwave_sprite.modulate = Color(0.8, 0.65, 0.95, 0.55)

	_shockwave_tween = create_tween()
	_shockwave_tween.set_parallel(true)

	# Daha küçük genişleme, daha yavaş
	_shockwave_tween.tween_property(_shockwave_sprite, "scale", Vector2(1.5, 1.5), 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Daha yumuşak fade out
	_shockwave_tween.tween_property(_shockwave_sprite, "modulate:a", 0.0, 0.35) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
