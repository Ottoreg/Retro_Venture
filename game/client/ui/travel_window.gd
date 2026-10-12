class_name TravelWindow
extends CanvasLayer
## Pierre de Passage : la liste des autres pierres, pour s'y téléporter.

const GOLD := Color(0.95, 0.76, 0.3)

var map_view: MapView

var _backdrop: ColorRect
var _panel: PanelContainer
var _list: VBoxContainer
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
	for destination: Dictionary in event["destinations"]:
		var here: bool = destination["id"] == event["ici"]
		var button := Button.new()
		button.text = "%s   (vous êtes ici)" % destination["nom"] if here else destination["nom"]
		button.disabled = here
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(300, 40)
		button.pressed.connect(_on_destination_pressed.bind(destination["id"]))
		_list.add_child(button)
	_set_visible(true)


func close() -> void:
	_set_visible(false)


func is_open() -> bool:
	return _panel.visible


## Boutons des destinations (pour les tests).
func destination_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	for child in _list.get_children():
		if child is Button and not child.is_queued_for_deletion():
			buttons.append(child)
	return buttons


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
	_panel.offset_left = -190
	_panel.offset_right = 190
	_panel.offset_top = 160
	add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "Pierre de Passage"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
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
