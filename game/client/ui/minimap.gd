class_name Minimap
extends CanvasLayer
## Minicarte, façon Dofus Rétro : la carte du monde en réduit autour de la carte actuelle, pour
## s'orienter (chaque carte tient sur un écran : inutile de la redessiner en petit). En haut de la
## bande gauche (`CombatHud.minimap_slot`) : jamais sur la zone de jeu ; en combat aussi, mais le clic
## n'y ouvre pas la carte du monde. Fenêtre fixe de `RADIUS` cartes de
## chaque côté, la carte actuelle au milieu (cadre doré, point bleu) ; toutes les cartes (rien n'est
## caché), chemins entre cartes et Pierres de Passage, comme sur la carte du monde
## (`WorldMapLayout`, `WorldMapWindow.ZoneGrid`). Dans une maison, la carte devant sa porte. Le
## survol d'une case donne son nom ; un clic ouvre la carte du monde. Le repère de quête
## (`Session.quest_pin`) y est une épingle, ou une flèche au bord s'il est plus loin dans la zone.

## Clic sur la minicarte.
signal pressed

## Cartes montrées de chaque côté de la carte actuelle (5 × 5 cartes, dans un cadre carré).
const RADIUS := Vector2i(2, 2)

var map_view: MapView

var _frame: PanelContainer
var _grid: WorldMapWindow.ZoneGrid
var _zone_name: Label
var _coordinates: Label
## Emplacement réservé dans la bande gauche (voir `setup`).
var _slot: Control
## Carte à coordonnées au centre (la carte actuelle, ou celle devant la porte d'une maison), ou "".
var _center_map := ""


func _ready() -> void:
	_build()
	_frame.visible = false


func setup(p_map_view: MapView, hud: CombatHud) -> void:
	map_view = p_map_view
	_slot = hud.minimap_slot
	map_view.map_changed.connect(refresh)
	map_view.combat_started.connect(refresh)
	map_view.exploration_resumed.connect(refresh)
	refresh()


func is_shown() -> bool:
	return _frame.visible


## Rectangle du cadre à l'écran.
func frame_rect() -> Rect2:
	return _frame.get_global_rect()


func _process(_delta: float) -> void:
	_place()


## Pose le cadre sur son emplacement de la bande gauche (qui suit la taille de l'écran).
func _place() -> void:
	if _slot == null or not _frame.visible:
		return
	var slot := _slot.get_global_rect()
	_frame.position = slot.position
	_frame.size = slot.size


## Carte au centre ("" sur une carte sans coordonnées, hors d'une maison).
func center_map() -> String:
	return _center_map


## Voisinage affiché (voir `WorldMapLayout.neighborhood`).
func shown_layout() -> Dictionary:
	return _grid.layout


## Reprend la carte actuelle (nouvelle carte, début ou fin de combat).
func refresh() -> void:
	if map_view == null or map_view.world == null:
		return
	var world := map_view.world
	_frame.visible = true
	_center_map = WorldMapWindow.here_map(world)
	var coordinates := WorldMapLayout.map_coordinates(_center_map)
	_coordinates.visible = not coordinates.is_empty()
	if coordinates.is_empty():
		_grid.layout = {}
		_zone_name.text = WorldMapLayout.short_name(world.map.display_name)
	else:
		var zone_id: String = coordinates["zone"]
		var infos := WorldMapWindow.map_infos(world, [zone_id])
		var layout := WorldMapLayout.zone_layout(zone_id, infos, WorldMapWindow.shown_maps(world), _center_map,
			world.data.passages, WorldMapWindow.known_passages(world))
		_grid.layout = WorldMapLayout.neighborhood(layout, coordinates["position"], RADIUS)
		_grid.indoors = _center_map != world.map.id
		_zone_name.text = layout["nom"]
		_coordinates.text = "%d, %d" % [coordinates["position"].x, coordinates["position"].y]
	_grid.pin = Session.quest_pin
	_place()
	_grid.queue_redraw()


func _on_frame_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT and map_view.mode == MapView.Mode.EXPLORATION:
		pressed.emit()


# --- Construction des contrôles ----------------------------------------------------------------

func _build() -> void:
	_frame = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.1, 0.07, 0.97)
	style.border_color = Color(0.55, 0.42, 0.22)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(3)
	_frame.add_theme_stylebox_override("panel", style)
	_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	_frame.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_frame.tooltip_text = "Carte du monde (M)"
	_frame.gui_input.connect(_on_frame_input)
	add_child(_frame)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(column)
	# En haut : zone et coordonnées ; puis le voisinage.
	var caption := HBoxContainer.new()
	caption.add_theme_constant_override("separation", 6)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(caption)
	_zone_name = Label.new()
	_zone_name.add_theme_font_size_override("font_size", 11)
	_zone_name.add_theme_color_override("font_color", Color(0.78, 0.75, 0.66))
	_zone_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_zone_name.clip_text = true
	_zone_name.custom_minimum_size.x = 60
	_zone_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.add_child(_zone_name)
	_coordinates = Label.new()
	_coordinates.add_theme_font_size_override("font_size", 11)
	_coordinates.add_theme_color_override("font_color", UiTheme.GOLD)
	_coordinates.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.add_child(_coordinates)
	# Le voisinage laisse passer le clic au cadre (carte du monde), mais garde la bulle de survol.
	_grid = WorldMapWindow.ZoneGrid.new()
	_grid.compact = true
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid.mouse_filter = Control.MOUSE_FILTER_PASS
	column.add_child(_grid)
