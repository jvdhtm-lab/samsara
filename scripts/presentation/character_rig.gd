class_name CharacterRig
extends Node2D
## Layered, data-driven robot-creature rig with a code-driven animator.
##
## Presentation layer. Owns no game state. Layers draw shape only; the rig
## positions/rotates/scales them and supplies shared animation state:
##   motion      -> body bob / squash / accessory sway        (idle, walk, uncanny_idle)
##   expression  -> eyes, brows, mouth shape                  (neutral, happy, sad, afraid, surprised, uncanny)
##   talking     -> mouth flap
##
## Adding a character is a new CharacterData resource, not new code.
##
## Hierarchy (set in character_rig.tscn):
##   Shadow
##   BackAccessory
##   Body
##     Face / Eyes / Mouth / Marking   (inherit the body's bob and squash)

const EXPRESSIONS := {
	&"neutral": {"eye": 1.0, "brow": &"neutral", "mouth": &"neutral"},
	&"happy": {"eye": 0.6, "brow": &"raised", "mouth": &"smile"},
	&"sad": {"eye": 0.85, "brow": &"down", "mouth": &"frown"},
	&"afraid": {"eye": 1.3, "brow": &"down", "mouth": &"small"},
	&"surprised": {"eye": 1.4, "brow": &"raised", "mouth": &"o"},
	&"uncanny": {"eye": 1.0, "brow": &"neutral", "mouth": &"uneven"},
}

var data: CharacterData

# Public animation state (read by layers; also asserted in tests).
var motion: StringName = &"idle"
var expression: StringName = &"neutral"
var talking := false
var facing := 1.0
var eye_open := 1.0
var mouth_open := 0.0
var brow_state: StringName = &"neutral"
var mouth_shape: StringName = &"neutral"
var body_offset := Vector2.ZERO
var body_rotation := 0.0
var body_scale := Vector2.ONE
var shadow_scale := Vector2.ONE
var accessory_sway := 0.0

var _layers: Array[CharacterLayer] = []
var _body: Node2D
var _back: Node2D
var _time := 0.0
var _blink := 0.0
var _blink_timer := 2.0
var _reduce_motion := false


func _ready() -> void:
	_collect_layers()
	_body = get_node_or_null("Body") as Node2D
	_back = get_node_or_null("BackAccessory") as Node2D
	var game := get_node_or_null("/root/Game")
	if game != null:
		_reduce_motion = game.settings.reduce_motion
	set_process(data != null)


func setup(character: CharacterData) -> void:
	data = character
	motion = character.idle_motion if character.idle_motion != &"" else &"idle"
	for layer in _layers:
		layer.layer_setup(self, data)
	set_process(true)
	queue_redraw()


func _collect_layers() -> void:
	_layers.clear()
	_gather(self)


func _gather(node: Node) -> void:
	for child in node.get_children():
		if child is CharacterLayer:
			_layers.append(child)
		_gather(child)


# --- Public API -----------------------------------------------------------

func set_motion(clip: StringName) -> void:
	if motion == clip:
		return
	if not _is_known_motion(clip):
		clip = &"idle"
	motion = clip


func set_expression(expr: StringName) -> void:
	if expression == expr or not EXPRESSIONS.has(expr):
		return
	expression = expr
	_time = 0.0


func set_talking(on: bool) -> void:
	talking = on


func set_facing(direction: float) -> void:
	if direction > 0.01:
		facing = 1.0
	elif direction < -0.01:
		facing = -1.0


func _is_known_motion(clip: StringName) -> bool:
	return clip == &"idle" or clip == &"walk" or clip == &"uncanny_idle"


# --- Animation ------------------------------------------------------------

func _process(delta: float) -> void:
	tick(delta)


## Advances the animator by `delta` seconds. Public so tests can run it
## deterministically without waiting on frames.
func tick(delta: float) -> void:
	if data == null:
		return
	_time += delta
	_update_blink(delta)
	_update_expression()
	_update_motion()
	_apply_transforms()
	for layer in _layers:
		layer.queue_redraw()


func _update_blink(delta: float) -> void:
	if expression == &"uncanny":
		_blink = 0.0
		return
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink_timer = 2.6 + randf() * 2.4
		_blink = 1.0
	_blink = maxf(0.0, _blink - delta * 6.5)


func _update_expression() -> void:
	var expr: Dictionary = EXPRESSIONS.get(expression, EXPRESSIONS[&"neutral"])
	eye_open = float(expr["eye"]) * (1.0 - _blink)
	brow_state = expr["brow"]
	mouth_shape = expr["mouth"]
	mouth_open = 0.0
	if talking:
		mouth_open = (sin(_time * 12.0) * 0.5 + 0.5) * 0.9


func _update_motion() -> void:
	var damp := 0.0 if _reduce_motion else 1.0
	match motion:
		&"walk":
			var s := sin(_time * 9.0)
			body_offset = Vector2(0.0, -absf(s) * 2.4) * damp
			body_scale = Vector2(1.0 - s * 0.04, 1.0 + s * 0.04)
			body_rotation = s * 0.05 * damp
			accessory_sway = s * 0.12 * damp
			shadow_scale = Vector2(1.0 - absf(s) * 0.06, 1.0 - absf(s) * 0.06)
		&"uncanny_idle":
			var s := sin(_time * 1.1)
			body_offset = Vector2(0.0, s * 1.0) * damp
			body_scale = Vector2.ONE
			body_rotation = sin(_time * 0.6) * 0.03 * damp
			accessory_sway = s * 0.02 * damp
			shadow_scale = Vector2.ONE
		_:
			var s := sin(_time * 2.2)
			body_offset = Vector2(0.0, s * 1.4) * damp
			body_scale = Vector2.ONE
			body_rotation = 0.0
			accessory_sway = s * 0.03 * damp
			shadow_scale = Vector2.ONE


func _apply_transforms() -> void:
	scale = Vector2(facing, 1.0)
	if _body != null:
		_body.position = body_offset
		_body.rotation = body_rotation
		_body.scale = body_scale
	if _back != null:
		_back.rotation = accessory_sway
