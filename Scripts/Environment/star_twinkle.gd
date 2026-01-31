extends Sprite2D

signal loop_completed(star: Node)

var base_scale := 1.0
var twinkle_speed := 1.0
var rotation_speed := 0.0
var _time := 0.0
var retiring := false

const CYCLE_DURATION := 2.5
const MIN_SCALE_FACTOR := 0.05
const MAX_SCALE_FACTOR := 0.7
const GLOW_STRENGTH := 1.6

static var _material_cache: CanvasItemMaterial

func setup(
		tex: Texture2D,
		base_scale_value: float,
		twinkle_speed_value: float,
		rotation_speed_value: float
	) -> void:
	texture = tex
	base_scale = base_scale_value * 0.5
	twinkle_speed = twinkle_speed_value
	rotation_speed = rotation_speed_value
	_time = 0.0
	retiring = false
	scale = Vector2.ONE * base_scale * MIN_SCALE_FACTOR
	material = _get_additive_material()
	self_modulate = Color(1.0, 1.0, 1.0, 0.0)

func _process(delta: float) -> void:
	if retiring:
		return
	rotation += rotation_speed * delta
	_time += delta * twinkle_speed

	var duration := CYCLE_DURATION
	if _time >= duration:
		retiring = true
		loop_completed.emit(self)
		queue_free()
		return

	var phase := _time / duration
	# sin curve: 0 -> 1 -> 0 (small -> big -> small)
	var t := sin(phase * PI)
	var s := lerpf(MIN_SCALE_FACTOR, MAX_SCALE_FACTOR, t) * base_scale
	scale = Vector2.ONE * s

	var glow := lerpf(1.0, GLOW_STRENGTH, t)
	self_modulate = Color(glow, glow, glow, lerpf(0.0, 1.0, t))

static func _get_additive_material() -> CanvasItemMaterial:
	if _material_cache != null:
		return _material_cache
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_material_cache = mat
	return mat
