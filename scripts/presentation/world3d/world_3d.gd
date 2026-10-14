class_name AreaWorld3D
extends Node3D
## Builds a 3D, three-quarter-view representation of an explorable area and
## mirrors the 2D gameplay actors into it. Visual layer only.
##
## Named `AreaWorld3D` because `World3D` is a native Godot resource class.
##
## A 45° orthographic camera frames the area; the 2D gameplay nodes keep
## collision and interaction and only their drawing is hidden. Content is
## generated from primitives with a palette from the timeline's variation theme
## (see ART_BIBLE / ADR-029 / ADR-030).

const VIEW := Vector2(640.0, 360.0)
const WALL_HEIGHT := 40.0
## A 3/4 view: ~40 degrees down, narrow FOV for a "toy world" feel.
const CAMERA_PITCH_DEG := 40.0
const CAMERA_FOV := 38.0
const CAMERA_DISTANCE := 470.0
const FOCUS := Vector3(320.0, 40.0, 205.0)

var _theme := "clear"
var _palette: Dictionary = {}
var _actors: Array[Actor3D] = []
var _prop_count := 0
var _rng := RandomNumberGenerator.new()
var _camera: Camera3D
var _focus := FOCUS
var _player: Node2D
var _layout: VillageLayout


func build(area: Node, location_id: StringName, theme := "clear", layout: VillageLayout = null) -> void:
	_theme = theme
	_layout = layout
	_palette = TimelineVariation.palette(theme)
	_rng.seed = absi(hash(theme)) + 20260113
	_player = _find_player(area)
	_sphere_enabled = location_id == &"village"
	if _sphere_enabled:
		_setup_sphere()
	_setup_view()
	if _sphere_enabled:
		_build_sphere_ground(location_id)
	var bend_start := get_child_count()
	_build_ground(location_id)
	_build_structures(area, location_id)
	_build_props(area)
	_decorate(location_id)
	_add_atmosphere(location_id)
	if _sphere_enabled:
		_bend(bend_start)
	_build_actors(area)
	if _sphere_enabled:
		_spawn_pets()
	set_process(true)


## A population of tiny autonomous critters scattered across the island.
func _spawn_pets() -> void:
	if _player == null or not is_instance_valid(_player) or _layout == null:
		return
	var swarm := PetSwarm.new()
	swarm.name = "Pets"
	add_child(swarm)
	swarm.setup(self, _player, VillageLayout.ISLAND_CENTER, _layout.island_radius, 30)


func _process(delta: float) -> void:
	if _player != null and is_instance_valid(_player):
		var target := Vector3(_player.global_position.x, FOCUS.y, _player.global_position.y)
		_focus = _focus.lerp(target, clampf(delta * 4.0, 0.0, 1.0))
		_update_camera()


func _update_camera() -> void:
	if _camera == null:
		return
	var pitch := deg_to_rad(CAMERA_PITCH_DEG)
	if _sphere_enabled:
		var xf := place_flat(_focus.x, _focus.z)
		var up := xf.basis.y
		var fwd := xf.basis.z
		_camera.position = xf.origin + up * (CAMERA_DISTANCE * sin(pitch)) + fwd * (CAMERA_DISTANCE * cos(pitch))
		_camera.look_at(xf.origin, up)
	else:
		_camera.position = _focus + Vector3(0.0, CAMERA_DISTANCE * sin(pitch), CAMERA_DISTANCE * cos(pitch))
		_camera.look_at(_focus, Vector3.UP)


func _find_player(root: Node) -> Node2D:
	for child in root.get_children():
		if child is PlayerController:
			return child as Node2D
		var found := _find_player(child)
		if found != null:
			return found
	return null


func actor_count() -> int:
	return _actors.size()


func prop_count() -> int:
	return _prop_count


# --- Planet sphere ---------------------------------------------------------
## The village sits on a complete spherical planet. Flat 2D coordinates map onto
## the sphere with an azimuthal projection centred at the village; the camera
## keeps the same 3/4 view but orbits to follow the player across the surface.

const SPHERE_R := 760.0
var _sphere_enabled := false
var _sphere_center := Vector3.ZERO


func _setup_sphere() -> void:
	_sphere_center = Vector3(VillageLayout.ISLAND_CENTER.x, -SPHERE_R, VillageLayout.ISLAND_CENTER.y)


func _normal(x: float, z: float) -> Vector3:
	var d := Vector2(x - VillageLayout.ISLAND_CENTER.x, z - VillageLayout.ISLAND_CENTER.y)
	var dist := d.length()
	if dist < 0.0001:
		return Vector3(0.0, 1.0, 0.0)
	var theta := dist / SPHERE_R
	var phi := atan2(d.y, d.x)
	return Vector3(sin(theta) * cos(phi), cos(theta), sin(theta) * sin(phi))


func _surface(x: float, z: float, y := 0.0) -> Vector3:
	return _sphere_center + _normal(x, z) * (SPHERE_R + y)


