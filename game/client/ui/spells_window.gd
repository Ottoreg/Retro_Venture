class_name SpellsWindow
extends CanvasLayer
## Fenêtre des sorts (touche S) : un onglet par famille (Voie, race, arme), la liste des sorts avec
## leurs icônes et la fiche du sort choisi.

const GOLD := Color(0.95, 0.76, 0.3)
const TARGET_NAMES := {"ennemis": "ennemis", "allies": "alliés"}
const ELEMENT_NAMES := {"acier": "Acier (Force)", "flamme": "Flamme (Intelligence)", "givre": "Givre (Chance)", "tempete": "Tempête (Agilité)",
	"sacre": "Sacré (Force et Intelligence)", "impie": "Impie (Agilité et Chance)"}
## Noms courts des éléments.
const ELEMENT_LABELS := {"acier": "Acier", "flamme": "Flamme", "givre": "Givre", "tempete": "Tempête", "sacre": "Sacré", "impie": "Impie"}
const ELEMENT_COLORS := {"acier": Color("d9a066"), "flamme": Color("ff8a5a"), "givre": Color("7ccfff"), "tempete": Color("9ade6a"),
	"sacre": Color("ffe9a0"), "impie": Color("c48aff")}

var map_view: MapView

var _panel: PanelContainer
var _tabs: TabBar
var _list: ItemList
var _icon: TextureRect
var _title: Label
var _details: Label
## Onglets : { nom, sorts: Array[Spell] }.
var _families: Array[Dictionary] = []
var _selected := ""
## Vrai pendant qu'on change les onglets par le code (pas de rafraîchissement en boucle).
var _quiet := false


## Fiche d'un sort, ligne par ligne (aussi l'infobulle de la barre de sorts).
static func describe(spell: Spell) -> PackedStringArray:
	var lines: PackedStringArray = [spell.display_name]
	var reach := "soi-même"
	if spell.range_max > 0 and spell.range_min == spell.range_max:
		reach = "%d case%s" % [spell.range_max, "s" if spell.range_max > 1 else ""]
	elif spell.range_max > 0:
		reach = "%d à %d cases" % [spell.range_min, spell.range_max]
	var notes: PackedStringArray = []
	if spell.cast_in_line:
		notes.append("en ligne")
	if not spell.needs_line_of_sight and spell.range_max > 0:
		notes.append("sans ligne de vue")
	lines.append("Coût : %d PA — Portée : %s%s" % [spell.pa_cost, reach, "" if notes.is_empty() else " (%s)" % ", ".join(notes)])
	lines.append_array(effect_lines(spell.effects))
	if spell.zone_type == Spell.ZONE_CIRCLE:
		lines.append("Zone : cercle de %d case%s" % [spell.zone_size, "s" if spell.zone_size > 1 else ""])
	elif spell.zone_type == Spell.ZONE_LATIN_CROSS:
		lines.append("Zone : croix (4 cases dans le sens du lancer, une de chaque côté de la 3e)")
	if spell.casts_per_turn > 0:
		lines.append("%d fois par tour au plus" % spell.casts_per_turn)
	if spell.crit_chance != Spell.DEFAULT_CRIT_CHANCE:
		lines.append("Coup critique : %d %%" % spell.crit_chance)
	if spell.cooldown > 0:
		lines.append("Relance : tous les %d tours" % spell.cooldown)
	if not spell.description.is_empty():
		lines.append("")
		lines.append(spell.description)
	return lines


