extends Control

## Triangulo dibujado a mano que conecta la esquina del panel de dialogo
## con la posicion en pantalla del robot, simulando la "colita" de un
## globo de comic. hud.gd actualiza `points` cada frame.

var points: PackedVector2Array = PackedVector2Array()

@export var fill_color: Color = Color(0.08627451, 0.078431375, 0.14117648, 0.95)
@export var border_color: Color = Color(0.9843137, 0.7490196, 0.14117648, 1)
@export var border_width: float = 3.0


func set_tail_points(new_points: PackedVector2Array) -> void:
	points = new_points
	queue_redraw()


func _draw() -> void:
	if points.size() < 3:
		return
	# Relleno del triangulo, mismo color que el fondo de la vineta
	draw_colored_polygon(points, fill_color)
	# Borde dorado, para que combine con el borde del panel
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, border_color, border_width, true)
