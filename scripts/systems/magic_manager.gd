class_name MagicManager
extends RefCounted
## Validation and resource spending for magic abilities.
##
## Systems layer, static so it is headless-testable. Pure state transitions over
## TimelineState (focus) and MetaProgression (unlocked abilities). Applying an
## ability's effects is the application layer's job (`Game.use_magic`).

const REASON_OK := ""
const REASON_UNKNOWN := "unknown"
const REASON_LOCKED := "locked"
const REASON_NO_FOCUS := "no_focus"
const REASON_NO_TARGET := "no_target"
const REASON_UNDISCOVERED := "undiscovered"


static func cost(ability_id: StringName) -> int:
	return int(MagicLibrary.load_definition(ability_id).get("cost", 1))


static func is_unlocked(meta: MetaProgression, ability_id: StringName) -> bool:
	return meta.has_ability(String(ability_id))


## Returns "" when usable, otherwise a reason code.
static func can_use(timeline: TimelineState, meta: MetaProgression,
		ability_id: StringName, active_trap: StringName) -> String:
	var definition := MagicLibrary.load_definition(ability_id)
	if definition.is_empty():
		return REASON_UNKNOWN
	if not meta.has_ability(String(ability_id)):
		return REASON_LOCKED
	if timeline.get_magic_focus() < int(definition.get("cost", 1)):
		return REASON_NO_FOCUS

	if bool(definition.get("requires_trap", false)):
		if active_trap == &"" or TrapMachine.is_resolved(timeline, active_trap):
			return REASON_NO_TARGET
		if bool(definition.get("requires_discovered_trap", false)) \
				and not TrapMachine.is_discovered(timeline, active_trap):
			return REASON_UNDISCOVERED
	return REASON_OK


## Validates and spends focus. Returns "" on success, else a reason code.
static func use(timeline: TimelineState, meta: MetaProgression,
		ability_id: StringName, active_trap: StringName) -> String:
	var reason := can_use(timeline, meta, ability_id, active_trap)
	if reason != REASON_OK:
		return reason
	var definition := MagicLibrary.load_definition(ability_id)
	timeline.spend_magic_focus(int(definition.get("cost", 1)))
	return REASON_OK
