class_name MainMenu
extends Control
## Title screen. Sends flow requests to the application layer.

const TITLE := "SAMSARA"
const SUBTITLE := "eternal restart"

var _continue_button: Button
var _status: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	AudioManager.play_music(&"menu")
	AudioManager.stop_ambience()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#2a2136")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var glow := ColorRect.new()
	glow.color = Color(0.78, 0.6, 0.85, 0.06)
	glow.set_anchors_preset(Control.PRESET_TOP_WIDE)
	glow.offset_bottom = 220.0
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.custom_minimum_size = Vector2(260, 0)
	center.add_child(column)

	var title := Label.new()
	title.text = TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color("#e7d6ff"))
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = SUBTITLE
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("#c9a86a"))
	column.add_child(subtitle)

	column.add_child(_spacer(24))

	_continue_button = _make_button("Continue", _on_continue)
	_continue_button.disabled = not SaveManager.has_save()
	column.add_child(_continue_button)

	column.add_child(_make_button("New Timeline", _on_new_timeline))
	column.add_child(_make_button("Settings", _on_settings))
	column.add_child(_make_button("Quit", _on_quit))

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	column.add_child(_status)


func _make_button(text: String, handler: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 34)
	button.pressed.connect(handler)
	return button


func _spacer(height: float) -> Control:
	var node := Control.new()
	node.custom_minimum_size = Vector2(0, height)
	return node


func _on_new_timeline() -> void:
	Game.start_new_timeline()


func _on_settings() -> void:
	Game.open_settings()


func _on_continue() -> void:
	if SaveManager.load_game():
		Game.enter_world()
	else:
		_status.text = "No readable save was found."


func _on_quit() -> void:
	get_tree().quit()
