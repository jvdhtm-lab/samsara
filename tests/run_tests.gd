extends Node
## Headless test runner (scene-based).
##
## Run with:
##   godot --headless --path . res://tests/test_runner.tscn
##
## Covers: domain rules, dialogue logic, persistence/restart isolation, and
## authored-content validation.

const TestCaseScript := preload("res://tests/framework.gd")

const CHARACTER_PATHS := [
	"res://resources/characters/lumi.tres",
	"res://resources/characters/pip.tres",
	"res://resources/characters/momo.tres",
	"res://resources/characters/fern.tres",
	"res://resources/characters/player.tres",
]

const DIALOGUE_IDS := ["lumi_intro", "pip_intro", "momo_intro", "picnic_loop", "fern_intro"]
const QUEST_IDS := ["pip_device", "lumi_story", "momo_picnic", "fern_hollow"]

const TEST_DIR := "user://tests"
const TEST_SLOT := "user://tests/slot.json"
const TEST_BACKUP := "user://tests/slot.backup.json"
const TEST_TEMP := "user://tests/slot.tmp.json"
const TEST_ARCHIVE := "user://tests/slot.archived.json"
const TEST_SETTINGS := "user://tests/settings.json"
const TEST_SETTINGS_BACKUP := "user://tests/settings.backup.json"
const TEST_SETTINGS_TEMP := "user://tests/settings.tmp.json"

var t


func _ready() -> void:
	t = TestCaseScript.new()

	_test_timeline_relationships()
	_test_timeline_flag_and_quest()
	_test_timeline_serialization_roundtrip()
	_test_meta_progression_roundtrip()
	_test_restart_isolation()
	_test_dialogue_runner()
	_test_dialogue_routing()
	_test_dialogue_line_objects()
	_test_character_registry()
	_test_dialogue_validation()
	_test_dialogue_conditions()
	_test_character_state()
	_test_timeline_quests()
	_test_timeline_migration()
	_test_migration_manager()
	_test_quest_manager()
	_test_quest_content()
	_test_relationship_reactions()
	_test_quest_integration()
	_test_new_timeline_initializer()
	_test_isolation_detects_leak()
	_test_game_begin_new_timeline()
	_test_save_load_via_manager()
	_test_clear_slot()
	_test_trap_machine()
	_test_timeline_traps()
	_test_trap_effects()
	_test_picnic_content()
	await _test_picnic_scene()
	await _test_hollow_scene()
	_test_meta_narrative_stages()
	_test_narrative_director()
	_test_restart_archive()
	_test_restart_flow()
	_test_timeline_focus()
	_test_magic_library()
	_test_magic_manager()
	_test_magic_trap_integration()
	_test_magic_unlock()
	_test_context_ability()
	_test_memory_echo_ability()
	_test_meta_flags()
	_test_trap_clue_and_exit()
	_test_secret_find()
	_test_journal()
	_test_fern_alt_timeline_dialogue()
	_test_expansion_path()
	await _test_journal_scene()
	_test_settings_persistence()
	_test_audio_catalog()
	_test_controller_mappings()
	_test_reduce_motion_transition()
	await _test_settings_menu()
	await _test_dialogue_typewriter()
	_test_timeline_variation()
	await _test_world3d_builds()
	await _test_world3d_toggle()
	_test_model_library()
	_test_character_models()
	_test_timeline_ending_conditions()
	_test_epilogue_lines()
	_test_record_completion()
	_test_ending_valid_path()
	await _test_ending_scene()
	_test_save_schema_validation()
	_test_save_storage_roundtrip()
	_test_backup_recovery()
	_test_character_content()
	_test_dialogue_content()
	_test_character_animation_content()
	_test_silhouette_uniqueness()
	await _test_dialogue_integration()
	await _test_character_rig()
	_test_interaction_priority()
	_test_door_lock()
	_test_text_interactable()
	_test_spawn_transition()
	await _test_area_spawn_placement()
	await _test_world_scenes_load()

	print("")
	print("Tests complete: %d passed, %d failed" % [t.passed, t.failed])
	_cleanup()
	AudioManager.shutdown_audio()
	await get_tree().process_frame
	await get_tree().process_frame
	# Let the audio server release stopped playbacks before the process exits.
	OS.delay_msec(50)

	if t.failed > 0:
		for failure in t.failures:
			printerr("  - " + failure)
		get_tree().quit(1)
	else:
		get_tree().quit(0)


# --- Domain ----------------------------------------------------------------

func _test_timeline_relationships() -> void:
	t.section("Timeline: relationships")
	var state := TimelineState.new()
	t.equal(state.get_relationship(&"lumi", "trust"), 0, "fresh relationship starts at zero")
	t.equal(state.adjust_relationship(&"lumi", "trust", 2), 2, "adjust accumulates")
	t.equal(state.get_relationship(&"lumi", "trust"), 2, "adjust persists")
	t.equal(state.get_relationship(&"lumi", "affection"), 0, "attributes are independent")


func _test_timeline_flag_and_quest() -> void:
	t.section("Timeline: flags and quests")
	var state := TimelineState.new()
	state.set_flag(&"heard_humming", true)
	t.is_true(state.get_flag(&"heard_humming"), "flag round-trips")
	t.is_false(state.get_flag(&"missing", false), "missing flag returns default")
	state.set_quest_state(&"pip_device", "active")
	t.equal(state.get_quest_state(&"pip_device"), "active", "quest state stored")
	t.equal(state.get_quest_state(&"unknown"), "unknown", "unknown quest returns sentinel")


func _test_timeline_serialization_roundtrip() -> void:
	t.section("Timeline: serialization")
	var state := TimelineState.new()
	state.adjust_relationship(&"pip", "trust", 3)
	state.set_flag(&"pip_device_helped", true)
	state.set_quest_state(&"pip_device", "active")
	state.visit_location(&"village")
	var restored := TimelineState.from_dict(state.to_dict())
	t.equal(restored.timeline_id, state.timeline_id, "timeline id preserved")
	t.equal(restored.get_relationship(&"pip", "trust"), 3, "relationship preserved")
	t.is_true(restored.get_flag(&"pip_device_helped"), "flag preserved")
	t.equal(restored.get_quest_state(&"pip_device"), "active", "quest preserved")
	t.equal(String(restored.current_location), "village", "location preserved")


func _test_meta_progression_roundtrip() -> void:
	t.section("Meta: serialization")
	var meta := MetaProgression.new()
	meta.restart_count = 2
	meta.unlock_ability("temporal_pause")
	meta.record_anomaly("backward_clock")
	var restored := MetaProgression.from_dict(meta.to_dict())
	t.equal(restored.restart_count, 2, "restart count preserved")
	t.is_true(restored.has_ability("temporal_pause"), "ability preserved")
	t.is_true(restored.anomalies_seen.has("backward_clock"), "anomaly preserved")


func _test_restart_isolation() -> void:
	t.section("Restart: timeline isolation, meta survival")
	var meta := MetaProgression.new()
	meta.unlock_ability("memory_echo")

	var timeline := TimelineState.new()
	timeline.adjust_relationship(&"lumi", "trust", 5)
	timeline.set_flag(&"personal_secret", true)

	# A restart replaces timeline state but must preserve meta-progression.
	var old_id := timeline.timeline_id
	timeline = TimelineState.new()
	t.equal(timeline.get_relationship(&"lumi", "trust"), 0, "relationships reset on new timeline")
	t.is_false(timeline.get_flag(&"personal_secret", false), "timeline flags reset")
	t.check(timeline.timeline_id != old_id, "new timeline receives a new id")
	t.is_true(meta.has_ability("memory_echo"), "meta-progression survives restart")


# --- Dialogue --------------------------------------------------------------

func _test_dialogue_runner() -> void:
	t.section("Dialogue: runner flow")
	var definition := DialogueLibrary.load_definition(&"lumi_intro")
	t.check(not definition.is_empty(), "lumi_intro definition loads")
	var runner := DialogueRunner.new(definition)
	runner.resolve(TimelineState.new())
	t.equal(String(runner.speaker_id()), "lumi", "speaker id parsed")
	t.check(runner.current_text().length() > 0, "first line has text")
	t.is_true(runner.available_choices(TimelineState.new()).is_empty(), "no choices mid-line")
	runner.advance()
	t.check(runner.is_last_line(), "advanced to last line")
	var choices := runner.available_choices(TimelineState.new())
	t.equal(choices.size(), 2, "two choices at the end")
	runner.choose_entry(choices[0])
	t.equal(runner.node_key, "reassure", "choice navigates to next node")
	t.is_true(runner.available_choices(TimelineState.new()).is_empty(), "branch node offers no choices")


func _test_dialogue_routing() -> void:
	t.section("Dialogue: conditional routing")
	var definition := {
		"speaker": "lumi", "speaker_name": "Lumi", "start": "start",
		"nodes": {
			"start": {"routes": [
				{"condition": {"type": "flag", "flag": "trusted", "equals": true}, "next": "trusted"},
				{"next": "new"},
			]},
			"trusted": {"lines": ["I remember you."], "choices": []},
			"new": {"lines": ["Who are you?"], "choices": []},
		},
	}
	var timeline := TimelineState.new()
	var runner := DialogueRunner.new(definition)
	runner.resolve(timeline)
	t.equal(String(runner.node_key), "new", "default route taken when condition is false")
	timeline.set_flag(&"trusted", true)
	var runner2 := DialogueRunner.new(definition)
	runner2.resolve(timeline)
	t.equal(String(runner2.node_key), "trusted", "conditional route taken when flag is set")


