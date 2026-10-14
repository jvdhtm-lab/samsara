class_name TimelineEnding
extends RefCounted
## Completion conditions and the epilogue text for finishing a timeline.
##
## Systems layer, static so it is headless-testable. Reads authoritative state
## (timeline + meta) and produces conditions and prose; it mutates nothing.

const REQUIRED_QUESTS: Array[String] = ["pip_device", "lumi_story", "momo_picnic"]

const PICNIC := &"endless_picnic"


## Returns [{ "id", "label", "met" }] for each completion requirement.
static func conditions(timeline: TimelineState, meta: MetaProgression) -> Array:
	var all_quests := true
	for quest_id in REQUIRED_QUESTS:
		if timeline.get_quest_status(StringName(quest_id)) != "completed":
			all_quests = false
			break
	return [
		{ "id": "quests", "label": "Help Lumi, Pip, and Momo", "met": all_quests },
		{ "id": "picnic", "label": "Resolve the endless picnic", "met": TrapMachine.is_resolved(timeline, PICNIC) },
		{ "id": "confront", "label": "Face what the village has become", "met": MetaNarrative.stage(timeline, meta) >= 4 },
	]


static func is_ready(timeline: TimelineState, meta: MetaProgression) -> bool:
	for condition in conditions(timeline, meta):
		if not condition["met"]:
			return false
	return true


static func unmet_labels(timeline: TimelineState, meta: MetaProgression) -> Array:
	var labels: Array = []
	for condition in conditions(timeline, meta):
		if not condition["met"]:
			labels.append(condition["label"])
	return labels


## The epilogue, assembled from the player's relationships, quest outcomes, and
## how they resolved the picnic.
static func epilogue_lines(timeline: TimelineState, meta: MetaProgression) -> Array:
	var lines: Array = [
		"You stayed.",
		"The village does not restart. It simply keeps going, and so do you.",
	]
	lines.append(_character_line(&"lumi", &"lumi_story", "Lumi", timeline))
	lines.append(_character_line(&"pip", &"pip_device", "Pip", timeline))
	lines.append(_character_line(&"momo", &"momo_picnic", "Momo", timeline))
	lines.append(_resolution_line(timeline.get_trap_resolution(PICNIC)))
	if meta.completed_timelines > 0:
		lines.append("You have finished a timeline before. You already knew it could be done.")
	lines.append("A timeline finished. Not erased.")
	lines.append("The End.")
	return lines


static func _character_line(character_id: StringName, quest_id: StringName, name: String, timeline: TimelineState) -> String:
	var completed := timeline.get_quest_status(quest_id) == "completed"
	var level := timeline.relationship_level(character_id)
	if completed and level == CharacterState.LEVEL_CONFIDANT:
		return "%s stays beside you, certain now that you will not leave." % name
	if completed:
		return "%s thanks you, quietly, for staying to the end." % name
	return "%s waves, still hoping you will come back." % name


static func _resolution_line(resolution: String) -> String:
	match resolution:
		"frozen":
			return "You froze the endless picnic, and the afternoon finally moved on."
		"walked_away":
			return "You walked out of the endless picnic instead of letting it keep you."
		"refused":
			return "You refused the endless picnic, and Momo let you go."
		_:
			return "The endless picnic ended because you did not let it start again."
