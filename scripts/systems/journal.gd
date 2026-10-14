class_name Journal
extends RefCounted
## Pure helpers for the journal: turns raw discovery and anomaly ids into
## readable entries. Systems layer, static so it is headless-testable.
##
## The journal is a reflection of meta-progression (knowledge that survives
## timelines), so it never touches timeline state.

const DISCOVERY_LABELS := {
	"lumi_trust": "Lumi's Trust",
	"fern_met": "Fern, Warden of the Hollow",
	"found_cellar_key": "The Cellar Key",
	"completed_timeline": "A Timeline, Finished",
	"ending_refused": "Ending: You Refused the Picnic",
	"ending_walked_away": "Ending: You Walked Away",
	"ending_frozen": "Ending: You Froze the Moment",
	"ending_remembered": "Ending: You Remembered the Tree",
}

const ANOMALY_LABELS := {
	"hum_repeat": "The Humming Sky",
	"world_unstable": "The Flickering Afternoon",
	"restart_whisper": "The Invitation to Begin Again",
	"game_speaks": "The Game Speaks",
	"endless_picnic": "The Endless Picnic",
	"picnic_tea_set": "The Four Cups",
	"temporal_pause_used": "A Moment, Held",
	"momo_time_question": "The Time Question",
	"returning_tree": "The Returning Tree",
	"memory_echo_used": "A Place, Remembered",
	"fern_knows": "Fern Remembers You",
}

const KIND_ANOMALY := "anomaly"
const KIND_DISCOVERY := "discovery"


static func title_for(entry_id: String, kind: String) -> String:
	var table := ANOMALY_LABELS if kind == KIND_ANOMALY else DISCOVERY_LABELS
	if table.has(entry_id):
		return table[entry_id]
	return entry_id.replace("_", " ").capitalize()


## Ordered entries for the journal: [{ "kind", "id", "title" }].
static func entries(meta: MetaProgression) -> Array:
	var out: Array = []
	for anomaly in meta.anomalies_seen:
		out.append({"kind": KIND_ANOMALY, "id": anomaly, "title": title_for(anomaly, KIND_ANOMALY)})
	for discovery in meta.discoveries:
		out.append({"kind": KIND_DISCOVERY, "id": discovery, "title": title_for(discovery, KIND_DISCOVERY)})
	return out


static func is_empty(meta: MetaProgression) -> bool:
	return meta.anomalies_seen.is_empty() and meta.discoveries.is_empty()
