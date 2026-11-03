class_name ForgeWindow
extends CanvasLayer
## Forge à l'enclume de la maison (`Forge`) : à gauche le sac (ressources de forge et plans, en icônes),
## qu'on clique ou glisse vers les 8 cases de la recette en bas au centre ; au centre le type d'objet,
## l'aperçu (lignes, jets possibles, palier) et le nom fait de mots proposés ; à droite le jet obtenu.

const GOLD := Color(0.95, 0.76, 0.3)
const REFUSALS := {
	Protocol.REASON_MISSING_INGREDIENTS: "Il manque des ressources.",
	Protocol.REASON_INVENTORY_FULL: "Inventaire plein.",
	Protocol.REASON_TOO_FAR: "L'enclume est trop loin.",
	Protocol.REASON_TOO_MANY_LINES: "Trop de lignes : %d au plus par objet." % Forge.MAX_LINES,
}

var map_view: MapView
var _anvil := Vector2i.ZERO
var _type := "coiffe"
## Ressources posées sur l'enclume, dans l'ordre des cases : id → quantité.
var _chosen := {}
## Plan choisi (id), ou "".
var _plan := ""
## Vrai quand une feuille de papier est dans la 9e case : elle recevra le patron de l'objet.
var _paper := false
## Vrai quand le joueur a touché au nom : on ne lui remet plus les mots proposés.
var _named := false
var _backdrop: ColorRect
var _panel: PanelContainer
var _job_label: Label
var _types: OptionButton
var _bag: ItemList
var _slots: Array[Button] = []
var _paper_slot: Button
var _preview: Label
var _words: Array[OptionButton] = []
var _forge_button: Button
var _message: Label
var _result_icon: TextureRect
var _result: Label


## Lignes de forge d'un modèle pour ses infobulles : caractéristique et matière d'une ressource
## (cachée sans la réputation d'artisan), contenu d'un plan ou d'un patron (ses jets et ses effets).
static func forge_lines(template: Dictionary, data: GameData, character: Character) -> PackedStringArray:
	var lines: PackedStringArray = []
	if template.has("caracteristique") and character != null:
		var tier := int(template.get("niveau", 1))
		lines.append("Forge : %s" % (", ".join(Forge.stats_of(template).map(func(s: String) -> String:
			return "+%d %s" % [Forge.value(s, tier), Item.stat_name(s)])) if Forge.reveals(character, tier) else "caractéristique inconnue (réputation de forgeron trop basse pour le palier %d)" % tier))
	if template.has("matiere"):
		lines.append("Matière : %s" % template["matiere"])
	var plan: Dictionary = template.get("recette", template.get("patron", {}))
	if not plan.is_empty() and data != null:
		lines.append("%s : %s" % [Forge.TYPE_NAMES[plan["type"]], plan["nom"]])
		for item_id: String in plan["ressources"]:
			lines.append("  • %d %s" % [plan["ressources"][item_id], data.items.get(item_id, {}).get("nom", item_id)])
		var details := roll_lines(plan["jets"], plan["bonus"]) + InventoryWindow.attack_lines(Item.entry_template({"objet": Forge.template_id(plan["type"]),
			"forge": {"nom": "", "artisan": "", "palier": plan["palier"], "bonus": plan["bonus"]}}, data.items)) if plan.has("jets") \
			else InventoryWindow.bonus_range_lines(Forge.preview(plan["type"], plan["ressources"], data.items, character, false)["bonus"])
		for line in details:
			lines.append("  " + line)
	return lines