## Une ligne par effet (avec les effets d'une glyphe ou d'un piège, en retrait).
static func effect_lines(effects: Array, indent := "") -> PackedStringArray:
	var lines: PackedStringArray = []
	for effect: Dictionary in effects:
		var type: String = effect["type"]
		var element: String = ELEMENT_NAMES.get(effect.get("element", ""), str(effect.get("element", "")))
		var turns := int(effect.get("duree", 0))
		var duration := "%d tour%s" % [turns, "s" if turns > 1 else ""]
		var line := ""
		match type:
			Spell.EFFECT_DAMAGE:
				line = "Dégâts %s : %d à %d" % [element, effect["min"], effect["max"]]
			Spell.EFFECT_HEAL:
				line = "Soin %s : %d à %d" % [element, effect["min"], effect["max"]]
			Spell.EFFECT_SHIELD:
				line = "Bouclier %s : %d à %d (absorbe les dégâts jusqu'au prochain tour de la cible)" % [element, effect["min"], effect["max"]]
			Spell.EFFECT_REMOVE_PM:
				line = "Retire %d PM au prochain tour" % effect["min"]
			Spell.EFFECT_GAIN_PA:
				line = "Donne %d PA" % effect["min"]
			Spell.EFFECT_TELEPORT:
				line = "Téléporte sur la case visée"
			Spell.EFFECT_BONUS, Spell.EFFECT_MALUS:
				var carac: String = MapView.CARAC_NAMES.get(effect["carac"], effect["carac"])
				if effect["carac"] == "resistance":
					carac = "résistance %s (%%)" % ELEMENT_LABELS.get(effect["element"], effect["element"])
				line = "%s %s : %s (%s)" % ["Bonus" if type == Spell.EFFECT_BONUS else "Malus", carac, _range_text(effect), duration]
			Spell.EFFECT_POISON:
				line = "Poison %s : %s par tour (%s)" % [element, _range_text(effect), duration]
			Spell.EFFECT_PUSH:
				line = "Pousse de %s case(s)" % _range_text(effect)
			Spell.EFFECT_PULL:
				line = "Attire de %s case(s)" % _range_text(effect)
			Spell.EFFECT_GLYPH:
				line = "Glyphe sur la zone (%s du lanceur), au début du tour de qui s'y trouve :" % duration
			Spell.EFFECT_TRAP:
				var zone: Dictionary = effect.get("zone", {})
				line = "Piège invisible pour l'adversaire%s, au premier ennemi qui y entre :" % (
					" (explosion : cercle de %d)" % int(zone["taille"]) if zone.get("type") == Spell.ZONE_CIRCLE else "")
		if line.is_empty():
			continue
		if effect.get("cibles", Spell.TARGETS_ALL) != Spell.TARGETS_ALL and type not in Spell.GROUND_EFFECTS:
			line += " (%s)" % TARGET_NAMES[effect["cibles"]]
		lines.append(indent + line)
		if type in Spell.GROUND_EFFECTS:
			lines.append_array(effect_lines(effect["effets"], indent + "    · "))
	return lines


static func _range_text(effect: Dictionary) -> String:
	return str(effect["min"]) if effect["min"] == effect["max"] else "%d à %d" % [effect["min"], effect["max"]]


func _ready() -> void:
	_build()
	_panel.visible = false


func setup(p_map_view: MapView) -> void:
	map_view = p_map_view
	map_view.combat_started.connect(func() -> void: _panel.visible = false)
	map_view.inventory_changed.connect(refresh)


func toggle() -> void:
	if map_view == null or map_view.mode == MapView.Mode.COMBAT:
		return
	_panel.visible = not _panel.visible
	refresh()


func is_open() -> bool:
	return _panel.visible


## Ouvre la fenêtre sur ce sort.
func show_spell(spell_id: String) -> void:
	if map_view == null or map_view.mode == MapView.Mode.COMBAT:
		return
	_panel.visible = true
	_selected = spell_id
	_update_families()
	_quiet = true
	for i in _families.size():
		for spell: Spell in _families[i]["sorts"]:
			if spell.id == spell_id:
				_tabs.current_tab = i
	_quiet = false
	refresh()


func refresh() -> void:
	if map_view == null or not _panel.visible:
		return
	_update_families()
	_list.clear()
	if _families.is_empty():
		return
	var family: Dictionary = _families[clampi(_tabs.current_tab, 0, _families.size() - 1)]
	var shown: Spell = null
	for spell: Spell in family["sorts"]:
		var index := _list.add_item("%s   (%d PA)" % [spell.display_name, spell.pa_cost], CombatHud.spell_icon(spell.id, map_view.world))
		_list.set_item_custom_fg_color(index, Color(0.92, 0.9, 0.85))
		_list.set_item_metadata(index, spell.id)
		if spell.id == _selected:
			_list.select(index)
			shown = spell
	if shown == null and not family["sorts"].is_empty():
		shown = family["sorts"][0]
		_selected = shown.id
		_list.select(0)
	_show(shown)