func _test_dialogue_line_objects() -> void:
	t.section("Dialogue: line objects + node next")
	var definition := {
		"speaker": "pip", "speaker_name": "Pip", "start": "start",
		"nodes": {
			"start": {"lines": [{"text": "Hello.", "expression": "happy"}], "next": "after"},
			"after": {"lines": ["Bye."], "choices": []},
		},
	}
	var runner := DialogueRunner.new(definition)
	t.equal(runner.current_text(), "Hello.", "object line text read")
	t.equal(String(runner.current_expression()), "happy", "object line expression read")
	t.is_true(runner.advance(), "advance follows the node's next")
	t.equal(String(runner.node_key), "after", "moved to the next node")
	t.equal(runner.current_text(), "Bye.", "next node text read")


func _test_character_registry() -> void:
	t.section("Dialogue: character registry")
	var lumi := CharacterRegistry.get_character(&"lumi")
	t.check(lumi != null, "registry resolves lumi")
	if lumi != null:
		t.equal(String(lumi.id), "lumi", "registry id matches resource")
	t.check(CharacterRegistry.get_character(&"nobody") == null, "unknown id returns null")


func _test_dialogue_validation() -> void:
	t.section("Dialogue: validator")
	var known := _known_character_ids()
	var known_quests := _known_quest_objectives()
	for dialogue_id in DIALOGUE_IDS:
		var definition := DialogueLibrary.load_definition(dialogue_id)
		var errors := DialogueValidator.validate(definition, known, known_quests)
		t.check(errors.is_empty(), "valid dialogue '%s' (%s)" % [dialogue_id, ", ".join(errors)])

	var broken := {
		"speaker": "lumi", "speaker_name": "Lumi", "start": "start",
		"nodes": {"start": {"lines": ["hi"], "choices": [{"text": "go", "next": "missing"}]}},
	}
	t.check(DialogueValidator.validate(broken, known).size() > 0, "validator flags a dangling choice target")

	var bad_quest := {
		"speaker": "lumi", "speaker_name": "Lumi", "start": "start",
		"nodes": {"start": {"lines": ["hi"], "effects": [
			{"type": "quest", "quest": "lumi_story", "action": "objective", "objective": "nope"}
		]}},
	}
	t.check(DialogueValidator.validate(bad_quest, known, known_quests).size() > 0, "validator flags an unknown objective")


func _known_quest_objectives() -> Dictionary:
	var known := {}
	for quest_id in QUEST_IDS:
		var definition := QuestLibrary.load_definition(quest_id)
		var objectives := {}
		for objective in definition.get("objectives", []):
			objectives[str(objective.get("id", ""))] = true
		known[quest_id] = objectives
	return known


func _known_character_ids() -> Dictionary:
	var known := {}
	for path in CHARACTER_PATHS:
		var character := load(path) as CharacterData
		if character != null:
			known[String(character.id)] = true
	return known


func _test_dialogue_conditions() -> void:
	t.section("Dialogue: conditions")
	var timeline := TimelineState.new()
	t.is_true(DialogueConditions.evaluate(null, timeline), "empty condition passes")
	t.is_false(
		DialogueConditions.evaluate({"type": "flag", "flag": "x", "equals": true}, timeline),
		"unset flag fails"
	)
	timeline.set_flag(&"x", true)
	t.is_true(
		DialogueConditions.evaluate({"type": "flag", "flag": "x", "equals": true}, timeline),
		"set flag passes"
	)
	timeline.adjust_relationship(&"lumi", "trust", 2)
	t.is_true(
		DialogueConditions.evaluate({"type": "relationship", "character": "lumi", "attr": "trust", "min": 2}, timeline),
		"relationship minimum passes"
	)
	timeline.set_quest_status(&"q", "active")
	timeline.mark_objective(&"q", &"o")
	t.is_true(
		DialogueConditions.evaluate({"type": "objective", "quest": "q", "objective": "o", "done": true}, timeline),
		"objective condition passes"
	)
	t.is_false(
		DialogueConditions.evaluate({"type": "objective", "quest": "q", "objective": "missing", "done": true}, timeline),
		"missing objective condition fails"
	)
	t.is_true(
		DialogueConditions.evaluate({"type": "quest_status", "quest": "q", "equals": "active"}, timeline),
		"quest status condition passes"
	)


# --- Relationships / quests ------------------------------------------------

func _test_character_state() -> void:
	t.section("Characters: state")
	var state := CharacterState.new(&"lumi")
	t.equal(state.get_attribute("trust"), 0, "default trust")
	state.adjust_attribute("trust", 3)
	t.equal(state.get_attribute("trust"), 3, "adjust accumulates")
	state.set_flag(&"greeted", true)
	t.is_true(state.get_flag(&"greeted"), "character flag set")
	t.equal(state.relationship_level(), CharacterState.LEVEL_FRIEND, "friend at score 3")
	state.adjust_attribute("suspicion", 5)
	t.equal(state.relationship_level(), CharacterState.LEVEL_WARY, "wary when score is negative")

	var restored := CharacterState.from_dict(&"lumi", state.to_dict())
	t.equal(restored.get_attribute("trust"), 3, "roundtrip attributes")
	t.is_true(restored.get_flag(&"greeted"), "roundtrip flags")

	var legacy := CharacterState.from_dict(&"pip", {"trust": 1, "affection": 2, "suspicion": 0})
	t.equal(legacy.get_attribute("affection"), 2, "v1 bare attribute map read")


func _test_timeline_quests() -> void:
	t.section("Quests: timeline state")
	var timeline := TimelineState.new()
	t.equal(timeline.get_quest_status(&"nope"), "inactive", "default status inactive")
	timeline.set_quest_status(&"q", "active")
	timeline.mark_objective(&"q", &"o1")
	t.equal(timeline.get_quest_status(&"q"), "active", "status stored")
	t.is_true(timeline.is_objective_complete(&"q", &"o1"), "objective stored")
	t.is_false(timeline.is_objective_complete(&"q", &"o2"), "missing objective false")

	var restored := TimelineState.from_dict(timeline.to_dict())
	t.equal(restored.get_quest_status(&"q"), "active", "roundtrip status")
	t.is_true(restored.is_objective_complete(&"q", &"o1"), "roundtrip objective")


func _test_timeline_migration() -> void:
	t.section("Quests: legacy state read")
	var legacy := {
		"timeline_id": "old",
		"current_location": "village",
		"relationships": {"lumi": {"trust": 4, "affection": 0, "suspicion": 0}},
		"story_flags": {},
		"quest_state": {"pip_device": "active"},
		"visited_locations": {},
	}
	var state := TimelineState.from_dict(legacy)
	t.equal(state.get_relationship(&"lumi", "trust"), 4, "legacy relationship read")
	t.equal(state.get_quest_status(&"pip_device"), "active", "legacy quest status read")


func _test_migration_manager() -> void:
	t.section("Quests: save migration v1 -> v2")
	var v1 := {
		"version": 1,
		"timeline": {"relationships": {"lumi": {"trust": 1}}, "quest_state": {"pip_device": "active"}},
		"meta": {},
		"settings": {},
	}
	var migrated := MigrationManager.migrate(v1)
	t.equal(int(migrated.get("version")), SaveSchema.CURRENT_VERSION, "version bumped to current")
	t.is_true(migrated["timeline"].has("characters"), "characters key added")
	t.is_true(migrated["timeline"].has("quests"), "quests key added")
	t.is_false(migrated["timeline"].has("relationships"), "legacy relationships removed")
	t.is_true(SaveSchema.validate(migrated), "migrated payload validates")


func _test_quest_manager() -> void:
	t.section("Quests: manager transitions")
	var timeline := TimelineState.new()
	t.is_false(QuestManager.complete_objective(timeline, &"pip_device", &"talk_pip"), "objective ignored before start")
	t.is_true(QuestManager.start_quest(timeline, &"pip_device"), "start returns true")
	t.is_false(QuestManager.start_quest(timeline, &"pip_device"), "double start returns false")
	t.is_false(QuestManager.start_quest(timeline, &"nope"), "unknown quest returns false")

	t.is_false(QuestManager.complete_objective(timeline, &"pip_device", &"talk_pip"), "partial objective does not complete")
	t.is_false(QuestManager.complete_objective(timeline, &"pip_device", &"talk_pip"), "duplicate objective returns false")
	QuestManager.complete_objective(timeline, &"pip_device", &"examine_device")
	t.is_false(QuestManager.is_completed(timeline, &"pip_device"), "still incomplete")
	t.is_true(QuestManager.complete_objective(timeline, &"pip_device", &"return_pip"), "final objective completes quest")
	t.is_true(QuestManager.is_completed(timeline, &"pip_device"), "quest completed")

	var progress := QuestManager.progress(timeline, &"pip_device")
	t.equal(progress["done"], 3, "progress done count")
	t.equal(progress["total"], 3, "progress total count")
	t.is_true(QuestManager.fail_quest(timeline, &"lumi_story"), "fail transitions an inactive quest")


func _test_quest_content() -> void:
	t.section("Quests: content")
	for quest_id in QUEST_IDS:
		var definition := QuestLibrary.load_definition(quest_id)
		t.check(not definition.is_empty(), "loads quest '%s'" % quest_id)
		if definition.is_empty():
			continue
		t.check(str(definition.get("title", "")) != "", "quest has a title '%s'" % quest_id)
		t.check(CharacterRegistry.has(StringName(str(definition.get("giver", "")))), "giver is a known character '%s'" % quest_id)

		var objectives: Array = definition.get("objectives", [])
		t.check(objectives.size() > 0, "quest has objectives '%s'" % quest_id)
		var seen := {}
		for objective in objectives:
			var objective_id := str(objective.get("id", ""))
			t.check(objective_id != "" and not seen.has(objective_id), "objective id unique in '%s'" % quest_id)
			seen[objective_id] = true

		for reward in definition.get("rewards", []):
			t.check(DialogueValidator.EFFECT_TYPES.has(str(reward.get("type", ""))), "reward type valid in '%s'" % quest_id)


