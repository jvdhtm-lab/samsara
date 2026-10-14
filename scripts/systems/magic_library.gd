class_name MagicLibrary
extends RefCounted
## Loads and caches magic ability definitions from `res://data/abilities`.
##
## Systems layer. Content is JSON so abilities are data, not code. Definitions
## are immutable during gameplay. Effects use the same vocabulary as dialogue
## (see docs/NARRATIVE_BIBLE.md), with `@active` as a target placeholder for the
## current trap.

const ABILITY_DIR := "res://data/abilities/"

static var _cache: Dictionary = {}


static func load_definition(ability_id: StringName) -> Dictionary:
	var key := String(ability_id)
	if _cache.has(key):
		return _cache[key]

	var path := "%s%s.json" % [ABILITY_DIR, key]
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	var ok := json.parse(file.get_as_text()) == OK
	file.close()

	if not ok or typeof(json.data) != TYPE_DICTIONARY:
		push_error("MagicLibrary: malformed ability JSON '%s'." % path)
		return {}

	_cache[key] = json.data
	return json.data


static func has_definition(ability_id: StringName) -> bool:
	return FileAccess.file_exists("%s%s.json" % [ABILITY_DIR, String(ability_id)])


static func clear_cache() -> void:
	_cache.clear()
