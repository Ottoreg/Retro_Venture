class_name OnlineScreen
extends Control
## Écran du jeu en ligne (prototype, GDD § 16.5, jalon M1) : connexion au compte (adresse et mot de
## passe, Supabase), ou pseudo seul sur un serveur de développement ; trouve l'adresse du serveur
## (options, sinon celle que publie le serveur de test), ouvre la connexion et attend le personnage.
## Un compte sans personnage passe par l'écran de création, qui revient ici.

const SCENE := "res://client/online/online.tscn"
const WORLD_SCENE := "res://client/world/world.tscn"
const CREATION_SCENE := "res://client/creation/creation.tscn"
const MENU_SCENE := "res://client/main/main.tscn"
## Serveur essayé sans réglage ni Supabase (développement sur le même poste).
const LOCAL_SERVER := "ws://localhost:8080"
## Attente maximale de la réponse du serveur (s).
const CONNECT_TIMEOUT := 20.0

var _email: LineEdit
var _password: LineEdit
var _pseudo: LineEdit
var _connect_button: Button
var _sign_up_button: Button
var _status: Label
var _supabase: Supabase
var _waiting := 0.0
## Serveur de développement même si le projet Supabase est réglé (tests).
static var force_dev := false
var _busy := false


func _ready() -> void:
	UiTheme.apply(get_tree())
	Options.load_options()
	if OnlineConfig.has_accounts() and not force_dev:
		_supabase = Supabase.new(OnlineConfig.SUPABASE_URL, OnlineConfig.PUBLISHABLE_KEY, self)
	_build()
	if not Session.online_error.is_empty():
		_show(Session.online_error, true)
		Session.online_error = ""
	if Session.online_connection != null:
		_busy = true  # Retour de l'écran de création : on attend le personnage.
		_show("Création du personnage…")


func _process(delta: float) -> void:
	var connection := Session.online_connection
	if connection == null:
		return
	connection.poll()
	_waiting += delta
	match connection.status:
		RemoteConnection.Status.READY:
			set_process(false)
			get_tree().change_scene_to_file(WORLD_SCENE)
		RemoteConnection.Status.NEEDS_CHARACTER:
			set_process(false)
			get_tree().change_scene_to_file(CREATION_SCENE)
		RemoteConnection.Status.CLOSED:
			_fail(connection.error_message if not connection.error_message.is_empty() else "Connexion impossible.")
		_:
			if _waiting > CONNECT_TIMEOUT:
				connection.close()
				_fail("Le serveur ne répond pas.")


func _on_connect_pressed() -> void:
	if _busy:
		return
	_busy = true
	_set_buttons(false)
	var token := ""
	if _supabase != null:
		_show("Connexion au compte…")
		var answer: Dictionary = await _supabase.sign_in(_email.text.strip_edges(), _password.text)
		if answer.has("erreur"):
			_fail(answer["erreur"])
			return
		token = answer["jeton"]
	else:
		var error := Character.name_error(_pseudo.text)
		if not error.is_empty():
			_fail(error)
			return
		token = AccountCheck.DEV_PREFIX + _pseudo.text.strip_edges()
	var address := await _server_address()
	if address.is_empty():
		_fail("Aucun serveur de test en ligne pour l'instant : réessayez plus tard.")
		return
	_show("Connexion au serveur…")
	_waiting = 0.0
	Session.online_connection = RemoteConnection.new(address, token, GameData.load_all(),
		func(map_id: String) -> GameMap: return DataLoader.load_map(DataLoader.map_path(map_id)), DataLoader.map_ids())


func _on_sign_up_pressed() -> void:
	if _busy or _supabase == null:
		return
	_busy = true
	_set_buttons(false)
	_show("Création du compte…")
	var answer: Dictionary = await _supabase.sign_up(_email.text.strip_edges(), _password.text)
	_busy = false
	_set_buttons(true)
	if answer.has("erreur"):
		_show(answer["erreur"], true)
	elif answer["confirmer"]:
		_show("Compte créé : confirmez votre adresse avec le lien reçu par courriel, puis connectez-vous.")
	else:
		_show("Compte créé : vous pouvez vous connecter.")


## Adresse du serveur : celle des options, sinon celle que publie le serveur de test (Supabase),
## sinon un serveur sur ce poste.
func _server_address() -> String:
	if not Options.server_address.is_empty():
		return Options.server_address
	if _supabase != null:
		_show("Recherche du serveur…")
		return await _supabase.live_server_address()
	return LOCAL_SERVER


func _fail(message: String) -> void:
	if Session.online_connection != null:
		Session.online_connection.close()
	Session.online_connection = null
	_busy = false
	_set_buttons(true)
	_show(message, true)


func _show(message: String, error := false) -> void:
	_status.text = message
	_status.add_theme_color_override("font_color", Color(1, 0.55, 0.45) if error else Color(0.85, 0.82, 0.75))


func _set_buttons(enabled: bool) -> void:
	_connect_button.disabled = not enabled
	if _sign_up_button != null:
		_sign_up_button.disabled = not enabled


func _on_back_pressed() -> void:
	if Session.online_connection != null:
		Session.online_connection.close()
		Session.online_connection = null
	get_tree().change_scene_to_file(MENU_SCENE)


func _build() -> void:
	var background := ColorRect.new()
	background.color = Color(0.168627, 0.129412, 0.0941176)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.window_style())
	panel.custom_minimum_size = Vector2(460, 0)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	var title := Label.new()
	title.text = "Jouer en ligne (prototype)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", UiTheme.GOLD)
	column.add_child(title)
	var intro := Label.new()
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size = Vector2(420, 0)
	if _supabase != null:
		intro.text = "Un compte porte un personnage, gardé sur le serveur. Les parties solo ne passent pas en ligne."
	else:
		intro.text = "Serveur de développement : un pseudo suffit (%s)." % (Options.server_address if not Options.server_address.is_empty() else LOCAL_SERVER)
	column.add_child(intro)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	column.add_child(grid)
	if _supabase != null:
		_email = _field(grid, "Adresse e-mail", "vous@exemple.fr")
		_password = _field(grid, "Mot de passe", "")
		_password.secret = true
		_password.text_submitted.connect(func(_text: String) -> void: _on_connect_pressed())
	else:
		_pseudo = _field(grid, "Pseudo", "Aventurier")
		_pseudo.text_submitted.connect(func(_text: String) -> void: _on_connect_pressed())
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 8)
	column.add_child(buttons)
	_connect_button = _button(buttons, "Se connecter", _on_connect_pressed)
	if _supabase != null:
		_sign_up_button = _button(buttons, "Créer un compte", _on_sign_up_pressed)
	_button(buttons, "Retour", _on_back_pressed)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(420, 0)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_status)
	(_email if _email != null else _pseudo).grab_focus.call_deferred()


func _field(grid: GridContainer, caption: String, placeholder: String) -> LineEdit:
	var label := Label.new()
	label.text = caption
	grid.add_child(label)
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.custom_minimum_size = Vector2(260, 34)
	grid.add_child(edit)
	return edit


func _button(row: HBoxContainer, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(130, 38)
	button.pressed.connect(action)
	row.add_child(button)
	return button
