extends CharacterBody2D


const SPEED = 300.0


func _physics_process(delta: float) -> void:
	var horizontal := Input.get_axis("ui_left", "ui_right")
	var vertical := Input.get_axis("ui_up","ui_down")
	if horizontal:
		velocity.x = horizontal * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if vertical:
		velocity.y = vertical * SPEED
	else:
		velocity.y = move_toward(velocity.y,0,SPEED)
		
	var mouse_pos := get_global_mouse_position()
	rotation = (mouse_pos - global_position).angle() + PI / 2

	move_and_slide()
