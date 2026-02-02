extends CharacterBody2D


const MAX_SPEED = 200.0
const ACCELERATION = 400.0
const FRICTION = 100.0
const BOOST_FORCE = 900.0
const MAX_BOOST_SPEED = 450.0
const BEAM_RECOIL_FORCE = 120.0

@onready var laser_beam = $LaserBeam
@onready var ship_inventory: InventoryComponent = $ShipInventory

var _nearby_base: Node2D = null  ## Su an yakininda olan base
var _beam_enabled := true

func _ready() -> void:
	add_to_group("player")

func get_inventory() -> InventoryComponent:
	return ship_inventory

func set_nearby_base(base: Node2D) -> void:
	_nearby_base = base

func set_beam_enabled(enabled: bool) -> void:
	_beam_enabled = enabled
	if not _beam_enabled and laser_beam:
		laser_beam.stop_firing()

func is_beam_enabled() -> bool:
	return _beam_enabled

func get_nearby_base() -> Node2D:
	return _nearby_base

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
	var aim_dir := mouse_pos - global_position
	if aim_dir.length() > 0.001:
		aim_dir = aim_dir.normalized()
	else:
		aim_dir = Vector2.UP
	rotation = aim_dir.angle() + PI / 2

	if _beam_enabled and Input.is_action_pressed("fire_weapon"):
		laser_beam.start_firing()
		if laser_beam.is_firing():
			velocity += -aim_dir * BEAM_RECOIL_FORCE * delta
	else:
		laser_beam.stop_firing()

	move_and_slide()
