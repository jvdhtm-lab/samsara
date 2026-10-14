class_name MetaProgression
extends RefCounted
## State that MAY persist across timelines.
##
## Domain layer. Deliberately narrow: it must never make relationships feel
## disposable, so it stores knowledge/achievements rather than timeline
## outcomes.

var restart_count: int = 0
var completed_timelines: int = 0
var unlocked_abilities: Array[String] = []
var anomalies_seen: Array[String] = []
var discoveries: Array[String] = []
var last_outcome: String = ""


func has_ability(ability_id: String) -> bool:
	return unlocked_abilities.has(ability_id)


func unlock_ability(ability_id: String) -> void:
	if not unlocked_abilities.has(ability_id):
		unlocked_abilities.append(ability_id)


func record_anomaly(anomaly_id: String) -> void:
	if not anomalies_seen.has(anomaly_id):
		anomalies_seen.append(anomaly_id)


func record_discovery(discovery_id: String) -> void:
	if not discoveries.has(discovery_id):
		discoveries.append(discovery_id)


func to_dict() -> Dictionary:
	return {
		"restart_count": restart_count,
		"completed_timelines": completed_timelines,
		"unlocked_abilities": unlocked_abilities.duplicate(),
		"anomalies_seen": anomalies_seen.duplicate(),
		"discoveries": discoveries.duplicate(),
		"last_outcome": last_outcome,
	}


static func from_dict(data: Dictionary) -> MetaProgression:
	var meta := MetaProgression.new()
	meta.restart_count = int(data.get("restart_count", 0))
	meta.completed_timelines = int(data.get("completed_timelines", 0))
	meta.unlocked_abilities = _to_string_array(data.get("unlocked_abilities", []))
	meta.anomalies_seen = _to_string_array(data.get("anomalies_seen", []))
	meta.discoveries = _to_string_array(data.get("discoveries", []))
	meta.last_outcome = str(data.get("last_outcome", ""))
	return meta


static func _to_string_array(source: Variant) -> Array[String]:
	var result: Array[String] = []
	if typeof(source) == TYPE_ARRAY:
		for item in source:
			result.append(str(item))
	return result
