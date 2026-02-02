extends Area2D

const EXPLOSION_SCENE := preload("res://Scenes/VFX/asteroid_explosion.tscn")
const ITEM_DROP_SCENE := preload("res://Scenes/Items/item_drop.tscn")

signal destroyed(asteroid: Area2D)

@export var max_health := 100.0
@export var size_multiplier: float = 0.85

var velocity := Vector2.ZERO
var rotation_speed := 0.0
var current_health := 100.0
var generation := 0  # 0=orijinal, 1=birinci parça, 2=ikinci parça
var _scale_initialized := false

# Parçalanma sabitleri
const MAX_GENERATION := 2
const MIN_FRAGMENT_SCALE := 0.35  # Bu altındakiler parçalanmaz (küçültülmüş)

@onready var _sprite: Sprite2D = $Sprite2D

var _flash_tween: Tween
var _impact_tween: Tween
var _fadeout_tween: Tween
var _is_fading_out := false

func configure_motion(vel: Vector2, rot_speed: float) -> void:
	velocity = vel
	rotation_speed = rot_speed

func setup(tex: Texture2D, base_scale: float, vel: Vector2, rot_speed: float) -> void:
	configure_motion(vel, rot_speed)
	scale = Vector2.ONE * base_scale * size_multiplier
	_scale_initialized = true

	if _sprite:
		_sprite.texture = tex

	collision_layer = 2
	collision_mask = 0

	_apply_health_from_scale(base_scale)
	current_health = max_health

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	if not _scale_initialized:
		var raw_scale: float = scale.x
		scale *= size_multiplier
		_apply_health_from_scale(raw_scale)
		current_health = max_health

func _apply_health_from_scale(base_scale: float) -> void:
	var min_scale: float = 0.4
	var max_scale: float = 1.2
	var ratio: float = clampf((base_scale - min_scale) / (max_scale - min_scale), 0.0, 1.0)
	max_health = lerpf(30.0, 120.0, ratio)

func take_damage(amount: float) -> void:
	current_health -= amount
	_flash_white()
	impact_pulse()
	if current_health <= 0.0:
		_explode()

func _flash_white() -> void:
	if _flash_tween and _flash_tween.is_running():
		_flash_tween.kill()
	if _sprite:
		_sprite.modulate = Color(1.0, 0.85, 1.0, 1.0)
		_flash_tween = create_tween()
		_flash_tween.tween_property(_sprite, "modulate", Color(1, 1, 1, 1), 0.15)

func impact_pulse() -> void:
	if not _sprite:
		return
	if _impact_tween and _impact_tween.is_running():
		_impact_tween.kill()
	var base_scale := _sprite.scale
	_impact_tween = create_tween()
	_impact_tween.tween_property(_sprite, "scale", base_scale * 1.08, 0.05).from(base_scale)
	_impact_tween.tween_property(_sprite, "scale", base_scale, 0.12)

func _explode() -> void:
	_spawn_explosion_particles()
	_trigger_screen_shake()
	_play_explosion_sound()  # Placeholder - ses dosyasi eklenince calisacak
	_spawn_fragments()  # Simdi generation bazli kontrol yapiyor
	_spawn_item_drops()
	destroyed.emit(self)
	queue_free()

func _trigger_screen_shake() -> void:
	# Asteroid boyutuna göre shake intensity hesapla
	var shake_intensity := remap(scale.x, 0.4, 1.2, 1.5, 8.0)
	shake_intensity = clampf(shake_intensity, 1.5, 8.0)
	
	# Kamerayı bul ve shake tetikle
	var camera := get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(shake_intensity)

func _play_explosion_sound() -> void:
	# TODO: Ses efekti eklendiğinde buraya entegre edilecek
	# Boyuta göre farklı pitch:
	# var pitch := remap(scale.x, 0.4, 1.2, 1.3, 0.7)
	# $AudioStreamPlayer.pitch_scale = pitch
	# $AudioStreamPlayer.play()
	pass

