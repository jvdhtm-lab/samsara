class_name BodyLayer
extends CharacterLayer
## Body shell, limbs, and rivets. The rig moves/squashes this node (and, as the
## parent of the face group, everything attached to it).

func _draw() -> void:
	if data == null:
		return
	var r := data.body_radius
	_draw_body(r)
	_draw_limbs(r)
	_draw_rivets(r)


func _draw_body(r: float) -> void:
	var outline := data.shade_color
	match data.silhouette:
		CharacterData.Silhouette.PEAR:
			_ellipse(Vector2(0.0, 0.75), r + 2.0, r * 1.22, outline)
			_pear(Vector2.ZERO, r, data.body_color)
		CharacterData.Silhouette.PLUSH:
			_ellipse(Vector2.ZERO, r * 1.18 + 2.0, r * 1.0 + 2.0, outline)
			_ellipse(Vector2.ZERO, r * 1.18, r * 1.0, data.body_color)
		_:
			_ellipse(Vector2.ZERO, r + 2.0, r + 2.0, outline)
			_ellipse(Vector2.ZERO, r, r, data.body_color)


func _draw_limbs(r: float) -> void:
	var limb := data.shade_color
	_ellipse(Vector2(-r * 0.42, r * 0.92), r * 0.30, r * 0.17, limb)
	_ellipse(Vector2(r * 0.42, r * 0.92), r * 0.30, r * 0.17, limb)
	_ellipse(Vector2(-r * 0.96, r * 0.20), r * 0.22, r * 0.15, limb)
	_ellipse(Vector2(r * 0.96, r * 0.20), r * 0.22, r * 0.15, limb)


func _draw_rivets(r: float) -> void:
	var rivet := data.shade_color.darkened(0.08)
	for p in [
		Vector2(-r * 0.72, -r * 0.42),
		Vector2(r * 0.72, -r * 0.42),
		Vector2(-r * 0.82, r * 0.30),
		Vector2(r * 0.82, r * 0.30),
	]:
		draw_circle(p, maxf(1.2, r * 0.09), rivet)
		draw_circle(p - Vector2(0.5, 0.5), maxf(0.6, r * 0.04), data.body_color.lightened(0.25))
