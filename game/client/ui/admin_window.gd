class_name AdminWindow
extends CanvasLayer
## Mode admin (tests, depuis les options) : mot de passe (`World.ADMIN_PASSWORD`), puis se donner objets, brumes,
## réputation et points de maîtrise de métier et de classe (`Protocol.CMD_ADMIN`). Une fois activé, un double-clic
## sur une carte de la minicarte y téléporte. Touche F2 en partie.

const SIZE := Vector2(560, 540)

var map_view: MapView
var _panel: PanelContainer
var _password: LineEdit
var _login: Control
var _tools: Control
var _search: LineEdit
var _items: ItemList
var _item_amount: SpinBox
var _ecus: SpinBox
var _job: OptionButton
var _class: OptionButton
var _status: Label


func _ready() -> void:
	layer = 62
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_panel.visible = false


func open() -> void:
	_panel.visible = true
	_fill()
	_password.text = ""
	_status.text = ""
	if not map_view.notice.is_connected(_on_notice):
		map_view.notice.connect(_on_notice)


func close() -> void:
	_panel.visible = false


func is_open() -> bool:
	return _panel.visible


func _process(_delta: float) -> void:
	if not is_open() or map_view == null or map_view.world == null:
		return
	var world := map_view.world
	_login.visible = not world.admin
	_tools.visible = world.admin
	if world.admin and _job.item_count > 0:
		var job_id: String = _job.get_item_metadata(_job.selected)
		var class_id: String = _class.get_item_metadata(_class.selected)
		var entry: Dictionary = world.character.classes.get(class_id, {})
		_status.text = "%d brumes · métier : %d de réputation, %d points · classe : %d de réputation, %d points" % [
			world.character.inventory.ecus, world.character.job_reputation(job_id), world.character.job_points(job_id),
			int(entry.get("reputation", 0)), int(entry.get("points", 0))]


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if is_open() and event.is_action_pressed("ui_cancel") or key != null and key.pressed and not key.echo and key.keycode == KEY_F2 and map_view != null:
		close() if is_open() else open()  # F2 : ouvrir ou fermer, en partie.
		get_viewport().set_input_as_handled()


func _on_notice(text: String) -> void:
	if is_open():
		_status.text = text


func _send(action: String, extra := {}) -> void:
	var command := {"type": Protocol.CMD_ADMIN, "entite": map_view.world.player_id, "action": action}
	command.merge(extra)
	map_view.send_command(command)


## Listes des métiers, des classes et des objets (tirées des données du jeu).
func _fill() -> void:
	var data := map_view.world.data
	if data == null or _job.item_count > 0:
		return
	for pair: Array in [[_job, data.jobs], [_class, data.voies]]:
		for id: String in pair[1]:
			pair[0].add_item(pair[1][id]["nom"])
			pair[0].set_item_metadata(pair[0].item_count - 1, id)
	_job.select(0)
	_class.select(maxi(0, data.voies.keys().find(map_view.world.character.voie_id)))
	_filter("")


func _filter(text: String) -> void:
	_items.clear()
	var data := map_view.world.data
	for id: String in data.items:
		var name := str(data.items[id].get("nom", id))
		if text.is_empty() or text.to_lower() in (name + " " + id).to_lower():
			_items.add_item("%s (%s)" % [name, data.items[id].get("type", "")])
			_items.set_item_metadata(_items.item_count - 1, id)


func _give_item() -> void:
	for index in _items.get_selected_items():
		_send("objet", {"objet": _items.get_item_metadata(index), "quantite": int(_item_amount.value)})


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiTheme.window_style())
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -SIZE.x / 2
	_panel.offset_right = SIZE.x / 2
	_panel.offset_top = -SIZE.y / 2
	_panel.offset_bottom = SIZE.y / 2
	add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_panel.add_child(column)
	var title := Label.new()
	title.text = "Mode admin"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", UiTheme.GOLD)
	column.add_child(title)

	_login = HBoxContainer.new()
	column.add_child(_login)
	_login.add_child(_label("Mot de passe"))
	_password = LineEdit.new()
	_password.secret = true
	_password.custom_minimum_size = Vector2(200, 34)
	_password.text_submitted.connect(func(text: String) -> void: _send("activer", {"mdp": text}))
	_login.add_child(_password)
	_login.add_child(_button("Activer", func() -> void: _send("activer", {"mdp": _password.text})))

	_tools = VBoxContainer.new()
	_tools.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_tools)
	var item_row := HBoxContainer.new()
	_tools.add_child(item_row)
	item_row.add_child(_label("Objet"))
	_search = LineEdit.new()
	_search.placeholder_text = "chercher (nom ou id)"
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.text_changed.connect(_filter)
	item_row.add_child(_search)
	_item_amount = _amount(1, 1000, 10)
	item_row.add_child(_item_amount)
	item_row.add_child(_button("Donner", _give_item))
	_items = ItemList.new()
	_items.select_mode = ItemList.SELECT_MULTI
	_items.custom_minimum_size = Vector2(0, 120)
	_items.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_items.item_activated.connect(func(_index: int) -> void: _give_item())
	_tools.add_child(_items)

	var ecus_row := HBoxContainer.new()
	_tools.add_child(ecus_row)
	ecus_row.add_child(_label("Brumes"))
	_ecus = _amount(-1000000, 10000000, 10000)
	ecus_row.add_child(_ecus)
	ecus_row.add_child(_button("Donner", func() -> void: _send("brumes", {"quantite": int(_ecus.value)})))

	for kind: String in ["metier", "classe"]:
		var row := HBoxContainer.new()
		_tools.add_child(row)
		row.add_child(_label("Métier" if kind == "metier" else "Classe"))
		var choice := OptionButton.new()
		choice.custom_minimum_size = Vector2(150, 0)
		row.add_child(choice)
		var amount := _amount(1, 1000000, 2500 if kind == "metier" else 1000)
		row.add_child(amount)
		var key := "metier" if kind == "metier" else "voie"
		for action: String in ["reputation", "points"]:
			row.add_child(_button("Réputation" if action == "reputation" else "Points", func() -> void:
				_send("%s_%s" % [action, kind], {key: choice.get_item_metadata(choice.selected), "quantite": int(amount.value)})))
		if kind == "metier":
			_job = choice
		else:
			_class = choice
	var hint := Label.new()
	hint.text = "Double-clic sur une carte de la minicarte : téléportation."
	hint.add_theme_color_override("font_color", UiTheme.GOLD)
	_tools.add_child(hint)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(0, 40)
	column.add_child(_status)
	var close_button := _button("Fermer", close)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(close_button)


func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(90, 0)
	return label


func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 32)
	button.pressed.connect(action)
	return button


func _amount(low: int, high: int, value: int) -> SpinBox:
	var box := SpinBox.new()
	box.min_value = low
	box.max_value = high
	box.value = value
	box.custom_minimum_size = Vector2(110, 0)
	return box


## Commandes de la fenêtre (pour les tests).
func controls() -> Dictionary:
	return {"mot_de_passe": _password, "objets": _items, "recherche": _search, "quantite": _item_amount, "brumes": _ecus,
		"metier": _job, "classe": _class, "connexion": _login, "outils": _tools}