## Maps a flat ground position (height y along the surface normal) to a transform
## on the planet, with local +Z pointing "south" (toward the road) and local +Y
## pointing up (the surface normal).
func place_flat(x: float, z: float, y := 0.0) -> Transform3D:
	var n := _normal(x, z)
	var tangent := _surface(x, z + 1.0) - _surface(x, z)
	if tangent.length() < 0.0001:
		tangent = Vector3(0.0, 0.0, -1.0)
	tangent = tangent.normalized()
	return Transform3D(Basis.looking_at(-tangent, n), _surface(x, z, y))


## Bends the flat content added since `start_index` onto the sphere surface.
func _bend(start_index: int) -> void:
	for i in range(start_index, get_child_count()):
		var child := get_child(i) as Node3D
		if child == null:
			continue
		var t := child.transform
		child.transform = place_flat(t.origin.x, t.origin.z, t.origin.y) * Transform3D(t.basis, Vector3.ZERO)


func _build_sphere_ground(location_id: StringName) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = SPHERE_R
	mesh.height = SPHERE_R * 2.0
	mesh.radial_segments = 64
	mesh.rings = 32
	add_child(Style3D.instance(mesh, Style3D.matte(_base_color(location_id), 0.95), _sphere_center))


# --- View / sky / lighting -------------------------------------------------

func _setup_view() -> void:
	var sky_color := _color("sky")
	var ground_color := _color("ground")

	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = sky_color
	sky_material.sky_horizon_color = sky_color.lerp(Color.WHITE, 0.45)
	sky_material.ground_horizon_color = ground_color
	sky_material.ground_bottom_color = ground_color.darkened(0.4)
	sky_material.sun_angle_max = 12.0
	var sky := Sky.new()
	sky.sky_material = sky_material

	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#8FB4E8")
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_exposure = 0.85
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.12
	environment.adjustment_saturation = 1.12
	environment.glow_enabled = true
	environment.glow_hdr_threshold = 1.1
	environment.glow_intensity = 0.4
	environment.glow_bloom = 0.05
	environment.fog_enabled = true
	environment.fog_light_color = Color("#C6DCF0")
	environment.fog_light_energy = 0.5
	environment.fog_density = 0.00035
	environment.fog_sky_affect = 0.3
	environment.ssao_enabled = true
	environment.ssao_radius = 26.0
	environment.ssao_intensity = 1.0
	environment.ssao_power = 1.5
	var world_env := WorldEnvironment.new()
	world_env.name = "Environment"
	world_env.environment = environment
	add_child(world_env)

	var light := DirectionalLight3D.new()
	light.name = "Sun"
	light.rotation_degrees = Vector3(-42.0, -35.0, 0.0)
	light.light_color = Color("#FFE2B8")
	light.light_energy = 1.05
	light.light_angular_distance = 1.6
	light.shadow_enabled = true
	light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	light.directional_shadow_max_distance = 700.0
	light.shadow_blur = 2.0
	light.shadow_bias = 0.04
	light.shadow_normal_bias = 1.0
	add_child(light)

	var camera := Camera3D.new()
	camera.name = "WorldCamera"
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = CAMERA_FOV
	camera.near = 0.5
	camera.far = 4000.0
	add_child(camera)
	camera.current = true
	_camera = camera
	_update_camera()


# --- Ground ----------------------------------------------------------------

func _build_ground(location_id: StringName) -> void:
	if not _sphere_enabled:
		var top_color := _base_color(location_id)
		_disc(300.0, 296.0, 26.0, top_color, Vector3(320.0, -13.0, 200.0))
		_disc(150.0, 298.0, 130.0, Color("#6f5236"), Vector3(320.0, -91.0, 200.0))

	match location_id:
		&"workshop":
			_plane(Vector3(320.0, 0.03, 215.0), Vector2(500.0, 180.0), Color("#c49a6c"))
		&"hollow":
			_plane(Vector3(320.0, 0.03, 225.0), Vector2(480.0, 140.0), Color("#3a3446"))
			_add_rocks(Vector3(320.0, 0.0, 230.0), 120.0, 220.0, 8)
		&"picnic":
			_plane(Vector3(320.0, 0.03, 225.0), Vector2(480.0, 140.0), Color("#8fc77e"))
			_add_grass(Vector3(320.0, 0.0, 225.0), 150.0, 140.0, 90)
			_scatter_plants(Vector3(320.0, 0.0, 225.0), 150.0, 70.0, 24)
		_:
			_roads()
			_ground_detail()
			_scatter_layout()


## Road network + plaza from the generated village plan. Roads are tiled into
## small quads so they curve correctly when bent onto the planet.
func _roads() -> void:
	if _layout == null:
		return
	var road := Color("#cdb891")
	var edge := Color("#b09a72")
	var center: Vector2 = _layout.plaza["center"]
	var pr: float = _layout.plaza["radius"]
	_disc(pr + 3.0, pr + 3.0, 2.0, edge, Vector3(center.x, 0.04, center.y))
	_disc(pr, pr, 2.0, road, Vector3(center.x, 0.05, center.y))
	for rect in _layout.roads:
		_tile_road(rect, edge, road)


