class_name OptionsWindow
extends CanvasLayer
## Fenêtre des options (depuis le menu principal ou le menu pause) : volume, plein écran, taille de
## la fenêtre, mode tactique en combat, adresse du serveur (jeu en ligne). Chaque changement
## s'applique et s'enregistre aussitôt.

signal closed

var _backdrop: ColorRect
var _panel: PanelContainer
var _volume: HSlider
var _volume_label: Label
var _fullscreen: Button
var _size: OptionButton
var _tactical: Button
var _pawns: Button
var _server: LineEdit
## Carte en jeu (posée par la scène du monde) : le mode admin n'est proposé qu'en partie.
var map_view: MapView
var admin: AdminWindow
var _admin_row: Array[Control] = []


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS  # Elle sert aussi pendant la pause.
	_build()
	_set_visible(false)


func open() -> void:
	Options.load_options()
	_volume.set_value_no_signal(Options.volume)
	_volume_label.text = "%d %%" % Options.volume
	_set_switch(_fullscreen, Options.fullscreen)
	_size.select(Options.window_size)
	_size.disabled = not Options.can_resize() or Options.fullscreen
	_set_switch(_tactical, Options.tactical)
	_set_switch(_pawns, Options.tactical_pawns)
	_server.text = Options.server_address
	for control in _admin_row:
		control.visible = map_view != null
	_set_visible(true)


func _set_switch(button: Button, on: bool) -> void:
	button.set_pressed_no_signal(on)
	button.text = "Activé" if on else "Désactivé"


func close() -> void:
	if is_open():
		_set_visible(false)
		closed.emit()


func is_open() -> bool:
	return _panel.visible


func _unhandled_input(event: InputEvent) -> void:
	if is_open() and not admin.is_open() and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _on_volume_changed(value: float) -> void:
	Options.volume = roundi(value)
	_volume_label.text = "%d %%" % Options.volume
	_changed()


func _on_fullscreen_toggled(on: bool) -> void:
	Options.fullscreen = on
	_size.disabled = not Options.can_resize() or on
	_changed()


func _on_size_selected(index: int) -> void:
	Options.window_size = index
	_changed()


func _on_tactical_toggled(on: bool) -> void:
	Options.tactical = on
	_changed()


func _on_pawns_toggled(on: bool) -> void:
	Options.tactical_pawns = on
	_changed()


func _on_server_changed(text: String) -> void:
	Options.server_address = text.strip_edges()
	Options.save_options()


func _changed() -> void:
	Options.apply()
	Options.save_options()


func _set_visible(shown: bool) -> void:
	_panel.visible = shown
	_backdrop.visible = shown


func _build() -> void:
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0, 0, 0, 0.45)
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_backdrop)
	var frame := UiTheme.window_frame(self, "Options", close, false)
	_panel = frame.panel
	var column: VBoxContainer = frame.column
	column.add_theme_constant_override("separation", 12)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 10)
	column.add_child(grid)
	grid.add_child(_caption("Volume"))
	var volume_row := HBoxContainer.new()
	volume_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_volume = HSlider.new()
	_volume.min_value = 0
	_volume.max_value = 100
	_volume.step = 5
	_volume.custom_minimum_size = Vector2(180, 0)
	_volume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_volume.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_volume.value_changed.connect(_on_volume_changed)
	volume_row.add_child(_volume)
	_volume_label = Label.new()
	_volume_label.custom_minimum_size = Vector2(52, 0)
	_volume_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	volume_row.add_child(_volume_label)
	grid.add_child(volume_row)

	grid.add_child(_caption("Plein écran"))
	_fullscreen = _switch()
	_fullscreen.toggled.connect(_on_fullscreen_toggled)
	grid.add_child(_fullscreen)

	grid.add_child(_caption("Taille de la fenêtre"))
	_size = OptionButton.new()
	for window_size in Options.WINDOW_SIZES:
		_size.add_item("%d × %d" % [window_size.x, window_size.y])
	_size.tooltip_text = "Sur ordinateur ; dans un navigateur, le jeu prend la taille de la page."
	_size.item_selected.connect(_on_size_selected)
	grid.add_child(_size)

	grid.add_child(_caption("Mode tactique en combat"))
	_tactical = _switch()
	_tactical.tooltip_text = "Vue simplifiée de la grille : cases à plat, obstacles en blocs, décor masqué (touche T en combat)."
	_tactical.toggled.connect(_on_tactical_toggled)
	grid.add_child(_tactical)

	grid.add_child(_caption("Pions en mode tactique"))
	_pawns = _switch()
	_pawns.tooltip_text = "En mode tactique, remplace les personnages par des pions : cercle de la couleur du camp et initiale."
	_pawns.toggled.connect(_on_pawns_toggled)
	grid.add_child(_pawns)

	grid.add_child(_caption("Adresse du serveur"))
	_server = LineEdit.new()
	_server.placeholder_text = "automatique"
	_server.custom_minimum_size = Vector2(220, 34)
	_server.tooltip_text = "Jeu en ligne : laisser vide pour le serveur de test. Développement : ws://localhost:8080 par exemple."
	_server.text_changed.connect(_on_server_changed)
	grid.add_child(_server)

	_admin_row = [_caption("Mode admin (tests)"), Button.new()]
	_admin_row[1].text = "Ouvrir…"
	_admin_row[1].custom_minimum_size = Vector2(130, 34)
	_admin_row[1].size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_admin_row[1].tooltip_text = "Se donner objets, brumes, réputation et maîtrise ; double-clic sur la minicarte pour s'y téléporter."
	_admin_row[1].pressed.connect(func() -> void:
		admin.map_view = map_view
		admin.open())
	for control in _admin_row:
		grid.add_child(control)
	admin = AdminWindow.new()
	add_child(admin)


## Interrupteur : bouton à bascule qui affiche son état.
func _switch() -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(130, 34)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.text = "Désactivé"
	button.toggled.connect(func(on: bool) -> void: button.text = "Activé" if on else "Désactivé")
	return button


func _caption(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return label


## Commandes de la fenêtre (pour les tests).
func controls() -> Dictionary:
	return {"volume": _volume, "plein_ecran": _fullscreen, "taille": _size, "tactique": _tactical, "pions": _pawns, "serveur": _server, "admin": _admin_row[1]}
