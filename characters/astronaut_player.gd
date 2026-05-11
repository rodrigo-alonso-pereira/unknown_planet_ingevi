extends CharacterBody2D


const speed = 200
const acceleration = 800
const friction = 1000
# Variable que recuerda la ultima posicion hacia donde miró el personaje
var last_direction := Vector2.DOWN

@onready var anim_tree = $Animation/AnimationTree
@onready var move_state_machine = anim_tree.get("parameters/MoveStateMachine/playback")


func _physics_process(delta: float) -> void:
	# Caputa el input una única vez por frame
	var direction := Input.get_vector("left", "right", "up", "down")
	# Recibe hacia donde ir (direction) y caunto tiempo ha pasado (delta)
	move(direction, delta)
	# Recibe hacia donde mira el personaje para actualizar el BlendSpace
	animate(direction)

func move(direction: Vector2, delta: float) -> void:
	if direction != Vector2.ZERO:
		# Multiplica la aceleracion por delta (el tiempo en segundos desde el último frame)
		# Esto evita que el personaje se mueva mas rapido en PCs con altos FPS o mas 
		# lento si el juego sufre una caída de rendimiento
		velocity = velocity.move_toward(direction * speed, acceleration * delta)
	else:
		# Aplicamos el mismo principio de delta time para el frenado
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# Actualiza la posición final
	move_and_slide()

func animate(direction: Vector2) -> void:
	# Comprueba el movimiento comparandolo con un vector cero
	if direction != Vector2.ZERO:
		# Redondeamos el vector para que el BlendSpace reciba coordenadas exactas 
		# (-1, 0 o 1) y no valores decimales que puedan confundir la mezcla de la animacion
		last_direction = Vector2(round(direction.x), round(direction.y))
		# Le pasamos la dirección a AMBOS BlendSpaces (para que al frenar sepa hacia dónde mirar)
		anim_tree.set("parameters/MoveStateMachine/Walk/blend_position", last_direction)
		anim_tree.set("parameters/MoveStateMachine/Idle/blend_position", last_direction)
		
		# Viajamos al estado de Caminar
		move_state_machine.travel("Walk")
	else:
		# Si no hay input, viajamos al estado Quieto (Idle)
		move_state_machine.travel("Idle")
