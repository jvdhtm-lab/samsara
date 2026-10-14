class_name VillageLayout
extends RefCounted
## A rule-based, per-timeline village plan in world coordinates (XZ).
##
## Generated once per timeline from a seed, then read by `AreaController` (to
## place the 2D gameplay nodes), `AreaWorld3D` (to build the 3D village), and
## `WorldMap` (to draw the plan). Restarting the universe reseeds it, so each
## timeline is an entirely different — but still coherent — world.
##
## Rules keep it sensible: a grid of streets (both axes) crosses the village;
## houses line the streets and face them (their doors open onto a street); 3
## carry the functional doors; NPCs/player stand on the plaza; nothing is ever
## placed on a road or inside a building.

const ISLAND_CENTER := Vector2(450.0, 320.0)
const WORLD_MIN := Vector2(0.0, 0.0)
const WORLD_MAX := Vector2(900.0, 640.0)
const PLAY := Rect2(90.0, 110.0, 720.0, 420.0)
const ROAD_WIDTH := 56.0

const ROOF_COLORS: Array[Color] = [Color("#D9657A"), Color("#9B8AD6"), Color("#C98A5A"), Color("#7FAE5A"), Color("#6FA8DC")]
const ACCENT_COLORS: Array[Color] = [Color("#9B8AD6"), Color("#D9657A"), Color("#6FA8DC"), Color("#E0A24A"), Color("#7FAE5A")]

var seed_value: int
var island_radius := 460.0
var roads: Array = []          # Array[Rect2]
var plaza: Dictionary = {}     # { center: Vector2, radius: float }
var buildings: Array = []      # { pos, size, yaw, wall, roof, accent, door }
var foliage: Array = []        # { pos: Vector2, scale: float }
var scatter: Array = []        # { pos: Vector2, kind: String }
var npc_spots: Array = []      # [lumi, pip, momo] Vector2
var door_slots: Array = []     # [workshop, picnic, cellar] Vector2
var player_spawn := Vector2.ZERO
var lantern_spot := Vector2.ZERO


func _init(seed_value_in := 0) -> void:
	seed_value = seed_value_in
	_generate()


func _generate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var w := ROAD_WIDTH
	island_radius = rng.randf_range(430.0, 500.0)

	# Streets on both axes (2 of 3 chosen each), spanning the island.
	var hz := _pick(rng, [200.0, 320.0, 450.0], 2)
	var vx := _pick(rng, [210.0, 450.0, 690.0], 2)
	var x0 := ISLAND_CENTER.x - island_radius + 44.0
	var x1 := ISLAND_CENTER.x + island_radius - 44.0
	var z0 := ISLAND_CENTER.y - island_radius + 44.0
	var z1 := ISLAND_CENTER.y + island_radius - 44.0
	roads = []
	for z in hz:
		roads.append(Rect2(x0, z - w * 0.5, x1 - x0, w))
	for x in vx:
		roads.append(Rect2(x - w * 0.5, z0, w, z1 - z0))

	var plaza_x := _nearest(vx, ISLAND_CENTER.x)
	var plaza_z := _nearest(hz, ISLAND_CENTER.y)
	var center := Vector2(plaza_x, plaza_z)
	plaza = {"center": center, "radius": rng.randf_range(58.0, 72.0)}

	_generate_buildings(rng, hz, vx, w)
	# Guarantee at least 3 houses (they carry the functional doors).
	while buildings.size() < 3:
		var idx := buildings.size()
		var pos := Vector2(ISLAND_CENTER.x - 130.0 + float(idx) * 130.0, center.y - w * 0.5 - 62.0)
		buildings.append(_building(pos, Vector2(88.0, 88.0), 0.0, ROOF_COLORS[idx % ROOF_COLORS.size()], ACCENT_COLORS[idx % ACCENT_COLORS.size()]))
	door_slots = [buildings[0]["door"], buildings[1]["door"], buildings[2]["door"]]

	npc_spots = [
		_clamp(center + Vector2(-30.0, 14.0)),
		_clamp(center + Vector2(34.0, -10.0)),
		_clamp(center + Vector2(8.0, 34.0)),
	]
	player_spawn = _clamp(center + Vector2(0.0, 46.0))
	lantern_spot = _clamp(center + Vector2(0.0, -28.0))

	_generate_foliage(rng)
	_generate_scatter(rng)


func _pick(rng: RandomNumberGenerator, values: Array, count: int) -> Array:
	var copy := values.duplicate()
	var out: Array = []
	for i in range(count):
		var idx := rng.randi_range(0, copy.size() - 1)
		out.append(copy[idx])
		copy.remove_at(idx)
	return out


