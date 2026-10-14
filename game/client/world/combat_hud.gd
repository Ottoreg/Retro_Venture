class_name CombatHud
extends CanvasLayer
## Barre de jeu du bas, comme dans Dofus Rétro, toujours affichée : points de vie dans un cœur
## rouge qui se vide, PA dans une étoile bleue, PM dans une case verte, sorts en icônes, bouton de
## tour (en combat) et menus. Aussi : ordre de jeu, messages et écran de fin de combat.

const BAR_HEIGHT := 96
## Message quand le sac déborde (butin en surplus).
const OVERLOAD_TEXT := "Inventaire surchargé ! Faites de la place (vendre, jeter, ranger au coffre) pour pouvoir combattre à nouveau."
## Noms courts des éléments pour les résistances du combattant survolé.
const RESISTANCE_NAMES := {"acier": "Acier", "flamme": "Flamme", "givre": "Givre", "tempete": "Tempête", "sacre": "Sacré", "impie": "Impie"}
const SPELL_KEYS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0]
const MENUS := [["personnage", "icone_personnage", "Personnage (C)"], ["inventaire", "icone_inventaire", "Inventaire (I)"],
	["sorts", "icone_sorts", "Sorts (S)"], ["metiers", "icone_metiers", "Métiers (J)"]]

## Un bouton de menu de la barre : « personnage », « inventaire », « sorts » ou « metiers ».
signal menu_pressed(menu: String)
## Clic sur un sort hors combat : afficher sa fiche.
signal spell_info_requested(spell_id: String)


## Jauge dessinée : PV dans un cœur qui se vide par le haut, PA dans une étoile, PM dans une case.
class Gauge extends Control:
	var kind := "pv"
	var value := 0
	var maximum := 0

	func show_values(p_value: int, p_maximum: int) -> void:
		if p_value != value or p_maximum != maximum:
			value = p_value
			maximum = p_maximum
			queue_redraw()

	func _draw() -> void:
		var center := size / 2.0
		var font := ThemeDB.fallback_font
		if kind == "pv":
			var empty := Art.texture("coeur_vide")
			var full := Art.texture("coeur_plein")
			var drawn := Vector2(64, 58)
			var origin := center - drawn / 2.0
			draw_texture_rect(empty, Rect2(origin, drawn), false)
			var ratio := clampf(float(value) / maxf(1.0, maximum), 0.0, 1.0)
			var source_top := full.get_height() * (1.0 - ratio)
			draw_texture_rect_region(full, Rect2(origin + Vector2(0, drawn.y * (1.0 - ratio)), Vector2(drawn.x, drawn.y * ratio)),
				Rect2(0, source_top, full.get_width(), full.get_height() - source_top))
			_number(font, center + Vector2(0, -2), str(value), 20)
			_number(font, center + Vector2(0, 14), "/%d" % maximum, 11)
		else:
			var image := "etoile_pa" if kind == "pa" else "case_pm"
			var drawn := Vector2(52, 52) if kind == "pa" else Vector2(60, 40)
			draw_texture_rect(Art.texture(image), Rect2(center - drawn / 2.0, drawn), false)
			_number(font, center + Vector2(0, 1), str(value), 20)

	func _number(font: Font, at: Vector2, text: String, font_size: int) -> void:
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var spot := at + Vector2(-width / 2.0, font_size * 0.36)
		draw_string_outline(font, spot, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, Color(0.1, 0.05, 0.02))
		draw_string(font, spot, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)


