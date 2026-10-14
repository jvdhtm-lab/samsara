class_name ReturningTree
extends TrapBase
## The Returning Tree, in the Hollow beneath the village.
##
## Whatever you carry away from it is back by the time you turn around. Each
## interaction with the fallen leaf advances the loop and the hollow darkens.
## Escape by understanding the rule, then leaving (Roots Edge), letting it stay
## (Fern), or remembering what the tree once was (Memory Echo).

@export var quest_id: StringName = &"fern_hollow"

var _background: Node


func _ready() -> void:
	if trap_id == &"":
		trap_id = &"returning_tree"
	super._ready()
	_background = get_node_or_null("Background")
	EventBus.trap_loop_iteration.connect(_on_iteration)
	if not is_resolved():
		apply_visuals(iterations())


func _on_iteration(changed_trap_id: StringName, count: int) -> void:
	if changed_trap_id != trap_id:
		return
	apply_visuals(count)
	AudioManager.play_tone(240.0 + float(count) * 24.0, 0.1, -16.0)


func _on_discover() -> void:
	Game.apply_effects([
		{"type": "quest", "quest": quest_id, "action": "start"},
		{"type": "quest", "quest": quest_id, "action": "objective", "objective": "discover_tree"},
	])


func _on_resolve(_resolution: StringName) -> void:
	Game.apply_effects([
		{"type": "quest", "quest": quest_id, "action": "objective", "objective": "resolve_tree"},
	])
	AudioManager.play_tone(520.0, 0.25, -12.0)


func apply_visuals(count: int) -> void:
	if _background != null and _background.has_method("set_iteration"):
		_background.call("set_iteration", count)
