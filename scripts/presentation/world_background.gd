class_name WorldBackground
extends Node2D
## Paints the floating-village diorama: soft pastel sky, oversized plants,
## crooked houses, and warm light. Placeholder-but-intentional presentation.
##
## Presentation layer. No collision; gameplay walls are built separately.

const VIEW := Vector2(640.0, 360.0)

const SKY_TOP := Color("#fbe4c9")
const SKY_BOTTOM := Color("#f6c1a4")
const GRASS := Color("#a9d99f")
const GRASS_DARK := Color("#83bd7d")
const SOIL := Color("#caa76c")
const SOIL_DARK := Color("#a5824f")
const PATH := Color("#efd9ab")
const CLOUD := Color("#fff7ec")
const LEAF := Color("#8fd07a")
const LEAF_DARK := Color("#6ba85f")

var _top: PackedVector2Array
var _bottom: PackedVector2Array


func _ready() -> void:
	z_index = -10
	_build_ground_curve()


func _build_ground_curve() -> void:
	_top = PackedVector2Array()
	_bottom = PackedVector2Array()
	var segments := 40
	for i in range(segments + 1):
		var x := lerpf(6.0, 634.0, float(i) / float(segments))
		var y := 252.0 + sin(x * 0.021) * 6.0 - sin(x * 0.011 + 1.3) * 5.0
		_top.append(Vector2(x, y))
		_bottom.append(Vector2(x, y + 26.0))


func _draw() -> void:
	_draw_sky()
	_draw_distant_islands()
	_draw_clouds()
	_draw_ground()
	_draw_path()
	_draw_plants()
	_draw_tree()
	_draw_houses()
	_draw_warm_light()


func _draw_sky() -> void:
	var bands := 26
	for i in range(bands):
		var t := float(i) / float(bands - 1)
		draw_rect(Rect2(0.0, VIEW.y * t, VIEW.x, VIEW.y / float(bands) + 1.0), SKY_TOP.lerp(SKY_BOTTOM, t))


func _draw_distant_islands() -> void:
	for spec in [Vector2(118.0, 118.0), Vector2(548.0, 148.0), Vector2(430.0, 88.0)]:
		_ellipse(spec + Vector2(0.0, 12.0), 44.0, 20.0, SOIL_DARK)
		_ellipse(spec, 46.0, 13.0, GRASS_DARK)
		_ellipse(spec + Vector2(-10.0, -4.0), 10.0, 6.0, LEAF)


func _draw_clouds() -> void:
	for spec in [Vector2(150.0, 70.0), Vector2(470.0, 60.0), Vector2(600.0, 120.0)]:
		for offset in [Vector2(-28.0, 6.0), Vector2(0.0, 0.0), Vector2(28.0, 7.0), Vector2(4.0, 12.0)]:
			draw_circle(spec + offset, 18.0, CLOUD)


func _draw_ground() -> void:
	var segments := _top.size() - 1
	for i in range(segments):
		var a := _top[i]
		var b := _top[i + 1]
		var ba := _bottom[i]
		var bb := _bottom[i + 1]
		# Soil
		draw_colored_polygon(PackedVector2Array([ba, bb, Vector2(bb.x, VIEW.y), Vector2(ba.x, VIEW.y)]), SOIL)
		# Grass cap
		draw_colored_polygon(PackedVector2Array([a, b, bb, ba]), GRASS)
		# Grass rim
		draw_colored_polygon(PackedVector2Array([a, b, Vector2(b.x, b.y + 5.0), Vector2(a.x, a.y + 5.0)]), GRASS_DARK)


func _draw_path() -> void:
	var steps := 12
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var y := lerpf(VIEW.y + 6.0, 258.0, t)
		var x := 320.0 + sin(t * 3.1) * 42.0 * (1.0 - t)
		var w := lerpf(96.0, 26.0, t)
		left.append(Vector2(x - w, y))
		right.append(Vector2(x + w, y))
	for i in range(steps):
		draw_colored_polygon(PackedVector2Array([left[i], right[i], right[i + 1], left[i + 1]]), PATH)
	_ellipse(Vector2(320.0, 250.0), 74.0, 22.0, PATH)


