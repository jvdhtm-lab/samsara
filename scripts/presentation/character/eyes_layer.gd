class_name EyesLayer
extends CharacterLayer
## Eyes, highlights, glow, and eyebrows.
##
## Reads `rig.eye_open` (0 = closed, 1 = normal, >1 = wide) blended with the
## blink timer, and `rig.brow_state` for the expression grammar.

func _draw() -> void:
	if data == null:
		return
	var r := data.body_radius
	var eye_r := _eye_radius(r)
	var eye_y := -r * 0.14
	var eye_dx := r * 0.30
	for side in [-1.0, 1.0]:
		var center := Vector2(side * eye_dx, eye_y)
		draw_circle(center, eye_r * 1.9, Color(data.eye_color.r, data.eye_color.g, data.eye_color.b, 0.12))
		var openness := clampf(rig.eye_open, 0.0, 1.6)
		if openness <= 0.05:
			draw_line(center + Vector2(-eye_r, 0.0), center + Vector2(eye_r, 0.0), data.shade_color, maxf(1.5, r * 0.08))
		else:
			_ellipse(center, eye_r * (0.85 + 0.15 * openness), eye_r * openness, data.eye_color)
			if openness > 0.5:
				draw_circle(center + Vector2(-eye_r * 0.32, -eye_r * 0.32), eye_r * 0.34, Color(1, 1, 1, 0.85))
		_draw_brow(side, center, eye_r, r)


func _draw_brow(side: float, eye_center: Vector2, eye_r: float, r: float) -> void:
	var y := eye_center.y - eye_r * 1.7
	var width := eye_r * 1.3
	var color := data.shade_color.darkened(0.15)
	var tilt := 0.0
	match rig.brow_state:
		&"raised":
			return  # hidden when raised in surprise/happy
		&"down":
			tilt = 0.35 * side
	var inner := eye_center + Vector2(-width * side, y + tilt * eye_r)
	var outer := eye_center + Vector2(width * side, y + eye_r * 0.15)
	draw_line(inner, outer, color, maxf(1.4, r * 0.07), true)


func _eye_radius(r: float) -> float:
	match data.eye_shape:
		CharacterData.EyeShape.OVERSIZED:
			return r * 0.26
		CharacterData.EyeShape.HALF:
			return r * 0.18
		_:
			return r * 0.17
