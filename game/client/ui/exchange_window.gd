class_name ExchangeWindow
extends CanvasLayer
## Échange entre joueurs (en ligne, jalon M4, GDD § 16.5), ouvert quand l'autre joueur accepte (ou
## qu'on accepte sa proposition) : l'inventaire à gauche, sa propre offre et celle de l'autre à
## droite, avec les brumes. Chaque changement retire les deux validations, et « Valider » attend
## quelques secondes après le dernier (`Exchange.VALIDATE_DELAY`). L'échange se fait quand les deux
## ont validé ; fermer la fenêtre (×, Échap) l'annule. Tout est décidé par le serveur : la fenêtre
## ne fait que montrer son dernier état (EVT_EXCHANGE).

const GOLD := Color(0.95, 0.76, 0.3)
const OK_COLOR := Color(0.45, 0.85, 0.4)

var map_view: MapView

var _refusal_texts := {
	Protocol.REASON_ITEM_WORN: "Retirez d'abord cet objet (inventaire, touche I).",
	Protocol.REASON_QUEST_ITEM: "Un objet de quête ne s'échange pas.",
	Protocol.REASON_NOT_ENOUGH_ECUS: "Vous n'avez pas autant de brumes.",
	Protocol.REASON_TOO_SOON: "L'offre vient de changer : relisez-la avant de valider.",
	Protocol.REASON_OFFER_FULL: "Votre offre est pleine (%d objets)." % Exchange.MAX_ITEMS,
}
var _panel: PanelContainer
var _title: Label
var _bag_title: Label
var _bag_list: ItemList
var _mine_list: ItemList
var _theirs_title: Label
var _theirs_list: ItemList
var _quantity: SpinBox
var _offer_button: Button
var _remove_button: Button
var _ecus: SpinBox
var _theirs_ecus: Label
var _status: Label
var _validate_button: Button
var _message: Label
## Dernier état reçu (EVT_EXCHANGE), {} sans échange.
var _state: Dictionary = {}
## Secondes avant de pouvoir valider.
var _wait := 0.0
## Objet choisi : uid dans le sac (`_from_offer` faux) ou dans sa propre offre.
var _selected := ""
var _from_offer := false


func _ready() -> void:
	_build()
	_panel.visible = false


func setup(p_map_view: MapView) -> void:
	map_view = p_map_view
	map_view.exchange_changed.connect(show_exchange)
	map_view.exchange_closed.connect(_on_closed)
	map_view.exchange_refused.connect(_on_refused)
	map_view.inventory_changed.connect(refresh)


func is_open() -> bool:
	return _panel.visible


## Ouvre l'échange, ou le met à jour d'après le serveur.
func show_exchange(event: Dictionary) -> void:
	if not is_open():
		_selected = ""
	_state = event
	_wait = float(event.get("attente", 0.0))
	_message.text = str(event.get("erreur", ""))
	_panel.visible = true
	refresh()


## Annule l'échange (la fenêtre se ferme à la réponse du serveur).
func cancel() -> void:
	if is_open():
		_send({"action": Exchange.CANCEL})


func _on_closed(event: Dictionary) -> void:
	_panel.visible = false
	_state = {}
	var texts := {
		Exchange.CLOSED_DONE: "Échange conclu avec %s.",
		Exchange.CLOSED_CANCELLED: "Échange avec %s annulé.",
		Exchange.CLOSED_DECLINED: "%s refuse l'échange.",
		Exchange.CLOSED_LEFT: "Échange annulé : %s est parti.",
	}
	map_view.notice.emit(str(texts.get(event["raison"], "Échange avec %s terminé.")) % event["nom"])


func _on_refused(event: Dictionary) -> void:
	var text: String = _refusal_texts.get(event["raison"], "Impossible.")
	if is_open():
		_message.text = text
	else:
		map_view.notice.emit({
			Protocol.REASON_PLAYER_BUSY: "Ce joueur est occupé (combat ou autre échange).",
			Protocol.REASON_UNKNOWN_ENTITY: "Ce joueur n'est plus sur la carte.",
			Protocol.REASON_NO_INVITATION: "La proposition d'échange n'est plus valable.",
			Protocol.REASON_IN_EXCHANGE: "Terminez d'abord votre échange.",
		}.get(event["raison"], "Échange impossible pour l'instant."))


func _process(delta: float) -> void:
	if not is_open() or _wait <= 0.0:
		return
	_wait = maxf(0.0, _wait - delta)
	_update_validate()


