class_name MetaNarrative
extends RefCounted
## Pure meta-narrative progression model.
##
## Systems layer, static so it is headless-testable. Derives a narrative stage
## (0–5) from player progress. This is deliberately a *defined* model rather
## than random escalation (AGENTS.md §17).

const STAGE_NAMES: Array[String] = [
	"Comfort", "Oddity", "Suspicion", "Pressure", "Confrontation", "Resolution",
]

const EVENTS_PATH := "res://data/events/anomalies.json"

static var _events_cache: Dictionary = {}


static func completed_quests(timeline: TimelineState) -> int:
	var count := 0
	for quest_id in timeline.quests:
		if timeline.get_quest_status(quest_id) == "completed":
			count += 1
	return count


static func met_characters(timeline: TimelineState) -> int:
	var count := 0
	for character_id in timeline.character_states:
		if (timeline.character_states[character_id] as CharacterState).met:
			count += 1
	return count


## A single scalar that grows with story progress. Considers quests, the first
## trap, recorded anomalies, and prior restarts.
static func pressure(timeline: TimelineState, meta: MetaProgression) -> int:
	var value := 0
	value += completed_quests(timeline) * 2
	if TrapMachine.is_discovered(timeline, &"endless_picnic"):
		value += 1
	if TrapMachine.is_resolved(timeline, &"endless_picnic"):
		value += 3
	value += mini(meta.anomalies_seen.size(), 4)
	value += mini(meta.restart_count, 3)
	return value


static func stage(timeline: TimelineState, meta: MetaProgression) -> int:
	var value := pressure(timeline, meta)
	if value >= 10:
		return 5
	if value >= 7:
		return 4
	if value >= 4:
		return 3
	if value >= 2:
		return 2
	if value >= 1:
		return 1
	return 0


static func stage_name(stage_index: int) -> String:
	return STAGE_NAMES[clampi(stage_index, 0, STAGE_NAMES.size() - 1)]


## Escalating flavor text for the restart confirmation, keyed by stage.
static func restart_warning(stage_index: int) -> String:
	match clampi(stage_index, 0, 5):
		0, 1:
			return "The world is warm and unfinished. If you begin again, this timeline will be gone."
		2:
			return "Something here is wrong, but it is still yours. Beginning again will erase it."
		3:
			return "It would be so easy to start over. No one would remember. You would."
		4:
			return "The village is watching you decide. It knows this is not the first time."
		_:
			return "You could end this and keep what you learned. Or you could stay, and finish it."


static func stage_anomalies(stage_index: int) -> Array:
	var events := load_events()
	var stages: Dictionary = events.get("stages", {})
	var entry: Dictionary = stages.get(str(stage_index), {})
	return entry.get("anomalies", [])


static func load_events() -> Dictionary:
	if not _events_cache.is_empty():
		return _events_cache
	if not FileAccess.file_exists(EVENTS_PATH):
		return {}
	var file := FileAccess.open(EVENTS_PATH, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	var ok := json.parse(file.get_as_text()) == OK
	file.close()
	if ok and typeof(json.data) == TYPE_DICTIONARY:
		_events_cache = json.data
	return _events_cache


static func clear_cache() -> void:
	_events_cache.clear()
