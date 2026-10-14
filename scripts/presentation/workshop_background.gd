class_name WorkshopBackground
extends Node2D
## Cozy workshop interior: warm walls, plank floor, a window, shelves with
## jars, and a workbench. Placeholder-but-intentional interior art.

const WALL := Color("#e8cdb0")
const WALL_DARK := Color("#d3b18f")
const FLOOR := Color("#c49a6c")
const FLOOR_DARK := Color("#a87f55")
const WOOD := Color("#9d7a52")
const WOOD_DARK := Color("#7c5f3e")
const GLOW := Color("#ffe9a8")


func _ready() -> void:
	z_index = -10


func _draw() -> void:
	_draw_room()
	_draw_window()
	_draw_shelf(Vector2(120.0, 150.0))
	_draw_shelf(Vector2(500.0, 150.0))
	_draw_bench(Vector2(300.0, 190.0))
	_draw_glow()


func _draw_room() -> void:
	draw_rect(Rect2(0.0, 0.0, 640.0, 360.0), WALL)
	for i in range(6):
		var y := 300.0 + float(i) * 10.0
		draw_rect(Rect2(0.0, y, 640.0, 6.0), FLOOR.darkened(0.04 * float(i)))
	draw_rect(Rect2(0.0, 300.0, 640.0, 60.0), FLOOR)
	for x in range(0, 660, 48):
		draw_line(Vector2(float(x), 300.0), Vector2(float(x - 30), 360.0), FLOOR_DARK, 2.0)
	draw_rect(Rect2(0.0, 0.0, 640.0, 26.0), WALL_DARK)
	draw_rect(Rect2(0.0, 292.0, 640.0, 10.0), WALL_DARK)


func _draw_window() -> void:
	var frame := Rect2(280.0, 40.0, 90.0, 70.0)
	draw_rect(frame.grow(4.0), WOOD_DARK)
	draw_rect(frame, Color("#cfe8f0"))
	draw_rect(Rect2(323.0, 40.0, 4.0, 70.0), WOOD_DARK)
	draw_rect(Rect2(280.0, 72.0, 90.0, 4.0), WOOD_DARK)
	draw_circle(Vector2(350.0, 60.0), 16.0, Color(1.0, 0.95, 0.75, 0.35))


func _draw_shelf(origin: Vector2) -> void:
	draw_rect(Rect2(origin.x - 40.0, origin.y, 80.0, 8.0), WOOD)
	for i in range(3):
		var jar := Color("#a8d8c8") if i % 2 == 0 else Color("#f0b8a0")
		draw_rect(Rect2(origin.x - 32.0 + float(i) * 24.0, origin.y - 20.0, 16.0, 20.0), jar)
		draw_rect(Rect2(origin.x - 34.0 + float(i) * 24.0, origin.y - 24.0, 20.0, 5.0), WOOD_DARK)


func _draw_bench(origin: Vector2) -> void:
	draw_rect(Rect2(origin.x - 60.0, origin.y, 120.0, 12.0), WOOD)
	draw_rect(Rect2(origin.x - 54.0, origin.y + 12.0, 10.0, 40.0), WOOD_DARK)
	draw_rect(Rect2(origin.x + 44.0, origin.y + 12.0, 10.0, 40.0), WOOD_DARK)
	draw_rect(Rect2(origin.x - 26.0, origin.y - 14.0, 26.0, 14.0), Color("#c9d6de"))
	draw_circle(Vector2(origin.x + 20.0, origin.y - 6.0), 7.0, Color("#e0b86a"))


func _draw_glow() -> void:
	for i in range(5):
		draw_circle(Vector2(325.0, 80.0), 40.0 + float(i) * 22.0, Color(1.0, 0.9, 0.7, 0.03))
	draw_rect(Rect2(0.0, 0.0, 640.0, 360.0), Color(1.0, 0.85, 0.6, 0.04))
