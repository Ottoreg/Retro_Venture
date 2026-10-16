class_name PauseMenu
extends CanvasLayer
## Menu pause (Échap quand aucune fenêtre n'est ouverte) : le jeu s'arrête (monstres, repousse,
## régénération) ; reprendre, options, retour au menu principal (sauvegardé, pas pendant un combat),
## quitter (pas dans un navigateur).

signal main_menu_requested

var options: OptionsWindow
var _backdrop: ColorRect
var _panel: PanelContainer
var _menu_button: Button
var _quit_button: Button


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	options = OptionsWindow.new()
	add_child(options)
	options.closed.connect(func() -> void: _panel.visible = true)
	_set_visible(false)


## `in_combat` : le retour au menu attend la fin du combat (on ne sauvegarde pas en combat).
func open(in_combat := false) -> void:
	_menu_button.disabled = in_combat
	_menu_button.tooltip_text = "Pas pendant un combat." if in_combat else "La partie est sauvegardée."
	_set_visible(true)
	get_tree().paused = true


func close() -> void:
	options.close()
	_set_visible(false)
	get_tree().paused = false


func is_open() -> bool:
	return _backdrop.visible


func _unhandled_input(event: InputEvent) -> void:
	if is_open() and not options.is_open() and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _on_options_pressed() -> void:
	_panel.visible = false
	options.open()


func _on_menu_pressed() -> void:
	close()
	main_menu_requested.emit()


func _set_visible(shown: bool) -> void:
	_backdrop.visible = shown
	_panel.visible = shown


func _build() -> void:
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0, 0, 0, 0.5)
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_backdrop)
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.add_theme_stylebox_override("panel", UiTheme.window_style())
	_panel.custom_minimum_size = Vector2(300, 0)
	add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_panel.add_child(column)
	var title := Label.new()
	title.text = "Pause"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", UiTheme.GOLD)
	column.add_child(title)
	column.add_child(_button("Reprendre", close))
	column.add_child(_button("Options", _on_options_pressed))
	_menu_button = _button("Menu principal", _on_menu_pressed)
	column.add_child(_menu_button)
	_quit_button = _button("Quitter le jeu", func() -> void: get_tree().quit())
	_quit_button.visible = not OS.has_feature("web")
	column.add_child(_quit_button)


func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(240, 40)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(action)
	return button


## Boutons du menu, par texte (pour les tests).
func buttons() -> Dictionary:
	var found := {}
	for child in _panel.get_child(0).get_children():
		if child is Button:
			found[(child as Button).text] = child
	return found