func refresh() -> void:
	if map_view == null or not is_open() or _state.is_empty():
		return
	var world := map_view.world
	var other_name: String = _state.get("nom", "?")
	_title.text = "Échange avec %s" % other_name
	var offered := {}
	for line: Dictionary in _state["mien"]["objets"]:
		offered[line["uid"]] = int(line["quantite"])
	var bag: Array = []
	for entry: Dictionary in world.character.inventory_sheet(world.data)["objets"]:
		var left := int(entry["quantite"]) - int(offered.get(entry["uid"], 0))
		if left > 0:
			var shown := entry.duplicate()
			shown["quantite"] = left
			bag.append(shown)
	_bag_title.text = "Inventaire (%d brumes)" % world.character.inventory.ecus
	var found := _fill(_bag_list, bag, false)
	found = _fill(_mine_list, _sheet(_state["mien"]["objets"]), true) or found
	_fill(_theirs_list, _sheet(_state["sien"]["objets"]), null)
	if not found:
		_selected = ""
	_theirs_title.text = "Offre de %s" % other_name
	_theirs_ecus.text = "%d brumes" % int(_state["sien"]["brumes"])
	if not _ecus.get_line_edit().has_focus():
		_ecus.max_value = maxi(world.character.inventory.ecus, int(_state["mien"]["brumes"]))
		_ecus.set_value_no_signal(int(_state["mien"]["brumes"]))
	var entry := _selected_entry(bag)
	var max_quantity := int(entry.get("quantite", 1))
	_quantity.max_value = maxi(1, max_quantity)
	_quantity.editable = max_quantity > 1
	var worn := not str(entry.get("emplacement", "")).is_empty()
	_offer_button.disabled = entry.is_empty() or _from_offer or worn
	_remove_button.disabled = entry.is_empty() or not _from_offer
	var lines: PackedStringArray = []
	lines.append("Vous avez validé." if _state["valide_moi"] else "Vous n'avez pas validé.")
	lines.append(("%s a validé." if _state["valide_lui"] else "%s n'a pas validé.") % other_name)
	_status.text = "  ·  ".join(lines)
	_status.add_theme_color_override("font_color", OK_COLOR if _state["valide_lui"] else Color(0.85, 0.82, 0.72))
	_update_validate()


## Texte des validations (tests).
func status_text() -> String:
	return _status.text


func _update_validate() -> void:
	var done: bool = _state.get("valide_moi", false)
	_validate_button.disabled = done or _wait > 0.0
	_validate_button.text = "Validé" if done else ("Valider (%d)" % ceili(_wait) if _wait > 0.0 else "Valider")


## Lignes d'une offre, comme celles de l'inventaire (pour les listes et leurs infobulles).
func _sheet(lines: Array) -> Array:
	var sheet: Array = []
	for line: Dictionary in lines:
		var template: Dictionary = map_view.world.data.items.get(line["objet"], {})
		sheet.append({"uid": line["uid"], "objet": line["objet"], "nom": template.get("nom", line["objet"]),
			"type": template.get("type", ""), "rarete": template.get("rarete", "commun"),
			"niveau": int(template.get("niveau", 1)), "description": template.get("description", ""),
			"quantite": line["quantite"], "jets": line["jets"], "conditions": template.get("conditions", {}),
			"emplacement": ""})
	return sheet


## Remplit une liste ; `offer_side` : vrai pour sa propre offre, faux pour le sac, null pour l'offre
## de l'autre (pas sélectionnable). Vrai si l'objet choisi y est.
func _fill(list: ItemList, entries: Array, offer_side: Variant) -> bool:
	var found := false
	list.clear()
	for entry: Dictionary in entries:
		var worn := not str(entry.get("emplacement", "")).is_empty()
		var label := "%s%s%s" % [entry["nom"], " ×%d" % entry["quantite"] if int(entry["quantite"]) > 1 else "", "   (porté)" if worn else ""]
		var index := list.add_item(label, InventoryWindow.item_icon(entry["objet"]))
		list.set_item_custom_fg_color(index, Color(0.5, 0.5, 0.5) if worn else InventoryWindow.rarity_color(entry["rarete"]))
		list.set_item_metadata(index, entry["uid"])
		list.set_item_tooltip(index, ItemTooltipList.tooltip_text_for(entry, map_view.world.data, map_view.world.character.inventory))
		if offer_side == null:
			list.set_item_selectable(index, false)
		elif entry["uid"] == _selected and _from_offer == offer_side:
			list.select(index)
			found = true
	return found


func _selected_entry(bag: Array) -> Dictionary:
	for entry: Dictionary in (_sheet(_state["mien"]["objets"]) if _from_offer else bag):
		if entry["uid"] == _selected:
			return entry
	return {}


