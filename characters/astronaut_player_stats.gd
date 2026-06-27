extends Node

var health: int = 100
var max_health: int = 100
var strength: int = 20

func reset() -> void:
	health = max_health
