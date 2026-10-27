class_name InventoryWindow
extends CanvasLayer
## Fenêtre d'inventaire (touche I) : emplacements d'équipement, objets, détail de l'objet choisi,
## boutons Équiper / Retirer / Jeter, brumes. Un double-clic équipe un objet du sac (ou retire un objet
## porté) ; on peut aussi glisser un objet du sac sur un emplacement, ou d'un emplacement vers le sac.
## Le sac a trois onglets : Équipements, Consommables, Ressources (objets de quête compris).

const GOLD := Color(0.95, 0.76, 0.3)
const RARITY_COLORS := {
	"commun": Color(0.85, 0.85, 0.82), "peu_commun": Color(0.45, 0.85, 0.4), "rare": Color(0.4, 0.65, 1.0),
	"epique": Color(0.75, 0.45, 0.95), "legendaire": Color(1.0, 0.6, 0.2), "relique": Color(1.0, 0.85, 0.3),
}
const TYPE_NAMES := {
	"ressource": "Ressource", "arme": "Arme", "coiffe": "Coiffe", "cape": "Cape", "amulette": "Amulette",
	"anneau": "Anneau", "ceinture": "Ceinture", "bottes": "Bottes",
}

## Onglets du sac, dans l'ordre de la barre.
enum BagTab { EQUIPMENT, CONSUMABLES, RESOURCES }
const BAG_TAB_NAMES := ["Équipements", "Consommables", "Ressources"]

var map_view: MapView

var _panel: PanelContainer
var _slot_buttons := {}
## Cases des Reliques (vides tant qu'aucune n'a été reprise).
var _relic_slots: Array[Control] = []
var _list: ItemTooltipList
var _bag_tabs: TabBar
var _icon: TextureRect
var _details: Label
var _equip_button: Button
var _unequip_button: Button
var _drop_button: Button
var _coins: Label
var _overload: Label
var _sheet: Dictionary = {}
## Ctrl enfoncé : on montre les jets possibles plutôt que ceux de l'objet.
var _show_ranges := false
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


## Ajoute un objet à une grille de sac : icône, quantité, fond de la couleur de sa rareté, et
## infobulle (`tooltip`, son nom par défaut).
static func add_bag_item(list: ItemList, entry: Dictionary, tooltip := "") -> int:
	var quantity := int(entry.get("quantite", 1))
	var worn := not str(entry.get("emplacement", "")).is_empty()
	var index := list.add_item("×%d" % quantity if quantity > 1 else "porté" if worn else " ", item_icon(entry["objet"]))
	var tint := GOLD if worn else rarity_color(entry["rarete"])
	list.set_item_custom_bg_color(index, Color(tint, 0.22 if worn else 0.1))
	list.set_item_tooltip(index, tooltip if not tooltip.is_empty()
		else "%s%s%s" % [entry["nom"], " ×%d" % quantity if quantity > 1 else "", " (porté)" if worn else ""])
	list.set_item_metadata(index, entry["uid"])
	return index


## Onglet du sac où ranger un objet de ce type : équipements, ressources (et objets de quête),
## consommables pour tout le reste (potions, pains…).
static func bag_tab(item_type: String) -> BagTab:
	if Item.SLOTS_BY_TYPE.has(item_type):
		return BagTab.EQUIPMENT
	if item_type == Item.TYPE_RESOURCE or item_type == Item.TYPE_QUEST:
		return BagTab.RESOURCES
	return BagTab.CONSUMABLES


static func rarity_color(rarity: String) -> Color:
	return RARITY_COLORS.get(rarity, RARITY_COLORS["commun"])