func _tile_road(rect: Rect2, edge: Color, road: Color) -> void:
	var step := 22.0
	var nx := maxi(1, int(ceil(rect.size.x / step)))
	var nz := maxi(1, int(ceil(rect.size.y / step)))
	var sx := rect.size.x / float(nx)
	var sz := rect.size.y / float(nz)
	for ix in range(nx):
		for iz in range(nz):
			var cx := rect.position.x + (float(ix) + 0.5) * sx
			var cz := rect.position.y + (float(iz) + 0.5) * sz
			_plane(Vector3(cx, 0.045, cz), Vector2(sx + 2.0, sz + 2.0), edge)
			_plane(Vector3(cx, 0.055, cz), Vector2(sx, sz), road)


func _scatter_layout() -> void:
	if _layout == null:
		return
	for s in _layout.scatter:
		var pos := Vector3(s["pos"].x, 0.0, s["pos"].y)
		if str(s["kind"]) == "flower":
			_flower(pos)
		else:
			_model_at(ModelLibrary.PLANTS[_rng.randi() % ModelLibrary.PLANTS.size()], pos, _rng.randf_range(14.0, 20.0))


func _disc(top_radius: float, bottom_radius: float, height: float, color: Color, center: Vector3) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 48
	add_child(Style3D.instance(mesh, Style3D.matte(color, 0.95), center))


func _base_color(location_id: StringName) -> Color:
	match location_id:
		&"workshop":
			return Color("#caa06c")
		&"hollow":
			return Color("#48415a")
		&"picnic":
			return Color("#7FBF6A")
		_:
			return Color("#7FBF6A")


## Darker grass patches + scattered stones to break up the flat ground.
## Only placed where the plan is clear (never on a road).
func _ground_detail() -> void:
	if _layout == null:
		return
	for i in range(14):
		var p := Vector2(_rng.randf_range(100.0, 540.0), _rng.randf_range(160.0, 300.0))
		if not _layout.is_clear(p, 12.0):
			continue
		var r := _rng.randf_range(16.0, 30.0)
		_disc(r, r, 1.0, Color("#6BAE58"), Vector3(p.x, 0.02, p.y))
	for i in range(10):
		var p := Vector2(_rng.randf_range(110.0, 530.0), _rng.randf_range(200.0, 292.0))
		if not _layout.is_clear(p, 8.0):
			continue
		_model_at(ModelLibrary.ROCKS[_rng.randi() % ModelLibrary.ROCKS.size()], Vector3(p.x, 0.0, p.y), _rng.randf_range(6.0, 11.0), "max")


func _path() -> void:
	# A simple road network the characters can walk along.
	var road := Color("#d8c49a")
	var edge := Color("#b9a276")
	_plane(Vector3(320.0, 0.045, 250.0), Vector2(524.0, 54.0), edge)
	_plane(Vector3(320.0, 0.05, 250.0), Vector2(516.0, 46.0), road)
	_plane(Vector3(320.0, 0.045, 214.0), Vector2(54.0, 86.0), edge)
	_plane(Vector3(320.0, 0.05, 214.0), Vector2(46.0, 86.0), road)
	_plane(Vector3(158.0, 0.05, 246.0), Vector2(130.0, 34.0), road)
	_plane(Vector3(470.0, 0.05, 216.0), Vector2(40.0, 78.0), road)


func _add_grass(center: Vector3, half_x: float, half_z: float, count: int) -> void:
	var blade := Style3D.cone(1.9, 6.0, 6)
	blade.material = Style3D.matte(Color("#6fa84f"), 0.9)
	var transforms: Array = []
	for i in range(count):
		var x := center.x + _rng.randf_range(-half_x, half_x)
		var z := center.z + _rng.randf_range(-half_z, half_z)
		if _layout != null and not _layout.is_clear(Vector2(x, z), 5.0):
			continue
		var s := _rng.randf_range(0.8, 1.7)
		var basis := Basis(Vector3.UP, _rng.randf_range(0.0, TAU)).scaled(Vector3(s, s, s))
		transforms.append(Transform3D(basis, Vector3(x, 3.0 * s, z)))
	if transforms.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = blade
	mm.instance_count = transforms.size()
	for i in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])
	var node := MultiMeshInstance3D.new()
	node.name = "Grass"
	node.multimesh = mm
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)


func _add_rocks(center: Vector3, half_x: float, half_z: float, count: int) -> void:
	for i in range(count):
		var x := center.x + _rng.randf_range(-half_x, half_x)
		var z := center.z + _rng.randf_range(-half_z, half_z)
		var id: String = ModelLibrary.ROCKS[_rng.randi() % ModelLibrary.ROCKS.size()]
		var model := ModelLibrary.instantiate(id, _rng.randf_range(12.0, 22.0), "max", _rng.randf_range(0.0, TAU))
		if model != null:
			model.position.x = x
			model.position.z = z
			add_child(model)
			continue
		var r := _rng.randf_range(3.0, 7.0)
		var rock := Style3D.instance(Style3D.sphere(r, 10, 6), Style3D.matte(Color("#3a3444"), 0.95), Vector3(x, r * 0.5, z))
		rock.scale = Vector3(1.0, 0.65, 1.0)
		rock.rotation = Vector3(0.0, _rng.randf_range(0.0, TAU), 0.0)
		add_child(rock)


