extends Node2D

var _beam_line: Line2D
var _beam_glow: Line2D
var _beam_particles: GPUParticles2D
var _collision_particles: GPUParticles2D
var _muzzle_effect: GPUParticles2D
var _fade_tween: Tween
var _appear_tween: Tween
var _pulse_tween: Tween

var _beam_particles_mat: ParticleProcessMaterial

var _line_width: float
var _glow_width: float
var _last_beam_length: float = 0.0
var _heat_pulse_time := 0.0
var _beam_dir := Vector2.UP

# Cozy renk paleti - yumuşak lavanta/mor tonları
const BEAM_COLOR := Color(0.85, 0.65, 1.0, 0.95)
const BEAM_MODULATE := Color(1.2, 1.0, 1.3, 1.0)
const BEAM_GLOW := Color(0.85, 0.7, 1.0, 0.6)
const BEAM_TIP := Color(0.5, 0.3, 0.7, 0.0)
const HEAT_COOL_TINT := Color(1.0, 1.0, 1.0, 1.0)
const HEAT_HOT_TINT := Color(1.25, 0.7, 0.5, 1.0)
const HEAT_OVERHEAT_TINT := Color(1.5, 0.35, 0.2, 1.0)

func _ready() -> void:
	_beam_line = $BeamLine
	_beam_glow = $BeamGlow
	_beam_particles = $BeamParticles
	_collision_particles = $CollisionParticles
	_muzzle_effect = $MuzzleEffect
	_setup_beam_line()
	_setup_beam_glow()
	_setup_collision_particles()
	_setup_muzzle_effect()
	_apply_particle_base_tint()
	# Beam particles devre disi - sadece beam line kullaniliyor
	_beam_particles.emitting = false
	_beam_particles.visible = false

func _setup_beam_line() -> void:
	var core_mat := CanvasItemMaterial.new()
	core_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_beam_line.material = core_mat

	# Yumuşak lavanta tonu
	_beam_line.modulate = BEAM_MODULATE
	_beam_line.default_color = BEAM_COLOR

	_line_width = _beam_line.width

	_beam_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_beam_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_beam_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_beam_line.antialiased = true
	_beam_line.texture_mode = Line2D.LINE_TEXTURE_TILE
	_beam_line.sharp_limit = 8.0

	# Daha yumuşak uzunluk boyunca gradient - 5 nokta
	_beam_line.gradient = BeamVisualCurves.create_line_gradient()
	_beam_line.width_curve = BeamVisualCurves.create_width_curve()

	_beam_line.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])

func _setup_beam_glow() -> void:
	var glow_mat := CanvasItemMaterial.new()
	glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_beam_glow.material = glow_mat

	_beam_glow.modulate = Color(0.7, 0.5, 1.0, 0.3)
	_beam_glow.default_color = Color(0.6, 0.35, 0.9, 0.2)
	_glow_width = _beam_glow.width

	_beam_glow.joint_mode = Line2D.LINE_JOINT_ROUND
	_beam_glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_beam_glow.end_cap_mode = Line2D.LINE_CAP_ROUND
	_beam_glow.antialiased = true

	# Glow gradient - daha seffaf, yaygin isik
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.2, 0.5, 0.8, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.8, 0.6, 1.0, 0.35),
		Color(0.7, 0.5, 0.95, 0.3),
		Color(0.6, 0.4, 0.85, 0.2),
		Color(0.5, 0.3, 0.75, 0.1),
		Color(0.4, 0.2, 0.6, 0.0)
	])
	_beam_glow.gradient = gradient

	# Glow width curve - ortada genis, uclarda ince
	var curve := Curve.new()
	curve.clear_points()
	curve.add_point(Vector2(0.0, 0.5), 0.0, 1.5)
	curve.add_point(Vector2(0.2, 1.0), 0.3, 0.0)
	curve.add_point(Vector2(0.7, 1.0), 0.0, -0.3)
	curve.add_point(Vector2(1.0, 0.2), -1.5, 0.0)
	_beam_glow.width_curve = curve

	_beam_glow.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])

func _setup_beam_particles() -> void:
	_beam_particles.amount = 120
	_beam_particles.emitting = false
	_beam_particles.modulate = BEAM_MODULATE
	_beam_particles.randomness = 0.3
	_beam_particles.preprocess = 0.8
	_beam_particles.lifetime = 0.9
	_beam_particles.local_coords = true
	_beam_particles.visibility_rect = Rect2(-2500, -2500, 5000, 5000)

	var beam_mat := CanvasItemMaterial.new()
	beam_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_beam_particles.material = beam_mat

	_beam_particles.texture = load("res://Assets/Weapons/glowing_circle.png")

	_beam_particles_mat = ParticleProcessMaterial.new()
	_beam_particles_mat.particle_flag_disable_z = true

	_beam_particles_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX

	# Daha yavaş, sakin drift
	_beam_particles_mat.direction = Vector3(1, 0, 0)
	_beam_particles_mat.spread = 140.0

	_beam_particles_mat.initial_velocity_min = 4.0
	_beam_particles_mat.initial_velocity_max = 14.0

	_beam_particles_mat.gravity = Vector3.ZERO

	# Daha küçük, zarif parçacıklar
	_beam_particles_mat.scale_min = 0.15
	_beam_particles_mat.scale_max = 0.4
	_beam_particles_mat.scale_curve = BeamVisualCurves.create_beam_scale_curve()

	_beam_particles_mat.damping_min = 8.0
	_beam_particles_mat.damping_max = 16.0

	_beam_particles_mat.color_ramp = BeamVisualCurves.create_beam_gradient()

	_beam_particles.process_material = _beam_particles_mat

