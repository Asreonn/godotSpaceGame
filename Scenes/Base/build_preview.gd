class_name BuildPreview
extends Node2D

## Holografik build preview sistemi.
## Mouse ile build edilebilir pozisyonlari gosterir,
## basili tutarak build animasyonu baslatir.

signal build_completed(grid_pos: Vector2i, module_def_id: String)
signal build_cancelled()

## Build suresi (saniye)
@export var build_duration: float = 2.0

## Manager referansi
var _manager: ModularBaseManager = null

## Secili modul tanimi
var _module_def: ModuleDefinition = null

## Preview sprite (hologram shader'li)
var _preview_sprite: Sprite2D = null

## Shader material
var _shader_material: ShaderMaterial = null

## Mevcut grid pozisyonu
var _current_grid_pos: Vector2i = Vector2i(99999, 99999)

## Gecerli pozisyon mu?
var _is_valid: bool = false

## Build progress (0-1)
var _build_progress: float = 0.0

## Mouse basili mi?
var _mouse_held: bool = false

## Build devam ediyor mu?
var _is_building: bool = false

## Buildable pozisyonlar cache
var _buildable_positions: Array[Vector2i] = []

## Slot gostericileri (bos buildable yerleri gosteren kucuk ikonlar)
var _slot_indicators: Array[Node2D] = []

## Progress bar UI
var _progress_bar_bg: ColorRect = null
var _progress_bar_fill: ColorRect = null

## Aktif mi?
var _active: bool = false

# -------------------------------------------------------
#  Baslatma
# -------------------------------------------------------

func setup(manager: ModularBaseManager) -> void:
	_manager = manager

func activate(module_def: ModuleDefinition) -> void:
	_module_def = module_def
	_active = true
	_build_progress = 0.0
	_is_building = false
	_mouse_held = false

	_create_preview_sprite()
	_create_progress_bar()
	_refresh_buildable_positions()
	_create_slot_indicators()

	visible = true
	set_process(true)
	set_process_input(true)

func deactivate() -> void:
	_active = false
	_is_building = false
	_mouse_held = false
	_build_progress = 0.0
	visible = false

	_clear_slot_indicators()

	if _preview_sprite:
		_preview_sprite.visible = false
	if _progress_bar_bg:
		_progress_bar_bg.visible = false
		_progress_bar_fill.visible = false

	set_process(false)
	set_process_input(false)

func _ready() -> void:
	set_process(false)
	set_process_input(false)
	visible = false

func _exit_tree() -> void:
	_clear_slot_indicators()

# -------------------------------------------------------
#  Preview sprite olusturma
# -------------------------------------------------------

func _create_preview_sprite() -> void:
	if _preview_sprite:
		_preview_sprite.queue_free()

	_preview_sprite = Sprite2D.new()
	_preview_sprite.name = "PreviewSprite"
	_preview_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_preview_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED

	if _module_def and _module_def.sprite_sheet:
		_preview_sprite.texture = _module_def.sprite_sheet
		_preview_sprite.hframes = _module_def.h_frames
		_preview_sprite.vframes = 1
		_preview_sprite.frame = 0

	# Hologram shader uygula
	var shader := preload("res://Shaders/hologram.gdshader")
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = shader
	_shader_material.set_shader_parameter("is_valid", true)
	_shader_material.set_shader_parameter("progress", 0.0)
	_preview_sprite.material = _shader_material

	add_child(_preview_sprite)

func _create_progress_bar() -> void:
	if _progress_bar_bg:
		_progress_bar_bg.queue_free()
	if _progress_bar_fill:
		_progress_bar_fill.queue_free()

	# Arkaplan
	_progress_bar_bg = ColorRect.new()
	_progress_bar_bg.size = Vector2(120, 8)
	_progress_bar_bg.position = Vector2(-60, -280)
	_progress_bar_bg.color = Color(0.1, 0.1, 0.15, 0.8)
	_progress_bar_bg.visible = false
	_progress_bar_bg.z_index = 10
	add_child(_progress_bar_bg)

	# Dolum
	_progress_bar_fill = ColorRect.new()
	_progress_bar_fill.size = Vector2(0, 8)
	_progress_bar_fill.position = Vector2(-60, -280)
	_progress_bar_fill.color = Color(0.0, 0.85, 0.9, 0.9)
	_progress_bar_fill.visible = false
	_progress_bar_fill.z_index = 11
	add_child(_progress_bar_fill)

# -------------------------------------------------------
#  Slot gostericileri (buildable pozisyonlari gosterme)
# -------------------------------------------------------

func _refresh_buildable_positions() -> void:
	if not _manager or not _module_def:
		_buildable_positions.clear()
		return
	_buildable_positions = _manager.get_buildable_positions_for(_module_def.id)

func _create_slot_indicators() -> void:
	_clear_slot_indicators()

	for pos in _buildable_positions:
		var indicator := _create_single_indicator(pos)
		_slot_indicators.append(indicator)
		# Indicator'lari manager'a ekle (cunku BuildPreview pozisyonu degisir)
		_manager.add_child(indicator)

