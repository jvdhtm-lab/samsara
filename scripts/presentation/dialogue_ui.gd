class_name DialogueUI
extends CanvasLayer
## Dialogue presentation with animated portraits. Owns no game state.
##
## Presentation layer. Requests effect application through the application
## layer (Game.apply_effects / Game.finish_dialogue) and reflects the resulting
## state. It never writes to TimelineState directly.
##
## The portrait reuses the character rig, so expressions and the talking
## animation are shared with the world (see docs/ART_BIBLE.md).

const PANEL_COLOR := Color("#241d30")
const BORDER_COLOR := Color("#c9a86a")
const TEXT_COLOR := Color("#f6efe2")
const SPEAKER_COLOR := Color("#ffd9a0")
const CHOICE_COLOR := Color("#d9cfc0")
const CHOICE_SELECTED := Color("#ffe9a8")
const PORTRAIT_SCALE := 2.3

var _panel: PanelContainer
var _speaker_label: Label
var _text_label: Label
var _choice_box: VBoxContainer
var _hint: Label
var _portrait_root: Node2D
var _portrait_rig: CharacterRig

var _runner: DialogueRunner
var _dialogue_id: StringName = &""
var _visible_choices: Array = []
var _choice_labels: Array[Label] = []
var _selected := 0
var _active := false
var _full_text := ""
var _revealed := 0.0
var _revealing := false


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.raw_dialogue_requested.connect(_on_raw_dialogue_requested)
	set_process(true)
	hide()


func _build_ui() -> void:
	_build_portrait()
	_build_panel()


func _build_portrait() -> void:
	_portrait_root = Node2D.new()
	_portrait_root.position = Vector2(72.0, 190.0)
	_portrait_root.scale = Vector2(PORTRAIT_SCALE, PORTRAIT_SCALE)
	_portrait_root.visible = false
	add_child(_portrait_root)

	var scene := load("res://scenes/characters/character_rig.tscn") as PackedScene
	if scene != null:
		_portrait_rig = scene.instantiate() as CharacterRig
		_portrait_root.add_child(_portrait_rig)


func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 140.0
	_panel.offset_right = -16.0
	_panel.offset_top = -150.0
	_panel.offset_bottom = -14.0
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = BORDER_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(vbox)

	_speaker_label = Label.new()
	_speaker_label.add_theme_color_override("font_color", SPEAKER_COLOR)
	vbox.add_child(_speaker_label)

	_text_label = Label.new()
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_color_override("font_color", TEXT_COLOR)
	_text_label.custom_minimum_size = Vector2(0, 46)
	vbox.add_child(_text_label)

	_choice_box = VBoxContainer.new()
	_choice_box.add_theme_constant_override("separation", 2)
	vbox.add_child(_choice_box)

	_hint = Label.new()
	_hint.text = "[E] continue"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	vbox.add_child(_hint)


# --- Start / finish --------------------------------------------------------

func _on_dialogue_started(speaker_id: StringName, dialogue_id: StringName) -> void:
	_begin(speaker_id, DialogueLibrary.load_definition(dialogue_id), dialogue_id)


func _on_raw_dialogue_requested(speaker_id: StringName, definition: Dictionary) -> void:
	_begin(speaker_id, definition, &"__raw")


func _begin(speaker_id: StringName, definition: Dictionary, dialogue_id: StringName) -> void:
	if definition.is_empty():
		Game.finish_dialogue(dialogue_id)
		return
	_runner = DialogueRunner.new(definition)
	_dialogue_id = dialogue_id
	_selected = 0
	_active = true
	_speaker_label.text = str(definition.get("speaker_name", String(speaker_id).capitalize()))
	_setup_portrait(speaker_id)
	show()
	_enter_node()
	if _runner == null or _runner.finished:
		_finish()
		return
	_render()


func _finish() -> void:
	_active = false
	_revealing = false
	if _portrait_rig != null:
		_portrait_rig.set_talking(false)
	_portrait_root.visible = false
	_runner = null
	hide()
	Game.finish_dialogue(_dialogue_id)


# --- Text reveal (typewriter) ----------------------------------------------

func _process(delta: float) -> void:
	if not _revealing:
		return
	var speed := Game.settings.text_speed
	if Game.settings.reduce_motion or speed <= 0.0:
		_complete_reveal()
		return
	_revealed += speed * delta
	var shown := int(_revealed)
	if shown >= _full_text.length():
		_complete_reveal()
	else:
		_text_label.text = _full_text.substr(0, shown)


