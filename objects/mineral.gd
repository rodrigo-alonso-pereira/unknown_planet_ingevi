extends StaticBody2D


const mineral_pickup_scene = preload("res://scenes/mineral_pickup.tscn")
@onready var mineral_sound: AudioStreamPlayer2D = $Mineral
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var take_damage_sound: AudioStreamPlayer2D = $TakeDamage


var health: int = 40
var player_in_range: bool = false
# Flag para no permitir multiples acciones de farmeo simultaneas
var is_being_damaged: bool = false


func _ready() -> void:
	# Aseguramos que el sprite comience en la primera imagen/frame
	if sprite_2d:
		sprite_2d.frame = 1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Si el jugador está dentro del rango y presiona la tecla de farmear
	if player_in_range and not is_being_damaged and Input.is_action_just_pressed("farm"):
		take_damage(AstronautPlayerStats.strength)

func take_damage(amount: int) -> void:
	is_being_damaged = true
	health -= amount
	take_damage_sound.play()
	await take_damage_sound.finished
	if health <= 0:
		drop_item()
		queue_free() # Elimina el mineral del juego por completo
	else:
		if health <= 20 and sprite_2d:
			sprite_2d.frame = 0
		await get_tree().create_timer(0.8).timeout
		is_being_damaged = false  # ← libera solo si el mineral sigue vivo

func _on_range_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	# Obtenemos el padre del área que entró (el AstronautPlayer)
	var body = area.get_parent()
	if body and body.is_in_group("player"):
		player_in_range = true


func _on_range_area_shape_exited(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	var body = area.get_parent()
	if body and body.is_in_group("player"):
		player_in_range = false

func drop_item() -> void:
	# Lógica para spawnear el item en el suelo.
	var drop = mineral_pickup_scene.instantiate()
	drop.global_position = global_position
	var level_root = get_parent().get_parent()
	var items_node = level_root.get_node("Items")
	items_node.call_deferred("add_child", drop)
