extends Control
## Écran de création du personnage : nom, race (un camp chacune), Voie, aperçu et récapitulatif.

const WORLD_SCENE := "res://client/world/world.tscn"
const MENU_SCENE := "res://client/main/main.tscn"
const RACE_ORDER := ["humain", "gobelin", "elfe"]
const VOIE_ORDER := ["guerrier", "rodeur", "arcaniste", "theologue"]
const CAMP_NAMES := {"allie": "Allié", "ennemi": "Ennemi", "neutre": "Neutre"}
const GOLD := Color(0.95, 0.76, 0.3)

## Aperçu du personnage : le personnage articulé du jeu, en grand, qui respire.
class Preview extends Control:
	var look: Dictionary = {}
	var time := 0.0

	func _process(delta: float) -> void:
		time += delta
		queue_redraw()

	func _draw() -> void:
		if look.is_empty():
			return
		Rig.draw(self, look, Vector2(size.x / 2.0, size.y - 20.0), {"facing": 1.0, "temps": time, "zoom": 2.6})


var data: GameData
var race_id := "humain"
var voie_id := "guerrier"

var _name_edit: LineEdit
var _race_buttons := {}
var _voie_buttons := {}
var _race_text: Label
var _voie_text: Label
var _summary: Label
var _error: Label
var _preview: Preview


func _ready() -> void:
	UiTheme.apply(get_tree())
	data = GameData.load_all()
	_build()
	_select_race(RACE_ORDER[0])
	_select_voie(VOIE_ORDER[0])
	_name_edit.grab_focus()


## Personnage correspondant aux choix actuels.
func build_character() -> Character:
	return Character.create(_name_edit.text, race_id, voie_id)


## Raison pour laquelle on ne peut pas encore commencer, ou "".
func validation_error() -> String:
	return Character.name_error(_name_edit.text)


func _select_race(id: String) -> void:
	race_id = id
	for key: String in _race_buttons:
		_race_buttons[key].button_pressed = key == id
	var race: Dictionary = data.races.get(id, {})
	var lines: PackedStringArray = [
		str(race.get("description", "")),
		"Camp : %s" % CAMP_NAMES.get(race.get("camp", ""), "?"),
		"Bonus : %s" % _bonus_text(race.get("bonus", {})),
	]
	var passive: Dictionary = race.get("passif", {})
	if not passive.is_empty():
		lines.append("Passif — %s : %s" % [passive.get("nom", ""), passive.get("description", "")])
	var spell: Spell = data.spells.get(race.get("sort", ""))
	if spell != null:
		lines.append("Sort racial — %s : %s" % [spell.display_name, spell.description])
	_race_text.text = "\n".join(lines)
	_refresh()


func _select_voie(id: String) -> void:
	voie_id = id
	for key: String in _voie_buttons:
		_voie_buttons[key].button_pressed = key == id
	var voie: Dictionary = data.voies.get(id, {})
	_voie_text.text = str(voie.get("description", ""))
	_refresh()


func _refresh() -> void:
	if _preview == null:
		return
	_preview.look = Rig.player_look(race_id, voie_id, data)
	_preview.queue_redraw()
	var fighter := data.create_character_fighter(build_character(), "apercu")
	if fighter == null:
		_summary.text = ""
		return
	var stats := PackedStringArray()
	for stat_name in Character.STATS:
		var value := fighter.stat(stat_name)
		if value != 0:
			stats.append("%s %d" % [Character.STAT_NAMES[stat_name], value])
	var lines: PackedStringArray = [
		"PV %d    PA %d    PM %d    Initiative %d" % [fighter.max_hp, fighter.max_pa, fighter.max_pm, fighter.initiative],
		"Caractéristiques : %s" % (", ".join(stats) if not stats.is_empty() else "aucune"),
		"",
		"Sorts :",
	]
	for spell in fighter.spells:
		var reach := "soi" if spell.range_max == 0 else "%d-%d" % [spell.range_min, spell.range_max]
		lines.append("• %s (%d PA, portée %s)" % [spell.display_name, spell.pa_cost, reach])
	_summary.text = "\n".join(lines)
	_error.text = ""


func _bonus_text(bonus: Dictionary) -> String:
	var parts := PackedStringArray()
	for stat_name: String in bonus:
		parts.append("%s +%d" % [Character.STAT_NAMES.get(stat_name, stat_name), int(bonus[stat_name])])
	return ", ".join(parts) if not parts.is_empty() else "aucun"


func _on_start_pressed() -> void:
	var error := validation_error()
	if not error.is_empty():
		_error.text = error
		_name_edit.grab_focus()
		return
	Session.new_character = build_character()
	Session.continue_game = false
	get_tree().change_scene_to_file(WORLD_SCENE)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)


# --- Construction des contrôles ----------------------------------------------------------------

func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color(0.168627, 0.129412, 0.0941176)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	column.add_child(_label("Création du personnage", 30, GOLD))

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 28)
	column.add_child(row)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 8)
	row.add_child(left)
	left.add_child(_label("Nom", 18, GOLD))
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Nom du personnage"
	_name_edit.max_length = Character.NAME_MAX_LENGTH
	_name_edit.custom_minimum_size = Vector2(320, 0)
	_name_edit.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_name_edit.text_submitted.connect(func(_text: String) -> void: _on_start_pressed())
	left.add_child(_name_edit)

	left.add_child(_label("Race", 18, GOLD))
	left.add_child(_choice_row(RACE_ORDER, data.races, _race_buttons, _select_race, true))
	_race_text = _wrapped_label()
	left.add_child(_race_text)

	left.add_child(_label("Classe (Voie)", 18, GOLD))
	left.add_child(_choice_row(VOIE_ORDER, data.voies, _voie_buttons, _select_voie, false))
	_voie_text = _wrapped_label()
	left.add_child(_voie_text)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(380, 0)
	right.add_theme_constant_override("separation", 8)
	row.add_child(right)
	_preview = Preview.new()
	_preview.custom_minimum_size = Vector2(380, 210)
	right.add_child(_preview)
	_summary = _wrapped_label()
	right.add_child(_summary)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	column.add_child(footer)
	_error = _label("", 16, Color(1, 0.45, 0.4))
	_error.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var save_summary := SaveGame.summary()
	if not save_summary.is_empty():
		var warning := _label("Attention : la partie en cours (%s) sera remplacée." % save_summary, 14, Color(0.85, 0.7, 0.5))
		column.add_child(warning)
		column.move_child(warning, column.get_child_count() - 2)
	footer.add_child(_error)
	var back := Button.new()
	back.text = "Retour"
	back.custom_minimum_size = Vector2(120, 42)
	back.pressed.connect(_on_back_pressed)
	footer.add_child(back)
	var start := Button.new()
	start.text = "Commencer l'aventure"
	start.custom_minimum_size = Vector2(240, 42)
	start.pressed.connect(_on_start_pressed)
	footer.add_child(start)


func _choice_row(order: Array, entries: Dictionary, buttons: Dictionary, on_select: Callable, show_camp: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for id: String in order:
		if not entries.has(id):
			continue
		var entry: Dictionary = entries[id]
		var button := Button.new()
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(150, 46)
		button.text = str(entry.get("nom", id))
		if show_camp:
			button.text += "\n(%s)" % CAMP_NAMES.get(entry.get("camp", ""), "?")
		button.pressed.connect(on_select.bind(id))
		row.add_child(button)
		buttons[id] = button
	return row


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _wrapped_label() -> Label:
	var label := _label("", 15, Color(0.92, 0.9, 0.85))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(300, 0)
	return label
