class_name HollowBackground
extends Node2D
## The Hollow beneath the village: dark soil, wandering roots, a pale tree, and
## drifting motes. Darkens as the returning-tree loop advances.
## Placeholder-but-intentional presentation; no collision.

const VIEW := Vector2(640.0, 360.0)

const ROCK := Color("#332c40")
const ROCK_DARK := Color("#211b2b")
const ROOT := Color("#6b5a45")
const ROOT_DARK := Color("#4a3d2e")
const TRUNK := Color("#8a7a68")
const LEAF_A := Color("#b6d3a8")
const LEAF_B := Color("#93b487")
const GLOW := Color("#cfe6a8")

var _iteration := 0
var _time := 0.0


func _ready() -> void:
	z_index = -10
	set_process(true)


func set_iteration(count: int) -> void:
	_iteration = count
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var dark := clampf(float(_iteration) / 6.0, 0.0, 0.85)
	draw_rect(Rect2(Vector2.ZERO, VIEW), ROCK.lerp(ROCK_DARK, dark))
	_draw_roots(dark)
	_draw_tree(dark)
	_draw_motes(dark)
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.05, 0.03, 0.09, 0.2 + dark * 0.25))


func _draw_roots(dark: float) -> void:
	var root_color := ROOT.lerp(ROCK_DARK, dark * 0.5)
	for base in [Vector2(70.0, 306.0), Vector2(210.0, 322.0), Vector2(390.0, 318.0), Vector2(560.0, 300.0)]:
		var points := PackedVector2Array()
		for i in range(7):
			var t := float(i) / 6.0
			points.append(base + Vector2(t * 70.0 - 35.0, -absf(sin(t * 3.0)) * 30.0 - t * 44.0))
		draw_polyline(points, root_color, 7.0, true)
	for x in range(0, 680, 40):
		draw_line(Vector2(float(x), 304.0), Vector2(float(x) - 18.0, 360.0), ROOT, 2.0)


func _draw_tree(dark: float) -> void:
	var base := Vector2(430.0, 300.0)
	var fringe := dark * 0.45
	draw_line(base, base + Vector2(0.0, -96.0), TRUNK.darkened(fringe * 0.5), 14.0, true)
	draw_line(base + Vector2(0.0, -56.0), base + Vector2(-30.0, -84.0), TRUNK.darkened(fringe * 0.5), 8.0, true)
	draw_line(base + Vector2(0.0, -64.0), base + Vector2(30.0, -92.0), TRUNK.darkened(fringe * 0.5), 8.0, true)
	for offset in [Vector2(-34.0, -98.0), Vector2(34.0, -104.0), Vector2(0.0, -128.0), Vector2(6.0, -92.0)]:
		draw_circle(base + offset, 34.0, LEAF_B.darkened(fringe))
		draw_circle(base + offset + Vector2(-6.0, -5.0), 22.0, LEAF_A.darkened(fringe))
	draw_circle(base + Vector2(4.0, -118.0), 5.0, GLOW)


func _draw_motes(dark: float) -> void:
	for i in range(10):
		var t := fmod(_time * 0.16 + float(i) * 0.13, 1.0)
		var x := fmod(float(i) * 67.0 + sin(_time * 0.5 + float(i)) * 12.0, VIEW.x)
		var y := lerpf(VIEW.y, 40.0, t)
		draw_circle(Vector2(x, y), 1.6, Color(GLOW.r, GLOW.g, GLOW.b, 0.25 * (1.0 - dark)))
