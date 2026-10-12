class_name InventoryWindow
extends CanvasLayer
## Fenêtre d'inventaire (touche I) : emplacements d'équipement, objets, détail de l'objet choisi,
## boutons Équiper / Retirer / Jeter, écus.

const GOLD := Color(0.95, 0.76, 0.3)
const RARITY_COLORS := {
	"commun": Color(0.85, 0.85, 0.82), "peu_commun": Color(0.45, 0.85, 0.4), "rare": Color(0.4, 0.65, 1.0),
	"epique": Color(0.75, 0.45, 0.95), "legendaire": Color(1.0, 0.6, 0.2), "relique": Color(1.0, 0.85, 0.3),
}
const TYPE_NAMES := {
	"ressource": "Ressource", "arme": "Arme", "coiffe": "Coiffe", "cape": "Cape", "amulette": "Amulette",
	"anneau": "Anneau", "ceinture": "Ceinture", "bottes": "Bottes",
}

var map_view: MapView

var _panel: PanelContainer
var _slot_buttons := {}
var _list: ItemList
var _icon: TextureRect
var _details: Label
var _equip_button: Button
var _unequip_button: Button
var _drop_button: Button
var _coins: Label
var _overload: Label
var _sheet: Dictionary = {}
var _selected := ""


## Icône d'un objet (image `objet_<id>` de `art/art.json`, ou un sac « ? » à défaut).
static func item_icon(item_id: String) -> Texture2D:
	var image := "objet_" + item_id
	return Art.texture(image if Art.has_image(image) else "objet_inconnu")


## Liste d'objets en grille d'icônes, comme un sac (texte : la quantité).
static func make_bag_grid(list: ItemList) -> void:
	list.icon_mode = ItemList.ICON_MODE_TOP
	list.max_columns = 0
	list.same_column_width = true
	list.fixed_column_width = 52
	list.fixed_icon_size = Vector2i(40, 40)
	list.add_theme_font_size_override("font_size", 11)
	list.add_theme_constant_override("h_separation", 4)
	list.add_theme_constant_override("v_separation", 4)


## Ajoute un objet à une grille de sac : icône, quantité, fond de la couleur de sa rareté.
static func add_bag_item(list: ItemList, entry: Dictionary) -> int:
	var quantity := int(entry.get("quantite", 1))
	var worn := not str(entry.get("emplacement", "")).is_empty()
	var index := list.add_item("×%d" % quantity if quantity > 1 else "porté" if worn else " ", item_icon(entry["objet"]))
	var tint := GOLD if worn else rarity_color(entry["rarete"])
	list.set_item_custom_bg_color(index, Color(tint, 0.22 if worn else 0.1))
	list.set_item_tooltip(index, "%s%s%s" % [entry["nom"], " ×%d" % quantity if quantity > 1 else "", " (porté)" if worn else ""])
	list.set_item_metadata(index, entry["uid"])
	return index


static func rarity_color(rarity: String) -> Color:
	return RARITY_COLORS.get(rarity, RARITY_COLORS["commun"])


## Plages de bonus d'un modèle d'objet : « +2 à 5 Force ».
static func bonus_range_lines(bonus: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	for stat: String in bonus:
		var span: Array = bonus[stat]
		lines.append("+%d à %d %s" % [span[0], span[1], Item.stat_name(stat)] if int(span[0]) != int(span[1]) else "+%d %s" % [span[0], Item.stat_name(stat)])
	return lines


## Description de l'attaque d'une arme (vide pour les autres objets).
static func attack_lines(template: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	if template.has("attaque"):
		var attack := Spell.from_dict(Item.weapon_spell_data(template))
		for effect in attack.effects:
			if effect["type"] == Spell.EFFECT_DAMAGE:
				lines.append("Attaque : %d à %d (%s), %d PA, portée %d-%d" % [effect["min"], effect["max"], effect["element"], attack.pa_cost, attack.range_min, attack.range_max])
	return lines


func _ready() -> void:
	_build()
	_panel.visible = false


func setup(p_map_view: MapView) -> void:
	map_view = p_map_view
	map_view.inventory_changed.connect(refresh)
	map_view.combat_started.connect(func() -> void: _panel.visible = false)


func toggle() -> void:
	if map_view == null or map_view.mode == MapView.Mode.COMBAT:
		return
	_panel.visible = not _panel.visible
	refresh()


func is_open() -> bool:
	return _panel.visible


func refresh() -> void:
	if map_view == null or not _panel.visible:
		return
	var world := map_view.world
	_sheet = world.character.inventory_sheet(world.data)
	_coins.text = "%d écus   ·   %d / %d places" % [_sheet["ecus"], _sheet["objets"].size(), _sheet["places"]]
	var overloaded: bool = _sheet["objets"].size() > int(_sheet["places"])
	_coins.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35) if overloaded else GOLD)
	_overload.visible = overloaded
	var by_uid := {}
	for entry: Dictionary in _sheet["objets"]:
		by_uid[entry["uid"]] = entry
	for slot: String in _slot_buttons:
		var button: Button = _slot_buttons[slot]
		var uid: String = _sheet["equipement"].get(slot, "")
		if by_uid.has(uid):
			button.text = by_uid[uid]["nom"]
			button.icon = item_icon(by_uid[uid]["objet"])
			button.add_theme_color_override("font_color", rarity_color(by_uid[uid]["rarete"]))
		else:
			button.text = "—"
			button.icon = null
			button.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		button.set_meta("uid", uid)
	_list.clear()
	for entry: Dictionary in _sheet["objets"]:
		var index := add_bag_item(_list, entry)
		if entry["uid"] == _selected:
			_list.select(index)
	if not by_uid.has(_selected):
		_selected = ""
	_show_details(by_uid.get(_selected, {}))


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_I:
		toggle()
		get_viewport().set_input_as_handled()