func _draw_plants() -> void:
	_plant(Vector2(72.0, 262.0), 1.15)
	_plant(Vector2(566.0, 260.0), 1.0)
	_plant(Vector2(232.0, 256.0), 0.7)


func _plant(base: Vector2, scale: float) -> void:
	draw_line(base, base + Vector2(0.0, -58.0 * scale), Color("#6ba85f"), 5.0 * scale, true)
	for i in range(4):
		var angle := -PI * 0.5 + (float(i) - 1.5) * 0.5
		var tip := base + Vector2(cos(angle), sin(angle)) * (44.0 * scale)
		_ellipse(tip, 20.0 * scale, 9.0 * scale, LEAF, 20, angle)
	draw_circle(base + Vector2(0.0, -60.0 * scale), 6.0 * scale, Color("#ffd166"))
	draw_circle(base + Vector2(-12.0 * scale, -46.0 * scale), 5.0 * scale, Color("#ff8fa3"))


func _draw_tree() -> void:
	var base := Vector2(150.0, 258.0)
	draw_line(base, base + Vector2(6.0, -70.0), Color("#9d7a52"), 9.0, true)
	draw_line(base + Vector2(4.0, -50.0), base + Vector2(-16.0, -74.0), Color("#9d7a52"), 6.0, true)
	draw_line(base + Vector2(5.0, -56.0), base + Vector2(24.0, -80.0), Color("#9d7a52"), 6.0, true)
	var canopy := Color("#b6a3d6")
	for offset in [Vector2(-18.0, -80.0), Vector2(18.0, -86.0), Vector2(0.0, -102.0), Vector2(-4.0, -74.0)]:
		draw_circle(base + offset, 30.0, canopy)
		draw_circle(base + offset + Vector2(-6.0, -4.0), 18.0, canopy.lightened(0.12))
	draw_circle(base + Vector2(6.0, -92.0), 4.0, Color("#ffe9a8"))


func _draw_houses() -> void:
	_house(Vector2(470.0, 246.0), Vector2(88.0, 62.0), Color("#f2b8a0"), Color("#d98c6a"), 0.05, Color("#ffe9a8"))
	_house(Vector2(360.0, 210.0), Vector2(66.0, 52.0), Color("#bcdce8"), Color("#a894c8"), -0.06, Color("#fff3c4"))


func _house(center: Vector2, size: Vector2, wall: Color, roof: Color, angle: float, window: Color) -> void:
	var half := size * 0.5
	var corners := PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	var outline := PackedVector2Array()
	var body := PackedVector2Array()
	for c in corners:
		var p := center + c.rotated(angle)
		body.append(p)
		outline.append(center + (c * 1.0 + Vector2(sign(c.x), sign(c.y)) * 1.5).rotated(angle))
	draw_colored_polygon(outline, wall.darkened(0.25))
	draw_colored_polygon(body, wall)

	var roof_apex := center + Vector2(0.0, -half.y - 26.0).rotated(angle)
	var roof_left := center + Vector2(-half.x - 8.0, -half.y).rotated(angle)
	var roof_right := center + Vector2(half.x + 8.0, -half.y).rotated(angle)
	draw_colored_polygon(PackedVector2Array([roof_left, roof_apex, roof_right]), roof)

	_ellipse(center + Vector2(-10.0, 4.0).rotated(angle), 11.0, 11.0, window)
	_ellipse(center + Vector2(16.0, 4.0).rotated(angle), 8.0, 11.0, window.darkened(0.1))


func _draw_warm_light() -> void:
	for i in range(6):
		var radius := 60.0 + float(i) * 26.0
		draw_circle(Vector2(505.0, 74.0), radius, Color(1.0, 0.92, 0.7, 0.03))
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(1.0, 0.85, 0.65, 0.05))


func _ellipse(center: Vector2, rx: float, ry: float, color: Color, segments := 26, angle := 0.0) -> void:
	var points := PackedVector2Array()
	for i in range(segments):
		var t := TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(t) * rx, sin(t) * ry).rotated(angle))
	draw_colored_polygon(points, color)
