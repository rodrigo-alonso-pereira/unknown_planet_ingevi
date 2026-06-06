#extends Area2D
#
#var player_nearby: bool = false
#
## Called every frame
#func _process(_delta: float) -> void:
	## Si el jugador esta dentro del area y presiona la tecla de interacción
	#if player_nearby and Input.is_action_just_pressed("interact"):
		## Llama a una funcion para equipar el arma
		#var player = get_tree().get_first_node_in_group("player")
		#if player:
			## Avisa al jugador que puede disparar
			#player.equip_weapon()
			## Destruye el arma puesta en escena
			#queue_free()
#
#
#func _on_body_entered(body: Node2D) -> void:
	#if body.is_in_group("player"):
		## Si el jugador se acerca al arma, cambia el booleano a true y muestra el texto para recoger el arma
		#print("Near weapon")
		#player_nearby = true
		#$Label.show()
#
#func _on_body_exited(body: Node2D) -> void:
	#if body.is_in_group("player"):
		## Si el jugador se aleja del arma, cambia el booleano a false y oculta el texto
		#print("Exit weapon")
		#player_nearby = false
		#$Label.hide()