func _test_relationship_reactions() -> void:
	t.section("Relationships: reactions")
	var timeline := TimelineState.new()
	t.equal(RelationshipManager.reaction_expression(timeline, &"lumi"), &"neutral", "neutral by default")
	timeline.adjust_relationship(&"lumi", "trust", 6)
	t.equal(RelationshipManager.reaction_expression(timeline, &"lumi"), &"happy", "happy when confidant")
	timeline.adjust_relationship(&"momo", "suspicion", 2)
	t.equal(RelationshipManager.reaction_expression(timeline, &"momo"), &"afraid", "afraid when suspicious")
	t.equal(RelationshipManager.level(timeline, &"lumi"), CharacterState.LEVEL_CONFIDANT, "level exposed")


func _test_quest_integration() -> void:
	t.section("Quests: end-to-end completion")
	Game.timeline = TimelineState.new()
	Game.meta = MetaProgression.new()

	Game.apply_effects([{"type": "quest", "quest": "pip_device", "action": "start"}])
	t.is_true(QuestManager.is_active(Game.timeline, &"pip_device"), "quest active after start")

	Game.apply_effects([{"type": "quest", "quest": "pip_device", "action": "objective", "objective": "talk_pip"}])
	Game.apply_effects([{"type": "quest", "quest": "pip_device", "action": "objective", "objective": "examine_device"}])
	t.is_false(QuestManager.is_completed(Game.timeline, &"pip_device"), "not complete before final objective")

	Game.apply_effects([{"type": "quest", "quest": "pip_device", "action": "objective", "objective": "return_pip"}])
	t.is_true(QuestManager.is_completed(Game.timeline, &"pip_device"), "quest completes on final objective")
	t.equal(Game.timeline.get_relationship(&"pip", "trust"), 1, "reward applied once")
	t.is_true(Game.timeline.get_flag(&"pip_quest_done", false), "consequence flag applied")

	# Re-completing must not grant the reward twice.
	Game.apply_effects([{"type": "quest", "quest": "pip_device", "action": "objective", "objective": "return_pip"}])
	t.equal(Game.timeline.get_relationship(&"pip", "trust"), 1, "reward not re-granted")


# --- Timeline lifecycle / save manager ------------------------------------

func _test_new_timeline_initializer() -> void:
	t.section("Timeline: initializer + isolation")
	var previous := TimelineState.new()
	previous.adjust_relationship(&"lumi", "trust", 5)
	previous.set_flag(&"x", true)
	previous.set_quest_status(&"pip_device", "completed")
	previous.visit_location(&"village")

	var fresh := TimelineInitializer.build()
	t.check(fresh.timeline_id != previous.timeline_id, "fresh timeline has a new id")
	var errors := TimelineInitializer.verify_isolation(previous.timeline_id, fresh)
	t.check(errors.is_empty(), "clean timeline passes isolation (%s)" % ", ".join(errors))
	t.is_true(fresh.character_states.is_empty(), "no character state carried over")
	t.is_true(fresh.quests.is_empty(), "no quest state carried over")
	t.is_true(fresh.story_flags.is_empty(), "no story flags carried over")
	t.is_true(fresh.visited_locations.is_empty(), "no visited locations carried over")


func _test_isolation_detects_leak() -> void:
	t.section("Timeline: isolation detects leaks")
	var previous := TimelineState.new()
	var leaky := TimelineState.new()
	leaky.adjust_relationship(&"lumi", "trust", 1)
	var errors := TimelineInitializer.verify_isolation(previous.timeline_id, leaky)
	t.check(errors.size() > 0, "leaked character state is detected")
	t.is_true(errors.any(func(message): return message.contains("character state")), "leak message names character state")


func _test_game_begin_new_timeline() -> void:
	t.section("Timeline: Game.begin_new_timeline")
	Game.timeline = TimelineState.new()
	Game.timeline.adjust_relationship(&"lumi", "trust", 4)
	Game.timeline.set_flag(&"secret", true)
	Game.meta = MetaProgression.new()
	Game.meta.unlock_ability("memory_echo")
	Game.settings.reduce_motion = true
	var restarts := Game.meta.restart_count

	var errors := Game.begin_new_timeline()
	t.check(errors.is_empty(), "begin_new_timeline reports clean isolation")
	t.equal(Game.timeline.get_relationship(&"lumi", "trust"), 0, "relationships reset")
	t.is_false(Game.timeline.get_flag(&"secret", false), "flags reset")
	t.equal(Game.meta.restart_count, restarts + 1, "restart count incremented")
	t.is_true(Game.meta.has_ability("memory_echo"), "meta-progression survives")
	t.is_true(Game.settings.reduce_motion, "settings survive")
	t.equal(Game.meta.last_outcome, "clean", "outcome recorded")


func _test_save_load_via_manager() -> void:
	t.section("Save: manager roundtrip during play")
	Game.timeline = TimelineState.new()
	Game.timeline.adjust_relationship(&"pip", "trust", 2)
	Game.timeline.set_flag(&"heard_humming", true)
	Game.timeline.set_quest_status(&"pip_device", "active")
	Game.timeline.mark_objective(&"pip_device", &"talk_pip")
	Game.meta = MetaProgression.new()
	Game.meta.unlock_ability("temporal_pause")
	Game.settings = ApplicationSettings.new()
	Game.settings.master_volume = 0.33
	var saved_id := Game.timeline.timeline_id

	t.is_true(SaveManager.save_game(TEST_SLOT, TEST_BACKUP, TEST_TEMP), "save_game succeeds")

	Game.timeline = TimelineState.new()
	Game.meta = MetaProgression.new()
	Game.settings = ApplicationSettings.new()

	t.is_true(SaveManager.load_game(TEST_SLOT, TEST_BACKUP), "load_game succeeds")
	t.equal(Game.timeline.timeline_id, saved_id, "timeline id restored")
	t.equal(Game.timeline.get_relationship(&"pip", "trust"), 2, "relationship restored")
	t.is_true(Game.timeline.get_flag(&"heard_humming"), "flag restored")
	t.equal(Game.timeline.get_quest_status(&"pip_device"), "active", "quest status restored")
	t.is_true(Game.timeline.is_objective_complete(&"pip_device", &"talk_pip"), "objective restored")
	t.is_true(Game.meta.has_ability("temporal_pause"), "meta restored")
	t.equal(Game.settings.master_volume, 0.33, "settings restored")

	SaveManager.clear_slot(TEST_SLOT, TEST_BACKUP, TEST_TEMP)


func _test_clear_slot() -> void:
	t.section("Save: clear slot")
	SaveManager.save_game(TEST_SLOT, TEST_BACKUP, TEST_TEMP)
	t.is_true(FileAccess.file_exists(TEST_SLOT), "slot exists before clear")
	SaveManager.clear_slot(TEST_SLOT, TEST_BACKUP, TEST_TEMP)
	t.is_false(FileAccess.file_exists(TEST_SLOT), "slot removed after clear")


# --- Persistence -----------------------------------------------------------

func _test_save_schema_validation() -> void:
	t.section("Persistence: schema validation")
	t.is_false(SaveSchema.validate(null), "null rejected")
	t.is_false(SaveSchema.validate([]), "array rejected")
	t.is_false(SaveSchema.validate({}), "missing keys rejected")
	var good := {
		"version": SaveSchema.CURRENT_VERSION,
		"timeline": {},
		"meta": {},
		"settings": {},
	}
	t.is_true(SaveSchema.validate(good), "valid payload accepted")
	var future := good.duplicate()
	future["version"] = SaveSchema.CURRENT_VERSION + 1
	t.is_false(SaveSchema.validate(future), "future version rejected")


func _test_save_storage_roundtrip() -> void:
	t.section("Persistence: atomic write + read")
	var timeline := TimelineState.new()
	timeline.set_flag(&"saved", true)
	var data := {
		"version": SaveSchema.CURRENT_VERSION,
		"timeline": timeline.to_dict(),
		"meta": MetaProgression.new().to_dict(),
		"settings": ApplicationSettings.new().to_dict(),
	}
	t.is_true(SaveStorage.write_atomic(TEST_SLOT, TEST_BACKUP, TEST_TEMP, data), "write succeeds")
	var result := SaveStorage.read_first_valid([TEST_SLOT, TEST_BACKUP], _is_valid)
	t.is_true(result.get("ok", false), "written save reads back as valid")
	if result.get("ok", false):
		var loaded := TimelineState.from_dict(result["data"]["timeline"])
		t.is_true(loaded.get_flag(&"saved", false), "flag survives file round-trip")


func _test_backup_recovery() -> void:
	t.section("Persistence: recovery from corrupt slot")
	# Write a valid save (creating a backup on the second write), then corrupt
	# the primary slot and confirm the backup is used.
	var first := _payload("first")
	var second := _payload("second")
	SaveStorage.write_atomic(TEST_SLOT, TEST_BACKUP, TEST_TEMP, first)
	SaveStorage.write_atomic(TEST_SLOT, TEST_BACKUP, TEST_TEMP, second)

	var file := FileAccess.open(TEST_SLOT, FileAccess.WRITE)
	file.store_string("{ this is not valid json")
	file.close()

	var result := SaveStorage.read_first_valid([TEST_SLOT, TEST_BACKUP], _is_valid)
	t.is_true(result.get("ok", false), "backup used when slot is corrupt")
	if result.get("ok", false):
		var loaded := TimelineState.from_dict(result["data"]["timeline"])
		t.is_true(loaded.get_flag(&"first", false), "backup contains the previous valid save")


# --- Content validation ----------------------------------------------------

func _test_character_content() -> void:
	t.section("Content: character resources")
	var ids := {}
	for path in CHARACTER_PATHS:
		var character := load(path) as CharacterData
		t.check(character != null, "loads character resource '%s'" % path)
		if character == null:
			continue
		t.check(String(character.id).length() > 0, "character has id (%s)" % path)
		t.check(character.display_name.length() > 0, "character has display name (%s)" % path)
		t.check(character.body_radius > 0.0, "character has radius (%s)" % path)
		t.check(not ids.has(String(character.id)), "character id is unique (%s)" % character.id)
		ids[String(character.id)] = true