# --- Structures ------------------------------------------------------------

func _build_structures(area: Node, location_id: StringName) -> void:
	var bounds := _bounds_of(area)
	match location_id:
		&"village":
			if _layout != null:
				for b in _layout.buildings:
					_house(Vector3(b["pos"].x, 0.0, b["pos"].y), b["size"], b["yaw"], b["wall"], b["roof"], b["accent"])
				for f in _layout.foliage:
					_tree(Vector3(f["pos"].x, 0.0, f["pos"].y), f["scale"])
		&"workshop":
			_walls(bounds, Color("#d3b18f"))
			_shelf(Vector3(120.0, 0.0, 150.0))
			_shelf(Vector3(500.0, 0.0, 150.0))
			_bench(Vector3(300.0, 0.0, 196.0))
		&"hollow":
			_walls(bounds, Color("#221d2c"))
			_big_tree(Vector3(430.0, 0.0, 288.0))
		&"picnic":
			_walls(bounds, Color("#8fae87"))
			_table(Vector3(320.0, 0.0, 232.0))
			for i in range(5):
				_flower(Vector3(200.0 + float(i) * 55.0, 0.0, 288.0))
		_:
			pass


func _bounds_of(area: Node) -> Rect2:
	var value: Variant = area.get("bounds")
	return value if typeof(value) == TYPE_RECT2 else Rect2()


func _walls(bounds: Rect2, color: Color) -> void:
	if bounds.size.x <= 0.0:
		return
	var t := 16.0
	var mat := Style3D.textured(color, Style3D.noise_texture(absi(hash(_theme)) + 3, 0.05), 6.0, 0.9)
	for spec in [
		[Vector3(bounds.get_center().x, WALL_HEIGHT * 0.5, bounds.position.y), Vector3(bounds.size.x, WALL_HEIGHT, t)],
		[Vector3(bounds.get_center().x, WALL_HEIGHT * 0.5, bounds.end.y), Vector3(bounds.size.x, WALL_HEIGHT, t)],
		[Vector3(bounds.position.x, WALL_HEIGHT * 0.5, bounds.get_center().y), Vector3(t, WALL_HEIGHT, bounds.size.y)],
		[Vector3(bounds.end.x, WALL_HEIGHT * 0.5, bounds.get_center().y), Vector3(t, WALL_HEIGHT, bounds.size.y)],
	]:
		add_child(Style3D.instance(Style3D.box(spec[1]), mat, spec[0]))


func _house(center: Vector3, footprint: Vector2, yaw: float, wall: Color, roof: Color, accent := Color("#6b4f34")) -> void:
	# Built from the CC0 Quaternius Medieval Village MegaKit (modular pieces).
	var group := Node3D.new()
	group.name = "House"
	group.position = center
	group.rotation.y = deg_to_rad(yaw)
	add_child(group)

	var s := footprint.x / 4.0        # kit footprint is 4 units; scale to world
	var wall_h := 3.122               # wall model height (kit units)
	var h := wall_h                   # seat the roof on the wall tops

	# The kit's all-in-one door wall (its own door is built into the piece).
	_add_piece(group, "medieval/glTF/Wall_Plaster_Door_Flat", Vector3(-1.0, 0.0, 2.0), 0.0, s)
	_add_piece(group, "medieval/glTF/Wall_Plaster_Window_Wide_Round", Vector3(1.0, 0.0, 2.0), 0.0, s)
	_add_piece(group, "medieval/glTF/Wall_Plaster_Window_Wide_Round", Vector3(-1.0, 0.0, -2.0), 180.0, s)
	_add_piece(group, "medieval/glTF/Wall_Plaster_Straight", Vector3(1.0, 0.0, -2.0), 180.0, s)
	_add_piece(group, "medieval/glTF/Wall_Plaster_Window_Wide_Round", Vector3(-2.0, 0.0, -1.0), 90.0, s)
	_add_piece(group, "medieval/glTF/Wall_Plaster_Straight", Vector3(-2.0, 0.0, 1.0), 90.0, s)
	_add_piece(group, "medieval/glTF/Wall_Plaster_Straight", Vector3(2.0, 0.0, -1.0), -90.0, s)
	_add_piece(group, "medieval/glTF/Wall_Plaster_Window_Wide_Round", Vector3(2.0, 0.0, 1.0), -90.0, s)

	# Solid interior so windows/doors don't see straight through the house.
	var inner_h := wall_h * s - 8.0
	group.add_child(Style3D.instance(Style3D.box(Vector3(footprint.x - 12.0, inner_h, footprint.y - 12.0)), Style3D.matte(Color("#2f2620"), 0.95), Vector3(0.0, inner_h * 0.5, 0.0)))

	_add_piece(group, "medieval/glTF/Roof_RoundTiles_4x4", Vector3(0.0, h, 0.0), 0.0, s)
	_add_piece(group, "medieval/glTF/Roof_Front_Brick4", Vector3(0.0, h, 2.0), 0.0, s)
	_add_piece(group, "medieval/glTF/Roof_Front_Brick4", Vector3(0.0, h, -2.0), 180.0, s)

	if group.get_child_count() == 0:
		# Fallback if the kit is unavailable.
		add_child(Style3D.instance(Style3D.box(Vector3(footprint.x, 64.0, footprint.y)), Style3D.matte(wall, 0.9), Vector3(center.x, 32.0, center.z)))