## Plages de bonus d'un modèle d'objet : « +2 à 5 Force ».
static func bonus_range_lines(bonus: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	for stat: String in bonus:
		var span: Array = bonus[stat]
		lines.append("+%d à %d %s" % [span[0], span[1], Item.stat_name(stat)] if int(span[0]) != int(span[1]) else "+%d %s" % [span[0], Item.stat_name(stat)])
	return lines


## Bonus d'un objet : ses jets (« +3 Force »), ou les jets possibles de son modèle quand on tient
## Ctrl (`show_ranges`). Les objets sans bonus n'affichent rien.
static func roll_lines(entry: Dictionary, template: Dictionary, show_ranges: bool) -> PackedStringArray:
	var bonus: Dictionary = template.get("bonus", {})
	var lines: PackedStringArray = []
	if show_ranges and not bonus.is_empty():
		lines.append("Jets possibles :")
		for line in bonus_range_lines(bonus):
			lines.append("  " + line)
		return lines
	var rolls: Dictionary = entry.get("jets", {})
	for stat: String in rolls:
		lines.append("+%d %s" % [rolls[stat], Item.stat_name(stat)])
	return lines


## Panoplie d'un objet : son nom, les pièces portées, et chaque palier de bonus (« (actif) » pour
## celui qui s'applique). Vide si l'objet n'est d'aucune panoplie.
static func set_lines(item_id: String, data: GameData, inventory: Inventory) -> PackedStringArray:
	var lines: PackedStringArray = []
	if data == null or not data.item_sets.has(item_id):
		return lines
	var set_id: String = data.item_sets[item_id]
	var panoply: Dictionary = data.sets[set_id]
	var worn := int(data.worn_sets(inventory).get(set_id, 0))
	var active := data.set_tier(set_id, worn)
	lines.append("")
	lines.append("%s — %d / %d" % [panoply["nom"], worn, panoply["objets"].size()])
	var counts: Array = panoply["bonus"].keys()
	counts.sort_custom(func(a: Variant, b: Variant) -> bool: return int(str(a)) < int(str(b)))
	for count: Variant in counts:
		var tier: Dictionary = panoply["bonus"][count]
		var parts: PackedStringArray = []
		for stat: String in tier:
			parts.append("+%d %s" % [tier[stat], Item.stat_name(stat)])
		lines.append("%s %s : %s" % ["»" if tier == active and not active.is_empty() else "  ", str(count), ", ".join(parts)])
	return lines


## Vrai si la touche Ctrl vient d'être enfoncée ou relâchée (pour afficher les jets possibles).
static func is_ctrl_event(event: InputEvent) -> bool:
	var key := event as InputEventKey
	return key != null and not key.echo and key.keycode == KEY_CTRL


## Description de l'attaque d'une arme (vide pour les autres objets).
static func attack_lines(template: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	if template.has("attaque"):
		var attack := Spell.from_dict(Item.weapon_spell_data(template))
		for effect in attack.effects:
			if effect["type"] == Spell.EFFECT_DAMAGE:
				lines.append("Attaque : %d à %d (%s), %d PA, portée %d-%d" % [effect["min"], effect["max"],
					SpellsWindow.ELEMENT_NAMES.get(effect["element"], effect["element"]), attack.pa_cost, attack.range_min, attack.range_max])
	return lines


func _ready() -> void:
	_build()
	_panel.visible = false


func setup(p_map_view: MapView) -> void:
	map_view = p_map_view
	map_view.inventory_changed.connect(refresh)
	map_view.combat_started.connect(refresh)
	map_view.exploration_resumed.connect(refresh)


## En combat, l'inventaire se consulte sans se modifier (GDD § 16.5, M2).
func toggle() -> void:
	if map_view == null:
		return
	_panel.visible = not _panel.visible
	refresh()


func is_read_only() -> bool:
	return map_view != null and map_view.mode == MapView.Mode.COMBAT


func is_open() -> bool:
	return _panel.visible


func refresh() -> void:
	if map_view == null or not _panel.visible:
		return
	var world := map_view.world
	_sheet = world.character.inventory_sheet(world.data)
	_coins.text = "%d brumes   ·   %d / %d places" % [_sheet["ecus"], _sheet["objets"].size(), _sheet["places"]]
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
	var counts := [0, 0, 0]
	for entry: Dictionary in _sheet["objets"]:
		counts[bag_tab(entry["type"])] += 1
	for tab in BAG_TAB_NAMES.size():
		_bag_tabs.set_tab_title(tab, "%s (%d)" % [BAG_TAB_NAMES[tab], counts[tab]] if counts[tab] > 0 else BAG_TAB_NAMES[tab])
	for entry: Dictionary in _sheet["objets"]:
		if bag_tab(entry["type"]) != _bag_tabs.current_tab:
			continue
		var index := add_bag_item(_list, entry, ItemTooltipList.tooltip_text_for(entry, world.data, world.character.inventory, _show_ranges))
		if entry["uid"] == _selected:
			_list.select(index)
	if not by_uid.has(_selected):
		_selected = ""
	_show_details(by_uid.get(_selected, {}))


func _input(event: InputEvent) -> void:
	if is_ctrl_event(event) and _panel.visible:
		set_show_ranges(event.is_pressed())


## Jets possibles (Ctrl enfoncé) ou jets de l'objet.
func set_show_ranges(shown: bool) -> void:
	if shown != _show_ranges:
		_show_ranges = shown
		refresh()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_I:
		toggle()
		get_viewport().set_input_as_handled()


## Affiche l'onglet `tab` du sac (`BagTab`).
func show_bag_tab(tab: int) -> void:
	if _bag_tabs.current_tab != tab:
		_bag_tabs.current_tab = tab
	refresh()


func _on_item_selected(index: int) -> void:
	_selected = _list.get_item_metadata(index)
	refresh()


## Double-clic dans le sac : équiper l'objet, ou le retirer s'il est déjà porté.
func _on_item_activated(index: int) -> void:
	_selected = _list.get_item_metadata(index)
	toggle_worn(_selected)


## Équipe l'objet `uid` (premier emplacement libre) ou le retire s'il est porté ; rien pour un
## objet qui ne s'équipe pas.
func toggle_worn(uid: String) -> void:
	var inventory := map_view.world.character.inventory
	if not inventory.entries.has(uid) or is_read_only():
		return
	var slot := inventory.slot_of(uid)
	if not slot.is_empty():
		map_view.send_command({"type": Protocol.CMD_UNEQUIP, "entite": map_view.world.player_id, "emplacement": slot})
	elif Item.is_equipment(map_view.world.data.items.get(inventory.entries[uid]["objet"], {})):
		map_view.send_command({"type": Protocol.CMD_EQUIP, "entite": map_view.world.player_id, "objet": uid})


func _on_slot_input(event: InputEvent, slot: String) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.double_click and click.button_index == MOUSE_BUTTON_LEFT:
		var uid: String = _slot_buttons[slot].get_meta("uid", "")
		if not uid.is_empty():
			toggle_worn(uid)


# --- Glisser-déposer : { "objet": uid, "emplacement": slot d'origine ou "" } -------------------

func _bag_drag_data(at_position: Vector2) -> Variant:
	var index := _list.get_item_at_position(at_position, true)
	if index < 0 or is_read_only():
		return null
	var uid: String = _list.get_item_metadata(index)
	_list.set_drag_preview(_drag_preview(uid))
	return {"objet": uid, "emplacement": map_view.world.character.inventory.slot_of(uid)}


func _slot_drag_data(_at_position: Vector2, slot: String) -> Variant:
	var uid: String = _slot_buttons[slot].get_meta("uid", "")
	if uid.is_empty() or is_read_only():
		return null
	_slot_buttons[slot].set_drag_preview(_drag_preview(uid))
	return {"objet": uid, "emplacement": slot}


## Vrai si l'objet glissé peut aller dans `slot` (bon type d'objet).
func can_drop_on_slot(dragged: Variant, slot: String) -> bool:
	if typeof(dragged) != TYPE_DICTIONARY or not dragged.has("objet"):
		return false
	var inventory := map_view.world.character.inventory
	if not inventory.entries.has(dragged["objet"]) or dragged.get("emplacement", "") == slot:
		return false
	var template: Dictionary = map_view.world.data.items.get(inventory.entries[dragged["objet"]]["objet"], {})
	return slot in Item.SLOTS_BY_TYPE.get(template.get("type", ""), [])


func drop_on_slot(dragged: Variant, slot: String) -> void:
	if can_drop_on_slot(dragged, slot):
		_selected = dragged["objet"]
		map_view.send_command({"type": Protocol.CMD_EQUIP, "entite": map_view.world.player_id, "objet": dragged["objet"], "emplacement": slot})


## Un objet porté lâché sur le sac est retiré.
func _can_drop_on_bag(_at_position: Vector2, dragged: Variant) -> bool:
	return typeof(dragged) == TYPE_DICTIONARY and not str(dragged.get("emplacement", "")).is_empty()


func _drop_on_bag(_at_position: Vector2, dragged: Variant) -> void:
	if _can_drop_on_bag(_at_position, dragged):
		map_view.send_command({"type": Protocol.CMD_UNEQUIP, "entite": map_view.world.player_id, "emplacement": dragged["emplacement"]})


func _drag_preview(uid: String) -> Control:
	var preview := TextureRect.new()
	preview.texture = item_icon(map_view.world.character.inventory.entries[uid]["objet"])
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.size = Vector2(40, 40)
	preview.position = Vector2(-20, -20)
	preview.modulate = Color(1, 1, 1, 0.85)
	var holder := Control.new()
	holder.add_child(preview)
	return holder


func _on_slot_pressed(slot: String) -> void:
	var uid: String = _slot_buttons[slot].get_meta("uid", "")
	if not uid.is_empty():
		_selected = uid
		show_bag_tab(BagTab.EQUIPMENT)


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
	var template: Dictionary = map_view.world.data.items.get(entry["objet"], {})
	lines.append_array(roll_lines(entry, template, _show_ranges))
	for stat: String in entry["conditions"]:
		lines.append("Condition : %s ≥ %d" % [Item.stat_name(stat), entry["conditions"][stat]])
	lines.append_array(attack_lines(template))
	lines.append_array(set_lines(entry["objet"], map_view.world.data, map_view.world.character.inventory))
	if not str(entry["description"]).is_empty():
		lines.append("")
		lines.append(entry["description"])
	_details.text = "\n".join(lines)
	var worn := not str(entry["emplacement"]).is_empty()
	_equip_button.disabled = worn or not Item.SLOTS_BY_TYPE.has(entry["type"]) or is_read_only()
	_unequip_button.disabled = not worn or is_read_only()
	_drop_button.disabled = is_read_only()


func _on_equip_pressed() -> void:
	map_view.send_command({"type": Protocol.CMD_EQUIP, "entite": map_view.world.player_id, "objet": _selected})


func _on_unequip_pressed() -> void:
	var slot := map_view.world.character.inventory.slot_of(_selected)
	if not slot.is_empty():
		map_view.send_command({"type": Protocol.CMD_UNEQUIP, "entite": map_view.world.player_id, "emplacement": slot})


func _on_drop_pressed() -> void:
	if _selected.is_empty():
		return
	var quantity := int(map_view.world.character.inventory.entries[_selected]["quantite"])
	map_view.send_command({"type": Protocol.CMD_DROP, "entite": map_view.world.player_id, "objet": _selected, "quantite": quantity})


# --- Construction des contrôles ----------------------------------------------------------------

func _build() -> void:
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.offset_left = -450
	_panel.offset_right = 450
	_panel.offset_top = 66
	_panel.offset_bottom = 612
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

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	row.add_child(left)
	var slots := GridContainer.new()
	slots.columns = 2
	slots.custom_minimum_size = Vector2(250, 0)
	left.add_child(slots)
	for slot: String in Inventory.SLOTS:
		var name_label := _label(14, Color(0.8, 0.78, 0.7))
		name_label.text = Item.SLOT_NAMES[slot]
		var button := Button.new()
		button.custom_minimum_size = Vector2(170, 36)
		button.focus_mode = Control.FOCUS_NONE
		button.clip_text = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_constant_override("icon_max_width", 32)
		button.pressed.connect(_on_slot_pressed.bind(slot))
		button.gui_input.connect(_on_slot_input.bind(slot))
		button.set_drag_forwarding(_slot_drag_data.bind(slot),
			func(_at: Vector2, dragged: Variant) -> bool: return can_drop_on_slot(dragged, slot),
			func(_at: Vector2, dragged: Variant) -> void: drop_on_slot(dragged, slot))
		slots.add_child(name_label)
		slots.add_child(button)
		_slot_buttons[slot] = button

	var relic_title := _label(15, GOLD)
	relic_title.text = "Reliques"
	relic_title.tooltip_text = "Les huit Reliques de l'Aube, des bagues que portent les Hérauts du Souverain Cendré. Elles s'équipent toutes en même temps, en plus des deux anneaux."
	relic_title.mouse_filter = Control.MOUSE_FILTER_PASS
	left.add_child(relic_title)
	var relics := GridContainer.new()
	relics.columns = 4
	relics.add_theme_constant_override("h_separation", 6)
	relics.add_theme_constant_override("v_separation", 6)
	left.add_child(relics)
	for i in Inventory.RELIC_SLOT_COUNT:
		var relic := _relic_slot(i + 1)
		relics.add_child(relic)
		_relic_slots.append(relic)

	var bag := VBoxContainer.new()
	bag.add_theme_constant_override("separation", 4)
	row.add_child(bag)
	_bag_tabs = TabBar.new()
	_bag_tabs.focus_mode = Control.FOCUS_NONE
	_bag_tabs.clip_tabs = false
	for tab_name: String in BAG_TAB_NAMES:
		_bag_tabs.add_tab(tab_name)
	_bag_tabs.tab_changed.connect(func(_tab: int) -> void: refresh())
	bag.add_child(_bag_tabs)
	_list = ItemTooltipList.new()
	_list.custom_minimum_size = Vector2(340, 0)
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	make_bag_grid(_list)
	_list.item_selected.connect(_on_item_selected)
	_list.item_activated.connect(_on_item_activated)
	_list.set_drag_forwarding(_bag_drag_data, _can_drop_on_bag, _drop_on_bag)
	bag.add_child(_list)

	var detail_box := VBoxContainer.new()
	detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(detail_box)
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(64, 64)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	detail_box.add_child(_icon)
	# Le détail défile s'il est long (panoplie complète) : la fenêtre garde sa taille.
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(230, 0)
	detail_box.add_child(scroll)
	_details = _label(13, Color(0.92, 0.9, 0.85))
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_details)
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
	hint.text = "Touche I : ouvrir / fermer · Double-clic ou glisser : équiper / retirer · Ctrl : jets possibles"
	column.add_child(hint)


## Case de Relique vide : silhouette de bague, numéro, infobulle.
func _relic_slot(number: int) -> Control:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(44, 44)
	slot.tooltip_text = "Relique %d : pas encore reprise" % number
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.04, 0.9)
	style.border_color = Color(0.55, 0.42, 0.22, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(4)
	slot.add_theme_stylebox_override("panel", style)
	var silhouette := TextureRect.new()
	silhouette.texture = item_icon("anneau_du_frondeur")
	silhouette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	silhouette.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	silhouette.modulate = Color(0, 0, 0, 0.45)
	silhouette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(silhouette)
	var label := _label(11, Color(0.75, 0.62, 0.35))
	label.text = str(number)
	label.size_flags_horizontal = Control.SIZE_SHRINK_END
	label.size_flags_vertical = Control.SIZE_SHRINK_END
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(label)
	return slot


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
