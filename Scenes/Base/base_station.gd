class_name BaseStation
extends Node2D

## Merkez us - oyuncu iceri girince UI acilir, envanter transferi yapilir.
## Moduler base sistemi: grid bazli modul yerlestirme, build preview ve holografik shader.

signal player_entered(base: BaseStation)
signal player_exited(base: BaseStation)

@export var trigger_radius: float = 300.0  ## Oyuncunun giris alani (moduler base icin buyutuldu)

@onready var base_inventory: InventoryComponent = $BaseInventory
@onready var trigger_area: Area2D = $TriggerArea

var _player_inside: bool = false
var _player_ref: Node2D = null

## Moduler base sistemi
@onready var _module_manager: ModularBaseManager = $ModuleManager
@onready var _build_preview: BuildPreview = $BuildPreview
@onready var _build_ui: BuildUI = $BuildUI
var _build_mode_active: bool = false

func _ready() -> void:
	add_to_group("base_station")

	# Collision shape'i kod ile olustur
	var shape := CircleShape2D.new()
	shape.radius = trigger_radius
	var col_shape: CollisionShape2D = trigger_area.get_node("CollisionShape2D")
	col_shape.shape = shape

	trigger_area.body_entered.connect(_on_body_entered)
	trigger_area.body_exited.connect(_on_body_exited)

	# Moduler sistemi baslat
	_setup_modular_system()

func get_inventory() -> InventoryComponent:
	return base_inventory

func is_player_inside() -> bool:
	return _player_inside

func get_module_manager() -> ModularBaseManager:
	return _module_manager

func get_build_ui() -> BuildUI:
	return _build_ui

# -------------------------------------------------------
#  Moduler sistem kurulumu
# -------------------------------------------------------

func _setup_modular_system() -> void:
	# Eski Visual node'u kaldir (artik sprite sheet kullaniyoruz)
	var old_visual := get_node_or_null("Visual")
	if old_visual:
		old_visual.queue_free()

	_build_preview.setup(_module_manager)
	_build_preview.build_completed.connect(_on_build_completed)
	_build_preview.build_cancelled.connect(_on_build_cancelled)

	_build_ui.setup(_module_manager, base_inventory)
	_build_ui.build_mode_requested.connect(_on_build_mode_requested)
	_build_ui.build_mode_closed.connect(_on_build_mode_closed)

	# Envanter degistiginde build UI'yi guncelle
	if base_inventory:
		base_inventory.changed.connect(_on_inventory_changed)

	# Ilk base modulunu yerlestir (0,0 konumuna, maliyetsiz)
	_module_manager.place_initial_module(Vector2i.ZERO, "main_base")

# -------------------------------------------------------
#  Build modu yonetimi
# -------------------------------------------------------

func _on_build_mode_requested(def_id: String) -> void:
	var definition := _module_manager.get_module_def(def_id)
	if not definition:
		return

	# Yeterli kaynak var mi?
	if not definition.can_afford(base_inventory):
		return

	_build_mode_active = true
	_module_manager.set_build_mode(true)
	_module_manager.set_selected_module_def(def_id)

	# Preview'i aktive et
	_build_preview.activate(definition)

	# Build UI'yi gizle (preview modunda)
	_build_ui.hide_ui()

func _on_build_mode_closed() -> void:
	_exit_build_mode()

func _on_build_cancelled() -> void:
	_exit_build_mode()

func _exit_build_mode() -> void:
	_build_mode_active = false
	_module_manager.set_build_mode(false)
	_build_preview.deactivate()

	# Player hala icindeyse build UI'yi tekrar goster
	if _player_inside:
		_build_ui.show_ui()

func _on_build_completed(grid_pos: Vector2i, module_def_id: String) -> void:
	# Modulu yerlestir (maliyet kesilir)
	var module := _module_manager.build_module(grid_pos, module_def_id, base_inventory)
	if module:
		# Trigger radius'u guncelle (base buyudukce alan genisler)
		_update_trigger_radius()

		# Preview'in buildable slotlarini yenile
		_build_preview.refresh_slots()

		# Envanter degisti, UI guncelle
		_build_ui.refresh()
	else:
		# Build basarisiz (yetersiz kaynak veya gecersiz pozisyon)
		push_warning("BaseStation: Build basarisiz - pos:%s def:%s" % [grid_pos, module_def_id])

func _on_inventory_changed() -> void:
	if _build_ui and _build_ui.is_open():
		_build_ui.refresh()

# -------------------------------------------------------
#  Trigger radius guncelleme
# -------------------------------------------------------

func _update_trigger_radius() -> void:
	## Base buyudukce trigger radius'u genislet
	var module_count := _module_manager.get_module_count()
	var cell_size := _module_manager.cell_size
	# Her yeni modul icin biraz daha genis trigger
	var base_radius := 300.0
	var extra := float(module_count - 1) * float(cell_size.x) * 0.6
	trigger_radius = base_radius + extra

	var col_shape: CollisionShape2D = trigger_area.get_node("CollisionShape2D")
	if col_shape and col_shape.shape is CircleShape2D:
		(col_shape.shape as CircleShape2D).radius = trigger_radius

# -------------------------------------------------------
#  Player giris/cikis
# -------------------------------------------------------

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		_player_ref = body
		if body.has_method("set_nearby_base"):
			body.set_nearby_base(self)
		if body.has_method("set_beam_enabled"):
			body.set_beam_enabled(false)
		player_entered.emit(self)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		_player_ref = null
		if body.has_method("set_nearby_base"):
			body.set_nearby_base(null)
		if body.has_method("set_beam_enabled"):
			body.set_beam_enabled(true)

		# Build modundan cik
		if _build_mode_active:
			_exit_build_mode()

		# Build UI'yi gizle
		_build_ui.hide_ui()

		player_exited.emit(self)

# -------------------------------------------------------
#  Dis erisim
# -------------------------------------------------------

## Build UI'yi goster (InventoryUI tarafindan cagirilir)
func show_build_ui() -> void:
	if _build_ui and not _build_mode_active:
		_build_ui.setup(_module_manager, base_inventory)
		_build_ui.show_ui()

## Build UI'yi gizle
func hide_build_ui() -> void:
	if _build_ui:
		_build_ui.hide_ui()
	if _build_mode_active:
		_exit_build_mode()

func is_build_mode_active() -> bool:
	return _build_mode_active
