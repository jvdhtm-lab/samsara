class_name PauseMenu
extends CanvasLayer
## Pause overlay. Owned by Game so it works in every scene.

var _root: Control
var _status: Label


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	set_open(false)


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var shade := ColorRect.new()
	shade.color = Color(0.08, 0.06, 0.11, 0.72)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.custom_minimum_size = Vector2(220, 0)
	center.add_child(column)

	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#e7d6ff"))
	column.add_child(title)

	column.add_child(_make_button("Resume", _on_resume))
	column.add_child(_make_button("Journal", _on_journal))
	column.add_child(_make_button("Settings", _on_settings))
	column.add_child(_make_button("Save Timeline", _on_save))
	column.add_child(_make_button("Load Last Save", _on_load))
	column.add_child(_make_button("Begin Again", _on_restart))
	column.add_child(_make_button("Return to Title", _on_title))
	column.add_child(_make_button("Quit", _on_quit))

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	column.add_child(_status)


func _make_button(text: String, handler: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 32)
	button.pressed.connect(handler)
	return button


func set_open(open: bool) -> void:
	if _root != null:
		_root.visible = open
	if open:
		_status.text = ""


func _on_resume() -> void:
	Game.toggle_pause()


func _on_journal() -> void:
	Game.toggle_journal()


func _on_settings() -> void:
	Game.open_settings()


func _on_save() -> void:
	_status.text = "Timeline saved." if SaveManager.save_game() else "Save failed."


func _on_load() -> void:
	if SaveManager.load_game():
		_status.text = "Timeline restored."
	else:
		_status.text = "No readable save."


func _on_title() -> void:
	if get_tree().paused:
		Game.toggle_pause()
	Game.go_to_main_menu()


func _on_restart() -> void:
	Game.request_restart()


func _on_quit() -> void:
	get_tree().quit()
