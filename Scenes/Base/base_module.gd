class_name BaseModule
extends Node2D

## Tek bir yerlestirilmis modul. Grid uzerinde bir hucreyi temsil eder.
## Sprite'i baglanti durumuna gore guncellenir.

signal connections_changed(module: BaseModule)

## Bu modulun grid koordinati
var grid_pos: Vector2i = Vector2i.ZERO

## Modul tanimi (tip bilgisi)
var module_def: ModuleDefinition = null

## Aktif baglantilarin yonleri (komsulara bagli yonler)
var active_connections: Array[Vector2i] = []

## Sprite node referansi
var _sprite: Sprite2D = null

# -------------------------------------------------------
#  Baslatma
# -------------------------------------------------------

func setup(pos: Vector2i, definition: ModuleDefinition) -> void:
	grid_pos = pos
	module_def = definition
	name = "Module_%s_%s" % [pos.x, pos.y]

func _ready() -> void:
	_create_sprite()
	_update_sprite()

# -------------------------------------------------------
#  Sprite yonetimi
# -------------------------------------------------------

func _create_sprite() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	if module_def and module_def.sprite_sheet:
		_sprite.texture = module_def.sprite_sheet
		_sprite.hframes = module_def.h_frames
		_sprite.vframes = 1
		_sprite.frame = 0
	add_child(_sprite)

func _update_sprite() -> void:
	if not _sprite or not module_def:
		return
	var frame_idx := module_def.get_frame_index(active_connections)
	_sprite.frame = frame_idx

## Baglanti ekle ve sprite'i guncelle
func add_connection(direction: Vector2i) -> void:
	if direction in active_connections:
		return
	if not module_def or not module_def.has_direction(direction):
		return
	active_connections.append(direction)
	_update_sprite()
	connections_changed.emit(self)

## Baglanti kaldir ve sprite'i guncelle
func remove_connection(direction: Vector2i) -> void:
	var idx := active_connections.find(direction)
	if idx < 0:
		return
	active_connections.remove_at(idx)
	_update_sprite()
	connections_changed.emit(self)

## Tum baglantilari ayarla ve sprite'i guncelle
func set_connections(connections: Array[Vector2i]) -> void:
	active_connections = connections.duplicate()
	_update_sprite()

## Bu modulun belirli bir yone baglanti noktasi var mi?
func can_connect(direction: Vector2i) -> bool:
	if not module_def:
		return false
	return module_def.has_direction(direction)

## Bu modulden hangi yonlere yeni modul build edilebilir?
## (baglanti noktasi olan ama henuz komsu olmayan yonler)
func get_open_directions() -> Array[Vector2i]:
	if not module_def:
		return []
	var open: Array[Vector2i] = []
	for dir in module_def.available_directions:
		if dir not in active_connections:
			open.append(dir)
	return open

## Grid pozisyonunu dunya pozisyonuna cevirir
static func grid_to_world(gpos: Vector2i, cell_size: Vector2i) -> Vector2:
	return Vector2(gpos.x * cell_size.x, gpos.y * cell_size.y)

## Dunya pozisyonunu grid pozisyonuna cevirir
static func world_to_grid(wpos: Vector2, cell_size: Vector2i) -> Vector2i:
	return Vector2i(
		roundi(wpos.x / float(cell_size.x)),
		roundi(wpos.y / float(cell_size.y))
	)
