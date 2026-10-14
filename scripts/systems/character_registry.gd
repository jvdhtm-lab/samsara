class_name CharacterRegistry
extends RefCounted
## Resolves character ids to their authored `CharacterData`.
##
## Systems layer. Uses an explicit path list (rather than directory scanning)
## so it also works from an exported build. New characters must be added here
## in addition to their `.tres`.

const PATHS: Array[String] = [
	"res://resources/characters/lumi.tres",
	"res://resources/characters/pip.tres",
	"res://resources/characters/momo.tres",
	"res://resources/characters/fern.tres",
	"res://resources/characters/player.tres",
]

static var _by_id: Dictionary = {}
static var _loaded := false


static func get_character(character_id: StringName) -> CharacterData:
	_ensure_loaded()
	return _by_id.get(String(character_id))


static func ids() -> Array:
	_ensure_loaded()
	return _by_id.keys()


static func has(character_id: StringName) -> bool:
	_ensure_loaded()
	return _by_id.has(String(character_id))


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	for path in PATHS:
		var character := load(path) as CharacterData
		if character != null:
			_by_id[String(character.id)] = character
