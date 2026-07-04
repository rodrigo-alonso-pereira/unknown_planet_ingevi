extends CharacterBody2D

signal died
signal health_changed(new_health: int)

const speed = 150
const acceleration = 600
var friction: float = 1000.0

var last_direction := Vector2.DOWN
var hitbox_offset: Vector2
var is_attacking: bool = false
var is_alive: bool = true
var strength: int
var max_health: int
var health: int

@onready var move_state_machine = $Animation/AnimationTree.get("parameters/MoveStateMachine/playback")
@onready var action_state_machine = $Animation/AnimationTree.get("parameters/ActionStateMachine/playback")
@onready var swing_sword_sound: AudioStreamPlayer2D = $SwingSword
@onready var hitbox: Area2D = $Hitbox
@onready var take_damage_sound: AudioStreamPlayer2D = $TakeDamage
@onready var damage_cooldown: Timer = $DamageCooldown


func _ready() -> void:
	health = AstronautPlayerStats.health
	max_health = AstronautPlayerStats.max_health
	strength = AstronautPlayerStats.strength
	hitbox_offset = hitbox.position

func _physics_process(delta: float) -> void:
	if is_alive:
		var is_acting: bool = bool($Animation/AnimationTree.get("parameters/OneShot/active"))
		get_basic_input(is_acting)
		if not is_acting:
			var direction := Input.get_vector("left", "right", "up", "down")
			move(direction, delta)
			animate(direction)
		else:
			move(Vector2.ZERO, delta)


func move(direction: Vector2, delta: float) -> void:
	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()


func animate(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		last_direction = Vector2(round(direction.x), round(direction.y))
		update_hitbox_offset()
		$Animation/AnimationTree.set("parameters/MoveStateMachine/Walk/blend_position", last_direction)
		$Animation/AnimationTree.set("parameters/MoveStateMachine/Idle/blend_position", last_direction)
		move_state_machine.travel("Walk")
	else:
		move_state_machine.travel("Idle")


func get_basic_input(is_acting: bool):
	if Input.is_action_just_pressed("attack") and not is_acting:
		is_attacking = true
		swing_sword_sound.play()
		$Animation/AnimationTree.set("parameters/ActionStateMachine/Attack/blend_position", last_direction)
		action_state_machine.travel("Attack")
		$Animation/AnimationTree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		var near_bodies = hitbox.get_overlapping_bodies()
		for body in near_bodies:
			if body.is_in_group("enemies"):
				body.take_damage(strength, position)
		await get_tree().create_timer(0.8).timeout
		is_attacking = false

	if Input.is_action_just_pressed("farm") and not is_acting:
		$Animation/AnimationTree.set("parameters/ActionStateMachine/Farm/blend_position", last_direction)
		action_state_machine.travel("Farm")
		$Animation/AnimationTree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

	if Input.is_action_just_pressed("interact") and not is_acting:
		$Animation/AnimationTree.set("parameters/ActionStateMachine/PickingUp/blend_position", last_direction)
		action_state_machine.travel("PickingUp")
		$Animation/AnimationTree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func update_hitbox_offset() -> void:
	var x := hitbox_offset.x
	var y := hitbox_offset.y
	match last_direction:
		Vector2.LEFT:
			hitbox.position = Vector2(-x, y)
		Vector2.RIGHT:
			hitbox.position = Vector2(x, y)
		Vector2.UP:
			hitbox.position = Vector2(y, -x)
		Vector2.DOWN:
			hitbox.position = Vector2(-y, x)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_attacking and body.is_in_group("enemies"):
		body.take_damage(strength, position)

# Funcion que permite aumentar la vida del personaje
func heal(amount: int) -> void:
	health += amount
	if health >= max_health:
		health = max_health
	AstronautPlayerStats.health = health
	emit_signal("health_changed", health)


func take_damage(amount: int) -> void:
	if is_alive:
		if damage_cooldown.time_left > 0:
			return
		take_damage_sound.play()
		health -= amount
		AstronautPlayerStats.health = health
		health_changed.emit(health)
		if health <= 0:
			die()
		damage_cooldown.start()


func die() -> void:
	is_alive = false
	$Animation/AnimationTree.active = false
	$Animation/AnimationPlayer.play("die")
	await $Animation/AnimationPlayer.animation_finished
	died.emit()
