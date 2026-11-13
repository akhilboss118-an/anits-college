class_name LCG
extends RefCounted
## The original game's deterministic pseudo-random generator.
##
## game.js:  let seed = 5;
##            const rnd = () => (seed = seed * 16807 % 2147483647) / 2147483647;
## Reproducing it exactly means the rebuilt campus grows the same forest.

var _seed: int = 5
var _calls: int = 0


func _init(seed_value: int = 5) -> void:
	_seed = seed_value


func randf() -> float:
	_seed = (_seed * 16807) % 2147483647
	_calls += 1
	return float(_seed) / 2147483647.0


func randf_range(from: float, to: float) -> float:
	return from + (to - from) * randf()


func randi_range(from: int, to: int) -> int:
	return from + int(randf() * float(to - from + 1))


func reset(seed_value: int = 5) -> void:
	_seed = seed_value
	_calls = 0


func calls() -> int:
	return _calls
