extends GPUParticles2D

var _hit_material: ParticleProcessMaterial
var _miss_material: ParticleProcessMaterial

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
	_hit_material.spread = 25.0
	_hit_material.initial_velocity_min = 90.0
	_hit_material.initial_velocity_max = 240.0
	_hit_material.gravity = Vector3.ZERO
	_hit_material.damping_min = 120.0
	_hit_material.damping_max = 180.0
	_hit_material.scale_min = 1.8
	_hit_material.scale_max = 4.5
	_hit_material.color = Color(0.9, 0.65, 1.0, 1.0)

	var color_ramp := Gradient.new()
	color_ramp.set_color(0, Color(1.0, 0.85, 1.0, 1.0))
	color_ramp.add_point(0.5, Color(0.8, 0.55, 1.0, 0.7))
	color_ramp.set_color(1, Color(0.4, 0.2, 0.8, 0.0))
	var color_tex := GradientTexture1D.new()
	color_tex.gradient = color_ramp
	_hit_material.color_ramp = color_tex

func _setup_miss_material() -> void:
	_miss_material = ParticleProcessMaterial.new()
	_miss_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	_miss_material.emission_sphere_radius = 4.0
	_miss_material.direction = Vector3(0, 1, 0)
	_miss_material.spread = 35.0
	_miss_material.initial_velocity_min = 50.0
	_miss_material.initial_velocity_max = 130.0
	_miss_material.gravity = Vector3.ZERO
	_miss_material.damping_min = 70.0
	_miss_material.damping_max = 120.0
	_miss_material.scale_min = 1.4
	_miss_material.scale_max = 3.2
	_miss_material.color = Color(0.8, 0.6, 1.0, 0.8)

	var color_ramp := Gradient.new()
	color_ramp.set_color(0, Color(0.9, 0.7, 1.0, 0.6))
	color_ramp.set_color(1, Color(0.4, 0.2, 0.8, 0.0))
	var color_tex := GradientTexture1D.new()
	color_tex.gradient = color_ramp
	_miss_material.color_ramp = color_tex

func set_hit_mode(hitting: bool) -> void:
	if hitting:
		amount = 70
		lifetime = 0.25
		process_material = _hit_material
	else:
		amount = 35
		lifetime = 0.45
		process_material = _miss_material
