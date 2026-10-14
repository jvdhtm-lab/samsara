class_name EndingSequence
extends CanvasLayer
## The timeline ending: a short epilogue assembled from the player's choices,
## then a choice to return to the menu or begin another timeline.

const BG := Color("#0d0a12")
const TEXT_COLOR := Color("#f6efe2")
const HINT_COLOR := Color(1, 1, 1, 0.5)

var _lines: Array = []
var _index := 0
var _label: Label
var _hint: Label
var _buttons: HBoxContainer


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_lines = TimelineEnding.epilogue_lines(Game.timeline, Game.meta)
	_build_ui()
	_show_line()
	AudioManager.play_music(&"ending")
	AudioManager.stop_ambience()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = BG
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	column.custom_minimum_size = Vector2(440.0, 0.0)
	center.add_child(column)

	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.custom_minimum_size = Vector2(440.0, 80.0)
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", TEXT_COLOR)
	column.add_child(_label)

	_hint = Label.new()
	_hint.text = "[E] continue"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_color_override("font_color", HINT_COLOR)
	column.add_child(_hint)

	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 16)
	_buttons.visible = false
	column.add_child(_buttons)

	_buttons.add_child(_make_button("Return to the Menu", _on_menu))
	_buttons.add_child(_make_button("Begin Another Timeline", _on_new_timeline))


func _make_button(text: String, handler: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(200.0, 34.0)
	button.pressed.connect(handler)
	return button


func _show_line() -> void:
	if _index < _lines.size():
		_label.text = str(_lines[_index])
		_hint.visible = true
		_buttons.visible = false
	else:
		_label.text = ""
		_hint.visible = false
		_buttons.visible = true


func _advance() -> void:
	if _index < _lines.size():
		_index += 1
		_show_line()


func _unhandled_input(event: InputEvent) -> void:
	if _index >= _lines.size():
		return
	if event.is_action_pressed("interact"):
		_advance()
		get_viewport().set_input_as_handled()


func _on_menu() -> void:
	Game.go_to_main_menu()


func _on_new_timeline() -> void:
	Game.start_new_timeline()
