extends Node

func _ready() -> void:
	var station_scene: PackedScene = load("res://Scenes/Base/base_station.tscn")
	if not station_scene:
		push_error("build_preview_smoke: base_station.tscn not found")
		get_tree().quit(1)
		return

	var station: Node = station_scene.instantiate()
	add_child(station)
	await get_tree().process_frame

	var manager: ModularBaseManager = station.get_module_manager()
	if not manager:
		push_error("build_preview_smoke: module manager missing")
		get_tree().quit(1)
		return

	var definition: ModuleDefinition = manager.get_module_def("main_base")
	if not definition:
		push_error("build_preview_smoke: main_base definition missing")
		get_tree().quit(1)
		return

	var preview: Node = station.get_node("BuildPreview")
	if not preview:
		push_error("build_preview_smoke: BuildPreview node missing")
		get_tree().quit(1)
		return

	preview.activate(definition)
	await get_tree().process_frame

	if preview._buildable_positions.size() == 0:
		push_error("build_preview_smoke: no buildable positions")
		get_tree().quit(1)
		return

	if preview._slot_indicators.size() == 0:
		push_error("build_preview_smoke: no slot indicators created")
		get_tree().quit(1)
		return

	get_tree().quit(0)