## Emplacement de sort : cadre, icône, raccourci et coût en PA.
class SpellSlot extends Control:
	signal pressed
	var icon: Texture2D
	var key_label := ""
	var cost := 0
	var selected := false
	var usable := true

	func _init() -> void:
		custom_minimum_size = Vector2(50, 50)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit()
			accept_event()

	func _draw() -> void:
		var frame := Rect2(Vector2(1, 1), Vector2(48, 48))
		draw_texture_rect(Art.texture("case_sort"), frame, false)
		if icon != null:
			draw_texture_rect(icon, frame.grow(-3), false, Color.WHITE if usable else Color(0.45, 0.45, 0.45))
		if selected:
			draw_rect(frame.grow(-1), Color(1.0, 0.82, 0.3), false, 3.0)
		var font := ThemeDB.fallback_font
		draw_string_outline(font, Vector2(5, 15), key_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color.BLACK)
		draw_string(font, Vector2(5, 15), key_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.95, 0.8))
		var price := str(cost)
		var spot := Vector2(44 - font.get_string_size(price, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x, 45)
		draw_string_outline(font, spot, price, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color.BLACK)
		draw_string(font, spot, price, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.85, 1.0))


var map_view: MapView

var _bar: PanelContainer
var _hp_gauge: Gauge
var _pa_gauge: Gauge
var _pm_gauge: Gauge
var _spells_box: HBoxContainer
## En combat, au survol d'un combattant : ses informations à la place de la barre de sorts.
var _target_box: HBoxContainer
var _target_name: Label
var _target_level: Label
var _target_stats: Label
var _target_resistances := {}
## Id du combattant survolé ("" si aucun).
var _target_id := ""
var _turn_button: Button
var _menu_buttons := {}
var _order_label: Label
var _message_label: Label
var _message_time := 0.0
var _result_panel: PanelContainer
var _result_title: Label
var _result_detail: Label
var _loot_box: HFlowContainer
var _overload_label: Label
## Emplacements de sorts affichés : id du sort → SpellSlot.
var _spell_buttons: Dictionary = {}
var _shown_spells: Array[String] = []
var _refresh_time := 0.0


func _ready() -> void:
	_build()
	_turn_button.visible = false
	_order_label.visible = false
	_result_panel.visible = false


func setup(p_map_view: MapView) -> void:
	map_view = p_map_view
	map_view.combat_started.connect(_on_combat_started)
	map_view.combat_state_changed.connect(_refresh)
	map_view.combat_message.connect(show_message)
	map_view.combat_ended.connect(_on_combat_ended)
	map_view.exploration_resumed.connect(_on_exploration_resumed)
	map_view.character_changed.connect(_refresh_exploration)
	map_view.inventory_changed.connect(_refresh_exploration)
	map_view.hovered_cell_changed.connect(_on_hovered_cell_changed)
	_refresh_exploration()


func show_message(text: String) -> void:
	_message_label.text = text
	_message_label.modulate.a = 1.0
	_message_time = 1.8


func _process(delta: float) -> void:
	if _message_time > 0.0:
		_message_time -= delta
		_message_label.modulate.a = clampf(_message_time / 0.5, 0.0, 1.0)
	# Hors combat, les PV remontent tout seuls : la jauge suit.
	_refresh_time += delta
	if _refresh_time >= 0.5:
		_refresh_time = 0.0
		_refresh_exploration()


func _unhandled_key_input(event: InputEvent) -> void:
	if map_view == null or map_view.mode != MapView.Mode.COMBAT or not event.is_pressed() or event.is_echo():
		return
	var key := (event as InputEventKey).keycode
	var index := SPELL_KEYS.find(key)
	var fighter := map_view.player_fighter()
	if index >= 0 and fighter != null and index < fighter.spells.size():
		map_view.select_spell(fighter.spells[index].id)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and map_view.selected_spell != "":
		map_view.select_spell(map_view.selected_spell)
		get_viewport().set_input_as_handled()


## Sorts du personnage hors combat (ceux qu'il aurait en combat : arme, Voie, race).
static func character_spells(world: World) -> Array[Spell]:
	var spells: Array[Spell] = []
	if world == null or world.data == null:
		return spells
	var fighter := world.data.create_character_fighter(world.character, World.PLAYER_ID)
	if fighter != null:
		spells = fighter.spells
	return spells


