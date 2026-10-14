class_name MigrationManager
extends RefCounted
## Upgrades older save payloads to the current schema version.
##
## Infrastructure layer, pure/static so it is headless-testable. Each step is
## explicit and additive; malformed input is returned unchanged for the
## validator to reject.

static func migrate(data: Dictionary) -> Dictionary:
	if not data.has("version"):
		return data
	var version := int(data["version"])
	var guard := 0
	while version < SaveSchema.CURRENT_VERSION and guard < 16:
		guard += 1
		match version:
			1:
				data = _v1_to_v2(data)
			_:
				break
		version += 1
		data["version"] = version
	return data


static func _v1_to_v2(data: Dictionary) -> Dictionary:
	var timeline: Dictionary = data.get("timeline", {})

	if timeline.has("relationships") and not timeline.has("characters"):
		var characters := {}
		for key in timeline["relationships"]:
			characters[key] = {
				"attributes": timeline["relationships"][key],
				"flags": {},
				"met": true,
			}
		timeline["characters"] = characters
		timeline.erase("relationships")

	if timeline.has("quest_state") and not timeline.has("quests"):
		var quests := {}
		for key in timeline["quest_state"]:
			quests[key] = {"status": str(timeline["quest_state"][key]), "objectives": {}}
		timeline["quests"] = quests
		timeline.erase("quest_state")

	data["timeline"] = timeline
	return data
