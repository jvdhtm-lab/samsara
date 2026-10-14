class_name LoopToken
extends Interactable
## A recurring object that drives a manual trap loop. Each interaction advances
## the trap and narrates escalating lines chosen by iteration count.
##
## Reusable across traps: set `trap_id` and three line sets. Requests the loop
## narration through the application layer so it reuses the one dialogue UI.

@export var trap_id: StringName = &""
@export var speaker_label: String = "The Returning Tree"
@export var prompt: String = "Pick up the leaf"
@export var lines_early: PackedStringArray = PackedStringArray()
@export var lines_mid: PackedStringArray = PackedStringArray()
@export var lines_late: PackedStringArray = PackedStringArray()


func _ready() -> void:
	super._ready()
	if prompt_text == "Interact":
		prompt_text = prompt


func can_interact(_player: Node) -> bool:
	if not enabled or Game.in_dialogue:
		return false
	return trap_id == &"" or not TrapMachine.is_resolved(Game.timeline, trap_id)


func interact(_player: Node) -> void:
	play_feedback()
	var count := TrapMachine.advance(Game.timeline, trap_id)
	Game.request_raw_dialogue(&"loop", _definition(_lines_for(count)))


func _lines_for(count: int) -> PackedStringArray:
	if count >= 3 and not lines_late.is_empty():
		return lines_late
	if count == 2 and not lines_mid.is_empty():
		return lines_mid
	return lines_early


func _definition(lines: PackedStringArray) -> Dictionary:
	return {
		"speaker": "loop",
		"speaker_name": speaker_label,
		"start": "start",
		"nodes": {"start": {"lines": Array(lines), "choices": []}},
	}
