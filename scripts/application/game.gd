extends Node
## Autoload: top-level game flow and the active session.
##
## Application layer. Owns the authoritative state models and mediates between
## presentation (which sends requests) and domain (which holds state). UI never
## mutates TimelineState directly; it calls into Game, which validates and then
## announces the result on EventBus.

const SCENE_MAIN_MENU := "res://scenes/menus/main_menu.tscn"
const SCENE_VILLAGE := "res://scenes/world/village.tscn"
const SCENE_ENDING := "res://scenes/endings/timeline_ending.tscn"
const DEFAULT_ABILITY := &"temporal_pause"

const INPUT_ACTIONS := {
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"interact": [KEY_E, KEY_ENTER, KEY_SPACE],
	"use_magic": [KEY_Q],
	"journal": [KEY_J],
	"pause": [KEY_ESCAPE],
	"choice_up": [KEY_W, KEY_UP],
	"choice_down": [KEY_S, KEY_DOWN],
}

## Gamepad buttons for the same actions (controller support).
const INPUT_BUTTONS := {
	"interact": [JOY_BUTTON_A],
	"use_magic": [JOY_BUTTON_X],
	"journal": [JOY_BUTTON_Y],
	"pause": [JOY_BUTTON_START],
	"choice_up": [JOY_BUTTON_DPAD_UP],
	"choice_down": [JOY_BUTTON_DPAD_DOWN],
}

## Gamepad axes for the movement actions (left stick; sign separates the pair).
const INPUT_AXES := {
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
	"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	"move_down": [JOY_AXIS_LEFT_Y, 1.0],
}

var timeline: TimelineState
var meta: MetaProgression
var settings: ApplicationSettings

var router: SceneRouter
var in_dialogue := false
var next_spawn: StringName = &"default"
var active_trap: StringName = &""

var _pause_menu: CanvasLayer
var director: NarrativeDirector
var meta_ui: MetaUI
var restart: RestartController
var journal_ui: JournalUI
var settings_menu: SettingsMenu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_input_actions()

	meta = MetaProgression.new()
	settings = ApplicationSettings.new()
	SaveManager.load_settings()
	timeline = TimelineState.new()
	settings.apply_to_audio_buses()
	settings.apply_fullscreen()

	router = SceneRouter.new()
	add_child(router)

	director = NarrativeDirector.new()
	add_child(director)

	meta_ui = MetaUI.new()
	add_child(meta_ui)

	_install_pause_menu()
	_install_restart()
	_install_journal()
	_install_settings()
	_sync_meta_flags()


func _ensure_input_actions() -> void:
	for action in INPUT_ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for keycode in INPUT_ACTIONS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			event.keycode = keycode
			if not _action_has_key(action, keycode):
				InputMap.action_add_event(action, event)

	for action in INPUT_BUTTONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for button in INPUT_BUTTONS[action]:
			if not _action_has_button(action, button):
				var event := InputEventJoypadButton.new()
				event.button_index = button
				InputMap.action_add_event(action, event)

	for action in INPUT_AXES:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var axis: int = INPUT_AXES[action][0]
		var value: float = INPUT_AXES[action][1]
		if not _action_has_axis(action, axis, value):
			var event := InputEventJoypadMotion.new()
			event.axis = axis
			event.axis_value = value
			InputMap.action_add_event(action, event)


