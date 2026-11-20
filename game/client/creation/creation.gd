extends Control
## Écran de création du personnage : nom, race (un camp chacune) dans un carrousel façon Dofus Rétro
## (la race choisie en grand, la précédente et la suivante en petit sur les côtés), Voie et récapitulatif.

const WORLD_SCENE := "res://client/world/world.tscn"
const MENU_SCENE := "res://client/main/main.tscn"
## Races du carrousel, par camp ; les variantes (`variante_de`, Arkhés) se choisissent sous le nom.
const RACE_ORDER := ["humain", "nain", "geant", "gobelin", "orc", "squelette", "elfe", "arkhe"]
const VOIE_ORDER := ["guerrier", "rodeur", "arcaniste", "theologue", "chronomancien", "ombre", "demoniste"]
const CAMP_NAMES := {"allie": "Allié", "ennemi": "Ennemi", "neutre": "Neutre"}
const GOLD := Color(0.95, 0.76, 0.3)

## Aperçu d'un personnage du jeu qui respire : en grand au centre du carrousel, en petit et assombri
## sur les côtés (un clic y choisit la race).
class Preview extends Control:
	var look: Dictionary = {}
	var time := 0.0
	var zoom := 2.2
	var tint := Color.WHITE

	func _process(delta: float) -> void:
		time += delta
		queue_redraw()

	func _draw() -> void:
		if look.is_empty():
			return
		Rig.draw(self, look, Vector2(size.x / 2.0, size.y - 20.0), {"facing": 1.0, "cap": 0, "temps": time, "zoom": zoom}, tint)


var data: GameData
var race_id := "humain"
var voie_id := "guerrier"

var _name_edit: LineEdit
var _race_name: Label
var _variant_row: HBoxContainer
var _voie_buttons := {}
var _race_text: Label
var _voie_text: Label
var _summary: Label
var _error: Label
var _preview: Preview
var _side_previews: Array[Preview] = []


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
	var race: Dictionary = data.races.get(id, {})
	_race_name.text = "%s %s(%s)" % [race.get("nom", id), race.get("variante", "") + " " if race.has("variante") else "", CAMP_NAMES.get(race.get("camp", ""), "?")]
	for child in _variant_row.get_children():
		_variant_row.remove_child(child)
		child.queue_free()
	var variants := _variants(_base_race(id))
	for variant: String in variants if variants.size() > 1 else []:
		var button := Button.new()
		button.toggle_mode = true
		button.button_pressed = variant == id
		button.text = str(data.races[variant].get("variante", variant))
		button.custom_minimum_size = Vector2(90, 32)
		button.pressed.connect(_select_race.bind(variant))
		_variant_row.add_child(button)
	var lines: PackedStringArray = [str(race.get("description", ""))]
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
	for i in _side_previews.size():
		_side_previews[i].look = Rig.player_look(_race_beside(1 if i else -1), voie_id, data)
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


## Race voisine de la race choisie dans le carrousel (`step` −1 : précédente, 1 : suivante), en boucle.
func _race_beside(step: int) -> String:
	return RACE_ORDER[posmod(RACE_ORDER.find(_base_race(race_id)) + step, RACE_ORDER.size())]


## Race de base d'une variante (l'Arkhé Givre → l'Arkhé), elle-même sinon.
func _base_race(id: String) -> String:
	return data.races.get(id, {}).get("variante_de", id)


## Variantes d'une race de base, elle comprise en premier (remplacent le choix mâle / femelle).
func _variants(base: String) -> Array:
	var others := data.races.keys().filter(func(id: String) -> bool: return data.races[id].get("variante_de") == base)
	others.sort()
	return [base] + others


func _on_start_pressed() -> void:
	var error := validation_error()
	if not error.is_empty():
		_error.text = error
		_name_edit.grab_focus()
		return
	if Session.online_connection != null:
		# En ligne : le serveur crée le personnage (pseudo unique), l'écran de connexion attend.
		Session.online_connection.create_character(_name_edit.text.strip_edges(), race_id, voie_id)
		get_tree().change_scene_to_file(OnlineScreen.SCENE)
		return
	Session.new_character = build_character()
	Session.continue_game = Session.adding_hero
	get_tree().change_scene_to_file(WORLD_SCENE)


func _on_back_pressed() -> void:
	if Session.online_connection != null:
		Session.online_connection.close()
		Session.online_connection = null
		get_tree().change_scene_to_file(OnlineScreen.SCENE)
		return
	if Session.adding_hero:
		Session.adding_hero = false  # Mode héros : retour à la partie, sans nouveau héros.
		get_tree().change_scene_to_file(WORLD_SCENE)
		return
	get_tree().change_scene_to_file(MENU_SCENE)


## En ligne, la connexion reste ouverte pendant la création (elle n'attend rien de plus).
func _process(_delta: float) -> void:
	if Session.online_connection != null:
		Session.online_connection.poll()


# --- Construction des contrôles ----------------------------------------------------------------

func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = UiTheme.BACKDROP
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
	left.add_child(_carousel())

	left.add_child(_label("Classe (Voie)", 18, GOLD))
	left.add_child(_choice_row(VOIE_ORDER, data.voies, _voie_buttons, _select_voie))
	_voie_text = _wrapped_label()
	left.add_child(_voie_text)

	var scroll := ScrollContainer.new()  # Race, classe et sorts : tout se lit en faisant défiler.
	scroll.custom_minimum_size = Vector2(340, 0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(scroll)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	scroll.add_child(right)
	_race_text = _wrapped_label()
	right.add_child(_race_text)
	_summary = _wrapped_label()
	right.add_child(_summary)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	column.add_child(footer)
	_error = _label("", 16, Color(1, 0.45, 0.4))
	_error.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var save_summary := SaveGame.summary()
	if not save_summary.is_empty() and not Session.adding_hero:
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


## Carrousel des races : flèches, race précédente, race choisie en grand avec son nom, race suivante.
func _carousel() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	var center := VBoxContainer.new()
	_preview = Preview.new()
	_preview.custom_minimum_size = Vector2(240, 165)
	center.add_child(_preview)
	_race_name = _label("", 20, GOLD)
	_race_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_race_name)
	_variant_row = HBoxContainer.new()
	_variant_row.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(_variant_row)
	for step in [-1, 1]:
		var arrow := Button.new()
		arrow.text = "‹" if step < 0 else "›"
		arrow.custom_minimum_size = Vector2(40, 80)
		arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		arrow.pressed.connect(func() -> void: _select_race(_race_beside(step)))
		var side := Preview.new()
		side.zoom = 1.3
		side.tint = Color(0.55, 0.55, 0.6, 0.7)
		side.custom_minimum_size = Vector2(110, 150)
		side.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		side.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		side.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_select_race(_race_beside(step)))
		_side_previews.append(side)
		for node: Control in ([arrow, side] if step < 0 else [side, arrow]):
			row.add_child(node)
		if step < 0:
			row.add_child(center)
	return row


func _choice_row(order: Array, entries: Dictionary, buttons: Dictionary, on_select: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for id: String in order:
		if not entries.has(id):
			continue
		var entry: Dictionary = entries[id]
		var button := Button.new()
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(128, 46)
		button.text = str(entry.get("nom", id))
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
