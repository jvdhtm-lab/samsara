class_name BackAccessoryLayer
extends CharacterLayer
## Silhouette-defining accessory drawn behind the body.
##
## This is the strongest recognition cue at gameplay scale: drooping ears
## (Lumi), a leaf antenna (Pip), plush nubs (Momo), or a single antenna
## (the player). The owning rig rotates this node for idle sway.

func _draw() -> void:
	if data == null:
		return
	var r := data.body_radius
	match data.accessory:
		CharacterData.Accessory.DROOP_EARS:
			for side in [-1.0, 1.0]:
				var center := Vector2(side * r * 0.72, -r * 0.78)
				_ellipse(center, r * 0.26 + 1.5, r * 0.80 + 1.5, data.shade_color, 24, side * 0.5)
				_ellipse(center, r * 0.26, r * 0.80, data.body_color, 24, side * 0.5)
		CharacterData.Accessory.LEAF_ANTENNA:
			var stem := data.shade_color
			draw_line(Vector2(0.0, -r * 0.95), Vector2(0.0, -r * 1.70), stem, maxf(2.0, r * 0.09), true)
			draw_circle(Vector2(0.0, -r * 1.70), maxf(2.0, r * 0.11), stem)
			_ellipse(Vector2(r * 0.24, -r * 1.78), r * 0.22, r * 0.13, data.accent_color, 20, -0.5)
		CharacterData.Accessory.BUTTON_STUDS:
			_ellipse(Vector2(-r * 1.12, -r * 0.30), r * 0.20, r * 0.26, data.shade_color)
			_ellipse(Vector2(r * 1.12, -r * 0.30), r * 0.20, r * 0.26, data.shade_color)
		CharacterData.Accessory.SIMPLE_ANTENNA:
			var antenna := data.shade_color
			draw_line(Vector2(0.0, -r * 0.95), Vector2(0.0, -r * 1.45), antenna, maxf(2.0, r * 0.08), true)
			draw_circle(Vector2(0.0, -r * 1.45), maxf(2.5, r * 0.14), data.accent_color)
			draw_circle(Vector2(0.0, -r * 1.45), maxf(1.2, r * 0.07), data.eye_color)
