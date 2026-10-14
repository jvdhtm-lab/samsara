class_name NpcController
extends Interactable
## A talkable robot-creature. Identity, looks, and idle behaviour come from a
## CharacterData resource, so new characters require no new code.
##
## Presentation/system boundary: interaction is a system request routed through
## the application layer (Game.start_dialogue).

@export var data: CharacterData

var _rig: CharacterRig
var _prompt: Node2D


func _ready() -> void:
	super._ready()
	_rig = get_node_or_null("Visual") as CharacterRig
	_prompt = get_node_or_null("Prompt") as Node2D
	if _prompt != null:
		_prompt.visible = false

	if data == null:
		push_warning("NpcController on '%s' has no CharacterData." % name)
		return

	prompt_text = "Talk to %s" % data.display_name
	if _rig != null:
		_rig.setup(data)
		_update_reaction()

	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_finished.connect(_on_dialogue_finished)
	EventBus.interaction_target_changed.connect(_on_target_changed)
	EventBus.relationship_changed.connect(_on_relationship_changed)
	EventBus.quest_completed.connect(_on_quest_completed)
	EventBus.meta_stage_changed.connect(_on_meta_stage_changed)


func can_interact(_player: Node) -> bool:
	return enabled and data != null and not Game.in_dialogue


func interact(_player: Node) -> void:
	if data == null:
		return
	Game.start_dialogue(data.id, data.dialogue_id)


func _on_dialogue_started(speaker_id: StringName, _dialogue_id: StringName) -> void:
	if _rig != null and speaker_id == data.id:
		_rig.set_talking(true)


func _on_dialogue_finished(_dialogue_id: StringName) -> void:
	if _rig != null:
		_rig.set_talking(false)


func _on_target_changed(interactable: Node) -> void:
	if _prompt != null:
		_prompt.visible = (interactable == self) and not Game.in_dialogue


func _on_relationship_changed(character_id: StringName, _attribute: StringName, _value: int, _delta: int) -> void:
	if character_id == data.id:
		_update_reaction()


func _on_quest_completed(_quest_id: StringName) -> void:
	_update_reaction()


func _on_meta_stage_changed(_stage: int, _previous: int) -> void:
	_update_reaction()


## Characters visibly react to how the player has treated them, and to the
## world becoming unstable later in the timeline.
func _update_reaction() -> void:
	if _rig == null:
		return
	var expression := RelationshipManager.reaction_expression(Game.timeline, data.id)
	if expression == &"neutral" and bool(Game.timeline.get_flag(&"world_unstable", false)):
		expression = &"uncanny"
	_rig.set_expression(expression)
