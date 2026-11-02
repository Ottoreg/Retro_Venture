class_name ForgeWindow
extends CanvasLayer
## Forge à l'enclume de la maison (`Forge`) : type d'objet, ressources du sac (ou un plan), aperçu de
## l'objet (lignes, jets possibles, palier), nom fait de mots proposés, puis forge.

const GOLD := Color(0.95, 0.76, 0.3)
const REFUSALS := {
	Protocol.REASON_MISSING_INGREDIENTS: "Il manque des ressources.",
	Protocol.REASON_INVENTORY_FULL: "Inventaire plein.",
	Protocol.REASON_TOO_FAR: "L'enclume est trop loin.",
}

var map_view: MapView
var _anvil := Vector2i.ZERO
var _type := "coiffe"
## Ressources posées sur l'enclume : id → quantité.
var _chosen := {}
## Plan choisi (id), ou "".
var _plan := ""
var _backdrop: ColorRect
var _panel: PanelContainer
var _job_label: Label
var _types: OptionButton
var _plans: ItemList
var _bag: ItemList
var _placed: ItemList
var _preview: Label
var _words: Array[OptionButton] = []
var _forge_button: Button
var _message: Label


## Lignes de forge d'un modèle pour ses infobulles : caractéristique et matière d'une ressource
## (cachée sans la réputation d'artisan), contenu d'un plan.
static func forge_lines(template: Dictionary, data: GameData, character: Character) -> PackedStringArray:
	var lines: PackedStringArray = []
	if template.has("caracteristique") and character != null:
		var tier := int(template.get("niveau", 1))
		lines.append("Forge : %s" % ("+%d %s" % [Forge.value(template["caracteristique"], tier), Item.stat_name(template["caracteristique"])]
			if Forge.reveals(character, tier) else "caractéristique inconnue (forgeron de palier %d requis)" % tier))
	if template.has("matiere"):
		lines.append("Matière : %s" % template["matiere"])
	var plan: Dictionary = template.get("recette", {})
	if not plan.is_empty() and data != null:
		lines.append("%s : %s" % [Forge.TYPE_NAMES[plan["type"]], plan["nom"]])
		for item_id: String in plan["ressources"]:
			lines.append("  • %d %s" % [plan["ressources"][item_id], data.items.get(item_id, {}).get("nom", item_id)])
		for line in InventoryWindow.bonus_range_lines(Forge.preview(plan["type"], plan["ressources"], data.items)["bonus"]):
			lines.append("  " + line)
	return lines


func _ready() -> void:
	_build()
	_set_visible(false)


func setup(p_map_view: MapView) -> void:
	map_view = p_map_view
	map_view.anvil_opened.connect(open)
	map_view.craft_result.connect(_on_result)
	map_view.inventory_changed.connect(refresh)
	map_view.combat_started.connect(close)
	map_view.map_changed.connect(close)


func open(event: Dictionary) -> void:
	_anvil = event["case"]
	_chosen = {}
	_plan = ""
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
	var world := map_view.world
	var character := world.character
	_job_label.text = "Forgeron niveau %d" % character.job_level(Forge.JOB)
	_types.select(Forge.TYPES.keys().find(_type))
	_plans.clear()
	_bag.clear()
	_placed.clear()
	for entry: Dictionary in character.inventory_sheet(world.data)["objets"]:
		var template: Dictionary = world.data.items.get(entry["objet"], {})
		if template.has("recette"):
			_plans.set_item_metadata(_plans.add_item(template["recette"]["nom"], InventoryWindow.item_icon(entry["objet"])), entry["objet"])
		var left := int(entry["quantite"]) - int(_chosen.get(entry["objet"], 0))
		if template.get("type") == Item.TYPE_RESOURCE and (template.has("caracteristique") or template.has("matiere")) and left > 0:
			var index := _bag.add_item("%s ×%d" % [entry["nom"], left], InventoryWindow.item_icon(entry["objet"]))
			_bag.set_item_tooltip(index, "\n".join(forge_lines(template, world.data, character)))
			_bag.set_item_metadata(index, entry["objet"])
	for item_id: String in _chosen:
		var index := _placed.add_item("%s ×%d" % [world.data.items[item_id]["nom"], _chosen[item_id]], InventoryWindow.item_icon(item_id))
		_placed.set_item_metadata(index, item_id)
	_show_preview()


