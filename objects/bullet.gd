extends RigidBody2D

const SPEED = 700

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# El movimiento físico se asigna directamente mediante la velocidad lineal
	# Rotamos el vector derecho nativo para que coincida con la dirección del disparo
	linear_velocity = Vector2.RIGHT.rotated(rotation) * SPEED
	
	# Conectamos la señal interna de colisión por código para asegurar estabilidad
	body_entered.connect(_on_body_entered)
	
	# Si la bala no choca con nada, se destruye tras 2 segundos
	await get_tree().create_timer(2.0).timeout
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	# Verifica colisión mediante el sistema de grupos
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage()
			
	# La bala se destruye inmediatamente tras el impacto físico
	queue_free()