## Icône d'un sort (l'attaque de l'arme prend l'icône de l'arme portée).
static func spell_icon(spell_id: String, world: World) -> Texture2D:
	var image := "sort_" + spell_id
	if spell_id == "arme" and world != null:
		var weapon := world.character.inventory.equipped_entry("arme")
		image = Art.manifest().get("icones_armes", {}).get(weapon.get("objet", ""), "sort_arme_epee")
	return Art.texture(image if Art.has_image(image) else "sort_inconnu")


## Remplit la barre de sorts (si la liste a changé).
func _show_spells(spells: Array[Spell]) -> void:
	var ids: Array[String] = []
	for spell in spells:
		ids.append(spell.id)
	if ids == _shown_spells and _spell_buttons.size() == ids.size():
		return
	_shown_spells = ids
	for child in _spells_box.get_children():
		child.queue_free()
	_spell_buttons.clear()
	for i in spells.size():
		var spell := spells[i]
		var slot := SpellSlot.new()
		slot.icon = spell_icon(spell.id, map_view.world)
		slot.key_label = str((i + 1) % 10) if i < SPELL_KEYS.size() else ""
		slot.cost = spell.pa_cost
		slot.tooltip_text = _spell_tooltip(spell)
		slot.pressed.connect(_on_spell_pressed.bind(spell.id))
		_spells_box.add_child(slot)
		_spell_buttons[spell.id] = slot


func _on_spell_pressed(spell_id: String) -> void:
	if map_view.mode == MapView.Mode.COMBAT:
		map_view.select_spell(spell_id)
	else:
		spell_info_requested.emit(spell_id)


# --- Réactions aux événements de la carte ------------------------------------------------------

func _on_combat_started() -> void:
	_result_panel.visible = false
	_turn_button.visible = true
	_order_label.visible = true
	_shown_spells.clear()
	var fighter := map_view.player_fighter()
	if fighter != null:
		_show_spells(fighter.spells)
	for menu: String in _menu_buttons:
		_menu_buttons[menu].disabled = true
	show_message("Placez-vous sur un cercle bleu, puis cliquez sur « Prêt »")
	_refresh()


# --- Combattant survolé ------------------------------------------------------------------------

## Survol d'une case en combat : un combattant vivant y est-il ? Ses infos remplacent les sorts.
func _on_hovered_cell_changed(cell: Vector2i, _description: String) -> void:
	var fighter: Fighter = null
	if map_view.mode == MapView.Mode.COMBAT and map_view.world.combat != null:
		fighter = map_view.world.combat.fighter_at(cell)
	_target_id = fighter.id if fighter != null else ""
	_show_target()


func _show_target() -> void:
	var fighter: Fighter = null
	if not _target_id.is_empty() and map_view.mode == MapView.Mode.COMBAT and map_view.world.combat != null:
		fighter = map_view.world.combat.get_fighter(_target_id)
	if fighter == null or not fighter.is_alive():
		_target_id = ""
		_target_box.visible = false
		_spells_box.visible = true
		return
	var shown := map_view.actor(fighter.id)  # Ce qu'affiche la carte (les animations peuvent être en retard).
	_target_name.text = fighter.display_name
	_target_name.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0) if fighter.team == Fighter.TEAM_PLAYERS else Color(1.0, 0.62, 0.5))
	_target_level.text = "Niveau %d" % fighter.level  # Pour un monstre, celui tiré à son apparition.
	# PA et PM : ce qu'il lui reste pendant son tour, sinon ce qu'il aura au prochain (PM retirés compris).
	var pa := fighter.next_turn_pa()
	var pm := fighter.next_turn_pm()
	if map_view.current_turn == fighter.id:
		pa = shown.get("pa", fighter.pa)
		pm = shown.get("pm", fighter.pm)
	_target_stats.text = "PV %d / %d%s\nPA %d / %d   ·   PM %d / %d" % [shown.get("hp", fighter.hp), fighter.max_hp,
		"   ·   bouclier %d" % shown["bouclier"] if int(shown.get("bouclier", 0)) > 0 else "",
		pa, fighter.max_pa, pm, fighter.max_pm]
	var states: PackedStringArray = []
	for state: Dictionary in fighter.states_snapshot():
		states.append(MapView.state_text(state))
	if not states.is_empty():
		_target_stats.text += "\n" + "   ·   ".join(states)
	for element: String in _target_resistances:
		var label: Label = _target_resistances[element]
		label.text = "%s %s" % [RESISTANCE_NAMES[element], percent_text(fighter.resistance(element))]
	_target_box.visible = true
	_spells_box.visible = false