func _create_single_indicator(grid_pos: Vector2i) -> Node2D:
	var node := Node2D.new()
	var world_pos := _manager.grid_to_world(grid_pos)
	# Indicator'lar _manager'in child'i olarak ekleniyor (global world coords)
	node.position = world_pos

	# Kucuk daire veya kare ciz
	var rect := ColorRect.new()
	rect.size = Vector2(60, 60)
	rect.position = Vector2(-30, -30)
	rect.color = Color(0.0, 0.85, 0.9, 0.15)
	node.add_child(rect)

	# + isareti ekle
	var plus := Label.new()
	plus.text = "+"
	plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus.add_theme_color_override("font_color", Color(0.0, 0.85, 0.9, 0.4))
	plus.add_theme_font_size_override("font_size", 28)
	plus.position = Vector2(-10, -20)
	node.add_child(plus)

	# Pulsating animasyon (tween'i manager'a bagla, indicator'in parent'i)
	var tween := _manager.create_tween()
	tween.set_loops()
	tween.tween_property(rect, "color:a", 0.3, 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(rect, "color:a", 0.1, 0.8).set_trans(Tween.TRANS_SINE)

	return node

func _clear_slot_indicators() -> void:
	for indicator in _slot_indicators:
		if is_instance_valid(indicator):
			indicator.queue_free()
	_slot_indicators.clear()

# -------------------------------------------------------
#  Input
# -------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not _active:
		return

	# Mouse buton
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if _is_valid:
					_on_mouse_pressed()
					get_viewport().set_input_as_handled()
			else:
				if _is_building:
					_on_mouse_released()
					get_viewport().set_input_as_handled()

		# Sag tik veya ESC ile iptal
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			build_cancelled.emit()
			get_viewport().set_input_as_handled()

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			build_cancelled.emit()
			get_viewport().set_input_as_handled()

func _on_mouse_pressed() -> void:
	if _is_valid:
		_mouse_held = true
		_is_building = true
		_build_progress = 0.0
		_progress_bar_bg.visible = true
		_progress_bar_fill.visible = true

func _on_mouse_released() -> void:
	_mouse_held = false
	if _is_building:
		_is_building = false
		_build_progress = 0.0
		if _shader_material:
			_shader_material.set_shader_parameter("progress", 0.0)
		_progress_bar_bg.visible = false
		_progress_bar_fill.visible = false

# -------------------------------------------------------
#  Process
# -------------------------------------------------------

func _process(delta: float) -> void:
	if not _active or not _manager or not _module_def:
		return

	_update_preview_position()
	_update_build_progress(delta)

func _update_preview_position() -> void:
	var mouse_world := _get_mouse_world_pos()
	var mouse_local := _manager.to_local(mouse_world)
	var grid_pos := _manager.world_to_grid(mouse_local)

	# Grid pozisyonu degisti mi?
	if grid_pos != _current_grid_pos:
		_current_grid_pos = grid_pos

		# Gecerli pozisyon mu kontrol et
		_is_valid = grid_pos in _buildable_positions

		# Preview sprite'i guncelle
		if _preview_sprite:
			_preview_sprite.visible = _is_valid
			var world_pos := _manager.grid_to_world(grid_pos)
			position = world_pos

		# Shader rengini guncelle
		if _shader_material:
			_shader_material.set_shader_parameter("is_valid", _is_valid)

		# Sprite frame'ini guncelle (komsulara gore)
		if _is_valid and _preview_sprite and _module_def:
			var preview_connections := _get_preview_connections(grid_pos)
			var frame_idx := _module_def.get_frame_index(preview_connections)
			_preview_sprite.frame = frame_idx

		# Gecersiz pozisyona gecince build iptal
		if not _is_valid and _is_building:
			_is_building = false
			_build_progress = 0.0
			_mouse_held = false
			if _shader_material:
				_shader_material.set_shader_parameter("progress", 0.0)
			_progress_bar_bg.visible = false
			_progress_bar_fill.visible = false

func _update_build_progress(delta: float) -> void:
	if not _is_building or not _mouse_held or not _is_valid:
		return

	_build_progress += delta / build_duration
	_build_progress = clampf(_build_progress, 0.0, 1.0)

	# Shader progress guncelle
	if _shader_material:
		_shader_material.set_shader_parameter("progress", _build_progress)

	# Progress bar guncelle
	if _progress_bar_fill:
		_progress_bar_fill.size.x = 120.0 * _build_progress

	# Build tamamlandi mi?
	if _build_progress >= 1.0:
		_complete_build()

func _complete_build() -> void:
	var grid_pos := _current_grid_pos
	var def_id := _module_def.id

	_is_building = false
	_build_progress = 0.0
	_mouse_held = false

	if _shader_material:
		_shader_material.set_shader_parameter("progress", 0.0)
	_progress_bar_bg.visible = false
	_progress_bar_fill.visible = false

	build_completed.emit(grid_pos, def_id)

	# Buildable pozisyonlari yenile
	_refresh_buildable_positions()
	_create_slot_indicators()

# -------------------------------------------------------
#  Yardimci
# -------------------------------------------------------

func _get_mouse_world_pos() -> Vector2:
	var canvas_transform := get_viewport().get_canvas_transform()
	return canvas_transform.affine_inverse() * get_viewport().get_mouse_position()

func _modules_nearby(grid_pos: Vector2i) -> bool:
	# Grid pozisyonu herhangi bir mevcut modulun yaninda mi?
	for dir in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
		var neighbor_pos: Vector2i = grid_pos + dir
		if _manager.get_module_at(neighbor_pos) != null:
			return true
	# Veya modulun kendisi varsa
	return _manager.get_module_at(grid_pos) != null

func _get_preview_connections(grid_pos: Vector2i) -> Array[Vector2i]:
	## Bu pozisyona yerlesse hangi baglantilari olurdu?
	var connections: Array[Vector2i] = []
	for dir in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
		if not _module_def.has_direction(dir):
			continue
		var neighbor_pos: Vector2i = grid_pos + dir
		var neighbor := _manager.get_module_at(neighbor_pos)
		if neighbor and neighbor.can_connect(ModularBaseManager.OPPOSITE_DIR[dir]):
			connections.append(dir)
	return connections

## Buildable pozisyonlari yeniden hesapla (dis erisim icin)
func refresh_slots() -> void:
	_refresh_buildable_positions()
	_create_slot_indicators()
