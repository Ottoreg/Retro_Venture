class_name TravelWindow
extends CanvasLayer
## Pierre de Passage : la liste des pierres, pour s'y téléporter contre quelques brumes. Les pierres pas
## encore découvertes sont grisées ; le bas de la fenêtre rappelle le point de résurrection.

const GOLD := Color(0.95, 0.76, 0.3)
## Prix d'une pierre inconnue, d'un voyage gratuit, d'un voyage trop cher pour la bourse.
const COLOR_UNKNOWN := Color(0.55, 0.52, 0.46)
const COLOR_FREE := Color(0.62, 0.88, 0.5)
const COLOR_TOO_EXPENSIVE := Color(0.92, 0.45, 0.35)

var map_view: MapView

var _backdrop: ColorRect
var _panel: PanelContainer
var _coins: Label
var _list: VBoxContainer
var _respawn: Label
var _stone := Vector2i.ZERO


func _ready() -> void:
	_build()
	_set_visible(false)


func setup(p_map_view: MapView) -> void:
	map_view = p_map_view
	map_view.travel_opened.connect(open)
	map_view.combat_started.connect(close)
	map_view.map_changed.connect(close)


func open(event: Dictionary) -> void:
	_stone = event["case"]
	for child in _list.get_children():
		child.queue_free()
	var ecus := int(event.get("ecus", 0))
	_coins.text = "%d brumes" % ecus
	var respawn_name := ""
	for destination: Dictionary in event["destinations"]:
		if destination["id"] == event.get("resurrection", ""):
			respawn_name = destination["nom"]
		_list.add_child(_destination_row(destination, destination["id"] == event["ici"], ecus))
	_respawn.text = "Point de résurrection : %s" % respawn_name if not respawn_name.is_empty() \
		else "Pas encore de point de résurrection."
	_set_visible(true)


func close() -> void:
	_set_visible(false)


func is_open() -> bool:
	return _panel.visible


## Boutons des destinations (pour les tests).
func destination_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	for row in _list.get_children():
		if not row.is_queued_for_deletion():
			buttons.append(row.get_child(0) as Button)
	return buttons


## Prix affiché à côté du bouton d'une destination (pour les tests).
static func price_text(button: Button) -> String:
	return (button.get_parent().get_child(1) as Label).text


## Ligne d'une destination : son bouton (grisé si l'on y est déjà ou si la pierre n'est pas encore
## découverte) et son prix.
func _destination_row(destination: Dictionary, here: bool, ecus: int) -> HBoxContainer:
	var known: bool = destination.get("connue", true)
	var price := int(destination.get("prix", 0))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var button := Button.new()
	button.text = destination["nom"]
	if here:
		button.text += "   (vous êtes ici)"
	elif not known:
		button.text += "   (pas encore découverte)"
		button.tooltip_text = "Allez-y à pied et touchez la pierre pour pouvoir y revenir en voyage."
	elif price > ecus:
		button.tooltip_text = "Pas assez de brumes : il en faut %d." % price
	button.disabled = here or not known
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(300, 40)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(_on_destination_pressed.bind(destination["id"]))
	row.add_child(button)
	var cost := Label.new()
	cost.custom_minimum_size = Vector2(76, 0)
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost.text = "" if here else ("gratuit" if price == 0 else "%d brumes" % price)
	var color := GOLD
	if not known:
		color = COLOR_UNKNOWN
	elif price == 0:
		color = COLOR_FREE
	elif price > ecus:
		color = COLOR_TOO_EXPENSIVE
	cost.add_theme_color_override("font_color", color)
	row.add_child(cost)
	return row


func _on_destination_pressed(destination: String) -> void:
	close()
	map_view.send_command({"type": Protocol.CMD_TRAVEL, "entite": World.PLAYER_ID, "case": _stone, "destination": destination})


func _on_backdrop_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.pressed:
		close()


func _set_visible(shown: bool) -> void:
	_panel.visible = shown
	_backdrop.visible = shown


func _build() -> void:
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0, 0, 0, 0.35)
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_backdrop.gui_input.connect(_on_backdrop_input)
	add_child(_backdrop)
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.offset_left = -230
	_panel.offset_right = 230
	_panel.offset_top = 160
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.1, 0.07, 0.97)
	style.border_color = Color(0.55, 0.42, 0.22)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(14)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_panel.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	column.add_child(header)
	var title := Label.new()
	title.text = "Pierre de Passage"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_coins = Label.new()
	_coins.add_theme_color_override("font_color", GOLD)
	_coins.tooltip_text = "Votre bourse"
	_coins.mouse_filter = Control.MOUSE_FILTER_PASS
	header.add_child(_coins)
	var close_button := Button.new()
	close_button.text = "×"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(close)
	header.add_child(close_button)
	var hint := Label.new()
	hint.text = "Posez la main sur les runes et choisissez où aller :"
	hint.add_theme_color_override("font_color", Color(0.85, 0.82, 0.72))
	column.add_child(hint)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 6)
	column.add_child(_list)
	column.add_child(HSeparator.new())
	_respawn = Label.new()
	_respawn.add_theme_font_size_override("font_size", 14)
	_respawn.add_theme_color_override("font_color", Color(0.78, 0.75, 0.66))
	_respawn.tooltip_text = "Après une défaite, vous vous réveillez à côté de cette pierre : la dernière que vous avez touchée."
	_respawn.mouse_filter = Control.MOUSE_FILTER_PASS
	column.add_child(_respawn)
