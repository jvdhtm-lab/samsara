class_name QuestManager
extends RefCounted
## Quest state transitions and queries.
##
## Systems layer, static so it is headless-testable and needs no lifetime.
## Operates on a TimelineState and emits EventBus notifications. It does NOT
## grant rewards/consequences — the application layer (Game) applies those when
## a quest completes, keeping reward logic in one place.

static func start_quest(timeline: TimelineState, quest_id: StringName) -> bool:
	if quest_id == &"" or not QuestLibrary.has_definition(quest_id):
		return false
	if timeline.get_quest_status(quest_id) == "active":
		return false
	timeline.set_quest_status(quest_id, "active")
	EventBus.quest_started.emit(quest_id)
	return true


## Marks an objective complete. Returns true only if this call completed the
## whole quest (so the caller grants rewards exactly once).
static func complete_objective(timeline: TimelineState, quest_id: StringName, objective_id: StringName) -> bool:
	if timeline.get_quest_status(quest_id) != "active":
		return false
	if timeline.is_objective_complete(quest_id, objective_id):
		return false
	timeline.mark_objective(quest_id, objective_id)
	EventBus.quest_objective_completed.emit(quest_id, objective_id)
	if _all_objectives_done(timeline, quest_id):
		complete_quest(timeline, quest_id)
		return true
	return false


static func complete_quest(timeline: TimelineState, quest_id: StringName) -> bool:
	if timeline.get_quest_status(quest_id) == "completed":
		return false
	timeline.set_quest_status(quest_id, "completed")
	EventBus.quest_completed.emit(quest_id)
	return true


static func fail_quest(timeline: TimelineState, quest_id: StringName) -> bool:
	if timeline.get_quest_status(quest_id) == "failed":
		return false
	timeline.set_quest_status(quest_id, "failed")
	EventBus.quest_failed.emit(quest_id)
	return true


static func is_active(timeline: TimelineState, quest_id: StringName) -> bool:
	return timeline.get_quest_status(quest_id) == "active"


static func is_completed(timeline: TimelineState, quest_id: StringName) -> bool:
	return timeline.get_quest_status(quest_id) == "completed"


## Returns {"done": int, "total": int} for the quest's authored objectives.
static func progress(timeline: TimelineState, quest_id: StringName) -> Dictionary:
	var objectives := QuestLibrary.objective_ids(quest_id)
	var done := 0
	for objective_id in objectives:
		if timeline.is_objective_complete(quest_id, objective_id):
			done += 1
	return {"done": done, "total": objectives.size()}


static func _all_objectives_done(timeline: TimelineState, quest_id: StringName) -> bool:
	var objectives := QuestLibrary.objective_ids(quest_id)
	if objectives.is_empty():
		return false
	for objective_id in objectives:
		if not timeline.is_objective_complete(quest_id, objective_id):
			return false
	return true
