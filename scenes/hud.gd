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
@onready var mineral_count_label: Label = $"Mineral Counter/MineralCountLabel"
@onready var level_title: Label = $LevelTitle

@onready var victory_panel: Control = $VictoryPanel
@onready var victory_restart: Button = $VictoryPanel/VBoxContainer/VictoryRestartButton
@onready var victory_quit: Button = $VictoryPanel/VBoxContainer/VictoryQuitButton

@onready var tutorial_box: PanelContainer = $TutorialBox
@onready var tutorial_label: Label = $TutorialBox/TutorialMargin/TutorialLabel
@onready var robot_dialog: PanelContainer = $RobotDialog
@onready var dialog_tail: Control = $RobotDialogTail
@onready var dialog_label: Label = $RobotDialog/MarginContainer/VBoxContainer/DialogLabel

var _prev_health: int = 100
var _dialog_target: Node2D = null
var _dialog_timer: SceneTreeTimer = null

## Separacion entre la esquina inferior-derecha del panel y el punto de
## anclaje del robot. Mas negativo en X = panel mas a la izquierda.
## Mas negativo en Y = panel mas arriba.
@export var dialog_offset: Vector2 = Vector2(-60, -90)

## Punto (relativo a la posicion del robot) al que apunta la PUNTA de la
## colita. Se calcula por separado del offset del panel para poder apuntar
## un poco arriba del robot (por ej. su cabeza) sin que la colita quede
## clavada en el centro del sprite.
@export var tail_tip_offset: Vector2 = Vector2(-6, -30)

const DIALOG_OFFSET := Vector2(-20, -20)  # separacion entre la esquina del robot y la vineta

func _process(_delta: float) -> void:
	if robot_dialog.visible and is_instance_valid(_dialog_target):
		_update_dialog_position()


func _ready() -> void:
	game_over_menu.hide()
	level_title.hide()
	victory_panel.hide()
	tutorial_box.hide()
	robot_dialog.hide()
	dialog_tail.hide()
	# Conexiones de Game Over
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Conexiones de Victoria
	victory_restart.pressed.connect(_on_restart_pressed)
	victory_quit.pressed.connect(_on_quit_pressed)

# ── Kill counter ──────────────────────────────────────────────────────────────

func update_kills(count: int) -> void:
	kill_count_label.text = "%d" % count
	var tween := create_tween()
	tween.tween_property(skull_icon, "scale", Vector2(1.4, 1.4), 0.08)
	tween.tween_property(skull_icon, "scale", Vector2(1.0, 1.0), 0.12)

# ── Mineral counter ──────────────────────────────────────────────────────────────

func update_minerals(count: int) -> void:
	mineral_count_label.text = "%d" % count

# ── Tutorial ──────────────────────────────────────────────────────────────────

func show_tutorial() -> void:
	# Espera 3 segundos antes de mostrar el primer mensaje
	await get_tree().create_timer(3.0).timeout
 
	# Primer mensaje: movimiento
	tutorial_label.text = "Utiliza WASD para moverte"
	tutorial_box.modulate.a = 0.0
	tutorial_box.show()
	var t1 := create_tween()
	t1.tween_property(tutorial_box, "modulate:a", 1.0, 0.5)
	t1.tween_interval(4.0)
	t1.tween_property(tutorial_box, "modulate:a", 0.0, 0.6)
	await t1.finished
 
	# Segundo mensaje: controles de acción
	tutorial_label.text = "ESPACIO → atacar\nQ → farmear\nE → interactuar con el robot"
	var t2 := create_tween()
	t2.tween_property(tutorial_box, "modulate:a", 1.0, 0.5)
	t2.tween_interval(4.0)
	t2.tween_property(tutorial_box, "modulate:a", 0.0, 0.6)
	t2.tween_callback(tutorial_box.hide)
	
# ── Dialogo del robot ─────────────────────────────────────────────────────────

func show_robot_dialog(text: String, source: Node2D = null) -> void:
	dialog_label.text = text
	_dialog_target = source
	if _dialog_target:
		_update_dialog_position()
	robot_dialog.modulate.a = 0.0
	dialog_tail.modulate.a = 0.0
	robot_dialog.show()
	dialog_tail.show()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(robot_dialog, "modulate:a", 1.0, 0.3)
	tween.tween_property(dialog_tail, "modulate:a", 1.0, 0.3)
	
	if _dialog_timer:
		_dialog_timer.timeout.disconnect(hide_robot_dialog)
	_dialog_timer = get_tree().create_timer(6.0)
	_dialog_timer.timeout.connect(hide_robot_dialog)

func hide_robot_dialog() -> void:
	if not robot_dialog.visible:
		return
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(robot_dialog, "modulate:a", 0.0, 0.3)
	tween.tween_property(dialog_tail, "modulate:a", 0.0, 0.3)
	tween.set_parallel(false)
	tween.tween_callback(robot_dialog.hide)
	tween.tween_callback(dialog_tail.hide)
	tween.tween_callback(func(): _dialog_target = null)

# Proyecta la posicion de mundo del robot a coordenadas de pantalla y
# ubica la vineta para que su esquina inferior-derecha quede pegada a
# la esquina superior-izquierda del robot.
func _update_dialog_position() -> void:
	var screen_pos: Vector2 = get_viewport().canvas_transform * _dialog_target.global_position
	robot_dialog.position = screen_pos + dialog_offset - robot_dialog.size
	_update_dialog_tail(screen_pos + tail_tip_offset)

# Arma el triangulo de la "colita": dos puntos pegados a la esquina del
# panel (quedan tapados por su borde) y la punta apoyada justo en la
# posicion del robot en pantalla.
func _update_dialog_tail(robot_screen_pos: Vector2) -> void:
	var panel_corner: Vector2 = robot_dialog.position + robot_dialog.size
	var inset := 12.0
	dialog_tail.position = panel_corner - Vector2(inset, inset)
	var tip_local: Vector2 = robot_screen_pos - dialog_tail.position
	dialog_tail.set_tail_points(PackedVector2Array([
		Vector2(inset, 0),
		Vector2(0, inset),
		tip_local,
	]))

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
