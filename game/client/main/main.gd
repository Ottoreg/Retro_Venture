extends Control
## Écran d'accueil : nouvelle partie ou reprise de la partie sauvegardée, export et import de la
## sauvegarde (image PNG chiffrée, `SaveGame.to_png`), jeu en ligne (prototype), options, quitter.

const WORLD_SCENE := "res://client/world/world.tscn"
const CREATION_SCENE := "res://client/creation/creation.tscn"


var options_window: OptionsWindow
var export_button: Button
var _web_import_callback: JavaScriptObject  # Gardé : le navigateur rappelle Godot après le choix du fichier.


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
	var save_row := HBoxContainer.new()
	save_row.alignment = BoxContainer.ALIGNMENT_CENTER
	save_row.add_theme_constant_override("separation", 8)
	box.add_child(save_row)
	box.move_child(save_row, row.get_index() + 1)
	export_button = _menu_button("Exporter", 116)
	export_button.tooltip_text = "Enregistre la sauvegarde dans une image PNG chiffrée (à garder ou à copier sur un autre appareil)."
	export_button.pressed.connect(_export_save)
	var import_button := _menu_button("Importer", 116)
	import_button.tooltip_text = "Reprend une sauvegarde exportée en image PNG (remplace la partie en cours)."
	import_button.pressed.connect(_ask_import)
	save_row.add_child(export_button)
	save_row.add_child(import_button)
	var online := _menu_button("Jouer en ligne (prototype)", 240)
	online.name = "Online"
	online.tooltip_text = "Prototype du multijoueur : un compte, un personnage gardé sur le serveur de test."
	online.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	online.pressed.connect(func() -> void: get_tree().change_scene_to_file(OnlineScreen.SCENE))
	box.add_child(online)
	box.move_child(online, save_row.get_index() + 1)
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
	_show_save()
	(%NewGame if %Continue.disabled else %Continue).grab_focus()


func _show_save(message := "") -> void:
	var summary := SaveGame.summary()
	%Continue.disabled = summary.is_empty()
	export_button.disabled = summary.is_empty()
	%SaveInfo.text = message if not message.is_empty() else "Partie en cours : %s" % summary if not summary.is_empty() else ""


func _export_save() -> void:
	var png := SaveGame.to_png()
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(png, SaveGame.EXPORT_NAME, "image/png")
		return
	_file_dialog(FileDialog.FILE_MODE_SAVE_FILE, func(path: String) -> void:
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_buffer(png)
		_show_save("Sauvegarde exportée." if file != null else "Export impossible : %s" % error_string(FileAccess.get_open_error())))


## Demande confirmation avant de remplacer une partie en cours, puis ouvre le choix du fichier.
func _ask_import() -> void:
	if not SaveGame.exists():
		_import_save()
		return
	var confirm := ConfirmationDialog.new()
	confirm.dialog_text = "Importer une sauvegarde remplace la partie en cours (%s). Continuer ?" % SaveGame.summary()
	confirm.confirmed.connect(_import_save)
	confirm.visibility_changed.connect(func() -> void: if not confirm.visible: confirm.queue_free())
	add_child(confirm)
	confirm.popup_centered()


func _import_save() -> void:
	if not OS.has_feature("web"):
		_file_dialog(FileDialog.FILE_MODE_OPEN_FILE, func(path: String) -> void: import_png(FileAccess.get_file_as_bytes(path)))
		return
	_web_import_callback = JavaScriptBridge.create_callback(func(args: Array) -> void: import_png(Marshalls.base64_to_raw(str(args[0]))))
	JavaScriptBridge.get_interface("window").rvImportSave = _web_import_callback
	JavaScriptBridge.eval("""(() => { const input = document.createElement('input');
		input.type = 'file'; input.accept = 'image/png';
		input.onchange = () => { const reader = new FileReader();
			reader.onload = () => window.rvImportSave(reader.result.split(',')[1]);
			reader.readAsDataURL(input.files[0]); };
		input.click(); })()""")


func import_png(png: PackedByteArray) -> void:
	_show_save("Sauvegarde importée." if SaveGame.from_png(png) else "Cette image ne contient pas de sauvegarde de Retro Venture.")


func _file_dialog(mode: FileDialog.FileMode, on_selected: Callable) -> void:
	var dialog := FileDialog.new()
	dialog.file_mode = mode
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.use_native_dialog = true
	dialog.filters = ["*.png ; Image PNG"]
	dialog.current_file = SaveGame.EXPORT_NAME
	dialog.file_selected.connect(on_selected)
	dialog.visibility_changed.connect(func() -> void: if not dialog.visible: dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered_ratio(0.6)


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
