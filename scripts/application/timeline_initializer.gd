class_name TimelineInitializer
extends RefCounted
## Builds a fresh timeline and verifies restart isolation.
##
## Application layer, pure/static so it is headless-testable. Meta-progression
## and application settings are owned by Game and are deliberately untouched
## here: a new timeline resets characters, relationships, quests, flags, and
## visited locations, while meta-progression survives.

static func build() -> TimelineState:
	return TimelineState.new()


## Returns a list of isolation violations (empty means clean). A "clean" fresh
## timeline has a new id and no leaked character, quest, flag, or location state.
static func verify_isolation(previous_timeline_id: String, fresh: TimelineState) -> Array[String]:
	var errors: Array[String] = []
	if fresh == null:
		errors.append("no timeline was produced")
		return errors
	if fresh.timeline_id == "":
		errors.append("timeline id is empty")
	if fresh.timeline_id == previous_timeline_id:
		errors.append("timeline id was not regenerated")
	if not fresh.character_states.is_empty():
		errors.append("character state leaked into the new timeline")
	if not fresh.quests.is_empty():
		errors.append("quest state leaked into the new timeline")
	if not fresh.story_flags.is_empty():
		errors.append("story flags leaked into the new timeline")
	if not fresh.visited_locations.is_empty():
		errors.append("visited locations leaked into the new timeline")
	return errors
