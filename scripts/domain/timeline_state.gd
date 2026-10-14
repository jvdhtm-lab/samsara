class_name TimelineState
extends RefCounted
## Authoritative mutable state for the CURRENT timeline.
##
## Domain layer. Serializes to primitive dictionaries only (never live scene
## nodes). Reset entirely when a new timeline begins.

const DEFAULT_LOCATION := &"village"
const MAGIC_FOCUS_MAX := 3
const MAGIC_FOCUS_START := 1

var timeline_id: String = ""
var current_location: StringName = DEFAULT_LOCATION
var character_states: Dictionary = {}   # StringName -> CharacterState
var story_flags: Dictionary = {}        # StringName -> Variant
var quests: Dictionary = {}             # StringName -> { "status": String, "objectives": {StringName: bool} }
var traps: Dictionary = {}              # StringName -> { "state": String, "iterations": int, "resolution": String }
var visited_locations: Dictionary = {}  # StringName -> true
var magic_focus: int = MAGIC_FOCUS_START


func _init() -> void:
	reset()


func reset() -> void:
	timeline_id = _make_id()
	current_location = DEFAULT_LOCATION
	character_states.clear()
	story_flags.clear()
	quests.clear()
	traps.clear()
	visited_locations.clear()
	magic_focus = MAGIC_FOCUS_START


static func _make_id() -> String:
	return "tl_%d_%d" % [int(Time.get_unix_time_from_system()), randi() % 100000]


# --- Characters / relationships -------------------------------------------

func ensure_character(character_id: StringName) -> CharacterState:
	if not character_states.has(character_id):
		character_states[character_id] = CharacterState.new(character_id)
	return character_states[character_id]


func get_character_state(character_id: StringName) -> CharacterState:
	return character_states.get(character_id)


func get_relationship(character_id: StringName, attribute: String) -> int:
	var state: CharacterState = character_states.get(character_id)
	return state.get_attribute(attribute) if state != null else 0


func adjust_relationship(character_id: StringName, attribute: String, delta: int) -> int:
	return ensure_character(character_id).adjust_attribute(attribute, delta)


func relationship_level(character_id: StringName) -> String:
	var state: CharacterState = character_states.get(character_id)
	return state.relationship_level() if state != null else CharacterState.LEVEL_STRANGER


# --- Flags ----------------------------------------------------------------

func set_flag(flag: StringName, value: Variant = true) -> void:
	story_flags[flag] = value


func get_flag(flag: StringName, default_value: Variant = false) -> Variant:
	return story_flags.get(flag, default_value)


# --- Quests ---------------------------------------------------------------

func set_quest_status(quest_id: StringName, status: String) -> void:
	var quest := _ensure_quest(quest_id)
	quest["status"] = status


func get_quest_status(quest_id: StringName) -> String:
	var quest: Dictionary = quests.get(quest_id, {})
	return str(quest.get("status", "inactive"))


func set_quest_objectives(quest_id: StringName, objectives: Dictionary) -> void:
	var quest := _ensure_quest(quest_id)
	quest["objectives"] = objectives


func get_quest_objectives(quest_id: StringName) -> Dictionary:
	var quest: Dictionary = quests.get(quest_id, {})
	return quest.get("objectives", {})


func is_objective_complete(quest_id: StringName, objective_id: StringName) -> bool:
	return bool(get_quest_objectives(quest_id).get(objective_id, false))


func mark_objective(quest_id: StringName, objective_id: StringName) -> void:
	var objectives := get_quest_objectives(quest_id).duplicate()
	objectives[objective_id] = true
	set_quest_objectives(quest_id, objectives)


# Back-compat aliases (Phase 1-4 used a bare status string).
func set_quest_state(quest_id: StringName, state: String) -> void:
	set_quest_status(quest_id, state)


func get_quest_state(quest_id: StringName) -> String:
	var quest: Dictionary = quests.get(quest_id, {})
	return str(quest.get("status", "unknown"))


func _ensure_quest(quest_id: StringName) -> Dictionary:
	if not quests.has(quest_id):
		quests[quest_id] = {"status": "inactive", "objectives": {}}
	return quests[quest_id]


# --- Traps ----------------------------------------------------------------

func get_trap(trap_id: StringName) -> Dictionary:
	if not traps.has(trap_id):
		traps[trap_id] = {"state": "dormant", "iterations": 0, "resolution": ""}
	return traps[trap_id]


func set_trap(trap_id: StringName, data: Dictionary) -> void:
	traps[trap_id] = data


func get_trap_state(trap_id: StringName) -> String:
	return str(get_trap(trap_id).get("state", "dormant"))


