class_name QuestTracker
extends CanvasLayer
## Suivi de la quête choisie, à droite du bandeau du haut (en exploration) : jamais sur la zone de
## jeu. Son nom et les objectifs de l'étape qui restent à faire (MAX_LINES au plus, le nombre des
## autres après le nom). Le bouton « – » le replie (il ne reste que le nom de la quête) ; un clic
## ailleurs ouvre le journal.

signal pressed

const WIDTH := 380.0
## Distance au bord droit et au haut de l'écran (le bandeau fait 62 pixels de haut).
const MARGIN_RIGHT := 12.0
const TOP := 4.0
## Objectifs montrés au plus (pour tenir dans le bandeau).
const MAX_LINES := 2

var map_view: MapView
var _frame: PanelContainer
var _title: Label
var _lines: Label
var _fold: Button


func _ready() -> void:
	_build()
	_frame.visible = false


func setup(p_map_view: MapView) -> void:
	map_view = p_map_view
	map_view.quests_changed.connect(func(_journal: Dictionary) -> void: refresh())
	map_view.combat_started.connect(refresh)
	map_view.exploration_resumed.connect(refresh)
	map_view.map_changed.connect(refresh)
	refresh()


func is_shown() -> bool:
	return _frame.visible


## Rectangle du cadre à l'écran.
func frame_rect() -> Rect2:
	return _frame.get_global_rect()


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
	# Les objectifs à faire d'abord ; tous faits (étape en train de se valider) : les derniers.
	var objectives: Array = tracked["objectifs"].filter(func(o: Dictionary) -> bool: return not o["fait"])
	if objectives.is_empty():
		objectives = tracked["objectifs"]
	var lines: PackedStringArray = []
	for objective: Dictionary in objectives.slice(0, MAX_LINES):
		lines.append(("✔ " if objective["fait"] else "• ") + objective["texte"])
	var hidden := objectives.size() - MAX_LINES
	_title.text = tracked["nom"] + ("  (+%d)" % hidden if hidden > 0 else "")
	_lines.text = "\n".join(lines)
	_lines.visible = not Session.tracker_folded
	_fold.text = "+" if Session.tracker_folded else "–"
	_fold.tooltip_text = "Déplier le suivi" if Session.tracker_folded else "Replier le suivi"
	_frame.reset_size()


func _process(_delta: float) -> void:
	if _frame.visible:
		_frame.position = Vector2(get_viewport().get_visible_rect().size.x - MARGIN_RIGHT - WIDTH, TOP)


func _on_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()


func _build() -> void:
	_frame = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.05, 0.6)
	style.border_color = Color(0.55, 0.42, 0.22)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(3)
	_frame.add_theme_stylebox_override("panel", style)
	_frame.custom_minimum_size = Vector2(WIDTH, 0)
	_frame.tooltip_text = "Journal des quêtes (Q)"
	_frame.gui_input.connect(_on_input)
	add_child(_frame)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 0)
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
	_lines.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_lines.custom_minimum_size = Vector2(WIDTH - 10, 0)
	_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_lines)
