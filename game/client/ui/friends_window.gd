class_name FriendsWindow
extends CanvasLayer
## Amis et joueurs ignorés (en ligne, jalon M3, GDD § 16.5), touche F ou bouton « Amis » de la bande
## droite. Pour chaque ami : en ligne (sa carte, « en combat ») ou hors ligne, « Écrire » et
## « Retirer » ; un champ pour en ajouter un par son pseudo. Les ignorés, dessous, avec « Ne plus
## ignorer ». Le statut d'un ami ne se voit que s'il nous compte aussi parmi ses amis.

## « Écrire » à un ami : la ligne de saisie du chat se prépare.
signal whisper_requested(player_name: String)

var map_view: MapView
## En ligne seulement (réglé par `setup` d'après la connexion ; les tests le forcent).
var enabled := false
var _panel: PanelContainer
var _friends: VBoxContainer
var _ignored: VBoxContainer
var _friend_field: LineEdit
var _ignore_field: LineEdit


func _ready() -> void:
	_build()
	_panel.visible = false


func setup(p_map_view: MapView) -> void:
	map_view = p_map_view
	enabled = map_view.connection.asynchronous
	map_view.relations_changed.connect(func(_event: Dictionary) -> void: refresh())


func is_open() -> bool:
	return _panel.visible


func toggle() -> void:
	if is_open():
		close()
	else:
		open()


## Ouvre la fenêtre et redemande la liste au serveur (statuts à jour).
func open() -> void:
	if map_view == null or not enabled:
		return
	_panel.visible = true
	refresh()
	_send("", "")


func close() -> void:
	_panel.visible = false
	_friend_field.release_focus()
	_ignore_field.release_focus()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_F:
		toggle()
		get_viewport().set_input_as_handled()
	elif is_open() and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


## Redessine les deux listes d'après la copie du client.
func refresh() -> void:
	if map_view == null or not is_open():
		return
	for child in _friends.get_children() + _ignored.get_children():
		child.queue_free()
	var friends: Array = map_view.world.relations.get("amis", [])
	if friends.is_empty():
		_friends.add_child(_dim("Aucun ami pour l'instant."))
	for friend: Dictionary in friends:
		var row := _row()
		var status := "hors ligne"
		if friend.get("en_ligne", false):
			status = "en combat" if friend.get("combat", false) else "en ligne"
			var place := map_view.world.map_name(str(friend.get("carte", "")))
			if not place.is_empty():
				status += ", " + place
		var label := Label.new()
		label.text = "%s (%s)" % [friend["nom"], status]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_color_override("font_color", UiTheme.TEXT if friend.get("en_ligne", false) else UiTheme.TEXT_DIM)
		row.add_child(label)
		var write := _small("Écrire", func() -> void:
			close()
			whisper_requested.emit(friend["nom"]))
		write.disabled = not friend.get("en_ligne", false)
		row.add_child(write)
		row.add_child(_small("Retirer", _send.bind(Relations.REMOVE, friend["nom"])))
		_friends.add_child(row)
	var ignored: Array = map_view.world.relations.get("ignores", [])
	if ignored.is_empty():
		_ignored.add_child(_dim("Personne."))
	for ignored_name: String in ignored:
		var row := _row()
		var label := Label.new()
		label.text = ignored_name
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		row.add_child(_small("Ne plus ignorer", _send.bind(Relations.UNIGNORE, ignored_name)))
		_ignored.add_child(row)


## Lignes de la liste d'amis (pour les tests) : « Nom (statut) ».
func friend_lines() -> PackedStringArray:
	var lines: PackedStringArray = []
	for row in _friends.get_children():
		if row is HBoxContainer and not row.is_queued_for_deletion():
			lines.append((row.get_child(0) as Label).text)
	return lines


func _send(action: String, player_name: String) -> void:
	map_view.send_command({"type": Protocol.CMD_RELATIONS, "entite": map_view.world.player_id, "action": action,
		"nom": player_name})


func _add_from(field: LineEdit, action: String) -> void:
	var player_name := field.text.strip_edges()
	if player_name.is_empty():
		return
	field.clear()
	_send(action, player_name)


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.add_theme_stylebox_override("panel", UiTheme.window_style())
	_panel.custom_minimum_size = Vector2(440, 380)
	add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	_panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "Amis"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", UiTheme.GOLD)
	header.add_child(title)
	header.add_child(_small("Fermer", close))
	column.add_child(_dim("On voit un ami en ligne s'il vous compte aussi parmi ses amis."))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	_friends = VBoxContainer.new()
	_friends.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_friends)
	_friend_field = _field(column, "Pseudo d'un ami", "Ajouter", Relations.ADD)
	column.add_child(HSeparator.new())
	var ignored_title := Label.new()
	ignored_title.text = "Ignorés (ni messages ni invitations)"
	ignored_title.add_theme_color_override("font_color", UiTheme.GOLD)
	column.add_child(ignored_title)
	_ignored = VBoxContainer.new()
	column.add_child(_ignored)
	_ignore_field = _field(column, "Pseudo à ignorer", "Ignorer", Relations.IGNORE)


func _field(column: VBoxContainer, hint: String, label: String, action: String) -> LineEdit:
	var row := _row()
	column.add_child(row)
	var field := LineEdit.new()
	field.placeholder_text = hint
	field.max_length = Character.NAME_MAX_LENGTH
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.text_submitted.connect(func(_text: String) -> void: _add_from(field, action))
	row.add_child(field)
	row.add_child(_small(label, func() -> void: _add_from(field, action)))
	return field


func _row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	return row


func _small(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	return button


func _dim(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", UiTheme.TEXT_DIM)
	return label
