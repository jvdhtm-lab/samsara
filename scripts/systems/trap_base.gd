class_name TrapBase
extends AreaController
## Scene root for a trap/loop. Wraps TrapMachine and adds overridable hooks.
##
## Systems layer (scene root). Subclasses (e.g. EndlessPicnic) implement the
## loop content; this base owns the state transitions and the timeline storage.

@export var trap_id: StringName = &""


func _ready() -> void:
	super._ready()
	if trap_id != &"" and not TrapMachine.is_resolved(Game.timeline, trap_id):
		Game.set_active_trap(trap_id)


func _exit_tree() -> void:
	if trap_id != &"":
		Game.clear_active_trap(trap_id)


func trap_state() -> String:
	return TrapMachine.state_of(Game.timeline, trap_id)


func is_resolved() -> bool:
	return TrapMachine.is_resolved(Game.timeline, trap_id)


func is_discovered() -> bool:
	return TrapMachine.is_discovered(Game.timeline, trap_id)


func iterations() -> int:
	return TrapMachine.iterations(Game.timeline, trap_id)


func enter() -> bool:
	var changed := TrapMachine.enter(Game.timeline, trap_id)
	if changed:
		_on_enter()
	return changed


func advance() -> int:
	return TrapMachine.advance(Game.timeline, trap_id)


func discover() -> bool:
	var changed := TrapMachine.discover(Game.timeline, trap_id)
	if changed:
		_on_discover()
	return changed


func resolve(resolution: StringName) -> bool:
	var changed := TrapMachine.resolve(Game.timeline, trap_id, resolution)
	if changed:
		_on_resolve(resolution)
	return changed


func _on_enter() -> void:
	pass


func _on_discover() -> void:
	pass


func _on_resolve(_resolution: StringName) -> void:
	pass
