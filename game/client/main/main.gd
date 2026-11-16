extends Control
## Écran d'accueil : nouvelle partie ou reprise de la partie sauvegardée, jeu en ligne (prototype),
## options, quitter.

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
	var online := _menu_button("Jouer en ligne (prototype)", 240)
	online.name = "Online"
	online.tooltip_text = "Prototype du multijoueur : un compte, un personnage gardé sur le serveur de test."
	online.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	online.pressed.connect(func() -> void: get_tree().change_scene_to_file(OnlineScreen.SCENE))
	box.add_child(online)
	box.move_child(online, row.get_index() + 1)
	var feedback := _menu_button("Donner son avis", 240)
	feedback.name = "Feedback"
	feedback.tooltip_text = "Le questionnaire des testeurs (s'ouvre dans le navigateur)"
	feedback.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	feedback.pressed.connect(func() -> void: OS.shell_open(Session.FEEDBACK_URL))
	box.add_child(feedback)
	box.move_child(feedback, online.get_index() + 1)
	if not web and Session.BUILD_COMMIT != "":
		_check_update(box)
	var version: String = ProjectSettings.get_setting("application/config/version", "?")
	%Version.text = "Version %s — Alpha test 1" % version
	%NewGame.pressed.connect(_on_new_game_pressed)
	%Continue.pressed.connect(_on_continue_pressed)
	var summary := SaveGame.summary()
	%Continue.disabled = summary.is_empty()
	%SaveInfo.text = "Partie en cours : %s" % summary if not summary.is_empty() else ""
	if summary.is_empty():
		%NewGame.grab_focus()
	else:
		%Continue.grab_focus()


## Client natif : demande à GitHub le commit de la dernière release ; s'il diffère du sien, ajoute
## un bouton « Nouvelle version disponible » qui ouvre la page de téléchargement.
func _check_update(box: VBoxContainer) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
		http.queue_free()
		var data: Variant = JSON.parse_string(body.get_string_from_utf8()) if result == HTTPRequest.RESULT_SUCCESS and code == 200 else null
		var latest: String = data.get("object", {}).get("sha", "") if data is Dictionary else ""
		if latest.is_empty() or latest == Session.BUILD_COMMIT:
			return
		var update := _menu_button("Nouvelle version disponible", 240)
		update.name = "Update"
		update.tooltip_text = "Ouvre la page de téléchargement : dézipper et remplacer l'ancien dossier (les sauvegardes sont gardées)."
		update.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		update.add_theme_color_override("font_color", Color.GOLD)
		update.pressed.connect(func() -> void: OS.shell_open(Session.RELEASE_URL))
		box.add_child(update)
		box.move_child(update, 0))
	http.request(Session.RELEASE_TAG_API)


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
