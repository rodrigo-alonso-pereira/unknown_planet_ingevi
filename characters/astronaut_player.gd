extends CharacterBody2D


const speed = 200
const acceleration = 800
const friction = 1000
# Variable que recuerda la ultima posicion hacia donde miró el personaje
var last_direction := Vector2.DOWN
# Control de estado para la mecánica principal
var has_weapon := false
# Carga de la escena de la bala
@export var bullet_scene: PackedScene

@onready var anim_tree = $Animation/AnimationTree
@onready var move_state_machine = anim_tree.get("parameters/MoveStateMachine/playback")
@onready var sprite = Sprite2D
@onready var shoot_sound = $ShootSound


func _physics_process(delta: float) -> void:
	# Caputa el input una única vez por frame
	var direction := Input.get_vector("left", "right", "up", "down")
	# Recibe hacia donde ir (direction) y caunto tiempo ha pasado (delta)
	move(direction, delta)
	# Recibe hacia donde mira el personaje para actualizar el BlendSpace
	animate(direction)
	# Verificacion de interaccion
	if Input.is_action_just_pressed("interact"):
		anim_tree.set("parameters/ActionStateMachine/PickingUp/blend_position", last_direction)
	# Verificacion de disparo
	if has_weapon and Input.is_action_just_pressed("shoot"):
		print("arma equipada")

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
# Función llamada por weapon_pickup al interactuar
func equip_weapon() -> void:
	has_weapon = true
	print("Arma de astronauta equipada con éxito")
	
#func shoot() -> void:
	#if bullet_scene == null:
		#return
		#
	## Instanciamos el proyectil balístico en tiempo de ejecución
	#var bullet_instance = bullet_scene.instantiate()
	#
	## Calculamos el vector de salida horizontal basado en la orientación del personaje
	#var shoot_direction = Vector2.RIGHT
	#if sprite.flip_h:
		#shoot_direction = Vector2.LEFT
		#
	## Añadimos el proyectil al nodo raíz del nivel para independizar su trayectoria física
	#get_parent().add_child(bullet_instance)
	#
	## Posicionamos la bala en el origen del jugador
	#bullet_instance.global_position = global_position
	#bullet_instance.rotation = shoot_direction.angle()
	#
	## Reproducción del AudioStreamPlayer sin distorsión
	#if shoot_sound:
		#shoot_sound.play()
		#
	## Squash & Stretch del cuerpo del astronauta al disparar
	#apply_shoot_kickback()
#
#func apply_shoot_kickback() -> void:
	## Deformación dinámica del sprite usando interpolación por Tween
	#var tween = create_tween()
	#tween.tween_property(sprite, "scale", Vector2(0.85, 1.15), 0.04)
	#tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.08)
