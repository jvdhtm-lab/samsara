class_name DialogueRunner
extends RefCounted
## Pure dialogue playback state machine.
##
## Systems layer. Given a loaded definition dictionary, tracks the current
## node/line and exposes text, advance, choice, and routing operations. It
## contains no presentation and mutates no state (effects are returned to the
## caller for application-layer handling).
##
## Node shape:
##   "lines":   [ "text" | {"text": "...", "expression": "happy"} ]
##   "choices": [ {"text","next","effects","condition"|"conditions"} ]
##   "next":    "node"      (auto-continue after the last line)
##   "routes":  [ {"condition"?, "next"} ]   (conditional auto-branch)
##   "effects": [ ... ]     (applied when the node is entered)

var definition: Dictionary
var node_key: String = "start"
var line_index: int = 0
var finished := false


func _init(dialogue_definition: Dictionary) -> void:
	definition = dialogue_definition
	node_key = str(definition.get("start", "start"))


func speaker_id() -> StringName:
	return StringName(str(definition.get("speaker", "")))


func current_node() -> Dictionary:
	var nodes: Dictionary = definition.get("nodes", {})
	return nodes.get(node_key, {})


func current_lines() -> Array:
	return current_node().get("lines", [])


func current_text() -> String:
	var lines := current_lines()
	if line_index < 0 or line_index >= lines.size():
		return ""
	var line: Variant = lines[line_index]
	if typeof(line) == TYPE_DICTIONARY:
		return str(line.get("text", ""))
	return str(line)


func current_expression() -> StringName:
	var lines := current_lines()
	if line_index < 0 or line_index >= lines.size():
		return &""
	var line: Variant = lines[line_index]
	if typeof(line) == TYPE_DICTIONARY:
		return StringName(str(line.get("expression", "")))
	return &""


func has_next_line() -> bool:
	return line_index < current_lines().size() - 1


func is_last_line() -> bool:
	return line_index >= current_lines().size() - 1


## True when the current node shows text or choices (i.e. is not a pure routing
## or effect-only node).
func has_content() -> bool:
	var node := current_node()
	return not node.get("lines", []).is_empty() or not node.get("choices", []).is_empty()


func available_choices(timeline: TimelineState) -> Array:
	if not is_last_line():
		return []
	var result: Array = []
	for choice in current_node().get("choices", []):
		if typeof(choice) == TYPE_DICTIONARY and _choice_passes(choice, timeline):
			result.append(choice)
	return result


func _choice_passes(choice: Dictionary, timeline: TimelineState) -> bool:
	if choice.has("condition") and not DialogueConditions.evaluate(choice["condition"], timeline):
		return false
	if choice.has("conditions") \
			and not DialogueConditions.evaluate({"type": "all", "conditions": choice["conditions"]}, timeline):
		return false
	return true


## Advances one line, or follows the node's `next` if the line list is spent.
## Returns true while the dialogue is still active.
func advance() -> bool:
	if has_next_line():
		line_index += 1
		return true
	var node := current_node()
	if node.get("choices", []).is_empty():
		var next := str(node.get("next", ""))
		if next != "" and _has_node(next):
			_enter_node(next)
			return true
		finished = true
	return not finished


## Navigates using a concrete, already condition-filtered choice entry. The
## caller applies `effects`.
func choose_entry(entry: Dictionary) -> void:
	var next := str(entry.get("next", ""))
	if next == "" or not _has_node(next):
		finished = true
	else:
		_enter_node(next)


func choose(index: int) -> Dictionary:
	var choices: Array = current_node().get("choices", [])
	if index < 0 or index >= choices.size():
		return {}
	var chosen: Dictionary = choices[index]
	choose_entry(chosen)
	return chosen


## Follows conditional routing/effect-only nodes until reaching a node with
## content (or a terminal node). Called by the caller after entering a node.
func resolve(timeline: TimelineState) -> void:
	var guard := 0
	while guard < 32 and not finished:
		guard += 1
		var node := current_node()
		if not node.get("lines", []).is_empty() or not node.get("choices", []).is_empty():
			return
		var routes: Array = node.get("routes", [])
		if routes.is_empty():
			finished = true
			return
		var next := ""
		for route in routes:
			if typeof(route) != TYPE_DICTIONARY:
				continue
			if DialogueConditions.evaluate(route.get("condition", null), timeline):
				next = str(route.get("next", ""))
				break
		if next == "" or not _has_node(next):
			finished = true
			return
		_enter_node(next)


func _enter_node(key: String) -> void:
	node_key = key
	line_index = 0


func _has_node(key: String) -> bool:
	var nodes: Dictionary = definition.get("nodes", {})
	return nodes.has(key)
