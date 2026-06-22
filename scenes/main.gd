extends Node2D

@onready var hud: CanvasLayer = $HUD

var current_level_root: Node = null
@onready var background_music: AudioStreamPlayer = $BackgroundMusic


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Espera 1 frame para que todos los nodos hijos y grupos se inicialicen
	await get_tree().process_frame
	
	# Conectamos las señales de los botones del HUD
	hud.restart_requested.connect(_on_restart_requested)
	hud.quit_requested.connect(_on_quit_requested)
	
	current_level_root = get_node("SurvivalLevel")
	
	if current_level_root:
		# Conectamos las señales del jugador apenas inicia el juego
		_setup_level(current_level_root)
		# Le inyectamos la vida máxima real al HUD para que dibuje los 5 corazones
		hud._update_health(AstronautPlayerStats.health)
		# Reproduce la música inicial apenas el juego arranca
		_play_background_music()
	else:
		print("CRÍTICO: Main no encontró el nodo SurvivalLevel")

func _load_level() -> void:
	if current_level_root:
		current_level_root.queue_free()
	
	var level_path = "res://scenes/survival_level.tscn"
	current_level_root = load(level_path).instantiate()
	add_child(current_level_root)
	current_level_root.name = "SurvivalLevel"
	# Espera 1 frame para asegurar que el nivel viejo se borró por completo
	await get_tree().process_frame
	# Reproduce la música inicial
	_play_background_music()
	_setup_level(current_level_root)

func _setup_level(level_root: Node) -> void:
	# Buscamos al jugador por su grupo
	var player = level_root.get_node_or_null("Objects/AstronautPlayer")
	if player:
		print("Main: Jugador encontrado -> ", player.name)
		
		# Conectamos validando que no existan conexiones previas
		if not player.died.is_connected(_on_player_died):
			player.died.connect(_on_player_died)
			
		if not player.health_changed.is_connected(hud._update_health):
			player.health_changed.connect(hud._update_health)
			print("Main: Señal health_changed conectada exitosamente al HUD.")
	else:
		print("ERROR CRÍTICO: Main no encontró al AstronautPlayer.")

func _on_player_died() -> void:
	# Detiene la música de fondo de forma abrupta en el momento del colapso
	_stop_background_music()
	# Iniciamos el fundido a negro RÁPIDO (0.5 segundos) en paralelo a la caída del personaje
	hud.fade(1.0, 0.5)
	# Esperamos un breve instante (0.8s aproximados para que el sprite toque el suelo)
	await get_tree().create_timer(0.8).timeout
	# Mostramos el menú
	hud.show_game_over()
	
# --- Gestión de Música de Fondo ---
func _play_background_music() -> void:
	if background_music:
		background_music.play()

func _stop_background_music() -> void:
	if background_music and background_music.playing:
		background_music.stop()

# --- Reacciones a los botones del HUD ---
func _on_restart_requested() -> void:
	# Ocultamos el menú
	hud.hide_game_over()
	
	# Reseteamos vida y corazones
	AstronautPlayerStats.reset()
	hud._update_health(AstronautPlayerStats.health)
	
	# Recargamos el nivel
	_load_level()
	
	# Quitamos el fondo negro
	await hud.fade(0.0)

func _on_quit_requested() -> void:
	print("Cerrando el juego...")
	# Cerramos la ventana del juego por completo
	get_tree().quit()
