class_name EndingTrigger
extends Interactable
## The plaza lantern. Once the timeline can be completed, touching it finishes
## the story; before then it explains what is still missing. This is the
## player's alternative to restarting.

const GLOW := Color(1.0, 0.91, 0.66, 0.16)
const POST := Color("#5a4a3a")
const FRAME := Color("#3a3026")
const FLAME := Color("#ffe9a8")


func _ready() -> void:
	super._ready()
	if prompt_text == "Interact":
		prompt_text = "Touch the lantern"


func should_complete() -> bool:
	return TimelineEnding.is_ready(Game.timeline, Game.meta)


func can_interact(_player: Node) -> bool:
	return enabled and not Game.in_dialogue


func interact(_player: Node) -> void:
	play_feedback()
	if should_complete():
		Game.begin_ending()
		return
	Game.request_raw_dialogue(&"lantern", _definition())


func _definition() -> Dictionary:
	var lines: Array = ["The lantern is warm, but it is not finished yet."]
	var unmet := TimelineEnding.unmet_labels(Game.timeline, Game.meta)
	if not unmet.is_empty():
		lines.append("It is waiting for you to:")
		for label in unmet:
			lines.append("   - %s" % label)
	else:
		lines.append("Perhaps it is waiting for something else.")
	return {
		"speaker": "lantern",
		"speaker_name": "The Lantern",
		"start": "start",
		"nodes": { "start": { "lines": lines, "choices": [] } },
	}


func _draw() -> void:
	draw_rect(Rect2(-3.0, 6.0, 6.0, 18.0), POST)
	draw_rect(Rect2(-10.0, -22.0, 20.0, 20.0), FRAME)
	draw_rect(Rect2(-6.0, -19.0, 12.0, 14.0), FLAME)
	draw_circle(Vector2(0.0, -12.0), 12.0, GLOW)
