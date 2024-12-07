extends Node

var generator := RandomNumberGenerator.new()

func random_int(number: int) -> int:
	return randi() % number


func random_weight() -> float:
	return randf()
