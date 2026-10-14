class_name TrapExit
extends Interactable
## A physical escape from a trap, available once its rule is known.
##
## Presentation/system boundary. Reusable across traps: set `trap_id`, the
## `required_flag` that gates the exit, and the `resolution` recorded when the
## player leaves. Requests effects through the application layer.

@export var trap_id: StringName = &""
@export var required_flag: StringName = &""
@export var resolution: StringName = &"left_it"
@export var set_flag: StringName = &""
@export var prompt: String = "Leave"


func _ready() -> void:
	super._ready()
	if prompt_text == "Interact":
		prompt_text = prompt


func can_interact(_player: Node) -> bool:
	if not enabled or Game.in_dialogue:
		return false
	if trap_id != &"" and TrapMachine.is_resolved(Game.timeline, trap_id):
		return false
	if required_flag != &"" and not bool(Game.timeline.get_flag(required_flag, false)):
		return false
	return true


func interact(_player: Node) -> void:
	play_feedback()
	var effects: Array = []
	if trap_id != &"":
		effects.append({
			"type": "trap", "trap": trap_id,
			"action": "resolve", "resolution": String(resolution),
		})
	if set_flag != &"":
		effects.append({"type": "flag", "flag": set_flag, "value": true})
	if not effects.is_empty():
		Game.apply_effects(effects)
