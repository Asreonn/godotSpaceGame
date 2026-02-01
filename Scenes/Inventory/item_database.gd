class_name ItemDatabase
extends Node

## Tum item tanimlarini tutan merkezi veritabani.
## Autoload olarak eklenir: ItemDB

var _items: Dictionary = {}  # id -> ItemDefinition

func _ready() -> void:
	_register_default_items()

func _register_default_items() -> void:
	# --- Gold ---
	var gold := ItemDefinition.new()
	gold.id = "gold"
	gold.display_name = "Gold"
	gold.icon = preload("res://Assets/Props/Gold.png")
	gold.capacity_cost = 2
	gold.color_hint = Color(1.0, 0.84, 0.0)
	register_item(gold)

	# --- Iron ---
	var iron := ItemDefinition.new()
	iron.id = "iron"
	iron.display_name = "Iron"
	iron.icon = preload("res://Assets/Props/Iron.png")
	iron.capacity_cost = 1
	iron.color_hint = Color(0.7, 0.7, 0.75)
	register_item(iron)

func register_item(definition: ItemDefinition) -> void:
	_items[definition.id] = definition

func get_item(id: String) -> ItemDefinition:
	if _items.has(id):
		return _items[id]
	push_warning("ItemDatabase: '%s' bulunamadi" % id)
	return null

func get_all_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in _items.keys():
		ids.append(key)
	return ids

func has_item(id: String) -> bool:
	return _items.has(id)
