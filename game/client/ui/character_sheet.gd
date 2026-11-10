class_name CharacterSheet
extends CanvasLayer
## Fiche du personnage (touche C) : réputation de la classe active (palier, points de maîtrise), PV,
## caractéristiques (points gagnés par la pratique et leur plafond, GDD § 4.5) et choix de la classe
## active. Survoler une valeur montre sa provenance (points gagnés, race, équipement, panoplie). Le bouton
## « Détails » ouvre à côté les caractéristiques détaillées (façon Dofus Rétro) : valeurs de combat, et par
## élément la puissance (% de dégâts), les dommages et la résistance.

const GOLD := Color(0.95, 0.76, 0.3)
const STAT_HELP := {
	"vitalite": "+1 PV par point",
	"force": "+1 % aux dégâts, soins et boucliers d'Acier et de Sacré, +1 initiative par point",
	"intelligence": "+1 % aux dégâts, soins et boucliers de Flamme et de Sacré, +1 initiative par point",
	"perception": "+1 % aux dégâts, soins et boucliers de Givre et d'Impie, +1 initiative par point",
	"agilite": "+1 % aux dégâts, soins et boucliers de Tempête et d'Impie, +1 initiative par point",
}
## Valeurs secondaires affichées : [clé de la fiche, nom, aide].
const DERIVED := [
	["pa", "PA", "Points d'action : pour lancer des sorts"],
	["pm", "PM", "Points de mouvement : une case par point en combat"],
	["initiative", "Initiative", "Ordre de jeu en combat : base de la Voie + Force, Intelligence, Perception et Agilité + équipement"],
	["prospection", "Prospection", "Chances de butin : 100 + équipement + passif de race"],
	["dommages", "Dommages", "Dégâts bruts ajoutés à chaque ligne de dégâts, quel que soit l'élément (ni multipliés, ni réduits par les résistances)"],
	["critique", "Critique (%)", "Chance de coup critique d'un sort ordinaire (5 % + équipement) : dégâts, soins, boucliers et poisons × 1,5"],
]

var map_view: MapView

var _panel: PanelContainer
var _title: Label
var _subtitle: Label
var _xp_bar: ProgressBar
var _xp_label: Label
var _hp_label: Label
var _points_label: Label
## Choix de la classe active (ids des Voies dans l'ordre des données).
var _class_choice: OptionButton
var _class_ids: Array = []
var _stat_values := {}
## Points gagnés / plafond de chaque caractéristique.
var _stat_caps := {}
## Valeurs secondaires : PA, PM, initiative, prospection.
var _derived_values := {}
var _details: PanelContainer
var _general: GridContainer
var _elements: GridContainer


func _ready() -> void:
	_build()
	_panel.visible = false


func setup(p_map_view: MapView) -> void:
	map_view = p_map_view
	map_view.character_changed.connect(refresh)
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
	var sheet := world.character.sheet(world.data)
	_title.text = sheet["nom"]
	_subtitle.text = "%s — %s %s" % [sheet["palier_nom"], sheet["race_nom"], sheet["voie_nom"]]
	var span := maxi(1, int(sheet["reputation_suivante"]) - int(sheet["reputation_palier"]))
	_xp_bar.value = 100.0 * (int(sheet["reputation"]) - int(sheet["reputation_palier"])) / span
	_xp_label.text = "Réputation de %s : %d / %d" % [sheet["voie_nom"], sheet["reputation"], sheet["reputation_suivante"]]
	_hp_label.text = "Points de vie : %d / %d" % [sheet["pv"], sheet["pv_max"]]
	var points: int = sheet["points_maitrise"]
	_points_label.text = "Points de maîtrise : %d" % points
	_points_label.modulate = GOLD if points > 0 else Color(0.7, 0.7, 0.7)
	_refresh_classes(world)
	for stat_name: String in _stat_values:
		var total: int = sheet["caracteristiques"][stat_name]
		_stat_values[stat_name].text = str(total)
		_stat_values[stat_name].tooltip_text = source_text(Character.STAT_NAMES[stat_name], total, sheet["provenance"][stat_name], true)
		_stat_caps[stat_name].text = "%d / %d" % [int(sheet["gagnes"].get(stat_name, 0)), int(sheet["plafonds"][stat_name])]
	for entry: Array in DERIVED:
		var key: String = entry[0]
		_derived_values[key].text = str(sheet[key])
		_derived_values[key].tooltip_text = source_text(entry[1], int(sheet[key]), sheet["provenance"].get(key, {}), false)
	_refresh_details(world)


