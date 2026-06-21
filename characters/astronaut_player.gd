extends CharacterBody2D

signal died

signal health_changed(new_health: int)

const speed = 200
const acceleration = 800
const friction = 1000
# Variable que recuerda la ultima posicion hacia donde miró el personaje
var last_direction := Vector2.DOWN
var hitbox_offset: Vector2
# Bandera para el ataque
var is_attacking: bool = false
# Bandera para saber si el personaje está vivo
var is_alive: bool = true
# Daño base del personaje
var strength: int
var max_health: int
var health: int

@onready var move_state_machine = $Animation/AnimationTree.get("parameters/MoveStateMachine/playback")
@onready var action_state_machine = $Animation/AnimationTree.get("parameters/ActionStateMachine/playback")
@onready var swing_sword_sound: AudioStreamPlayer2D = $SwingSword
@onready var swing_pickaxe_sound: AudioStreamPlayer2D = $SwingPickaxe
@onready var hitbox: Area2D = $Hitbox
@onready var take_damage_sound: AudioStreamPlayer2D = $TakeDamage
@onready var damage_cooldown: Timer = $DamageCooldown


func _ready() -> void:
	# Carga las stats del personaje
	health = AstronautPlayerStats.health
	max_health = AstronautPlayerStats.max_health
	strength = AstronautPlayerStats.strength
	# Inicializa el offset del hitobx
	hitbox_offset = hitbox.position

func _physics_process(delta: float) -> void:
	if is_alive:
		# Comprueba si el OneShot está activo (si el personaje está atacando/recogiendo/farmeando)
		var is_acting: bool = bool($Animation/AnimationTree.get("parameters/OneShot/active"))
		# Escucha si el jugador presiona botones de acción
		get_basic_input(is_acting)
		if not is_acting:
			# Si NO está actuando, le permitimos moverse y caminar
			# Caputa el input una única vez por frame
			var direction := Input.get_vector("left", "right", "up", "down")
			# Recibe hacia donde ir (direction) y caunto tiempo ha pasado (delta)
			move(direction, delta)
			# Recibe hacia donde mira el personaje para actualizar el BlendSpace
			animate(direction)
		else:
			# Si ESTÁ actuando, forzamos un input de ZERO para que frene con fricción
			move(Vector2.ZERO, delta)

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
		update_hitbox_offset()
		# Le pasamos la dirección a AMBOS BlendSpaces (para que al frenar sepa hacia dónde mirar)
		$Animation/AnimationTree.set("parameters/MoveStateMachine/Walk/blend_position", last_direction)
		$Animation/AnimationTree.set("parameters/MoveStateMachine/Idle/blend_position", last_direction)
		
		# Viajamos al estado de Caminar
		move_state_machine.travel("Walk")
	else:
		# Si no hay input, viajamos al estado Quieto (Idle)
		move_state_machine.travel("Idle")
		
func get_basic_input(is_acting: bool):
	# --- ACCIÓN: ATACAR ---
	if Input.is_action_just_pressed("attack") and not is_acting:
		print("attack")
		is_attacking = true
		swing_sword_sound.play()
		# Le decimos a la máquina de acción hacia dónde mirar
		$Animation/AnimationTree.set("parameters/ActionStateMachine/Attack/blend_position", last_direction)
		# Viaja al estado correcto
		action_state_machine.travel("Attack")
		# Disparamos el OneShot (acción)
		$Animation/AnimationTree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		
		# Revisa objetos dentro de la hitbox al atacar
		var near_bodies = hitbox.get_overlapping_bodies()
		
		# Recorremos la lista de cuerpos detectados
		for body in near_bodies:
			if body.is_in_group("enemies"):
				body.take_damage(strength, position)
				print(body.name, " Hit! (Daño estático)")
		
		# Pausa la ejecución hasta finalizar la animación
		await get_tree().create_timer(0.8).timeout 
		
		# Baja la bandera cuando el ataque termina
		is_attacking = false
	
	# --- ACCIÓN: FARMEAR ---
	if Input.is_action_just_pressed("farm") and not is_acting:
		print("farm")
		swing_pickaxe_sound.play()
		# Le decimos a la máquina de acción hacia dónde mirar
		$Animation/AnimationTree.set("parameters/ActionStateMachine/Farm/blend_position", last_direction)
		# Viaja al estado correcto
		action_state_machine.travel("Farm")
		# Disparamos el OneShot (acción)
		$Animation/AnimationTree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		
	# --- ACCIÓN: INTERACTUAR (Recoger) ---
	if Input.is_action_just_pressed("interact") and not is_acting:
		print("interact")
		# Le decimos a la máquina de acción hacia dónde mirar
		$Animation/AnimationTree.set("parameters/ActionStateMachine/PickingUp/blend_position", last_direction)
		# Viaja al estado correcto
		action_state_machine.travel("PickingUp")
		# Disparamos el OneShot (acción)
		$Animation/AnimationTree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		
# Actualiza la posición de la hitbox según la última dirección registrada del personaje
func update_hitbox_offset() -> void:
	# valores iniciales de los ejes X e Y
	var x := hitbox_offset.x
	var y := hitbox_offset.y
	
	# Evalúa el vector de dirección para reasignar la posición espacial de la hitbox
	match last_direction:
		Vector2.LEFT:
			# Desplaza la hitbox hacia el lado izquierdo invirtiendo el valor horizontal
			hitbox.position = Vector2(-x, y)
		Vector2.RIGHT:
			# Mantiene el desplazamiento original apuntando hacia el lado derecho
			hitbox.position = Vector2(x, y)
		Vector2.UP:
			# Intercambia y ajusta las coordenadas para posicionar la hitbox en la parte superior
			hitbox.position = Vector2(y, -x)
		Vector2.DOWN:
			# Intercambia y ajusta las coordenadas para posicionar la hitbox en la parte inferior
			hitbox.position = Vector2(-y, x)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_attacking and body.is_in_group("enemies"):
		body.take_damage(strength, position)
		print(body.name, " Hit! (Daño dinámico)")

func take_damage(amount: int) -> void:
	if is_alive:
		if damage_cooldown.time_left > 0:
			return
		take_damage_sound.play()
		health -= amount
		AstronautPlayerStats.health = health
		emit_signal("health_changed", health)
		if health <= 0:
			die()
		# Personaje es invensible por un periodo de tiempo para no recibir multiples ataques simultaneos
		damage_cooldown.start()

func die() -> void:
	# Crear animación para cuando el personaje muere
	print("You are dead")
	is_alive = false
	# Espera a que termine la animación antes de emitir la señal
	died.emit()
