extends Node

## Ventisca intensa para el nivel 3.
## Cubre la pantalla completa desde el primer frame (preprocess).
## Partículas en forma de líneas diagonales tipo tormenta de nieve 2D.
## También aplica efecto de deslizamiento al jugador solo en este nivel.

const AMOUNT: int = 2000
const LIFETIME: float = 3
const VELOCITY_MIN: float = 600.0
const VELOCITY_MAX: float = 700.0
const FRICTION_HIELO: float = 100.0   # Normal es 1000 → con 80 el jugador se desliza mucho

var _canvas_layer: CanvasLayer
var _particles: GPUParticles2D
var _player: CharacterBody2D = null


func _ready() -> void:
	_setup_canvas_layer()
	_setup_particles()
	# Esperamos 1 frame para que el jugador esté en el árbol
	await get_tree().process_frame
	_apply_ice_friction()


# ─── Ventisca ────────────────────────────────────────────────────────────────

func _setup_canvas_layer() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 0
	add_child(_canvas_layer)


func _setup_particles() -> void:
	_particles = GPUParticles2D.new()
	_particles.name = "BlizzardParticles"
	_particles.amount = AMOUNT
	_particles.lifetime = LIFETIME
	_particles.emitting = true
	_particles.local_coords = false
	# Llena la pantalla desde el primer frame (simula LIFETIME segundos antes de mostrar)
	_particles.preprocess = LIFETIME
	_particles.position = Vector2(640, 360)  # Centro de la pantalla 1280×720

	var mat := ParticleProcessMaterial.new()

	# Viento diagonal fuerte: izquierda→derecha con caída
	mat.direction = Vector3(1.0, 0.45, 0.0)
	mat.spread = 8.0           # Poco spread → todas las líneas van casi en la misma diagonal
	mat.flatness = 1.0

	mat.initial_velocity_min = VELOCITY_MIN
	mat.initial_velocity_max = VELOCITY_MAX

	mat.gravity = Vector3(0.0, 40.0, 0.0)

	# Rotación fija para que las líneas apunten en diagonal (≈25°)
	mat.angle_min = 25.0
	mat.angle_max = 25.0
	mat.angular_velocity_min = 0.0
	mat.angular_velocity_max = 0.0

	# Líneas de distintos largos
	mat.scale_min = 3
	mat.scale_max = 60

	# Blanco con algo de transparencia
	mat.color = Color(1, 1, 1, 0.4)

	# Emisión: caja grande que cubre más que la pantalla para que no se vean bordes
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(1500.0, 900.0, 0.0)

	_particles.process_material = mat
	_particles.texture = _create_line_texture()

	_canvas_layer.add_child(_particles)


func _create_line_texture() -> ImageTexture:
	## Línea blanca vertical de 2×16 px con bordes desvanecidos.
	## La rotación de 25° en el material la convierte en diagonal.
	var w := 16
	var h := 2
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)

	for y in range(h):
		# Desvanece los 3 primeros y últimos píxeles
		var alpha := 1.0
		if y < 3:
			alpha = float(y) / 3.0
		elif y > h - 4:
			alpha = float(h - 1 - y) / 3.0
		for x in range(w):
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))

	return ImageTexture.create_from_image(img)


# ─── Deslizamiento del jugador ────────────────────────────────────────────────

func _apply_ice_friction() -> void:
	## Busca al jugador y baja su fricción solo mientras está en este nivel.
	_player = get_tree().get_first_node_in_group("player")
	if _player and "friction" in _player:
		_player.set("friction", FRICTION_HIELO)
		print("Blizzard: fricción del jugador → ", FRICTION_HIELO)
	else:
		print("Blizzard: jugador no encontrado o sin propiedad 'friction'")


func _notification(what: int) -> void:
	## Restaura la fricción original cuando el nivel se descarga.
	if what == NOTIFICATION_EXIT_TREE:
		if _player and is_instance_valid(_player) and "friction" in _player:
			_player.set("friction", 1000.0)
			print("Blizzard: fricción restaurada → 1000")