## Jets obtenus avec leur plage : « +9 Initiative (8 à 11) ».
static func roll_lines(jets: Dictionary, bonus: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	for stat: String in jets:
		var span: Array = bonus.get(stat, [])
		lines.append("+%d %s%s" % [jets[stat], Item.stat_name(stat), " (%d à %d)" % span if span.size() == 2 and span[0] != span[1] else ""])
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
	_named = false
	_paper = false
	_message.text = ""
	_result.text = "Le jet obtenu s'affichera ici."
	_result_icon.texture = null
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
	var reputation_value := character.job_reputation(Forge.JOB)
	_job_label.text = "Forgeron %s (réputation %d)" % [Character.tier_name(Character.tier_index(reputation_value)), reputation_value]
	_types.select(Forge.TYPES.keys().find(_type))
	_bag.clear()
	for entry: Dictionary in character.inventory_sheet(world.data)["objets"]:
		var template: Dictionary = world.data.items.get(entry["objet"], {})
		var left := int(entry["quantite"]) - ((1 if _paper else 0) if entry["objet"] == Forge.PAPER else int(_chosen.get(entry["objet"], 0)))
		if template.has("recette") or (left > 0 and (entry["objet"] == Forge.PAPER or template.get("type") == Item.TYPE_RESOURCE and (template.has("caracteristique") or template.has("matiere")))):
			InventoryWindow.add_bag_item(_bag, entry.merged({"quantite": left}, true),
				"\n".join([entry["nom"] + (" (cliquer pour le suivre)" if template.has("recette") else "")] + Array(forge_lines(template, world.data, character))))
	var ids := _chosen.keys()
	for i in _slots.size():
		var item_id: String = ids[i] if i < ids.size() else ""
		_slots[i].set_meta("objet", item_id)
		_slots[i].icon = InventoryWindow.item_icon(item_id) if not item_id.is_empty() else null
		_slots[i].text = "×%d" % _chosen[item_id] if not item_id.is_empty() else ""
		_slots[i].tooltip_text = "%s ×%d (cliquer pour en retirer un)" % [world.data.items[item_id]["nom"], _chosen[item_id]] if not item_id.is_empty() else ""
	_paper_slot.icon = InventoryWindow.item_icon(Forge.PAPER) if _paper else null
	_show_preview()


func _show_preview() -> void:
	var data := map_view.world.data
	var plan: Dictionary = data.items.get(_plan, {}).get("recette", {})
	var preview := Forge.preview(_type, _chosen, data.items, map_view.world.character, plan.is_empty())
	# Adjectifs et élément d'attaque d'après toutes les lignes, même cachées : ils laissent deviner l'objet.
	var full: Dictionary = Forge.preview(_type, _chosen, data.items, map_view.world.character, false)["bonus"]
	_update_words(full, plan)
	var lines: PackedStringArray = ["%s, palier %d" % [Forge.TYPE_NAMES[_type], preview["palier"]]]
	lines.append_array(InventoryWindow.bonus_range_lines(preview["bonus"]))
	lines.append_array(InventoryWindow.attack_lines(Item.entry_template({"objet": Forge.template_id(_type),
		"forge": {"nom": "", "artisan": "", "palier": preview["palier"], "bonus": full}}, data.items)))
	if preview["cachees"] > 0:
		lines.append("+ %d ressource(s) à la caractéristique inconnue" % preview["cachees"])
	lines.append("")
	lines.append("Ressources différentes : %d / %d · matières : %s" % [_chosen.size(), Forge.MAX_SLOTS,
		", ".join(PackedStringArray(Forge.TYPES[_type]["matieres"]))])
	if not preview["manquantes"].is_empty():
		lines.append("Manque : %s" % ", ".join(PackedStringArray(preview["manquantes"])))
	if preview["erreur"] == Protocol.REASON_TOO_MANY_LINES:
		lines.append(REFUSALS[Protocol.REASON_TOO_MANY_LINES])
	lines.append("Nom : %s" % _name())
	_preview.text = "\n".join(lines)
	_forge_button.disabled = not preview["erreur"].is_empty() or not _owns_all()


## Choix du nom : le nom du type puis deux adjectifs des lignes de l'objet (un plan impose son nom). Les mots
## proposés ne s'appliquent que tant que le joueur n'a pas touché au nom ; un adjectif choisi suit le genre du nom.
func _update_words(bonus: Dictionary, plan: Dictionary) -> void:
	var noun: String = _words[0].get_item_text(_words[0].selected) if _words[0].selected >= 0 else ""
	var wanted := Forge.default_words(_type, bonus)
	if Forge.gender(_type, noun).is_empty():
		noun = wanted[0]
	var previous: Array = _words.slice(1).map(func(option: OptionButton) -> Variant:
		return option.get_item_metadata(option.selected) if option.selected > 0 else null)
	_words[0].clear()
	for entry: Array in Forge.TYPES[_type]["noms"]:
		_words[0].add_item(entry[0])
		if entry[0] == noun:
			_words[0].select(_words[0].item_count - 1)
	for i in range(1, _words.size()):
		var option := _words[i]
		option.clear()
		option.add_item("—")
		option.select(0)
		for stat: String in bonus:
			for k in Forge.WORDS[stat].size():
				option.add_item(Forge.adjective(Forge.WORDS[stat][k], Forge.gender(_type, noun)))
				option.set_item_metadata(option.item_count - 1, [stat, k])
				if previous[i - 1] == [stat, k] or (not _named and i < wanted.size() and Forge.adjective(Forge.WORDS[stat][k], Forge.gender(_type, wanted[0])) == wanted[i]):
					option.select(option.item_count - 1)
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
	if item_id == Forge.PAPER:
		_paper = delta > 0
		refresh()
		return
	if delta > 0 and not _chosen.has(item_id) and _chosen.size() >= Forge.MAX_SLOTS:
		_message.text = "%d ressources différentes au plus." % Forge.MAX_SLOTS
		return
	_plan = ""
	_chosen[item_id] = int(_chosen.get(item_id, 0)) + delta
	if _chosen[item_id] <= 0:
		_chosen.erase(item_id)
	_message.text = ""
	refresh()


func _can_drop_on_recipe(_at: Vector2, dragged: Variant) -> bool:
	return typeof(dragged) == TYPE_DICTIONARY and dragged.has("forge")


func _drop_on_recipe(at: Vector2, dragged: Variant) -> void:
	if _can_drop_on_recipe(at, dragged):
		_change(dragged["forge"], 1)


func _follow_plan(item_id: String) -> void:
	_plan = item_id
	var plan: Dictionary = map_view.world.data.items[_plan]["recette"]
	_type = plan["type"]
	_chosen = plan["ressources"].duplicate()
	refresh()


func _on_forge_pressed() -> void:
	var command := {"type": Protocol.CMD_FORGE, "entite": map_view.world.player_id, "case": _anvil}
	command.merge({"recette": _plan} if not _plan.is_empty() else {"type_objet": _type, "ressources": _chosen.duplicate(), "mots": _words_chosen()})
	command["papier"] = _paper
	map_view.send_command(command)


func _on_result(event: Dictionary) -> void:
	var refused: bool = event["type"] == Protocol.EVT_REFUSED
	_message.text = REFUSALS.get(event.get("raison"), "Impossible.") if refused else "Forgé : %s%s" % [event["nom"], ", et son patron" if event.get("patron", false) else ""]
	_message.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4) if refused else Color(0.55, 0.9, 0.5))
	if not refused:
		_chosen = {}
		_plan = ""
		_named = false
		_result_icon.texture = InventoryWindow.item_icon(event["objet"])
		_paper = false
		_result.text = "\n".join(PackedStringArray([event["nom"], "Palier %d" % event.get("palier", 1), ""]) + roll_lines(event.get("jets", {}), event.get("bonus", {})))
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
	_panel.offset_left = -560
	_panel.offset_right = 560
	_panel.offset_top = 40
	_panel.offset_bottom = 650
	_panel.add_theme_stylebox_override("panel", UiTheme.window_style())
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
	# Gauche : le sac en icônes. Un clic gauche relâché ajoute une ressource (ou suit un plan), sans la
	# molette ; on peut aussi glisser une ressource vers les cases de la recette.
	_bag = ItemList.new()
	InventoryWindow.make_bag_grid(_bag)
	_bag.custom_minimum_size = Vector2(360, 0)
	_bag.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_bag.gui_input.connect(func(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		var index := _bag.get_item_at_position(click.position, true) if click != null and click.button_index == MOUSE_BUTTON_LEFT and not click.pressed else -1
		if index >= 0:
			var item_id: String = _bag.get_item_metadata(index)
			if map_view.world.data.items[item_id].has("recette"):
				_follow_plan(item_id)
			else:
				_change(item_id, 1))
	_bag.set_drag_forwarding(func(at: Vector2) -> Variant:
		var index := _bag.get_item_at_position(at, true)
		if index < 0 or map_view.world.data.items[_bag.get_item_metadata(index)].has("recette"):
			return null
		var preview := TextureRect.new()
		preview.texture = _bag.get_item_icon(index)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.size = Vector2(40, 40)
		_bag.set_drag_preview(preview)
		return {"forge": _bag.get_item_metadata(index)}, Callable(), Callable())
	var left := _titled("Sac : ressources de forge, plans et papier (cliquer ou glisser vers la recette)", _bag)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	(left.get_child(0) as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(left)

	# Centre : type, aperçu, nom, puis la recette (8 cases) et le bouton.
	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(center)
	_types = OptionButton.new()
	for type: String in Forge.TYPES:
		_types.add_item(Forge.TYPE_NAMES[type])
	_types.item_selected.connect(func(index: int) -> void:
		_type = Forge.TYPES.keys()[index]
		_plan = ""
		_named = false
		refresh())
	center.add_child(_titled("Type d'objet", _types))
	_preview = _label(14, Color(0.92, 0.9, 0.85))
	_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center.add_child(UiTheme.scroll_area(_preview))
	var names := HBoxContainer.new()
	for i in 1 + Forge.MAX_ADJECTIVES:
		var option := OptionButton.new()
		option.fit_to_longest_item = false
		option.custom_minimum_size = Vector2(130, 0)
		option.item_selected.connect(func(_index: int) -> void:
			_named = true
			_show_preview())
		names.add_child(option)
		_words.append(option)
	center.add_child(_titled("Nom de l'objet", names))
	var slots := HBoxContainer.new()
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in Forge.MAX_SLOTS + 1:  # 8 cases de ressources, puis celle de la feuille de papier.
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(48, 62)
		slot.focus_mode = Control.FOCUS_NONE
		slot.expand_icon = true
		slot.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		slot.add_theme_font_size_override("font_size", 11)
		slot.pressed.connect(func() -> void:
			if not str(slot.get_meta("objet", "")).is_empty():
				_change(slot.get_meta("objet"), -1))
		slot.set_drag_forwarding(Callable(), _can_drop_on_recipe, _drop_on_recipe)
		slots.add_child(slot)
		_slots.append(slot)
	_paper_slot = _slots.pop_back()
	_paper_slot.set_meta("objet", Forge.PAPER)
	_paper_slot.text = "patron"
	_paper_slot.tooltip_text = "Feuille de papier (vendue par les marchands) : elle reçoit le patron de l'objet forgé"
	_paper_slot.modulate = Color(1.0, 0.9, 0.7)
	center.add_child(_titled("Recette (cliquer une case pour en retirer)", slots))
	_forge_button = Button.new()
	_forge_button.text = "Forger"
	_forge_button.focus_mode = Control.FOCUS_NONE
	_forge_button.pressed.connect(_on_forge_pressed)
	center.add_child(_forge_button)
	_message = _label(14, Color(0.55, 0.9, 0.5))
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center.add_child(_message)

	# Droite : l'objet forgé et ses jets.
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(220, 0)
	row.add_child(right)
	var result_title := _label(15, GOLD)
	result_title.text = "Objet forgé"
	right.add_child(result_title)
	_result_icon = TextureRect.new()
	_result_icon.custom_minimum_size = Vector2(64, 64)
	_result_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_result_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	right.add_child(_result_icon)
	_result = _label(14, Color(0.92, 0.9, 0.85))
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(UiTheme.scroll_area(_result))
	var hint := _label(12, Color(0.6, 0.58, 0.52))
	hint.text = "Les jets sont tirés au hasard dans les plages affichées ; votre nom est gravé sur l'objet · Échap : fermer"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(hint)


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
