class_name TrapClue
extends Interactable
## An examinable object that reveals a trap's rule.
##
## The first look sets a "noticed" flag and shows a hint; the second look
## discovers the trap, sets the rule flag, and records the anomaly. Reusable
## across traps: configure the flags, lines, and trap id per instance.

@export var trap_id: StringName = &""
@export var notice_flag: StringName = &""
@export var rule_flag: StringName = &""
@export var anomaly_id: String = ""
@export var speaker_label: String = "Clue"
@export var first_lines: PackedStringArray = PackedStringArray()
@export var rule_lines: PackedStringArray = PackedStringArray()


func _ready() -> void:
	super._ready()
	if prompt_text == "Interact":
		prompt_text = "Examine"


func can_interact(_player: Node) -> bool:
	return enabled and not Game.in_dialogue


func interact(_player: Node) -> void:
	play_feedback()
	if notice_flag != &"" and not bool(Game.timeline.get_flag(notice_flag, false)):
		Game.apply_effects([{"type": "flag", "flag": notice_flag, "value": true}])
		Game.request_raw_dialogue(StringName(name), _definition(first_lines))
		return

	var effects: Array = []
	if trap_id != &"":
		effects.append({"type": "trap", "trap": trap_id, "action": "discover"})
	if rule_flag != &"":
		effects.append({"type": "flag", "flag": rule_flag, "value": true})
	if anomaly_id != "":
		effects.append({"type": "meta", "record_anomaly": anomaly_id})
	if not effects.is_empty():
		Game.apply_effects(effects)
	Game.request_raw_dialogue(StringName(name), _definition(rule_lines))


func _definition(lines: PackedStringArray) -> Dictionary:
	return {
		"speaker": String(name),
		"speaker_name": speaker_label,
		"start": "start",
		"nodes": {"start": {"lines": Array(lines), "choices": []}},
	}
