extends Node

var health: int = 100
var max_health: int = 100
var strength: int = 20
# Variables para llevar el conteo de minerales recolectados
signal mineral_collected(count: int)
var mineral_count: int = 0

func reset() -> void:
	health = max_health
	mineral_count = 0
