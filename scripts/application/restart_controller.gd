class_name RestartController
extends CanvasLayer
## The restart transaction: request -> confirmation -> restart -> new timeline.
##
## Application layer. Owns the state machine and the confirmation UI. It archives
## the current timeline, resets to a clean timeline via Game, persists the new
## state, and never depends on deleting the player's only save.

enum State { AVAILABLE, CONFIRMATION, RESTARTING, NEW_TIMELINE }

const SHADE := Color(0.06, 0.04, 0.09, 0.82)

var state: State = State.AVAILABLE

var _root: Control
var _warning: Label
var _stakes: Label


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	set_open(false)


func is_open() -> bool:
	return _root != null and _root.visible


func open() -> void:
	if state == State.RESTARTING or is_open():
		return
	state = State.CONFIRMATION
	_refresh_text()
	set_open(true)
	get_tree().paused = true
	EventBus.restart_warning.emit()


func cancel() -> void:
	if state == State.RESTARTING:
		return
	state = State.AVAILABLE
	set_open(false)
	get_tree().paused = false
	EventBus.restart_cancelled.emit()


## Performs the restart transaction. `navigate` returns the player to a fresh
## world; tests pass false. Paths default to SaveManager's real locations.
func confirm(navigate := true, slot := "", backup := "", temp := "", archive := "") -> bool:
	if state == State.RESTARTING:
		return false
	state = State.RESTARTING
	EventBus.restart_confirmed.emit()

	var slot_path := slot if slot != "" else SaveManager.SLOT_PATH
	var backup_path := backup if backup != "" else SaveManager.BACKUP_PATH
	var temp_path := temp if temp != "" else SaveManager.TEMP_PATH
	var archive_path := archive if archive != "" else SaveManager.ARCHIVE_PATH

	SaveManager.archive_current(slot_path, archive_path, backup_path)
	var errors := Game.begin_new_timeline()
	SaveManager.save_game(slot_path, backup_path, temp_path)

	state = State.NEW_TIMELINE
	set_open(false)
	get_tree().paused = false
	EventBus.restart_completed.emit(errors.is_empty())
	if navigate:
		Game.enter_world()
	return errors.is_empty()


# --- UI --------------------------------------------------------------------

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var shade := ColorRect.new()
	shade.color = SHADE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.custom_minimum_size = Vector2(360.0, 0.0)
	center.add_child(column)

	var title := Label.new()
	title.text = "Begin Again?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#e7d6ff"))
	column.add_child(title)

	_warning = Label.new()
	_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_warning.add_theme_color_override("font_color", Color("#f6efe2"))
	column.add_child(_warning)

	_stakes = Label.new()
	_stakes.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stakes.add_theme_color_override("font_color", Color("#c9a86a"))
	column.add_child(_stakes)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	column.add_child(buttons)

	var keep := Button.new()
	keep.text = "Keep This Timeline"
	keep.custom_minimum_size = Vector2(160.0, 34.0)
	keep.pressed.connect(cancel)
	buttons.add_child(keep)

	var restart := Button.new()
	restart.text = "Restart the Universe"
	restart.custom_minimum_size = Vector2(160.0, 34.0)
	restart.pressed.connect(func(): confirm())
	buttons.add_child(restart)


func _refresh_text() -> void:
	_warning.text = MetaNarrative.restart_warning(Game.director.current_stage if Game.director != null else 0)
	var picnic := Game.timeline.get_trap_resolution(&"endless_picnic")
	_stakes.text = "Characters met: %d\nQuests completed: %d\nPicnic: %s\n\nThis timeline will be lost." % [
		MetaNarrative.met_characters(Game.timeline),
		MetaNarrative.completed_quests(Game.timeline),
		picnic if picnic != "" else "not yet resolved",
	]


func set_open(open: bool) -> void:
	if _root != null:
		_root.visible = open
