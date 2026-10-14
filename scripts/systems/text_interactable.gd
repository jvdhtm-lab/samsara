class_name TextInteractable
extends Interactable
## Base for objects that show authored text when used (signs, props).
##
## Systems layer. Builds a minimal dialogue definition and routes it through the
## application layer, so props reuse the one dialogue UI and its rules.

@export var speaker_label: String = "Sign"
@export var lines: PackedStringArray = PackedStringArray()

@export_group("Quest")
## When both are set, interacting completes this quest objective.
@export var quest_id: StringName = &""
@export var objective_id: StringName = &""


func can_interact(_player: Node) -> bool:
	return enabled and lines.size() > 0 and not Game.in_dialogue


func interact(_player: Node) -> void:
	if quest_id != &"" and objective_id != &"":
		Game.apply_effects([{
			"type": "quest",
			"quest": quest_id,
			"action": "objective",
			"objective": objective_id,
		}])
	if lines.is_empty():
		return
	play_feedback()
	Game.request_raw_dialogue(StringName(name), build_definition())


func build_definition() -> Dictionary:
	return {
		"speaker": String(name),
		"speaker_name": speaker_label,
		"start": "start",
		"nodes": {
			"start": {"lines": Array(lines), "choices": []},
		},
	}
