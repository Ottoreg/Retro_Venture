class_name Minimap
extends CanvasLayer
## Minicarte, façon Dofus Rétro : la carte du monde en réduit autour de la carte actuelle, pour
## s'orienter (chaque carte tient sur un écran : inutile de la redessiner en petit). En haut à droite
## sous le bandeau, en exploration seulement (masquée en combat, pour laisser la place à l'ordre de
## jeu). Fenêtre fixe de `RADIUS` cartes de chaque côté, la carte actuelle au milieu (cadre doré,
## point bleu) ; cartes visitées, voisines inconnues en « ? », chemins entre cartes et Pierres de
## Passage, comme sur la carte du monde (`WorldMapLayout`, `WorldMapWindow.ZoneGrid`). Dans une
## maison, la carte devant sa porte. Le survol d'une case donne son nom ; un clic ouvre la carte du
## monde. Le bouton « – » de sa barre la replie (il ne reste que la barre).

## Clic sur la minicarte.
signal pressed

## Cartes montrées de chaque côté de la carte actuelle (5 × 5 cartes).
const RADIUS := Vector2i(2, 2)
## Taille du dessin (pixels).
const GRID_SIZE := Vector2(210, 140)
## Distance au bord droit de l'écran et au haut de l'écran (sous le bandeau du haut).
const MARGIN_RIGHT := 12.0
const TOP := 72.0

var map_view: MapView

var _frame: PanelContainer
var _grid: WorldMapWindow.ZoneGrid
var _zone_name: Label
var _coordinates: Label
var _fold_button: Button
## Carte à coordonnées au centre (la carte actuelle, ou celle devant la porte d'une maison), ou "".
var _center_map := ""


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


## Vrai si le joueur a replié la minicarte (gardé d'une carte et d'un combat à l'autre, dans `Session`).
func is_folded() -> bool:
	return Session.minimap_folded


## Replie la minicarte (seule sa barre reste) ou la déplie.
func set_folded(folded: bool) -> void:
	Session.minimap_folded = folded
	refresh()


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
	_frame.visible = map_view.mode == MapView.Mode.EXPLORATION
	_grid.visible = not Session.minimap_folded
	# Taille nulle une fois repliée : le cadre se recalcule tout de suite (masquer ne suffit pas).
	_grid.custom_minimum_size = Vector2.ZERO if Session.minimap_folded else GRID_SIZE
	_fold_button.text = "+" if Session.minimap_folded else "–"
	_fold_button.tooltip_text = "Déplier la minicarte" if Session.minimap_folded else "Replier la minicarte"
	_center_map = WorldMapWindow.here_map(world)
	var coordinates := WorldMapLayout.map_coordinates(_center_map)
	_coordinates.visible = not coordinates.is_empty()
	if coordinates.is_empty():
		_grid.layout = {}
		_zone_name.text = WorldMapLayout.short_name(world.map.display_name)
	else:
		var zone_id: String = coordinates["zone"]
		var infos := WorldMapWindow.map_infos(world, [zone_id])
		var layout := WorldMapLayout.zone_layout(zone_id, infos, WorldMapWindow.visited_here(world), _center_map,
			world.data.passages, WorldMapWindow.known_passages(world))
		_grid.layout = WorldMapLayout.neighborhood(layout, coordinates["position"], RADIUS)
		_grid.indoors = _center_map != world.map.id
		_zone_name.text = layout["nom"]
		_coordinates.text = "%d, %d" % [coordinates["position"].x, coordinates["position"].y]
	# Ancrée en haut à droite : elle s'étend vers la gauche et vers le bas à sa taille minimale.
	_frame.offset_left = _frame.offset_right
	_frame.offset_bottom = _frame.offset_top
	_frame.reset_size()
	_grid.queue_redraw()


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
	style.bg_color = Color(0.13, 0.1, 0.07, 0.97)
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
	# Barre du haut : zone, coordonnées et bouton pour replier ; puis le voisinage.
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
	# Bouton pour replier ou déplier ; il garde son clic (pas d'ouverture de la carte du monde).
	_fold_button = Button.new()
	_fold_button.flat = true
	_fold_button.focus_mode = Control.FOCUS_NONE
	_fold_button.custom_minimum_size = Vector2(18, 16)
	_fold_button.add_theme_font_size_override("font_size", 13)
	_fold_button.add_theme_color_override("font_color", UiTheme.GOLD)
	_fold_button.add_theme_constant_override("h_separation", 0)
	for state in ["normal", "hover", "pressed", "focus"]:
		var box := StyleBoxEmpty.new()
		box.set_content_margin_all(0)
		_fold_button.add_theme_stylebox_override(state, box)
	_fold_button.pressed.connect(func() -> void: set_folded(not Session.minimap_folded))
	caption.add_child(_fold_button)
	# Le voisinage laisse passer le clic au cadre (carte du monde), mais garde la bulle de survol.
	_grid = WorldMapWindow.ZoneGrid.new()
	_grid.compact = true
	_grid.custom_minimum_size = GRID_SIZE
	_grid.mouse_filter = Control.MOUSE_FILTER_PASS
	column.add_child(_grid)
