class_name ShadowLayer
extends CharacterLayer
## Soft contact shadow. Scales with the body's walk squash for weight.

func _draw() -> void:
	if data == null:
		return
	var r := data.body_radius
	var base := r + data.footprint * 0.5
	_ellipse(
		Vector2(0.0, base),
		rig.shadow_scale.x * r * 0.92,
		rig.shadow_scale.y * r * 0.30,
		Color(0.15, 0.12, 0.20, 0.22)
	)
