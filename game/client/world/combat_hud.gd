class_name CombatHud
extends CanvasLayer
## Interface de combat, construite par le code : barre du bas (PV, PA, PM, sorts, bouton de
## tour), ordre de jeu, messages et écran de fin de combat.

const BAR_HEIGHT := 92
const SPELL_KEYS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6]

var map_view: MapView

var _bar: PanelContainer
var _name_label: Label
var _hp_label: Label
var _points_label: Label
var _spells_box: HBoxContainer
var _turn_button: Button
var _order_label: Label
var _message_label: Label
var _message_time := 0.0
var _result_panel: PanelContainer
var _result_title: Label
var _result_detail: Label
var _loot_box: VBoxContainer
var _spell_buttons: Dictionary = {}


func _ready() -> void:
	_build()
	_bar.visible = false
	_order_label.visible = false
	_result_panel.visible = false


func setup(p_map_view: MapView) -> void:
	map_view = p_map_view
	map_view.combat_started.connect(_on_combat_started)
	map_view.combat_state_changed.connect(_refresh)
	map_view.combat_message.connect(show_message)
	map_view.combat_ended.connect(_on_combat_ended)
	map_view.exploration_resumed.connect(_on_exploration_resumed)


func show_message(text: String) -> void:
	_message_label.text = text
	_message_label.modulate.a = 1.0
	_message_time = 1.8


func _process(delta: float) -> void:
	if _message_time > 0.0:
		_message_time -= delta
		_message_label.modulate.a = clampf(_message_time / 0.5, 0.0, 1.0)


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


# --- Réactions aux événements de la carte ------------------------------------------------------

func _on_combat_started() -> void:
	_result_panel.visible = false
	_bar.visible = true
	_order_label.visible = true
	for child in _spells_box.get_children():
		child.queue_free()
	_spell_buttons.clear()
	var fighter := map_view.player_fighter()
	if fighter != null:
		for i in fighter.spells.size():
			var spell := fighter.spells[i]
			var button := Button.new()
			button.text = "%d. %s\n%d PA" % [i + 1, spell.display_name, spell.pa_cost]
			button.tooltip_text = _spell_tooltip(spell)
			button.custom_minimum_size = Vector2(118, 56)
			button.focus_mode = Control.FOCUS_NONE
			button.pressed.connect(map_view.select_spell.bind(spell.id))
			_spells_box.add_child(button)
			_spell_buttons[spell.id] = button
	show_message("Placez-vous sur un cercle bleu, puis cliquez sur « Prêt »")
	_refresh()


func _on_combat_ended(result: Dictionary) -> void:
	_bar.visible = false
	_order_label.visible = false
	var victory: bool = result["vainqueur"] == Fighter.TEAM_PLAYERS
	_result_title.text = "Victoire !" if victory else "Défaite…"
	var lines := PackedStringArray()
	if not victory:
		lines.append("Vous vous réveillez au point de départ, un peu groggy.")
	if int(result["xp"]) > 0:
		lines.append("+%d points d'expérience" % result["xp"])
	for level: int in result.get("niveaux", []):
		lines.append("Niveau %d atteint !" % level)
	if int(result.get("ecus", 0)) > 0:
		lines.append("+%d écus" % result["ecus"])
	_result_detail.text = "\n".join(lines)
	for child in _loot_box.get_children():
		child.queue_free()
	for drop: Dictionary in result.get("butin", []):
		var label := Label.new()
		label.text = "%s%s%s" % [drop["nom"], " ×%d" % drop["quantite"] if int(drop["quantite"]) > 1 else "",
			"  (inventaire plein, perdu)" if drop["perdu"] else ""]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", InventoryWindow.rarity_color(drop["rarete"]))
		_loot_box.add_child(label)
	_loot_box.visible = not result.get("butin", []).is_empty()
	_result_panel.visible = true


func _on_exploration_resumed() -> void:
	_bar.visible = false
	_order_label.visible = false


func _on_continue_pressed() -> void:
	_result_panel.visible = false
	map_view.resume()


