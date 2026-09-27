class_name SimRng
extends RefCounted
## Seeded random source for the sim layer. Every draw goes through here so a
## run replays from its seed. The sim never touches the global RNG.

var _rng := RandomNumberGenerator.new()
var seed_value: int


func _init(seed: int) -> void:
	seed_value = seed
	_rng.seed = seed


func range_int(low: int, high_inclusive: int) -> int:
	return _rng.randi_range(low, high_inclusive)


## Weighted draw: weights is {key: weight}. Returns a key.
func weighted(weights: Dictionary) -> Variant:
	var total := 0.0
	for key in weights:
		total += float(weights[key])
	var roll := _rng.randf() * total
	var acc := 0.0
	for key in weights:
		acc += float(weights[key])
		if roll < acc:
			return key
	return weights.keys().back()


func state() -> int:
	return _rng.state
