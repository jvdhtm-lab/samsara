class_name DialogueLibrary
extends RefCounted
## Loads and caches authored dialogue definitions from `res://data/dialogue`.
##
## Systems layer. Content is JSON so narrative writers can edit it without
## touching code. Definitions are immutable during gameplay.

const DIALOGUE_DIR := "res://data/dialogue/"

static var _cache: Dictionary = {}


static func load_definition(dialogue_id: StringName) -> Dictionary:
	var key := String(dialogue_id)
	if _cache.has(key):
		return _cache[key]

	var path := "%s%s.json" % [DIALOGUE_DIR, key]
	if not FileAccess.file_exists(path):
		push_error("DialogueLibrary: missing dialogue definition '%s'." % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DialogueLibrary: cannot open '%s'." % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("DialogueLibrary: malformed dialogue JSON '%s'." % path)
		return {}

	_cache[key] = parsed
	return parsed


static func clear_cache() -> void:
	_cache.clear()
