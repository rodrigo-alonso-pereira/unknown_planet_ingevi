extends CanvasLayer

signal restart_requested
signal quit_requested

const HEART_SIZE: int = 20

const HEART_FULL = preload("res://art/UI/Heart_full.png")
const HEART_HALF = preload("res://art/UI/Heart_half.png")
const HEART_EMPTY = preload("res://art/UI/Heart_empty.png")

@onready var game_over_menu: Control = $GameOverMenu
@onready var restart_button: Button = $GameOverMenu/VBoxContainer/RestartButton
@onready var quit_button: Button = $GameOverMenu/VBoxContainer/QuitButton
@onready var game_over_sound: AudioStreamPlayer = $GameOverSound



@onready var hearts_container: HBoxContainer = $Hearts
@onready var fade_overlay: ColorRect = $FadeOverlay

func _ready() -> void:
	# Aseguramos que el menú inicie oculto
	game_over_menu.hide()
	
	# Conectamos el clic de los botones a nuestras señales personalizadas
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func fade(to_alpha: float, duration: float = 1.5) -> void:
	var tween:= create_tween()
	tween.tween_property(fade_overlay, "modulate:a", to_alpha, duration)
	await tween.finished

func _update_health(new_health: int) -> void:
	print("El HUD está redibujando los corazones para vida: ", new_health)
	
	var hearts = hearts_container.get_children()
	var full_hearts = int(new_health / HEART_SIZE)
	var has_half_heart = (new_health % HEART_SIZE) > 0
	
	# Recorremos cada corazón de izquierda a derecha de forma lineal
	for i in range(hearts.size()):
		if i < full_hearts:
			# Si el índice es menor a los corazones llenos, lo llenamos
			hearts[i].texture = HEART_FULL
		elif i == full_hearts and has_half_heart:
			# Si estamos exactamente en el corazón que sigue, y hay un resto, lo partimos
			hearts[i].texture = HEART_HALF
		else:
			# Todo lo demás a la derecha se apaga
			hearts[i].texture = HEART_EMPTY

# --- Funciones del Game Over ---
func show_game_over() -> void:
	# Asegura opacidad instantánea del negro absoluto de fondo antes de revelar letras
	fade_overlay.modulate.a = 1.0
	# Hacemos el menú completamente transparente (Alpha = 0) ANTES de mostrarlo
	game_over_menu.modulate.a = 0.0
	game_over_menu.show()
	
	# Nos aseguramos de que el jugador pueda usar el ratón para hacer clic
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Reproducimos el acorde dramático de muerte
	if game_over_sound:
		game_over_sound.play()
	# Creamos el Tween para el efecto de aparición suave
	var tween = create_tween()
	# Transicionamos el canal Alpha hacia 1.0 tomando 1.5 segundos. 
	# TRANS_SINE hace que la curva de aparición sea suave y orgánica.
	tween.tween_property(game_over_menu, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	

func hide_game_over() -> void:
	game_over_menu.hide()
	# Detiene el sonido si el jugador reinicia muy rápido
	if game_over_sound.playing:
		game_over_sound.stop()

func _on_restart_pressed() -> void:
	restart_requested.emit()

func _on_quit_pressed() -> void:
	quit_requested.emit()