func _select(uid: String, from_offer: bool) -> void:
	_selected = uid
	_from_offer = from_offer
	refresh()
	_quantity.value = _quantity.max_value


## Met dans l'offre (ou en retire) la quantité choisie de l'objet choisi.
func _change_offer(adding: bool) -> void:
	if _selected.is_empty():
		return
	var offered := 0
	for line: Dictionary in _state["mien"]["objets"]:
		if line["uid"] == _selected:
			offered = int(line["quantite"])
	var quantity := offered + int(_quantity.value) * (1 if adding else -1)
	_send({"action": Exchange.ITEM, "objet": _selected, "quantite": maxi(0, quantity)})


## Ajoute à l'offre (tests) : `quantity` exemplaires de plus de l'objet `uid`.
func offer(uid: String, quantity: int) -> void:
	_select(uid, false)
	_quantity.value = quantity
	_change_offer(true)


func _on_ecus_changed(value: float) -> void:
	_send({"action": Exchange.ECUS, "brumes": int(value)})


func validate() -> void:
	_send({"action": Exchange.VALIDATE})


func _send(extra: Dictionary) -> void:
	_message.text = ""
	var command := {"type": Protocol.CMD_EXCHANGE, "entite": map_view.world.player_id}
	command.merge(extra)
	map_view.send_command(command)


func _unhandled_key_input(event: InputEvent) -> void:
	if is_open() and event.is_action_pressed("ui_cancel"):
		cancel()
		get_viewport().set_input_as_handled()


# --- Construction des contrôles ----------------------------------------------------------------

func _build() -> void:
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.offset_left = -420
	_panel.offset_right = 420
	_panel.offset_top = 40
	_panel.offset_bottom = 530
	_panel.add_theme_stylebox_override("panel", UiTheme.window_style())
	add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	_title = _label(22, GOLD)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	header.add_child(_button("×", cancel, "Annuler l'échange"))

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	var bag_box := VBoxContainer.new()
	bag_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bag_box)
	_bag_title = _label(15, Color(0.85, 0.82, 0.72))
	bag_box.add_child(_bag_title)
	_bag_list = _list(bag_box)
	_bag_list.item_selected.connect(func(index: int) -> void: _select(_bag_list.get_item_metadata(index), false))

	var actions := VBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
	row.add_child(actions)
	var quantity_label := _label(14, Color(0.8, 0.78, 0.7))
	quantity_label.text = "Quantité"
	actions.add_child(quantity_label)
	_quantity = SpinBox.new()
	_quantity.min_value = 1
	_quantity.value = 1
	actions.add_child(_quantity)
	_offer_button = _button("Proposer »", _change_offer.bind(true))
	actions.add_child(_offer_button)
	_remove_button = _button("« Retirer", _change_offer.bind(false))
	actions.add_child(_remove_button)

	var offers := VBoxContainer.new()
	offers.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(offers)
	var mine_title := _label(15, Color(0.85, 0.82, 0.72))
	mine_title.text = "Votre offre"
	offers.add_child(mine_title)
	_mine_list = _list(offers)
	_mine_list.item_selected.connect(func(index: int) -> void: _select(_mine_list.get_item_metadata(index), true))
	var ecus_row := HBoxContainer.new()
	offers.add_child(ecus_row)
	_ecus = SpinBox.new()
	_ecus.min_value = 0
	_ecus.suffix = "brumes"
	_ecus.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ecus.value_changed.connect(_on_ecus_changed)
	ecus_row.add_child(_ecus)
	offers.add_child(HSeparator.new())
	_theirs_title = _label(15, Color(0.85, 0.82, 0.72))
	offers.add_child(_theirs_title)
	_theirs_list = _list(offers)
	_theirs_ecus = _label(15, GOLD)
	offers.add_child(_theirs_ecus)

	_status = _label(15, Color(0.85, 0.82, 0.72))
	column.add_child(_status)
	_message = _label(14, Color(1.0, 0.5, 0.4))
	column.add_child(_message)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 10)
	column.add_child(buttons)
	var hint := _label(12, Color(0.6, 0.58, 0.52))
	hint.text = "Chaque changement retire les validations · Échap : annuler"
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(hint)
	buttons.add_child(_button("Annuler", cancel))
	_validate_button = _button("Valider", validate)
	buttons.add_child(_validate_button)


func _list(parent: Control) -> ItemList:
	var list := ItemTooltipList.new()
	list.fixed_icon_size = Vector2i(28, 28)
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(list)
	return list


func _button(text: String, action: Callable, tooltip := "") -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = tooltip
	button.pressed.connect(action)
	return button


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