func _test_dialogue_content() -> void:
	t.section("Content: dialogue definitions")
	var character_ids := {}
	for path in CHARACTER_PATHS:
		var character := load(path) as CharacterData
		if character != null:
			character_ids[String(character.id)] = true

	for dialogue_id in DIALOGUE_IDS:
		var definition := DialogueLibrary.load_definition(dialogue_id)
		t.check(not definition.is_empty(), "loads dialogue '%s'" % dialogue_id)
		if definition.is_empty():
			continue
		var nodes: Dictionary = definition.get("nodes", {})
		t.check(nodes.has(str(definition.get("start", "start"))), "'%s' start node exists" % dialogue_id)
		t.check(character_ids.has(String(definition.get("speaker", ""))), "'%s' speaker is a known character" % dialogue_id)
		for node_key in nodes:
			var node: Dictionary = nodes[node_key]
			for choice in node.get("choices", []):
				var next := str(choice.get("next", ""))
				t.check(next == "" or nodes.has(next), "'%s' choice next '%s' resolves" % [dialogue_id, next])
				for effect in choice.get("effects", []):
					if str(effect.get("type", "")) == "relationship":
						t.check(
							character_ids.has(str(effect.get("character", ""))),
							"'%s' effect targets known character" % dialogue_id
						)


# --- Integration -----------------------------------------------------------

func _test_character_animation_content() -> void:
	t.section("Content: character animation data")
	for path in CHARACTER_PATHS:
		var character := load(path) as CharacterData
		if character == null:
			continue
		t.check(
			character.idle_motion == &"idle" or character.idle_motion == &"uncanny_idle",
			"valid idle_motion for '%s'" % character.id
		)


func _test_silhouette_uniqueness() -> void:
	t.section("Content: silhouette + palette uniqueness")
	var signatures := {}
	var hues: Array[float] = []
	var ids: Array[String] = []
	for path in CHARACTER_PATHS:
		var character := load(path) as CharacterData
		if character == null:
			continue
		var signature := "%d|%d|%d|%d|%.0f" % [
			character.silhouette, character.accessory, character.marking,
			character.eye_shape, character.body_radius,
		]
		t.check(not signatures.has(signature), "silhouette signature is unique for '%s'" % character.id)
		signatures[signature] = true
		hues.append(character.body_color.h)
		ids.append(String(character.id))

	for i in range(hues.size()):
		for j in range(i + 1, hues.size()):
			var distance := absf(hues[i] - hues[j])
			distance = minf(distance, 1.0 - distance)
			t.check(distance > 0.05, "palette hue distinct: %s vs %s" % [ids[i], ids[j]])


func _test_character_rig() -> void:
	t.section("Rig: layers, motion, expression, talk")
	Game.settings.reduce_motion = false
	for path in CHARACTER_PATHS:
		var character := load(path) as CharacterData
		if character == null:
			continue
		var npc: Variant = load("res://scenes/characters/character_base.tscn").instantiate()
		npc.data = character
		add_child(npc)
		await get_tree().process_frame

		var rig := npc.get_node_or_null("Visual") as CharacterRig
		t.check(rig != null, "rig exists for '%s'" % character.id)
		if rig == null:
			npc.queue_free()
			await get_tree().process_frame
			continue

		t.check(rig._layers.size() >= 7, "all layers present for '%s'" % character.id)

		rig.set_motion(&"walk")
		rig.tick(0.2)
		t.check(rig.body_offset.length() > 0.1, "walk animates body for '%s'" % character.id)

		rig.set_expression(&"afraid")
		rig.tick(0.001)
		t.check(rig.eye_open > 1.2, "afraid widens eyes for '%s'" % character.id)

		rig.set_expression(&"neutral")
		rig.set_talking(true)
		var max_mouth := 0.0
		for i in range(24):
			rig.tick(0.05)
			max_mouth = maxf(max_mouth, rig.mouth_open)
		t.check(max_mouth > 0.7, "talking animates the mouth for '%s'" % character.id)

		rig.set_facing(-1.0)
		t.check(rig.facing < 0.0, "facing follows direction for '%s'" % character.id)

		npc.queue_free()
		await get_tree().process_frame


func _test_dialogue_integration() -> void:
	t.section("Integration: dialogue changes state")
	Game.timeline = TimelineState.new()

	var events: Array = []
	var listener: Callable = func(character_id, attribute, value, delta):
		events.append({"character": character_id, "attr": attribute, "value": value, "delta": delta})
	EventBus.relationship_changed.connect(listener)

	var box: Node = load("res://scenes/dialogue/dialogue_box.tscn").instantiate()
	add_child(box)
	await get_tree().process_frame

	Game.start_dialogue(&"lumi", &"lumi_intro")
	await get_tree().process_frame
	t.is_true(Game.in_dialogue, "game reports an active dialogue")
	t.is_true(box._active, "dialogue box is active")
	t.is_true(box._portrait_root.visible, "portrait shown for lumi")
	if box._portrait_rig != null:
		t.equal(String(box._portrait_rig.data.id), "lumi", "portrait uses the speaker's data")
		t.is_true(box._runner.current_text().length() > 0, "resolved past the routing node")

	box._advance()          # first line -> choice line
	box._confirm_choice()   # pick the supportive choice
	var guard := 0
	while Game.in_dialogue and guard < 20:
		guard += 1
		box._advance()
	await get_tree().process_frame

	t.equal(Game.timeline.get_relationship(&"lumi", "trust"), 1, "choice raised Lumi trust")
	t.equal(Game.timeline.get_relationship(&"lumi", "suspicion"), 0, "other attributes untouched")
	t.is_true(Game.timeline.get_flag(&"heard_humming", false), "choice set the story flag")
	t.is_true(Game.timeline.get_flag(&"lumi_trusted", false), "routing node set the follow-up flag")
	t.is_false(Game.in_dialogue, "dialogue closed after the last line")
	t.equal(events.size(), 1, "one relationship_changed signal emitted")

	EventBus.relationship_changed.disconnect(listener)
	box.queue_free()
	await get_tree().process_frame


# --- Traps / picnic --------------------------------------------------------

func _test_trap_machine() -> void:
	t.section("Traps: state machine")
	var timeline := TimelineState.new()
	t.equal(TrapMachine.state_of(timeline, &"t"), TrapMachine.DORMANT, "dormant initially")
	t.is_true(TrapMachine.enter(timeline, &"t"), "enter returns true")
	t.is_false(TrapMachine.enter(timeline, &"t"), "enter twice returns false")
	t.equal(TrapMachine.advance(timeline, &"t"), 1, "advance returns 1")
	t.equal(TrapMachine.advance(timeline, &"t"), 2, "advance returns 2")
	t.is_true(TrapMachine.discover(timeline, &"t"), "discover returns true")
	t.is_false(TrapMachine.discover(timeline, &"t"), "discover twice returns false")
	t.is_true(TrapMachine.resolve(timeline, &"t", &"refused"), "resolve returns true")
	t.is_true(TrapMachine.is_resolved(timeline, &"t"), "trap is resolved")
	t.is_false(TrapMachine.resolve(timeline, &"t", &"again"), "resolve twice returns false")
	t.is_false(TrapMachine.enter(timeline, &"t"), "cannot re-enter a resolved trap")
	t.equal(timeline.get_trap_resolution(&"t"), "refused", "resolution stored")


func _test_timeline_traps() -> void:
	t.section("Traps: timeline serialization")
	var timeline := TimelineState.new()
	TrapMachine.enter(timeline, &"endless_picnic")
	TrapMachine.advance(timeline, &"endless_picnic")
	TrapMachine.resolve(timeline, &"endless_picnic", &"walked_away")

	var restored := TimelineState.from_dict(timeline.to_dict())
	t.equal(restored.get_trap_state(&"endless_picnic"), "resolved", "trap state roundtrip")
	t.equal(restored.get_trap_iterations(&"endless_picnic"), 1, "iterations roundtrip")
	t.equal(restored.get_trap_resolution(&"endless_picnic"), "walked_away", "resolution roundtrip")


func _test_trap_effects() -> void:
	t.section("Traps: effects + repeated entry")
	Game.timeline = TimelineState.new()
	Game.meta = MetaProgression.new()

	Game.apply_effects([{"type": "trap", "trap": "endless_picnic", "action": "enter"}])
	t.equal(Game.timeline.get_trap_state(&"endless_picnic"), "active", "enter via effect")
	Game.apply_effects([{"type": "trap", "trap": "endless_picnic", "action": "advance"}])
	t.equal(Game.timeline.get_trap_iterations(&"endless_picnic"), 1, "advance via effect")
	Game.apply_effects([
		{"type": "trap", "trap": "endless_picnic", "action": "discover"},
		{"type": "flag", "flag": "picnic_rule_known", "value": true},
	])
	t.equal(Game.timeline.get_trap_state(&"endless_picnic"), "discovered", "discover via effect")
	t.is_true(Game.timeline.get_flag(&"picnic_rule_known"), "discovery flag set")

	Game.apply_effects([{"type": "trap", "trap": "endless_picnic", "action": "resolve", "resolution": "refused"}])
	t.is_true(TrapMachine.is_resolved(Game.timeline, &"endless_picnic"), "resolve via effect")
	t.equal(Game.timeline.get_trap_resolution(&"endless_picnic"), "refused", "resolution recorded")

	Game.apply_effects([{"type": "trap", "trap": "endless_picnic", "action": "enter"}])
	t.equal(Game.timeline.get_trap_state(&"endless_picnic"), "resolved", "resolved trap does not re-activate")