func _begin_reveal(text: String) -> void:
	_full_text = text
	_revealed = 0.0
	_revealing = text.length() > 0
	if not _revealing or Game.settings.reduce_motion or Game.settings.text_speed <= 0.0:
		_complete_reveal()
	else:
		_text_label.text = ""
	_sync_visibility()


func _complete_reveal() -> void:
	_revealing = false
	_text_label.text = _full_text
	_sync_visibility()


func is_revealing() -> bool:
	return _revealing


func _sync_visibility() -> void:
	if _revealing:
		_choice_box.visible = false
		_hint.visible = false
		return
	_choice_box.visible = not _visible_choices.is_empty()
	_hint.visible = _visible_choices.is_empty()


# --- Portrait --------------------------------------------------------------

func _setup_portrait(speaker_id: StringName) -> void:
	var character := CharacterRegistry.get_character(speaker_id)
	if character == null or _portrait_rig == null:
		_portrait_root.visible = false
		return
	_portrait_root.visible = true
	_portrait_rig.setup(character)
	_portrait_rig.set_motion(character.idle_motion if character.idle_motion != &"" else &"idle")
	_portrait_rig.set_expression(&"neutral")
	_portrait_rig.set_talking(true)


# --- Node entry / rendering ------------------------------------------------

## Applies the current node's effects, then follows routing nodes until a node
## with visible content (or a terminal node) is reached.
func _enter_node() -> void:
	var guard := 0
	while guard < 32 and _runner != null and not _runner.finished:
		guard += 1
		Game.apply_effects(_runner.current_node().get("effects", []))
		if _runner.has_content():
			return
		_runner.resolve(Game.timeline)


func _render() -> void:
	if _runner == null:
		return
	_apply_text_style()
	_begin_reveal(_runner.current_text())

	var expression := _runner.current_expression()
	if _portrait_rig != null and _portrait_root.visible:
		_portrait_rig.set_expression(expression if expression != &"" else &"neutral")

	for label in _choice_labels:
		label.queue_free()
	_choice_labels.clear()
	_visible_choices = []

	if _runner.is_last_line():
		_visible_choices = _runner.available_choices(Game.timeline)

	if _visible_choices.is_empty():
		_hint.text = "[E] continue"
		_sync_visibility()
		return

	_selected = clampi(_selected, 0, _visible_choices.size() - 1)
	for i in range(_visible_choices.size()):
		var choice: Dictionary = _visible_choices[i]
		var label := Label.new()
		label.text = "%s %s" % [">" if i == _selected else " ", str(choice.get("text", "..."))]
		label.add_theme_color_override("font_color", CHOICE_SELECTED if i == _selected else CHOICE_COLOR)
		_choice_box.add_child(label)
		_choice_labels.append(label)
	_sync_visibility()


func _apply_text_style() -> void:
	if Game.settings.high_contrast_text:
		_text_label.add_theme_color_override("font_color", Color.WHITE)
		_text_label.add_theme_color_override("font_outline_color", Color.BLACK)
		_text_label.add_theme_constant_override("outline_size", 4)
	else:
		_text_label.add_theme_color_override("font_color", TEXT_COLOR)
		_text_label.add_theme_constant_override("outline_size", 0)


# --- Input -----------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if _revealing and event.is_action_pressed("interact"):
		_complete_reveal()
		get_viewport().set_input_as_handled()
		return
	if not _visible_choices.is_empty():
		if event.is_action_pressed("choice_up"):
			_move_selection(-1)
		elif event.is_action_pressed("choice_down"):
			_move_selection(1)
		elif event.is_action_pressed("interact"):
			_confirm_choice()
		else:
			return
	else:
		if not event.is_action_pressed("interact"):
			return
		_advance()
	get_viewport().set_input_as_handled()


func _move_selection(delta: int) -> void:
	if _visible_choices.is_empty():
		return
	_selected = wrapi(_selected + delta, 0, _visible_choices.size())
	_render()


func _advance() -> void:
	var previous_node := _runner.node_key
	if not _runner.advance():
		_finish()
		return
	if _runner.node_key != previous_node or not _runner.has_content():
		_enter_node()
	if _runner == null or _runner.finished:
		_finish()
		return
	_render()


func _confirm_choice() -> void:
	if _selected < 0 or _selected >= _visible_choices.size():
		return
	var choice: Dictionary = _visible_choices[_selected]
	Game.apply_effects(choice.get("effects", []))
	_runner.choose_entry(choice)
	if _runner.finished:
		_finish()
		return
	_enter_node()
	if _runner == null or _runner.finished:
		_finish()
		return
	_render()
