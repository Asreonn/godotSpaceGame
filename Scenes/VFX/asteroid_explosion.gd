extends Node2D

## Asteroid boyutuna tam orantılı, kompakt patlama efekti.
## Tüm materyal değerleri doğrudan asteroid boyutuna göre ayarlanır.

@export var cleanup_delay: float = 0.4

# Particle katmanları
@onready var _flash: GPUParticles2D = $Flash
@onready var _core: GPUParticles2D = $CoreBurst
@onready var _embers: GPUParticles2D = $Embers
@onready var _sparks: GPUParticles2D = $Sparks
@onready var _smoke: GPUParticles2D = $Smoke
@onready var _glow_ring: GPUParticles2D = $GlowRing

var _cleanup_timer: SceneTreeTimer


func play(asteroid_scale: float = 1.0) -> void:
	var s: float = clampf(asteroid_scale, 0.25, 1.5)
	var t: float = inverse_lerp(0.25, 1.5, s)

	# Node scale - minimal patlama
	var node_scale: float = lerpf(0.2, 0.7, ease(t, 0.7))
	scale = Vector2.ONE * node_scale

	_configure_flash(t)
	_configure_core(t)
	_configure_embers(t)
	_configure_sparks(t)
	_configure_smoke(t)
	_configure_glow_ring(t)

	_emit_all(t)


# ── FLASH ────────────────────────────────────────────────────────
func _configure_flash(t: float) -> void:
	var mat: ParticleProcessMaterial = _flash.process_material

	_flash.amount = maxi(1, int(lerpf(1.0, 3.0, t)))
	_flash.lifetime = lerpf(0.08, 0.15, t)

	mat.emission_sphere_radius = lerpf(0.3, 2.0, t)
	mat.initial_velocity_min = lerpf(1.0, 4.0, t)
	mat.initial_velocity_max = lerpf(3.0, 12.0, t)
	mat.scale_min = lerpf(0.5, 1.2, t)
	mat.scale_max = lerpf(1.0, 2.2, t)
	mat.damping_min = lerpf(15.0, 30.0, t)
	mat.damping_max = lerpf(25.0, 50.0, t)


# ── CORE BURST ───────────────────────────────────────────────────
func _configure_core(t: float) -> void:
	var mat: ParticleProcessMaterial = _core.process_material

	_core.amount = maxi(3, int(lerpf(6.0, 18.0, ease(t, 1.3))))
	_core.lifetime = lerpf(0.25, 0.5, t)
	_core.speed_scale = lerpf(1.1, 0.85, t)

	mat.emission_sphere_radius = lerpf(1.0, 5.0, t)
	mat.initial_velocity_min = lerpf(15.0, 35.0, t)
	mat.initial_velocity_max = lerpf(35.0, 75.0, t)
	mat.damping_min = lerpf(35.0, 70.0, t)
	mat.damping_max = lerpf(70.0, 130.0, t)
	mat.scale_min = lerpf(0.15, 0.4, t)
	mat.scale_max = lerpf(0.4, 0.9, t)


# ── EMBERS ───────────────────────────────────────────────────────
func _configure_embers(t: float) -> void:
	var mat: ParticleProcessMaterial = _embers.process_material

	_embers.amount = maxi(3, int(lerpf(5.0, 20.0, ease(t, 1.2))))
	_embers.lifetime = lerpf(0.3, 0.7, t)
	_embers.speed_scale = lerpf(1.0, 0.8, t)

	mat.emission_sphere_radius = lerpf(1.5, 5.0, t)
	mat.initial_velocity_min = lerpf(8.0, 22.0, t)
	mat.initial_velocity_max = lerpf(22.0, 50.0, t)
	mat.damping_min = lerpf(18.0, 40.0, t)
	mat.damping_max = lerpf(40.0, 80.0, t)
	mat.scale_min = lerpf(0.06, 0.15, t)
	mat.scale_max = lerpf(0.2, 0.4, t)
	mat.gravity = Vector3(0, lerpf(3.0, 8.0, t), 0)


# ── SPARKS ───────────────────────────────────────────────────────
func _configure_sparks(t: float) -> void:
	var mat: ParticleProcessMaterial = _sparks.process_material

	_sparks.amount = maxi(2, int(lerpf(3.0, 10.0, ease(t, 1.4))))
	_sparks.lifetime = lerpf(0.15, 0.35, t)
	_sparks.speed_scale = lerpf(1.1, 0.9, t)

	mat.emission_sphere_radius = lerpf(0.8, 3.0, t)
	mat.initial_velocity_min = lerpf(30.0, 65.0, t)
	mat.initial_velocity_max = lerpf(65.0, 130.0, t)
	mat.damping_min = lerpf(40.0, 90.0, t)
	mat.damping_max = lerpf(80.0, 160.0, t)
	mat.scale_min = lerpf(0.03, 0.07, t)
	mat.scale_max = lerpf(0.08, 0.16, t)
	mat.gravity = Vector3(0, lerpf(6.0, 15.0, t), 0)


# ── SMOKE ────────────────────────────────────────────────────────
func _configure_smoke(t: float) -> void:
	var mat: ParticleProcessMaterial = _smoke.process_material

	_smoke.amount = maxi(2, int(lerpf(2.0, 10.0, ease(t, 1.6))))
	_smoke.lifetime = lerpf(0.4, 1.0, t)
	_smoke.speed_scale = lerpf(0.85, 0.55, t)

	mat.emission_sphere_radius = lerpf(1.5, 6.0, t)
	mat.initial_velocity_min = lerpf(0.8, 3.0, t)
	mat.initial_velocity_max = lerpf(3.0, 8.0, t)
	mat.damping_min = lerpf(3.0, 8.0, t)
	mat.damping_max = lerpf(6.0, 15.0, t)
	mat.scale_min = lerpf(0.25, 0.8, t)
	mat.scale_max = lerpf(0.6, 1.5, t)


# ── GLOW RING ────────────────────────────────────────────────────
func _configure_glow_ring(t: float) -> void:
	var mat: ParticleProcessMaterial = _glow_ring.process_material

	_glow_ring.amount = 1
	_glow_ring.lifetime = lerpf(0.15, 0.4, t)
	_glow_ring.speed_scale = lerpf(1.3, 0.8, t)

	mat.scale_min = lerpf(0.25, 0.5, t)
	mat.scale_max = lerpf(0.25, 0.5, t)


# ── EMIT ─────────────────────────────────────────────────────────
func _emit_all(t: float) -> void:
	_restart(_flash)
	_restart(_core)
	_restart(_glow_ring)
	_restart(_sparks)

	var ember_delay: float = lerpf(0.015, 0.04, t)
	get_tree().create_timer(ember_delay).timeout.connect(func():
		if is_instance_valid(_embers):
			_restart(_embers)
	)

	var smoke_delay: float = lerpf(0.03, 0.08, t)
	get_tree().create_timer(smoke_delay).timeout.connect(func():
		if is_instance_valid(_smoke):
			_restart(_smoke)
	)

	var max_lt: float = 0.0
	for node in [_flash, _core, _embers, _sparks, _smoke, _glow_ring]:
		if node:
			var effective: float = node.lifetime / maxf(node.speed_scale, 0.1)
			max_lt = maxf(max_lt, effective)

	_cleanup_timer = get_tree().create_timer(max_lt + smoke_delay + cleanup_delay)
	_cleanup_timer.timeout.connect(_cleanup)


func _cleanup() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(queue_free)


func _restart(p: GPUParticles2D) -> void:
	if p and is_instance_valid(p):
		p.emitting = true
		p.restart()
