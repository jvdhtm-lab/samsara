class_name DialogueConditions
extends RefCounted
## Evaluates authored dialogue conditions against timeline state.
##
## Systems layer, pure/static for headless testing. Kept intentionally small;
## extend when concrete content requires it.

static func evaluate(condition: Variant, timeline: TimelineState) -> bool:
	if condition == null:
		return true
	if typeof(condition) != TYPE_DICTIONARY:
		return true
	var cond: Dictionary = condition
	match str(cond.get("type", "")):
		"flag":
			var flag := StringName(str(cond.get("flag", "")))
			return _loose_equal(timeline.get_flag(flag, false), cond.get("equals", true))
		"relationship":
			var character_id := StringName(str(cond.get("character", "")))
			var attribute := str(cond.get("attr", "trust"))
			return timeline.get_relationship(character_id, attribute) >= int(cond.get("min", 0))
		"objective":
			var quest_id := StringName(str(cond.get("quest", "")))
			var objective_id := StringName(str(cond.get("objective", "")))
			var expected := bool(cond.get("done", true))
			return timeline.is_objective_complete(quest_id, objective_id) == expected
		"quest_status":
			var quest_id := StringName(str(cond.get("quest", "")))
			return timeline.get_quest_status(quest_id) == str(cond.get("equals", "active"))
		"trap_iteration":
			var trap_id := StringName(str(cond.get("trap", "")))
			return timeline.get_trap_iterations(trap_id) >= int(cond.get("min", 1))
		"trap_state":
			var trap_id := StringName(str(cond.get("trap", "")))
			return timeline.get_trap_state(trap_id) == str(cond.get("equals", "active"))
		"focus":
			return timeline.get_magic_focus() >= int(cond.get("min", 1))
		"ability":
			var ability := str(cond.get("ability", ""))
			return bool(timeline.get_flag(StringName("ability_%s" % ability), false))
		"all":
			for sub in cond.get("conditions", []):
				if not evaluate(sub, timeline):
					return false
			return true
		"any":
			for sub in cond.get("conditions", []):
				if evaluate(sub, timeline):
					return true
			return false
	return true


static func _loose_equal(a: Variant, b: Variant) -> bool:
	if typeof(a) == typeof(b):
		return a == b
	if _is_number(a) and _is_number(b):
		return float(a) == float(b)
	return str(a) == str(b)


static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
