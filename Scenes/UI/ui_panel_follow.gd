extends PanelContainer

## Viewport boyutuna gore kendini yeniden boyutlandiran UI panel.
## CanvasLayer icinde oldugu icin koordinatlar ekran bazli (0,0 = sol ust).

func _ready() -> void:
	_update_size()
	get_viewport().size_changed.connect(_update_size)

func _update_size() -> void:
	var vp := get_viewport()
	if not vp:
		return
	var vp_size := vp.get_visible_rect().size
	position = Vector2.ZERO
	size = vp_size
