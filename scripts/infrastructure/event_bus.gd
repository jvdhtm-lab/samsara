extends Node
## Global event bus.
##
## Infrastructure layer. Emits typed signals only. No string-based event
## routing. Presentation nodes subscribe; systems/application emit.
##
## Ownership: every signal below is emitted by exactly one layer.
##  - application (Game)  : dialogue_started/finished, timeline_started
##  - systems (interaction): interaction_target_changed
##  - infrastructure      : save_completed, load_completed

# --- Narrative / dialogue -------------------------------------------------
signal dialogue_started(speaker_id: StringName, dialogue_id: StringName)
signal dialogue_finished(dialogue_id: StringName)
signal raw_dialogue_requested(speaker_id: StringName, definition: Dictionary)

# --- Domain state changes (emitted by application after validation) -------
signal relationship_changed(character_id: StringName, attribute: StringName, value: int, delta: int)
signal story_flag_changed(flag: StringName, value: Variant)
signal quest_state_changed(quest_id: StringName, state: String)
signal quest_started(quest_id: StringName)
signal quest_objective_completed(quest_id: StringName, objective_id: StringName)
signal quest_completed(quest_id: StringName)
signal quest_failed(quest_id: StringName)

# --- Traps ----------------------------------------------------------------
signal trap_triggered(trap_id: StringName)
signal trap_loop_iteration(trap_id: StringName, iteration: int)
signal trap_discovered(trap_id: StringName)
signal trap_resolved(trap_id: StringName, resolution: StringName)

# --- Meta-narrative / anomalies ------------------------------------------
signal meta_stage_changed(stage: int, previous: int)
signal anomaly_triggered(anomaly_id: StringName, message: String)

# --- Restart --------------------------------------------------------------
signal restart_warning()
signal restart_confirmed()
signal restart_cancelled()
signal restart_completed(success: bool)

# --- Magic ----------------------------------------------------------------
signal magic_used(ability_id: StringName)
signal magic_failed(ability_id: StringName, reason: String)
signal focus_changed(value: int)

# --- Interaction ----------------------------------------------------------
signal interaction_target_changed(interactable: Node)

# --- Timeline / persistence ----------------------------------------------
signal timeline_started(timeline_id: String)
signal timeline_completed(timeline_id: String)
signal save_completed(success: bool, path: String)
signal load_completed(success: bool)
