class_name AsteroidDeathSpawner

## Asteroid olum aninda parcalanma ve item drop spawn islemlerini yonetir.
## Saf fonksiyonlar - state tutmaz, asteroid verisini parametre alir.

const ITEM_DROP_SCENE := preload("res://Scenes/Items/item_drop.tscn")

## Parcalanma sabitleri
const MAX_GENERATION := 2
const MIN_FRAGMENT_SCALE := 0.35

static func spawn_fragments(
		asteroid_pos: Vector2,
		asteroid_scale_x: float,
		asteroid_velocity: Vector2,
		asteroid_generation: int,
		asteroid_texture: Texture2D,
		scene_root: Node
	) -> void:
	# Cok kucukse parcalanma
	if asteroid_scale_x < MIN_FRAGMENT_SCALE:
		return

	# Max generation'a ulastiysa parcalanma
	if asteroid_generation >= MAX_GENERATION:
		return

	# Boyuta gore parca sayisi ve boyutu belirle
	var fragment_count: int
	var fragment_scale_range: Vector2

	if asteroid_scale_x >= 0.9:
		# BUYUK: 2 orta parca
		fragment_count = 2
		fragment_scale_range = Vector2(0.55, 0.75)
	elif asteroid_scale_x >= 0.5:
		# ORTA: 2-3 kucuk parca
		fragment_count = randi_range(2, 3)
		fragment_scale_range = Vector2(0.35, 0.45)
	else:
		# Kucuk ama yeterince buyuk: 2 mini parca
		fragment_count = 2
		fragment_scale_range = Vector2(0.25, 0.35)

	# Parcalari spawn et
	var scene := load("res://Scenes/Environment/asteroid.tscn") as PackedScene
	var angle_step := TAU / float(fragment_count)

	for i in fragment_count:
		var fragment := scene.instantiate()

		var angle := angle_step * i + randf_range(-0.4, 0.4)
		var frag_vel := asteroid_velocity + Vector2.from_angle(angle) * randf_range(70.0, 140.0)
		var frag_scale := randf_range(fragment_scale_range.x, fragment_scale_range.y)
		var frag_rot := randf_range(-1.2, 1.2)

		fragment.setup(asteroid_texture, frag_scale, frag_vel, frag_rot)
		fragment.generation = asteroid_generation + 1
		fragment.global_position = asteroid_pos + Vector2.from_angle(angle) * 20.0
		fragment.add_to_group("asteroid_active")

		scene_root.add_child(fragment)

static func spawn_item_drops(
		asteroid_pos: Vector2,
		asteroid_scale_x: float,
		scene_root: Node
	) -> void:
	if not scene_root:
		return

	# Kucuk asteroidler drop vermez
	if asteroid_scale_x < 0.3:
		return

	# Sabit drop tablosu: her asteroid iron ve/veya gold dusurur
	# Miktar asteroid scale ile orantili
	var drop_count := 1
	if asteroid_scale_x >= 0.8:
		drop_count = randi_range(2, 3)
	elif asteroid_scale_x >= 0.5:
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
		if asteroid_scale_x >= 0.9:
			amount = randi_range(2, 3)
		elif asteroid_scale_x >= 0.6:
			amount = randi_range(1, 2)

		drop.setup(item_id, amount, asteroid_pos)
		scene_root.add_child(drop)