## « +10 % », « -5 % », « +12,5 % », « 0 % ».
static func percent_text(value: float) -> String:
	if is_zero_approx(value):
		return "0 %"
	var text := "%+d" % roundi(value) if is_equal_approx(value, roundf(value)) else ("%+.1f" % value).replace(".", ",")
	return text + " %"


func _on_combat_ended(result: Dictionary) -> void:
	_turn_button.visible = false
	_order_label.visible = false
	var victory: bool = result["vainqueur"] == Fighter.TEAM_PLAYERS
	_result_title.text = "Victoire !" if victory else "Défaite…"
	var lines := PackedStringArray()
	if not victory:
		lines.append(MapView.wake_up_text(result.get("reveil", {})))
	if int(result["xp"]) > 0:
		lines.append("+%d points d'expérience" % result["xp"])
	for level: int in result.get("niveaux", []):
		lines.append("Niveau %d atteint !" % level)
	if int(result.get("ecus", 0)) > 0:
		lines.append("+%d écus" % result["ecus"])
	_result_detail.text = "\n".join(lines)
	_overload_label.visible = result.get("surcharge", false)
	for child in _loot_box.get_children():
		child.queue_free()
	for drop: Dictionary in result.get("butin", []):
		_loot_box.add_child(_loot_slot(drop))
	_loot_box.visible = not result.get("butin", []).is_empty()
	_result_panel.visible = true


## Case du butin : l'icône sur un fond de la couleur de la rareté, la quantité en bas, le nom en
## infobulle.
func _loot_slot(drop: Dictionary) -> Control:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(52, 52)
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	var quantity := int(drop["quantite"])
	slot.tooltip_text = "%s%s" % [drop["nom"], " ×%d" % quantity if quantity > 1 else ""]
	var style := _panel_style(Color(InventoryWindow.rarity_color(drop["rarete"]), 0.18))
	style.border_color = InventoryWindow.rarity_color(drop["rarete"]).darkened(0.3)
	style.set_border_width_all(1)
	style.set_content_margin_all(2)
	slot.add_theme_stylebox_override("panel", style)
	var icon := TextureRect.new()
	icon.texture = InventoryWindow.item_icon(drop.get("objet", ""))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon)
	if quantity > 1:
		var amount := _label(13, Color.WHITE)
		amount.text = str(quantity)
		amount.size_flags_horizontal = Control.SIZE_SHRINK_END
		amount.size_flags_vertical = Control.SIZE_SHRINK_END
		amount.add_theme_color_override("font_outline_color", Color.BLACK)
		amount.add_theme_constant_override("outline_size", 4)
		amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(amount)
	return slot


func _on_exploration_resumed() -> void:
	_target_id = ""
	_show_target()
	_turn_button.visible = false
	_order_label.visible = false
	for menu: String in _menu_buttons:
		_menu_buttons[menu].disabled = false
	_shown_spells.clear()
	_refresh_exploration()


func _on_continue_pressed() -> void:
	_result_panel.visible = false
	map_view.resume()


func _on_turn_button_pressed() -> void:
	if map_view.is_placement():
		map_view.request_start_fight()
	else:
		map_view.request_end_turn()


## Hors combat : PV, PA et PM du personnage, sorts qu'il aurait en combat.
func _refresh_exploration() -> void:
	if map_view == null or map_view.world == null or map_view.mode == MapView.Mode.COMBAT:
		return
	var world := map_view.world
	var sheet := world.character.sheet(world.data)
	_hp_gauge.show_values(int(sheet["pv"]), int(sheet["pv_max"]))
	_pa_gauge.show_values(int(sheet["pa"]), int(sheet["pa"]))
	_pm_gauge.show_values(int(sheet["pm"]), int(sheet["pm"]))
	_show_spells(character_spells(world))
	for spell_id: String in _spell_buttons:
		var slot: SpellSlot = _spell_buttons[spell_id]
		slot.usable = true
		slot.selected = false
		slot.queue_redraw()


