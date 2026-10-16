class_name QuestTracker
extends CanvasLayer
## Suivi de la quête choisie, sous la minicarte (en exploration) : son nom et les objectifs de
## l'étape, cochés au fur et à mesure, en petit pour ne pas cacher la carte. Le bouton « – » le
## replie (il ne reste que le nom de la quête) ; un clic ailleurs ouvre le journal.

signal pressed

const WIDTH := 196.0
const GAP := 4.0

var map_view: MapView
var minimap: Minimap
var _frame: PanelContainer
var _title: Label
var _lines: Label
var _fold: Button


func _ready() -> void:
	_build()
	_frame.visible = false


func setup(p_map_view: MapView, p_minimap: Minimap) -> void:
	map_view = p_map_view
	minimap = p_minimap
	map_view.quests_changed.connect(func(_journal: Dictionary) -> void: refresh())
	map_view.combat_started.connect(refresh)
	map_view.exploration_resumed.connect(refresh)
	map_view.map_changed.connect(refresh)
	refresh()


func is_shown() -> bool:
	return _frame.visible


func is_folded() -> bool:
	return Session.tracker_folded


func set_folded(folded: bool) -> void:
	Session.tracker_folded = folded
	refresh()


## Texte affiché (pour les tests) : nom de la quête, puis les objectifs.
func shown_text() -> String:
	return "%s\n%s" % [_title.text, _lines.text]


func refresh() -> void:
	if map_view == null or map_view.world == null:
		return
	var journal := map_view.world.quest_book.sheet()
	var tracked: Dictionary = {}
	for entry: Dictionary in journal["en_cours"]:
		if entry["id"] == journal["suivie"]:
			tracked = entry
	_frame.visible = not tracked.is_empty() and map_view.mode == MapView.Mode.EXPLORATION
	if tracked.is_empty():
		return
	_title.text = tracked["nom"]
	var lines: PackedStringArray = []
	for objective: Dictionary in tracked["objectifs"]:
		lines.append(("✔ " if objective["fait"] else "• ") + objective["texte"])
	_lines.text = "\n".join(lines)
	_lines.visible = not Session.tracker_folded
	_fold.text = "+" if Session.tracker_folded else "–"
	_fold.tooltip_text = "Déplier le suivi" if Session.tracker_folded else "Replier le suivi"
	_frame.reset_size()


func _process(_delta: float) -> void:
	# Juste sous la minicarte (qui change de taille quand on la replie).
	if _frame.visible and minimap != null:
		var top := Minimap.TOP
		if minimap.is_shown():
			var rect := minimap.frame_rect()
			top = rect.end.y + GAP
		_frame.position = Vector2(get_viewport().get_visible_rect().size.x - Minimap.MARGIN_RIGHT - WIDTH, top)


func _on_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()


func _build() -> void:
	_frame = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.05, 0.82)
	style.border_color = Color(0.55, 0.42, 0.22)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(5)
	_frame.add_theme_stylebox_override("panel", style)
	_frame.custom_minimum_size = Vector2(WIDTH, 0)
	_frame.tooltip_text = "Journal des quêtes (Q)"
	_frame.gui_input.connect(_on_input)
	add_child(_frame)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 1)
	_frame.add_child(column)
	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(header)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 12)
	_title.add_theme_color_override("font_color", UiTheme.GOLD)
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.custom_minimum_size = Vector2(WIDTH - 34, 0)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(_title)
	_fold = Button.new()
	_fold.flat = true
	_fold.focus_mode = Control.FOCUS_NONE
	_fold.custom_minimum_size = Vector2(18, 16)
	_fold.add_theme_font_size_override("font_size", 12)
	_fold.pressed.connect(func() -> void: set_folded(not Session.tracker_folded))
	header.add_child(_fold)
	_lines = Label.new()
	_lines.add_theme_font_size_override("font_size", 11)
	_lines.add_theme_color_override("font_color", UiTheme.TEXT)
	_lines.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lines.custom_minimum_size = Vector2(WIDTH - 10, 0)
	_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_lines)