func _nearest(values: Array, target: float) -> float:
	var best: float = values[0]
	for v in values:
		if absf(float(v) - target) < absf(best - target):
			best = float(v)
	return best


func _generate_buildings(rng: RandomNumberGenerator, hz: Array, vx: Array, w: float) -> void:
	var gap := 56.0
	for z in hz:
		var x := ISLAND_CENTER.x - island_radius + 90.0
		while x < ISLAND_CENTER.x + island_radius - 90.0:
			_try_building(Vector2(x + rng.randf_range(-12.0, 12.0), z - w * 0.5 - gap), 0.0, rng)
			_try_building(Vector2(x + rng.randf_range(-12.0, 12.0), z + w * 0.5 + gap), 180.0, rng)
			x += rng.randf_range(150.0, 210.0)
	for x in vx:
		var z := ISLAND_CENTER.y - island_radius + 90.0
		while z < ISLAND_CENTER.y + island_radius - 90.0:
			_try_building(Vector2(x - w * 0.5 - gap, z + rng.randf_range(-12.0, 12.0)), 90.0, rng)
			_try_building(Vector2(x + w * 0.5 + gap, z + rng.randf_range(-12.0, 12.0)), -90.0, rng)
			z += rng.randf_range(150.0, 210.0)


func _try_building(pos: Vector2, yaw: float, rng: RandomNumberGenerator) -> void:
	if buildings.size() >= 12:
		return
	var s := rng.randf_range(80.0, 104.0)
	if not _free(pos, s * 0.55 + 8.0):
		return
	buildings.append(_building(pos, Vector2(s, s), yaw, ROOF_COLORS[buildings.size() % ROOF_COLORS.size()], ACCENT_COLORS[buildings.size() % ACCENT_COLORS.size()]))


func _building(pos: Vector2, size: Vector2, yaw: float, roof: Color, accent: Color) -> Dictionary:
	# The kit door sits on the front wall's left segment (1 kit unit left of centre).
	var local_door := Vector2(-size.x * 0.25, size.y * 0.5).rotated(deg_to_rad(yaw))
	return {
		"pos": pos,
		"size": size,
		"yaw": yaw,
		"wall": Color("#EBCBA0"),
		"roof": roof,
		"accent": accent,
		"door": pos + local_door,
	}


func _generate_foliage(rng: RandomNumberGenerator) -> void:
	var target := rng.randi_range(18, 30)
	var tries := 0
	while foliage.size() < target and tries < 800:
		tries += 1
		var angle := rng.randf_range(0.0, TAU)
		var radius := rng.randf_range(island_radius * 0.72, island_radius - 16.0)
		var pos := ISLAND_CENTER + Vector2(cos(angle), sin(angle)) * radius
		if not _free(pos, 30.0):
			continue
		foliage.append({"pos": pos, "scale": rng.randf_range(0.8, 1.3)})


func _generate_scatter(rng: RandomNumberGenerator) -> void:
	var kinds := ["plant", "plant", "flower", "flower", "plant", "flower"]
	var target := rng.randi_range(26, 48)
	var tries := 0
	while scatter.size() < target and tries < 1400:
		tries += 1
		var pos := ISLAND_CENTER + Vector2(rng.randf_range(-island_radius * 0.72, island_radius * 0.72), rng.randf_range(-island_radius * 0.55, island_radius * 0.55))
		if not _free(pos, 22.0):
			continue
		scatter.append({"pos": pos, "kind": kinds[rng.randi() % kinds.size()]})


func _clamp(point: Vector2) -> Vector2:
	return Vector2(
		clampf(point.x, PLAY.position.x, PLAY.end.x),
		clampf(point.y, PLAY.position.y, PLAY.end.y)
	)


## True if a point is clear of roads, plaza, buildings and existing foliage.
func is_clear(pos: Vector2, margin: float) -> bool:
	return _free(pos, margin)


func _free(pos: Vector2, margin: float) -> bool:
	if pos.distance_to(ISLAND_CENTER) > island_radius - 18.0:
		return false
	if pos.distance_to(plaza["center"]) < float(plaza["radius"]) + margin:
		return false
	for rect in roads:
		if (rect as Rect2).grow(margin).has_point(pos):
			return false
	for b in buildings:
		var r := Rect2(b["pos"] - (b["size"] as Vector2) * 0.55, (b["size"] as Vector2) * 1.1)
		if r.grow(margin).has_point(pos):
			return false
	for f in foliage:
		if pos.distance_to(f["pos"]) < 26.0:
			return false
	return true
