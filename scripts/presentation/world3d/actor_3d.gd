class_name Actor3D
extends Node3D
## A 3D, three-quarter-view creature built from primitive meshes and a
## CharacterData resource. Visual layer only: the authoritative position comes
## from the linked 2D gameplay node, which it mirrors each frame.
##
## The camera looks from 45°, so the face is modelled on the front-top of the
## body toward +Z (the camera side). Idle breathing and blinking give life.

var data: CharacterData
var target: CanvasItem

var _group: Node3D
var _eyes: Array[Node3D] = []
var _world: Node3D
var _time := 0.0
var _blink := 0.0
var _blink_timer := 2.0
var _animate := true
var _procedural := true


func use_sphere(world: Node3D) -> void:
	_world = world
	_sync()


func setup(character: CharacterData, link: CanvasItem) -> void:
	data = character
	target = link
	name = "Actor_%s" % (character.display_name if character != null else "?")
	_build()
	_sync()
	_animate = not (Game.settings != null and Game.settings.reduce_motion)
	set_process(true)


func _process(delta: float) -> void:
	_sync()
	if not _animate or not _procedural or _group == null:
		return
	_time += delta
	_group.position.y = sin(_time * 1.8) * 0.6
	_group.scale = Vector3(1.0, 1.0 + sin(_time * 1.8) * 0.015, 1.0)
	_update_blink(delta)


func _sync() -> void:
	if target == null or not is_instance_valid(target):
		return
	if _world != null:
		transform = _world.call("place_flat", target.global_position.x, target.global_position.y)
	else:
		position = Vector3(target.global_position.x, 0.0, target.global_position.y)


func _update_blink(delta: float) -> void:
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink_timer = 2.4 + randf() * 2.8
		_blink = 1.0
	_blink = maxf(0.0, _blink - delta * 7.0)
	for eye in _eyes:
		eye.scale = Vector3(1.0, maxf(0.12, 1.0 - _blink), 1.0)


# --- Build -----------------------------------------------------------------

func _build() -> void:
	if data == null:
		return
	_group = Node3D.new()
	_group.name = "Group"
	add_child(_group)

	var radius := data.body_radius
	_group.add_child(Style3D.blob_shadow(radius))
	if _build_from_model(radius):
		_procedural = false
		return
	var head := _add_body(radius)
	_add_face(head, radius)
	_add_marking(head, radius)
	_add_accessory(head, radius)


## Uses a CC0 model (FBX/GLB) when the character defines one. Returns false to
## fall back to the procedural body.
func _build_from_model(radius: float) -> bool:
	if data.model_id == "":
		return false
	var scene := _load_model(data.model_id)
	if scene == null:
		return false
	var model := scene.instantiate() as Node3D
	if model == null:
		return false
	_group.add_child(model)
	ModelLibrary.fit_node(model, radius * 1.6, "max")
	model.rotation.y = deg_to_rad(data.model_yaw)
	_play_idle(model)
	return true


func _load_model(id: String) -> PackedScene:
	var extensions := [".fbx", ".glb"]
	for ext in extensions:
		var path: String = "res://assets/models/" + id + str(ext)
		if ResourceLoader.exists(path):
			return load(path) as PackedScene
	return null


func _play_idle(root: Node) -> void:
	for child in root.find_children("*", "AnimationPlayer", true, false):
		var player := child as AnimationPlayer
		if player == null:
			continue
		_play_idle_on(player)
		return


func _play_idle_on(player: AnimationPlayer) -> void:
	var names := player.get_animation_list()
	if names.is_empty():
		return
	# A short, named idle clip plays directly.
	for name in names:
		var anim := player.get_animation(name)
		if anim != null and anim.length <= 2.5 and String(name).to_lower().contains("idle"):
			player.play(name)
			return
	# Otherwise the first clip may be idle+attack+dead concatenated: trim to the
	# first third (the idle portion) and loop it.
	var first := names[0]
	var source := player.get_animation(first)
	if source == null:
		player.play(first)
		return
	if source.length > 2.5:
		var trimmed := source.duplicate()
		var cut := source.length / 3.0
		for track in range(trimmed.get_track_count()):
			for key in range(trimmed.track_get_key_count(track) - 1, -1, -1):
				if trimmed.track_get_key_time(track, key) > cut:
					trimmed.track_remove_key(track, key)
		trimmed.loop_mode = Animation.LOOP_LINEAR
		var library := player.get_animation_library("")
		if library == null:
			library = AnimationLibrary.new()
			player.add_animation_library("", library)
		library.add_animation("__idle", trimmed)
		player.play("__idle")
	else:
		player.play(first)


func _add_body(radius: float) -> Dictionary:
	var body_mat := Style3D.toy(data.body_color)
	var shade_mat := Style3D.toy(data.shade_color)
	match data.silhouette:
		CharacterData.Silhouette.PEAR:
			_group.add_child(Style3D.instance(Style3D.sphere(radius * 0.82), body_mat, Vector3(0.0, radius * 0.72, 0.0)))
			_group.add_child(Style3D.instance(Style3D.sphere(radius * 1.08), body_mat, Vector3(0.0, radius * 1.5, 0.0)))
			_belly(radius * 1.05, radius * 1.5, radius * 0.55)
			return {"y": radius * 1.5, "r": radius * 1.08}
		CharacterData.Silhouette.PLUSH:
			var plush := Style3D.instance(Style3D.sphere(radius), body_mat, Vector3(0.0, radius * 0.78, 0.0))
			plush.scale = Vector3(1.22, 0.82, 1.22)
			_group.add_child(plush)
			_belly(radius * 1.1, radius * 0.82, radius * 0.6)
			return {"y": radius * 0.92, "r": radius * 1.16}
		_:
			var body := Style3D.instance(Style3D.sphere(radius), body_mat, Vector3(0.0, radius * 0.85, 0.0))
			body.scale = Vector3(1.0, 0.96, 1.0)
			_group.add_child(body)
			_belly(radius, radius * 0.9, radius * 0.58)
			return {"y": radius * 0.95, "r": radius}


