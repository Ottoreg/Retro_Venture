class_name ShopWindow
extends CanvasLayer
## Boutique d'un marchand : onglets Acheter (tous les objets du jeu, prix selon la rareté) et Vendre
## (objets de l'inventaire, à prix réduit). S'ouvre quand on parle à un marchand.

const GOLD := Color(0.95, 0.76, 0.3)
const BUY := "achat"
const SELL := "vente"
var _refusal_texts := {
	Protocol.REASON_NOT_ENOUGH_ECUS: "Pas assez de brumes.",
	Protocol.REASON_INVENTORY_FULL: "Inventaire plein.",
	Protocol.REASON_ITEM_WORN: "Retirez d'abord cet objet (inventaire, touche I).",
	Protocol.REASON_TOO_FAR: "Le marchand est trop loin.",
}

var map_view: MapView

var _backdrop: ColorRect
var _panel: PanelContainer
var _title: Label
var _coins: Label
## Ctrl enfoncé : jets possibles des objets à vendre plutôt que les leurs.
var _show_ranges := false
var _greeting: Label
var _buy_tab: Button
var _sell_tab: Button
var _search: LineEdit
var _list: ItemList
var _details: Label
var _quantity_box: HBoxContainer
var _quantity: SpinBox
var _action_button: Button
var _message: Label
var _shop: Dictionary = {}
var _mode := BUY
## Objet choisi : id du modèle (achat) ou uid de l'inventaire (vente).
var _selected := ""


func _ready() -> void:
	_build()
	_set_visible(false)


func setup(p_map_view: MapView) -> void:
	map_view = p_map_view
	map_view.shop_opened.connect(open)
	map_view.trade_result.connect(_on_trade_result)
	map_view.inventory_changed.connect(refresh)
	map_view.combat_started.connect(close)
	map_view.map_changed.connect(close)


func open(event: Dictionary) -> void:
	_shop = event
	_mode = BUY
	_selected = ""
	_title.text = event["nom"]
	var lines: Array = event["repliques"]
	_greeting.text = "« %s »" % lines[0] if not lines.is_empty() else ""
	_message.text = ""
	_search.text = ""
	_set_visible(true)
	refresh()


func close() -> void:
	_set_visible(false)


func is_open() -> bool:
	return _panel.visible


func refresh() -> void:
	if map_view == null or not is_open():
		return
	_buy_tab.button_pressed = _mode == BUY
	_sell_tab.button_pressed = _mode == SELL
	_coins.text = "%d brumes" % map_view.world.character.inventory.ecus
	_list.clear()
	var found := false
	for entry in _entries():
		if not matches_search(entry, _search.text):
			continue
		var key: String = entry["objet"] if _mode == BUY else entry["uid"]
		var label := "%s — %d brumes" % [entry["nom"], _unit_price(entry)]
		if _mode == SELL:
			label = "%s%s — %d brumes%s" % [entry["nom"], " ×%d" % entry["quantite"] if int(entry["quantite"]) > 1 else "",
				_unit_price(entry), "   (porté)" if _is_worn(entry) else ""]
		var index := _list.add_item(label, InventoryWindow.item_icon(entry["objet"]))
		_list.set_item_custom_fg_color(index, Color(0.5, 0.5, 0.5) if _is_worn(entry) else InventoryWindow.rarity_color(entry["rarete"]))
		_list.set_item_metadata(index, key)
		_list.set_item_tooltip(index, ItemTooltipList.tooltip_text_for(entry, map_view.world.data, map_view.world.character.inventory, _show_ranges))
		if key == _selected:
			_list.select(index)
			found = true
	if not found:
		_selected = ""
	_show_details(_selected_entry())


## Vrai si l'objet correspond à la recherche : chaque mot dans son nom ou son type (sans tenir
## compte des majuscules ni des accents).
static func matches_search(entry: Dictionary, search: String) -> bool:
	var haystack := fold_text("%s %s" % [entry["nom"], InventoryWindow.TYPE_NAMES.get(entry["type"], entry["type"])])
	for word in fold_text(search).split(" ", false):
		if not haystack.contains(word):
			return false
	return true


