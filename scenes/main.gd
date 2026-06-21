extends Node2D

@onready var hud: CanvasLayer = $HUD

var current_level_root: Node = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_level_root = get_node("SurvivalLevel")
	var player = current_level_root.get_node("AstronautPlayer")


func _load_level() -> void:
	if current_level_root:
		current_level_root.queue_free()
	
	var level_path = "res://scenes/survival_level.tscn"
	current_level_root = load(level_path).instantiate()
	add_child(current_level_root)
	current_level_root.name = "SurvivalLevel"
	_setup_level(current_level_root)

func _setup_level(level_root: Node) -> void:
	var player = level_root.get_node("AstronautPlayer")
	player.died.connect(_on_player_died)

func _on_player_died() -> void:
	# Pausa el juego por 5 segundos antes de reiniciar todo
	await get_tree().create_timer(5.0).timeout
	await hud.fade(5.0)
	AstronautPlayerStats.reset()
	_load_level()
	await hud.fade(0.0)
