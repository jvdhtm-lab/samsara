class_name WorldMap
extends Control
## A small circular plan overlay: the island, roads, plaza, buildings, foliage,
## and live actor dots, drawn from the timeline's generated `VillageLayout`.

var _area: Node
var _layout: VillageLayout


func setup(area: Node, layout: VillageLayout) -> void:
	_area = area
	_layout = layout
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _layout == null or size.x <= 4.0:
		return
	var radius := minf(size.x, size.y) * 0.5 - 6.0
	var center := size * 0.5
	var scale := radius / _layout.island_radius

	draw_circle(center, radius, Color(0.07, 0.08, 0.12, 0.72))
	draw_circle(_map(VillageLayout.ISLAND_CENTER, scale, center), _layout.island_radius * scale, Color(0.44, 0.68, 0.42, 0.55))

	var pc: Vector2 = _layout.plaza["center"]
	var pr: float = _layout.plaza["radius"]
	draw_circle(_map(pc, scale, center), pr * scale, Color(0.85, 0.78, 0.62, 0.95))
	for rect in _layout.roads:
		draw_rect(_rect(rect, scale, center), Color(0.85, 0.78, 0.62, 0.95))
	for b in _layout.buildings:
		var pos: Vector2 = b["pos"]
		var sz: Vector2 = b["size"]
		draw_rect(_rect(Rect2(pos - sz * 0.5, sz), scale, center), Color(0.96, 0.86, 0.72, 0.98))
	for f in _layout.foliage:
		draw_circle(_map(f["pos"], scale, center), 1.8, Color(0.30, 0.58, 0.32, 1.0))
	for node in _actors():
		var color := Color(0.60, 0.85, 1.0) if node is PlayerController else Color(1.0, 0.62, 0.40)
		draw_circle(_map(node.global_position, scale, center), 2.6, color)

	draw_arc(center, radius, 0.0, TAU, 64, Color(0.92, 0.92, 1.0, 0.5), 2.0, true)
	var north := center + Vector2(0.0, -radius)
	draw_colored_polygon(PackedVector2Array([north + Vector2(0.0, -7.0), north + Vector2(-5.0, 2.0), north + Vector2(5.0, 2.0)]), Color(0.95, 0.95, 1.0, 0.9))


func _map(point: Vector2, scale: float, center: Vector2) -> Vector2:
	return center + (point - VillageLayout.ISLAND_CENTER) * scale


func _rect(rect: Rect2, scale: float, center: Vector2) -> Rect2:
	return Rect2(_map(rect.position, scale, center), rect.size * scale)


func _actors() -> Array:
	var out: Array = []
	_collect(_area, out)
	return out


func _collect(root: Node, out: Array) -> void:
	for child in root.get_children():
		if child is PlayerController or child is NpcController:
			out.append(child)
		_collect(child, out)
