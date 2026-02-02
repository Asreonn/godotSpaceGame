class_name ModularBaseManager
extends Node2D

## Modüler base sistemini yoneten merkezi sinif.
## Grid bazli modul yerlestirme, baglanti guncelleme ve build islemlerini yonetir.

signal module_placed(module: BaseModule, grid_pos: Vector2i)
signal module_removed(module: BaseModule, grid_pos: Vector2i)
signal buildable_slots_changed()
signal build_mode_changed(active: bool)

## Grid hücre boyutu (piksel)
@export var cell_size: Vector2i = Vector2i(400, 400)

## Kayitli modul tanimlari
var _module_defs: Dictionary = {}  # id -> ModuleDefinition

## Yerlesmis moduller: grid_pos -> BaseModule
var _modules: Dictionary = {}

## Build edilebilir pozisyonlar ve hangi modul tiplerinin oraya yerlestirilebilecegi
## grid_pos -> Array[String] (module_def id'leri)
var _buildable_slots: Dictionary = {}

## Build modu aktif mi?
var _build_mode: bool = false

## Secili modul tanimi (build icin)
var _selected_def: ModuleDefinition = null

## Ters yon tablosu
const OPPOSITE_DIR: Dictionary = {
	Vector2i.RIGHT: Vector2i.LEFT,
	Vector2i.LEFT: Vector2i.RIGHT,
	Vector2i.UP: Vector2i.DOWN,
	Vector2i.DOWN: Vector2i.UP,
}

# -------------------------------------------------------
#  Baslatma
# -------------------------------------------------------

func _ready() -> void:
	_register_default_modules()

func _register_default_modules() -> void:
	# --- Main Base ---
	var main_base := ModuleDefinition.new()
	main_base.id = "main_base"
	main_base.display_name = "Main Base"
	main_base.description = "Temel us modulu. Sag, sol ve alt yonlere genisletilebilir."
	main_base.build_cost = {"iron": 2}
	main_base.available_directions = [
		Vector2i.RIGHT,   # (1, 0)
		Vector2i.LEFT,    # (-1, 0)
		Vector2i.DOWN,    # (0, 1)
	]
	main_base.sprite_sheet = preload("res://Assets/BaseMainSpriteSheet.png")
	main_base.frame_size = Vector2i(400, 400)
	main_base.h_frames = 8
	# Baglanti -> frame index mapping
	# Sira: Index 0=bos, 1=R, 2=D, 3=L, 4=RD, 5=LD, 6=RL, 7=RLD
	main_base.connection_to_frame = {
		"": 0,       # Hic baglanti yok
		"R": 1,      # Sag
		"D": 2,      # Alt
		"L": 3,      # Sol
		"RD": 4,     # Sag + Alt
		"DL": 5,     # Sol + Alt  (siralama: R, D, L, U)
		"RL": 6,     # Sag + Sol
		"RDL": 7,    # Sag + Sol + Alt
	}
	register_module_def(main_base)

func register_module_def(definition: ModuleDefinition) -> void:
	_module_defs[definition.id] = definition

func get_module_def(id: String) -> ModuleDefinition:
	return _module_defs.get(id, null)

func get_all_module_defs() -> Array[ModuleDefinition]:
	var result: Array[ModuleDefinition] = []
	for key in _module_defs.keys():
		var definition: ModuleDefinition = _module_defs[key]
		if definition:
			result.append(definition)
	return result

# -------------------------------------------------------
#  Modul yerlestirme
# -------------------------------------------------------

## Ilk base modulunu yerlestirir (oyun basinda, maliyet olmadan)
func place_initial_module(grid_pos: Vector2i, def_id: String) -> BaseModule:
	var definition := get_module_def(def_id)
	if not definition:
		push_error("ModularBaseManager: '%s' tanimi bulunamadi" % def_id)
		return null
	return _place_module_internal(grid_pos, definition)

## Build ile modul yerlestirir (maliyet kesilir)
func build_module(grid_pos: Vector2i, def_id: String, inventory: Node) -> BaseModule:
	var definition := get_module_def(def_id)
	if not definition:
		push_error("ModularBaseManager: '%s' tanimi bulunamadi" % def_id)
		return null

	if not can_place_at(grid_pos, definition):
		return null

	# Maliyeti ode (spend_cost icinde can_afford kontrolu var)
	if not definition.spend_cost(inventory):
		return null

	return _place_module_internal(grid_pos, definition)

func _place_module_internal(grid_pos: Vector2i, definition: ModuleDefinition) -> BaseModule:
	if _modules.has(grid_pos):
		push_warning("ModularBaseManager: %s pozisyonunda zaten modul var" % grid_pos)
		return null

	# BaseModule olustur
	var module := BaseModule.new()
	module.setup(grid_pos, definition)
	module.position = BaseModule.grid_to_world(grid_pos, cell_size)
	add_child(module)

	_modules[grid_pos] = module

	# Baglantilari guncelle (bu modul ve komsu moduller)
	_update_connections_around(grid_pos)

	# Buildable slot'lari guncelle
	_recalculate_buildable_slots()

	module_placed.emit(module, grid_pos)
	return module