func _add_piece(parent: Node3D, id: String, pos_units: Vector3, yaw_deg: float, s: float) -> void:
	var model := ModelLibrary.make(id)
	if model == null:
		return
	model.scale = Vector3(s, s, s)
	model.position = pos_units * s
	model.rotation.y = deg_to_rad(yaw_deg)
	parent.add_child(model)


func _tree(base: Vector3, scale: float) -> void:
	var id: String = ModelLibrary.TREES[_rng.randi() % ModelLibrary.TREES.size()]
	var model := ModelLibrary.instantiate(id, 118.0 * scale, "height", _rng.randf_range(0.0, TAU))
	if model != null:
		model.position.x = base.x
		model.position.z = base.z
		add_child(model)
		_add_blob(base, 24.0 * scale)
		return
	var trunk := Style3D.instance(Style3D.cylinder(4.0 * scale, 6.0 * scale, 84.0 * scale), Style3D.matte(Color("#8a6a44"), 0.95), Vector3(base.x, 42.0 * scale, base.z))
	add_child(trunk)
	for spec in [
		[Vector3(base.x, 100.0 * scale, base.z), 30.0 * scale],
		[Vector3(base.x - 20.0 * scale, 88.0 * scale, base.z + 8.0 * scale), 21.0 * scale],
		[Vector3(base.x + 20.0 * scale, 92.0 * scale, base.z - 6.0 * scale), 21.0 * scale],
	]:
		add_child(Style3D.instance(Style3D.sphere(spec[1], 18, 12), Style3D.toy(Color("#8fc77e")), spec[0]))
	_add_blob(base, 34.0 * scale)


func _add_blob(pos: Vector3, radius: float) -> void:
	var shadow := Style3D.blob_shadow(radius)
	shadow.position = pos + Vector3(0.0, 0.04, 0.0)
	add_child(shadow)


## Instantiates a model at (x, z) on the ground, sized to `target`. Returns the
## node (whose y is managed by the fit) or null if the model is unavailable.
func _model_at(id: String, pos: Vector3, target: float, axis := "height") -> Node3D:
	var node := ModelLibrary.instantiate(id, target, axis, _rng.randf_range(0.0, TAU))
	if node == null:
		return null
	node.position.x = pos.x
	node.position.z = pos.z
	add_child(node)
	return node


## Adds location-specific CC0 decor (visual only).
func _decorate(location_id: StringName) -> void:
	match location_id:
		&"village":
			if _layout != null:
				var pc: Vector2 = _layout.plaza["center"]
				_model_at("town/fountain-round", Vector3(pc.x - 62.0, 0.0, pc.y - 6.0), 28.0, "max")
				_model_at("town/stall-red", Vector3(pc.x + 68.0, 0.0, pc.y + 14.0), 26.0)
				_model_at("town/stall-green", Vector3(pc.x + 96.0, 0.0, pc.y - 12.0), 26.0)
				_model_at("town/cart", Vector3(pc.x - 100.0, 0.0, pc.y + 20.0), 20.0)
				_model_at("town/windmill", Vector3(96.0, 0.0, 236.0), 66.0)
		&"hollow":
			_model_at("survival/campfire-pit", Vector3(300.0, 0.0, 252.0), 14.0, "max")
			_model_at("survival/tree-log", Vector3(250.0, 0.0, 268.0), 22.0, "max")
			_model_at("survival/rock-a", Vector3(200.0, 0.0, 256.0), 16.0, "max")
		&"workshop":
			_model_at("survival/barrel", Vector3(140.0, 0.0, 180.0), 22.0)
			_model_at("survival/box-large", Vector3(500.0, 0.0, 182.0), 18.0)
			_model_at("survival/barrel", Vector3(474.0, 0.0, 192.0), 20.0)
			_model_at("survival/bucket", Vector3(180.0, 0.0, 186.0), 12.0)
			_place_cooking("cooking/Beer Mug/sercups_beer_mug", Vector3(300.0, 0.0, 196.0), 9.0, 26.0)
			_place_cooking("cooking/Funnel/funnel_small", Vector3(340.0, 0.0, 198.0), 8.0, 26.0)
		&"picnic":
			_place_cooking("cooking/Kettle/misc_kettle", Vector3(300.0, 0.0, 222.0), 12.0, 29.0)
			_place_cooking("cooking/Casserole Pot/pan_casserole_pot", Vector3(344.0, 0.0, 226.0), 13.0, 29.0)
			_place_cooking("cooking/Cutting Board/board_cutting_board_001", Vector3(320.0, 0.0, 240.0), 15.0, 29.0)
			_place_cooking("cooking/Charcuterie Board/board_charcuterie_board", Vector3(340.0, 0.0, 244.0), 16.0, 29.0)
			_place_cooking("cooking/Glass/sercups_glass", Vector3(306.0, 0.0, 238.0), 7.0, 29.0)
			_place_cooking("cooking/Goblet/sercups_goblet", Vector3(334.0, 0.0, 220.0), 8.0, 29.0)
			_place_cooking("cooking/Big Spoon/cutensils_big_spoon", Vector3(300.0, 0.0, 244.0), 10.0, 29.0)
			_place_cooking("cooking/Fork/utensil_fork", Vector3(350.0, 0.0, 236.0), 10.0, 29.0)
			_place_cooking("cooking/Measuring Cup/mcup_measuring_cup_small", Vector3(312.0, 0.0, 228.0), 8.0, 29.0)
		_:
			pass


