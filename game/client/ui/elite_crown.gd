class_name EliteCrown
extends Control
## Ancienneté d'un monstre élite dans la bulle de son groupe : un petit losange doré par rang
## (5 au plus sur la ligne), puis, à partir du 6e rang, des triangles au-dessus qui forment une
## couronne.

const STEP := 18.0
const ROW := 16.0
const GOLD := Color("f2c14e")
const OUTLINE := Color("5a3a10")

var rank := 0:
	set(value):
		rank = clampi(value, 0, 10)
		var rows := 0 if rank == 0 else (1 if rank <= 5 else 2)
		custom_minimum_size = Vector2(5 * STEP, rows * ROW + (2.0 if rows > 0 else 0.0))
		visible = rank > 0
		queue_redraw()


func diamonds() -> int:
	return mini(rank, 5)


func triangles() -> int:
	return maxi(0, rank - 5)


func _draw() -> void:
	var center_x := size.x / 2.0
	var diamond_y := ROW * (2 if triangles() > 0 else 1) - ROW / 2.0 + 1.0
	for i in diamonds():
		var x := center_x + (i - (diamonds() - 1) / 2.0) * STEP
		_shape(PackedVector2Array([Vector2(x, diamond_y - 7), Vector2(x + 5.5, diamond_y), Vector2(x, diamond_y + 7), Vector2(x - 5.5, diamond_y)]))
	var triangle_y := ROW / 2.0 + 1.0
	for i in triangles():
		var x := center_x + (i - (triangles() - 1) / 2.0) * STEP
		_shape(PackedVector2Array([Vector2(x - 6, triangle_y + 6), Vector2(x + 6, triangle_y + 6), Vector2(x, triangle_y - 6)]))


func _shape(points: PackedVector2Array) -> void:
	draw_colored_polygon(points, GOLD)
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, OUTLINE, 1.2, true)