func get_trap_iterations(trap_id: StringName) -> int:
	return int(get_trap(trap_id).get("iterations", 0))


func get_trap_resolution(trap_id: StringName) -> String:
	return str(get_trap(trap_id).get("resolution", ""))


# --- Magic resource -------------------------------------------------------

func get_magic_focus() -> int:
	return magic_focus


func add_magic_focus(delta: int) -> int:
	magic_focus = clampi(magic_focus + delta, 0, MAGIC_FOCUS_MAX)
	return magic_focus


func spend_magic_focus(cost: int) -> bool:
	if cost <= 0:
		return true
	if magic_focus < cost:
		return false
	magic_focus -= cost
	return true


# --- Location -------------------------------------------------------------

func visit_location(location_id: StringName) -> void:
	current_location = location_id
	visited_locations[location_id] = true


# --- Serialization --------------------------------------------------------

func to_dict() -> Dictionary:
	var characters := {}
	for key in character_states:
		characters[String(key)] = (character_states[key] as CharacterState).to_dict()

	var flags := {}
	for key in story_flags:
		flags[String(key)] = story_flags[key]

	var quests_out := {}
	for key in quests:
		var quest: Dictionary = quests[key]
		var objectives := {}
		for objective_key in quest.get("objectives", {}):
			objectives[String(objective_key)] = bool(quest["objectives"][objective_key])
		quests_out[String(key)] = {"status": str(quest.get("status", "inactive")), "objectives": objectives}

	var visited := {}
	for key in visited_locations:
		visited[String(key)] = true

	var traps_out := {}
	for key in traps:
		var trap: Dictionary = traps[key]
		traps_out[String(key)] = {
			"state": str(trap.get("state", "dormant")),
			"iterations": int(trap.get("iterations", 0)),
			"resolution": str(trap.get("resolution", "")),
		}

	return {
		"timeline_id": timeline_id,
		"current_location": String(current_location),
		"characters": characters,
		"story_flags": flags,
		"quests": quests_out,
		"traps": traps_out,
		"visited_locations": visited,
		"magic_focus": magic_focus,
	}


static func from_dict(data: Dictionary) -> TimelineState:
	var state := TimelineState.new()
	if data.has("timeline_id"):
		state.timeline_id = str(data["timeline_id"])

	state.current_location = StringName(str(data.get("current_location", DEFAULT_LOCATION)))

	# Characters (v2) with a v1 "relationships" fallback.
	if data.has("characters") and typeof(data["characters"]) == TYPE_DICTIONARY:
		for key in data["characters"]:
			state.character_states[StringName(key)] = CharacterState.from_dict(StringName(key), data["characters"][key])
	elif data.has("relationships") and typeof(data["relationships"]) == TYPE_DICTIONARY:
		for key in data["relationships"]:
			var legacy := {"attributes": data["relationships"][key], "met": true}
			state.character_states[StringName(key)] = CharacterState.from_dict(StringName(key), legacy)

	var flags: Dictionary = data.get("story_flags", {})
	for key in flags:
		state.story_flags[StringName(key)] = flags[key]

	# Quests (v2) with a v1 "quest_state" (bare status) fallback.
	if data.has("quests") and typeof(data["quests"]) == TYPE_DICTIONARY:
		for key in data["quests"]:
			var quest: Dictionary = data["quests"][key]
			var objectives := {}
			for objective_key in quest.get("objectives", {}):
				objectives[StringName(objective_key)] = bool(quest["objectives"][objective_key])
			state.quests[StringName(key)] = {
				"status": str(quest.get("status", "inactive")),
				"objectives": objectives,
			}
	elif data.has("quest_state") and typeof(data["quest_state"]) == TYPE_DICTIONARY:
		for key in data["quest_state"]:
			state.quests[StringName(key)] = {"status": str(data["quest_state"][key]), "objectives": {}}

	var visited: Dictionary = data.get("visited_locations", {})
	for key in visited:
		state.visited_locations[StringName(key)] = true

	if data.has("traps") and typeof(data["traps"]) == TYPE_DICTIONARY:
		for key in data["traps"]:
			var trap: Dictionary = data["traps"][key]
			state.traps[StringName(key)] = {
				"state": str(trap.get("state", "dormant")),
				"iterations": int(trap.get("iterations", 0)),
				"resolution": str(trap.get("resolution", "")),
			}

	state.magic_focus = clampi(int(data.get("magic_focus", MAGIC_FOCUS_START)), 0, MAGIC_FOCUS_MAX)

	return state
