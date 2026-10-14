class_name AreaController
extends Node2D
## Root controller for an explorable area.
##
## Application/presentation boundary. Records the visited location, places the
## player at the requested spawn point, and builds optional collision bounds.

const WALL_LAYER := 1

@export var location_id: StringName = &""
@export var bounds: Rect2 = Rect2()
@export var wall_thickness: float = 24.0
@export var music_id: StringName = &""
@export var ambience_id: StringName = &""


func _ready() -> void:
	if location_id != &"":
		Game.timeline.visit_location(location_id)
	var layout: VillageLayout = null
	if _use_3d_visuals() and location_id == &"village":
		layout = VillageLayout.new(_layout_seed())
		_apply_layout(layout)
	_place_player()
	if bounds.size.x > 0.0 and bounds.size.y > 0.0:
		_build_bounds()
	if music_id != &"":
		AudioManager.play_music(music_id)
	if ambience_id != &"":
		AudioManager.play_ambience(ambience_id)
	if _use_3d_visuals():
		_enable_3d(layout)


## Seed the whole village (layout + look variation) from the timeline.
func _layout_seed() -> int:
	return absi(hash(Game.timeline.timeline_id)) + Game.meta.restart_count * 1013904223


## Moves the 2D gameplay nodes to match the generated plan, so the world the
## player actually collides with matches the 3D build and the map.
func _apply_layout(layout: VillageLayout) -> void:
	_move(&"WorkshopDoor", layout.door_slots[0])
	_move(&"PicnicDoor", layout.door_slots[1])
	_move(&"CellarDoor", layout.door_slots[2])
	_move(&"Lumi", layout.npc_spots[0])
	_move(&"Pip", layout.npc_spots[1])
	_move(&"Momo", layout.npc_spots[2])
	_move(&"Lantern", layout.lantern_spot)
	_move(&"Player", layout.player_spawn)
	_move(&"SpawnDefault", layout.player_spawn)
	_move(&"SpawnFromWorkshop", layout.player_spawn + Vector2(-40.0, 10.0))
	_move(&"SpawnFromCellar", layout.lantern_spot + Vector2(40.0, 10.0))
	_move(&"SpawnFromPicnic", layout.door_slots[1] + Vector2(30.0, 20.0))
	_move(&"VillageSign", layout.plaza["center"] + Vector2(62.0, 44.0))
	_move(&"TreeSign", layout.plaza["center"] + Vector2(-72.0, 48.0))
	_move(&"Crate", layout.plaza["center"] + Vector2(-92.0, 6.0))
	_move(&"Flower", layout.plaza["center"] + Vector2(96.0, 2.0))


func _move(node_name: StringName, pos: Vector2) -> void:
	var node := get_node_or_null(NodePath(node_name)) as Node2D
	if node != null:
		node.position = pos


## Builds the 3D presentation of this area (characters + world) and hides the
## 2D procedural drawing. Gameplay stays in 2D; the 3D layer only mirrors it.
func _enable_3d(layout: VillageLayout = null) -> void:
	var theme := str(Game.timeline.get_flag(&"variation_theme", "clear"))
	var world := _make_world()
	if world == null:
		return
	world.name = "World3D"
	add_child(world)
	world.call("build", self, location_id, theme, layout)
	_hide_2d_visuals()
	if layout != null:
		_add_map(layout)


## A small top-down plan overlay (island, roads, buildings, actors).
func _add_map(layout: VillageLayout) -> void:
	var layer := CanvasLayer.new()
	layer.name = "WorldMapLayer"
	layer.layer = 3
	add_child(layer)
	var map := WorldMap.new()
	map.name = "WorldMap"
	map.setup(self, layout)
	map.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	map.offset_left = -146.0
	map.offset_top = -146.0
	map.offset_right = -30.0
	map.offset_bottom = -30.0
	layer.add_child(map)


func _make_world() -> Node3D:
	var script := load("res://scripts/presentation/world3d/world_3d.gd")
	if script == null:
		push_warning("AreaController: 3D world script missing.")
		return null
	var instance: Variant = script.new()
	return instance as Node3D


func _use_3d_visuals() -> bool:
	return Game.settings != null and Game.settings.use_3d_visuals


func _hide_2d_visuals() -> void:
	for child in get_children():
		if child.name == &"Background":
			child.visible = false
	_hide_recursive(self)


func _hide_recursive(root: Node) -> void:
	for child in root.get_children():
		if child is Interactable:
			child.visible = false
		elif child is PlayerController:
			var visual := child.get_node_or_null("Visual")
			if visual != null:
				visual.visible = false
		if child.get_child_count() > 0:
			_hide_recursive(child)


func _place_player() -> void:
	var player := get_node_or_null("Player") as Node2D
	if player == null:
		return
	var spawn := _find_spawn(Game.consume_spawn())
	if spawn != null:
		player.global_position = spawn.global_position


func _find_spawn(spawn_id: StringName) -> Node2D:
	var fallback: Node2D = null
	for child in get_children():
		if child is SpawnPoint:
			if child.spawn_id == spawn_id:
				return child
			if fallback == null:
				fallback = child
	return fallback


func _build_bounds() -> void:
	var body := StaticBody2D.new()
	body.name = "Bounds"
	body.collision_layer = WALL_LAYER
	body.collision_mask = 0
	add_child(body)

	_add_wall(body, Vector2(bounds.position.x, bounds.position.y - wall_thickness),
		Vector2(bounds.size.x, wall_thickness))
	_add_wall(body, Vector2(bounds.position.x, bounds.end.y),
		Vector2(bounds.size.x, wall_thickness))
	_add_wall(body, Vector2(bounds.position.x - wall_thickness, bounds.position.y),
		Vector2(wall_thickness, bounds.size.y))
	_add_wall(body, Vector2(bounds.end.x, bounds.position.y),
		Vector2(wall_thickness, bounds.size.y))


func _add_wall(parent: Node, position: Vector2, size: Vector2) -> void:
	var wall := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	wall.shape = rect
	wall.position = position + size * 0.5
	parent.add_child(wall)
