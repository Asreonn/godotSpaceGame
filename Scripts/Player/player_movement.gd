extends CharacterBody2D


const MAX_SPEED = 200.0
const ACCELERATION = 400.0
const FRICTION = 100.0
const BOOST_FORCE = 900.0
const MAX_BOOST_SPEED = 450.0

@onready var laser_beam = $LaserBeam


func _physics_process(delta: float) -> void:
	var horizontal := Input.get_axis("ui_left", "ui_right")
	var vertical := Input.get_axis("ui_up", "ui_down")

	var input_dir := Vector2(horizontal, vertical)
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()

	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * MAX_SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	if Input.is_action_pressed("boost"):
		var facing := Vector2.UP.rotated(rotation)
		velocity += facing * BOOST_FORCE * delta
		if velocity.length() > MAX_BOOST_SPEED:
			velocity = velocity.normalized() * MAX_BOOST_SPEED

	var mouse_pos := get_global_mouse_position()
	rotation = (mouse_pos - global_position).angle() + PI / 2

	if Input.is_action_pressed("fire_weapon"):
		laser_beam.start_firing()
	else:
		laser_beam.stop_firing()

	move_and_slide()
