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
## (`Session.quest_pin`) y est une épingle, ou une flèche au bord s'il est plus loin (dans le monde : les zones voisines se touchent) ;
## l'objectif de la quête suivie aussi, en jaune (`QuestLinks.objective_pin`) ; les membres du groupe
## de joueurs en points verts, leurs repères en épingles vertes (`WorldMapWindow.party_markers`).

## Clic sur la minicarte.
signal pressed
## Clic droit sur une carte : un drapeau (repère) ; `shared` avec Maj (montré au groupe).
signal flag_requested(pin: Dictionary, shared: bool)

const NO_POINT := Vector2(-1, -1)

var map_view: MapView

var _frame: PanelContainer
var _grid: WorldMapWindow.ZoneGrid
var _zone_name: Label
var _coordinates: Label
## Emplacement réservé dans la bande gauche (voir `setup`).
var _slot: Control
## Carte à coordonnées au centre (la carte actuelle, ou celle devant la porte d'une maison), ou "".
var _center_map := ""
## Décalage de la fenêtre (glisser), en cartes ; remis à zéro à chaque changement de carte.
var _offset := Vector2i.ZERO
var _drag_from := NO_POINT
var _drag_offset := Vector2i.ZERO
var _dragged := false
## Ligne du repère, sous la grille : flèche vers sa carte, nom et distance.
var _flag_row: HBoxContainer
var _flag_arrow: FlagArrow
var _flag_label: Label


## Flèche vers la carte du repère (dessinée : la police n'a pas de flèches).
class FlagArrow extends Control:
	var direction := Vector2.ZERO

	func _draw() -> void:
		var middle := size / 2.0
		if direction == Vector2.ZERO:
			draw_circle(middle, 4.0, WorldMapWindow.COLOR_PIN)
			return
		var tip := middle + direction * 6.0
		var side := Vector2(-direction.y, direction.x) * 4.0
		draw_colored_polygon(PackedVector2Array([tip, middle - direction * 5.0 + side, middle - direction * 2.0,
			middle - direction * 5.0 - side]), WorldMapWindow.COLOR_PIN)


func _ready() -> void:
	_build()
	_frame.visible = false


func setup(p_map_view: MapView, hud: CombatHud) -> void:
	map_view = p_map_view
	_slot = hud.minimap_slot
	map_view.map_changed.connect(recenter)
	map_view.combat_started.connect(refresh)
	map_view.exploration_resumed.connect(refresh)
	map_view.quests_changed.connect(func(_journal: Dictionary) -> void: refresh())
	map_view.party_changed.connect(refresh)
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
		# Le monde entier (les zones voisines se touchent), recadré autour de la carte.
		var layout := WorldMapWindow.world_grid_layout(world, _center_map)
		var center: Vector2i = coordinates["position"] - layout["origines"][coordinates["zone"]] + layout["origine"]
		var radius := Options.minimap_radius
		_grid.layout = WorldMapLayout.neighborhood(layout, center + _offset, Vector2i(radius, radius))
		_grid.indoors = _center_map != world.map.id
		for zone: Dictionary in layout["zones"]:
			if zone["zone"] == coordinates["zone"]:
				_zone_name.text = zone["nom"]
		_coordinates.text = "%d, %d" % [coordinates["position"].x, coordinates["position"].y]
	_grid.pin = Session.quest_pin
	_grid.objective = QuestLinks.objective_pin(world)
	_grid.party = WorldMapWindow.party_markers(world)
	_grid.world = world
	_refresh_flag(coordinates)
	_place()
	_grid.queue_redraw()


