class_name Sign
extends TextInteractable
## A readable village sign. Draws a small wooden board placeholder.

@export var board_color: Color = Color("#d9b98a")
@export var post_color: Color = Color("#8a6a44")


func _ready() -> void:
	super._ready()
	if prompt_text == "Interact":
		prompt_text = "Read"
	if speaker_label == "Sign":
		speaker_label = "Village Sign"


func _draw() -> void:
	draw_rect(Rect2(-2.5, 2.0, 5.0, 14.0), post_color)
	var board := Rect2(-17.0, -13.0, 34.0, 17.0)
	draw_rect(board.grow(1.5), post_color.darkened(0.2))
	draw_rect(board, board_color)
	draw_line(Vector2(-12.0, -8.0), Vector2(12.0, -8.0), post_color, 1.6)
	draw_line(Vector2(-12.0, -4.0), Vector2(8.0, -4.0), post_color, 1.6)
	draw_line(Vector2(-12.0, 0.0), Vector2(4.0, 0.0), post_color, 1.6)
