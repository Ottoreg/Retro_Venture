class_name Minimap
extends CanvasLayer
## Minicarte : la carte actuelle en miniature, en haut à droite sous le bandeau, en exploration
## seulement (masquée en combat, pour laisser la place à l'ordre de jeu). Sol, obstacles, eau,
## chemins, bords de sortie, portes et Pierre de Passage sont dessinés une fois par carte ; le joueur
## (point bleu), les groupes de monstres (points rouges, dorés pour une élite) et les PNJ (points
## clairs) à chaque image, pendant la marche et les promenades des groupes. Un clic dessus ouvre la
## carte du monde ; ailleurs, les clics vont à la carte.

## Clic sur la minicarte.
signal pressed

## Place maximale du dessin (pixels) : la carte y tient en entier, sans dépasser l'échelle MAX_SCALE.
const MAX_SIZE := Vector2(200, 100)
const MAX_SCALE := 0.2
## Distance au bord droit de l'écran et au haut de l'écran (sous le bandeau du haut).
const MARGIN_RIGHT := 12.0
const TOP := 72.0
const COLOR_PATH := Color("c9a66b")
const COLOR_WATER := Color("4f8fb8")
const COLOR_EXIT := Color(0.98, 0.82, 0.32, 0.9)
const COLOR_DOOR := Color("e0b060")
const COLOR_STONE := Color("7fd0f0")
const COLOR_PLAYER := Color("4d8fff")
const COLOR_MONSTER := Color("e0453a")
const COLOR_ELITE := Color("f2c14e")
const COLOR_NPC := Color("f0e6cc")
const COLOR_OUTLINE := Color("1e160f")
## Couleur des obstacles par type ; les autres prennent celle du sol, assombrie.
const OBSTACLE_COLORS := {
	"arbre": Color("2f5a2a"),
	"ressource": Color("3f6a3a"),
	"rocher": Color("8a857a"),
	"mur": Color("6b5440"),
	"bloc": Color("8a4a32"),
}

var map_view: MapView

var _frame: PanelContainer
## Dessin fixe de la carte (sol, obstacles…), puis par-dessus ce qui bouge.
var _ground: Control
var _marks: Control
var _coordinates: Label
var _map: GameMap
var _scale := 0.16


func _ready() -> void:
	_build()
	_frame.visible = false


func setup(p_map_view: MapView) -> void:
	map_view = p_map_view
	map_view.map_changed.connect(refresh)
	map_view.combat_started.connect(refresh)
	map_view.exploration_resumed.connect(refresh)
	refresh()


func is_shown() -> bool:
	return _frame.visible


## Échelle du dessin (pixels de la minicarte par pixel de la carte).
func map_scale() -> float:
	return _scale


## Reprend la carte actuelle (nouvelle carte, début ou fin de combat).
func refresh() -> void:
	if map_view == null or map_view.world == null:
		return
	_frame.visible = map_view.mode == MapView.Mode.EXPLORATION
	_map = map_view.current_map()
	var rect := _map.screen_rect()
	_scale = minf(MAX_SCALE, minf(MAX_SIZE.x / rect.size.x, MAX_SIZE.y / rect.size.y))
	_ground.custom_minimum_size = (rect.size * _scale).ceil()
	var coordinates := WorldMapLayout.map_coordinates(_map.id)
	_coordinates.visible = not coordinates.is_empty()
	if not coordinates.is_empty():
		_coordinates.text = "%d, %d" % [coordinates["position"].x, coordinates["position"].y]
	# Ancrée en haut à droite : elle s'étend vers la gauche et vers le bas à sa taille minimale.
	_frame.offset_left = _frame.offset_right
	_frame.offset_bottom = _frame.offset_top
	_ground.queue_redraw()
	_marks.queue_redraw()


## Position d'une case (ou d'un point de la grille) sur la minicarte.
func to_minimap(grid_pos: Vector2) -> Vector2:
	return IsoGrid.grid_to_screen(grid_pos) * _scale


func _process(_delta: float) -> void:
	if _frame.visible:
		_marks.queue_redraw()