## Modul kaldir
func remove_module(grid_pos: Vector2i) -> void:
	if not _modules.has(grid_pos):
		return
	var module: BaseModule = _modules[grid_pos]
	_modules.erase(grid_pos)

	# Komsu baglantilari guncelle
	for dir in OPPOSITE_DIR.keys():
		var neighbor_pos: Vector2i = grid_pos + dir
		if _modules.has(neighbor_pos):
			var neighbor: BaseModule = _modules[neighbor_pos]
			neighbor.remove_connection(OPPOSITE_DIR[dir])

	module.queue_free()
	_recalculate_buildable_slots()
	module_removed.emit(module, grid_pos)

# -------------------------------------------------------
#  Baglanti guncelleme
# -------------------------------------------------------

func _update_connections_around(center_pos: Vector2i) -> void:
	if not _modules.has(center_pos):
		return

	var center_module: BaseModule = _modules[center_pos]
	var new_connections: Array[Vector2i] = []

	# 4 yonu kontrol et
	for dir in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
		var neighbor_pos: Vector2i = center_pos + dir
		if not _modules.has(neighbor_pos):
			continue

		var neighbor: BaseModule = _modules[neighbor_pos]
		var opp: Vector2i = OPPOSITE_DIR[dir]

		# Merkez modulun bu yone baglanti noktasi var mi?
		if not center_module.can_connect(dir):
			continue
		# Komsunun karsi yone baglanti noktasi var mi?
		if not neighbor.can_connect(opp):
			continue

		# Iki taraf da baglanabilir
		new_connections.append(dir)
		# Komsuya da karsi yon baglantiyi ekle
		neighbor.add_connection(opp)

	center_module.set_connections(new_connections)

# -------------------------------------------------------
#  Buildable slot hesaplama
# -------------------------------------------------------

func _recalculate_buildable_slots() -> void:
	_buildable_slots.clear()

	for pos in _modules.keys():
		var module: BaseModule = _modules[pos]
		var open_dirs := module.get_open_directions()

		for dir in open_dirs:
			var target_pos: Vector2i = pos + dir
			# Zaten dolu mu?
			if _modules.has(target_pos):
				continue

			# Bu pozisyona hangi moduller yerlestirilebilir?
			if not _buildable_slots.has(target_pos):
				_buildable_slots[target_pos] = []

			# Tum modul tiplerini kontrol et
			for def_id in _module_defs.keys():
				var definition: ModuleDefinition = _module_defs[def_id]
				if _can_module_fit(target_pos, definition):
					var slot_list: Array = _buildable_slots[target_pos]
					if def_id not in slot_list:
						slot_list.append(def_id)

	buildable_slots_changed.emit()

## Bir modul tipinin belirli bir pozisyona yerlesip yerlesemeyecegini kontrol eder
func _can_module_fit(grid_pos: Vector2i, definition: ModuleDefinition) -> bool:
	# Pozisyon dolu mu?
	if _modules.has(grid_pos):
		return false

	# En az bir komsundan baglanti saglanmali
	var has_valid_connection := false

	for dir in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
		var neighbor_pos: Vector2i = grid_pos + dir
		if not _modules.has(neighbor_pos):
			continue

		var neighbor: BaseModule = _modules[neighbor_pos]
		var opp: Vector2i = OPPOSITE_DIR[dir]

		# Yerlestirmek istedigimiz modulun bu yone baglanti noktasi var mi?
		if not definition.has_direction(dir):
			continue
		# Komsunun karsi yone baglanti noktasi var mi?
		if not neighbor.can_connect(opp):
			continue

		has_valid_connection = true
		break

	return has_valid_connection

# -------------------------------------------------------
#  Sorgulama
# -------------------------------------------------------

## Belirli bir pozisyona belirli bir modul yerlestirilebilir mi?
func can_place_at(grid_pos: Vector2i, definition: ModuleDefinition) -> bool:
	if _modules.has(grid_pos):
		return false
	return _can_module_fit(grid_pos, definition)

## Belirli bir modul tipi icin build edilebilir pozisyonlari dondurur
func get_buildable_positions_for(def_id: String) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for pos in _buildable_slots.keys():
		var slot_list: Array = _buildable_slots[pos]
		if def_id in slot_list:
			result.append(pos)
	return result

## Tum buildable slot'lari dondurur
func get_all_buildable_slots() -> Dictionary:
	return _buildable_slots.duplicate()

## Belirli pozisyondaki modulu dondurur
func get_module_at(grid_pos: Vector2i) -> BaseModule:
	return _modules.get(grid_pos, null)

## Tum modulleri dondurur
func get_all_modules() -> Dictionary:
	return _modules.duplicate()

## Modul sayisini dondurur
func get_module_count() -> int:
	return _modules.size()

## Dunya pozisyonunu grid pozisyonuna cevirir
func world_to_grid(world_pos: Vector2) -> Vector2i:
	return BaseModule.world_to_grid(world_pos, cell_size)

## Grid pozisyonunu dunya pozisyonuna cevirir
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return BaseModule.grid_to_world(grid_pos, cell_size)

# -------------------------------------------------------
#  Build modu
# -------------------------------------------------------

func set_build_mode(active: bool) -> void:
	_build_mode = active
	build_mode_changed.emit(active)

func is_build_mode() -> bool:
	return _build_mode

func set_selected_module_def(def_id: String) -> void:
	_selected_def = get_module_def(def_id)

func get_selected_module_def() -> ModuleDefinition:
	return _selected_def