## Texte en minuscules, sans accents (é → e, œ → oe).
static func fold_text(text: String) -> String:
	var folded := text.to_lower()
	for pair: Array in [["àâä", "a"], ["éèêë", "e"], ["îï", "i"], ["ôö", "o"], ["ùûü", "u"], ["ÿ", "y"], ["ç", "c"]]:
		for letter in pair[0]:
			folded = folded.replace(letter, pair[1])
	return folded.replace("œ", "oe").replace("æ", "ae")


## Lignes de la liste : articles du marchand, ou objets de l'inventaire.
func _entries() -> Array:
	if _mode == BUY:
		return _shop.get("articles", [])
	var world := map_view.world
	return world.character.inventory_sheet(world.data)["objets"]


func _selected_entry() -> Dictionary:
	if _selected.is_empty():
		return {}
	for entry: Dictionary in _entries():
		if (entry["objet"] if _mode == BUY else entry["uid"]) == _selected:
			return entry
	return {}


func _unit_price(entry: Dictionary) -> int:
	if _mode == BUY:
		return int(entry["prix"])
	return Item.sell_price(map_view.world.data.items.get(entry["objet"], {}))


func _is_worn(entry: Dictionary) -> bool:
	return _mode == SELL and not str(entry.get("emplacement", "")).is_empty()


func _show_details(entry: Dictionary) -> void:
	if entry.is_empty():
		_details.text = "Choisissez un objet à acheter." if _mode == BUY else "Choisissez un objet à vendre."
		_quantity_box.visible = false
		_action_button.disabled = true
		_action_button.text = "Acheter" if _mode == BUY else "Vendre"
		return
	var lines: PackedStringArray = [
		"%s — %s" % [entry["nom"], Item.RARITY_NAMES.get(entry["rarete"], "")],
		"%s, palier %d" % [InventoryWindow.TYPE_NAMES.get(entry["type"], entry["type"]), entry["niveau"]],
	]
	if _mode == BUY:
		lines.append_array(InventoryWindow.bonus_range_lines(entry["bonus"]))
	else:
		lines.append_array(InventoryWindow.roll_lines(entry, map_view.world.data.items.get(entry["objet"], {}), _show_ranges))
	lines.append_array(InventoryWindow.attack_lines(map_view.world.data.items.get(entry["objet"], {})))
	lines.append_array(InventoryWindow.set_lines(entry["objet"], map_view.world.data, map_view.world.character.inventory))
	if not str(entry["description"]).is_empty():
		lines.append("")
		lines.append(entry["description"])
	lines.append("")
	lines.append(("Prix : %d brumes" if _mode == BUY else "Prix de revente : %d brumes") % _unit_price(entry)
		+ (" l'unité" if entry["type"] == Item.TYPE_RESOURCE else ""))
	_details.text = "\n".join(lines)

	var max_quantity := _max_quantity(entry)
	_quantity.max_value = maxi(1, max_quantity)
	_quantity_box.visible = max_quantity > 1
	_update_action_button()


## Quantité qu'on peut acheter ou vendre d'un coup : les équipements s'achètent un par un.
func _max_quantity(entry: Dictionary) -> int:
	if _mode == SELL:
		return int(entry["quantite"])
	return World.MAX_TRADE_QUANTITY if entry["type"] == Item.TYPE_RESOURCE else 1


func _update_action_button() -> void:
	var entry := _selected_entry()
	if entry.is_empty():
		return
	var quantity := int(_quantity.value) if _quantity_box.visible else 1
	var total := _unit_price(entry) * quantity
	if _mode == BUY:
		_action_button.text = "Acheter — %d brumes" % total
		_action_button.disabled = total > map_view.world.character.inventory.ecus
	else:
		_action_button.text = "Vendre — %d brumes" % total
		_action_button.disabled = _is_worn(entry)


func _on_tab_pressed(mode: String) -> void:
	if _mode != mode:
		_mode = mode
		_selected = ""
		_quantity.value = 1
	refresh()


func _on_item_selected(index: int) -> void:
	_selected = _list.get_item_metadata(index)
	_quantity.value = 1
	refresh()


func _on_quantity_changed(_value: float) -> void:
	_update_action_button()


