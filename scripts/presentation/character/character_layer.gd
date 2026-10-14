class_name CharacterLayer
extends Node2D
## Base class for a single visual layer of the character rig.
##
## Presentation layer. A layer draws one part of a robot-creature relative to
## its own origin. The owning `CharacterRig` positions/rotates/scales layers and
## supplies shared animation state (blink, expression, mouth) through `rig`.
##
## Shared vector primitives live here so every layer draws in one visual
## language (soft rounded shapes, consistent edges).

var rig: CharacterRig
var data: CharacterData


func layer_setup(rig_ref: CharacterRig, character: CharacterData) -> void:
	rig = rig_ref
	data = character
	queue_redraw()


func _ellipse(center: Vector2, rx: float, ry: float, color: Color, segments := 28, angle := 0.0) -> void:
	var points := PackedVector2Array()
	for i in range(segments):
		var t := TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(t) * rx, sin(t) * ry).rotated(angle))
	draw_colored_polygon(points, color)


func _pear(center: Vector2, r: float, color: Color) -> void:
	var segments := 32
	var points := PackedVector2Array()
	for i in range(segments):
		var a := TAU * float(i) / float(segments)
		var v := sin(a)
		var width := r * (1.0 - 0.30 * ((v + 1.0) * 0.5))
		points.append(center + Vector2(cos(a) * width, v * r * 1.20))
	draw_colored_polygon(points, color)


func _star_points(center: Vector2, outer: float, inner: float, points: int, rotation: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	var step := PI / float(points)
	var a := -PI * 0.5 + rotation
	for i in range(points * 2):
		var radius := outer if i % 2 == 0 else inner
		result.append(center + Vector2(cos(a), sin(a)) * radius)
		a += step
	return result
