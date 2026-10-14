class_name MetaUI
extends CanvasLayer
## Escalating meta-narrative UI: a subtle full-screen tint whose intensity grows
## with the narrative stage, plus fading "whisper" messages for anomalies.
##
## Presentation layer. Reads stage/anomalies from EventBus and the director.

const TINT := Color(0.12, 0.05, 0.17, 0.0)
const FLASH := Color(0.7, 0.85, 1.0, 0.0)
const WHISPER_SECONDS := 3.5

var _tint: ColorRect
var _flash: ColorRect
var _whisper: Label
var _intensity := 0.0
var _flash_time := 0.0
var _whisper_time := 0.0
var _time := 0.0


func _ready() -> void:
	layer = 4
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	EventBus.meta_stage_changed.connect(_on_stage_changed)
	EventBus.anomaly_triggered.connect(_on_anomaly)
	EventBus.magic_used.connect(_on_magic_used)
	if Game.director != null:
		_intensity = clampf(float(Game.director.current_stage) / 5.0, 0.0, 1.0)
	set_process(true)


func _build_ui() -> void:
	_tint = ColorRect.new()
	_tint.color = TINT
	_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tint)

	_flash = ColorRect.new()
	_flash.color = FLASH
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)

	_whisper = Label.new()
	_whisper.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_whisper.offset_top = 60.0
	_whisper.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_whisper.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_whisper.add_theme_color_override("font_color", Color("#e7d6ff"))
	_whisper.add_theme_color_override("font_outline_color", Color(0.06, 0.04, 0.09, 0.9))
	_whisper.add_theme_constant_override("outline_size", 4)
	_whisper.visible = false
	add_child(_whisper)


func _process(delta: float) -> void:
	_time += delta
	var pulse := 0.5 + 0.5 * sin(_time * 1.5)
	_tint.color = Color(TINT.r, TINT.g, TINT.b, _intensity * (0.03 + 0.05 * pulse))

	if _flash_time > 0.0:
		_flash_time = maxf(0.0, _flash_time - delta)
		_flash.color = Color(FLASH.r, FLASH.g, FLASH.b, _flash_time * 0.35)

	if _whisper_time > 0.0:
		_whisper_time -= delta
		_whisper.modulate.a = clampf(_whisper_time / 0.8, 0.0, 1.0)
		if _whisper_time <= 0.0:
			_whisper.visible = false


func _on_magic_used(_ability_id: StringName) -> void:
	_flash_time = 0.5


func _on_stage_changed(stage: int, _previous: int) -> void:
	_intensity = clampf(float(stage) / 5.0, 0.0, 1.0)


func _on_anomaly(_anomaly_id: StringName, message: String) -> void:
	if message == "":
		return
	_whisper.text = message
	_whisper.visible = true
	_whisper.modulate.a = 1.0
	_whisper_time = WHISPER_SECONDS