func _show_preview() -> void:
	var data := map_view.world.data
	var plan: Dictionary = data.items.get(_plan, {}).get("recette", {})
	var preview := Forge.preview(_type, _chosen, data.items, null if not plan.is_empty() else map_view.world.character)
	_update_words(preview["bonus"], plan)
	var lines: PackedStringArray = ["%s, palier %d" % [Forge.TYPE_NAMES[_type], preview["palier"]]]
	lines.append_array(InventoryWindow.bonus_range_lines(preview["bonus"]))
	lines.append_array(InventoryWindow.attack_lines(Item.entry_template({"objet": Forge.template_id(_type),
		"forge": {"nom": "", "artisan": "", "palier": preview["palier"], "bonus": {}}}, data.items)))
	if preview["cachees"] > 0:
		lines.append("+ %d ressource(s) à la caractéristique inconnue" % preview["cachees"])
	var count := 0
	for item_id: String in _chosen:
		count += int(_chosen[item_id])
	lines.append("")
	lines.append("Ressources : %d / %d · matières : %s" % [count, Forge.MAX_RESOURCES,
		", ".join(PackedStringArray(Forge.TYPES[_type]["matieres"]))])
	if not preview["manquantes"].is_empty():
		lines.append("Manque : %s" % ", ".join(PackedStringArray(preview["manquantes"])))
	if count > Forge.MAX_RESOURCES:
		lines.append("Trop de ressources.")
	lines.append("Nom : %s" % _name())
	_preview.text = "\n".join(lines)
	_forge_button.disabled = not preview["erreur"].is_empty() or not _owns_all()


## Choix du nom : le nom du type puis deux adjectifs des lignes de l'objet (un plan impose son nom).
func _update_words(bonus: Dictionary, plan: Dictionary) -> void:
	var noun: String = _words[0].get_item_text(_words[0].selected) if _words[0].selected >= 0 else ""
	var wanted := Forge.default_words(_type, bonus)
	if Forge.gender(_type, noun).is_empty():
		noun = wanted[0]
	var previous: Array = _words.slice(1).map(func(option: OptionButton) -> String:
		return option.get_item_text(option.selected) if option.selected > 0 else "")
	_words[0].clear()
	for entry: Array in Forge.TYPES[_type]["noms"]:
		_words[0].add_item(entry[0])
		if entry[0] == noun:
			_words[0].select(_words[0].item_count - 1)
	for i in range(1, _words.size()):
		var option := _words[i]
		option.clear()
		option.add_item("—")
		for stat: String in bonus:
			for forms: Array in Forge.WORDS[stat]:
				option.add_item(Forge.adjective(forms, Forge.gender(_type, noun)))
				if option.get_item_text(option.item_count - 1) == (previous[i - 1] if not previous[i - 1].is_empty() else wanted[i] if i < wanted.size() else ""):
					option.select(option.item_count - 1)
		if option.selected < 0:
			option.select(0)
	for option in _words:
		option.disabled = not plan.is_empty()


func _words_chosen() -> Array:
	var words: Array = []
	for option in _words:
		if option.selected >= 0 and option.get_item_text(option.selected) != "—" and option.get_item_text(option.selected) not in words:
			words.append(option.get_item_text(option.selected))
	return words


func _name() -> String:
	var plan: Dictionary = map_view.world.data.items.get(_plan, {}).get("recette", {})
	return plan["nom"] if not plan.is_empty() else " ".join(_words_chosen())


func _owns_all() -> bool:
	var inventory := map_view.world.character.inventory
	for item_id: String in _chosen:
		if inventory.quantity_of(item_id) < int(_chosen[item_id]):
			return false
	return not _chosen.is_empty()


func _change(item_id: String, delta: int) -> void:
	_plan = ""
	_chosen[item_id] = int(_chosen.get(item_id, 0)) + delta
	if _chosen[item_id] <= 0:
		_chosen.erase(item_id)
	_message.text = ""
	refresh()


func _on_plan_selected(index: int) -> void:
	_plan = _plans.get_item_metadata(index)
	var plan: Dictionary = map_view.world.data.items[_plan]["recette"]
	_type = plan["type"]
	_chosen = plan["ressources"].duplicate()
	refresh()


