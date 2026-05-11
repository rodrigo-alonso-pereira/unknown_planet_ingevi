extends Camera2D

# Exportamos una variable para asignarle el nodo del Astronauta desde el Inspector
@export var follow_object: Node2D

# Velocidad a la que la camara alcanza al jugador
const tracking_speed = 5.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Proyeccion ortográfica con cámara 2D
	make_current()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if follow_object != null:
		# Usamos la interpolación lineal (lerp) multiplicada por delta
		# Esto hace que el movimiento de la cámara sea suave y fluido,
		# sin tirones cuando cambia la tasa de cuadros por segundo (framerate).
		global_position = global_position.lerp(follow_object.global_position, tracking_speed * delta)
