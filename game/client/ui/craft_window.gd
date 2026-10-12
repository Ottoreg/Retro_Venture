class_name CraftWindow
extends CanvasLayer
## Atelier d'un artisan (forgeron…) : recettes du métier, ingrédients possédés, fabrication.
## S'ouvre quand on parle à un PNJ qui tient un atelier.

const GOLD := Color(0.95, 0.76, 0.3)
const LOCKED := Color(0.5, 0.5, 0.5)

var map_view: MapView

var _refusal_texts := {
	Protocol.REASON_MISSING_INGREDIENTS: "Il manque des ingrédients.",
	Protocol.REASON_JOB_LEVEL: "Niveau de métier insuffisant.",
	Protocol.REASON_INVENTORY_FULL: "Inventaire plein.",
	Protocol.REASON_TOO_FAR: "L'artisan est trop loin.",
}
var _backdrop: ColorRect
var _panel: PanelContainer
var _title: Label
var _job_label: Label
var _job_bar: ProgressBar
var _greeting: Label
var _list: ItemList
var _details: Label
var _quantity_box: HBoxContainer
var _quantity: SpinBox
var _craft_button: Button
var _message: Label
var _workshop: Dictionary = {}
## Recette choisie : id de l'objet fabriqué.
var _selected := ""


func _ready() -> void:
	_build()
	_set_visible(false)


func setup(p_map_view: MapView) -> void:
	map_view = p_map_view
	map_view.workshop_opened.connect(open)
	map_view.craft_result.connect(_on_craft_result)
	map_view.inventory_changed.connect(refresh)
	map_view.combat_started.connect(close)
	map_view.map_changed.connect(close)


func open(event: Dictionary) -> void:
	_workshop = event
	_selected = ""
	_title.text = event["nom"]
	var lines: Array = event["repliques"]
	_greeting.text = "« %s »" % lines[0] if not lines.is_empty() else ""
	_message.text = ""
	_set_visible(true)
	refresh()


func close() -> void:
	_set_visible(false)


func is_open() -> bool:
	return _panel.visible


func refresh() -> void:
	if map_view == null or not is_open():
		return
	var character := map_view.world.character
	var job_id: String = _workshop["metier"]
	var level := character.job_level(job_id)
	var xp := character.job_xp(job_id)
	var floor_xp := Profession.xp_for_level(level)
	var next_xp := Profession.xp_for_level(level + 1) if level < Profession.MAX_LEVEL else xp
	_job_label.text = "%s niveau %d — %d / %d XP" % [_workshop["nom_metier"], level, xp, next_xp]
	_job_bar.value = 100.0 * (xp - floor_xp) / maxi(1, next_xp - floor_xp)
	_list.clear()
	var found := false
	for recipe: Dictionary in _workshop["recettes"]:
		var label := "%s   (niv. %d)" % [recipe["nom"], recipe["niveau"]]
		var color := InventoryWindow.rarity_color(recipe["rarete"])
		if level < int(recipe["niveau"]):
			color = LOCKED
		elif _max_crafts(recipe) > 0:
			label += "   — prêt"
		else:
			color = color.darkened(0.35)
		var index := _list.add_item(label, InventoryWindow.item_icon(recipe["objet"]))
		_list.set_item_custom_fg_color(index, color)
		_list.set_item_metadata(index, recipe["objet"])
		if recipe["objet"] == _selected:
			_list.select(index)
			found = true
	if not found:
		_selected = ""
	_show_details(_selected_recipe())


func _selected_recipe() -> Dictionary:
	for recipe: Dictionary in _workshop.get("recettes", []):
		if recipe["objet"] == _selected:
			return recipe
	return {}


## Nombre d'exemplaires qu'on peut fabriquer avec les ingrédients de l'inventaire.
func _max_crafts(recipe: Dictionary) -> int:
	var inventory := map_view.world.character.inventory
	var count := World.MAX_TRADE_QUANTITY
	for ingredient: Dictionary in recipe["ingredients"]:
		count = mini(count, floori(float(inventory.quantity_of(ingredient["objet"])) / int(ingredient["quantite"])))
	return count


