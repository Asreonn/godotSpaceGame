extends Camera2D

@export var target_path: NodePath
@export var follow_speed := 5.0
@export var shake_decay := 5.0  # Titreşimin azalma hızı

# Zoom ayarları
@export_group("Zoom Settings")
@export var zoom_min := 1.0  # En yakın (normal)
@export var zoom_max := 5.0  # En uzak
@export var zoom_speed := 8.0  # Zoom geçiş hızı (smooth)
@export var zoom_step := 0.3  # Her scroll/tuş basımında zoom değişimi
@export var mouse_wheel_enabled := true
@export var keyboard_zoom_enabled := true

@onready var _target: Node2D = get_node_or_null(target_path)
var _shake_strength := 0.0
var _shake_offset := Vector2.ZERO
var _target_zoom := 1.0  # Hedef zoom seviyesi
var _current_zoom := 1.0  # Mevcut zoom seviyesi

func _ready() -> void:
	if _target:
		global_position = _target.global_position
	Events.camera_shake_requested.connect(_on_camera_shake_requested)
	
	# Başlangıç zoom'u ayarla
	_target_zoom = zoom_min
	_current_zoom = zoom_min
	zoom = Vector2.ONE / _current_zoom

func _process(delta: float) -> void:
	# Zoom input kontrolü
	_handle_zoom_input(delta)

func _physics_process(delta: float) -> void:
	if _target == null:
		return
	
	# Shake azalması
	if _shake_strength > 0.0:
		_shake_strength = max(0.0, _shake_strength - shake_decay * delta)
		_shake_offset = Vector2(
			randf_range(-_shake_strength, _shake_strength),
			randf_range(-_shake_strength, _shake_strength)
		)
	else:
		_shake_offset = Vector2.ZERO
	
	# Smooth zoom geçişi
	_current_zoom = lerpf(_current_zoom, _target_zoom, zoom_speed * delta)
	zoom = Vector2.ONE / _current_zoom
	
	# Hedefi takip et + shake offset
	var target_pos := _target.global_position + _shake_offset
	global_position = global_position.lerp(target_pos, follow_speed * delta)

func shake(intensity: float) -> void:
	# Mevcut shake'den daha güçlüyse değiştir
	_shake_strength = max(_shake_strength, intensity)

func _on_camera_shake_requested(intensity: float) -> void:
	shake(intensity)

func _handle_zoom_input(delta: float) -> void:
	# Zoom In (E tuşu veya mouse wheel up)
	if Input.is_action_just_pressed("zoom_in"):
		zoom_in()
	
	# Zoom Out (Q tuşu veya mouse wheel down)
	if Input.is_action_just_pressed("zoom_out"):
		zoom_out()
	
	# Sürekli basılı tutma desteği (tuşlar için)
	if keyboard_zoom_enabled:
		if Input.is_action_pressed("zoom_in"):
			_target_zoom = clampf(_target_zoom - zoom_step * delta * 1.5, zoom_min, zoom_max)
		elif Input.is_action_pressed("zoom_out"):
			_target_zoom = clampf(_target_zoom + zoom_step * delta * 1.5, zoom_min, zoom_max)

func zoom_in() -> void:
	_target_zoom = clampf(_target_zoom - zoom_step, zoom_min, zoom_max)

func zoom_out() -> void:
	_target_zoom = clampf(_target_zoom + zoom_step, zoom_min, zoom_max)

func set_zoom_level(level: float) -> void:
	_target_zoom = clampf(level, zoom_min, zoom_max)

func reset_zoom() -> void:
	_target_zoom = zoom_min
