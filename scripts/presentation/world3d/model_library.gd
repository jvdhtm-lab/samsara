class_name ModelLibrary
extends RefCounted
## Loads optional CC0 GLB/FBX/GLTF/OBJ models for the 3D world, from KayKit's
## Forest Nature Pack, Quaternius, and Kenney. See docs/CREDITS.md.
##
## Graceful absence: if a model file is missing, callers fall back to primitive
## meshes, so the game always runs. Models are auto-fitted to a target size so
## unknown source scales self-correct.
##
## Ids are paths relative to `assets/models/` (e.g. "nature/tree_default",
## "chars/minion-a01", "cooking/Kettle/misc_kettle"). A bare id defaults to the
## nature folder.

const ROOT := "res://assets/models/"
const SCENE_EXTS := [".glb", ".gltf", ".fbx"]

# KayKit Forest Nature Pack (CC0) — nicer stylized trees/rocks/bushes/grass.
const TREES: Array[String] = [
	"kaykit_forest/Assets/gltf/Tree_1_A_Color1",
	"kaykit_forest/Assets/gltf/Tree_2_A_Color1",
	"kaykit_forest/Assets/gltf/Tree_2_C_Color1",
	"kaykit_forest/Assets/gltf/Tree_3_A_Color1",
	"kaykit_forest/Assets/gltf/Tree_4_A_Color1",
	"kaykit_forest/Assets/gltf/Tree_4_C_Color1",
	"kaykit_forest/Assets/gltf/Tree_Bare_1_A_Color1",
	"town/tree-high",
	"nature/tree_pineTallA_detailed",
]
const ROCKS: Array[String] = [
	"kaykit_forest/Assets/gltf/Rock_1_A_Color1",
	"kaykit_forest/Assets/gltf/Rock_2_A_Color1",
	"kaykit_forest/Assets/gltf/Rock_3_A_Color1",
	"nature/rock_largeA",
	"survival/rock-a",
]
const PLANTS: Array[String] = [
	"kaykit_forest/Assets/gltf/Bush_1_A_Color1",
	"kaykit_forest/Assets/gltf/Bush_2_A_Color1",
	"kaykit_forest/Assets/gltf/Bush_3_A_Color1",
	"kaykit_forest/Assets/gltf/Bush_4_A_Color1",
	"nature/plant_bush",
]
const FLOWERS: Array[String] = [
	"nature/flower_purpleA", "nature/flower_redA", "nature/flower_yellowA",
]
const DETAILS: Array[String] = [
	"kaykit_forest/Assets/gltf/Grass_1_A_Color1",
	"kaykit_forest/Assets/gltf/Grass_2_A_Color1",
	"nature/grass_leafs",
	"nature/mushroom_red",
	"nature/stump_round",
]
## Decor pieces used by the world per location.
const TOWN_PROPS: Array[String] = [
	"town/fountain-round", "town/stall-red", "town/stall-green", "town/banner-red",
	"town/banner-green", "town/windmill", "town/hedge", "town/cart", "town/chimney",
]
const CAMP_PROPS: Array[String] = [
	"survival/campfire-pit", "survival/tree-log", "survival/rock-a", "survival/resource-stone-large",
]
## Kitchen props (free) for the picnic / workshop.
const KITCHEN: Array[String] = [
	"cooking/Kettle/misc_kettle",
	"cooking/Casserole Pot/pan_casserole_pot",
	"cooking/Cutting Board/board_cutting_board_001",
	"cooking/Charcuterie Board/board_charcuterie_board",
	"cooking/Big Spoon/cutensils_big_spoon",
	"cooking/Fork/utensil_fork",
	"cooking/Glass/sercups_glass",
	"cooking/Goblet/sercups_goblet",
	"cooking/Measuring Cup/mcup_measuring_cup_small",
	"cooking/Beer Mug/sercups_beer_mug",
]

static var _cache: Dictionary = {}


static func path_for(id: String) -> String:
	return ROOT + (id if id.contains("/") else "nature/" + id)


static func has_model(id: String) -> bool:
	var base := path_for(id)
	for ext in SCENE_EXTS:
		if ResourceLoader.exists(base + ext):
			return true
	return ResourceLoader.exists(base + ".obj")


static func get_scene(id: String) -> PackedScene:
	if _cache.has(id):
		return _cache[id]
	var base := path_for(id)
	for ext in SCENE_EXTS:
		var full: String = base + str(ext)
		if ResourceLoader.exists(full):
			var scene := load(full) as PackedScene
			_cache[id] = scene
			return scene
	return null


## Instantiates a model scaled so its `axis` extent ("height" or "max") equals
## `target`, with its base resting on y = 0. Returns null if unavailable.
## Accepts GLB/GLTF/FBX scenes and OBJ meshes (e.g. "cooking/Kettle/misc_kettle").
static func instantiate(id: String, target: float, axis := "height", yaw := 0.0) -> Node3D:
	var node := _instantiate_scene(id)
	if node == null:
		node = _instantiate_mesh(id)
	if node == null:
		return null
	_fit(node, target, axis)
	node.rotation.y = yaw
	return node


static func group_available(group: Array) -> bool:
	for id in group:
		if has_model(id):
			return true
	return false


## Instantiates a model at its authored scale/orientation (no auto-fit), for
## modular assembly (e.g. houses built from kit pieces).
static func make(id: String) -> Node3D:
	var scene := get_scene(id)
	if scene == null:
		return null
	var node := scene.instantiate() as Node3D
	return node


## Scales an already-instantiated node so its `axis` extent equals `target`,
## with its base on y = 0. Used for character models.
static func fit_node(root: Node3D, target: float, axis := "height") -> void:
	_fit(root, target, axis)


static func _instantiate_scene(id: String) -> Node3D:
	var scene := get_scene(id)
	if scene == null:
		return null
	return scene.instantiate() as Node3D


static func _instantiate_mesh(id: String) -> Node3D:
	var path := path_for(id) + ".obj"
	if not ResourceLoader.exists(path):
		return null
	var mesh := load(path) as Mesh
	if mesh == null:
		return null
	var holder := Node3D.new()
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	holder.add_child(instance)
	return holder


static func _fit(root: Node3D, target: float, axis: String) -> void:
	var bounds := _local_bounds(root)
	var extent := bounds.size.y if axis == "height" else maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	var factor := target / maxf(extent, 0.0001)
	root.scale = Vector3(factor, factor, factor)
	root.position.y = -bounds.position.y * factor


static func _local_bounds(root: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for pair in _meshes(root, Transform3D.IDENTITY):
		var mesh: MeshInstance3D = pair[0]
		var xform: Transform3D = pair[1]
		var aabb := mesh.get_aabb()
		for i in range(8):
			var point := xform * aabb.get_endpoint(i)
			if first:
				result = AABB(point, Vector3.ZERO)
				first = false
			else:
				result = result.expand(point)
	return result


static func _meshes(node: Node, parent_xform: Transform3D) -> Array:
	var out: Array = []
	for child in node.get_children():
		var child_xform := parent_xform
		if child is Node3D:
			child_xform = parent_xform * (child as Node3D).transform
		if child is MeshInstance3D:
			out.append([child, child_xform])
		if child.get_child_count() > 0:
			out.append_array(_meshes(child, child_xform))
	return out