func _belly(radius: float, y: float, forward: float) -> void:
	var patch := Style3D.instance(Style3D.sphere(radius * 0.72), Style3D.toy(data.face_color), Vector3(0.0, y, forward))
	patch.scale = Vector3(0.9, 0.72, 0.5)
	_group.add_child(patch)


func _add_face(head: Dictionary, radius: float) -> void:
	var hy := float(head["y"])
	var hr := float(head["r"])
	var eye_r := radius * (0.30 if data.eye_shape == CharacterData.EyeShape.OVERSIZED else 0.24)
	var sclera_mat := Style3D.matte(data.face_color, 0.5)
	var pupil_mat := Style3D.glossy(data.eye_color, 0.2)
	var glint_mat := Style3D.unshaded(Color(1.0, 1.0, 1.0, 0.95))

	for side in [-1.0, 1.0]:
		var eye := Node3D.new()
		eye.position = Vector3(side * hr * 0.42, hy + hr * 0.42, hr * 0.72)
		var sclera := Style3D.instance(Style3D.sphere(eye_r), sclera_mat)
		sclera.scale = Vector3(1.0, 1.15, 0.7)
		eye.add_child(sclera)
		eye.add_child(Style3D.instance(Style3D.sphere(eye_r * 0.58), pupil_mat, Vector3(0.0, 0.0, eye_r * 0.5)))
		eye.add_child(Style3D.instance(Style3D.sphere(eye_r * 0.22), glint_mat, Vector3(-eye_r * 0.25, eye_r * 0.25, eye_r * 0.78)))
		_group.add_child(eye)
		_eyes.append(eye)

		# brow
		var brow := Style3D.instance(Style3D.box(Vector3(eye_r * 1.5, eye_r * 0.35, eye_r * 0.4)), Style3D.matte(data.shade_color, 0.7))
		brow.position = Vector3(side * hr * 0.42, hy + hr * 0.98, hr * 0.72)
		_group.add_child(brow)

	# mouth
	var mouth := Style3D.instance(Style3D.box(Vector3(radius * 0.38, radius * 0.08, radius * 0.1)), Style3D.matte(data.shade_color, 0.7))
	mouth.position = Vector3(0.0, hy + hr * 0.02, hr * 0.96)
	_group.add_child(mouth)


func _add_marking(head: Dictionary, radius: float) -> void:
	var hy := float(head["y"])
	var hr := float(head["r"])
	var top := hy + hr * 0.86
	match data.marking:
		CharacterData.Marking.STAR:
			_group.add_child(Style3D.instance(Style3D.sphere(radius * 0.16), Style3D.emissive(data.accent_color, 0.3), Vector3(0.0, top, -hr * 0.05)))
		CharacterData.Marking.LEAF:
			var leaf := Style3D.instance(Style3D.cone(radius * 0.16, radius * 0.36), Style3D.matte(data.accent_color, 0.6), Vector3(0.0, top, -hr * 0.05))
			leaf.rotation = Vector3(deg_to_rad(18.0), 0.0, 0.0)
			_group.add_child(leaf)
		CharacterData.Marking.BUTTON:
			_group.add_child(Style3D.instance(Style3D.cylinder(radius * 0.14, radius * 0.14, radius * 0.06), Style3D.matte(data.accent_color, 0.5), Vector3(0.0, top, -hr * 0.05)))


func _add_accessory(head: Dictionary, radius: float) -> void:
	var hy := float(head["y"])
	var hr := float(head["r"])
	match data.accessory:
		CharacterData.Accessory.DROOP_EARS:
			for side in [-1.0, 1.0]:
				var ear := Style3D.instance(Style3D.capsule(radius * 0.28, radius * 0.95), Style3D.toy(data.body_color))
				ear.position = Vector3(side * hr * 1.0, hy + hr * 0.1, -hr * 0.15)
				ear.rotation = Vector3(0.0, 0.0, side * deg_to_rad(-42.0))
				_group.add_child(ear)
		CharacterData.Accessory.LEAF_ANTENNA:
			_group.add_child(_stem(Vector3(0.0, hy + hr, 0.0), radius * 1.15, data.shade_color))
			var leaf := Style3D.instance(Style3D.cone(radius * 0.24, radius * 0.54), Style3D.matte(data.accent_color, 0.6), Vector3(0.0, hy + hr + radius * 1.2, 0.0))
			leaf.rotation = Vector3(deg_to_rad(22.0), 0.0, 0.0)
			_group.add_child(leaf)
		CharacterData.Accessory.BUTTON_STUDS:
			for side in [-1.0, 1.0]:
				_group.add_child(Style3D.instance(Style3D.sphere(radius * 0.13), Style3D.matte(data.accent_color, 0.5), Vector3(side * hr * 0.36, hy + hr * 0.82, hr * 0.3)))
		CharacterData.Accessory.SIMPLE_ANTENNA:
			_group.add_child(_stem(Vector3(0.0, hy + hr, 0.0), radius * 0.95, data.shade_color))
			_group.add_child(Style3D.instance(Style3D.sphere(radius * 0.16), Style3D.emissive(data.accent_color, 0.5), Vector3(0.0, hy + hr + radius * 0.95, 0.0)))


func _stem(base: Vector3, length: float, color: Color) -> Node3D:
	return Style3D.instance(Style3D.cylinder(0.045, 0.05, length), Style3D.matte(color, 0.8), base + Vector3(0.0, length * 0.5, 0.0))