## En combat : met à jour la barre à partir de ce qu'affiche la carte.
func _refresh() -> void:
	if map_view == null or map_view.mode != MapView.Mode.COMBAT:
		return
	if not _target_id.is_empty():
		_show_target()
	var player := map_view.actor(World.PLAYER_ID)
	if not player.is_empty():
		_hp_gauge.show_values(int(player["hp"]), int(player["max_hp"]))
		_pa_gauge.show_values(int(player["pa"]), int(player["pa"]))
		_pm_gauge.show_values(int(player["pm"]), int(player["pm"]))
	var player_turn := map_view.is_player_turn()
	if map_view.is_placement():
		_turn_button.text = "Prêt"
		_turn_button.disabled = map_view.is_busy()
	else:
		_turn_button.text = "Fin du tour"
		_turn_button.disabled = not player_turn
	var fighter := map_view.player_fighter()
	for spell_id: String in _spell_buttons:
		var slot: SpellSlot = _spell_buttons[spell_id]
		var spell: Spell = fighter.get_spell(spell_id) if fighter != null else null
		slot.usable = player_turn and spell != null and fighter.cast_blocker(spell).is_empty()
		slot.selected = spell_id == map_view.selected_spell
		slot.queue_redraw()
	_order_label.text = _order_text()


func _order_text() -> String:
	if map_view.turn_order.is_empty():
		return "Placement"
	var names: PackedStringArray = []
	for actor_id in map_view.turn_order:
		var data := map_view.actor(actor_id)
		if data.is_empty() or not data["alive"]:
			continue
		var label: String = data["name"]
		names.append("▶ %s" % label if actor_id == map_view.current_turn else label)
	return "  ·  ".join(names)


static func _spell_tooltip(spell: Spell) -> String:
	return "\n".join(SpellsWindow.describe(spell))


# --- Construction des contrôles ----------------------------------------------------------------

