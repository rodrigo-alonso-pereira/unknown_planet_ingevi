extends Node2D

@onready var hud: CanvasLayer = $HUD
@onready var background_music: AudioStreamPlayer = $BackgroundMusic
@onready var victory_sound: AudioStreamPlayer = $VictorySound

var level: int = 1
var current_level_root: Node = null
var _kill_count: int = 0

func _ready() -> void:
	await get_tree().process_frame
	# Conecta los botones de reinicio y termino del juego 
	hud.restart_requested.connect(_on_restart_requested)
	hud.quit_requested.connect(_on_quit_requested)
	# Conecta la señal del autoload al HUD una sola vez aquí
	AstronautPlayerStats.mineral_collected.connect(hud.update_minerals)
	current_level_root = get_node("LevelRoot")
	# Busca la escena del nivel
	if current_level_root:
		_load_level(level)
		hud._update_health(AstronautPlayerStats.health)
		_play_background_music()
	else:
		print("CRÍTICO: Main no encontró el nodo LevelRoot")

# Funcion que actualiza el nivel del jugador, una vez que llega al final de cada nivel
func _on_exit_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		level += 1
		# Si llega al nivel 3, finaliza el juego
		if level > 3:
			level = 1
		else:
			call_deferred("_load_level", level)

# Función que muestra la pantalla de victoria
func _trigger_victory() -> void:
	_stop_background_music()
	if victory_sound:
		victory_sound.play()
	var player := current_level_root.get_node_or_null("Objects/AstronautPlayer")
	if player:
		player.process_mode = Node.PROCESS_MODE_DISABLED
	await hud.fade(1.0, 0.8)
	hud.show_victory()

# Función que permite cargar el nivel actual o siguiente
func _load_level(level_number: int) -> void:
	if current_level_root:
		current_level_root.queue_free()
		
	# Busca la carpeta de los niveles
	var level_path := "res://scenes/levels/level_%s.tscn" % level_number
	current_level_root = load(level_path).instantiate()
	add_child(current_level_root)
	current_level_root.name = "LevelRoot"

	await get_tree().process_frame
	# Muestra el título de cada nivel
	hud.show_level_title(level_number)
	_play_background_music()
	_setup_level(current_level_root)
	hud.update_kills(_kill_count)
	hud.update_minerals(AstronautPlayerStats.mineral_count)

# Configura el nivel, una vez cargado
func _setup_level(level_root: Node) -> void:
	# Si el personaje está en el area2d del final del juego, pasa al siguiente nivel
	var exit := level_root.get_node_or_null("Exit")
	if exit:
		exit.body_entered.connect(_on_exit_body_entered)
		
	# Busca el personaje para instanciarlo
	var player := level_root.get_node_or_null("Objects/AstronautPlayer")
	if player:
		if not player.died.is_connected(_on_player_died):
			player.died.connect(_on_player_died)
		if not player.health_changed.is_connected(hud._update_health):
			player.health_changed.connect(hud._update_health)
	else:
		print("ERROR CRÍTICO: Main no encontró al AstronautPlayer.")
	
	# ── Conexión del robot NPC ──────────────────────────────────────────────
	for robot in get_tree().get_nodes_in_group("npc"):
		if not robot.victory_triggered.is_connected(_trigger_victory):
			robot.victory_triggered.connect(_trigger_victory)
	# ───────────────────────────────────────────────────────────────────────
	
	await get_tree().process_frame
	for slime in get_tree().get_nodes_in_group("enemies"):
		if not slime.died.is_connected(_on_slime_died):
			slime.died.connect(_on_slime_died)

# Actualiza el conteo de muertes de enemigos
func _on_slime_died() -> void:
	_kill_count += 1
	hud.update_kills(_kill_count)

# Muestra el hud cuando el jugador muere
func _on_player_died() -> void:
	_stop_background_music()
	hud.fade(1.0, 0.5)
	await get_tree().create_timer(0.8).timeout
	hud.show_game_over()


func _play_background_music() -> void:
	if background_music:
		background_music.play()


func _stop_background_music() -> void:
	if background_music and background_music.playing:
		background_music.stop()

func _on_restart_requested() -> void:
	hud.hide_game_over()
	# Si el jugador presiona "Jugar de nuevo", detenemos la fanfarria de victoria
	if victory_sound and victory_sound.playing:
		victory_sound.stop()
	# Reinicia los stats del jugador
	AstronautPlayerStats.reset()
	hud._update_health(AstronautPlayerStats.health)
	hud.update_minerals(0)
	# Vuelve a empezar en el nivel 1
	_kill_count = 0
	level = 1
	_load_level(1)
	await hud.fade(0.0)


func _on_quit_requested() -> void:
	get_tree().quit()
