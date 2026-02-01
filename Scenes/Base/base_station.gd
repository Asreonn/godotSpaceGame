class_name BaseStation
extends Node2D

## Merkez us - oyuncu iceri girince UI acilir, envanter transferi yapilir.

signal player_entered(base: BaseStation)
signal player_exited(base: BaseStation)

@export var trigger_radius: float = 80.0  ## Oyuncunun giris alani

@onready var base_inventory: InventoryComponent = $BaseInventory
@onready var trigger_area: Area2D = $TriggerArea

var _player_inside: bool = false

func _ready() -> void:
	add_to_group("base_station")
	# Collision shape'i kod ile olustur
	var shape := CircleShape2D.new()
	shape.radius = trigger_radius
	var col_shape: CollisionShape2D = trigger_area.get_node("CollisionShape2D")
	col_shape.shape = shape

	trigger_area.body_entered.connect(_on_body_entered)
	trigger_area.body_exited.connect(_on_body_exited)

func get_inventory() -> InventoryComponent:
	return base_inventory

func is_player_inside() -> bool:
	return _player_inside

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		if body.has_method("set_nearby_base"):
			body.set_nearby_base(self)
		player_entered.emit(self)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		if body.has_method("set_nearby_base"):
			body.set_nearby_base(null)
		player_exited.emit(self)
