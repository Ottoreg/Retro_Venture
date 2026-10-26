class_name QuestsWindow
extends CanvasLayer
## Journal des quêtes (touche Q) : les quêtes en cours (la suivie d'abord) puis terminées ; pour
## celle choisie, son donneur, son texte, l'étape, les objectifs cochés, les récompenses, et
## « Suivre » (affichée dans le bandeau du haut). Les noms des PNJ, cartes et zones du texte et des
## objectifs sont des liens qui posent un repère sur la carte (`QuestLinks`).

## Clic sur un nom du texte : repère { carte, nom } à poser.
signal pin_requested(pin: Dictionary)

const CATEGORY_NAMES := {"tutoriel": "Tutoriel", "principale": "Quête principale", "secondaire": "Quête secondaire"}
const DONE_COLOR := Color(0.55, 0.75, 0.45)

var map_view: MapView
var _panel: PanelContainer
var _list: ItemList
var _title: Label
var _details: RichTextLabel
var _objectives: RichTextLabel
var _rewards: Label
var _track: Button
## Ids des quêtes de la liste, dans l'ordre ("" pour les intertitres).
var _ids: Array[String] = []
var _selected := ""
var _journal: Dictionary = {}


func _ready() -> void:
	_build()
	_panel.visible = false


func setup(p_map_view: MapView) -> void:
	map_view = p_map_view
	map_view.quests_changed.connect(func(_journal_data: Dictionary) -> void: refresh())
	map_view.combat_started.connect(func() -> void: _panel.visible = false)


func toggle() -> void:
	if map_view == null or map_view.mode == MapView.Mode.COMBAT:
		return
	_panel.visible = not _panel.visible
	refresh()


func is_open() -> bool:
	return _panel.visible


## Texte des récompenses d'une quête : « 120 XP, 30 brumes, Bottes de marche ».
static func rewards_text(rewards: Dictionary) -> String:
	var parts: PackedStringArray = []
	if int(rewards.get("xp", 0)) > 0:
		parts.append("%d XP" % rewards["xp"])
	if int(rewards.get("ecus", 0)) > 0:
		parts.append("%d brumes" % rewards["ecus"])
	for item: Dictionary in rewards.get("objets", []):
		parts.append(item["nom"] if int(item["quantite"]) == 1 else "%d %s" % [item["quantite"], item["nom"]])
	return ", ".join(parts) if not parts.is_empty() else "—"


## Ligne du journal par id (pour les tests).
func select(quest_id: String) -> void:
	_selected = quest_id
	refresh()


func refresh() -> void:
	if map_view == null or map_view.world == null or not _panel.visible:
		return
	_journal = map_view.world.quest_book.sheet()
	if _selected.is_empty() or _entry(_selected).is_empty():
		_selected = _journal["suivie"] if not str(_journal["suivie"]).is_empty() else ""
		if _selected.is_empty() and not _journal["en_cours"].is_empty():
			_selected = _journal["en_cours"][0]["id"]
	_list.clear()
	_ids.clear()
	_section("En cours (%d)" % _journal["en_cours"].size())
	for entry: Dictionary in _journal["en_cours"]:
		var mark := "» " if entry["id"] == _journal["suivie"] else "   "
		_add(entry, mark + entry["nom"], UiTheme.TEXT)
	if not _journal["terminees"].is_empty():
		_section("Terminées (%d)" % _journal["terminees"].size())
		for entry: Dictionary in _journal["terminees"]:
			_add(entry, "   " + entry["nom"], DONE_COLOR)
	_show_details()


func _section(text: String) -> void:
	var index := _list.add_item(text)
	_list.set_item_selectable(index, false)
	_list.set_item_custom_fg_color(index, UiTheme.GOLD)
	_ids.append("")


func _add(entry: Dictionary, text: String, color: Color) -> void:
	var index := _list.add_item(text)
	_list.set_item_custom_fg_color(index, color)
	_ids.append(entry["id"])
	if entry["id"] == _selected:
		_list.select(index)


func _entry(quest_id: String) -> Dictionary:
	for key in ["en_cours", "terminees"]:
		for entry: Dictionary in _journal.get(key, []):
			if entry["id"] == quest_id:
				return entry
	return {}


func _show_details() -> void:
	var entry := _entry(_selected)
	_track.visible = entry.has("objectifs")
	if entry.is_empty():
		_title.text = "Aucune quête"
		_details.text = "Parlez aux personnages marqués d'un « ! » pour obtenir des quêtes."
		_objectives.text = ""
		_rewards.text = ""
		return
	_title.text = entry["nom"]
	var category: String = CATEGORY_NAMES.get(entry["categorie"], "")
	if int(entry["acte"]) > 0:
		category += ", acte %d" % entry["acte"]
	var lines: PackedStringArray = ["%s — niveau %d — donnée par %s" % [category, entry["niveau"], entry["donneur"]]]
	if not str(entry["description"]).is_empty():
		lines.append(entry["description"])
	_details.text = QuestLinks.linkify("\n\n".join(lines), map_view.world)
	if entry.has("objectifs"):
		var objectives: PackedStringArray = ["Étape %d / %d" % [entry["etape"], entry["etapes"]]]
		for objective: Dictionary in entry["objectifs"]:
			objectives.append(("√  " if objective["fait"] else "•  ") + objective["texte"])
		_objectives.text = QuestLinks.linkify("\n".join(objectives), map_view.world)
		var tracked: bool = entry["id"] == _journal["suivie"]
		_track.text = "Ne plus suivre" if tracked else "Suivre"
	else:
		_objectives.text = "Terminée."
	_rewards.text = "Récompenses : " + rewards_text(entry["recompenses"])


func _on_item_selected(index: int) -> void:
	if index >= 0 and index < _ids.size() and not _ids[index].is_empty():
		_selected = _ids[index]
		_show_details()


func _on_track_pressed() -> void:
	var tracked: bool = _selected == _journal.get("suivie", "")
	map_view.send_command({"type": Protocol.CMD_QUEST_TRACK, "entite": map_view.world.player_id, "quete": "" if tracked else _selected})


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_Q:
		toggle()
		get_viewport().set_input_as_handled()


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.add_theme_stylebox_override("panel", UiTheme.window_style())
	_panel.custom_minimum_size = Vector2(760, 440)
	add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var heading := Label.new()
	heading.text = "Journal des quêtes"
	heading.add_theme_font_size_override("font_size", 22)
	heading.add_theme_color_override("font_color", UiTheme.GOLD)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var close_button := Button.new()
	close_button.text = "×"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(toggle)
	header.add_child(close_button)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)
	column.add_child(row)
	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(270, 360)
	_list.focus_mode = Control.FOCUS_NONE
	_list.item_selected.connect(_on_item_selected)
	row.add_child(_list)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 10)
	row.add_child(details)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 20)
	_title.add_theme_color_override("font_color", UiTheme.GOLD)
	details.add_child(_title)
	_details = QuestLinks.make_label(14, UiTheme.TEXT, pin_requested.emit)
	_objectives = QuestLinks.make_label(14, UiTheme.TEXT, pin_requested.emit)
	_rewards = Label.new()
	_rewards.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rewards.add_theme_font_size_override("font_size", 14)
	for label: Control in [_details, _objectives, _rewards]:
		label.custom_minimum_size = Vector2(420, 0)
		details.add_child(label)
	_track = Button.new()
	_track.custom_minimum_size = Vector2(160, 34)
	_track.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_track.focus_mode = Control.FOCUS_NONE
	_track.pressed.connect(_on_track_pressed)
	details.add_child(_track)
