class_name SceneRouter
extends CanvasLayer
## Co-ordinates scene changes with a soft fade transition.
##
## Application layer. Instantiated by Game. Owns no game state.

signal transition_started(target_path: String)

var _fade: ColorRect
var _busy := false


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Color(0.09, 0.07, 0.12, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)


func goto(path: String) -> void:
	if _busy:
		return
	_busy = true
	transition_started.emit(path)
	var reduced := _reduced_motion()
	if not reduced:
		await _fade_to(1.0, 0.3)
	else:
		# Defer at least one frame so a caller inside `_ready` is not swapping
		# the scene while the tree is still adding it.
		await get_tree().process_frame
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("SceneRouter: failed to load scene '%s' (error %d)." % [path, err])
	await get_tree().process_frame
	if not reduced:
		await _fade_to(0.0, 0.3)
	_busy = false


func _reduced_motion() -> bool:
	var game := get_node_or_null("/root/Game")
	return game != null and game.settings != null and game.settings.reduce_motion


func _fade_to(alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, duration)
	await tween.finished
