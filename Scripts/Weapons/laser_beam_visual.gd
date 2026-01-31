extends Node2D

var _beam_line: Line2D
var _beam_glow: Line2D
var _beam_particles: GPUParticles2D
var _glow_particles: GPUParticles2D
var _muzzle_effect: GPUParticles2D
var _fade_tween: Tween

var _beam_particles_mat: ParticleProcessMaterial
var _glow_particles_mat: ParticleProcessMaterial
var _muzzle_particles_mat: ParticleProcessMaterial

func _ready() -> void:
	_beam_line = $BeamLine
	_beam_glow = $BeamGlow
	_beam_particles = $BeamParticles
	_glow_particles = $GlowParticles
	_muzzle_effect = $MuzzleEffect
	_setup_beam_lines()
	_setup_beam_particles()
	_setup_glow_particles()
	_setup_muzzle_effect()

func _setup_beam_lines() -> void:
	var core_mat := CanvasItemMaterial.new()
	core_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_beam_line.material = core_mat
	_beam_line.modulate = Color(1.0, 1.0, 1.0, 1.0)

	_beam_line.width = 3.5
	_beam_line.default_color = Color(0.85, 0.65, 1.0, 0.95)

	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.95, 0.85, 1.0, 1.0))
	gradient.add_point(0.45, Color(0.75, 0.55, 1.0, 0.9))
	gradient.set_color(1, Color(0.35, 0.2, 0.7, 0.35))
	_beam_line.gradient = gradient

	var width_curve := Curve.new()
	width_curve.add_point(Vector2(0.0, 1.0))
	width_curve.add_point(Vector2(0.6, 0.85))
	width_curve.add_point(Vector2(1.0, 0.2))
	_beam_line.width_curve = width_curve

	var glow_mat := CanvasItemMaterial.new()
	glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_beam_glow.material = glow_mat
	_beam_glow.modulate = Color(1.0, 1.0, 1.0, 1.0)

	_beam_glow.width = 12.0
	_beam_glow.default_color = Color(0.85, 0.65, 1.0, 0.35)
	var glow_gradient := Gradient.new()
	glow_gradient.set_color(0, Color(0.9, 0.7, 1.0, 0.55))
	glow_gradient.add_point(0.6, Color(0.6, 0.4, 0.95, 0.3))
	glow_gradient.set_color(1, Color(0.3, 0.15, 0.7, 0.0))
	_beam_glow.gradient = glow_gradient

	var glow_curve := Curve.new()
	glow_curve.add_point(Vector2(0.0, 1.0))
	glow_curve.add_point(Vector2(0.7, 0.7))
	glow_curve.add_point(Vector2(1.0, 0.1))
	_beam_glow.width_curve = glow_curve

	_beam_line.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
	_beam_glow.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])

func _setup_beam_particles() -> void:
	_beam_particles.amount = 90
	_beam_particles.lifetime = 0.6
	_beam_particles.emitting = false
	var beam_mat := CanvasItemMaterial.new()
	beam_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_beam_particles.material = beam_mat

	_beam_particles_mat = ParticleProcessMaterial.new()
	_beam_particles_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	_beam_particles_mat.emission_box_extents = Vector3(3.0, 80.0, 0.0)
	_beam_particles_mat.direction = Vector3(0, -1, 0)
	_beam_particles_mat.spread = 8.0
	_beam_particles_mat.initial_velocity_min = 160.0
	_beam_particles_mat.initial_velocity_max = 280.0
	_beam_particles_mat.gravity = Vector3.ZERO
	_beam_particles_mat.scale_min = 1.1
	_beam_particles_mat.scale_max = 2.4
	_beam_particles_mat.damping_min = 30.0
	_beam_particles_mat.damping_max = 70.0
	_beam_particles_mat.color = Color(0.9, 0.7, 1.0, 0.85)

	var color_ramp := Gradient.new()
	color_ramp.set_color(0, Color(1.0, 0.85, 1.0, 0.95))
	color_ramp.set_color(1, Color(0.5, 0.3, 0.9, 0.0))
	var color_tex := GradientTexture1D.new()
	color_tex.gradient = color_ramp
	_beam_particles_mat.color_ramp = color_tex

	_beam_particles.process_material = _beam_particles_mat

