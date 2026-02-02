class_name SpawnWeightCalculator

## Asteroid spawn agirligi ve boyut hesaplama yardimcisi.
## Saf matematik fonksiyonlari - state tutmaz.

static func get_weight_for_scale(
		scale_value: float,
		weight_min_scale: float,
		weight_max_scale: float,
		weight_steps: int
	) -> int:
	if weight_steps <= 1:
		return 1
	if weight_max_scale <= weight_min_scale:
		return 1
	var ratio := clampf((scale_value - weight_min_scale) / (weight_max_scale - weight_min_scale), 0.0, 1.0)
	var raw := int(floor(ratio * float(weight_steps))) + 1
	return clampi(raw, 1, weight_steps)

static func pick_spawn_scale(
		rng: RandomNumberGenerator,
		spawn_weight_small: int,
		spawn_weight_once: int,
		spawn_weight_multi: int,
		spawn_scale_tier_small: Vector2,
		spawn_scale_tier_once: Vector2,
		spawn_scale_tier_multi: Vector2,
		scale_range: Vector2,
		roll: float = -1.0
	) -> float:
	var w1 := maxi(spawn_weight_small, 0)
	var w2 := maxi(spawn_weight_once, 0)
	var w3 := maxi(spawn_weight_multi, 0)
	var total := w1 + w2 + w3
	if total <= 0:
		return rng.randf_range(scale_range.x, scale_range.y)

	var r := roll
	if r < 0.0:
		r = rng.randf()
	r = clampf(r, 0.0, 0.999999) * float(total)

	if r < float(w1):
		return rng.randf_range(spawn_scale_tier_small.x, spawn_scale_tier_small.y)
	r -= float(w1)
	if r < float(w2):
		return rng.randf_range(spawn_scale_tier_once.x, spawn_scale_tier_once.y)
	return rng.randf_range(spawn_scale_tier_multi.x, spawn_scale_tier_multi.y)

static func get_asteroid_weight(
		asteroid: Node2D,
		weight_min_scale: float,
		weight_max_scale: float,
		weight_steps: int
	) -> int:
	if not asteroid:
		return 0
	return get_weight_for_scale(asteroid.scale.x, weight_min_scale, weight_max_scale, weight_steps)
