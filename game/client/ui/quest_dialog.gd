class_name QuestDialog
extends CanvasLayer
## Proposition de quête d'un PNJ : son texte, les objectifs de la première étape, les récompenses,
## et « Accepter » / « Plus tard ». Les noms des PNJ, cartes et zones sont des liens qui posent un
## repère sur la carte (`QuestLinks`).

## Clic sur un nom du texte : repère { carte, nom } à poser.
signal pin_requested(pin: Dictionary)

var map_view: MapView
var _quest_id := ""
var _backdrop: ColorRect
var _panel: PanelContainer
var _npc: Label
var _portrait: FriendsWindow.FriendPortrait
var _title: Label
var _text: RichTextLabel
var _objectives: RichTextLabel
var _rewards: Label
var _accept: Button
## Mode héros : accepter aussi pour les autres héros de l'équipe.
var _accept_team: Button


func _ready() -> void:
	_build()
	_set_visible(false)


func setup(p_map_view: MapView) -> void:
	map_view = p_map_view
	map_view.quest_offered.connect(open)
	map_view.combat_started.connect(close)
	map_view.map_changed.connect(close)


func open(event: Dictionary) -> void:
	_quest_id = event["quete"]
	_npc.text = event["nom"]
	var spec: Dictionary = Art.manifest().get("pnj", {}).get(event.get("pnj", ""), {})
	_portrait.look = Rig.look(spec["rig"], spec.get("couleurs", {}), spec.get("arme", ""), spec.get("accessoires", [])) if spec.has("rig") else {}
	_portrait.queue_redraw()
	_title.text = event["titre"]
	_text.text = QuestLinks.linkify("\n\n".join(PackedStringArray(event["repliques"])), map_view.world)
	var lines: PackedStringArray = []
	for objective: Dictionary in event["objectifs"]:
		lines.append("•  " + objective["texte"])
	_objectives.text = QuestLinks.linkify("\n".join(lines), map_view.world)
	_rewards.text = QuestsWindow.rewards_text(event["recompenses"])
	_set_visible(true)
	_accept_team.visible = map_view.world.heroes.size() > 1


func close() -> void:
	_set_visible(false)


func is_open() -> bool:
	return _panel.visible


func quest_id() -> String:
	return _quest_id


func accept(team := false) -> void:
	close()
	map_view.send_command({"type": Protocol.CMD_QUEST_ACCEPT, "entite": map_view.world.player_id, "quete": _quest_id, "equipe": team})


func later() -> void:
	close()
	map_view.send_command({"type": Protocol.CMD_QUEST_DECLINE, "entite": map_view.world.player_id, "quete": _quest_id})


func _set_visible(shown: bool) -> void:
	_panel.visible = shown
	_backdrop.visible = shown


func _build() -> void:
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0, 0, 0, 0.3)
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_backdrop)
	var frame := UiTheme.window_frame(self, "", later, false)
	_panel = frame.panel
	var column: VBoxContainer = frame.column
	_npc = frame.title
	# Le PNJ en pied à gauche ; à droite le titre, puis le texte, les objectifs et les récompenses qui
	# défilent : la fenêtre garde sa taille, les boutons restent visibles.
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 20)
	column.add_child(row)
	_portrait = FriendsWindow.FriendPortrait.new()
	_portrait.online = true
	_portrait.custom_minimum_size = Vector2(220, 300)
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(_portrait)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	_title = _label(20, UiTheme.GOLD)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_title)
	var text_box := VBoxContainer.new()
	text_box.add_theme_constant_override("separation", 8)
	right.add_child(UiTheme.scroll_area(text_box))
	_text = QuestLinks.make_label(15, UiTheme.TEXT, pin_requested.emit)
	text_box.add_child(_text)
	text_box.add_child(_label(15, UiTheme.GOLD, "Objectifs"))
	_objectives = QuestLinks.make_label(14, UiTheme.TEXT, pin_requested.emit)
	text_box.add_child(_objectives)
	text_box.add_child(_label(15, UiTheme.GOLD, "Récompenses"))
	_rewards = _label(14, UiTheme.TEXT)
	_rewards.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_box.add_child(_rewards)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 12)
	column.add_child(buttons)
	_accept = Button.new()
	_accept.text = "Accepter"
	_accept.custom_minimum_size = Vector2(130, 38)
	_accept.pressed.connect(accept)
	buttons.add_child(_accept)
	_accept_team = Button.new()
	_accept_team.text = "Pour l'équipe"
	_accept_team.custom_minimum_size = Vector2(130, 38)
	_accept_team.pressed.connect(accept.bind(true))
	buttons.add_child(_accept_team)
	var later_button := Button.new()
	later_button.text = "Plus tard"
	later_button.custom_minimum_size = Vector2(130, 38)
	later_button.pressed.connect(later)
	buttons.add_child(later_button)


func _label(font_size: int, color: Color, text := "") -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