## Places a kitchen prop resting on a surface at `base_y` (e.g. a table top).
func _place_cooking(id: String, pos: Vector3, target: float, base_y: float) -> void:
	var node := ModelLibrary.instantiate(id, target, "max")
	if node == null:
		return
	node.position.x = pos.x
	node.position.z = pos.z
	node.position.y += base_y
	add_child(node)


func _scatter_plants(center: Vector3, half_x: float, half_z: float, count: int) -> void:
	for i in range(count):
		var x := center.x + _rng.randf_range(-half_x, half_x)
		var z := center.z + _rng.randf_range(-half_z, half_z)
		var roll := _rng.randf()
		var id: String
		var target: float
		if roll < 0.5:
			id = ModelLibrary.PLANTS[_rng.randi() % ModelLibrary.PLANTS.size()]
			target = _rng.randf_range(16.0, 24.0)
		elif roll < 0.8:
			id = ModelLibrary.FLOWERS[_rng.randi() % ModelLibrary.FLOWERS.size()]
			target = _rng.randf_range(11.0, 15.0)
		else:
			id = ModelLibrary.DETAILS[_rng.randi() % ModelLibrary.DETAILS.size()]
			target = _rng.randf_range(9.0, 16.0)
		var model := ModelLibrary.instantiate(id, target, "height", _rng.randf_range(0.0, TAU))
		if model != null:
			model.position.x = x
			model.position.z = z
			add_child(model)


func _big_tree(base: Vector3) -> void:
	add_child(Style3D.instance(Style3D.cylinder(7.0, 13.0, 140.0), Style3D.matte(Color("#7d6e5c"), 0.95), Vector3(base.x, 70.0, base.z)))
	for offset in [Vector3(0.0, 168.0, 0.0), Vector3(-38.0, 140.0, 8.0), Vector3(38.0, 148.0, -8.0), Vector3(0.0, 128.0, 30.0)]:
		add_child(Style3D.instance(Style3D.sphere(42.0, 18, 12), Style3D.toy(Color("#8fb98c")), base + offset))
	var shadow := Style3D.blob_shadow(58.0)
	shadow.position = base + Vector3(0.0, 0.04, 0.0)
	add_child(shadow)
	# roots
	for i in range(6):
		var angle := TAU * float(i) / 6.0
		var root := Style3D.instance(Style3D.capsule(4.0, 46.0), Style3D.matte(Color("#5c5347"), 0.95), base + Vector3(cos(angle) * 44.0, 6.0, sin(angle) * 44.0))
		root.rotation = Vector3(deg_to_rad(80.0), -angle, 0.0)
		add_child(root)


func _shelf(origin: Vector3) -> void:
	add_child(Style3D.instance(Style3D.box(Vector3(80.0, 6.0, 24.0)), Style3D.matte(Color("#9d7a52"), 0.9), origin + Vector3(0.0, 34.0, 0.0)))
	for i in range(3):
		var jar := Style3D.instance(Style3D.cylinder(5.0, 5.0, 14.0), Style3D.glossy(Color("#a8d8c8") if i % 2 == 0 else Color("#f0b8a0"), 0.35), origin + Vector3(-26.0 + float(i) * 26.0, 41.0, 0.0))
		add_child(jar)


func _bench(center: Vector3) -> void:
	add_child(Style3D.instance(Style3D.box(Vector3(130.0, 10.0, 34.0)), Style3D.matte(Color("#9d7a52"), 0.9), center + Vector3(0.0, 24.0, 0.0)))
	for side in [-1.0, 1.0]:
		add_child(Style3D.instance(Style3D.box(Vector3(10.0, 22.0, 10.0)), Style3D.matte(Color("#7c5f3e"), 0.9), center + Vector3(side * 52.0, 11.0, 0.0)))


