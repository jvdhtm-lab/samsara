class_name MarkingLayer
extends CharacterLayer
## Chest marking / badge: a secondary, non-colour recognition cue.

func _draw() -> void:
	if data == null:
		return
	var r := data.body_radius
	match data.marking:
		CharacterData.Marking.STAR:
			draw_colored_polygon(_star_points(Vector2(0.0, r * 0.34), r * 0.24, r * 0.10, 5, 0.0), data.accent_color)
		CharacterData.Marking.LEAF:
			_ellipse(Vector2(0.0, r * 0.40), r * 0.16, r * 0.24, data.accent_color, 20, -0.4)
		CharacterData.Marking.BUTTON:
			draw_circle(Vector2(0.0, r * 0.42), r * 0.20, data.accent_color)
			draw_circle(Vector2(-r * 0.06, r * 0.36), r * 0.045, data.shade_color.darkened(0.3))
			draw_circle(Vector2(-r * 0.06, r * 0.48), r * 0.045, data.shade_color.darkened(0.3))