func _on_action_pressed() -> void:
	if _selected.is_empty():
		return
	var quantity := int(_quantity.value) if _quantity_box.visible else 1
	map_view.send_command({
		"type": Protocol.CMD_BUY if _mode == BUY else Protocol.CMD_SELL,
		"entite": map_view.world.player_id,
		"pnj": _shop["pnj"],
		"objet": _selected,
		"quantite": quantity,
	})


func _on_trade_result(event: Dictionary) -> void:
	if event["type"] == Protocol.EVT_REFUSED:
		_message.text = _refusal_texts.get(event["raison"], "Impossible.")
		_message.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4))
		return
	var amount := " ×%d" % event["quantite"] if int(event["quantite"]) > 1 else ""
	if event["operation"] == BUY:
		_message.text = "Acheté : %s%s (−%d brumes)" % [event["nom"], amount, event["prix"]]
	else:
		_message.text = "Vendu : %s%s (+%d brumes)" % [event["nom"], amount, event["prix"]]
	_message.add_theme_color_override("font_color", Color(0.55, 0.9, 0.5))
	_quantity.value = 1
	refresh()


func _on_backdrop_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.pressed:
		close()


func _set_visible(shown: bool) -> void:
	_panel.visible = shown
	_backdrop.visible = shown


func _input(event: InputEvent) -> void:
	if InventoryWindow.is_ctrl_event(event) and is_open() and event.is_pressed() != _show_ranges:
		_show_ranges = event.is_pressed()
		refresh()


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
	_panel.offset_left = -420
	_panel.offset_right = 420
	_panel.offset_top = 60
	_panel.offset_bottom = 590
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
	_title = _label(22, GOLD)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	_coins = _label(16, GOLD)
	header.add_child(_coins)
	var close_button := Button.new()
	close_button.text = "×"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(close)
	header.add_child(close_button)

	_greeting = _label(14, Color(0.85, 0.82, 0.72))
	_greeting.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_greeting)

	var tabs := HBoxContainer.new()
	column.add_child(tabs)
	var group := ButtonGroup.new()
	_buy_tab = _tab_button("Acheter", BUY, group)
	_sell_tab = _tab_button("Vendre", SELL, group)
	tabs.add_child(_buy_tab)
	tabs.add_child(_sell_tab)

	_search = LineEdit.new()
	_search.placeholder_text = "Rechercher un objet (nom ou type)…"
	_search.clear_button_enabled = true
	_search.custom_minimum_size = Vector2(380, 0)
	_search.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_search.text_changed.connect(func(_text: String) -> void: refresh())
	column.add_child(_search)

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)
	column.add_child(row)
	_list = ItemTooltipList.new()
	_list.custom_minimum_size = Vector2(380, 0)
	_list.fixed_icon_size = Vector2i(28, 28)
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_on_item_selected)
	row.add_child(_list)

	var detail_box := VBoxContainer.new()
	detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(detail_box)
	_details = _label(14, Color(0.92, 0.9, 0.85))
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.custom_minimum_size = Vector2(260, 0)
	_details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_box.add_child(_details)
	_quantity_box = HBoxContainer.new()
	detail_box.add_child(_quantity_box)
	var quantity_label := _label(14, Color(0.8, 0.78, 0.7))
	quantity_label.text = "Quantité"
	_quantity_box.add_child(quantity_label)
	_quantity = SpinBox.new()
	_quantity.min_value = 1
	_quantity.value = 1
	_quantity.value_changed.connect(_on_quantity_changed)
	_quantity_box.add_child(_quantity)
	_action_button = Button.new()
	_action_button.focus_mode = Control.FOCUS_NONE
	_action_button.pressed.connect(_on_action_pressed)
	detail_box.add_child(_action_button)
	_message = _label(14, Color(0.55, 0.9, 0.5))
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_box.add_child(_message)

	var hint := _label(12, Color(0.6, 0.58, 0.52))
	hint.text = "Revente : %d %% du prix d'achat · Les objets portés ne se vendent pas · Ctrl : jets possibles · Échap : fermer" % roundi(Item.RESALE_RATE * 100.0)
	column.add_child(hint)


func _tab_button(text: String, mode: String, group: ButtonGroup) -> Button:
	var button := Button.new()
	button.text = text
	button.toggle_mode = true
	button.button_group = group
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(120, 0)
	button.pressed.connect(_on_tab_pressed.bind(mode))
	return button


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
