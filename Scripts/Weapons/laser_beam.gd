extends Node2D

@export var max_range := 500.0
@export var damage_per_second := 50.0

var _firing := false
var _raycast: RayCast2D
var _visual: Node2D
var _impact_effect: GPUParticles2D

func _ready() -> void:
	_raycast = $RayCast2D
	_visual = $LaserBeamVisual
	_impact_effect = $ImpactEffect

	_raycast.target_position = Vector2(0, -max_range)
	_raycast.collision_mask = 2
	_raycast.collide_with_areas = true
	_raycast.collide_with_bodies = false
	_raycast.enabled = false

	_visual.visible = false
	_impact_effect.emitting = false

func _physics_process(delta: float) -> void:
	if not _firing:
		return

	_raycast.force_raycast_update()

	var beam_end: Vector2
	var is_hitting := false

	if _raycast.is_colliding():
		var hit_point := _raycast.get_collision_point()
		beam_end = to_local(hit_point)
		is_hitting = true

		var collider = _raycast.get_collider()
		if collider and collider.has_method("take_damage"):
			collider.take_damage(damage_per_second * delta)
	else:
		beam_end = _raycast.target_position

	_visual.update_beam(beam_end, is_hitting)
	_impact_effect.set_hit_mode(is_hitting)

	if is_hitting:
		_impact_effect.global_position = _raycast.get_collision_point()
	else:
		_impact_effect.global_position = to_global(beam_end)

	_impact_effect.emitting = true

func start_firing() -> void:
	if _firing:
		return
	_firing = true
	_raycast.enabled = true
	_visual.visible = true
	_visual.show_beam()

func stop_firing() -> void:
	if not _firing:
		return
	_firing = false
	_raycast.enabled = false
	_impact_effect.emitting = false
	_visual.fade_out()