func _action_has_key(action: String, keycode: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and (event.physical_keycode == keycode or event.keycode == keycode):
			return true
	return false


func _action_has_button(action: String, button: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button:
			return true
	return false


func _action_has_axis(action: String, axis: int, value: float) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and event.axis == axis and is_equal_approx(event.axis_value, value):
			return true
	return false


# --- Flow -----------------------------------------------------------------

func go_to_main_menu() -> void:
	in_dialogue = false
	router.goto(SCENE_MAIN_MENU)


## Resets the active timeline to a clean state, preserving meta-progression and
## settings. Returns the isolation errors (empty means clean). Does not
## navigate, so it is safe to call from tests.
func begin_new_timeline() -> Array[String]:
	var previous_id := timeline.timeline_id
	timeline = TimelineInitializer.build()
	meta.restart_count += 1
	in_dialogue = false
	next_spawn = &"default"

	var errors := TimelineInitializer.verify_isolation(previous_id, timeline)
	meta.last_outcome = "clean" if errors.is_empty() else "isolation_error"
	if not errors.is_empty():
		push_error("Timeline isolation failed: %s" % ", ".join(errors))

	_sync_ability_flags()
	_sync_meta_flags()
	EventBus.timeline_started.emit(timeline.timeline_id)
	return errors


func start_new_timeline() -> void:
	begin_new_timeline()
	router.goto(SCENE_VILLAGE)


## Records a completed timeline in meta-progression (persists across restarts).
## Does not navigate, so it is safe to call from tests.
func record_timeline_completion(resolution := "") -> void:
	meta.completed_timelines += 1
	meta.record_discovery("completed_timeline")
	if resolution != "":
		meta.record_discovery("ending_%s" % resolution)
	meta.last_outcome = "completed"
	EventBus.timeline_completed.emit(timeline.timeline_id)


## Records completion and plays the ending sequence.
func begin_ending() -> void:
	if timeline == null:
		return
	record_timeline_completion(timeline.get_trap_resolution(&"endless_picnic"))
	in_dialogue = false
	active_trap = &""
	router.goto(SCENE_ENDING)


func enter_world() -> void:
	router.goto(SCENE_VILLAGE)


## Requests a transition to another area, placing the player at `spawn_id`.
func change_area(scene_path: String, spawn_id: StringName = &"default") -> void:
	next_spawn = spawn_id
	in_dialogue = false
	router.goto(scene_path)


## Records the spawn an area should place the player at on load.
func set_spawn(spawn_id: StringName) -> void:
	next_spawn = spawn_id


## Returns the pending spawn id and resets it to the default.
func consume_spawn() -> StringName:
	var spawn := next_spawn
	next_spawn = &"default"
	return spawn


# --- Magic ----------------------------------------------------------------

func set_active_trap(trap_id: StringName) -> void:
	active_trap = trap_id


func clear_active_trap(trap_id: StringName) -> void:
	if active_trap == trap_id:
		active_trap = &""


## The ability the primary magic input uses.
func first_ability() -> StringName:
	if meta.unlocked_abilities.is_empty():
		return DEFAULT_ABILITY
	return StringName(meta.unlocked_abilities[0])


## The unlocked ability best suited to the current context: the first one that
## validates against the active trap, falling back to the primary ability. This
## lets one input serve several abilities without a selection UI.
func context_ability() -> StringName:
	for ability in meta.unlocked_abilities:
		var ability_id := StringName(ability)
		if MagicManager.can_use(timeline, meta, ability_id, active_trap) == MagicManager.REASON_OK:
			return ability_id
	return first_ability()


## Attempts to use an ability. Returns true on success; on failure announces a
## reason on EventBus.magic_failed.
func use_magic(ability_id: StringName) -> bool:
	var reason := MagicManager.use(timeline, meta, ability_id, active_trap)
	if reason != MagicManager.REASON_OK:
		EventBus.magic_failed.emit(ability_id, reason)
		return false

	var definition := MagicLibrary.load_definition(ability_id)
	var effects: Array = []
	for effect in definition.get("effects", []):
		effects.append(_resolve_effect_target(effect, active_trap))
	apply_effects(effects)

	EventBus.magic_used.emit(ability_id)
	EventBus.focus_changed.emit(timeline.get_magic_focus())
	return true


func _resolve_effect_target(effect: Variant, target: StringName) -> Variant:
	if typeof(effect) != TYPE_DICTIONARY:
		return effect
	var entry: Dictionary = (effect as Dictionary).duplicate()
	if str(entry.get("type", "")) == "trap" and str(entry.get("trap", "")) == "@active":
		entry["trap"] = String(target)
	return entry


## Mirrors unlocked abilities (meta) into timeline flags so dialogue conditions
## can reference them generically.
func _sync_ability_flags() -> void:
	for ability in meta.unlocked_abilities:
		timeline.set_flag(StringName("ability_%s" % ability), true)


## Mirrors cross-timeline meta knowledge into timeline flags so authored
## dialogue can vary between a first run and later timelines. Also derives the
## deterministic per-timeline variation (theme flags) used by presentation and
## content.
func _sync_meta_flags() -> void:
	timeline.set_flag(&"meta_restarted", meta.restart_count > 0)
	timeline.set_flag(&"meta_completed_before", meta.completed_timelines > 0)
	TimelineVariation.apply(timeline, meta)


func apply_loaded_state(data: Dictionary) -> void:
	timeline = TimelineState.from_dict(data.get("timeline", {}))
	meta = MetaProgression.from_dict(data.get("meta", {}))
	settings = ApplicationSettings.from_dict(data.get("settings", {}))
	settings.apply_to_audio_buses()
	in_dialogue = false
	active_trap = &""
	_sync_ability_flags()
	_sync_meta_flags()
	EventBus.timeline_started.emit(timeline.timeline_id)


# --- Dialogue --------------------------------------------------------------

func start_dialogue(speaker_id: StringName, dialogue_id: StringName) -> void:
	if in_dialogue:
		return
	if dialogue_id == &"":
		push_warning("Game.start_dialogue: empty dialogue id for speaker '%s'." % speaker_id)
		return
	in_dialogue = true
	EventBus.dialogue_started.emit(speaker_id, dialogue_id)


## Starts a dialogue from an in-memory definition (used by signs and props).
func request_raw_dialogue(speaker_id: StringName, definition: Dictionary) -> void:
	if in_dialogue:
		return
	if definition.is_empty():
		return
	in_dialogue = true
	EventBus.raw_dialogue_requested.emit(speaker_id, definition)


func finish_dialogue(dialogue_id: StringName) -> void:
	if not in_dialogue:
		return
	in_dialogue = false
	EventBus.dialogue_finished.emit(dialogue_id)


## Applies a list of authored effects from dialogue to authoritative state.
## Returns the effects that were actually applied (for logging/tests).
func apply_effects(effects: Array) -> Array:
	var applied: Array = []
	for effect in effects:
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = effect
		match str(entry.get("type", "")):
			"relationship":
				var character_id := StringName(str(entry.get("character", "")))
				var attribute := str(entry.get("attr", "trust"))
				var delta := int(entry.get("delta", 0))
				var value := timeline.adjust_relationship(character_id, attribute, delta)
				EventBus.relationship_changed.emit(character_id, StringName(attribute), value, delta)
				applied.append(entry)
			"flag":
				var flag := StringName(str(entry.get("flag", "")))
				var flag_value: Variant = entry.get("value", true)
				timeline.set_flag(flag, flag_value)
				EventBus.story_flag_changed.emit(flag, flag_value)
				applied.append(entry)
			"quest":
				_apply_quest_effect(entry)
				applied.append(entry)
			"meta":
				if entry.has("unlock_ability"):
					var ability := str(entry["unlock_ability"])
					meta.unlock_ability(ability)
					timeline.set_flag(StringName("ability_%s" % ability), true)
				if entry.has("record_anomaly"):
					meta.record_anomaly(str(entry["record_anomaly"]))
				if entry.has("record_discovery"):
					meta.record_discovery(str(entry["record_discovery"]))
				applied.append(entry)
			"focus":
				var delta := int(entry.get("delta", 1))
				if delta >= 0:
					timeline.add_magic_focus(delta)
				else:
					timeline.spend_magic_focus(-delta)
				EventBus.focus_changed.emit(timeline.get_magic_focus())
				applied.append(entry)
			"trap":
				_apply_trap_effect(entry)
				applied.append(entry)
			_:
				push_warning("Game.apply_effects: unknown effect type '%s'." % entry.get("type", ""))
	return applied


func _apply_quest_effect(entry: Dictionary) -> void:
	var quest_id := StringName(str(entry.get("quest", "")))
	if quest_id == &"":
		return
	var action := str(entry.get("action", ""))
	if action == "":
		# Legacy/plain status set.
		var status := str(entry.get("state", "active"))
		timeline.set_quest_status(quest_id, status)
		EventBus.quest_state_changed.emit(quest_id, status)
		return
	match action:
		"start":
			QuestManager.start_quest(timeline, quest_id)
		"objective":
			var objective_id := StringName(str(entry.get("objective", "")))
			if QuestManager.complete_objective(timeline, quest_id, objective_id):
				_grant_quest_rewards(quest_id)
		"complete":
			if QuestManager.complete_quest(timeline, quest_id):
				_grant_quest_rewards(quest_id)
		"fail":
			QuestManager.fail_quest(timeline, quest_id)
		_:
			push_warning("Game: unknown quest action '%s'." % action)


## Applies a completed quest's authored rewards and consequences exactly once
## (guarded by QuestManager's completion transition).
func _grant_quest_rewards(quest_id: StringName) -> void:
	var definition := QuestLibrary.load_definition(quest_id)
	if definition.is_empty():
		return
	apply_effects(definition.get("rewards", []))
	apply_effects(definition.get("consequences", []))


func _apply_trap_effect(entry: Dictionary) -> void:
	var trap_id := StringName(str(entry.get("trap", "")))
	if trap_id == &"@active":
		trap_id = active_trap
	if trap_id == &"":
		return
	match str(entry.get("action", "")):
		"enter":
			TrapMachine.enter(timeline, trap_id)
		"advance":
			TrapMachine.advance(timeline, trap_id)
		"discover":
			TrapMachine.discover(timeline, trap_id)
		"resolve":
			var resolution := StringName(str(entry.get("resolution", "unknown")))
			TrapMachine.resolve(timeline, trap_id, resolution)
		_:
			push_warning("Game: unknown trap action '%s'." % entry.get("action", ""))


# --- Pause / restart -------------------------------------------------------

func _install_pause_menu() -> void:
	var scene := load("res://scenes/menus/pause_menu.tscn") as PackedScene
	if scene == null:
		push_warning("Game: pause menu scene missing.")
		return
	_pause_menu = scene.instantiate() as CanvasLayer
	add_child(_pause_menu)


func _install_restart() -> void:
	var scene := load("res://scenes/menus/restart_confirmation.tscn") as PackedScene
	if scene == null:
		push_warning("Game: restart confirmation scene missing.")
		return
	restart = scene.instantiate() as RestartController
	add_child(restart)


func _install_journal() -> void:
	var scene := load("res://scenes/ui/journal.tscn") as PackedScene
	if scene == null:
		push_warning("Game: journal scene missing.")
		return
	journal_ui = scene.instantiate() as JournalUI
	add_child(journal_ui)


## Opens/closes the journal overlay. Safe to call from UI or input.
func toggle_journal() -> void:
	if journal_ui != null:
		journal_ui.toggle()


func _install_settings() -> void:
	var scene := load("res://scenes/menus/settings_menu.tscn") as PackedScene
	if scene == null:
		push_warning("Game: settings menu scene missing.")
		return
	settings_menu = scene.instantiate() as SettingsMenu
	add_child(settings_menu)


## Opens the settings/accessibility overlay. Safe to call from any UI.
func open_settings() -> void:
	if settings_menu != null:
		settings_menu.open()


## Opens the restart confirmation, closing the pause menu first if needed.
func request_restart() -> void:
	if _pause_menu != null and _pause_menu.has_method("set_open"):
		_pause_menu.call("set_open", false)
	if restart != null:
		restart.open()


func _unhandled_input(event: InputEvent) -> void:
	if restart != null and restart.is_open():
		return
	if settings_menu != null and settings_menu.is_open():
		if event.is_action_pressed("pause"):
			settings_menu.close()
			get_viewport().set_input_as_handled()
		return
	if journal_ui != null and journal_ui.is_open():
		if event.is_action_pressed("journal") or event.is_action_pressed("pause"):
			toggle_journal()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("journal"):
		toggle_journal()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	var tree := get_tree()
	tree.paused = not tree.paused
	if _pause_menu != null and _pause_menu.has_method("set_open"):
		_pause_menu.call("set_open", tree.paused)
