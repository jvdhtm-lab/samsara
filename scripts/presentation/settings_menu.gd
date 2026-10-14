class_name SettingsMenu
extends CanvasLayer
## Settings and accessibility overlay. Owned by `Game` so it is reachable from
## both the title screen and the pause menu.
##
## Presentation layer. Edits `Game.settings`, applies changes, and persists them
## to the standalone settings file (ADR-028). It never touches narrative state.

const BG := Color(0.05, 0.04, 0.08, 0.92)
const TITLE_COLOR := Color("#e7d6ff")
const LABEL_COLOR := Color("#c9bfe0")
const HINT_COLOR := Color(1, 1, 1, 0.55)

var _root: Control
var _master: HSlider
var _music: HSlider
var _sfx: HSlider
var _text_speed: HSlider
var _reduce_motion: CheckButton
var _high_contrast: CheckButton
var _fullscreen: CheckButton
var _use_3d: CheckButton


func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_close()


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var shade := ColorRect.new()
	shade.color = BG
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.custom_minimum_size = Vector2(420, 0)
	center.add_child(column)

	var title := Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	column.add_child(title)

	_master = _add_slider(column, "Master volume", 0.0, 1.0, 0.05)
	_music = _add_slider(column, "Music volume", 0.0, 1.0, 0.05)
	_sfx = _add_slider(column, "Effects volume", 0.0, 1.0, 0.05)
	_text_speed = _add_slider(column, "Text speed", 0.0, 120.0, 2.0)

	_reduce_motion = _add_check(column, "Reduce motion")
	_high_contrast = _add_check(column, "High-contrast text")
	_fullscreen = _add_check(column, "Fullscreen")
	_use_3d = _add_check(column, "3D characters & world (2.5D)")

	_master.value_changed.connect(func(v): _on_master(v))
	_music.value_changed.connect(func(v): _on_music(v))
	_sfx.value_changed.connect(func(v): _on_sfx(v))
	_text_speed.value_changed.connect(func(v): _on_text_speed(v))
	_reduce_motion.toggled.connect(func(on): _on_reduce_motion(on))
	_high_contrast.toggled.connect(func(on): _on_high_contrast(on))
	_fullscreen.toggled.connect(func(on): _on_fullscreen(on))
	_use_3d.toggled.connect(func(on): _on_use_3d(on))

	var close := Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(0, 32)
	close.pressed.connect(_close)
	column.add_child(close)

	var hint := Label.new()
	hint.text = "Changes are saved immediately."
	hint.add_theme_color_override("font_color", HINT_COLOR)
	column.add_child(hint)


func _add_slider(parent: Node, title: String, min_value: float, max_value: float, step: float) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = title
	label.custom_minimum_size = Vector2(130, 0)
	label.add_theme_color_override("font_color", LABEL_COLOR)
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.custom_minimum_size = Vector2(220, 0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)

	var readout := Label.new()
	readout.custom_minimum_size = Vector2(44, 0)
	readout.add_theme_color_override("font_color", LABEL_COLOR)
	slider.value_changed.connect(func(v): readout.text = _format(v, step))
	row.add_child(readout)

	parent.add_child(row)
	return slider


func _add_check(parent: Node, title: String) -> CheckButton:
	var check := CheckButton.new()
	check.text = title
	check.add_theme_color_override("font_color", LABEL_COLOR)
	parent.add_child(check)
	return check


func _format(value: float, step: float) -> String:
	if step >= 1.0:
		return "%d" % int(round(value))
	return "%d%%" % int(round(value * 100.0))


# --- Open / close ----------------------------------------------------------

func is_open() -> bool:
	return _root != null and _root.visible


func open() -> void:
	_sync_from_settings()
	_root.visible = true


func close() -> void:
	_close()


func _close() -> void:
	if _root != null:
		_root.visible = false


func _sync_from_settings() -> void:
	var settings := Game.settings
	_master.value = settings.master_volume
	_music.value = settings.music_volume
	_sfx.value = settings.sfx_volume
	_text_speed.value = settings.text_speed
	_reduce_motion.button_pressed = settings.reduce_motion
	_high_contrast.button_pressed = settings.high_contrast_text
	_fullscreen.button_pressed = settings.fullscreen
	_use_3d.button_pressed = settings.use_3d_visuals


# --- Change handlers -------------------------------------------------------

func _on_master(value: float) -> void:
	Game.settings.master_volume = value
	_apply()

func _on_music(value: float) -> void:
	Game.settings.music_volume = value
	_apply()

func _on_sfx(value: float) -> void:
	Game.settings.sfx_volume = value
	_apply()

func _on_text_speed(value: float) -> void:
	Game.settings.text_speed = value
	_apply()

func _on_reduce_motion(on: bool) -> void:
	Game.settings.reduce_motion = on
	_apply()

func _on_high_contrast(on: bool) -> void:
	Game.settings.high_contrast_text = on
	_apply()

func _on_fullscreen(on: bool) -> void:
	Game.settings.fullscreen = on
	_apply()


func _on_use_3d(on: bool) -> void:
	Game.settings.use_3d_visuals = on
	_apply()


func _apply() -> void:
	Game.settings.apply_to_audio_buses()
	Game.settings.apply_fullscreen()
	AudioManager.refresh_music_volume()
	SaveManager.save_settings()