## Familles de sorts du personnage : sa Voie, sa race, son arme.
func _update_families() -> void:
	var world := map_view.world
	var data := world.data
	var families: Array[Dictionary] = []
	var voie: Dictionary = data.voies.get(world.character.voie_id, {})
	var voie_spells: Array[Spell] = []
	for spell_id: String in voie.get("sorts", []):
		if data.spells.has(spell_id):
			voie_spells.append(data.spells[spell_id])
	families.append({"nom": "Voie : %s" % voie.get("nom", "?"), "sorts": voie_spells})
	var race: Dictionary = data.races.get(world.character.race_id, {})
	var race_spells: Array[Spell] = []
	if data.spells.has(race.get("sort", "")):
		race_spells.append(data.spells[race["sort"]])
	families.append({"nom": "Race : %s" % race.get("nom", "?"), "sorts": race_spells})
	var weapon := world.character.inventory.equipped_entry("arme")
	if not weapon.is_empty() and data.items.has(weapon["objet"]):
		var weapon_spells: Array[Spell] = [Spell.from_dict(Item.weapon_spell_data(data.items[weapon["objet"]]))]
		families.append({"nom": "Arme : %s" % data.items[weapon["objet"]]["nom"], "sorts": weapon_spells})
	var names: Array[String] = []
	for family in families:
		names.append(family["nom"])
	var current: Array[String] = []
	for i in _tabs.tab_count:
		current.append(_tabs.get_tab_title(i))
	_families = families
	if names != current:
		_quiet = true
		var keep := _tabs.current_tab
		_tabs.clear_tabs()
		for tab_name in names:
			_tabs.add_tab(tab_name)
		_tabs.current_tab = clampi(keep, 0, names.size() - 1)
		_quiet = false


func _show(spell: Spell) -> void:
	if spell == null:
		_icon.texture = null
		_title.text = "Aucun sort"
		_details.text = ""
		return
	_icon.texture = CombatHud.spell_icon(spell.id, map_view.world)
	_title.text = spell.display_name
	var color := GOLD
	for effect in spell.effects:
		if effect["type"] in Spell.ELEMENT_EFFECTS:
			color = ELEMENT_COLORS.get(effect["element"], GOLD)
			break
	_title.add_theme_color_override("font_color", color)
	var lines := describe(spell)
	lines.remove_at(0)
	_details.text = "\n".join(lines)


func _on_tab_changed(_index: int) -> void:
	if _quiet:
		return
	_selected = ""
	refresh()


func _on_item_selected(index: int) -> void:
	_selected = _list.get_item_metadata(index)
	refresh()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_S:
		toggle()
		get_viewport().set_input_as_handled()


# --- Construction des contrôles ----------------------------------------------------------------

func _build() -> void:
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.offset_left = -400
	_panel.offset_right = 400
	_panel.offset_top = 70
	_panel.offset_bottom = 520
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
	var window_title := _label(22, GOLD)
	window_title.text = "Sorts"
	window_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(window_title)
	var close := Button.new()
	close.text = "×"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(toggle)
	header.add_child(close)
	_tabs = TabBar.new()
	_tabs.focus_mode = Control.FOCUS_NONE
	_tabs.tab_changed.connect(_on_tab_changed)
	column.add_child(_tabs)

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)
	column.add_child(row)
	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(320, 0)
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.fixed_icon_size = Vector2i(40, 40)
	_list.item_selected.connect(_on_item_selected)
	row.add_child(_list)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(detail)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	detail.add_child(title_row)
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(64, 64)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_row.add_child(_icon)
	_title = _label(22, GOLD)
	_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_row.add_child(_title)
	_details = _label(15, Color(0.92, 0.9, 0.85))
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_child(_details)
	var hint := _label(12, Color(0.6, 0.58, 0.52))
	hint.text = "Touche S : ouvrir / fermer · En combat, les touches 1 à 0 choisissent les sorts de la barre"
	column.add_child(hint)


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
