class_name EndlessPicnic
extends TrapBase
## The Endless Picnic. Each completed conversation advances the loop: the
## garden gains a place setting, the palette cools, and Momo's lines escalate.
## Escape by understanding the rule and then leaving (garden edge) or refusing
## her (dialogue). The trap resolves once; revisiting the garden is harmless.
##
## The loop is driven by a child Timer node (not a coroutine) so it is freed
## with the scene and never leaks.

@export var start_delay := 0.6
@export var loop_pause := 1.2

var _running := false
var _background: Node
var _timer: Timer


func _ready() -> void:
	if trap_id == &"":
		trap_id = &"endless_picnic"
	super._ready()
	_background = get_node_or_null("Background")

	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)

	EventBus.dialogue_finished.connect(_on_dialogue_finished)
	EventBus.trap_resolved.connect(_on_trap_resolved)

	if is_resolved():
		_apply_visuals(iterations())
		return

	_running = true
	enter()
	_timer.start(start_delay)


func _on_timer_timeout() -> void:
	if not _running or is_resolved():
		return
	_run_iteration()


func _run_iteration() -> void:
	if is_resolved():
		return
	var count := advance()
	_apply_visuals(count)
	AudioManager.play_tone(300.0 + float(count) * 30.0, 0.09, -16.0)
	Game.start_dialogue(&"momo", &"picnic_loop")


func _on_dialogue_finished(dialogue_id: StringName) -> void:
	if not _running or dialogue_id != &"picnic_loop":
		return
	if is_resolved():
		return
	_timer.start(loop_pause)


func _on_trap_resolved(changed_trap_id: StringName, _resolution: StringName) -> void:
	if changed_trap_id == trap_id:
		_leave()


func _leave() -> void:
	if not _running:
		return
	_running = false
	if _timer != null:
		_timer.stop()
	AudioManager.play_tone(660.0, 0.25, -12.0)
	Game.change_area("res://scenes/world/village.tscn", &"from_picnic")


func _apply_visuals(count: int) -> void:
	if _background != null and _background.has_method("set_iteration"):
		_background.call("set_iteration", count)
