extends CharacterBody2D

# ============================================================================
# SLIME - Agente autonomo
# Implementa una FSM (Finite State Machine) con 3 estados: PATROL, CHASE, ATTACK.
# ============================================================================

signal died  # avisamos cuando el slime muere

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var take_damage_sound: AudioStreamPlayer2D = $TakeDamage
@onready var health_bar: Node2D = $HealthBar
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var sight_shape: CollisionShape2D = $Sight/CollisionShape2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

# ---------------------------------------------------------------------------
# Estados de la FSM
# ---------------------------------------------------------------------------
enum State { PATROL, CHASE, ATTACK }
var current_state: State = State.PATROL

# ---------------------------------------------------------------------------
# Parametros configurables desde el inspector
# ---------------------------------------------------------------------------
@export_group("Deteccion")
@export var detection_range: float = 150.0   # Radio del Area2D "Sight"

@export_group("Combate")
@export var attack_range: float = 26.0       # Distancia a la que ataca en vez de perseguir
@export var knockback_force: float = 60.0
const DROP_CHANCE: float = 0.5

@export_group("Movimiento")
@export var patrol_speed: float = 40.0
@export var chase_speed: float = 50.0
@export var patrol_radius: float = 80.0      # Radio de patrullaje alrededor del punto de origen
@export var patrol_wait_time: float = 1.5    # Espera al llegar a un punto de patrullaje
@export var patrol_point_timeout: float = 4.0 # Si no llega al punto en este tiempo, elige otro

var is_alive: bool = true
var health: int = 100
var strength: int = 10
var target: Node2D = null

var home_position: Vector2
var patrol_target: Vector2
var patrol_timer: float = 0.0        # cuenta espera en el punto
var patrol_travel_timer: float = 0.0 # cuenta tiempo intentando llegar

var health_pickup_scene = preload("res://scenes/health_pickup.tscn")


func _ready() -> void:
	home_position = global_position
	# El rango de deteccion se controla desde el inspector (detection_range),
	# y se aplica al radio del Area2D "Sight" para mantener todo sincronizado.
	if sight_shape and sight_shape.shape is CircleShape2D:
		sight_shape.shape.radius = detection_range

	_enter_state(State.PATROL)


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	match current_state:
		State.PATROL:
			_update_patrol(delta)
		State.CHASE:
			_update_chase(delta)
		State.ATTACK:
			_update_attack(delta)


# ============================================================================
# TRANSICIONES DE ESTADO (OnEnter / OnExit)
# ============================================================================

func _change_state(new_state: State) -> void:
	if new_state == current_state:
		return
	_exit_state(current_state)
	current_state = new_state
	_enter_state(new_state)


func _enter_state(state: State) -> void:
	match state:
		State.PATROL:
			_pick_new_patrol_point()
			patrol_timer = 0.0
			patrol_travel_timer = 0.0
			if animated_sprite_2d.animation != "idle":
				animated_sprite_2d.play("idle")
		State.CHASE:
			pass  # el movimiento se resuelve en _update_chase
		State.ATTACK:
			if animated_sprite_2d.animation != "attack":
				animated_sprite_2d.play("attack")


func _exit_state(state: State) -> void:
	match state:
		State.ATTACK:
			pass  # nada que limpiar; la animacion cambia al entrar al nuevo estado
		_:
			pass


# ============================================================================
# LOGICA DE CADA ESTADO
# ============================================================================

func _update_patrol(delta: float) -> void:
	patrol_travel_timer += delta
	var distance_to_point := global_position.distance_to(patrol_target)

	if distance_to_point <= 4.0:
		# Llego al punto: espera un momento antes de elegir el siguiente
		velocity = Vector2.ZERO
		move_and_slide()
		patrol_timer += delta
		if patrol_timer >= patrol_wait_time:
			_pick_new_patrol_point()
			patrol_timer = 0.0
			patrol_travel_timer = 0.0
		return

	if patrol_travel_timer >= patrol_point_timeout:
		# Se quedo atascado intentando llegar (p.ej. contra una esquina): reintenta con otro punto
		_pick_new_patrol_point()
		patrol_travel_timer = 0.0

	_move_towards(patrol_target, patrol_speed)


