extends AnimatedSprite2D

const ANIM_NAME := &"twinkle"
const FRAME_COUNT := 13
const BASE_FPS := 18.0

static var frames_cache: Dictionary = {}

signal loop_completed(star: Node)

var base_scale := 1.0
var twinkle_speed := 1.0
var rotation_speed := 0.0
var frame_index := FRAME_COUNT - 1
var frame_dir := -1
var frame_accum := 0.0
var retiring := false

func setup(
		texture: Texture2D,
		base_scale_value: float,
		twinkle_speed_value: float,
		rotation_speed_value: float
	) -> void:
	base_scale = base_scale_value * 0.5
	twinkle_speed = twinkle_speed_value
	rotation_speed = rotation_speed_value
	_ensure_frames(texture)
	animation = ANIM_NAME
	stop()
	frame_index = FRAME_COUNT - 1
	frame_dir = -1
	frame = frame_index
	frame_progress = 0.0
	frame_accum = 0.0
	scale = Vector2.ONE * base_scale
	retiring = false

func _process(delta: float) -> void:
	rotation += rotation_speed * delta
	_advance_frames(delta)

func _advance_frames(delta: float) -> void:
	if retiring:
		return
	frame_accum += delta * BASE_FPS * twinkle_speed
	while frame_accum >= 1.0:
		frame_accum -= 1.0
		_step_frame()

func _step_frame() -> void:
	if retiring:
		return
	frame_index += frame_dir
	if frame_index >= FRAME_COUNT - 1:
		frame_index = FRAME_COUNT - 1
		frame_dir = -1
		retiring = true
		loop_completed.emit(self)
		queue_free()
	elif frame_index <= 0:
		frame_index = 0
		frame_dir = 1
	frame = frame_index

func _ensure_frames(texture: Texture2D) -> void:
	if texture == null:
		return
	var key := _get_texture_key(texture)
	if frames_cache.has(key):
		sprite_frames = frames_cache[key]
		return
	var frames := SpriteFrames.new()
	frames.add_animation(ANIM_NAME)
	frames.set_animation_speed(ANIM_NAME, 12.0)
	frames.set_animation_loop(ANIM_NAME, true)
	var size := texture.get_size()
	var frame_height := size.y / float(FRAME_COUNT)
	for i in range(FRAME_COUNT):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(0.0, i * frame_height, size.x, frame_height)
		frames.add_frame(ANIM_NAME, atlas)
	frames_cache[key] = frames
	sprite_frames = frames

func _get_texture_key(texture: Texture2D) -> String:
	if texture.resource_path != "":
		return texture.resource_path
	return str(texture.get_instance_id())