func _on_forge_pressed() -> void:
	var command := {"type": Protocol.CMD_FORGE, "entite": map_view.world.player_id, "case": _anvil}
	command.merge({"recette": _plan} if not _plan.is_empty() else {"type_objet": _type, "ressources": _chosen.duplicate(), "mots": _words_chosen()})
	map_view.send_command(command)


func _on_result(event: Dictionary) -> void:
	var refused: bool = event["type"] == Protocol.EVT_REFUSED
	_message.text = REFUSALS.get(event.get("raison"), "Impossible.") if refused else "Forgé : %s" % event["nom"]
	_message.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4) if refused else Color(0.55, 0.9, 0.5))
	if not refused:
		_chosen = {}
		_plan = ""
	refresh()


func _set_visible(shown: bool) -> void:
	_panel.visible = shown
	_backdrop.visible = shown


# --- Construction des contrôles ----------------------------------------------------------------

func _build() -> void:
	# Fond assombri : un clic à côté de la fenêtre la ferme (et ne fait pas marcher le personnage).
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0, 0, 0, 0.35)
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			close())
	add_child(_backdrop)
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.offset_left = -440
	_panel.offset_right = 440
	_panel.offset_top = 50
	_panel.offset_bottom = 620
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
	title.text = "Enclume"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_job_label = _label(15, GOLD)
	header.add_child(_job_label)
	var close_button := Button.new()
	close_button.text = "×"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(close)
	header.add_child(close_button)

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)
	column.add_child(row)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(400, 0)
	row.add_child(left)
	_types = OptionButton.new()
	for type: String in Forge.TYPES:
		_types.add_item(Forge.TYPE_NAMES[type])
	_types.item_selected.connect(func(index: int) -> void:
		_type = Forge.TYPES.keys()[index]
		_plan = ""
		refresh())
	left.add_child(_titled("Type d'objet", _types))
	_plans = _list(70)
	_plans.item_selected.connect(_on_plan_selected)
	left.add_child(_titled("Plans du sac (cliquer pour les suivre)", _plans))
	_bag = _list(140)
	_bag.item_clicked.connect(func(index: int, _at: Vector2, _button: int) -> void: _change(_bag.get_item_metadata(index), 1))
	left.add_child(_titled("Ressources du sac (cliquer pour ajouter)", _bag))
	_placed = _list(90)
	_placed.item_clicked.connect(func(index: int, _at: Vector2, _button: int) -> void: _change(_placed.get_item_metadata(index), -1))
	left.add_child(_titled("Sur l'enclume (cliquer pour retirer)", _placed))

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	_preview = _label(14, Color(0.92, 0.9, 0.85))
	_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(UiTheme.scroll_area(_preview))
	var names := HBoxContainer.new()
	for i in 1 + Forge.MAX_ADJECTIVES:
		var option := OptionButton.new()
		option.fit_to_longest_item = false
		option.custom_minimum_size = Vector2(120, 0)
		option.item_selected.connect(func(_index: int) -> void: _show_preview())
		names.add_child(option)
		_words.append(option)
	right.add_child(_titled("Nom de l'objet", names))
	_forge_button = Button.new()
	_forge_button.text = "Forger"
	_forge_button.focus_mode = Control.FOCUS_NONE
	_forge_button.pressed.connect(_on_forge_pressed)
	right.add_child(_forge_button)
	_message = _label(14, Color(0.55, 0.9, 0.5))
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_message)
	var hint := _label(12, Color(0.6, 0.58, 0.52))
	hint.text = "Les jets sont tirés au hasard dans les plages affichées ; votre nom est gravé sur l'objet · Échap : fermer"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(hint)


func _list(height: float) -> ItemList:
	var list := ItemList.new()
	list.custom_minimum_size = Vector2(0, height)
	list.fixed_icon_size = Vector2i(24, 24)
	return list


func _titled(text: String, content: Control) -> VBoxContainer:
	var box := VBoxContainer.new()
	var label := _label(13, Color(0.8, 0.78, 0.7))
	label.text = text
	box.add_child(label)
	box.add_child(content)
	return box


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
