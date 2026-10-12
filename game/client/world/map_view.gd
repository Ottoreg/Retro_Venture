class_name MapView
extends Node2D
## Affichage provisoire d'une carte, dessiné avec des formes simples en attendant les graphismes :
## sol, obstacles, joueur, survol de case, aperçu du chemin et déplacement au clic.

signal hovered_cell_changed(cell: Vector2i, walkable: bool)

## Vitesse de marche, en pixels par seconde.
const WALK_SPEED := 170.0

const COLOR_GRASS := Color("7aa35a")
const COLOR_BORDER := Color("6a8f4e")
const COLOR_WATER := Color("4f8fb8")
const COLOR_GRID := Color(0, 0, 0, 0.12)
const COLOR_HOVER_OK := Color(1, 1, 1, 0.35)
const COLOR_HOVER_KO := Color(0.9, 0.2, 0.2, 0.45)
const COLOR_PATH := Color(1.0, 0.92, 0.55, 0.85)
const COLOR_SHADOW := Color(0, 0, 0, 0.25)

const NO_CELL := Vector2i(-1, -1)

var world: World

var _hovered := NO_CELL
var _preview: Array[Vector2i] = []
## Position affichée du joueur sur la grille (fractionnaire pendant la marche).
var _player_pos := Vector2.ZERO
var _walk_queue: Array[Vector2i] = []
## Destination cliquée pendant une marche, jouée à l'arrivée.
var _pending_target := NO_CELL
## Demi-cases du bord, déjà découpées au rectangle de la carte.
var _border_polygons: Array[PackedVector2Array] = []


func setup(p_world: World) -> void:
	world = p_world
	_player_pos = Vector2(world.position_of(World.PLAYER_ID))
	var rect := world.map.screen_rect()
	var rect_polygon := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	_border_polygons.clear()
	for cell in world.map.border_cells():
		_border_polygons.append_array(Geometry2D.intersect_polygons(IsoGrid.diamond(IsoGrid.cell_to_screen(cell)), rect_polygon))
	queue_redraw()


func is_walking() -> bool:
	return not _walk_queue.is_empty()


func _process(delta: float) -> void:
	if _walk_queue.is_empty():
		return
	var next := Vector2(_walk_queue[0])
	var distance := IsoGrid.grid_to_screen(_player_pos).distance_to(IsoGrid.grid_to_screen(next))
	var step := WALK_SPEED * delta
	if distance <= step:
		_player_pos = next
		_walk_queue.remove_at(0)
		if _walk_queue.is_empty():
			_on_walk_finished()
	else:
		_player_pos = _player_pos.lerp(next, step / distance)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if world == null:
		return
	if event is InputEventMouseMotion:
		_set_hovered(IsoGrid.screen_to_cell(get_local_mouse_position()))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell := IsoGrid.screen_to_cell(get_local_mouse_position())
		if is_walking():
			_pending_target = cell
		else:
			_request_move(cell)


func _request_move(cell: Vector2i) -> void:
	var command := {"type": Protocol.CMD_MOVE, "entite": World.PLAYER_ID, "cible": cell}
	for event in world.execute(command):
		_apply_event(event)


func _apply_event(event: Dictionary) -> void:
	# Les refus (clic sur une case inaccessible) sont ignorés pour l'instant.
	if event["type"] == Protocol.EVT_MOVED and event["entite"] == World.PLAYER_ID:
		_walk_queue.append_array(event["chemin"])
		_preview.clear()


func _on_walk_finished() -> void:
	if _pending_target != NO_CELL:
		var target := _pending_target
		_pending_target = NO_CELL
		_request_move(target)
	else:
		_update_preview()


func _set_hovered(cell: Vector2i) -> void:
	if cell == _hovered:
		return
	_hovered = cell
	_update_preview()
	hovered_cell_changed.emit(cell, world.map.is_walkable(cell))


func _update_preview() -> void:
	_preview.clear()
	if not is_walking():
		_preview = world.map.find_path(world.position_of(World.PLAYER_ID), _hovered)
	queue_redraw()


# --- Dessin ---------------------------------------------------------------------------------

