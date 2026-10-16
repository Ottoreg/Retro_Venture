class_name QuestDialog
extends CanvasLayer
## Proposition de quête d'un PNJ : son texte, les objectifs de la première étape, les récompenses,
## et « Accepter » / « Plus tard ».

var map_view: MapView
var _quest_id := ""
var _backdrop: ColorRect
var _panel: PanelContainer
var _npc: Label
var _title: Label
var _text: Label
var _objectives: Label
var _rewards: Label
var _accept: Button


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
	_title.text = "%s  (niveau %d)" % [event["titre"], event["niveau"]]
	_text.text = "\n\n".join(PackedStringArray(event["repliques"]))
	var lines: PackedStringArray = []
	for objective: Dictionary in event["objectifs"]:
		lines.append("•  " + objective["texte"])
	_objectives.text = "\n".join(lines)
	_rewards.text = QuestsWindow.rewards_text(event["recompenses"])
	_set_visible(true)


func close() -> void:
	_set_visible(false)


func is_open() -> bool:
	return _panel.visible


func quest_id() -> String:
	return _quest_id


func accept() -> void:
	close()
	map_view.send_command({"type": Protocol.CMD_QUEST_ACCEPT, "entite": World.PLAYER_ID, "quete": _quest_id})


func later() -> void:
	close()
	map_view.send_command({"type": Protocol.CMD_QUEST_DECLINE, "entite": World.PLAYER_ID, "quete": _quest_id})


func _set_visible(shown: bool) -> void:
	_panel.visible = shown
	_backdrop.visible = shown


func _build() -> void:
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0, 0, 0, 0.3)
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_backdrop)
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.add_theme_stylebox_override("panel", UiTheme.window_style())
	_panel.custom_minimum_size = Vector2(460, 0)
	add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_panel.add_child(column)
	_npc = _label(14, UiTheme.TEXT_DIM)
	column.add_child(_npc)
	_title = _label(20, UiTheme.GOLD)
	column.add_child(_title)
	_text = _label(15, UiTheme.TEXT)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(440, 0)
	column.add_child(_text)
	column.add_child(_label(15, UiTheme.GOLD, "Objectifs"))
	_objectives = _label(14, UiTheme.TEXT)
	_objectives.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_objectives)
	column.add_child(_label(15, UiTheme.GOLD, "Récompenses"))
	_rewards = _label(14, UiTheme.TEXT)
	_rewards.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_rewards)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	column.add_child(buttons)
	_accept = Button.new()
	_accept.text = "Accepter"
	_accept.custom_minimum_size = Vector2(150, 38)
	_accept.pressed.connect(accept)
	buttons.add_child(_accept)
	var later_button := Button.new()
	later_button.text = "Plus tard"
	later_button.custom_minimum_size = Vector2(150, 38)
	later_button.pressed.connect(later)
	buttons.add_child(later_button)


func _label(font_size: int, color: Color, text := "") -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
