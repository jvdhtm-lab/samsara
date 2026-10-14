class_name DialogueValidator
extends RefCounted
## Static validation for authored dialogue definitions.
##
## Systems layer, pure/static for headless use. Returns a list of human-readable
## errors (empty means valid). Used by the test suite and available to future
## authoring tools.

const EFFECT_TYPES := ["relationship", "flag", "quest", "meta", "trap", "focus"]


static func validate(definition: Dictionary, known_character_ids: Dictionary = {},
		known_quest_ids: Dictionary = {}) -> Array[String]:
	var errors: Array[String] = []
	if definition.is_empty():
		errors.append("definition is empty")
		return errors

	var nodes: Variant = definition.get("nodes", {})
	if typeof(nodes) != TYPE_DICTIONARY or (nodes as Dictionary).is_empty():
		errors.append("no nodes defined")
		return errors

	var start := str(definition.get("start", "start"))
	if not nodes.has(start):
		errors.append("start node '%s' does not exist" % start)

	var speaker := str(definition.get("speaker", ""))
	if speaker == "":
		errors.append("missing speaker id")
	elif not known_character_ids.is_empty() and not known_character_ids.has(speaker):
		errors.append("unknown speaker '%s'" % speaker)

	for node_key in nodes:
		var node: Variant = nodes[node_key]
		if typeof(node) != TYPE_DICTIONARY:
			errors.append("node '%s' is not an object" % node_key)
			continue
		_validate_node(node_key, node, nodes, known_character_ids, known_quest_ids, errors)
	return errors


static func _validate_node(node_key: String, node: Dictionary, nodes: Dictionary,
		known_character_ids: Dictionary, known_quest_ids: Dictionary, errors: Array[String]) -> void:
	var lines: Array = node.get("lines", [])
	var choices: Array = node.get("choices", [])
	var routes: Array = node.get("routes", [])
	var next := str(node.get("next", ""))

	if lines.is_empty() and choices.is_empty() and routes.is_empty() and next == "":
		errors.append("node '%s' has no lines, choices, routes, or next" % node_key)

	for line in lines:
		if typeof(line) == TYPE_DICTIONARY and str(line.get("text", "")) == "":
			errors.append("node '%s' has a line with empty text" % node_key)

	for choice in choices:
		if typeof(choice) != TYPE_DICTIONARY:
			errors.append("node '%s' has a malformed choice" % node_key)
			continue
		var target := str(choice.get("next", ""))
		if target != "" and not nodes.has(target):
			errors.append("node '%s' choice points to missing node '%s'" % [node_key, target])
		if str(choice.get("text", "")) == "":
			errors.append("node '%s' has a choice with empty text" % node_key)
		_validate_effects(node_key, choice.get("effects", []), known_character_ids, known_quest_ids, errors)

	for route in routes:
		if typeof(route) != TYPE_DICTIONARY:
			errors.append("node '%s' has a malformed route" % node_key)
			continue
		var target := str(route.get("next", ""))
		if target == "" or not nodes.has(target):
			errors.append("node '%s' route points to missing node '%s'" % [node_key, target])

	if next != "" and not nodes.has(next):
		errors.append("node '%s' next points to missing node '%s'" % [node_key, next])

	_validate_effects(node_key, node.get("effects", []), known_character_ids, known_quest_ids, errors)


static func _validate_effects(node_key: String, effects: Array, known_character_ids: Dictionary,
		known_quest_ids: Dictionary, errors: Array[String]) -> void:
	for effect in effects:
		if typeof(effect) != TYPE_DICTIONARY:
			errors.append("node '%s' has a malformed effect" % node_key)
			continue
		var type := str(effect.get("type", ""))
		if not EFFECT_TYPES.has(type):
			errors.append("node '%s' has unknown effect type '%s'" % [node_key, type])
			continue
		if type == "relationship":
			var character := str(effect.get("character", ""))
			if not known_character_ids.is_empty() and not known_character_ids.has(character):
				errors.append("node '%s' effect targets unknown character '%s'" % [node_key, character])
		elif type == "quest":
			_validate_quest_effect(node_key, effect, known_quest_ids, errors)


static func _validate_quest_effect(node_key: String, effect: Dictionary, known_quest_ids: Dictionary,
		errors: Array[String]) -> void:
	if known_quest_ids.is_empty():
		return
	var quest := str(effect.get("quest", ""))
	if not known_quest_ids.has(quest):
		errors.append("node '%s' quest effect targets unknown quest '%s'" % [node_key, quest])
		return
	if str(effect.get("action", "")) == "objective":
		var objective := str(effect.get("objective", ""))
		var objectives: Dictionary = known_quest_ids[quest]
		if not objectives.has(objective):
			errors.append("node '%s' objective '%s' is not part of quest '%s'" % [node_key, objective, quest])
