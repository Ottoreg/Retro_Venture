extends Control
## Écran d'accueil : nouvelle partie ou reprise de la partie sauvegardée, options, quitter.

const WORLD_SCENE := "res://client/world/world.tscn"
const CREATION_SCENE := "res://client/creation/creation.tscn"


var options_window: OptionsWindow


func _ready() -> void:
	UiTheme.apply(get_tree())
	Options.load_options()
	Options.apply()
	options_window = OptionsWindow.new()
	add_child(options_window)
	# Options et Quitter côte à côte sous « Continuer » (Quitter : pas dans un navigateur).
	var box: VBoxContainer = %Continue.get_parent()
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	box.move_child(row, %Continue.get_index() + 1)
	var web := OS.has_feature("web")
	var options_button := _menu_button("Options", 240 if web else 116)
	options_button.name = "Options"
	options_button.pressed.connect(options_window.open)
	row.add_child(options_button)
	if not web:
		var quit_button := _menu_button("Quitter", 116)
		quit_button.name = "Quit"
		quit_button.pressed.connect(get_tree().quit)
		row.add_child(quit_button)
	var version: String = ProjectSettings.get_setting("application/config/version", "?")
	%Version.text = "Version %s — Phase 2 (alpha en construction)" % version
	%NewGame.pressed.connect(_on_new_game_pressed)
	%Continue.pressed.connect(_on_continue_pressed)
	var summary := SaveGame.summary()
	%Continue.disabled = summary.is_empty()
	%SaveInfo.text = "Partie en cours : %s" % summary if not summary.is_empty() else ""
	if summary.is_empty():
		%NewGame.grab_focus()
	else:
		%Continue.grab_focus()


func _menu_button(text: String, width: int) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(width, 40)
	button.add_theme_font_size_override("font_size", 18)
	return button


func _on_new_game_pressed() -> void:
	Session.continue_game = false
	Session.new_character = null
	get_tree().change_scene_to_file(CREATION_SCENE)


func _on_continue_pressed() -> void:
	Session.continue_game = true
	Session.new_character = null
	get_tree().change_scene_to_file(WORLD_SCENE)