func _draw() -> void:
	if world == null:
		return
	var map := world.map
	_draw_ground(map)

	for cell in _preview:
		draw_colored_polygon(_scaled_diamond(IsoGrid.cell_to_screen(cell), 0.35), COLOR_PATH)
	if map.is_inside(_hovered):
		var color := COLOR_HOVER_OK if map.is_walkable(_hovered) else COLOR_HOVER_KO
		draw_colored_polygon(IsoGrid.diamond(IsoGrid.cell_to_screen(_hovered)), color)

	# Objets en relief et joueur, du fond vers l'avant.
	var drawables: Array = []
	for cell: Vector2i in map.obstacles:
		if map.obstacles[cell] not in GameMap.FLAT_OBSTACLES:
			drawables.append([IsoGrid.depth(Vector2(cell)), "obstacle", cell])
	drawables.append([IsoGrid.depth(_player_pos) + 0.01, "joueur", NO_CELL])
	drawables.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for drawable: Array in drawables:
		if drawable[1] == "joueur":
			_draw_player(IsoGrid.grid_to_screen(_player_pos))
		else:
			_draw_obstacle(drawable[2], map.obstacles[drawable[2]])


func _draw_ground(map: GameMap) -> void:
	for polygon in _border_polygons:
		draw_colored_polygon(polygon, COLOR_BORDER)
		var outline := polygon.duplicate()
		outline.append(polygon[0])
		draw_polyline(outline, COLOR_GRID)
	for cell: Vector2i in map.cells():
		var points := IsoGrid.diamond(IsoGrid.cell_to_screen(cell))
		var color := COLOR_WATER if map.obstacles.get(cell) == "eau" else COLOR_GRASS
		# Légère variation de teinte, stable d'une image à l'autre.
		color = color.darkened(float(posmod(cell.x * 7 + cell.y * 13, 5)) * 0.025)
		draw_colored_polygon(points, color)
		points.append(points[0])
		draw_polyline(points, COLOR_GRID)


func _draw_obstacle(cell: Vector2i, kind: String) -> void:
	var base := IsoGrid.cell_to_screen(cell)
	match kind:
		"arbre":
			draw_colored_polygon(_ellipse(base + Vector2(0, 2), 18, 8), COLOR_SHADOW)
			draw_rect(Rect2(base + Vector2(-4, -24), Vector2(8, 24)), Color("6b4a2b"))
			draw_circle(base + Vector2(0, -40), 22, Color("3f6b34"))
			draw_circle(base + Vector2(-6, -46), 11, Color("4f8040"))
		"rocher":
			var points := PackedVector2Array()
			for offset in [Vector2(-20, 2), Vector2(-15, -14), Vector2(2, -20), Vector2(18, -10), Vector2(21, 4), Vector2(0, 9)]:
				points.append(base + offset)
			draw_colored_polygon(points, Color("8c8c86"))
			draw_colored_polygon(PackedVector2Array([base + Vector2(-15, -14), base + Vector2(2, -20), base + Vector2(4, -8)]), Color("a5a59e"))
		"mur":
			_draw_block(base, 40, Color("b49a74"))
		_:
			_draw_block(base, 20, Color.MAGENTA)  # Type inconnu : bien visible pour le corriger.


## Bloc isométrique de hauteur `height` posé sur la case : faces gauche, droite et dessus.
func _draw_block(base: Vector2, height: float, color: Color) -> void:
	var ground := IsoGrid.diamond(base)  # haut, droite, bas, gauche
	var up := Vector2(0, -height)
	draw_colored_polygon(PackedVector2Array([ground[3], ground[2], ground[2] + up, ground[3] + up]), color.darkened(0.25))
	draw_colored_polygon(PackedVector2Array([ground[2], ground[1], ground[1] + up, ground[2] + up]), color.darkened(0.4))
	draw_colored_polygon(PackedVector2Array([ground[0] + up, ground[1] + up, ground[2] + up, ground[3] + up]), color)


func _draw_player(base: Vector2) -> void:
	draw_colored_polygon(_ellipse(base, 14, 7), COLOR_SHADOW)
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-11, -2), base + Vector2(11, -2), base + Vector2(7, -30), base + Vector2(-7, -30),
	]), Color("2f5d8a"))
	draw_circle(base + Vector2(0, -38), 8, Color("f0c8a0"))
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-9, -40), base + Vector2(9, -40), base + Vector2(0, -56),
	]), Color("8a3b2f"))


func _scaled_diamond(center: Vector2, scale_factor: float) -> PackedVector2Array:
	var points := IsoGrid.diamond(Vector2.ZERO)
	for i in points.size():
		points[i] = center + points[i] * scale_factor
	return points


func _ellipse(center: Vector2, radius_x: float, radius_y: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 16:
		var angle := TAU * i / 16.0
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points
