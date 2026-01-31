extends Node2D

@export var max_range := 500.0
@export var damage_per_second := 10.0
@export var damage_tick_seconds := 1.0

var _firing := false
var _raycast: RayCast2D
var _visual: Node2D
var _impact_effect: GPUParticles2D
var _damage_tick_timer: Timer
var _current_collider: Object = null
var _last_collider: Object = null
var _is_hitting := false

func _ready() -> void:
	_raycast = $RayCast2D
	_visual = $LaserBeamVisual
	_impact_effect = $ImpactEffect
	_setup_damage_timer()

	_raycast.target_position = Vector2(0, -max_range)
	_raycast.collision_mask = 2
	_raycast.collide_with_areas = true
	_raycast.collide_with_bodies = false
	_raycast.enabled = false

	_visual.visible = false
	_impact_effect.emitting = false

func _setup_damage_timer() -> void:
	_damage_tick_timer = Timer.new()
	_damage_tick_timer.wait_time = damage_tick_seconds
	_damage_tick_timer.one_shot = false
	_damage_tick_timer.autostart = false
	_damage_tick_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	add_child(_damage_tick_timer)
	_damage_tick_timer.timeout.connect(_on_damage_tick)

func _physics_process(delta: float) -> void:
	if not _firing:
		return

	_raycast.force_raycast_update()

	var beam_end: Vector2
	_is_hitting = false

	if _raycast.is_colliding():
		var hit_point := _raycast.get_collision_point()
		beam_end = to_local(hit_point)
		_is_hitting = true

		_current_collider = _raycast.get_collider()
		if _current_collider != _last_collider:
			_last_collider = _current_collider
			_damage_tick_timer.stop()
			_damage_tick_timer.wait_time = damage_tick_seconds
			_damage_tick_timer.start()
		elif _damage_tick_timer.is_stopped():
			_damage_tick_timer.wait_time = damage_tick_seconds
			_damage_tick_timer.start()
	else:
		beam_end = _raycast.target_position
		_current_collider = null
		_last_collider = null
		_damage_tick_timer.stop()

	_visual.update_beam(beam_end, _is_hitting)
	_impact_effect.set_hit_mode(_is_hitting)

	if _is_hitting:
		_impact_effect.global_position = _raycast.get_collision_point()
	else:
		_impact_effect.global_position = to_global(beam_end)

	_impact_effect.emitting = true

func start_firing() -> void:
	if _firing:
		return
	_firing = true
	_current_collider = null
	_last_collider = null
	_damage_tick_timer.stop()
	_raycast.enabled = true
	_visual.visible = true
	_visual.show_beam()

func stop_firing() -> void:
	if not _firing:
		return
	_firing = false
	_current_collider = null
	_last_collider = null
	_damage_tick_timer.stop()
	_raycast.enabled = false
	_impact_effect.emitting = false
	_visual.fade_out()

func _on_damage_tick() -> void:
	if not _is_hitting:
		_damage_tick_timer.stop()
		return
	if not _current_collider:
		_damage_tick_timer.stop()
		return
	if _current_collider.has_method("take_damage"):
		_current_collider.take_damage(damage_per_second * damage_tick_seconds)
		if _current_collider.has_method("impact_pulse"):
			_current_collider.impact_pulse()
	if _impact_effect.has_method("pulse"):
		_impact_effect.pulse()
	if _visual.has_method("pulse_hit"):
		_visual.pulse_hit()
	_play_impact_sound()

func _play_impact_sound() -> void:
	# TODO: Ses efekti eklendiğinde buraya entegre edilecek
	# $ImpactSound.play()
	pass
