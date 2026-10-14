class_name PicnicBackground
extends Node2D
## Momo's picnic garden. `set_iteration` shifts the palette and grows the place
## settings each loop — a quiet, escalating inconsistency.

const SKY := Color("#f7dcc2")
const SKY_LATE := Color("#e6c2b4")
const GRASS := Color("#a9d99f")
const GRASS_LATE := Color("#93b98f")
const BLANKET := Color("#e9b7c4")
const BLANKET_LATE := Color("#c9a2ae")
const PLATE := Color("#f6efe2")
const WOOD := Color("#9d7a52")

var _iteration := 0


func _ready() -> void:
	z_index = -10


func set_iteration(iteration: int) -> void:
	_iteration = maxi(0, iteration)
	queue_redraw()


func _draw() -> void:
	_draw_sky()
	_draw_ground()
	_draw_blanket()
	_draw_places()
	_draw_flowers()
	_draw_light()


func _draw_sky() -> void:
	var t := clampf(float(_iteration) / 6.0, 0.0, 1.0)
	draw_rect(Rect2(0.0, 0.0, 640.0, 220.0), SKY.lerp(SKY_LATE, t))


func _draw_ground() -> void:
	var t := clampf(float(_iteration) / 6.0, 0.0, 1.0)
	draw_rect(Rect2(0.0, 200.0, 640.0, 160.0), GRASS.lerp(GRASS_LATE, t))


func _draw_blanket() -> void:
	var t := clampf(float(_iteration) / 6.0, 0.0, 1.0)
	var blanket := BLANKET.lerp(BLANKET_LATE, t)
	_ellipse(Vector2(320.0, 258.0), 150.0, 60.0, blanket.darkened(0.15))
	_ellipse(Vector2(320.0, 254.0), 146.0, 56.0, blanket)
	for x in range(190, 460, 26):
		draw_line(Vector2(float(x), 210.0), Vector2(float(x) - 8.0, 300.0), blanket.darkened(0.1), 2.0)


func _draw_places() -> void:
	# One extra place setting appears every iteration.
	var places := 2 + _iteration
	if places > 8:
		places = 8
	for i in range(places):
		var t := float(i) / float(maxi(1, places - 1))
		var x := lerpf(250.0, 390.0, t)
		var y := 262.0 + sin(t * PI) * -10.0
		draw_circle(Vector2(x, y), 13.0, PLATE.darkened(0.12))
		draw_circle(Vector2(x, y), 10.0, PLATE)
		draw_circle(Vector2(x, y), 4.0, Color("#e0938a"))
	# Single central tea set.
	draw_circle(Vector2(320.0, 236.0), 8.0, Color("#cfe0e6"))
	draw_rect(Rect2(312.0, 232.0, 16.0, 8.0), Color("#cfe0e6").darkened(0.15))


func _draw_flowers() -> void:
	for spec in [Vector2(120.0, 210.0), Vector2(540.0, 214.0), Vector2(180.0, 300.0), Vector2(470.0, 296.0)]:
		draw_line(spec, spec + Vector2(0.0, -18.0), Color("#6ba85f"), 2.0)
		draw_circle(spec + Vector2(0.0, -20.0), 5.0, Color("#ffd166"))
		draw_circle(spec + Vector2(-6.0, -14.0), 4.0, Color("#ff9bb0"))


func _draw_light() -> void:
	var t := clampf(float(_iteration) / 6.0, 0.0, 1.0)
	for i in range(5):
		draw_circle(Vector2(500.0, 60.0), 50.0 + float(i) * 24.0, Color(1.0, 0.92, 0.7, 0.03))
	draw_rect(Rect2(0.0, 0.0, 640.0, 360.0), Color(1.0, 0.85, 0.6, 0.03 + 0.04 * t))


func _ellipse(center: Vector2, rx: float, ry: float, color: Color, segments := 26) -> void:
	var points := PackedVector2Array()
	for i in range(segments):
		var a := TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(points, color)
