class_name ModuleDefinition
extends Resource

## Bir modul tipinin tanimini tutan resource.
## Her modul tipi (main_base, storage, refinery vb.) icin bir tane olusturulur.

## Benzersiz modul ID'si (ornek: "main_base", "storage")
@export var id: String = ""

## Gosterim ismi
@export var display_name: String = ""

## Build maliyeti: item_id -> miktar
@export var build_cost: Dictionary = {}

## Bu modulun hangi yonlere baglanti noktasi var
## Vector2i.RIGHT (1,0), LEFT (-1,0), UP (0,-1), DOWN (0,1)
@export var available_directions: Array[Vector2i] = []

## Sprite sheet texture
@export var sprite_sheet: Texture2D = null

## Sprite frame boyutu (piksel)
@export var frame_size: Vector2i = Vector2i(400, 400)

## Toplam yatay frame sayisi
@export var h_frames: int = 8

## Baglanti durumuna gore hangi sprite frame kullanilacak
## Ornek: sag=1, sol=2, alt=4 bitmask sistemi
## frame_index = right*1 + down*2 + left*4 seklinde hesaplanir
## Veya ozel mapping icin bu dictionary kullanilir
## Key: "R", "D", "L", "RD", "RL", "LD", "RLD", "" (bos = hic baglanti yok)
## Value: frame index
@export var connection_to_frame: Dictionary = {}

## Modul aciklamasi (UI icin)
@export var description: String = ""

## Modul ikonu (build menusunde gosterilecek kucuk ikon)
@export var menu_icon: Texture2D = null

# -------------------------------------------------------
#  Yardimci metodlar
# -------------------------------------------------------

## Verilen baglanti yonleri icin dogru frame index'i dondurur
func get_frame_index(active_connections: Array[Vector2i]) -> int:
	var key := _connections_to_key(active_connections)
	if connection_to_frame.has(key):
		return connection_to_frame[key]
	# Fallback: frame 0
	return 0

## Bu modulun belirli bir yone baglanti noktasi var mi?
func has_direction(dir: Vector2i) -> bool:
	return dir in available_directions

## Verilen item id ve miktara gore build edilebilir mi?
func can_afford(inventory: InventoryComponent) -> bool:
	if inventory == null:
		return false
	for item_id in build_cost.keys():
		var needed: int = build_cost[item_id]
		var have: int = inventory.get_item_count(item_id)
		if have < needed:
			return false
	return true

## Build maliyetini envanterden dus
func spend_cost(inventory: InventoryComponent) -> bool:
	if not can_afford(inventory):
		return false
	for item_id in build_cost.keys():
		var needed: int = build_cost[item_id]
		inventory.remove_item(item_id, needed)
	return true

# -------------------------------------------------------
#  Dahili
# -------------------------------------------------------

## Baglanti yonlerini string key'e cevirir (siralama tutarli olmali)
func _connections_to_key(connections: Array[Vector2i]) -> String:
	var parts: Array[String] = []
	# Sabit sira: Right, Down, Left, Up
	if Vector2i.RIGHT in connections:
		parts.append("R")
	if Vector2i.DOWN in connections:
		parts.append("D")
	if Vector2i.LEFT in connections:
		parts.append("L")
	if Vector2i.UP in connections:
		parts.append("U")
	return "".join(parts)
