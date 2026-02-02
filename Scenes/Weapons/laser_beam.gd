extends Node2D

@export var max_range := 500.0
@export var damage_per_second := 10.0
@export var damage_tick_seconds := 1.0
@export var max_heat := 300.0
@export var heat_per_second := 33.0
@export var cooling_rate := 80.0
@export var overheat_cooldown_duration := 6.0

var _firing := false
var _raycast: RayCast2D
var _visual: Node2D
var _impact_effect: GPUParticles2D
@onready var _damage_tick_timer: Timer = $DamageTickTimer
var _current_collider: Object = null
var _last_collider: Object = null
var _is_hitting := false
var _current_heat := 0.0
var _is_overheated := false
var _cooldown_timer := 0.0

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
	_damage_tick_timer.wait_time = damage_tick_seconds
	_damage_tick_timer.one_shot = false
	_damage_tick_timer.autostart = false
	_damage_tick_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	_damage_tick_timer.timeout.connect(_on_damage_tick)

func _physics_process(delta: float) -> void:
	_update_heat(delta)
	_update_heat_visual(delta)

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
	if not can_fire():
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
	if _current_collider is Node2D:
		Events.laser_damage_requested.emit(_current_collider, damage_per_second * damage_tick_seconds)
		Events.laser_impact_pulse_requested.emit(_current_collider)
	_impact_effect.pulse()
	_visual.pulse_hit()
	_play_impact_sound()

func can_fire() -> bool:
	return not _is_overheated and _cooldown_timer <= 0.0

func is_firing() -> bool:
	return _firing

func get_heat_ratio() -> float:
	if max_heat <= 0.0:
		return 0.0
	return clampf(_current_heat / max_heat, 0.0, 1.0)

func is_overheated() -> bool:
	return _is_overheated

func get_cooldown_progress() -> float:
	if not _is_overheated:
		return 0.0
	if overheat_cooldown_duration <= 0.0:
		return 1.0
	return clampf(1.0 - (_cooldown_timer / overheat_cooldown_duration), 0.0, 1.0)

func get_cooldown_remaining() -> float:
	return maxf(_cooldown_timer, 0.0)

func _update_heat(delta: float) -> void:
	if _firing and not _is_overheated:
		_current_heat += heat_per_second * delta
		if _current_heat >= max_heat:
			_current_heat = max_heat
			_enter_overheat()
	else:
		_current_heat = maxf(_current_heat - cooling_rate * delta, 0.0)

	if _is_overheated:
		_cooldown_timer = maxf(_cooldown_timer - delta, 0.0)
		if _cooldown_timer <= 0.0:
			_is_overheated = false
			_current_heat = 0.0

func _enter_overheat() -> void:
	if _is_overheated:
		return
	_is_overheated = true
	_cooldown_timer = maxf(overheat_cooldown_duration, 0.0)
	stop_firing()

func _update_heat_visual(delta: float) -> void:
	if _visual:
		_visual.set_heat_level(get_heat_ratio(), _is_overheated, delta)

func _play_impact_sound() -> void:
	# TODO: Ses efekti eklendiğinde buraya entegre edilecek
	# $ImpactSound.play()
	pass
