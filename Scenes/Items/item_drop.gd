class_name ItemDrop
extends Area2D

## Dunyada yere dusen toplanabilir item.
## Miknatis gibi gemiye cekilir, yeterince yakinsa otomatik toplanir.
## Envanterden atildiginda gemiden hedefe dogru firlatilir.

@export var item_id: String = ""
@export var amount: int = 1

## Miknatis ayarlari
@export var magnet_radius: float = 80.0    ## Cekim mesafesi (arttirildi)
@export var pickup_radius: float = 45.0    ## Bu mesafede envantere eklenir (arttirildi)
@export var magnet_speed: float = 400.0    ## Cekim hizi
@export var magnet_acceleration: float = 900.0  ## Cekim ivmesi

## Spawn animasyonu
@export var scatter_force: float = 120.0   ## Patlama sonrasi dagılma gucu

const GLOW_BOOST := 2.8

var _target: Node2D = null  ## Cekilecek hedef (Player)
var _velocity: Vector2 = Vector2.ZERO
var _current_speed: float = 0.0
var _spawn_timer: float = 0.0
var _spawn_delay: float = 0.3  ## Spawn sonrasi miknatis gecikmesi
var _is_being_picked_up: bool = false
var _no_scatter: bool = false  ## true ise spawn scatter hareketi yapilmaz

# --- Firlatma (launch) sistemi ---
var _launching: bool = false
var _launch_target: Vector2 = Vector2.ZERO
var _launch_arrived: bool = false

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	monitoring = false
	monitorable = true

	var col_shape: CollisionShape2D = $CollisionShape2D
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	col_shape.shape = shape

	_update_visual()

	# Firlatma modunu kontrol et (meta'dan)
	if has_meta("launch_velocity") and has_meta("launch_target"):
		_launching = true
		_velocity = get_meta("launch_velocity") as Vector2
		_launch_target = get_meta("launch_target") as Vector2
		_spawn_delay = 0.0  # firlatmada gecikme yok, hemen hareket
	elif not _no_scatter:
		var angle := randf() * TAU
		_velocity = Vector2.from_angle(angle) * scatter_force

func setup(p_item_id: String, p_amount: int, spawn_pos: Vector2, no_scatter: bool = false) -> void:
	item_id = p_item_id
	amount = p_amount
	position = spawn_pos
	_no_scatter = no_scatter

func _update_visual() -> void:
	if not _sprite:
		return
	var db := _get_db()
	if db and db.has_item(item_id):
		var definition := db.get_item(item_id)
		if definition and definition.icon:
			_sprite.texture = definition.icon
		var tint := definition.color_hint
		_sprite.modulate = Color(tint.r * GLOW_BOOST, tint.g * GLOW_BOOST, tint.b * GLOW_BOOST, 1.0)

func _process(delta: float) -> void:
	_spawn_timer += delta

	# --- Firlatma modu ---
	if _launching and not _launch_arrived:
		_process_launch(delta)
		return

	# Spawn gecikmesi bitmeden miknatis calismaz
	if _spawn_timer < _spawn_delay:
		_velocity = _velocity.move_toward(Vector2.ZERO, 200.0 * delta)
		position += _velocity * delta
		return

	if _is_being_picked_up:
		return

	# Hedef bul
	if not _target:
		_find_target()
		_velocity = _velocity.move_toward(Vector2.ZERO, 100.0 * delta)
		position += _velocity * delta
		return

	var dist := global_position.distance_to(_target.global_position)

	# Pickup mesafesi
	if dist < pickup_radius:
		_try_pickup()
		return

	# Miknatis mesafesi
	if dist < magnet_radius:
		var pull_factor := 1.0 - (dist / magnet_radius)
		_current_speed = move_toward(_current_speed, magnet_speed * (0.5 + pull_factor), magnet_acceleration * delta)

		var direction := global_position.direction_to(_target.global_position)
		_velocity = direction * _current_speed
		position += _velocity * delta
	else:
		_current_speed = 0.0
		_velocity = _velocity.move_toward(Vector2.ZERO, 80.0 * delta)
		position += _velocity * delta
		_target = null

## Firlatma hareketi: gemiden hedefe dogru ucus, hedefe yaklasinca yavasla ve dur
func _process_launch(delta: float) -> void:
	var to_target := _launch_target - global_position
	var dist := to_target.length()

	if dist < 8.0:
		# Hedefe vardi
		global_position = _launch_target
		_velocity = Vector2.ZERO
		_launching = false
		_launch_arrived = true
		_spawn_delay = 0.0
		_spawn_timer = 999.0  # gecikmeyi atla, hemen toplanabilir
		return

	# Hedefe yaklastikca yavasla (easing)
	var speed := _velocity.length()
	var decel_dist := 60.0
	if dist < decel_dist:
		var slow_factor := dist / decel_dist
		_velocity = _velocity.normalized() * maxf(speed * slow_factor, 40.0)

	position += _velocity * delta

func _find_target() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return

	var player: Node2D = players[0] as Node2D
	if not player:
		return

	var dist := global_position.distance_to(player.global_position)
	if dist < magnet_radius:
		_target = player

func _try_pickup() -> void:
	if _is_being_picked_up:
		return
	if not _target:
		return

	var inventory: InventoryComponent = null
	if _target.has_node("ShipInventory"):
		inventory = _target.get_node("ShipInventory") as InventoryComponent

	if not inventory:
		return

	var added := inventory.add_item(item_id, amount)
	if added <= 0:
		_target = null
		_current_speed = 0.0
		return

	amount -= added
	if amount <= 0:
		_is_being_picked_up = true
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
		tween.tween_callback(queue_free)

func _get_db() -> ItemDatabase:
	var tree := get_tree()
	if tree:
		var root := tree.root
		if root.has_node("ItemDB"):
			return root.get_node("ItemDB") as ItemDatabase
	return null
