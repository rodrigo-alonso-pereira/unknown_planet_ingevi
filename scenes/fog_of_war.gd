extends CanvasLayer

## Niebla de guerra para el nivel 2 (laberinto).
## Todo es negro excepto un círculo de visión alrededor del jugador.

const VISION_RADIUS: float = 180.0  # radio en píxeles de pantalla (~10 tiles)
const EDGE_SOFTNESS: float = 30.0   # suavizado del borde del círculo

var _overlay: ColorRect
var _player: Node2D = null
var _shader_mat: ShaderMaterial

const SHADER_CODE := """
shader_type canvas_item;

uniform vec2 player_screen_pos = vec2(640.0, 360.0);
uniform float radius : hint_range(50.0, 600.0) = 180.0;
uniform float softness : hint_range(0.0, 100.0) = 30.0;
uniform vec2 viewport_size = vec2(1280.0, 720.0);

void fragment() {
	vec2 pixel_pos = UV * viewport_size;
	float dist = length(pixel_pos - player_screen_pos);
	float alpha = smoothstep(radius, radius + softness, dist);
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
"""

func _ready() -> void:
	layer = 0  # Por encima del juego, por debajo del HUD

	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color.BLACK

	var shader := Shader.new()
	shader.code = SHADER_CODE

	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = shader
	_shader_mat.set_shader_parameter("radius", VISION_RADIUS)
	_shader_mat.set_shader_parameter("softness", EDGE_SOFTNESS)

	_overlay.material = _shader_mat
	add_child(_overlay)


func _process(_delta: float) -> void:
	# Busca al jugador la primera vez
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
		return

	# Convierte posición mundial del jugador a coordenadas de pantalla
	var viewport := get_viewport()
	var screen_pos: Vector2 = viewport.get_canvas_transform() * _player.global_position

	_shader_mat.set_shader_parameter("player_screen_pos", screen_pos)
	_shader_mat.set_shader_parameter("viewport_size", Vector2(viewport.size))
