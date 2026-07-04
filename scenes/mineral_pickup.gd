extends Area2D


@onready var collected_sound: AudioStreamPlayer2D = $CollectedSound
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		visible = false
		collision_shape_2d.set_deferred("disabled", true)
		
		# Incrementa el contador y emite la señal del autoload
		AstronautPlayerStats.mineral_count += 1
		AstronautPlayerStats.mineral_collected.emit(AstronautPlayerStats.mineral_count)
		
		collected_sound.play()
		await collected_sound.finished
		
		queue_free()
