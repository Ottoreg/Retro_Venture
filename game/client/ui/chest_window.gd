class_name ChestWindow
extends CanvasLayer
## Coffre de la maison : l'inventaire à gauche, le coffre à droite, et de quoi déposer ou reprendre
## des objets (en entier ou en partie pour une pile de ressources).

const GOLD := Color(0.95, 0.76, 0.3)

var map_view: MapView

var _refusal_texts := {
	Protocol.REASON_INVENTORY_FULL: "Plus de place.",
	Protocol.REASON_ITEM_WORN: "Retirez d'abord cet objet (inventaire, touche I).",
	Protocol.REASON_TOO_FAR: "Le coffre est trop loin.",
}
var _backdrop: ColorRect
var _panel: PanelContainer
var _bag_title: Label
var _chest_title: Label
var _bag_list: ItemList
var _chest_list: ItemList
var _quantity: SpinBox
var _deposit_button: Button
var _withdraw_button: Button
var _message: Label
var _chest: Dictionary = {}
var _chest_cell := Vector2i.ZERO
## Objet choisi : uid dans le sac (`_from_chest` faux) ou dans le coffre.
var _selected := ""
var _from_chest := false


func _ready() -> void:
	_build()
	_set_visible(false)


func setup(p_map_view: MapView) -> void:
	map_view = p_map_view
	map_view.chest_changed.connect(show_chest)
	map_view.chest_refused.connect(_on_refused)
	map_view.inventory_changed.connect(refresh)
	map_view.combat_started.connect(close)
	map_view.map_changed.connect(close)


## Ouvre le coffre, ou met à jour son contenu s'il est déjà ouvert.
func show_chest(event: Dictionary) -> void:
	if not is_open():
		_selected = ""
		_message.text = ""
	_chest = event["coffre"]
	_chest_cell = event["case"]
	_set_visible(true)
	refresh()


func close() -> void:
	_set_visible(false)


func is_open() -> bool:
	return _panel.visible


func refresh() -> void:
	if map_view == null or not is_open():
		return
	var world := map_view.world
	var bag: Array = world.character.inventory_sheet(world.data)["objets"]
	var stored: Array = _chest.get("objets", [])
	_bag_title.text = "Inventaire (%d / %d)" % [bag.size(), world.character.inventory.capacity]
	_chest_title.text = "Coffre (%d / %d)" % [stored.size(), _chest.get("places", 0)]
	var found := _fill(_bag_list, bag, false)
	found = _fill(_chest_list, stored, true) or found
	if not found:
		_selected = ""
	var entry := _selected_entry()
	var max_quantity := int(entry.get("quantite", 1))
	_quantity.max_value = maxi(1, max_quantity)
	_quantity.editable = max_quantity > 1
	var worn := not str(entry.get("emplacement", "")).is_empty()
	_deposit_button.disabled = entry.is_empty() or _from_chest or worn
	_withdraw_button.disabled = entry.is_empty() or not _from_chest


func _fill(list: ItemList, entries: Array, chest_side: bool) -> bool:
	var found := false
	list.clear()
	for entry: Dictionary in entries:
		var worn := not str(entry.get("emplacement", "")).is_empty()
		var label := "%s%s%s" % [entry["nom"], " ×%d" % entry["quantite"] if int(entry["quantite"]) > 1 else "", "   (porté)" if worn else ""]
		var index := list.add_item(label)
		list.set_item_custom_fg_color(index, Color(0.5, 0.5, 0.5) if worn else InventoryWindow.rarity_color(entry["rarete"]))
		list.set_item_metadata(index, entry["uid"])
		if entry["uid"] == _selected and _from_chest == chest_side:
			list.select(index)
			found = true
	return found


func _selected_entry() -> Dictionary:
	if _selected.is_empty():
		return {}
	var world := map_view.world
	var entries: Array = _chest.get("objets", []) if _from_chest else world.character.inventory_sheet(world.data)["objets"]
	for entry: Dictionary in entries:
		if entry["uid"] == _selected:
			return entry
	return {}


func _on_bag_selected(index: int) -> void:
	_select(_bag_list.get_item_metadata(index), false)


func _on_chest_selected(index: int) -> void:
	_select(_chest_list.get_item_metadata(index), true)


func _select(uid: String, from_chest: bool) -> void:
	_selected = uid
	_from_chest = from_chest
	refresh()
	_quantity.value = _quantity.max_value


func _on_deposit_pressed() -> void:
	_send(Protocol.CMD_DEPOSIT)


func _on_withdraw_pressed() -> void:
	_send(Protocol.CMD_WITHDRAW)


func _send(type: String) -> void:
	if _selected.is_empty():
		return
	_message.text = ""
	map_view.send_command({
		"type": type,
		"entite": World.PLAYER_ID,
		"case": _chest_cell,
		"objet": _selected,
		"quantite": int(_quantity.value),
	})


func _on_refused(event: Dictionary) -> void:
	_message.text = _refusal_texts.get(event["raison"], "Impossible.")


func _on_backdrop_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.pressed:
		close()


func _set_visible(shown: bool) -> void:
	_panel.visible = shown
	_backdrop.visible = shown


# --- Construction des contrôles ----------------------------------------------------------------

func _build() -> void:
	# Fond assombri : un clic à côté de la fenêtre la ferme (et ne fait pas marcher le personnage).
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0, 0, 0, 0.35)
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_backdrop.gui_input.connect(_on_backdrop_input)
	add_child(_backdrop)

	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.offset_left = -400
	_panel.offset_right = 400
	_panel.offset_top = 70
	_panel.offset_bottom = 560
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.1, 0.07, 0.97)
	style.border_color = Color(0.55, 0.42, 0.22)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(14)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := _label(22, GOLD)
	title.text = "Coffre de la maison"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_button := Button.new()
	close_button.text = "×"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(close)
	header.add_child(close_button)

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	var bag_box := VBoxContainer.new()
	bag_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bag_box)
	_bag_title = _label(15, Color(0.85, 0.82, 0.72))
	bag_box.add_child(_bag_title)
	_bag_list = ItemList.new()
	_bag_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_bag_list.item_selected.connect(_on_bag_selected)
	bag_box.add_child(_bag_list)

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
	_deposit_button = Button.new()
	_deposit_button.text = "Déposer →"
	_deposit_button.focus_mode = Control.FOCUS_NONE
	_deposit_button.pressed.connect(_on_deposit_pressed)
	actions.add_child(_deposit_button)
	_withdraw_button = Button.new()
	_withdraw_button.text = "← Reprendre"
	_withdraw_button.focus_mode = Control.FOCUS_NONE
	_withdraw_button.pressed.connect(_on_withdraw_pressed)
	actions.add_child(_withdraw_button)

	var chest_box := VBoxContainer.new()
	chest_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(chest_box)
	_chest_title = _label(15, Color(0.85, 0.82, 0.72))
	chest_box.add_child(_chest_title)
	_chest_list = ItemList.new()
	_chest_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_chest_list.item_selected.connect(_on_chest_selected)
	chest_box.add_child(_chest_list)

	_message = _label(14, Color(1.0, 0.5, 0.4))
	column.add_child(_message)
	var hint := _label(12, Color(0.6, 0.58, 0.52))
	hint.text = "Les objets portés restent sur vous · Échap : fermer"
	column.add_child(hint)


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