## Ligne du repère (`Session.quest_pin`) : flèche vers sa carte, son nom et sa distance en cartes.
func _refresh_flag(here: Dictionary) -> void:
	var pin: Dictionary = Session.quest_pin
	_flag_row.visible = not pin.is_empty()
	if pin.is_empty():
		return
	var target: Variant = _grid.map_cell(pin.get("carte", ""))
	var from: Variant = _grid.map_cell(_center_map)
	var shift := Vector2i.ZERO
	if not here.is_empty() and target != null and from != null:
		shift = target - from
		var steps := absi(shift.x) + absi(shift.y)
		_flag_label.text = "%s : ici" % pin["nom"] if steps == 0 else "%s : %d carte%s" % [pin["nom"], steps, "s" if steps > 1 else ""]
	else:
		_flag_label.text = "%s (ailleurs)" % pin["nom"]
	_flag_arrow.direction = Vector2(shift).normalized()
	_flag_arrow.queue_redraw()


## Revient sur la carte actuelle (après un changement de carte, ou un clic quand on a glissé).
func recenter() -> void:
	_offset = Vector2i.ZERO
	refresh()


## Molette : de 3 × 3 (1) à 9 × 9 (4) cartes.
func zoom(step: int) -> void:
	var radius := clampi(Options.minimap_radius + step, 1, 4)
	if radius != Options.minimap_radius:
		Options.minimap_radius = radius
		Options.save_options()
		refresh()


## Molette : zoom ; glisser : déplace la fenêtre ; clic : recentre si on a glissé, sinon ouvre la
## carte du monde ; clic droit : drapeau sur la carte visée (Maj : montré au groupe).
func _on_frame_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null:
		if button.pressed and button.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			zoom(-1 if button.button_index == MOUSE_BUTTON_WHEEL_UP else 1)
			_frame.accept_event()
		elif button.button_index == MOUSE_BUTTON_LEFT:
			if button.pressed:
				_drag_from = button.position
				_drag_offset = _offset
				_dragged = false
			elif _drag_from != NO_POINT:
				_drag_from = NO_POINT
				if _dragged:
					return
				if _offset != Vector2i.ZERO:
					recenter()
				elif map_view.mode == MapView.Mode.EXPLORATION:
					pressed.emit()
		elif button.button_index == MOUSE_BUTTON_RIGHT and button.pressed:
			flag_at(_grid.get_local_mouse_position(), button.shift_pressed)
		return
	var motion := event as InputEventMouseMotion
	if motion != null and _drag_from != NO_POINT and motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
		drag_to(motion.position)


## Glisser jusqu'à ce point du cadre (depuis l'appui).
func drag_to(point: Vector2) -> void:
	var moved := point - _drag_from
	if moved.length() > 4.0:
		_dragged = true
	if not _dragged:
		return
	var step := _grid.cell_size()
	var shift := _drag_offset - Vector2i(roundi(moved.x / maxf(step.x, 1.0)), roundi(moved.y / maxf(step.y, 1.0)))
	if shift != _offset:
		_offset = shift
		refresh()


## Drapeau sur la carte sous ce point de la grille (rien hors des cartes).
func flag_at(point: Vector2, shared: bool) -> void:
	var case := _grid.case_at(point)
	if not case.is_empty():
		flag_requested.emit(WorldMapWindow.flag_pin(case), shared)


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
	_frame.tooltip_text = "Clic : carte du monde (M). Molette : zoom. Glisser : se déplacer. Clic droit : drapeau (Maj : pour le groupe)."
	_grid = WorldMapWindow.ZoneGrid.new()
	_grid.compact = true
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid.mouse_filter = Control.MOUSE_FILTER_PASS
	column.add_child(_grid)
	_flag_row = HBoxContainer.new()
	_flag_row.add_theme_constant_override("separation", 3)
	_flag_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flag_row.visible = false
	column.add_child(_flag_row)
	_flag_arrow = FlagArrow.new()
	_flag_arrow.custom_minimum_size = Vector2(16, 16)
	_flag_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flag_row.add_child(_flag_arrow)
	_flag_label = Label.new()
	_flag_label.add_theme_font_size_override("font_size", 11)
	_flag_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.6))
	_flag_label.clip_text = true
	_flag_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_flag_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_flag_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flag_row.add_child(_flag_label)
