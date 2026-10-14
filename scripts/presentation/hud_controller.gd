class_name HUDController
extends CanvasLayer
## Interaction prompt, quest notifications, and magic focus/feedback.
##
## Presentation layer. Reflects interaction targets and events announced on
## EventBus. Reads titles from QuestLibrary (systems) for display.

const TOAST_SECONDS := 3.0

var _prompt: Label
var _toast: Label
var _magic: Label
var _vignette: TextureRect
var _toast_time := 0.0
var _current: Interactable


func _ready() -> void:
	layer = 5
	_build_ui()
	set_process(true)
	EventBus.interaction_target_changed.connect(_on_target_changed)
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_finished.connect(_on_dialogue_finished)
	EventBus.quest_started.connect(_on_quest_started)
	EventBus.quest_completed.connect(_on_quest_completed)
	EventBus.focus_changed.connect(_on_focus_changed)
	EventBus.magic_used.connect(_on_magic_used)
	EventBus.magic_failed.connect(_on_magic_failed)
	EventBus.timeline_started.connect(_on_timeline_started)
	_prompt.visible = false
	_refresh_magic()


func _build_ui() -> void:
	_vignette = TextureRect.new()
	_vignette.texture = _make_vignette_texture()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vignette)

	_prompt = Label.new()
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -46.0
	_prompt.offset_bottom = -24.0
	_prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_color_override("font_color", Color("#fff3d6"))
	_prompt.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.12, 0.9))
	_prompt.add_theme_constant_override("outline_size", 4)
	add_child(_prompt)

	_toast = Label.new()
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_top = 14.0
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_color_override("font_color", Color("#ffe9a8"))
	_toast.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.12, 0.9))
	_toast.add_theme_constant_override("outline_size", 4)
	_toast.visible = false
	add_child(_toast)

	_magic = Label.new()
	_magic.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_magic.offset_left = 12.0
	_magic.offset_top = -40.0
	_magic.offset_bottom = -18.0
	_magic.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_magic.add_theme_color_override("font_color", Color("#bcd9ff"))
	_magic.add_theme_color_override("font_outline_color", Color(0.06, 0.04, 0.09, 0.9))
	_magic.add_theme_constant_override("outline_size", 4)
	add_child(_magic)


func _make_vignette_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.0, 0.0, 0.0, 0.0))
	gradient.set_color(1, Color(0.02, 0.02, 0.05, 0.25))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture


func _process(delta: float) -> void:
	if _toast_time > 0.0:
		_toast_time -= delta
		if _toast_time <= 0.0:
			_toast.visible = false


# --- Interaction -----------------------------------------------------------

func _on_target_changed(interactable: Node) -> void:
	_current = interactable as Interactable
	_update()


func _on_dialogue_started(_speaker: StringName, _dialogue: StringName) -> void:
	_prompt.visible = false


func _on_dialogue_finished(_dialogue: StringName) -> void:
	_update()


func _update() -> void:
	if _current == null or not is_instance_valid(_current):
		_prompt.visible = false
		return
	_prompt.text = "[E] %s" % _current.prompt_text
	_prompt.visible = true


# --- Quests ----------------------------------------------------------------

func _on_quest_started(quest_id: StringName) -> void:
	_show_toast("Quest started: %s" % _quest_title(quest_id))


func _on_quest_completed(quest_id: StringName) -> void:
	_show_toast("Quest complete: %s" % _quest_title(quest_id))


func _quest_title(quest_id: StringName) -> String:
	var definition := QuestLibrary.load_definition(quest_id)
	return str(definition.get("title", String(quest_id)))


# --- Magic -----------------------------------------------------------------

func _on_focus_changed(_value: int) -> void:
	_refresh_magic()


func _on_timeline_started(_timeline_id: String) -> void:
	_refresh_magic()


func _on_magic_used(ability_id: StringName) -> void:
	_show_toast(str(MagicLibrary.load_definition(ability_id).get("name", String(ability_id))))
	AudioManager.play_tone(880.0, 0.18, -10.0)


func _on_magic_failed(_ability_id: StringName, reason: String) -> void:
	_show_toast(_reason_text(reason))
	AudioManager.play_tone(150.0, 0.16, -14.0)


func _refresh_magic() -> void:
	if _magic == null:
		return
	var focus := Game.timeline.get_magic_focus()
	var pips := ""
	for i in range(TimelineState.MAGIC_FOCUS_MAX):
		pips += "◆" if i < focus else "◇"
	_magic.text = "[Q] Focus %s" % pips


func _reason_text(reason: String) -> String:
	match reason:
		MagicManager.REASON_LOCKED:
			return "You do not know that yet."
		MagicManager.REASON_NO_FOCUS:
			return "Not enough focus."
		MagicManager.REASON_NO_TARGET:
			return "Nothing here to use it on."
		MagicManager.REASON_UNDISCOVERED:
			return "You need to understand the pattern first."
		_:
			return "Nothing happens."


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast.visible = true
	_toast_time = TOAST_SECONDS