func _test_picnic_content() -> void:
	t.section("Traps: picnic content")
	var definition := DialogueLibrary.load_definition(&"picnic_loop")
	t.check(not definition.is_empty(), "picnic_loop loads")
	var errors := DialogueValidator.validate(definition, _known_character_ids(), _known_quest_objectives())
	t.check(errors.is_empty(), "picnic_loop validates (%s)" % ", ".join(errors))

	var resolutions: Array = []
	var nodes: Dictionary = definition.get("nodes", {})
	for node_key in nodes:
		for choice in nodes[node_key].get("choices", []):
			for effect in choice.get("effects", []):
				if str(effect.get("type", "")) == "trap" and str(effect.get("action", "")) == "resolve":
					resolutions.append(str(effect.get("resolution", "")))
	t.check(resolutions.has("walked_away"), "dialogue offers the walked_away escape")
	t.check(resolutions.has("refused"), "dialogue offers the refused escape")


func _test_picnic_scene() -> void:
	t.section("Traps: picnic scene instantiates")
	Game.timeline = TimelineState.new()
	var picnic: Variant = load("res://scenes/puzzles/endless_picnic.tscn").instantiate()
	add_child(picnic)
	await get_tree().process_frame
	t.equal(String(picnic.trap_id), "endless_picnic", "scene carries the trap id")
	t.check(picnic.get_node_or_null("Background") != null, "picnic background present")
	t.check(picnic.get_node_or_null("TeaSet") != null, "tea set clue present")
	t.check(picnic.get_node_or_null("GardenEdge") != null, "garden edge exit present")
	t.check(picnic.get_node_or_null("Player") != null, "player present")
	picnic.queue_free()
	await get_tree().process_frame
	Game.in_dialogue = false


# --- Meta-narrative / restart ---------------------------------------------

func _test_meta_narrative_stages() -> void:
	t.section("Meta-narrative: stages")
	var timeline := TimelineState.new()
	var meta := MetaProgression.new()
	t.equal(MetaNarrative.stage(timeline, meta), 0, "stage 0 with no progress")
	t.equal(MetaNarrative.stage_name(0), "Comfort", "stage 0 name")
	t.equal(MetaNarrative.stage_name(5), "Resolution", "stage 5 name")

	timeline.set_quest_status(&"pip_device", "completed")
	t.check(MetaNarrative.stage(timeline, meta) >= 1, "progress advances the stage")

	TrapMachine.enter(timeline, &"endless_picnic")
	TrapMachine.discover(timeline, &"endless_picnic")
	TrapMachine.resolve(timeline, &"endless_picnic", &"refused")
	timeline.set_quest_status(&"lumi_story", "completed")
	timeline.set_quest_status(&"momo_picnic", "completed")
	t.check(MetaNarrative.stage(timeline, meta) >= 4, "full progress reaches late stages")
	t.check(MetaNarrative.pressure(timeline, meta) > 0, "pressure is positive with progress")


func _test_narrative_director() -> void:
	t.section("Meta-narrative: director applies anomalies")
	Game.timeline = TimelineState.new()
	Game.meta = MetaProgression.new()
	Game.director.current_stage = 0

	Game.timeline.set_quest_status(&"pip_device", "completed")
	Game.timeline.set_quest_status(&"lumi_story", "completed")
	Game.director.recompute()

	t.check(Game.director.current_stage >= 3, "director advanced to Pressure or beyond")
	t.is_true(Game.timeline.get_flag(&"restart_offered", false), "stage anomaly set its flag")
	t.is_true(Game.meta.anomalies_seen.has("restart_whisper"), "stage anomaly recorded in meta")


func _test_restart_archive() -> void:
	t.section("Restart: archiving the current timeline")
	Game.timeline = TimelineState.new()
	Game.timeline.set_flag(&"archived_marker", true)
	Game.meta = MetaProgression.new()
	Game.settings = ApplicationSettings.new()
	t.is_true(SaveManager.save_game(TEST_SLOT, TEST_BACKUP, TEST_TEMP), "current save written")
	t.is_true(SaveManager.archive_current(TEST_SLOT, TEST_ARCHIVE, TEST_BACKUP), "archive copies the save")
	t.is_true(FileAccess.file_exists(TEST_ARCHIVE), "archive file exists")

	var parsed: Variant = SaveStorage.read_json(TEST_ARCHIVE)
	var had_marker := false
	if typeof(parsed) == TYPE_DICTIONARY:
		var flags: Dictionary = parsed["timeline"].get("story_flags", {})
		had_marker = flags.has("archived_marker")
	t.is_true(had_marker, "archive contains the timeline state")

	SaveManager.clear_slot(TEST_SLOT, TEST_BACKUP, TEST_TEMP)
	if FileAccess.file_exists(TEST_ARCHIVE):
		DirAccess.remove_absolute(TEST_ARCHIVE)


func _test_restart_flow() -> void:
	t.section("Restart: request -> cancel -> confirm")
	Game.timeline = TimelineState.new()
	Game.timeline.adjust_relationship(&"lumi", "trust", 3)
	Game.meta = MetaProgression.new()
	Game.meta.unlock_ability("temporal_pause")
	Game.settings.reduce_motion = true
	var old_id := Game.timeline.timeline_id

	Game.request_restart()
	t.is_true(Game.restart.is_open(), "restart confirmation opens")
	t.equal(Game.restart.state, RestartController.State.CONFIRMATION, "state is confirmation")

	Game.restart.cancel()
	t.is_false(Game.restart.is_open(), "cancel closes the confirmation")
	t.equal(Game.restart.state, RestartController.State.AVAILABLE, "state returns to available")
	t.equal(Game.timeline.timeline_id, old_id, "cancel does not reset the timeline")

	Game.request_restart()
	var ok := Game.restart.confirm(false, TEST_SLOT, TEST_BACKUP, TEST_TEMP, TEST_ARCHIVE)
	t.is_true(ok, "confirm completes with clean isolation")
	t.equal(Game.restart.state, RestartController.State.NEW_TIMELINE, "state is new timeline")
	t.check(Game.timeline.timeline_id != old_id, "timeline id regenerated")
	t.equal(Game.timeline.get_relationship(&"lumi", "trust"), 0, "timeline relationships reset")
	t.is_true(Game.meta.has_ability("temporal_pause"), "meta-progression survives restart")
	t.is_true(Game.settings.reduce_motion, "settings survive restart")

	SaveManager.clear_slot(TEST_SLOT, TEST_BACKUP, TEST_TEMP)
	if FileAccess.file_exists(TEST_ARCHIVE):
		DirAccess.remove_absolute(TEST_ARCHIVE)


# --- Magic -----------------------------------------------------------------

func _test_timeline_focus() -> void:
	t.section("Magic: focus resource")
	var timeline := TimelineState.new()
	t.equal(timeline.get_magic_focus(), TimelineState.MAGIC_FOCUS_START, "starts with focus")
	t.equal(timeline.add_magic_focus(5), TimelineState.MAGIC_FOCUS_MAX, "clamps to max")
	t.is_true(timeline.spend_magic_focus(1), "spend succeeds with focus")
	t.is_false(timeline.spend_magic_focus(99), "spend fails when insufficient")
	var restored := TimelineState.from_dict(timeline.to_dict())
	t.equal(restored.get_magic_focus(), timeline.get_magic_focus(), "focus round-trips")


func _test_magic_library() -> void:
	t.section("Magic: ability library")
	var definition := MagicLibrary.load_definition(&"temporal_pause")
	t.check(not definition.is_empty(), "temporal_pause loads")
	t.equal(int(definition.get("cost", 0)), 1, "ability declares a cost")
	t.check((definition.get("effects", []) as Array).size() > 0, "ability declares effects")
	t.is_true(MagicLibrary.has_definition(&"temporal_pause"), "has_definition true")
	t.is_false(MagicLibrary.has_definition(&"nope"), "unknown ability reported false")


func _test_magic_manager() -> void:
	t.section("Magic: validation + spend")
	var timeline := TimelineState.new()
	var meta := MetaProgression.new()
	t.equal(MagicManager.can_use(timeline, meta, &"temporal_pause", &""), MagicManager.REASON_LOCKED, "locked before unlock")

	meta.unlock_ability("temporal_pause")
	t.equal(MagicManager.can_use(timeline, meta, &"temporal_pause", &""), MagicManager.REASON_NO_TARGET, "no target outside a trap")

	TrapMachine.enter(timeline, &"endless_picnic")
	t.equal(MagicManager.can_use(timeline, meta, &"temporal_pause", &"endless_picnic"), MagicManager.REASON_UNDISCOVERED, "needs discovery first")

	TrapMachine.discover(timeline, &"endless_picnic")
	t.equal(MagicManager.can_use(timeline, meta, &"temporal_pause", &"endless_picnic"), MagicManager.REASON_OK, "usable once discovered")

	var drained := TimelineState.new()
	drained.spend_magic_focus(drained.get_magic_focus())
	TrapMachine.enter(drained, &"endless_picnic")
	TrapMachine.discover(drained, &"endless_picnic")
	t.equal(MagicManager.can_use(drained, meta, &"temporal_pause", &"endless_picnic"), MagicManager.REASON_NO_FOCUS, "fails without focus")
	t.equal(MagicManager.can_use(timeline, meta, &"nope", &""), MagicManager.REASON_UNKNOWN, "unknown ability reported")

	var focus_before := timeline.get_magic_focus()
	t.equal(MagicManager.use(timeline, meta, &"temporal_pause", &"endless_picnic"), MagicManager.REASON_OK, "use returns ok")
	t.equal(timeline.get_magic_focus(), focus_before - 1, "use spends focus")