func _setup_glow_particles() -> void:
	_glow_particles.amount = 40
	_glow_particles.lifetime = 0.8
	_glow_particles.emitting = false
	var glow_mat := CanvasItemMaterial.new()
	glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow_particles.material = glow_mat

	_glow_particles_mat = ParticleProcessMaterial.new()
	_glow_particles_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	_glow_particles_mat.emission_box_extents = Vector3(7.0, 80.0, 0.0)
	_glow_particles_mat.direction = Vector3(0, -1, 0)
	_glow_particles_mat.spread = 20.0
	_glow_particles_mat.initial_velocity_min = 40.0
	_glow_particles_mat.initial_velocity_max = 90.0
	_glow_particles_mat.gravity = Vector3.ZERO
	_glow_particles_mat.scale_min = 2.8
	_glow_particles_mat.scale_max = 6.2
	_glow_particles_mat.damping_min = 20.0
	_glow_particles_mat.damping_max = 50.0
	_glow_particles_mat.color = Color(0.75, 0.55, 1.0, 0.4)

	var color_ramp := Gradient.new()
	color_ramp.set_color(0, Color(0.85, 0.65, 1.0, 0.5))
	color_ramp.set_color(1, Color(0.35, 0.2, 0.8, 0.0))
	var color_tex := GradientTexture1D.new()
	color_tex.gradient = color_ramp
	_glow_particles_mat.color_ramp = color_tex

	_glow_particles.process_material = _glow_particles_mat

func _setup_muzzle_effect() -> void:
	_muzzle_effect.amount = 40
	_muzzle_effect.lifetime = 0.25
	_muzzle_effect.emitting = false
	var muzzle_mat := CanvasItemMaterial.new()
	muzzle_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_muzzle_effect.material = muzzle_mat

	_muzzle_particles_mat = ParticleProcessMaterial.new()
	_muzzle_particles_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	_muzzle_particles_mat.emission_sphere_radius = 6.0
	_muzzle_particles_mat.direction = Vector3(0, -1, 0)
	_muzzle_particles_mat.spread = 160.0
	_muzzle_particles_mat.initial_velocity_min = 30.0
	_muzzle_particles_mat.initial_velocity_max = 90.0
	_muzzle_particles_mat.gravity = Vector3.ZERO
	_muzzle_particles_mat.scale_min = 1.4
	_muzzle_particles_mat.scale_max = 3.2
	_muzzle_particles_mat.damping_min = 60.0
	_muzzle_particles_mat.damping_max = 110.0
	_muzzle_particles_mat.color = Color(0.95, 0.8, 1.0, 0.8)

	var color_ramp := Gradient.new()
	color_ramp.set_color(0, Color(1.0, 0.9, 1.0, 0.95))
	color_ramp.add_point(0.5, Color(0.8, 0.6, 1.0, 0.6))
	color_ramp.set_color(1, Color(0.4, 0.25, 0.8, 0.0))
	var color_tex := GradientTexture1D.new()
	color_tex.gradient = color_ramp
	_muzzle_particles_mat.color_ramp = color_tex

	_muzzle_effect.process_material = _muzzle_particles_mat

func update_beam(end_point: Vector2, _is_hitting: bool) -> void:
	_beam_line.points = PackedVector2Array([Vector2.ZERO, end_point])
	_beam_glow.points = PackedVector2Array([Vector2.ZERO, end_point])

	var beam_length := end_point.length()
	var beam_mid := end_point * 0.5
	_beam_particles.position = beam_mid
	_glow_particles.position = beam_mid
	_update_beam_particle_extents(beam_length)
	_beam_particles.emitting = true
	_glow_particles.emitting = true
	_muzzle_effect.emitting = true
	_beam_glow.modulate.a = 0.85 if _is_hitting else 0.7

func show_beam() -> void:
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	modulate.a = 1.0
	visible = true

func fade_out() -> void:
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	_fade_tween.tween_callback(_on_fade_complete)

func _on_fade_complete() -> void:
	visible = false
	_beam_particles.emitting = false
	_glow_particles.emitting = false
	_muzzle_effect.emitting = false

func _update_beam_particle_extents(beam_length: float) -> void:
	var half_length: float = maxf(beam_length * 0.5, 1.0)
	_beam_particles_mat.emission_box_extents = Vector3(3.0, half_length, 0.0)
	_glow_particles_mat.emission_box_extents = Vector3(7.0, half_length, 0.0)
	_beam_particles.amount = int(clampf(beam_length * 0.18, 80.0, 200.0))
	_glow_particles.amount = int(clampf(beam_length * 0.08, 30.0, 120.0))
