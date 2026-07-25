extends StaticBody2D

signal victory_triggered
signal dialog_requested(text: String)  # pide mostrar dialogo
signal dialog_hide_requested            # pide ocultar dialogo

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_sound: AudioStreamPlayer2D = $Interact

# Variables para manejar el estado del robot 
var _player_in_range: bool = false
var _is_interacting: bool = false

func _ready() -> void:
	# Arranca en idle y conecta el signal de fin de animación
	animated_sprite_2d.play("idle")
	animated_sprite_2d.animation_finished.connect(_on_animation_finished)
	
func _unhandled_input(event: InputEvent) -> void:
	# Solo reacciona si el player está en rango y no está ya interactuando
	if _player_in_range and not _is_interacting:
		if event.is_action_pressed("interact"):
			_trigger_interact()

func _trigger_interact() -> void:
	_is_interacting = true
	interact_sound.play()
	# Decide qué animación reproducir según los minerales recolectados
	if AstronautPlayerStats.mineral_count >= 12:
		animated_sprite_2d.play("final")
	else:
		animated_sprite_2d.play("interact")
		# Calcula cuántos recursos faltan y muestra el diálogo
		var remaining := 12 - AstronautPlayerStats.mineral_count
		var text := "Estamos varados en un planeta desconocido...\nVuelve cuando recolectes %d recursos para poder reparar tu nave y escapar..." % remaining
		dialog_requested.emit(text, self)

func _on_animation_finished() -> void:
	match animated_sprite_2d.animation:
		"interact":
			_is_interacting = false
			animated_sprite_2d.play("idle")
		"final":
			# No vuelve a idle ni libera el estado — el juego termina
			victory_triggered.emit()


func _on_range_area_shape_entered(_area_rid: RID, area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	var body = area.get_parent()
	# Verificamos que el padre exista y que esté en el grupo "player"
	if body and body.is_in_group("player"):
		_player_in_range = true


func _on_range_area_shape_exited(_area_rid: RID, area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	var body = area.get_parent()
	# Verificamos que el padre exista y que esté en el grupo "player"
	if body and body.is_in_group("player"):
		_player_in_range = false
		# Si el jugador se aleja mientras el diálogo está abierto, lo cerramos
		dialog_hide_requested.emit()
