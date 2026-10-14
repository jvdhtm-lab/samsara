class_name Prop
extends TextInteractable
## A generic examinable object. One script, several placeholder shapes chosen by
## `kind`, so new props are scenes/data rather than new code.

enum Kind { CRATE, FLOWER, DEVICE }

@export var kind: Kind = Kind.CRATE
@export var tint: Color = Color("#d9b98a")


func _ready() -> void:
	super._ready()
	if prompt_text == "Interact":
		prompt_text = "Examine"


func _draw() -> void:
	match kind:
		Kind.FLOWER:
			_draw_flower()
		Kind.DEVICE:
			_draw_device()
		_:
			_draw_crate()


func _draw_crate() -> void:
	var box := Rect2(-12.0, -12.0, 24.0, 24.0)
	draw_rect(box, tint.darkened(0.28))
	draw_rect(Rect2(box.position + Vector2(2.0, 2.0), box.size - Vector2(4.0, 4.0)), tint)
	draw_line(Vector2(-12.0, -12.0), Vector2(12.0, 12.0), tint.darkened(0.35), 2.0)
	draw_line(Vector2(12.0, -12.0), Vector2(-12.0, 12.0), tint.darkened(0.35), 2.0)


func _draw_flower() -> void:
	draw_line(Vector2(0.0, 12.0), Vector2(0.0, -2.0), Color("#6ba85f"), 2.5)
	for angle in [0.0, 1.26, 2.51, 3.77, 5.03]:
		draw_circle(Vector2(cos(angle), sin(angle)) * 6.0 + Vector2(0.0, -4.0), 4.0, tint)
	draw_circle(Vector2(0.0, -4.0), 3.0, Color("#ffe28a"))


func _draw_device() -> void:
	var body := Rect2(-13.0, -11.0, 26.0, 22.0)
	draw_rect(body.grow(1.5), tint.darkened(0.35))
	draw_rect(body, tint)
	draw_circle(Vector2(-4.0, -1.0), 5.0, tint.darkened(0.15))
	draw_line(Vector2(-4.0, -1.0), Vector2(-4.0, -5.0), Color("#3a2f26"), 1.6)
	draw_circle(Vector2(6.0, -4.0), 2.0, Color("#ff8a6a"))
	draw_rect(Rect2(-9.0, 6.0, 18.0, 3.0), tint.darkened(0.25))
