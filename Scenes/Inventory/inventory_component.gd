class_name InventoryComponent
extends Node

## Kapasite bazli envanter bileseni.
## Gemi ve Base icin ortak kullanilir.

signal changed()
signal item_added(item_id: String, amount: int)
signal item_removed(item_id: String, amount: int)

@export var max_capacity: int = 50  ## Toplam kapasite

var _items: Dictionary = {}  # item_id -> miktar
var used_capacity: int = 0

# --- Sorgulama ---

func get_items() -> Dictionary:
	return _items.duplicate()

func get_item_count(item_id: String) -> int:
	return _items.get(item_id, 0)

func get_used_capacity() -> int:
	return used_capacity

func get_free_capacity() -> int:
	return max_capacity - used_capacity

func is_full() -> bool:
	return used_capacity >= max_capacity

func is_empty() -> bool:
	return used_capacity <= 0

# --- Ekleme ---

## Belirtilen miktarda item ekler. Kapasiteye sigdigi kadarini ekler.
## Gercekte eklenen miktari dondurur.
func add_item(item_id: String, amount: int) -> int:
	if amount <= 0:
		return 0

	var db: ItemDatabase = _get_db()
	if not db:
		return 0

	var definition := db.get_item(item_id)
	if not definition:
		return 0

	var cost_per_unit: int = definition.capacity_cost
	if cost_per_unit <= 0:
		cost_per_unit = 1

	var free := get_free_capacity()
	var max_addable: int = free / cost_per_unit
	var actual := mini(amount, max_addable)

	if actual <= 0:
		return 0

	_items[item_id] = _items.get(item_id, 0) + actual
	used_capacity += actual * cost_per_unit

	item_added.emit(item_id, actual)
	changed.emit()
	return actual

## Kapasiteyi kontrol eder, eklenebilir mi?
func can_add(item_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	var db: ItemDatabase = _get_db()
	if not db:
		return false
	var definition := db.get_item(item_id)
	if not definition:
		return false
	var cost: int = definition.capacity_cost
	if cost <= 0:
		cost = 1
	return (cost * amount) <= get_free_capacity()

# --- Cikarma ---

## Belirtilen miktarda item cikarir. Mevcut miktardan fazlasini cikaramaz.
## Gercekte cikarilan miktari dondurur.
func remove_item(item_id: String, amount: int) -> int:
	if amount <= 0:
		return 0

	var current: int = _items.get(item_id, 0)
	if current <= 0:
		return 0

	var db: ItemDatabase = _get_db()
	if not db:
		return 0
	var definition := db.get_item(item_id)
	if not definition:
		return 0

	var actual := mini(amount, current)
	var cost_per_unit: int = definition.capacity_cost
	if cost_per_unit <= 0:
		cost_per_unit = 1

	_items[item_id] = current - actual
	if _items[item_id] <= 0:
		_items.erase(item_id)
	used_capacity -= actual * cost_per_unit
	used_capacity = maxi(used_capacity, 0)

	item_removed.emit(item_id, actual)
	changed.emit()
	return actual

# --- Transfer ---

## Bu envanterden hedefe transfer eder. Aktarilan miktari dondurur.
func transfer_to(target: InventoryComponent, item_id: String, amount: int) -> int:
	if amount <= 0 or not target:
		return 0

	var current: int = _items.get(item_id, 0)
	var to_transfer := mini(amount, current)
	if to_transfer <= 0:
		return 0

	var added := target.add_item(item_id, to_transfer)
	if added > 0:
		remove_item(item_id, added)
	return added

## Tum itemleri hedefe transfer eder. Aktarilan miktarlari dondurur.
func transfer_all_to(target: InventoryComponent) -> Dictionary:
	var transferred: Dictionary = {}
	var keys: Array = _items.keys().duplicate()
	for item_id in keys:
		var count: int = _items.get(item_id, 0)
		if count > 0:
			var moved := transfer_to(target, item_id, count)
			if moved > 0:
				transferred[item_id] = moved
	return transferred

# --- Upgrade ---

func set_max_capacity(new_max: int) -> void:
	max_capacity = maxi(new_max, 0)
	changed.emit()

# --- Yardimci ---

func _get_db() -> ItemDatabase:
	return ItemDB