## Caractéristiques détaillées, lues sur le combattant que deviendrait le personnage (équipement compris).
func _refresh_details(world: Variant) -> void:
	if not _details.visible:
		return
	var fighter: Fighter = world.data.create_character_fighter(world.character, "fiche")
	for grid in [_general, _elements]:
		for child in grid.get_children():
			grid.remove_child(child)
			child.queue_free()
	for row: Array in [["Points de vie", fighter.max_hp], ["PA", fighter.max_pa], ["PM", fighter.max_pm], ["Initiative", fighter.initiative],
			["Prospection", fighter.prospection], ["Portée", "%+d" % fighter.range_bonus], ["Critique", "%d %%" % (Spell.DEFAULT_CRIT_CHANCE + fighter.crit_bonus)],
			["Dommages", fighter.total_dommages()], ["Tacle", fighter.tackle()], ["Fuite", fighter.escape()]] \
			+ Fighter.COMBAT_STATS.filter(func(stat: String) -> bool: return stat not in ["tacle", "fuite"] and fighter.combat_stat(stat) != 0) \
				.map(func(stat: String) -> Array: return [Item.EXTRA_STAT_NAMES[stat], fighter.combat_stat(stat)]):
		_cells(_general, row, Color.WHITE)
	_cells(_elements, ["Élément", "Puissance", "Dommages", "Résistance"], GOLD)
	for element: String in Spell.ELEMENTS:
		_cells(_elements, [SpellsWindow.ELEMENT_LABELS[element], "%+d %%" % fighter.power(element), "%+d" % fighter.element_damage(element),
			"%d %%" % roundi(fighter.resistance(element))], SpellsWindow.ELEMENT_COLORS[element])


func _cells(grid: GridContainer, values: Array, color: Color) -> void:
	for i in values.size():
		var label := _label(14, color if i == 0 or color == GOLD else Color.WHITE)
		label.text = str(values[i])
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL if i == 0 else Control.SIZE_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if i == 0 else HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(label)


## Infobulle de provenance d'une valeur : points gagnés et race (caractéristiques), sinon la base
## (Voie, caractéristiques), puis l'équipement objet par objet et la panoplie.
static func source_text(title: String, total: int, sources: Dictionary, is_stat: bool) -> String:
	var lines: PackedStringArray = ["%s : %d" % [title, total]]
	var equipment := int(sources.get("equipement", 0))
	var panoply := int(sources.get("panoplie", 0))
	if is_stat:
		lines.append("Gagnés par la pratique : %d" % int(sources.get("points", 0)))
	else:
		lines.append("Base : %d" % (total - equipment - panoply))
	if equipment != 0:
		lines.append("Équipement : %+d" % equipment)
		for item: Array in sources.get("objets", []):
			lines.append("  %s : %+d" % [item[0], int(item[1])])
	if panoply != 0:
		lines.append("Panoplie : %+d" % panoply)
	return "\n".join(lines)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_C:
		toggle()
		get_viewport().set_input_as_handled()


## Liste des classes : la classe active choisie, celles qu'on ne peut pas encore commencer grisées.
func _refresh_classes(world: Variant) -> void:
	_class_choice.clear()
	_class_ids = world.data.voies.keys()
	for i in _class_ids.size():
		var class_id: String = _class_ids[i]
		var label: String = world.data.voies[class_id].get("nom", class_id)
		if world.character.classes.has(class_id):
			label += " (%s)" % Character.tier_name(Character.tier_index(world.character.reputation(class_id)))
		_class_choice.add_item(label, i)
		_class_choice.set_item_disabled(i, not world.character.can_switch_to(class_id))
		if class_id == world.character.voie_id:
			_class_choice.select(i)
	_class_choice.tooltip_text = ("Classe active, changée hors combat. Une nouvelle classe demande %d de réputation "
		+ "dans une autre et repart de zéro ; les caractéristiques suivent.") % Character.NEW_CLASS_REPUTATION


func _on_class_selected(index: int) -> void:
	if index < 0 or index >= _class_ids.size() or _class_ids[index] == map_view.world.character.voie_id:
		return
	map_view.send_command({"type": Protocol.CMD_SWITCH_CLASS, "entite": map_view.world.player_id, "voie": _class_ids[index]})


# --- Construction des contrôles ----------------------------------------------------------------

