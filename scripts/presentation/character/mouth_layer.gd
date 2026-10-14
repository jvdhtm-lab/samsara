class_name MouthLayer
extends CharacterLayer
## Mouth. Uses `rig.mouth_shape` for expression and `rig.mouth_open` for talk.
##
## A data flag (`uneven_smile`) lets a character keep a subtly wrong resting
## smile without any per-character branching in this script's logic.

func _draw() -> void:
	if data == null:
		return
	var r := data.body_radius
	var color := data.shade_color.darkened(0.15)
	var width := maxf(1.4, r * 0.07)

	var shape := rig.mouth_shape
	if rig.mouth_open > 0.05:
		_ellipse(Vector2(0.0, r * 0.34), r * 0.20, r * (0.10 + 0.16 * rig.mouth_open), color)
		return

	if data.uneven_smile and (shape == &"neutral" or shape == &"uneven"):
		draw_arc(Vector2(-r * 0.10, r * 0.34), r * 0.24, 0.15, PI - 0.55, 12, color, width, true)
		return

	match shape:
		&"smile":
			draw_arc(Vector2(0.0, r * 0.32), r * 0.20, 0.35, PI - 0.35, 12, color, width, true)
		&"frown":
			draw_arc(Vector2(0.0, r * 0.48), r * 0.20, PI + 0.35, TAU - 0.35, 12, color, width, true)
		&"small":
			_ellipse(Vector2(0.0, r * 0.36), r * 0.10, r * 0.05, color)
		&"o":
			_ellipse(Vector2(0.0, r * 0.36), r * 0.13, r * 0.16, color)
		_:
			draw_arc(Vector2(0.0, r * 0.34), r * 0.18, 0.35, PI - 0.35, 12, color, width, true)
