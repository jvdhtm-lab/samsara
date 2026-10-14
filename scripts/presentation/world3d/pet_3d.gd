class_name Pet3D
extends Node3D
## A tiny autonomous critter. Purely decorative — no gameplay collision and not
## interactable. It wanders the island, sometimes randomly follows the player,
## is nice to other critters (hearts / "I love you!"), and sometimes fights —
## with a chance of killing the loser.

enum State { WANDER, FOLLOW, GREET, FIGHT, DEAD }

var _world: Node3D
var _swarm: PetSwarm
var _group: Node3D
var _bubble: Label3D
var _pos := Vector2.ZERO
var _target := Vector2.ZERO
var _state := State.WANDER
var _timer := 0.0
var _cool := 0.0
var _bob := 0.0
var _alive := true
var _speed := 34.0
var _will_die := false
var _opponent: Pet3D


func setup(world: Node3D, swarm: PetSwarm, model_id: String, start_pos: Vector2) -> void:
	_world = world
	_swarm = swarm
	_pos = start_pos
	_build(model_id)
	_pick_wander()
	_timer = randf_range(1.0, 4.0)
	_sync()
	set_process(true)


func is_alive() -> bool:
	return _alive


func pos2d() -> Vector2:
	return _pos


func die() -> void:
	if not _alive:
		return
	_alive = false
	_hide_bubble()
	var tween := create_tween()
	tween.tween_property(_group, "scale", Vector3.ZERO, 0.45)
	tween.tween_callback(queue_free)


func _build(model_id: String) -> void:
	_group = Node3D.new()
	add_child(_group)
	var model := ModelLibrary.instantiate(model_id, 14.0, "max")
	if model != null:
		_group.add_child(model)

	_bubble = Label3D.new()
	_bubble.font_size = 40
	_bubble.pixel_size = 0.007
	_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bubble.outline_modulate = Color(1.0, 1.0, 1.0)
	_bubble.outline_size = 8
	_bubble.position = Vector3(0.0, 26.0, 0.0)
	_bubble.visible = false
	add_child(_bubble)


func _player_pos() -> Vector2:
	if _swarm == null or _swarm.player() == null or not is_instance_valid(_swarm.player()):
		return _pos
	var p := _swarm.player()
	return Vector2(p.global_position.x, p.global_position.y)


func _pick_wander() -> void:
	var angle := randf() * TAU
	var radius := randf_range(40.0, 170.0)
	_target = _pos + Vector2(cos(angle), sin(angle)) * radius


func _process(delta: float) -> void:
	if not _alive:
		return
	_timer -= delta
	_cool = maxf(0.0, _cool - delta)
	_bob += delta

	match _state:
		State.WANDER:
			_move(_target, _speed * 0.5, delta)
			if _pos.distance_to(_target) < 8.0 or _timer <= 0.0:
				if randf() < 0.35:
					_state = State.FOLLOW
					_timer = randf_range(4.0, 9.0)
				else:
					_pick_wander()
					_timer = randf_range(2.0, 5.0)
		State.FOLLOW:
			var phase := float(get_instance_id() % 100) + _bob
			var orbit := Vector2(cos(phase * 0.6), sin(phase * 0.8)) * 40.0
			_move(_player_pos() + orbit, _speed, delta)
			if _timer <= 0.0:
				_state = State.WANDER
				_pick_wander()
				_timer = randf_range(2.0, 5.0)
		State.GREET:
			_move(_target, _speed * 0.4, delta)
			if _timer <= 0.0:
				_hide_bubble()
				_state = State.WANDER
				_timer = randf_range(2.0, 5.0)
		State.FIGHT:
			_move(_target, _speed * 0.9, delta)
			_group.position.x = sin(_bob * 26.0) * 2.2
			if _timer <= 0.0:
				_resolve_fight()

	if _state == State.WANDER or _state == State.FOLLOW:
		_try_interact()
	_sync()
	_group.position.y = 2.0 + sin(_bob * 3.0) * 1.6


func _move(target: Vector2, speed: float, delta: float) -> void:
	_pos = _pos.move_toward(target, speed * delta)


func _sync() -> void:
	if _world != null:
		transform = _world.call("place_flat", _pos.x, _pos.y)


func _try_interact() -> void:
	if _cool > 0.0 or _swarm == null:
		return
	var near := _swarm.neighbors(self, 48.0)
	if near.is_empty():
		return
	var other: Pet3D = near[randi() % near.size()]
	if other == null or other._state != State.WANDER and other._state != State.FOLLOW:
		return
	var roll := randf()
	if roll < 0.40:
		_greet(other)
	elif roll < 0.62:
		_fight(other)
	else:
		_cool = randf_range(2.0, 4.0)


func _greet(other: Pet3D) -> void:
	_show_bubble("I love you!" if randf() < 0.6 else "\u2665")
	other._show_bubble("\u2665")
	_state = State.GREET
	_timer = 2.2
	_cool = randf_range(5.0, 9.0)
	other._state = State.GREET
	other._timer = 2.2
	other._cool = randf_range(5.0, 9.0)
	_target = _pos + (_face_dir(other) * 12.0)
	other._target = other._pos - (_face_dir(other) * 12.0)


func _fight(other: Pet3D) -> void:
	_show_bubble("!")
	other._show_bubble("!")
	_state = State.FIGHT
	_timer = 1.2
	_cool = randf_range(6.0, 10.0)
	other._state = State.FIGHT
	other._timer = 1.2
	other._cool = randf_range(6.0, 10.0)
	_target = _pos + (_face_dir(other) * 8.0)
	other._target = other._pos - (_face_dir(other) * 8.0)
	# Decide the loser up front; they die when the fight ends.
	var loser := self if randf() < 0.5 else other
	loser._will_die = true
	other._will_die = other == loser


func _resolve_fight() -> void:
	_hide_bubble()
	_group.position.x = 0.0
	if _will_die:
		_swarm.kill(self)
		return
	_state = State.WANDER
	_timer = randf_range(2.0, 4.0)


func _face_dir(other: Pet3D) -> Vector2:
	var d := other._pos - _pos
	return d.normalized() if d.length() > 0.01 else Vector2.RIGHT


func _show_bubble(text: String) -> void:
	_bubble.text = text
	_bubble.modulate = Color("#ff5a86") if text == "!" else Color("#ff7aa8")
	_bubble.visible = true


func _hide_bubble() -> void:
	if _bubble != null:
		_bubble.visible = false