func _table(center: Vector3) -> void:
	add_child(Style3D.instance(Style3D.cylinder(38.0, 38.0, 6.0), Style3D.matte(Color("#e8dcc4"), 0.8), center + Vector3(0.0, 26.0, 0.0)))
	add_child(Style3D.instance(Style3D.cylinder(4.0, 4.0, 26.0), Style3D.matte(Color("#a5824f"), 0.9), center + Vector3(0.0, 13.0, 0.0)))


func _flower(base: Vector3) -> void:
	var id: String = ModelLibrary.FLOWERS[_rng.randi() % ModelLibrary.FLOWERS.size()]
	var model := ModelLibrary.instantiate(id, 14.0, "height", _rng.randf_range(0.0, TAU))
	if model != null:
		model.position.x = base.x
		model.position.z = base.z
		add_child(model)
		return
	add_child(Style3D.instance(Style3D.cylinder(0.8, 0.8, 12.0), Style3D.matte(Color("#6ba85f"), 0.9), base + Vector3(0.0, 6.0, 0.0)))
	for i in range(5):
		var angle := TAU * float(i) / 5.0
		add_child(Style3D.instance(Style3D.sphere(3.0, 8, 6), Style3D.toy(Color("#ff8fa3")), base + Vector3(cos(angle) * 4.0, 13.0, sin(angle) * 4.0)))
	add_child(Style3D.instance(Style3D.sphere(2.2), Style3D.emissive(Color("#ffe28a"), 0.4), base + Vector3(0.0, 13.0, 0.0)))


# --- Props / actors --------------------------------------------------------

func _build_props(area: Node) -> void:
	for node in _interactables(area):
		if node is PlayerController or node is NpcController:
			continue
		if not node.visible or not node.enabled:
			continue
		var prop := _prop_for(node)
		if prop != null:
			add_child(prop)
			_prop_count += 1


func _interactables(root: Node) -> Array:
	var found: Array = []
	for child in root.get_children():
		if child is Interactable:
			found.append(child)
		if child.get_child_count() > 0:
			found.append_array(_interactables(child))
	return found


