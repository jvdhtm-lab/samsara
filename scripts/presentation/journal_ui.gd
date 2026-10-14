class_name JournalUI
extends CanvasLayer
## The journal overlay: an at-a-glance listing of the anomalies and discoveries
## recorded across timelines (meta-progression).
##
## Presentation layer. Reads `Game.meta` and owns no state; content is rendered
## by the pure `Journal` helper. Toggled with the journal key or from the pause
## menu.

const BG := Color(0.05, 0.04, 0.08, 0.9)
const TITLE_COLOR := Color("#e7d6ff")
const ANOMALY_COLOR := Color("#f0b8a0")
const DISCOVERY_COLOR := Color("#bcd9ff")
const HINT_COLOR := Color(1, 1, 1, 0.5)

var _root: Control
var _list: VBoxContainer
var _empty: Label


func _ready() -> void:
	layer = 60
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

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 64)
	margin.add_theme_constant_override("margin_right", 64)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	_root.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var title := Label.new()
	title.text = "Journal"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "What you carry between timelines."
	subtitle.add_theme_color_override("font_color", HINT_COLOR)
	column.add_child(subtitle)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	column.add_child(_list)

	_empty = Label.new()
	_empty.text = "You have not noticed anything yet."
	_empty.add_theme_color_override("font_color", HINT_COLOR)
	column.add_child(_empty)

	column.add_child(_spacer())
	var hint := Label.new()
	hint.text = "[J] close"
	hint.add_theme_color_override("font_color", HINT_COLOR)
	column.add_child(hint)


func _spacer() -> Control:
	var node := Control.new()
	node.custom_minimum_size = Vector2(0, 12)
	return node


func is_open() -> bool:
	return _root != null and _root.visible


func toggle() -> void:
	if is_open():
		_close()
	else:
		_open()


func _open() -> void:
	_refresh()
	_root.visible = true


func _close() -> void:
	if _root != null:
		_root.visible = false


func _refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
	var entries: Array = Journal.entries(Game.meta)
	_empty.visible = entries.is_empty()
	for entry in entries:
		var is_anomaly: bool = str(entry.get("kind", "")) == Journal.KIND_ANOMALY
		var label := Label.new()
		label.text = ("~ %s" if is_anomaly else "- %s") % str(entry.get("title", "?"))
		label.add_theme_color_override("font_color", ANOMALY_COLOR if is_anomaly else DISCOVERY_COLOR)
		_list.add_child(label)
