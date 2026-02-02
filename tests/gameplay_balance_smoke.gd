extends Node

const EXPECTED_DAMAGE_PER_SECOND := 20
const EXPECTED_DAMAGE_TICK_SECONDS := 1
const EXPECTED_MAX_HEAT := 120
const EXPECTED_HEAT_PER_SECOND := 10
const EXPECTED_COOLING_RATE := 80
const EXPECTED_OVERHEAT_COOLDOWN := 4

const EXPECTED_ASTEROID_MIN_HEALTH := 20
const EXPECTED_ASTEROID_MAX_HEALTH := 100
const EXPECTED_ITEM_DROP_SCALE := 0.24

const SPAWN_EDGE_BUFFER := 200.0

func _ready() -> void:
	var failures: Array[String] = []

	await get_tree().process_frame

	_failures_for_laser(failures)
	_failures_for_asteroid_health(failures)
	await _failures_for_asteroid_spawn(failures)
	_failures_for_item_drop_scale(failures)
	await _failures_for_transfer_all(failures)

	if not failures.is_empty():
		for msg in failures:
			push_error(msg)
		get_tree().quit(1)
		return

	get_tree().quit(0)

func _failures_for_laser(failures: Array[String]) -> void:
	var laser_scene: PackedScene = load("res://Scenes/Weapons/laser_beam.tscn")
	if not laser_scene:
		failures.append("laser: laser_beam.tscn not found")
		return

	var laser := laser_scene.instantiate()
	add_child(laser)

	if laser.damage_per_second != EXPECTED_DAMAGE_PER_SECOND:
		failures.append("laser: damage_per_second expected %s" % EXPECTED_DAMAGE_PER_SECOND)
	if laser.damage_tick_seconds != EXPECTED_DAMAGE_TICK_SECONDS:
		failures.append("laser: damage_tick_seconds expected %s" % EXPECTED_DAMAGE_TICK_SECONDS)
	if laser.max_heat != EXPECTED_MAX_HEAT:
		failures.append("laser: max_heat expected %s" % EXPECTED_MAX_HEAT)
	if laser.heat_per_second != EXPECTED_HEAT_PER_SECOND:
		failures.append("laser: heat_per_second expected %s" % EXPECTED_HEAT_PER_SECOND)
	if laser.cooling_rate != EXPECTED_COOLING_RATE:
		failures.append("laser: cooling_rate expected %s" % EXPECTED_COOLING_RATE)
	if laser.overheat_cooldown_duration != EXPECTED_OVERHEAT_COOLDOWN:
		failures.append("laser: overheat_cooldown_duration expected %s" % EXPECTED_OVERHEAT_COOLDOWN)

func _failures_for_asteroid_health(failures: Array[String]) -> void:
	var asteroid_scene: PackedScene = load("res://Scenes/Environment/asteroid.tscn")
	if not asteroid_scene:
		failures.append("asteroid: asteroid.tscn not found")
		return

	var asteroid := asteroid_scene.instantiate()
	add_child(asteroid)
	asteroid._apply_health_from_scale(0.4)
	if int(asteroid.max_health) != EXPECTED_ASTEROID_MIN_HEALTH:
		failures.append("asteroid: min health expected %s" % EXPECTED_ASTEROID_MIN_HEALTH)
	asteroid._apply_health_from_scale(1.2)
	if int(asteroid.max_health) != EXPECTED_ASTEROID_MAX_HEALTH:
		failures.append("asteroid: max health expected %s" % EXPECTED_ASTEROID_MAX_HEALTH)

