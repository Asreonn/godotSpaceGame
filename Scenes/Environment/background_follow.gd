extends ColorRect

## Kamerayi takip ederek her zaman ekrani kaplayan arka plan.

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if not camera:
		return
	var cam_pos := camera.global_position
	var zoom := camera.zoom
	# Viewport boyutunu zoom'a gore hesapla
	var vp_size := get_viewport().get_visible_rect().size / zoom
	var half := vp_size * 0.5
	# ColorRect'i kameranin gorunur alanina yerlestir (biraz margin ile)
	position = cam_pos - half * 1.1
	size = vp_size * 1.1