func _test_magic_trap_integration() -> void:
	t.section("Magic: resolves the picnic trap")
	Game.timeline = TimelineState.new()
	Game.meta = MetaProgression.new()
	Game.meta.unlock_ability("temporal_pause")
	Game.set_active_trap(&"endless_picnic")
	TrapMachine.enter(Game.timeline, &"endless_picnic")

	var reasons: Array = []
	var failed_listener: Callable = func(_id, reason): reasons.append(reason)
	EventBus.magic_failed.connect(failed_listener)
	t.is_false(Game.use_magic(&"temporal_pause"), "fails before discovery")
	t.equal(reasons.size(), 1, "failure signalled")
	t.equal(reasons[0], MagicManager.REASON_UNDISCOVERED, "reason is undiscovered")
	EventBus.magic_failed.disconnect(failed_listener)

	TrapMachine.discover(Game.timeline, &"endless_picnic")
	var used: Array = []
	var used_listener: Callable = func(id): used.append(id)
	EventBus.magic_used.connect(used_listener)
	t.is_true(Game.use_magic(&"temporal_pause"), "succeeds after discovery")
	t.equal(used.size(), 1, "success signalled")
	EventBus.magic_used.disconnect(used_listener)

	t.is_true(TrapMachine.is_resolved(Game.timeline, &"endless_picnic"), "trap resolved by magic")
	t.equal(Game.timeline.get_trap_resolution(&"endless_picnic"), "frozen", "resolution is frozen")
	t.is_true(Game.timeline.get_flag(&"picnic_frozen", false), "freeze flag set")
	t.is_true(Game.meta.anomalies_seen.has("temporal_pause_used"), "anomaly recorded")
	t.equal(Game.timeline.get_magic_focus(), TimelineState.MAGIC_FOCUS_START - 1, "focus spent")
	Game.clear_active_trap(&"endless_picnic")


func _test_magic_unlock() -> void:
	t.section("Magic: unlocked by Pip's quest")
	Game.timeline = TimelineState.new()
	Game.meta = MetaProgression.new()
	Game.apply_effects([{"type": "quest", "quest": "pip_device", "action": "start"}])
	Game.apply_effects([{"type": "quest", "quest": "pip_device", "action": "objective", "objective": "talk_pip"}])
	Game.apply_effects([{"type": "quest", "quest": "pip_device", "action": "objective", "objective": "examine_device"}])
	Game.apply_effects([{"type": "quest", "quest": "pip_device", "action": "objective", "objective": "return_pip"}])
	t.is_true(Game.meta.has_ability("temporal_pause"), "quest completion unlocks the ability")
	t.is_true(Game.timeline.get_flag(&"ability_temporal_pause", false), "ability flag synced to the timeline")


# --- Phase 11: content expansion -------------------------------------------

func _test_context_ability() -> void:
	t.section("Magic: context-aware ability selection")
	Game.timeline = TimelineState.new()
	Game.meta = MetaProgression.new()
	t.equal(Game.context_ability(), Game.DEFAULT_ABILITY, "default ability when nothing is unlocked")

	Game.meta.unlock_ability("memory_echo")
	t.equal(Game.context_ability(), &"memory_echo", "falls back to the primary unlocked ability")

	Game.set_active_trap(&"returning_tree")
	TrapMachine.enter(Game.timeline, &"returning_tree")
	TrapMachine.discover(Game.timeline, &"returning_tree")
	t.equal(Game.context_ability(), &"memory_echo", "picks the unlocked ability valid for the active trap")
	Game.clear_active_trap(&"returning_tree")


func _test_memory_echo_ability() -> void:
	t.section("Magic: Memory Echo resolves the returning tree")
	Game.timeline = TimelineState.new()
	Game.meta = MetaProgression.new()
	Game.meta.unlock_ability("memory_echo")
	Game.set_active_trap(&"returning_tree")
	TrapMachine.enter(Game.timeline, &"returning_tree")
	TrapMachine.discover(Game.timeline, &"returning_tree")

	t.is_true(Game.use_magic(&"memory_echo"), "memory echo succeeds once the tree is understood")
	t.is_true(TrapMachine.is_resolved(Game.timeline, &"returning_tree"), "trap resolved by memory echo")
	t.equal(Game.timeline.get_trap_resolution(&"returning_tree"), "remembered", "resolution is remembered")
	t.is_true(Game.meta.anomalies_seen.has("memory_echo_used"), "anomaly recorded")
	Game.clear_active_trap(&"returning_tree")


func _test_meta_flags() -> void:
	t.section("Timeline: meta flags for alternate timelines")
	Game.timeline = TimelineState.new()
	Game.meta = MetaProgression.new()
	t.is_false(Game.timeline.get_flag(&"meta_restarted", false), "no restart flag on a fresh timeline")

	Game.meta.restart_count = 2
	Game.meta.completed_timelines = 1
	Game.begin_new_timeline()
	t.is_true(Game.timeline.get_flag(&"meta_restarted"), "restart history mirrored to a flag")
	t.is_true(Game.timeline.get_flag(&"meta_completed_before"), "completion history mirrored to a flag")


func _test_trap_clue_and_exit() -> void:
	t.section("Traps: reusable clue + exit")
	Game.timeline = TimelineState.new()
	Game.meta = MetaProgression.new()

	var clue := TrapClue.new()
	clue.trap_id = &"endless_picnic"
	clue.notice_flag = &"picnic_noticed"
	clue.rule_flag = &"picnic_rule_known"
	clue.anomaly_id = "picnic_tea_set"
	clue.first_lines = PackedStringArray(["one", "two"])
	clue.rule_lines = PackedStringArray(["the rule"])
	clue.interact(null)
	t.is_true(Game.timeline.get_flag(&"picnic_noticed"), "first look sets the noticed flag")
	Game.in_dialogue = false
	clue.interact(null)
	t.equal(Game.timeline.get_trap_state(&"endless_picnic"), "discovered", "second look discovers the trap")
	t.is_true(Game.timeline.get_flag(&"picnic_rule_known"), "rule flag set")
	t.is_true(Game.meta.anomalies_seen.has("picnic_tea_set"), "clue records its anomaly")
	Game.in_dialogue = false

	var exit := TrapExit.new()
	exit.trap_id = &"endless_picnic"
	exit.required_flag = &"missing_flag"
	exit.resolution = &"walked_away"
	t.is_false(exit.can_interact(null), "exit is gated until the rule is known")
	Game.timeline.set_flag(&"missing_flag", true)
	TrapMachine.enter(Game.timeline, &"endless_picnic")
	t.is_true(exit.can_interact(null), "exit opens once the gate flag is set")
	exit.interact(null)
	t.is_true(TrapMachine.is_resolved(Game.timeline, &"endless_picnic"), "exit resolves the trap")
	t.equal(Game.timeline.get_trap_resolution(&"endless_picnic"), "walked_away", "resolution recorded")
	clue.free()
	exit.free()


func _test_secret_find() -> void:
	t.section("Secrets: one-time find")
	Game.timeline = TimelineState.new()
	Game.meta = MetaProgression.new()
	var secret := SecretFind.new()
	secret.name = "LoosePanel"
	secret.grant_flag = &"cellar_key"
	secret.found_flag = &"found_loose_panel"
	secret.discovery_id = "found_cellar_key"
	secret.lines = PackedStringArray(["Found it."])

	t.is_false(secret.is_found(), "secret starts unfound")
	t.is_true(secret.can_interact(null), "secret can be searched")
	secret.interact(null)
	t.is_true(Game.timeline.get_flag(&"cellar_key"), "secret grants the key")
	t.is_true(Game.meta.discoveries.has("found_cellar_key"), "secret records a discovery")
	t.is_true(secret.is_found(), "secret is now found")
	t.is_false(secret.can_interact(null), "a found secret cannot be searched again")
	Game.in_dialogue = false
	secret.free()


func _test_journal() -> void:
	t.section("Journal: labels + entries")
	var meta := MetaProgression.new()
	t.is_true(Journal.is_empty(meta), "journal starts empty")
	meta.record_anomaly("returning_tree")
	meta.record_discovery("found_cellar_key")
	var entries := Journal.entries(meta)
	t.equal(entries.size(), 2, "one entry per recorded item")
	t.equal(str(entries[0]["title"]), "The Returning Tree", "anomaly labelled")
	t.is_true(entries.any(func(entry): return str(entry["title"]) == "The Cellar Key"), "discovery labelled")
	t.equal(Journal.title_for("unknown_thing", Journal.KIND_DISCOVERY), "Unknown Thing", "unknown ids are prettified")
	t.is_false(Journal.is_empty(meta), "journal is not empty after recording")


func _test_fern_alt_timeline_dialogue() -> void:
	t.section("Dialogue: alternate-timeline variation")
	Game.timeline = TimelineState.new()
	var definition := DialogueLibrary.load_definition(&"fern_intro")
	var fresh := DialogueRunner.new(definition)
	fresh.resolve(Game.timeline)
	t.equal(String(fresh.node_key), "first", "first encounter on a fresh timeline")

	Game.timeline.set_flag(&"meta_completed_before", true)
	var again := DialogueRunner.new(definition)
	again.resolve(Game.timeline)
	t.equal(String(again.node_key), "first_again", "alternate opening once a timeline has been finished")


func _test_expansion_path() -> void:
	t.section("Phase 11: hollow arc completes and unlocks magic")
	Game.timeline = TimelineState.new()
	Game.meta = MetaProgression.new()
	Game.apply_effects([{"type": "quest", "quest": "fern_hollow", "action": "start"}])
	Game.apply_effects([{"type": "quest", "quest": "fern_hollow", "action": "objective", "objective": "meet_fern"}])
	Game.apply_effects([{"type": "quest", "quest": "fern_hollow", "action": "objective", "objective": "discover_tree"}])
	Game.apply_effects([{"type": "quest", "quest": "fern_hollow", "action": "objective", "objective": "resolve_tree"}])
	t.is_true(QuestManager.is_completed(Game.timeline, &"fern_hollow"), "Fern's quest completes")
	t.is_true(Game.meta.has_ability("memory_echo"), "completion unlocks Memory Echo")
	t.is_true(Game.timeline.get_flag(&"fern_hollow_done", false), "completion flag set")