func _on_item_selected(index: int) -> void:
	_selected = _list.get_item_metadata(index)
	refresh()


func _on_slot_pressed(slot: String) -> void:
	var uid: String = _slot_buttons[slot].get_meta("uid", "")
	if not uid.is_empty():
		_selected = uid
		refresh()


func _show_details(entry: Dictionary) -> void:
	_equip_button.disabled = true
	_unequip_button.disabled = true
	_drop_button.disabled = entry.is_empty()
	_icon.texture = null if entry.is_empty() else item_icon(entry["objet"])
	if entry.is_empty():
		_details.text = "Choisissez un objet."
		return
	var lines: PackedStringArray = [
		"%s — %s" % [entry["nom"], Item.RARITY_NAMES.get(entry["rarete"], "")],
		"%s, niveau %d" % [TYPE_NAMES.get(entry["type"], entry["type"]), entry["niveau"]],
	]
	for stat: String in entry["jets"]:
		lines.append("+%d %s" % [entry["jets"][stat], Item.stat_name(stat)])
	for stat: String in entry["conditions"]:
		lines.append("Condition : %s ≥ %d" % [Item.stat_name(stat), entry["conditions"][stat]])
	lines.append_array(attack_lines(map_view.world.data.items.get(entry["objet"], {})))
	if not str(entry["description"]).is_empty():
		lines.append("")
		lines.append(entry["description"])
	_details.text = "\n".join(lines)
	var worn := not str(entry["emplacement"]).is_empty()
	_equip_button.disabled = worn or not Item.SLOTS_BY_TYPE.has(entry["type"])
	_unequip_button.disabled = not worn


func _on_equip_pressed() -> void:
	map_view.send_command({"type": Protocol.CMD_EQUIP, "entite": World.PLAYER_ID, "objet": _selected})


func _on_unequip_pressed() -> void:
	var slot := map_view.world.character.inventory.slot_of(_selected)
	if not slot.is_empty():
		map_view.send_command({"type": Protocol.CMD_UNEQUIP, "entite": World.PLAYER_ID, "emplacement": slot})


func _on_drop_pressed() -> void:
	if _selected.is_empty():
		return
	var quantity := int(map_view.world.character.inventory.entries[_selected]["quantite"])
	map_view.send_command({"type": Protocol.CMD_DROP, "entite": World.PLAYER_ID, "objet": _selected, "quantite": quantity})


# --- Construction des contrôles ----------------------------------------------------------------

func _build() -> void:
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.offset_left = -450
	_panel.offset_right = 450
	_panel.offset_top = 70
	_panel.offset_bottom = 560
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.1, 0.07, 0.96)
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
	title.text = "Inventaire"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_coins = _label(15, GOLD)
	header.add_child(_coins)
	var close := Button.new()
	close.text = "×"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(toggle)
	header.add_child(close)

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)
	column.add_child(row)

	var slots := GridContainer.new()
	slots.columns = 2
	slots.custom_minimum_size = Vector2(250, 0)
	row.add_child(slots)
	for slot: String in Inventory.SLOTS:
		var name_label := _label(14, Color(0.8, 0.78, 0.7))
		name_label.text = Item.SLOT_NAMES[slot]
		var button := Button.new()
		button.custom_minimum_size = Vector2(170, 40)
		button.focus_mode = Control.FOCUS_NONE
		button.clip_text = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_constant_override("icon_max_width", 32)
		button.pressed.connect(_on_slot_pressed.bind(slot))
		slots.add_child(name_label)
		slots.add_child(button)
		_slot_buttons[slot] = button

	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(340, 0)
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	make_bag_grid(_list)
	_list.item_selected.connect(_on_item_selected)
	row.add_child(_list)

	var detail_box := VBoxContainer.new()
	detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(detail_box)
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(64, 64)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	detail_box.add_child(_icon)
	_details = _label(14, Color(0.92, 0.9, 0.85))
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.custom_minimum_size = Vector2(220, 0)
	_details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_box.add_child(_details)
	var buttons := HBoxContainer.new()
	detail_box.add_child(buttons)
	_equip_button = _action_button("Équiper", _on_equip_pressed)
	_unequip_button = _action_button("Retirer", _on_unequip_pressed)
	_drop_button = _action_button("Jeter", _on_drop_pressed)
	for button in [_equip_button, _unequip_button, _drop_button]:
		buttons.add_child(button)
	_overload = _label(14, Color(1.0, 0.55, 0.4))
	_overload.text = CombatHud.OVERLOAD_TEXT
	_overload.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_overload.visible = false
	column.add_child(_overload)
	var hint := _label(12, Color(0.6, 0.58, 0.52))
	hint.text = "Touche I : ouvrir / fermer"
	column.add_child(hint)


func _action_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	return button


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
