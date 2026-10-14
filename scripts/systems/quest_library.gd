class_name QuestLibrary
extends RefCounted
## Loads and caches quest definitions from `res://data/quests`.
##
## Systems layer. Content is JSON so designers can add quests without code.
## Definitions are immutable during gameplay.

const QUEST_DIR := "res://data/quests/"

static var _cache: Dictionary = {}


static func load_definition(quest_id: StringName) -> Dictionary:
	var key := String(quest_id)
	if _cache.has(key):
		return _cache[key]

	var path := "%s%s.json" % [QUEST_DIR, key]
	if not FileAccess.file_exists(path):
		push_error("QuestLibrary: missing quest definition '%s'." % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("QuestLibrary: cannot open '%s'." % path)
		return {}
	var json := JSON.new()
	var parsed_ok := json.parse(file.get_as_text()) == OK
	file.close()

	if not parsed_ok or typeof(json.data) != TYPE_DICTIONARY:
		push_error("QuestLibrary: malformed quest JSON '%s'." % path)
		return {}

	_cache[key] = json.data
	return json.data


static func has_definition(quest_id: StringName) -> bool:
	return FileAccess.file_exists("%s%s.json" % [QUEST_DIR, String(quest_id)])


static func objective_ids(quest_id: StringName) -> Array:
	var ids: Array = []
	for objective in load_definition(quest_id).get("objectives", []):
		if typeof(objective) == TYPE_DICTIONARY:
			ids.append(StringName(str(objective.get("id", ""))))
	return ids


static func clear_cache() -> void:
	_cache.clear()
