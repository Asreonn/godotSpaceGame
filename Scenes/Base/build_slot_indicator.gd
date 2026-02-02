extends Node2D
class_name BuildSlotIndicator

@onready var rect: ColorRect = $Rect

func _ready() -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(rect, "color:a", 0.3, 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(rect, "color:a", 0.1, 0.8).set_trans(Tween.TRANS_SINE)
