extends CanvasLayer

const HEART_SIZE: int = 20

const HEART_FULL = preload("res://art/UI/Heart_full.png")
const HEART_HALF = preload("res://art/UI/Heart_half.png")
const HEART_EMPTY = preload("res://art/UI/Heart_empty.png")

@onready var hearts_container: HBoxContainer = $Hearts
@onready var fade_overlay: ColorRect = $FadeOverlay


func fade(to_alpha: float) -> void:
	var tween:= create_tween()
	tween.tween_property(fade_overlay, "modulate:a", to_alpha, 1.5)
	await tween.finished

func _ready() -> void:
	_update_health(50)

func _update_health(new_health: int) -> void:
	var hearts = hearts_container.get_children()
	var max_hearts = len(hearts)
	var full = int(new_health / HEART_SIZE)
	var half = 1 if (new_health % HEART_SIZE) > 0 else 0
	var empty = max_hearts - (full + half)
	
	# Actualiza los corazones completos
	for i in full:
		hearts[i].texture = HEART_FULL
	# Actualiza los corazones a la mitad
	if half:
		hearts[full].texture = HEART_HALF
	# Actualiza los corazones vacios
	for i in empty:
		hearts[len(hearts) - 1 - i].texture = HEART_EMPTY