func _prop_for(node: Interactable) -> Node3D:
	var pos := Vector3(node.global_position.x, 0.0, node.global_position.y)
	var key := String(node.name).to_lower()
	var group := Node3D.new()
	group.position = pos

	if key.contains("door"):
		group.add_child(Style3D.instance(Style3D.box(Vector3(30.0, 40.0, 4.0)), Style3D.matte(Color("#6b4f34"), 0.8), Vector3(0.0, 20.0, 0.0)))
		group.add_child(Style3D.instance(Style3D.box(Vector3(22.0, 30.0, 2.0)), Style3D.matte(Color("#8a6a44"), 0.8), Vector3(0.0, 18.0, 3.0)))
		group.add_child(Style3D.instance(Style3D.sphere(1.8), Style3D.glossy(Color("#ffe9a8"), 0.2), Vector3(8.0, 16.0, 4.5)))
		return group
	if key.contains("sign") or key.contains("plaque"):
		group.add_child(Style3D.instance(Style3D.cylinder(2.0, 2.4, 28.0), Style3D.matte(Color("#8a6a44"), 0.9), Vector3(0.0, 14.0, 0.0)))
		group.add_child(Style3D.instance(Style3D.box(Vector3(36.0, 20.0, 4.0)), Style3D.matte(Color("#d9b98a"), 0.85), Vector3(0.0, 32.0, 0.0)))
		group.add_child(Style3D.instance(Style3D.box(Vector3(26.0, 1.6, 1.0)), Style3D.matte(Color("#6b4f34"), 0.9), Vector3(0.0, 36.0, 2.6)))
		group.add_child(Style3D.instance(Style3D.box(Vector3(20.0, 1.6, 1.0)), Style3D.matte(Color("#6b4f34"), 0.9), Vector3(0.0, 32.0, 2.6)))
		return group
	if key.contains("lantern"):
		var lantern_model := ModelLibrary.instantiate("town/lantern", 42.0, "height")
		if lantern_model != null:
			group.add_child(lantern_model)
		else:
			group.add_child(Style3D.instance(Style3D.cylinder(2.4, 3.0, 30.0), Style3D.matte(Color("#5a4a3a"), 0.9), Vector3(0.0, 15.0, 0.0)))
			group.add_child(Style3D.instance(Style3D.sphere(5.0), Style3D.emissive(Color("#ffe9a8"), 0.8), Vector3(0.0, 36.0, 0.0)))
		var lamp := OmniLight3D.new()
		lamp.light_color = Color("#ffe3a0")
		lamp.light_energy = 0.8
		lamp.omni_range = 38.0
		lamp.position = Vector3(0.0, 34.0, 0.0)
		group.add_child(lamp)
		return group
	if key.contains("crate"):
		group.add_child(Style3D.instance(Style3D.box(Vector3(24.0, 22.0, 24.0)), Style3D.matte(Color("#c9a76e"), 0.9), Vector3(0.0, 11.0, 0.0)))
		for side in [-1.0, 1.0]:
			group.add_child(Style3D.instance(Style3D.box(Vector3(25.0, 3.0, 25.0)), Style3D.matte(Color("#8a6a44"), 0.9), Vector3(0.0, 11.0, side * 12.0)))
		return group
	if key.contains("flower"):
		group.add_child(Style3D.instance(Style3D.cylinder(0.8, 0.8, 12.0), Style3D.matte(Color("#6ba85f"), 0.9), Vector3(0.0, 6.0, 0.0)))
		for i in range(5):
			var angle := TAU * float(i) / 5.0
			group.add_child(Style3D.instance(Style3D.sphere(3.0, 8, 6), Style3D.toy(Color("#ff8fa3")), Vector3(cos(angle) * 4.0, 13.0, sin(angle) * 4.0)))
		return group
	if key.contains("device"):
		group.add_child(Style3D.instance(Style3D.box(Vector3(28.0, 18.0, 22.0)), Style3D.glossy(Color("#c9d6de"), 0.35), Vector3(0.0, 9.0, 0.0)))
		group.add_child(Style3D.instance(Style3D.cylinder(6.0, 6.0, 2.0), Style3D.matte(Color("#f4e2b8"), 0.5), Vector3(-5.0, 19.0, 0.0)))
		group.add_child(Style3D.instance(Style3D.sphere(2.0), Style3D.emissive(Color("#ff8a6a"), 0.8), Vector3(7.0, 15.0, 10.0)))
		return group
	if key.contains("teaset") or key.contains("tea"):
		for offset in [Vector2(-12.0, -4.0), Vector2(12.0, -4.0), Vector2(0.0, 10.0)]:
			group.add_child(Style3D.instance(Style3D.cylinder(4.5, 4.5, 6.0), Style3D.glossy(Color("#f3ecff"), 0.3), Vector3(offset.x, 3.0, offset.y)))
		group.add_child(Style3D.instance(Style3D.cylinder(16.0, 16.0, 2.0), Style3D.matte(Color("#e8dcc4"), 0.6), Vector3(0.0, 1.0, 2.0)))
		return group
	if key.contains("leaf"):
		group.add_child(Style3D.instance(Style3D.box(Vector3(12.0, 2.0, 12.0)), Style3D.matte(Color("#b6d3a8"), 0.8), Vector3(0.0, 1.0, 0.0)))
		return group
	if key.contains("panel") or key.contains("nook") or key.contains("secret"):
		group.add_child(Style3D.instance(Style3D.box(Vector3(20.0, 6.0, 20.0)), Style3D.matte(Color("#a5824f"), 0.9), Vector3(0.0, 3.0, 0.0)))
		group.add_child(Style3D.instance(Style3D.box(Vector3(24.0, 2.0, 6.0)), Style3D.matte(Color("#7c5f3e"), 0.9), Vector3(0.0, 6.0, 0.0)))
		return group
	group.add_child(Style3D.instance(Style3D.box(Vector3(16.0, 14.0, 16.0)), Style3D.matte(_color("accent"), 0.85), Vector3(0.0, 7.0, 0.0)))
	return group


func _build_actors(area: Node) -> void:
	for node in _characters(area):
		var actor := Actor3D.new()
		add_child(actor)
		actor.setup(node.data, node)
		if _sphere_enabled:
			actor.use_sphere(self)
		_actors.append(actor)


func _characters(root: Node) -> Array:
	var found: Array = []
	for child in root.get_children():
		if child is PlayerController or child is NpcController:
			found.append(child)
		if child.get_child_count() > 0:
			found.append_array(_characters(child))
	return found


# --- Atmosphere ------------------------------------------------------------

func _add_atmosphere(location_id: StringName) -> void:
	if location_id == &"hollow":
		_add_particles(28, Color("#cfe6a8"), 1.6, Vector3(0.0, 1.2, 0.0), Vector3(300.0, 10.0, 120.0), 5.0)


func _add_particles(amount: int, color: Color, scale: float, drift: Vector3, box: Vector3, lifetime: float) -> void:
	var particles := CPUParticles3D.new()
	particles.name = "Motes"
	particles.amount = amount
	particles.lifetime = lifetime
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = box
	particles.position = FOCUS + Vector3(0.0, 40.0, 0.0)
	particles.direction = drift.normalized()
	particles.spread = 35.0
	particles.gravity = Vector3.ZERO
	particles.initial_velocity_min = 2.0
	particles.initial_velocity_max = 5.0
	particles.scale_amount_min = scale * 0.6
	particles.scale_amount_max = scale * 1.3
	particles.color = color
	particles.mesh = Style3D.sphere(scale, 6, 4)
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(particles)


# --- Primitive helpers -----------------------------------------------------

func _color(key: String) -> Color:
	return _palette.get(key, Color("#a9d99f"))


func _plane(center: Vector3, size: Vector2, color: Color) -> void:
	var node := Style3D.instance(Style3D.plane(size, 1), Style3D.matte(color, 0.95), center)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
