class_name TrapMachine
extends RefCounted
## Reusable trap/loop state machine.
##
## Systems layer, static so it is headless-testable. State lives in
## `TimelineState.traps` (so it resets with the timeline and persists in saves).
## A trap progresses dormant -> active -> discovered -> resolved. A resolved
## trap never re-activates.

const DORMANT := "dormant"
const ACTIVE := "active"
const DISCOVERED := "discovered"
const RESOLVED := "resolved"


static func default_state() -> Dictionary:
	return {"state": DORMANT, "iterations": 0, "resolution": ""}


static func state_of(timeline: TimelineState, trap_id: StringName) -> String:
	return timeline.get_trap_state(trap_id)


static func iterations(timeline: TimelineState, trap_id: StringName) -> int:
	return timeline.get_trap_iterations(trap_id)


static func is_resolved(timeline: TimelineState, trap_id: StringName) -> bool:
	return state_of(timeline, trap_id) == RESOLVED


static func is_discovered(timeline: TimelineState, trap_id: StringName) -> bool:
	return state_of(timeline, trap_id) == DISCOVERED


## Activates the trap. Returns false if it was already resolved.
static func enter(timeline: TimelineState, trap_id: StringName) -> bool:
	if is_resolved(timeline, trap_id):
		return false
	var data := timeline.get_trap(trap_id)
	if data.get("state") == ACTIVE:
		return false
	data["state"] = ACTIVE
	timeline.set_trap(trap_id, data)
	EventBus.trap_triggered.emit(trap_id)
	return true


## Advances the loop counter. Returns the new iteration count.
static func advance(timeline: TimelineState, trap_id: StringName) -> int:
	if is_resolved(timeline, trap_id):
		return iterations(timeline, trap_id)
	var data := timeline.get_trap(trap_id)
	var count := int(data.get("iterations", 0)) + 1
	data["iterations"] = count
	timeline.set_trap(trap_id, data)
	EventBus.trap_loop_iteration.emit(trap_id, count)
	return count


## Marks the underlying rule as understood. Returns false if already discovered
## or resolved.
static func discover(timeline: TimelineState, trap_id: StringName) -> bool:
	if is_resolved(timeline, trap_id) or is_discovered(timeline, trap_id):
		return false
	var data := timeline.get_trap(trap_id)
	data["state"] = DISCOVERED
	timeline.set_trap(trap_id, data)
	EventBus.trap_discovered.emit(trap_id)
	return true


## Resolves the trap with a named resolution. Returns false if already resolved.
static func resolve(timeline: TimelineState, trap_id: StringName, resolution: StringName) -> bool:
	if is_resolved(timeline, trap_id):
		return false
	var data := timeline.get_trap(trap_id)
	data["state"] = RESOLVED
	data["resolution"] = String(resolution)
	timeline.set_trap(trap_id, data)
	EventBus.trap_resolved.emit(trap_id, resolution)
	return true
