class_name SecretFind
extends Interactable
## A one-time optional secret. Interacting grants a flag (e.g. a key), records a
## discovery for the journal, and shows a short text; afterwards it is inert.
##
## Reusable: configure `grant_flag`, the `found_flag` that gates repeats, and
## the discovery id.

@export var grant_flag: StringName = &""
@export var found_flag: StringName = &""
@export var discovery_id: String = ""
@export var speaker_label: String = "Secret"
@export var prompt: String = "Search"
@export var lines: PackedStringArray = PackedStringArray()
## When more than one slot exists, only the slot chosen by the timeline
## variation is active, so the secret moves between timelines.
@export var variation_slots: int = 1
@export var variation_slot: int = 0


func _ready() -> void:
	super._ready()
	if prompt_text == "Interact":
		prompt_text = prompt
	_apply_variation()


func _apply_variation() -> void:
	if variation_slots <= 1:
		return
	var active := TimelineVariation.variant_index(Game.timeline, Game.meta, variation_slots)
	var selected := active == variation_slot
	visible = selected
	enabled = selected


func is_found() -> bool:
	return found_flag != &"" and bool(Game.timeline.get_flag(found_flag, false))


func can_interact(_player: Node) -> bool:
	return enabled and not is_found() and not Game.in_dialogue


func interact(_player: Node) -> void:
	play_feedback()
	var effects: Array = []
	if grant_flag != &"":
		effects.append({"type": "flag", "flag": grant_flag, "value": true})
	if found_flag != &"":
		effects.append({"type": "flag", "flag": found_flag, "value": true})
	if discovery_id != "":
		effects.append({"type": "meta", "record_discovery": discovery_id})
	if not effects.is_empty():
		Game.apply_effects(effects)
	if not lines.is_empty():
		Game.request_raw_dialogue(StringName(name), _definition())


func _definition() -> Dictionary:
	return {
		"speaker": String(name),
		"speaker_name": speaker_label,
		"start": "start",
		"nodes": {"start": {"lines": Array(lines), "choices": []}},
	}
