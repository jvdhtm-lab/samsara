class_name Door
extends Interactable
## A transition between areas, optionally locked behind a story flag.
##
## Systems layer + light presentation (it draws its own placeholder door).
## Interaction requests are routed through the application layer
## (Game.change_area), which owns navigation and spawn state.

@export_file("*.tscn") var target_scene: String = ""
@export var target_spawn: StringName = &"default"
@export var initially_unlocked: bool = true
@export var unlock_flag: StringName = &""
@export var locked_lines: PackedStringArray = PackedStringArray(["The door is locked."])
@export var door_color: Color = Color("#b98a5a")


func _ready() -> void:
	super._ready()
	if prompt_text == "Interact":
		prompt_text = "Enter"


func is_locked() -> bool:
	if unlock_flag != &"" and Game.timeline.get_flag(unlock_flag, false):
		return false
	return not initially_unlocked


func can_interact(_player: Node) -> bool:
	return enabled and not Game.in_dialogue


func interact(_player: Node) -> void:
	play_feedback()
	if is_locked():
		Game.request_raw_dialogue(StringName(name), _locked_definition())
		return
	if target_scene == "":
		push_warning("Door '%s' has no target_scene." % name)
		return
	Game.change_area(target_scene, target_spawn)


func _locked_definition() -> Dictionary:
	return {
		"speaker": String(name),
		"speaker_name": "Door",
		"start": "start",
		"nodes": {
			"start": {"lines": Array(locked_lines), "choices": []},
		},
	}


func _draw() -> void:
	var frame := Rect2(-13.0, -20.0, 26.0, 34.0)
	draw_rect(frame.grow(2.0), door_color.darkened(0.35))
	draw_rect(frame, door_color)
	draw_rect(Rect2(-9.0, -16.0, 18.0, 12.0), door_color.darkened(0.12))
	draw_circle(Vector2(7.0, -1.0), 2.2, Color("#f4e2b8"))
	if is_locked():
		draw_rect(Rect2(-4.0, 2.0, 8.0, 7.0), Color("#6b5a45"))
		draw_arc(Vector2(0.0, 2.0), 3.0, PI, TAU, 8, Color("#6b5a45"), 2.0, true)