func _failures_for_asteroid_spawn(failures: Array[String]) -> void:
	var game_scene: PackedScene = load("res://Scenes/game.tscn")
	if not game_scene:
		failures.append("asteroid_field: game.tscn not found")
		return

	var game := game_scene.instantiate()
	add_child(game)
	var field := game.get_node_or_null("AsteroidField")
	if not field:
		failures.append("asteroid_field: AsteroidField node missing")
		return

	var view_size: Vector2 = get_viewport().get_visible_rect().size
	var max_view_radius: float = view_size.length() * 0.5 * float(field.camera_max_zoom)
	var expected_min: float = max_view_radius + SPAWN_EDGE_BUFFER
	if field.spawn_min_distance < expected_min:
		failures.append("asteroid_field: spawn_min_distance below max zoom view")
	if field.spawn_max_distance < field.spawn_min_distance:
		failures.append("asteroid_field: spawn_max_distance below spawn_min_distance")

	var slow_zoom: float = float(field.slow_zone_zoom)
	var slow_view_radius: float = view_size.length() * 0.5 * slow_zoom
	if field._slow_zone_radius < slow_view_radius:
		failures.append("asteroid_field: slow zone radius below slow zoom view")
	if field.max_area_capacity != 50:
		failures.append("asteroid_field: max area capacity expected 50")
	if field.weight_steps != 5:
		failures.append("asteroid_field: weight steps expected 5")

	var player := game.get_node_or_null("Player") as Node2D
	if not player:
		failures.append("asteroid_field: Player node missing")
		game.queue_free()
		await get_tree().process_frame
		return

	var expected_weight: int = 0
	var min_scale: float = float(field.weight_min_scale)
	var max_scale: float = float(field.weight_max_scale)
	if max_scale <= min_scale:
		failures.append("asteroid_field: weight scale range invalid")
		game.queue_free()
		await get_tree().process_frame
		return
	var step: float = (max_scale - min_scale) / float(field.weight_steps)
	var weight_cases := []
	for i in range(1, field.weight_steps + 1):
		var sample_scale := min_scale + step * (float(i - 1) + 0.1)
		weight_cases.append({"scale": sample_scale, "weight": i})
	weight_cases.append({"scale": min_scale, "weight": 1})
	weight_cases.append({"scale": max_scale, "weight": field.weight_steps})
	field._active_asteroids.clear()
	for entry in weight_cases:
		var w: int = field._get_weight_for_scale(entry.scale)
		if w != entry.weight:
			failures.append("asteroid_field: weight mismatch (%s -> %s)" % [entry.scale, w])
			break
		expected_weight += entry.weight
		var ast: Asteroid = field._create_asteroid()
		ast._scale_initialized = true
		ast.scale = Vector2.ONE * float(entry.scale)
		ast.global_position = player.global_position
		field._activate_asteroid(ast)
		field._active_asteroids.append(ast)

	var total_weight: int = field._get_area_weight()
	if total_weight != expected_weight:
		failures.append("asteroid_field: area weight expected %s got %s" % [expected_weight, total_weight])
	for ast in field._active_asteroids:
		if ast:
			ast.queue_free()
	field._active_asteroids.clear()

	field._spawn_asteroid()
	await get_tree().process_frame
	if field._active_asteroids.is_empty():
		failures.append("asteroid_field: no active asteroids spawned")
		game.queue_free()
		await get_tree().process_frame
		return
	var asteroid: Asteroid = field._active_asteroids[0]
	if not asteroid._steer_enabled:
		failures.append("asteroid_field: steering not enabled")
	if absf(asteroid._fast_speed - asteroid._slow_speed) > 0.01:
		failures.append("asteroid_field: speed should be constant")
	if asteroid._slow_speed < field.speed_range.x or asteroid._slow_speed > field.speed_range.y:
		failures.append("asteroid_field: speed out of range")
	if asteroid._drift_strength <= 0.0:
		failures.append("asteroid_field: drift strength not set")
	var dir_to_player := (player.global_position - asteroid.global_position).normalized()
	var vel_dir := asteroid.velocity.normalized()
	if vel_dir.length() > 0.001 and dir_to_player.dot(vel_dir) > 0.98:
		failures.append("asteroid_field: fly-by too direct")

	game.queue_free()
	await get_tree().process_frame

func _failures_for_item_drop_scale(failures: Array[String]) -> void:
	var drop_scene: PackedScene = load("res://Scenes/Items/item_drop.tscn")
	if not drop_scene:
		failures.append("item_drop: item_drop.tscn not found")
		return

	var drop := drop_scene.instantiate()
	add_child(drop)
	var sprite := drop.get_node_or_null("Sprite2D") as Sprite2D
	if not sprite:
		failures.append("item_drop: Sprite2D missing")
		return
	if sprite.scale != Vector2.ONE * EXPECTED_ITEM_DROP_SCALE:
		failures.append("item_drop: sprite scale expected %s" % EXPECTED_ITEM_DROP_SCALE)

func _failures_for_transfer_all(failures: Array[String]) -> void:
	var ui_scene: PackedScene = load("res://Scenes/UI/inventory_ui.tscn")
	if not ui_scene:
		failures.append("inventory_ui: inventory_ui.tscn not found")
		return

	var player_scene: PackedScene = load("res://Scenes/Player/player.tscn")
	var base_scene: PackedScene = load("res://Scenes/Base/base_station.tscn")
	if not player_scene or not base_scene:
		failures.append("inventory_ui: player or base scene missing")
		return

	var ui := ui_scene.instantiate()
	var player := player_scene.instantiate()
	var base := base_scene.instantiate()
	add_child(player)
	add_child(base)
	add_child(ui)
	await get_tree().process_frame
	for node in get_tree().get_nodes_in_group("player"):
		if node != player:
			node.remove_from_group("player")
	var players := get_tree().get_nodes_in_group("player")
	if players.size() != 1 or players[0] != player:
		failures.append("inventory_ui: unexpected player group (%s)" % players.size())
		return

	var actions := ui.get_node_or_null("Root/ActionPanel/Actions")
	if not actions:
		failures.append("inventory_ui: action buttons missing")
		return

	var transfer_button: Button = null
	for child in actions.get_children():
		if child is Button and child.text == "Transfer All":
			transfer_button = child
			break
	if not transfer_button:
		failures.append("inventory_ui: Transfer All button missing")
		return
	if not transfer_button.is_connected("pressed", Callable(ui, "_on_transfer_all_pressed")):
		failures.append("inventory_ui: Transfer All button not connected")
		return

	var ship_inv: InventoryComponent = player.get_inventory()
	var base_inv: InventoryComponent = base.get_inventory()
	ui._ship_inventory = ship_inv
	ui._base_inventory = base_inv
	var added := ship_inv.add_item("iron", 5)
	if added != 5:
		failures.append("inventory_ui: add_item failed (%s)" % added)
	transfer_button.pressed.emit()
	await get_tree().process_frame
	var ship_count := ship_inv.get_item_count("iron")
	var base_count := base_inv.get_item_count("iron")
	if ship_count != 0:
		failures.append("inventory_ui: ship inventory not emptied (%s)" % ship_count)
	if base_count != 5:
		failures.append("inventory_ui: base inventory not filled (%s)" % base_count)