func _update_chase(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		_change_state(State.PATROL)
		return

	var distance_to_target := global_position.distance_to(target.global_position)
	if distance_to_target <= attack_range:
		_change_state(State.ATTACK)
		return

	_move_towards(target.global_position, chase_speed)


func _update_attack(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		_change_state(State.PATROL)
		return

	var distance_to_target := global_position.distance_to(target.global_position)
	if distance_to_target > attack_range * 1.3:
		_change_state(State.CHASE)
		return

	# En ataque el slime se mantiene quieto (el dano real lo gestiona el Area2D "Hitbox",
	# ver _on_hitbox_body_entered / _on_attack_cooldown_timeout mas abajo -> Integracion R4).
	velocity = Vector2.ZERO
	move_and_slide()


# ============================================================================
# MOVIMIENTO CON NAVEGACION (Opcion B - NavigationAgent2D)
# ============================================================================

func _move_towards(point: Vector2, speed: float) -> void:
	nav_agent.target_position = point

	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var next_path_pos: Vector2 = nav_agent.get_next_path_position()
	var desired_dir := (next_path_pos - global_position).normalized()
	velocity = desired_dir * speed
	move_and_slide()
	if velocity.length() > 1.0:
		animated_sprite_2d.flip_h = velocity.x < 0


func _pick_new_patrol_point() -> void:
	var angle := randf_range(0.0, TAU)
	var dist := randf_range(patrol_radius * 0.3, patrol_radius)
	patrol_target = home_position + Vector2(cos(angle), sin(angle)) * dist


# ============================================================================
# DETECCION DEL JUGADOR (R3) -> dispara la transicion PATROL -> CHASE
# ============================================================================

func _on_sight_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body
		if current_state == State.PATROL:
			_change_state(State.CHASE)


func _on_sight_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and is_alive:
		target = null
		if current_state != State.PATROL:
			_change_state(State.PATROL)


# ============================================================================
# INTEGRACION R4 - Daño al jugador (se mantiene igual que antes: pasa por
# take_damage() del jugador, nunca se toca su variable de vida directamente)
# ============================================================================

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and is_alive:
		body.take_damage(strength)
		attack_cooldown.start()


func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and is_alive:
		attack_cooldown.stop()


func _on_attack_cooldown_timeout() -> void:
	if target and current_state == State.ATTACK:
		target.take_damage(strength)


# ============================================================================
# INTEGRACION R4 - Sistema de vida propio del agente
# ============================================================================

func take_damage(damage: int, attacker_postion: Vector2) -> void:
	health -= damage
	health_bar.update_health(health)
	if health <= 0:
		_die()
	else:
		take_damage_sound.play()
		var knockback_direction = (global_position - attacker_postion).normalized()
		var desired_target = global_position + knockback_direction * knockback_force

		# 1) No atravesar paredes: recorta el knockback en el primer obstaculo fisico
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(global_position, desired_target)
		query.collision_mask = 1  # capa de paredes/entorno
		query.exclude = [self]
		var hit = space_state.intersect_ray(query)
		var clamped_target = desired_target
		if hit:
			clamped_target = hit.position - knockback_direction * 4.0  # pequeño margen

		# 2) Ademas, nunca salir del area navegable (respaldo extra)
		var nav_map = nav_agent.get_navigation_map()
		var safe_target = NavigationServer2D.map_get_closest_point(nav_map, clamped_target)

		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(self, "global_position", safe_target, 0.5)


func _die() -> void:
	is_alive = false
	animated_sprite_2d.play("die")

	take_damage_sound.pitch_scale = 0.5
	take_damage_sound.play()

	$CollisionShape2D.set_deferred("disabled", true)
	$Sight/CollisionShape2D.set_deferred("disabled", true)
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)

	# Esperamos que termine la animacion antes de emitir y borrar
	await animated_sprite_2d.animation_finished
	died.emit()  # -> conectado en main.gd al contador de kills del HUD (efecto observable)
	queue_free()
	# Drop health pickup
	if randf() <= DROP_CHANCE:
		drop_item()


# Funcion que permite instanciar la escena del corazon de vida
func drop_item():
	var drop = health_pickup_scene.instantiate()
	drop.position = position
	var level_root = get_parent().get_parent()
	var items_node = level_root.get_node("Items")
	items_node.call_deferred("add_child", drop)