func _draw_ground() -> void:
	if _map == null:
		return
	var indoor := _map.floor_kind == "parquet"
	var floor_color := Art.color("bois") if indoor else Art.color("herbe")
	_ground.draw_rect(Rect2(Vector2.ZERO, _ground.custom_minimum_size), floor_color)
	for cell: Vector2i in _map.cells():
		var color := Color(0, 0, 0, 0)
		var kind: String = _map.obstacles.get(cell, "")
		if kind == "eau":
			color = COLOR_WATER
		elif kind == GameMap.TRAVEL_STONE:
			color = floor_color
		elif not kind.is_empty():
			color = OBSTACLE_COLORS.get(kind, floor_color.darkened(0.45))
		elif _map.ground.has(cell):
			color = COLOR_PATH
		elif not _map.exit_directions(cell).is_empty():
			color = COLOR_EXIT
		if color.a > 0.0:
			_ground.draw_colored_polygon(_diamond(Vector2(cell)), color)
	for cell: Vector2i in _map.doors:
		var center := to_minimap(Vector2(cell))
		_ground.draw_rect(Rect2(center - Vector2(3, 3), Vector2(6, 6)), COLOR_DOOR)
		_ground.draw_rect(Rect2(center - Vector2(3, 3), Vector2(6, 6)), COLOR_OUTLINE, false, 1.0)
	var stone := _map.travel_stone()
	if stone != Vector2i(-1, -1):
		var center := to_minimap(Vector2(stone))
		var points := PackedVector2Array([center + Vector2(0, -5), center + Vector2(3.5, 0), center + Vector2(0, 5), center + Vector2(-3.5, 0)])
		_ground.draw_colored_polygon(points, COLOR_STONE)
		points.append(points[0])
		_ground.draw_polyline(points, COLOR_OUTLINE, 1.0)


func _draw_marks() -> void:
	if _map == null or map_view.world == null:
		return
	for npc: Dictionary in _map.npcs:
		_dot(Vector2(npc["case"]), 2.5, COLOR_NPC)
	var world := map_view.world
	for group: Dictionary in world.groups():
		var shown := map_view.actor(group["id"])
		if not shown.is_empty() and not shown["alive"]:
			continue
		var at: Vector2 = shown["pos"] if not shown.is_empty() else Vector2(group["case"])
		_dot(at, 3.5 if group.has("elite") else 3.0, COLOR_ELITE if group.has("elite") else COLOR_MONSTER)
	var player := map_view.actor(World.PLAYER_ID)
	if not player.is_empty():
		_dot(player["pos"], 3.5, COLOR_PLAYER, Color.WHITE)


func _dot(grid_pos: Vector2, radius: float, color: Color, outline := COLOR_OUTLINE) -> void:
	var center := to_minimap(grid_pos)
	_marks.draw_circle(center, radius, color)
	_marks.draw_arc(center, radius, 0, TAU, 12, outline, 1.0)


func _diamond(grid_pos: Vector2) -> PackedVector2Array:
	var center := to_minimap(grid_pos)
	var half := IsoGrid.HALF_TILE * _scale
	return PackedVector2Array([center + Vector2(0, -half.y), center + Vector2(half.x, 0), center + Vector2(0, half.y), center + Vector2(-half.x, 0)])


func _on_frame_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()


# --- Construction des contrôles ----------------------------------------------------------------

func _build() -> void:
	_frame = PanelContainer.new()
	_frame.anchor_left = 1.0
	_frame.anchor_right = 1.0
	_frame.offset_left = -MARGIN_RIGHT
	_frame.offset_right = -MARGIN_RIGHT
	_frame.offset_top = TOP
	_frame.offset_bottom = TOP
	_frame.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.1, 0.07, 0.92)
	style.border_color = Color(0.55, 0.42, 0.22)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(5)
	_frame.add_theme_stylebox_override("panel", style)
	_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	_frame.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_frame.tooltip_text = "Carte du monde (M)"
	_frame.gui_input.connect(_on_frame_input)
	add_child(_frame)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(column)
	_ground = Control.new()
	_ground.clip_contents = true
	_ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ground.draw.connect(_draw_ground)
	column.add_child(_ground)
	_marks = Control.new()
	_marks.set_anchors_preset(Control.PRESET_FULL_RECT)
	_marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marks.draw.connect(_draw_marks)
	_ground.add_child(_marks)
	var caption := HBoxContainer.new()
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(caption)
	var hint := Label.new()
	hint.text = "M : carte du monde"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.7, 0.67, 0.6))
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.add_child(hint)
	_coordinates = Label.new()
	_coordinates.add_theme_font_size_override("font_size", 11)
	_coordinates.add_theme_color_override("font_color", UiTheme.GOLD)
	_coordinates.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_coordinates.tooltip_text = "Coordonnées de la carte"
	caption.add_child(_coordinates)
