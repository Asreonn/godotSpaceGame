extends Camera2D

@export var target_path: NodePath
@export var follow_speed := 5.0

var _target: Node2D

func _ready() -> void:
	_target = get_node_or_null(target_path)
	if _target:
		global_position = _target.global_position

func _physics_process(delta: float) -> void:
	if _target == null:
		return
	global_position = global_position.lerp(_target.global_position, follow_speed * delta)
