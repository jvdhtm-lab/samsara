class_name CharacterState
extends RefCounted
## Per-character mutable state within the current timeline.
##
## Domain layer. Groups relationship attributes, character-scoped flags, and
## whether the player has met the character. Serializes to primitives only.

const DEFAULT_ATTRIBUTES := {"trust": 0, "affection": 0, "suspicion": 0}

const LEVEL_WARY := "wary"
const LEVEL_STRANGER := "stranger"
const LEVEL_FRIEND := "friend"
const LEVEL_CONFIDANT := "confidant"

var character_id: StringName = &""
var attributes: Dictionary = {}
var flags: Dictionary = {}
var met := false


func _init(id: StringName = &"") -> void:
	character_id = id
	attributes = DEFAULT_ATTRIBUTES.duplicate()


func get_attribute(attribute: String) -> int:
	return int(attributes.get(attribute, 0))


func set_attribute(attribute: String, value: int) -> void:
	attributes[attribute] = value


func adjust_attribute(attribute: String, delta: int) -> int:
	var value := get_attribute(attribute) + delta
	attributes[attribute] = value
	return value


func set_flag(flag: StringName, value: Variant = true) -> void:
	flags[flag] = value


func get_flag(flag: StringName, default_value: Variant = false) -> Variant:
	return flags.get(flag, default_value)


## Combined standing: trust and affection raise it, suspicion lowers it.
func score() -> int:
	return get_attribute("trust") + get_attribute("affection") - get_attribute("suspicion")


func relationship_level() -> String:
	var value := score()
	if value < 0:
		return LEVEL_WARY
	if value <= 2:
		return LEVEL_STRANGER
	if value <= 5:
		return LEVEL_FRIEND
	return LEVEL_CONFIDANT


func to_dict() -> Dictionary:
	var attrs := {}
	for key in attributes:
		attrs[String(key)] = attributes[key]
	var out_flags := {}
	for key in flags:
		out_flags[String(key)] = flags[key]
	return {"attributes": attrs, "flags": out_flags, "met": met}


static func from_dict(character_id: StringName, data: Dictionary) -> CharacterState:
	var state := CharacterState.new(character_id)

	if data.has("attributes") and typeof(data["attributes"]) == TYPE_DICTIONARY:
		for key in data["attributes"]:
			state.attributes[String(key)] = int(data["attributes"][key])
	else:
		# Accept the v1 bare attribute map shape.
		for key in DEFAULT_ATTRIBUTES:
			if data.has(key):
				state.attributes[key] = int(data[key])

	if data.has("flags") and typeof(data["flags"]) == TYPE_DICTIONARY:
		for key in data["flags"]:
			state.flags[StringName(key)] = data["flags"][key]

	state.met = bool(data.get("met", true))
	return state
