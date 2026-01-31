extends Node2D

var _beam_line: Line2D
var _beam_particles: GPUParticles2D
var _collision_particles: GPUParticles2D
var _muzzle_effect: GPUParticles2D
var _fade_tween: Tween
var _appear_tween: Tween
var _pulse_tween: Tween

var _beam_particles_mat: ParticleProcessMaterial
var _collision_particles_mat: ParticleProcessMaterial
var _muzzle_particles_mat: ParticleProcessMaterial

var _line_width: float
var _last_beam_length: float = 0.0

# Cozy renk paleti - yumuşak lavanta/mor tonları
const BEAM_COLOR := Color(0.75, 0.55, 0.95, 0.85)
const BEAM_MODULATE := Color(1.0, 0.9, 1.1, 1.0)
const BEAM_GLOW := Color(0.85, 0.7, 1.0, 0.6)
const BEAM_TIP := Color(0.5, 0.3, 0.7, 0.0)

func _ready() -> void:
	_beam_line = $BeamLine
	_beam_particles = $BeamParticles
	_collision_particles = $CollisionParticles
	_muzzle_effect = $MuzzleEffect
	_setup_beam_line()
	_setup_beam_particles()
	_setup_collision_particles()
	_setup_muzzle_effect()

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
	_beam_line.gradient = _create_line_gradient()
	_beam_line.width_curve = _create_width_curve()

	_beam_line.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])

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
	_beam_particles_mat.scale_curve = _create_beam_scale_curve()

	_beam_particles_mat.damping_min = 8.0
	_beam_particles_mat.damping_max = 16.0

	_beam_particles_mat.color_ramp = _create_beam_gradient()

	_beam_particles.process_material = _beam_particles_mat

func _setup_collision_particles() -> void:
	_collision_particles.amount = 18
	_collision_particles.lifetime = 0.5
	_collision_particles.emitting = false
	_collision_particles.modulate = BEAM_MODULATE
	_collision_particles.show_behind_parent = true
	_collision_particles.visibility_rect = Rect2(-2500, -2500, 5000, 5000)
	_collision_particles.local_coords = true

	var collision_mat := CanvasItemMaterial.new()
	collision_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_collision_particles.material = collision_mat

	_collision_particles.texture = load("res://Assets/Weapons/glowing_circle.png")

	_collision_particles_mat = ParticleProcessMaterial.new()
	_collision_particles_mat.particle_flag_disable_z = true
	_collision_particles_mat.spread = 28.0
	_collision_particles_mat.gravity = Vector3.ZERO
	# Daha küçük, soft parçacıklar
	_collision_particles_mat.scale_min = 0.2
	_collision_particles_mat.scale_max = 0.55
	_collision_particles_mat.scale_curve = _create_casting_scale_curve()
	_collision_particles_mat.color_ramp = _create_beam_gradient()
	# Daha yavaş spray
	_collision_particles_mat.initial_velocity_min = 12.0
	_collision_particles_mat.initial_velocity_max = 45.0
	_collision_particles_mat.damping_min = 20.0
	_collision_particles_mat.damping_max = 50.0

	_collision_particles.process_material = _collision_particles_mat

func _setup_muzzle_effect() -> void:
	_muzzle_effect.lifetime = 0.4
	_muzzle_effect.amount = 10
	_muzzle_effect.emitting = false
	_muzzle_effect.modulate = BEAM_MODULATE
	_muzzle_effect.show_behind_parent = true
	_muzzle_effect.visibility_rect = Rect2(-100, -100, 200, 200)
	_muzzle_effect.local_coords = true
	_muzzle_effect.position = Vector2.ZERO

	var muzzle_mat := CanvasItemMaterial.new()
	muzzle_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_muzzle_effect.material = muzzle_mat

	_muzzle_effect.texture = load("res://Assets/Weapons/glowing_circle.png")

	_muzzle_particles_mat = ParticleProcessMaterial.new()
	_muzzle_particles_mat.particle_flag_disable_z = true
	_muzzle_particles_mat.gravity = Vector3.ZERO

	_muzzle_particles_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	_muzzle_particles_mat.emission_sphere_radius = 3.0
	_muzzle_particles_mat.direction = Vector3(0, -1, 0)
	_muzzle_particles_mat.spread = 15.0

	# Daha küçük, nazik muzzle flash
	_muzzle_particles_mat.scale_min = 0.15
	_muzzle_particles_mat.scale_max = 0.4
	_muzzle_particles_mat.scale_curve = _create_casting_scale_curve()
	_muzzle_particles_mat.color_ramp = _create_beam_gradient()

	_muzzle_particles_mat.initial_velocity_min = 15.0
	_muzzle_particles_mat.initial_velocity_max = 45.0
	_muzzle_particles_mat.damping_min = 15.0
	_muzzle_particles_mat.damping_max = 40.0

	_muzzle_effect.process_material = _muzzle_particles_mat

func update_beam(end_point: Vector2, is_hitting: bool) -> void:
	_beam_line.points = PackedVector2Array([Vector2.ZERO, end_point])

	var beam_length: float = end_point.length()
	var beam_mid: Vector2 = end_point * 0.5
	var length_delta: float = absf(beam_length - _last_beam_length)

	_beam_particles.position = beam_mid
	var box_half_width: float = maxf(_line_width * 0.7, 3.0)
	_beam_particles_mat.emission_box_extents = Vector3(box_half_width, beam_length * 0.5, 0.0)

	if _beam_particles.emitting and beam_length < _last_beam_length and length_delta > 25.0:
		_beam_particles.restart()

	if is_hitting:
		_collision_particles.position = end_point
		_collision_particles.emitting = true
	else:
		_collision_particles.emitting = false

	_last_beam_length = beam_length

