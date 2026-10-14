class_name NarrativeDirector
extends Node
## Observes game events and schedules authored anomalies as the timeline's
## narrative stage changes.
##
## Systems layer (owned by Game). It requests narrative effects through the
## application layer (`Game.apply_effects`) and announces them on EventBus; it
## never mutates arbitrary scene nodes.

var current_stage := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.timeline_started.connect(_on_timeline_started)
	EventBus.quest_completed.connect(func(_quest_id): recompute())
	EventBus.trap_discovered.connect(func(_trap_id): recompute())
	EventBus.trap_resolved.connect(func(_trap_id, _resolution): recompute())
	recompute()


func _on_timeline_started(_timeline_id: String) -> void:
	recompute()


func recompute() -> void:
	var stage_now := MetaNarrative.stage(Game.timeline, Game.meta)
	if stage_now == current_stage:
		return
	var previous := current_stage
	current_stage = stage_now
	_apply_stage(stage_now)
	EventBus.meta_stage_changed.emit(stage_now, previous)


func _apply_stage(stage_index: int) -> void:
	var theme := str(Game.timeline.get_flag(&"variation_theme", ""))
	for anomaly in MetaNarrative.stage_anomalies(stage_index):
		if typeof(anomaly) != TYPE_DICTIONARY:
			continue
		var variant := str(anomaly.get("variant", ""))
		if variant != "" and variant != theme:
			continue
		var anomaly_id := StringName(str(anomaly.get("id", "")))
		var flag := StringName(str(anomaly.get("flag", "")))
		var message := str(anomaly.get("message", ""))
		var effects: Array = []
		if flag != &"":
			effects.append({"type": "flag", "flag": flag, "value": true})
		if anomaly_id != &"":
			effects.append({"type": "meta", "record_anomaly": String(anomaly_id)})
		if not effects.is_empty():
			Game.apply_effects(effects)
		EventBus.anomaly_triggered.emit(anomaly_id, message)