func _test_hollow_scene() -> void:
	t.section("World: hollow instantiates")
	Game.timeline = TimelineState.new()
	Game.meta = MetaProgression.new()
	var hollow: Variant = load("res://scenes/world/hollow.tscn").instantiate()
	add_child(hollow)
	await get_tree().process_frame
	t.equal(String(hollow.trap_id), "returning_tree", "hollow carries the trap id")
	t.check(hollow.get_node_or_null("Background") != null, "hollow background present")
	t.check(hollow.get_node_or_null("Fern") != null, "Fern is present in the hollow")
	t.check(hollow.get_node_or_null("TreeRoots") != null, "tree roots clue present")
	t.check(hollow.get_node_or_null("FallenLeaf") != null, "fallen leaf loop token present")
	t.check(hollow.get_node_or_null("RootsEdge") != null, "roots edge exit present")
	t.check(hollow.get_node_or_null("Player") != null, "player present")
	hollow.queue_free()
	await get_tree().process_frame
	Game.in_dialogue = false


func _test_journal_scene() -> void:
	t.section("UI: journal opens and closes")
	var scene: Variant = load("res://scenes/ui/journal.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	t.is_false(scene.is_open(), "journal starts closed")
	scene.toggle()
	t.is_true(scene.is_open(), "journal toggles open")
	scene.toggle()
	t.is_false(scene.is_open(), "journal toggles closed")
	scene.queue_free()
	await get_tree().process_frame


# --- Phase 12: polish / release --------------------------------------------

func _test_settings_persistence() -> void:
	t.section("Settings: standalone persistence")
	Game.settings = ApplicationSettings.new()
	Game.settings.master_volume = 0.42
	Game.settings.reduce_motion = true
	Game.settings.text_speed = 60.0
	t.is_true(
		SaveManager.save_settings(TEST_SETTINGS, TEST_SETTINGS_BACKUP, TEST_SETTINGS_TEMP),
		"save_settings writes the file"
	)
	t.is_true(SaveManager.has_settings(TEST_SETTINGS, TEST_SETTINGS_BACKUP), "settings file exists")

	Game.settings = ApplicationSettings.new()
	t.is_true(SaveManager.load_settings(TEST_SETTINGS, TEST_SETTINGS_BACKUP), "load_settings succeeds")
	t.equal(Game.settings.master_volume, 0.42, "master volume persisted")
	t.is_true(Game.settings.reduce_motion, "reduce motion persisted")
	t.equal(Game.settings.text_speed, 60.0, "text speed persisted")
	SaveManager.clear_slot(TEST_SETTINGS, TEST_SETTINGS_BACKUP, TEST_SETTINGS_TEMP)
	Game.settings = ApplicationSettings.new()


func _test_audio_catalog() -> void:
	t.section("Audio: music + ambience catalog")
	t.is_true(AudioManager.has_music(&"menu"), "menu music registered")
	t.is_true(AudioManager.has_music(&"village"), "village music registered")
	t.is_true(AudioManager.has_ambience(&"village_wind"), "village ambience registered")
	t.is_false(AudioManager.has_music(&"nope"), "unknown music rejected")
	t.check(AudioManager._stream_for("music", "menu") != null, "music stream synthesized")
	t.check(AudioManager._stream_for("ambience", "village_wind") != null, "ambience stream synthesized")

	AudioManager.play_music(&"menu")
	t.equal(String(AudioManager.current_music()), "menu", "music switches to the requested track")
	AudioManager.play_music(&"nope")
	t.equal(String(AudioManager.current_music()), "menu", "unknown track leaves music unchanged")
	AudioManager.stop_music(0.0)
	AudioManager.stop_ambience(0.0)


func _test_controller_mappings() -> void:
	t.section("Input: keyboard + controller bindings")
	t.is_true(InputMap.has_action("interact"), "interact action exists")
	var has_face_button := false
	for event in InputMap.action_get_events("interact"):
		if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_A:
			has_face_button = true
	t.is_true(has_face_button, "interact is bound to the A face button")

	var has_left_axis := false
	for event in InputMap.action_get_events("move_left"):
		if event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_X and event.axis_value < 0.0:
			has_left_axis = true
	t.is_true(has_left_axis, "move_left is bound to the left stick")
	t.is_true(InputMap.has_action("journal"), "journal action exists")


func _test_reduce_motion_transition() -> void:
	t.section("Accessibility: reduce motion skips transitions")
	Game.settings = ApplicationSettings.new()
	Game.settings.reduce_motion = false
	t.is_false(Game.router._reduced_motion(), "transitions animate by default")
	Game.settings.reduce_motion = true
	t.is_true(Game.router._reduced_motion(), "transitions skip the fade when reduced motion is on")
	Game.settings = ApplicationSettings.new()


func _test_settings_menu() -> void:
	t.section("UI: settings menu applies + saves")
	Game.settings = ApplicationSettings.new()
	var menu: Variant = load("res://scenes/menus/settings_menu.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	t.is_false(menu.is_open(), "settings menu starts closed")
	menu.open()
	t.is_true(menu.is_open(), "settings menu opens")

	menu._master.value = 0.5
	t.equal(Game.settings.master_volume, 0.5, "volume slider updates settings")
	menu._reduce_motion.button_pressed = true
	t.is_true(Game.settings.reduce_motion, "accessibility toggle updates settings")
	menu._text_speed.value = 80.0
	t.equal(Game.settings.text_speed, 80.0, "text speed slider updates settings")

	menu.close()
	t.is_false(menu.is_open(), "settings menu closes")
	menu.queue_free()
	await get_tree().process_frame
	Game.settings = ApplicationSettings.new()


func _test_dialogue_typewriter() -> void:
	t.section("Dialogue: typewriter reveal + skip")
	Game.timeline = TimelineState.new()
	Game.settings = ApplicationSettings.new()

	var box: Node = load("res://scenes/dialogue/dialogue_box.tscn").instantiate()
	add_child(box)
	await get_tree().process_frame

	Game.start_dialogue(&"lumi", &"lumi_intro")
	await get_tree().process_frame
	t.is_true(box.is_revealing(), "text begins revealing after a non-empty line")
	t.check(box._text_label.text.length() < box._full_text.length(), "text is partially revealed")

	box._complete_reveal()
	t.is_false(box.is_revealing(), "skip completes the reveal")
	t.equal(box._text_label.text, box._full_text, "completed reveal shows the full line")

	box._advance()          # first line -> choice line
	box._confirm_choice()   # pick the first choice
	var guard := 0
	while Game.in_dialogue and guard < 40:
		guard += 1
		box._advance()
	await get_tree().process_frame
	box.queue_free()
	await get_tree().process_frame
	Game.settings = ApplicationSettings.new()


# --- Phase 13: variation + 3D presentation ---------------------------------

func _test_timeline_variation() -> void:
	t.section("Variation: per-timeline theme")
	var timeline := TimelineState.new()
	timeline.timeline_id = "tl_fixed_alpha"
	var meta := MetaProgression.new()
	var theme := TimelineVariation.theme(timeline, meta)
	t.check(TimelineVariation.THEMES.has(theme), "theme is one of the known values")
	t.equal(TimelineVariation.theme(timeline, meta), theme, "theme is deterministic for a timeline id")
	t.check(TimelineVariation.palette(theme).has("sky"), "theme has a palette")
	t.check(TimelineVariation.variant_index(timeline, meta, 2) in [0, 1], "variant index is within range")

	Game.timeline = TimelineState.new()
	Game.meta = MetaProgression.new()
	Game.begin_new_timeline()
	var applied := str(Game.timeline.get_flag(&"variation_theme", ""))
	t.check(applied != "", "Game applies a variation theme to a new timeline")
	t.is_true(Game.timeline.get_flag(StringName("variant_%s" % applied), false), "matching variant flag is set")


func _test_world3d_builds() -> void:
	t.section("3D: village builds a top-down 3D world")
	Game.timeline = TimelineState.new()
	Game.meta = MetaProgression.new()
	Game.settings = ApplicationSettings.new()
	Game.settings.use_3d_visuals = true
	var village: Variant = load("res://scenes/world/village.tscn").instantiate()
	add_child(village)
	await get_tree().process_frame
	var world = village.get_node_or_null("World3D")
	t.check(world != null, "a 3D world node is created")
	if world != null:
		t.check(world.get_node_or_null("WorldCamera") != null, "45-degree 3D camera present")
		t.check(world.get_node_or_null("Environment") != null, "3D environment present")
		t.check(world.actor_count() >= 4, "3D actors built for the player and NPCs")
		t.check(world.prop_count() >= 3, "3D props built for interactables")
		var camera := world.get_node_or_null("WorldCamera") as Camera3D
		t.check(camera != null and camera.projection == Camera3D.PROJECTION_PERSPECTIVE, "camera is perspective")
		if camera != null:
			t.check(camera.fov > 0.0 and camera.fov < 60.0, "camera has a narrow 3/4 FOV")
			var forward := -camera.global_transform.basis.z
			t.check(forward.y < -0.3, "camera looks downward at an angle (not straight down)")
			t.check(absf(forward.z) > 0.1, "camera has a three-quarter angle")
	t.is_false(village.get_node("Lumi").visible, "2D NPC drawing is hidden in 3D mode")
	village.queue_free()
	await get_tree().process_frame


func _test_world3d_toggle() -> void:
	t.section("3D: disabled falls back to 2D")
	Game.timeline = TimelineState.new()
	Game.settings = ApplicationSettings.new()
	Game.settings.use_3d_visuals = false
	var village: Variant = load("res://scenes/world/village.tscn").instantiate()
	add_child(village)
	await get_tree().process_frame
	t.check(village.get_node_or_null("World3D") == null, "no 3D world when the setting is off")
	t.is_true(village.get_node("Lumi").visible, "2D NPC drawing is shown when 3D is off")
	village.queue_free()
	await get_tree().process_frame
	Game.settings = ApplicationSettings.new()


# --- Ending ----------------------------------------------------------------

func _complete_arc(timeline: TimelineState) -> void:
	for quest_id in TimelineEnding.REQUIRED_QUESTS:
		timeline.set_quest_status(StringName(quest_id), "completed")
	TrapMachine.enter(timeline, &"endless_picnic")
	TrapMachine.discover(timeline, &"endless_picnic")
	TrapMachine.resolve(timeline, &"endless_picnic", &"refused")


func _test_model_library() -> void:
	t.section("3D: CC0 models load and auto-fit")
	t.is_true(ModelLibrary.has_model("tree_default"), "nature model file is present")
	var scene := ModelLibrary.get_scene("tree_default")
	t.check(scene != null, "model imports as a PackedScene")
	var node := ModelLibrary.instantiate("tree_default", 60.0, "height")
	t.check(node != null, "model instantiates")
	if node != null:
		t.check(node.scale.x > 0.0, "model is uniformly scaled to the target size")
		node.free()
	t.check(ModelLibrary.instantiate("does_not_exist", 10.0) == null, "a missing model returns null (fallback path)")
	t.check(ModelLibrary.group_available(ModelLibrary.TREES), "tree group is available")


func _test_character_models() -> void:
	t.section("3D: CC0 character models load")
	var scene := load("res://assets/models/chars/Astronaut_FinnTheFrog.fbx") as PackedScene
	t.check(scene != null, "character FBX imports as a scene")
	if scene == null:
		return
	var node: Node = scene.instantiate()
	t.check(node is Node3D, "character root is 3D")
	var players := node.find_children("*", "AnimationPlayer", true, false)
	t.check(players.size() >= 1, "character has an AnimationPlayer")
	var has_idle := false
	if players.size() > 0:
		for name in (players[0] as AnimationPlayer).get_animation_list():
			if String(name).to_lower().contains("idle"):
				has_idle = true
	t.check(has_idle, "character has an idle animation")
	node.free()

	var actor := Actor3D.new()
	add_child(actor)
	actor.setup(CharacterRegistry.get_character(&"pip"), null)
	t.is_false(actor._procedural, "actor uses the CC0 model when a character defines one")
	actor.queue_free()


func _test_timeline_ending_conditions() -> void:
	t.section("Ending: completion conditions")
	var timeline := TimelineState.new()
	var meta := MetaProgression.new()
	t.is_false(TimelineEnding.is_ready(timeline, meta), "not ready at the start")
	t.equal(TimelineEnding.unmet_labels(timeline, meta).size(), 3, "three conditions unmet")

	for quest_id in TimelineEnding.REQUIRED_QUESTS:
		timeline.set_quest_status(StringName(quest_id), "completed")
	t.is_false(TimelineEnding.is_ready(timeline, meta), "not ready until the picnic is resolved")

	TrapMachine.enter(timeline, &"endless_picnic")
	TrapMachine.resolve(timeline, &"endless_picnic", &"refused")
	t.is_true(TimelineEnding.is_ready(timeline, meta), "ready once quests and picnic are done")
	t.is_true(TimelineEnding.unmet_labels(timeline, meta).is_empty(), "no unmet labels when ready")


func _test_epilogue_lines() -> void:
	t.section("Ending: epilogue text")
	var timeline := TimelineState.new()
	var meta := MetaProgression.new()
	_complete_arc(timeline)
	var lines := TimelineEnding.epilogue_lines(timeline, meta)
	t.check(lines.size() >= 6, "epilogue has several lines")
	t.equal(str(lines[0]), "You stayed.", "epilogue opens with the central choice")
	t.is_true(lines.any(func(line): return str(line).contains("Momo")), "epilogue names the characters")
	t.is_true(lines.any(func(line): return str(line).contains("refused")), "epilogue reflects the picnic resolution")


func _test_record_completion() -> void:
	t.section("Ending: records the completed timeline")
	Game.timeline = TimelineState.new()
	Game.meta = MetaProgression.new()
	_complete_arc(Game.timeline)

	var events: Array = []
	var listener: Callable = func(id): events.append(id)
	EventBus.timeline_completed.connect(listener)
	Game.record_timeline_completion(Game.timeline.get_trap_resolution(&"endless_picnic"))
	EventBus.timeline_completed.disconnect(listener)

	t.equal(Game.meta.completed_timelines, 1, "completed_timelines incremented")
	t.is_true(Game.meta.discoveries.has("completed_timeline"), "completion discovery recorded")
	t.is_true(Game.meta.discoveries.has("ending_refused"), "resolution discovery recorded")
	t.equal(Game.meta.last_outcome, "completed", "outcome recorded")
	t.equal(events.size(), 1, "timeline_completed emitted")


func _test_ending_valid_path() -> void:
	t.section("Ending: reachable from a valid path")
	Game.timeline = TimelineState.new()
	Game.meta = MetaProgression.new()
	_complete_arc(Game.timeline)
	t.is_true(TimelineEnding.is_ready(Game.timeline, Game.meta), "a full playthrough reaches the ending")


func _test_ending_scene() -> void:
	t.section("Ending: scene instantiates")
	Game.timeline = TimelineState.new()
	Game.meta = MetaProgression.new()
	_complete_arc(Game.timeline)
	var scene: Variant = load("res://scenes/endings/timeline_ending.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	t.check(scene._lines.size() > 0, "ending scene assembled epilogue lines")
	scene.queue_free()
	await get_tree().process_frame


# --- Interaction / world ---------------------------------------------------

func _test_interaction_priority() -> void:
	t.section("Interaction: selection priority")
	var near := Interactable.new()
	near.position = Vector2(10.0, 0.0)
	near.interaction_priority = 0
	var far := Interactable.new()
	far.position = Vector2(100.0, 0.0)
	far.interaction_priority = 5
	t.check(InteractionSelector.pick([near, far], Vector2.ZERO) == far, "higher priority wins over nearer")
	near.free()
	far.free()

	var a := Interactable.new()
	a.position = Vector2(30.0, 0.0)
	var b := Interactable.new()
	b.position = Vector2(20.0, 0.0)
	t.check(InteractionSelector.pick([a, b], Vector2.ZERO) == b, "nearest wins at equal priority")
	a.free()
	b.free()


func _test_door_lock() -> void:
	t.section("Door: flag-gated lock")
	Game.timeline = TimelineState.new()
	var door := Door.new()
	door.initially_unlocked = false
	door.unlock_flag = &"cellar_key"
	t.is_true(door.is_locked(), "locked when its unlock flag is unset")
	Game.timeline.set_flag(&"cellar_key", true)
	t.is_false(door.is_locked(), "unlocks when its unlock flag is set")
	door.free()

	var open := Door.new()
	open.initially_unlocked = true
	t.is_false(open.is_locked(), "open door is never locked")
	open.free()


func _test_text_interactable() -> void:
	t.section("Sign/Prop: text definition")
	var sign := TextInteractable.new()
	sign.name = "TestSign"
	sign.speaker_label = "Village Sign"
	sign.lines = PackedStringArray(["Hello.", "World."])
	var definition := sign.build_definition()
	t.equal(definition.get("speaker_name"), "Village Sign", "speaker label carried")
	var runner := DialogueRunner.new(definition)
	t.equal(runner.current_text(), "Hello.", "sign first line")
	runner.advance()
	t.is_true(runner.is_last_line(), "sign advances")
	t.is_true(runner.available_choices(TimelineState.new()).is_empty(), "signs have no choices")
	sign.free()


func _test_spawn_transition() -> void:
	t.section("World: spawn hand-off")
	Game.set_spawn(&"from_workshop")
	t.equal(Game.consume_spawn(), &"from_workshop", "pending spawn returned")
	t.equal(Game.consume_spawn(), &"default", "spawn resets after consumption")


func _test_area_spawn_placement() -> void:
	t.section("World: area places player at spawn")
	Game.set_spawn(&"door")
	var area := AreaController.new()
	area.location_id = &"test_area"
	var spawn := SpawnPoint.new()
	spawn.spawn_id = &"door"
	spawn.position = Vector2(120.0, 40.0)
	area.add_child(spawn)
	var dummy := Node2D.new()
	dummy.name = "Player"
	area.add_child(dummy)
	add_child(area)
	await get_tree().process_frame

	t.check(dummy.position == Vector2(120.0, 40.0), "player moved to requested spawn")
	t.equal(String(Game.timeline.current_location), "test_area", "location recorded on load")
	area.queue_free()
	await get_tree().process_frame


func _test_world_scenes_load() -> void:
	t.section("World: scenes instantiate")
	for path in ["res://scenes/world/village.tscn", "res://scenes/world/workshop.tscn"]:
		var area: Variant = load(path).instantiate()
		add_child(area)
		await get_tree().process_frame
		t.check(area.get_node_or_null("Player") != null, "player present in %s" % path)
		t.check(area.get_node_or_null("DialogueBox") != null, "dialogue UI present in %s" % path)
		area.queue_free()
		await get_tree().process_frame


# --- Helpers ---------------------------------------------------------------

func _payload(flag: String) -> Dictionary:
	var timeline := TimelineState.new()
	timeline.set_flag(StringName(flag), true)
	return {
		"version": SaveSchema.CURRENT_VERSION,
		"timeline": timeline.to_dict(),
		"meta": MetaProgression.new().to_dict(),
		"settings": ApplicationSettings.new().to_dict(),
	}


func _is_valid(data: Variant) -> bool:
	return SaveSchema.validate(data)


func _cleanup() -> void:
	for path in [TEST_SLOT, TEST_BACKUP, TEST_TEMP, TEST_ARCHIVE,
			TEST_SETTINGS, TEST_SETTINGS_BACKUP, TEST_SETTINGS_TEMP]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	# The settings-menu test writes to the live settings slot; remove it so the
	# suite leaves no preference changes behind.
	for path in [SaveManager.SETTINGS_PATH, SaveManager.SETTINGS_BACKUP, SaveManager.SETTINGS_TEMP]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