func _build() -> void:
	_panel = PanelContainer.new()
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.offset_left = -330
	_panel.offset_right = -16
	_panel.offset_top = 70
	_panel.offset_bottom = 530
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.1, 0.07, 0.95)
	style.border_color = Color(0.55, 0.42, 0.22)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(14)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_panel.add_child(UiTheme.scroll_area(box))  # Taille fixe : ce qui ne tient pas défile.
	var header := HBoxContainer.new()
	box.add_child(header)
	_title = _label(22, GOLD)
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var details_button := Button.new()
	details_button.text = "Détails"
	details_button.focus_mode = Control.FOCUS_NONE
	details_button.pressed.connect(func() -> void:
		_details.visible = not _details.visible
		refresh())
	header.add_child(details_button)
	var close := Button.new()
	close.text = "×"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(toggle)
	header.add_child(close)
	_subtitle = _label(15, Color(0.85, 0.82, 0.75))
	_subtitle.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(_subtitle)
	_xp_bar = ProgressBar.new()
	_xp_bar.show_percentage = false
	_xp_bar.custom_minimum_size = Vector2(0, 10)
	box.add_child(_xp_bar)
	_xp_label = _label(13, Color(0.75, 0.72, 0.65))
	box.add_child(_xp_label)
	_hp_label = _label(15, Color(0.95, 0.5, 0.45))
	box.add_child(_hp_label)
	var points_row := HBoxContainer.new()
	box.add_child(points_row)
	_points_label = _label(16, GOLD)
	_points_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	points_row.add_child(_points_label)
	_class_choice = OptionButton.new()
	_class_choice.focus_mode = Control.FOCUS_NONE
	_class_choice.fit_to_longest_item = false
	_class_choice.clip_text = true
	_class_choice.item_selected.connect(_on_class_selected)
	box.add_child(_class_choice)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	box.add_child(grid)
	for stat_name in Character.STATS:
		var name_label := _label(15, Color.WHITE)
		name_label.text = Character.STAT_NAMES[stat_name]
		name_label.tooltip_text = STAT_HELP.get(stat_name, "")
		name_label.mouse_filter = Control.MOUSE_FILTER_PASS
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value_label := _label(15, Color.WHITE)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.custom_minimum_size = Vector2(40, 0)
		value_label.mouse_filter = Control.MOUSE_FILTER_PASS
		var cap_label := _label(13, Color(0.7, 0.68, 0.6))
		cap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cap_label.custom_minimum_size = Vector2(70, 0)
		cap_label.mouse_filter = Control.MOUSE_FILTER_PASS
		cap_label.tooltip_text = "Points gagnés par la pratique / plafond (hors race et équipement)"
		grid.add_child(name_label)
		grid.add_child(value_label)
		grid.add_child(cap_label)
		_stat_values[stat_name] = value_label
		_stat_caps[stat_name] = cap_label
	var derived := GridContainer.new()
	derived.columns = 4
	derived.add_theme_constant_override("h_separation", 10)
	box.add_child(derived)
	for entry: Array in DERIVED:
		var name_label := _label(14, Color(0.8, 0.78, 0.7))
		name_label.text = entry[1]
		name_label.tooltip_text = entry[2]
		name_label.mouse_filter = Control.MOUSE_FILTER_PASS
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value_label := _label(14, Color.WHITE)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.custom_minimum_size = Vector2(36, 0)
		value_label.mouse_filter = Control.MOUSE_FILTER_PASS
		derived.add_child(name_label)
		derived.add_child(value_label)
		_derived_values[entry[0]] = value_label
	var hint := _label(12, Color(0.6, 0.58, 0.52))
	hint.text = "Touche C : ouvrir / fermer"
	box.add_child(hint)

	# Caractéristiques détaillées, à gauche de la fiche.
	_details = PanelContainer.new()
	_details.anchor_left = 1.0
	_details.anchor_right = 1.0
	_details.offset_left = -680
	_details.offset_right = -340
	_details.offset_top = 70
	_details.offset_bottom = 530
	_details.add_theme_stylebox_override("panel", UiTheme.window_style())
	_details.visible = false
	_panel.visibility_changed.connect(func() -> void: _details.visible = _details.visible and _panel.visible)
	add_child(_details)
	var details_box := VBoxContainer.new()
	details_box.add_theme_constant_override("separation", 8)
	_details.add_child(UiTheme.scroll_area(details_box))
	var details_title := _label(18, GOLD)
	details_title.text = "Caractéristiques détaillées"
	details_box.add_child(details_title)
	_general = GridContainer.new()
	_general.columns = 2
	details_box.add_child(_general)
	_elements = GridContainer.new()
	_elements.columns = 4
	_elements.add_theme_constant_override("h_separation", 12)
	details_box.add_child(_elements)
	var details_hint := _label(12, Color(0.6, 0.58, 0.52))
	details_hint.text = "Puissance : % de dégâts, soins et boucliers de l'élément (sa caractéristique) ; Dommages : ajoutés aux dégâts de l'élément ; Sacré et Impie : leurs deux éléments."
	details_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_box.add_child(details_hint)


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
