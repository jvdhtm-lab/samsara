class_name PlayerController
extends CharacterBody2D
## Top-down player controller with interaction probing and rig animation.
##
## Presentation layer. Reads input, moves via physics, drives the character
## rig, and forwards interaction requests to Interactables. It never mutates
## game state directly.

const SPEED := 96.0
const ACCEL := 720.0
const FRICTION := 1200.0
const PROBE_RADIUS := 26.0

@export var data: CharacterData

var _rig: CharacterRig
var _probe: Area2D
var _targets: Array[Interactable] = []
var _current: Interactable


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	_setup_visual()
	_setup_probe()
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_finished.connect(_on_dialogue_finished)


func _setup_visual() -> void:
	_rig = get_node_or_null("Visual") as CharacterRig
	if _rig != null and data != null:
		_rig.setup(data)


func _setup_probe() -> void:
	_probe = get_node_or_null("InteractionProbe") as Area2D
	if _probe == null:
		_probe = Area2D.new()
		_probe.name = "InteractionProbe"
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = PROBE_RADIUS
		shape.shape = circle
		_probe.add_child(shape)
		add_child(_probe)
	_probe.collision_layer = 0
	_probe.collision_mask = 4
	_probe.monitoring = true
	_probe.area_entered.connect(_on_area_entered)
	_probe.area_exited.connect(_on_area_exited)


func _physics_process(delta: float) -> void:
	if Game.in_dialogue:
		velocity = Vector2.ZERO
		move_and_slide()
		if _rig != null:
			_rig.set_motion(&"idle")
		return

	var direction := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	var target := direction * SPEED
	if Game.settings.reduce_motion:
		velocity = target
	else:
		var rate := ACCEL if direction.length_squared() > 0.01 else FRICTION
		velocity = velocity.move_toward(target, rate * delta)
	move_and_slide()

	if _rig != null:
		_rig.set_facing(direction.x)
		_rig.set_motion(&"walk" if direction.length_squared() > 0.01 else &"idle")
	_refresh_target()


func _unhandled_input(event: InputEvent) -> void:
	if Game.in_dialogue:
		return
	if event.is_action_pressed("use_magic"):
		Game.use_magic(Game.context_ability())
		get_viewport().set_input_as_handled()
		return
	if _current == null:
		return
	if event.is_action_pressed("interact") and _current.can_interact(self):
		_current.interact(self)
		get_viewport().set_input_as_handled()


func _on_area_entered(area: Area2D) -> void:
	var interactable := area as Interactable
	if interactable != null and not _targets.has(interactable):
		_targets.append(interactable)
	_refresh_target()


func _on_area_exited(area: Area2D) -> void:
	var interactable := area as Interactable
	if interactable != null:
		_targets.erase(interactable)
	_refresh_target()


func _refresh_target() -> void:
	var candidates: Array[Interactable] = []
	for candidate in _targets:
		if is_instance_valid(candidate) and candidate.can_interact(self):
			candidates.append(candidate)
	var best := InteractionSelector.pick(candidates, global_position)
	if best != _current:
		_current = best
		EventBus.interaction_target_changed.emit(_current)


func _on_dialogue_started(_speaker: StringName, _dialogue: StringName) -> void:
	velocity = Vector2.ZERO
	if _rig != null:
		_rig.set_motion(&"idle")
	EventBus.interaction_target_changed.emit(null)


func _on_dialogue_finished(_dialogue: StringName) -> void:
	_refresh_target()