func _on_turn_button_pressed() -> void:
	if map_view.is_placement():
		map_view.request_start_fight()
	else:
		map_view.request_end_turn()


## Met à jour la barre à partir de ce qu'affiche la carte.
func _refresh() -> void:
	if map_view == null or map_view.mode != MapView.Mode.COMBAT:
		return
	var player := map_view.actor(World.PLAYER_ID)
	if not player.is_empty():
		_name_label.text = player["name"]
		_hp_label.text = "PV %d / %d" % [player["hp"], player["max_hp"]]
		_points_label.text = "PA %d    PM %d" % [player["pa"], player["pm"]]
	var player_turn := map_view.is_player_turn()
	if map_view.is_placement():
		_turn_button.text = "Prêt"
		_turn_button.disabled = map_view.is_busy()
	else:
		_turn_button.text = "Fin du tour"
		_turn_button.disabled = not player_turn
	var fighter := map_view.player_fighter()
	for spell_id: String in _spell_buttons:
		var button: Button = _spell_buttons[spell_id]
		var spell: Spell = fighter.get_spell(spell_id) if fighter != null else null
		var usable := player_turn and spell != null and fighter.cast_blocker(spell).is_empty()
		button.disabled = not usable
		button.modulate = Color(1, 0.85, 0.4) if spell_id == map_view.selected_spell else Color.WHITE
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


func _spell_tooltip(spell: Spell) -> String:
	var lines: PackedStringArray = [spell.display_name]
	if not spell.description.is_empty():
		lines.append(spell.description)
	var reach := "soi-même" if spell.range_max == 0 else "%d à %d cases" % [spell.range_min, spell.range_max]
	lines.append("Coût : %d PA — Portée : %s" % [spell.pa_cost, reach])
	for effect in spell.effects:
		if effect["type"] == Spell.EFFECT_DAMAGE:
			lines.append("Dégâts %s : %d à %d" % [effect["element"], effect["min"], effect["max"]])
		else:
			lines.append("Soin : %d à %d" % [effect["min"], effect["max"]])
	if spell.zone_type == Spell.ZONE_CIRCLE:
		lines.append("Zone : cercle de %d" % spell.zone_size)
	if spell.casts_per_turn > 0:
		lines.append("%d fois par tour" % spell.casts_per_turn)
	if spell.cooldown > 0:
		lines.append("Relance : tous les %d tours" % spell.cooldown)
	return "\n".join(lines)


# --- Construction des contrôles ----------------------------------------------------------------

func _build() -> void:
	_bar = PanelContainer.new()
	_bar.anchor_left = 0.0
	_bar.anchor_right = 1.0
	_bar.anchor_top = 1.0
	_bar.anchor_bottom = 1.0
	_bar.offset_top = -BAR_HEIGHT
	_bar.add_theme_stylebox_override("panel", _panel_style(Color(0.13, 0.1, 0.07, 0.92)))
	add_child(_bar)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	_bar.add_child(row)

	var stats := VBoxContainer.new()
	stats.custom_minimum_size = Vector2(170, 0)
	row.add_child(stats)
	_name_label = _label(18, Color(0.95, 0.76, 0.3))
	_hp_label = _label(16, Color(0.95, 0.5, 0.45))
	_points_label = _label(16, Color(0.75, 0.85, 1.0))
	stats.add_child(_name_label)
	stats.add_child(_hp_label)
	stats.add_child(_points_label)

	_spells_box = HBoxContainer.new()
	_spells_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_spells_box.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(_spells_box)

	_turn_button = Button.new()
	_turn_button.custom_minimum_size = Vector2(150, 56)
	_turn_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_turn_button.focus_mode = Control.FOCUS_NONE
	_turn_button.pressed.connect(_on_turn_button_pressed)
	row.add_child(_turn_button)

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
	_loot_box = VBoxContainer.new()
	result_box.add_child(_result_title)
	result_box.add_child(_result_detail)
	result_box.add_child(_loot_box)
	result_box.add_child(continue_button)


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
