class_name FaceLayer
extends CharacterLayer
## Faceplate / visor. Sits behind the eyes and mouth.

func _draw() -> void:
	if data == null:
		return
	var r := data.body_radius
	_ellipse(Vector2(0.0, -r * 0.10), r * 0.74, r * 0.62, data.face_color)
