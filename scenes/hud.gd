extends CanvasLayer

signal restart_requested
signal quit_requested

const HEART_SIZE: int = 20
const HEART_FULL  = preload("res://art/UI/Heart_full.png")
const HEART_HALF  = preload("res://art/UI/Heart_half.png")
const HEART_EMPTY = preload("res://art/UI/Heart_empty.png")
const SKULL_ICON  = preload("res://art/UI/Skull_full.png")

@onready var game_over_menu: Control  = $GameOverMenu
@onready var restart_button: Button   = $GameOverMenu/VBoxContainer/RestartButton
@onready var quit_button: Button      = $GameOverMenu/VBoxContainer/QuitButton
@onready var game_over_sound: AudioStreamPlayer = $GameOverSound
@onready var hearts_container         = $Hearts
@onready var fade_overlay: ColorRect  = $FadeOverlay

@onready var skull_icon: TextureRect = $KillCounter/SkullIcon
@onready var kill_count_label: Label = $KillCounter/KillCountLabel
@onready var level_title: Label = $LevelTitle

@onready var victory_panel: Control = $VictoryPanel
@onready var victory_restart: Button = $VictoryPanel/VBoxContainer/VictoryRestartButton
@onready var victory_quit: Button = $VictoryPanel/VBoxContainer/VictoryQuitButton

var _prev_health: int = 100


func _ready() -> void:
	game_over_menu.hide()
	level_title.hide()
	victory_panel.hide()
	# Conexiones de Game Over
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Conexiones de Victoria
	victory_restart.pressed.connect(_on_restart_pressed)
	victory_quit.pressed.connect(_on_quit_pressed)

# ── Kill counter ──────────────────────────────────────────────────────────────

func update_kills(count: int) -> void:
	kill_count_label.text = " %d" % count
	var tween := create_tween()
	tween.tween_property(skull_icon, "scale", Vector2(1.4, 1.4), 0.08)
	tween.tween_property(skull_icon, "scale", Vector2(1.0, 1.0), 0.12)


# ── Intro de nivel ────────────────────────────────────────────────────────────

func show_level_title(level: int) -> void:
	var titles := {
		1: "Nivel 1: El Planeta Desconocido\nExplora la superficie y encuentra la salida",
		2: "Nivel 2: Las Catacumbas\nCuidado… aquí no se ve nada",
		3: "Nivel 3: La Tormenta de Hielo\nEl suelo resbala. Los slimes no",
	}
	level_title.text = titles.get(level, "Nivel %d" % level)
	level_title.modulate.a = 1.0
	level_title.show()
	
	var tween := create_tween()
	tween.tween_interval(5.0)
	tween.tween_property(level_title, "modulate:a", 0.0, 0.5)
	tween.tween_callback(level_title.hide)


# ── Pantalla de victoria ──────────────────────────────────────────────────────

func show_victory() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	victory_panel.modulate.a = 0.0
	victory_panel.show()
	var tween := create_tween()
	tween.tween_property(victory_panel, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)


# ── Vida y corazones ──────────────────────────────────────────────────────────

func _update_health(new_health: int) -> void:
	var hearts := hearts_container.get_children()
	var full_hearts := int(new_health / HEART_SIZE)
	var has_half_heart := (new_health % HEART_SIZE) > 0

	for i in range(hearts.size()):
		# Calcula la cantidad de imagenes por corazon lleno, corazon medio y corazon vacio
		# para mostrar en el hud cuando se actualiza la vida del personaje
		if i < full_hearts:
			hearts[i].texture = HEART_FULL
		elif i == full_hearts and has_half_heart:
			hearts[i].texture = HEART_HALF
		else:
			hearts[i].texture = HEART_EMPTY
	# Actualiza la vida del personaje cuando recibe daño
	if new_health < _prev_health:
		for heart in hearts_container.get_children():
			var tween := create_tween()
			tween.tween_property(heart, "scale", Vector2(1.3, 1.3), 0.08)
			tween.tween_property(heart, "scale", Vector2(1.0, 1.0), 0.12)
	_prev_health = new_health


# ── Fade ──────────────────────────────────────────────────────────────────────

func fade(to_alpha: float, duration: float = 1.5) -> void:
	var tween := create_tween()
	tween.tween_property(fade_overlay, "modulate:a", to_alpha, duration)
	await tween.finished


# ── Game Over ─────────────────────────────────────────────────────────────────

func show_game_over() -> void:
	fade_overlay.modulate.a = 1.0
	game_over_menu.modulate.a = 0.0
	game_over_menu.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# Reproduce sonido dramático de muerte
	if game_over_sound:
		game_over_sound.play()
	var tween := create_tween()
	tween.tween_property(game_over_menu, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)

func hide_game_over() -> void:
	game_over_menu.hide()
	if game_over_sound.playing:
		game_over_sound.stop()


# ── Botones ───────────────────────────────────────────────────────────────────

func _on_restart_pressed() -> void:
	victory_panel.hide()
	restart_requested.emit()

func _on_quit_pressed() -> void:
	quit_requested.emit()
