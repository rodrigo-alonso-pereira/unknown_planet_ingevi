extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var take_damage_sound: AudioStreamPlayer2D = $TakeDamage
@onready var health_bar: Node2D = $HealthBar
@onready var attack_cooldown: Timer = $AttackCooldown

const SPEED = 100.0
var is_alive: bool = true
const KNOCKBACK_FORCE: int = 100
var health: int = 100
var strength: int = 10
var target = null
var target_in_range: bool = false


func _physics_process(delta: float) -> void:
	if is_alive and target:
		_attack(delta)
	

func _attack(delta: float) -> void:
	var direction = (target.position - position).normalized()
	position += direction * SPEED * delta
	# Solo llamamos a play() si la animación NO se está reproduciendo ya
	if animated_sprite_2d.animation != "attack":
		animated_sprite_2d.play("attack")
		
func take_damage(damage: int, attacker_postion: Vector2) -> void:
	health -= damage
	health_bar.update_health(health)
	if health <= 0:
		_die()
	else:
		take_damage_sound.play()
		# Knockback
		var knockback_direction = (position - attacker_postion).normalized()
		var target_position = position + knockback_direction * KNOCKBACK_FORCE
		
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(self, "position", target_position, 0.5)
	

func _die() -> void:
	is_alive = false
	animated_sprite_2d.play("die")
	
	take_damage_sound.pitch_scale = 0.5
	take_damage_sound.play()
	
	# Desactiva la colision
	$CollisionShape2D.set_deferred("disabled", true)
	$Sight/CollisionShape2D.set_deferred("disabled", true)
	

func _on_sight_body_entered(body: Node2D) -> void:
	print("En rango: ", body.get_groups())
	if body.is_in_group("player"):
		target = body


func _on_sight_body_exited(body: Node2D) -> void:
	print("Fuera de rango: ", body.get_groups())
	if body.is_in_group("player") and is_alive:
		target = null


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and is_alive:
		target_in_range = true
		body.take_damage(strength)
		attack_cooldown.start()

func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and is_alive:
		target_in_range = false
		attack_cooldown.stop()

func _on_attack_cooldown_timeout() -> void:
	if target and target_in_range:
		target.take_damage(strength)