func _build() -> void:
	_bar = PanelContainer.new()
	_bar.anchor_left = 0.0
	_bar.anchor_right = 1.0
	_bar.anchor_top = 1.0
	_bar.anchor_bottom = 1.0
	_bar.offset_top = -BAR_HEIGHT
	_bar.add_theme_stylebox_override("panel", _panel_style(Color(0.13, 0.1, 0.07, 0.97)))
	add_child(_bar)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	_bar.add_child(row)

	_hp_gauge = _gauge("pv", Vector2(70, 72), "Points de vie")
	_pa_gauge = _gauge("pa", Vector2(56, 72), "Points d'action (PA) : pour lancer des sorts")
	_pm_gauge = _gauge("pm", Vector2(64, 72), "Points de mouvement (PM) : une case par point")
	for gauge in [_hp_gauge, _pa_gauge, _pm_gauge]:
		row.add_child(gauge)
	row.add_child(VSeparator.new())

	_spells_box = HBoxContainer.new()
	_spells_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_spells_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_spells_box.add_theme_constant_override("separation", 4)
	row.add_child(_spells_box)
	_build_target_box(row)

	_turn_button = Button.new()
	_turn_button.custom_minimum_size = Vector2(140, 50)
	_turn_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_turn_button.focus_mode = Control.FOCUS_NONE
	_turn_button.pressed.connect(_on_turn_button_pressed)
	row.add_child(_turn_button)

	row.add_child(VSeparator.new())
	var menus := GridContainer.new()
	menus.columns = 2
	menus.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(menus)
	for menu: Array in MENUS:
		var button := Button.new()
		button.icon = Art.texture(menu[1])
		button.expand_icon = true
		button.custom_minimum_size = Vector2(36, 34)
		button.tooltip_text = menu[2]
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func() -> void: menu_pressed.emit(menu[0]))
		menus.add_child(button)
		_menu_buttons[menu[0]] = button

	_order_label = _label(15, Color.WHITE)
	_order_label.anchor_left = 0.0
	_order_label.anchor_right = 1.0
	_order_label.offset_top = 12
	_order_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_order_label.offset_right = -16
	add_child(_order_label)

	_message_label = _label(22, Color(1, 0.95, 0.75))
	_message_label.anchor_left = 0.0
	_message_label.anchor_right = 1.0
	_message_label.anchor_top = 1.0
	_message_label.anchor_bottom = 1.0
	_message_label.offset_top = -BAR_HEIGHT - 44
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.modulate.a = 0.0
	add_child(_message_label)

	_result_panel = PanelContainer.new()
	_result_panel.anchor_left = 0.5
	_result_panel.anchor_right = 0.5
	_result_panel.anchor_top = 0.5
	_result_panel.anchor_bottom = 0.5
	_result_panel.offset_left = -190
	_result_panel.offset_right = 190
	_result_panel.offset_top = -150
	_result_panel.offset_bottom = 150
	_result_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_result_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.13, 0.1, 0.07, 0.96)))
	add_child(_result_panel)
	var result_box := VBoxContainer.new()
	result_box.alignment = BoxContainer.ALIGNMENT_CENTER
	result_box.add_theme_constant_override("separation", 12)
	_result_panel.add_child(result_box)
	_result_title = _label(30, Color(0.95, 0.76, 0.3))
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_detail = _label(16, Color.WHITE)
	_result_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var continue_button := Button.new()
	continue_button.text = "Continuer"
	continue_button.custom_minimum_size = Vector2(160, 40)
	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	continue_button.pressed.connect(_on_continue_pressed)
	_loot_box = HFlowContainer.new()
	_loot_box.alignment = FlowContainer.ALIGNMENT_CENTER
	_loot_box.add_theme_constant_override("h_separation", 6)
	_loot_box.add_theme_constant_override("v_separation", 6)
	result_box.add_child(_result_title)
	result_box.add_child(_result_detail)
	result_box.add_child(_loot_box)
	_overload_label = _label(15, Color(1.0, 0.55, 0.4))
	_overload_label.text = OVERLOAD_TEXT
	_overload_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overload_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_overload_label.custom_minimum_size = Vector2(340, 0)
	_overload_label.visible = false
	result_box.add_child(_overload_label)
	result_box.add_child(continue_button)


func _build_target_box(row: HBoxContainer) -> void:
	_target_box = HBoxContainer.new()
	_target_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_target_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_target_box.add_theme_constant_override("separation", 24)
	_target_box.visible = false
	row.add_child(_target_box)
	var identity := VBoxContainer.new()
	identity.alignment = BoxContainer.ALIGNMENT_CENTER
	_target_box.add_child(identity)
	_target_name = _label(18, Color(1.0, 0.62, 0.5))
	identity.add_child(_target_name)
	_target_level = _label(14, Color(0.85, 0.82, 0.72))
	identity.add_child(_target_level)
	_target_stats = _label(15, Color.WHITE)
	_target_stats.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_target_box.add_child(_target_stats)
	var resistances := GridContainer.new()
	resistances.columns = 3
	resistances.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	resistances.add_theme_constant_override("h_separation", 14)
	resistances.tooltip_text = "Résistances : dégâts reçus en moins (en négatif : en plus)"
	_target_box.add_child(resistances)
	for element: String in Spell.ELEMENTS:
		var label := _label(13, SpellsWindow.ELEMENT_COLORS.get(element, Color.WHITE))
		resistances.add_child(label)
		_target_resistances[element] = label


func _gauge(kind: String, minimum: Vector2, tooltip: String) -> Gauge:
	var gauge := Gauge.new()
	gauge.kind = kind
	gauge.custom_minimum_size = minimum
	gauge.tooltip_text = tooltip
	gauge.mouse_filter = Control.MOUSE_FILTER_PASS
	return gauge


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	return label


func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.55, 0.42, 0.22)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	return style