func _setup_collision_particles() -> void:
	_collision_particles.emitting = false

func _setup_muzzle_effect() -> void:
	_muzzle_effect.emitting = false

func update_beam(end_point: Vector2, is_hitting: bool) -> void:
	_update_particle_directions(end_point)
	var pts := PackedVector2Array([Vector2.ZERO, end_point])
	_beam_line.points = pts
	_beam_glow.points = pts

	if is_hitting:
		_collision_particles.global_position = to_global(end_point)
		_collision_particles.emitting = true
	else:
		_collision_particles.emitting = false

func _update_particle_directions(end_point: Vector2) -> void:
	var dir := _beam_dir
	if end_point.length() > 0.001:
		dir = end_point.normalized()
		_beam_dir = dir

	if _muzzle_effect:
		_muzzle_effect.rotation = dir.angle()

	if _collision_particles:
		var global_dir := global_transform.basis_xform(dir)
		if global_dir.length() > 0.001:
			global_dir = global_dir.normalized()
		_collision_particles.global_rotation = (-global_dir).angle()

func _apply_particle_base_tint() -> void:
	var base := _get_base_beam_tint()
	if _muzzle_effect:
		_muzzle_effect.modulate = Color(1, 1, 1, 1)
		_muzzle_effect.self_modulate = base
	if _collision_particles:
		_collision_particles.modulate = Color(1, 1, 1, 1)
		_collision_particles.self_modulate = base

func _get_base_beam_tint() -> Color:
	return Color(
		BEAM_COLOR.r * BEAM_MODULATE.r,
		BEAM_COLOR.g * BEAM_MODULATE.g,
		BEAM_COLOR.b * BEAM_MODULATE.b,
		BEAM_COLOR.a * BEAM_MODULATE.a
	)

func show_beam() -> void:
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	if _appear_tween and _appear_tween.is_running():
		_appear_tween.kill()

	visible = true
	_muzzle_effect.emitting = true

	# Daha yavaş, yumuşak açılma
	_appear_tween = create_tween()
	_appear_tween.set_parallel(true)
	_appear_tween.tween_property(_beam_line, "width", _line_width, 0.25).from(0.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_appear_tween.tween_property(_beam_glow, "width", _glow_width, 0.3).from(0.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

func fade_out() -> void:
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	if _appear_tween and _appear_tween.is_running():
		_appear_tween.kill()
	if _pulse_tween and _pulse_tween.is_running():
		_pulse_tween.kill()

	_muzzle_effect.emitting = false
	_collision_particles.emitting = false

	# Daha yavaş, yumuşak kapanma
	_fade_tween = create_tween()
	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(_beam_line, "width", 0.0, 0.15).from(_beam_line.width).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_fade_tween.tween_property(_beam_glow, "width", 0.0, 0.2).from(_beam_glow.width).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_fade_tween.set_parallel(false)
	_fade_tween.chain().tween_callback(_on_fade_complete)

func _on_fade_complete() -> void:
	visible = false

func pulse_hit() -> void:
	if not visible:
		return
	if _beam_line.width <= 0.0:
		return
	if _pulse_tween and _pulse_tween.is_running():
		_pulse_tween.kill()

	_collision_particles.restart()

	# Daha yumuşak, cozy pulse - küçük genişleme, nazik parlaklık
	_pulse_tween = create_tween()
	_pulse_tween.set_parallel(true)

	# Width pulse
	_pulse_tween.tween_property(_beam_line, "width", _line_width * 1.25, 0.08) \
		.from(_beam_line.width).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_pulse_tween.tween_property(_beam_glow, "width", _glow_width * 1.4, 0.08) \
		.from(_beam_glow.width).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# Parlaklik artisi
	_pulse_tween.tween_property(_beam_line, "modulate", Color(1.1, 1.0, 1.2, 1.0), 0.08) \
		.from(_beam_line.modulate).set_ease(Tween.EASE_OUT)
	_pulse_tween.tween_property(_beam_glow, "modulate", Color(0.85, 0.65, 1.1, 0.45), 0.08) \
		.from(_beam_glow.modulate).set_ease(Tween.EASE_OUT)

	# Geri donus
	_pulse_tween.set_parallel(false)
	_pulse_tween.chain().tween_property(_beam_line, "width", _line_width, 0.22) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(_beam_glow, "width", _glow_width, 0.22) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(_beam_line, "modulate", BEAM_MODULATE, 0.22) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(_beam_glow, "modulate", Color(0.7, 0.5, 1.0, 0.3), 0.22) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func set_heat_level(heat_ratio: float, overheated: bool, delta: float) -> void:
	var t := clampf(heat_ratio, 0.0, 1.0)
	var color := HEAT_COOL_TINT.lerp(HEAT_HOT_TINT, t)
	if overheated:
		_heat_pulse_time += delta
		var pulse := 0.5 + 0.5 * sin(_heat_pulse_time * 10.0)
		color = color.lerp(HEAT_OVERHEAT_TINT, pulse)
	modulate = color
	if _collision_particles and _collision_particles.top_level:
		var base := _get_base_beam_tint()
		_collision_particles.self_modulate = Color(
			base.r * color.r,
			base.g * color.g,
			base.b * color.b,
			base.a * color.a
		)