func show_beam() -> void:
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	if _appear_tween and _appear_tween.is_running():
		_appear_tween.kill()

	visible = true
	_beam_particles.emitting = true
	_muzzle_effect.emitting = true

	# Daha yavaş, yumuşak açılma
	_appear_tween = create_tween()
	_appear_tween.tween_property(_beam_line, "width", _line_width, 0.25).from(0.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

func fade_out() -> void:
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	if _appear_tween and _appear_tween.is_running():
		_appear_tween.kill()
	if _pulse_tween and _pulse_tween.is_running():
		_pulse_tween.kill()

	_beam_particles.emitting = false
	_muzzle_effect.emitting = false
	_collision_particles.emitting = false

	# Daha yavaş, yumuşak kapanma
	_fade_tween = create_tween()
	_fade_tween.tween_property(_beam_line, "width", 0.0, 0.15).from(_beam_line.width).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
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

	# Width pulse - daha az agresif
	_pulse_tween.tween_property(_beam_line, "width", _line_width * 1.25, 0.08) \
		.from(_beam_line.width).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# Nazik parlaklık artışı
	_pulse_tween.tween_property(_beam_line, "modulate", Color(1.1, 1.0, 1.2, 1.0), 0.08) \
		.from(_beam_line.modulate).set_ease(Tween.EASE_OUT)

	_pulse_tween.tween_property(_beam_particles, "modulate", Color(1.1, 1.0, 1.2, 1.0), 0.08) \
		.from(_beam_particles.modulate).set_ease(Tween.EASE_OUT)

	# Geri dönüş - daha yavaş, smooth
	_pulse_tween.set_parallel(false)
	_pulse_tween.chain().tween_property(_beam_line, "width", _line_width, 0.22) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(_beam_line, "modulate", BEAM_MODULATE, 0.22) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(_beam_particles, "modulate", BEAM_MODULATE, 0.22) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

# ── Gradient ve Curve yardımcıları ──────────────────────────────

func _create_beam_scale_curve() -> CurveTexture:
	var curve := Curve.new()
	curve.clear_points()
	# Yumuşak çan eğrisi - yavaş büyü, yavaş küçül
	curve.add_point(Vector2(0.0, 0.0), 0.0, 2.0)
	curve.add_point(Vector2(0.3, 0.8), 0.5, 0.2)
	curve.add_point(Vector2(0.6, 1.0), 0.0, -0.3)
	curve.add_point(Vector2(1.0, 0.0), -1.5, 0.0)
	var tex := CurveTexture.new()
	tex.curve = curve
	return tex

func _create_casting_scale_curve() -> CurveTexture:
	var curve := Curve.new()
	curve.clear_points()
	# Smooth fade out
	curve.add_point(Vector2(0.0, 0.3), 0.0, 3.0)
	curve.add_point(Vector2(0.2, 1.0), 0.0, 0.0)
	curve.add_point(Vector2(0.6, 0.6), -0.5, -0.5)
	curve.add_point(Vector2(1.0, 0.0), -1.0, 0.0)
	var tex := CurveTexture.new()
	tex.curve = curve
	return tex

func _create_beam_gradient() -> GradientTexture1D:
	var gradient := Gradient.new()
	# 5 noktalı yumuşak geçiş
	gradient.offsets = PackedFloat32Array([0.0, 0.2, 0.5, 0.8, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.85, 0.7, 1.0, 0.7),   # Başlangıç - yumuşak lavanta
		Color(0.75, 0.55, 0.95, 0.55), # Erken orta
		Color(0.6, 0.4, 0.85, 0.35),   # Orta - solmaya başlıyor
		Color(0.45, 0.25, 0.7, 0.15),  # Geç orta
		Color(0.3, 0.15, 0.5, 0.0)     # Bitiş - tamamen şeffaf
	])
	var tex := GradientTexture1D.new()
	tex.gradient = gradient
	return tex

func _create_line_gradient() -> Gradient:
	var gradient := Gradient.new()
	# Beam boyunca yumuşak renk geçişi
	gradient.offsets = PackedFloat32Array([0.0, 0.15, 0.5, 0.85, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.9, 0.75, 1.0, 0.9),    # Muzzle - parlak
		Color(0.8, 0.6, 0.95, 0.8),    # Erken
		Color(0.7, 0.5, 0.9, 0.65),    # Orta
		Color(0.6, 0.4, 0.8, 0.4),     # Geç
		Color(0.45, 0.28, 0.65, 0.0)   # Uç - kaybolma
	])
	return gradient

func _create_width_curve() -> Curve:
	# Beam genişliği: başta ince, ortada normal, uçta sivrilen
	var curve := Curve.new()
	curve.clear_points()
	curve.add_point(Vector2(0.0, 0.7), 0.0, 1.0)
	curve.add_point(Vector2(0.15, 1.0), 0.3, 0.0)
	curve.add_point(Vector2(0.7, 1.0), 0.0, -0.3)
	curve.add_point(Vector2(1.0, 0.3), -1.5, 0.0)
	return curve