func start_fadeout() -> void:
	if _is_fading_out:
		return
	_is_fading_out = true
	
	# Mevcut scale'i kaydet
	var current_scale := scale
	
	# Boyuta göre fade süresi - büyük asteroidler daha yavaş kaybolur
	var fade_duration := remap(current_scale.x, 0.4, 1.2, 0.3, 0.8)
	fade_duration = clampf(fade_duration, 0.3, 0.8)
	
	# Boyuta göre küçülme oranı - büyük asteroidler daha az küçülür
	var shrink_factor := remap(current_scale.x, 0.4, 1.2, 0.5, 0.75)
	shrink_factor = clampf(shrink_factor, 0.5, 0.75)
	
	if _fadeout_tween and _fadeout_tween.is_running():
		_fadeout_tween.kill()
	
	_fadeout_tween = create_tween()
	_fadeout_tween.set_parallel(true)
	
	# Modulate alpha'yı azalt (fade out)
	if _sprite:
		_fadeout_tween.tween_property(_sprite, "modulate:a", 0.0, fade_duration).from(_sprite.modulate.a)
	
	# Scale'i boyuta göre küçült
	var target_scale := current_scale * shrink_factor
	_fadeout_tween.tween_property(self, "scale", target_scale, fade_duration).from(current_scale)
	
	# Tween bitince queue_free
	_fadeout_tween.set_parallel(false)
	_fadeout_tween.chain().tween_callback(queue_free)

func _spawn_explosion_particles() -> void:
	var scene := get_tree().current_scene
	if not scene:
		return
	var explosion := EXPLOSION_SCENE.instantiate()
	explosion.global_position = global_position
	explosion.z_index = z_index - 1  # Asteroidlerin arkasinda, yildizlarin ustunde
	scene.add_child(explosion)
	# Doğrudan asteroidin gerçek ekran scale'ini gönder
	# play() bu değere göre tüm materyal özelliklerini ayarlayacak
	explosion.play(scale.x)

func _spawn_fragments() -> void:
	var current_scale := scale.x
	
	# Çok küçükse parçalanma
	if current_scale < MIN_FRAGMENT_SCALE:
		return
	
	# Max generation'a ulaştıysa parçalanma
	if generation >= MAX_GENERATION:
		return
	
	# Boyuta göre parça sayısı ve boyutu belirle
	var fragment_count: int
	var fragment_scale_range: Vector2
	
	if current_scale >= 0.9:
		# BÜYÜK: 2 orta parça
		fragment_count = 2
		fragment_scale_range = Vector2(0.55, 0.75)
	elif current_scale >= 0.5:
		# ORTA: 2-3 küçük parça
		fragment_count = randi_range(2, 3)
		fragment_scale_range = Vector2(0.35, 0.45)
	else:
		# Küçük ama yeterince büyük: 2 mini parça
		fragment_count = 2
		fragment_scale_range = Vector2(0.25, 0.35)
	
	# Parçaları spawn et
	var tex := _sprite.texture
	var scene := load("res://Scenes/Environment/asteroid.tscn") as PackedScene
	
	var angle_step := TAU / float(fragment_count)
	
	for i in fragment_count:
		var fragment := scene.instantiate()
		
		var angle := angle_step * i + randf_range(-0.4, 0.4)
		var frag_vel := velocity + Vector2.from_angle(angle) * randf_range(70.0, 140.0)
		var frag_scale := randf_range(fragment_scale_range.x, fragment_scale_range.y)
		var frag_rot := randf_range(-1.2, 1.2)
		
		fragment.setup(tex, frag_scale, frag_vel, frag_rot)
		fragment.generation = generation + 1  # Bir sonraki generation
		fragment.global_position = global_position + Vector2.from_angle(angle) * 20.0
		
		get_tree().current_scene.add_child(fragment)

func _spawn_item_drops() -> void:
	var scene := get_tree().current_scene
	if not scene:
		return

	var current_scale := scale.x

	# Kucuk asteroidler drop vermez
	if current_scale < 0.3:
		return

	# Sabit drop tablosu: her asteroid iron ve/veya gold dusurur
	# Miktar asteroid scale ile orantili
	var drop_count := 1
	if current_scale >= 0.8:
		drop_count = randi_range(2, 3)
	elif current_scale >= 0.5:
		drop_count = randi_range(1, 2)

	for i in drop_count:
		var drop: Area2D = ITEM_DROP_SCENE.instantiate()

		# Esit oran: %50 Iron, %50 Gold
		var roll := randf()
		var item_id: String
		if roll < 0.5:
			item_id = "iron"
		else:
			item_id = "gold"

		# Miktar: scale bazli 1-3
		var amount := 1
		if current_scale >= 0.9:
			amount = randi_range(2, 3)
		elif current_scale >= 0.6:
			amount = randi_range(1, 2)

		drop.setup(item_id, amount, global_position)
		scene.add_child(drop)

func _process(delta: float) -> void:
	position += velocity * delta
	rotation += rotation_speed * delta
