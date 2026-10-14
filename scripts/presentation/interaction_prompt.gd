class_name InteractionPrompt
extends Node2D
## Small floating cue shown above an interactable when it is the current
## interaction target. Complements the HUD's action text.

const BUBBLE := Color("#fff3d6")
const BUBBLE_EDGE := Color("#241d30")
const DOT := Color("#241d30")

var _time := 0.0
var _base_y := 0.0


func _ready() -> void:
	_base_y = position.y
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	position.y = _base_y + sin(_time * 3.0) * 2.0
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(0.0, 1.0), 8.0, BUBBLE_EDGE)
	draw_circle(Vector2.ZERO, 8.0, BUBBLE)
	draw_circle(Vector2(-3.0, 0.0), 1.4, DOT)
	draw_circle(Vector2(0.0, 0.0), 1.4, DOT)
	draw_circle(Vector2(3.0, 0.0), 1.4, DOT)