func _show_details(recipe: Dictionary) -> void:
	if recipe.is_empty():
		_details.text = "Choisissez une recette."
		_quantity_box.visible = false
		_craft_button.disabled = true
		_craft_button.text = "Fabriquer"
		return
	var inventory := map_view.world.character.inventory
	var lines: PackedStringArray = [
		"%s — %s" % [recipe["nom"], Item.RARITY_NAMES.get(recipe["rarete"], "")],
		"%s, niveau %d" % [InventoryWindow.TYPE_NAMES.get(recipe["type"], recipe["type"]), recipe["niveau_objet"]],
	]
	lines.append_array(InventoryWindow.bonus_range_lines(recipe["bonus"]))
	for stat: String in recipe["conditions"]:
		lines.append("Condition : %s ≥ %d" % [Item.stat_name(stat), recipe["conditions"][stat]])
	lines.append_array(InventoryWindow.attack_lines(map_view.world.data.items.get(recipe["objet"], {})))
	lines.append("")
	lines.append("Ingrédients :")
	for ingredient: Dictionary in recipe["ingredients"]:
		lines.append("  • %s : %d / %d" % [ingredient["nom"], inventory.quantity_of(ingredient["objet"]), ingredient["quantite"]])
	lines.append("")
	lines.append("%s niveau %d requis · +%d XP" % [_workshop["nom_metier"], recipe["niveau"], recipe["xp"]])
	_details.text = "\n".join(lines)

	var level_ok: bool = map_view.world.character.job_level(_workshop["metier"]) >= int(recipe["niveau"])
	var max_crafts := _max_crafts(recipe)
	_quantity.max_value = maxi(1, max_crafts)
	_quantity_box.visible = level_ok and max_crafts > 1
	_craft_button.disabled = not level_ok or max_crafts == 0
	_craft_button.text = "Fabriquer" if level_ok else "Niveau %d requis" % recipe["niveau"]


func _on_item_selected(index: int) -> void:
	_selected = _list.get_item_metadata(index)
	_quantity.value = 1
	refresh()


func _on_craft_pressed() -> void:
	if _selected.is_empty():
		return
	map_view.send_command({
		"type": Protocol.CMD_CRAFT,
		"entite": World.PLAYER_ID,
		"pnj": _workshop["pnj"],
		"recette": _selected,
		"quantite": int(_quantity.value) if _quantity_box.visible else 1,
	})


func _on_craft_result(event: Dictionary) -> void:
	if event["type"] == Protocol.EVT_REFUSED:
		_message.text = _refusal_texts.get(event["raison"], "Impossible.")
		_message.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4))
		return
	var amount := " ×%d" % event["quantite"] if int(event["quantite"]) > 1 else ""
	_message.text = "Fabriqué : %s%s" % [event["nom"], amount]
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
	_panel.offset_bottom = 600
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
	_job_label = _label(15, GOLD)
	header.add_child(_job_label)
	var close_button := Button.new()
	close_button.text = "×"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(close)
	header.add_child(close_button)
	_job_bar = ProgressBar.new()
	_job_bar.show_percentage = false
	_job_bar.custom_minimum_size = Vector2(0, 8)
	column.add_child(_job_bar)

	_greeting = _label(14, Color(0.85, 0.82, 0.72))
	_greeting.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_greeting)

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)
	column.add_child(row)
	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(360, 0)
	_list.fixed_icon_size = Vector2i(28, 28)
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_on_item_selected)
	row.add_child(_list)

	var detail_box := VBoxContainer.new()
	detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(detail_box)
	_details = _label(14, Color(0.92, 0.9, 0.85))
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.custom_minimum_size = Vector2(280, 0)
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
	_quantity_box.add_child(_quantity)
	_craft_button = Button.new()
	_craft_button.focus_mode = Control.FOCUS_NONE
	_craft_button.pressed.connect(_on_craft_pressed)
	detail_box.add_child(_craft_button)
	_message = _label(14, Color(0.55, 0.9, 0.5))
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_box.add_child(_message)

	var hint := _label(12, Color(0.6, 0.58, 0.52))
	hint.text = "« prêt » : ingrédients réunis · Les ressources se récoltent (bûcheron, mineur) ou s'achètent chez le marchand · Échap : fermer"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(hint)


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
