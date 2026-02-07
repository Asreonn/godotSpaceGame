extends Node

## Base health sistemi smoke testi.
## Komut: godot --headless --path . -s tests/base_health_smoke.tscn

func _ready() -> void:
	var failures: Array[String] = []

	await _failures_for_health_init(failures)
	await _failures_for_take_damage(failures)
	await _failures_for_heal(failures)
	await _failures_for_set_health(failures)

	if not failures.is_empty():
		for msg in failures:
			push_error(msg)
		get_tree().quit(1)
		return

	print("base_health_smoke: TAMAM - tum testler gecti")
	get_tree().quit(0)

func _failures_for_health_init(failures: Array[String]) -> void:
	var station_scene: PackedScene = load("res://Scenes/Base/base_station.tscn")
	if not station_scene:
		failures.append("base_station.tscn yuklenemedi")
		return
	var station: Node = station_scene.instantiate()
	add_child(station)
	await get_tree().process_frame

	var base := station as BaseStation
	if not base:
		failures.append("station BaseStation tipinde degil")
		station.queue_free()
		return

	if base.get_max_health() != 500.0:
		failures.append("max_health beklenen: 500, gelen: %s" % base.get_max_health())
	if base.get_current_health() != 500.0:
		failures.append("baslangic current_health beklenen: 500, gelen: %s" % base.get_current_health())
	if not is_equal_approx(base.get_health_ratio(), 1.0):
		failures.append("baslangic health_ratio beklenen: 1.0, gelen: %s" % base.get_health_ratio())

	station.queue_free()
	await get_tree().process_frame

func _failures_for_take_damage(failures: Array[String]) -> void:
	var station_scene: PackedScene = load("res://Scenes/Base/base_station.tscn")
	var station: Node = station_scene.instantiate()
	add_child(station)
	await get_tree().process_frame

	var base := station as BaseStation

	base.take_damage(100.0)
	if base.get_current_health() != 400.0:
		failures.append("100 hasar sonrasi beklenen: 400, gelen: %s" % base.get_current_health())

	base.take_damage(500.0)
	if base.get_current_health() != 0.0:
		failures.append("asiri hasar sonrasi beklenen: 0, gelen: %s" % base.get_current_health())

	# Negatif hasar bir sey yapmamali
	base.set_health(300.0)
	base.take_damage(-50.0)
	if base.get_current_health() != 300.0:
		failures.append("negatif hasar sonrasi beklenen: 300, gelen: %s" % base.get_current_health())

	station.queue_free()
	await get_tree().process_frame

func _failures_for_heal(failures: Array[String]) -> void:
	var station_scene: PackedScene = load("res://Scenes/Base/base_station.tscn")
	var station: Node = station_scene.instantiate()
	add_child(station)
	await get_tree().process_frame

	var base := station as BaseStation

	base.take_damage(200.0)
	base.heal(100.0)
	if base.get_current_health() != 400.0:
		failures.append("iyilestirme sonrasi beklenen: 400, gelen: %s" % base.get_current_health())

	# Max uzerine cikmamali
	base.heal(9999.0)
	if base.get_current_health() != 500.0:
		failures.append("asiri iyilestirme sonrasi beklenen: 500, gelen: %s" % base.get_current_health())

	station.queue_free()
	await get_tree().process_frame

func _failures_for_set_health(failures: Array[String]) -> void:
	var station_scene: PackedScene = load("res://Scenes/Base/base_station.tscn")
	var station: Node = station_scene.instantiate()
	add_child(station)
	await get_tree().process_frame

	var base := station as BaseStation

	base.set_health(250.0)
	if base.get_current_health() != 250.0:
		failures.append("set_health sonrasi beklenen: 250, gelen: %s" % base.get_current_health())

	# Clamp kontrolleri
	base.set_health(-100.0)
	if base.get_current_health() != 0.0:
		failures.append("negatif set_health sonrasi beklenen: 0, gelen: %s" % base.get_current_health())

	base.set_health(9999.0)
	if base.get_current_health() != 500.0:
		failures.append("asiri set_health sonrasi beklenen: 500, gelen: %s" % base.get_current_health())

	station.queue_free()
	await get_tree().process_frame
