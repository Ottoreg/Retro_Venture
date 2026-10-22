class_name QuestTracker
extends CanvasLayer
## Suivi de la quête choisie, dans la bande gauche sous la minicarte (`CombatHud.quest_slot`) :
## jamais sur la zone de jeu. Son nom et les objectifs de l'étape qui restent à faire (MAX_LINES au
## plus, le nombre des autres après le nom). Le bouton « – » le replie (il ne reste que le nom de la
## quête) ; un clic ailleurs ouvre le journal (hors combat).

signal pressed

## Objectifs montrés au plus.
const MAX_LINES := 5

var map_view: MapView
## Emplacement réservé dans la bande gauche (voir `setup`).
var _slot: Control
var _frame: PanelContainer
var _title: Label
var _lines: Label
var _fold: Button


func _ready() -> void:
	_build()
	_frame.visible = false


func setup(p_map_view: MapView, hud: CombatHud) -> void:
	map_view = p_map_view
	_slot = hud.quest_slot
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
	_frame.visible = not tracked.is_empty()
	if tracked.is_empty():
		return
	# Les objectifs à faire d'abord ; tous faits (étape en train de se valider) : les derniers.
	var objectives: Array = tracked["objectifs"].filter(func(o: Dictionary) -> bool: return not o["fait"])
	if objectives.is_empty():
		objectives = tracked["objectifs"]
	var lines: PackedStringArray = []
	for objective: Dictionary in objectives.slice(0, MAX_LINES):
		lines.append(("√ " if objective["fait"] else "• ") + objective["texte"])
	var hidden := objectives.size() - MAX_LINES
	_title.text = tracked["nom"] + ("  (+%d)" % hidden if hidden > 0 else "")
	_lines.text = "\n".join(lines)
	_lines.visible = not Session.tracker_folded
	_fold.text = "+" if Session.tracker_folded else "–"
	_fold.tooltip_text = "Déplier le suivi" if Session.tracker_folded else "Replier le suivi"
	_frame.reset_size()
	_place()


func _process(_delta: float) -> void:
	_place()


## En haut de son emplacement, sur toute sa largeur ; aussi haut que son texte, sans en sortir.
func _place() -> void:
	if _slot == null or not _frame.visible:
		return
	var slot := _slot.get_global_rect()
	# Les lignes coupées ont besoin de leur largeur pour connaître leur hauteur.
	var inner := slot.size.x - 10.0
	_title.custom_minimum_size.x = inner - _fold.custom_minimum_size.x - 4.0
	_lines.custom_minimum_size.x = inner
	_frame.position = slot.position
	_frame.custom_minimum_size = Vector2(slot.size.x, 0)
	_frame.size = Vector2(slot.size.x, slot.size.y)
	for container in [_frame] + _frame.find_children("*", "Container", true, false):
		container.notification(Container.NOTIFICATION_SORT_CHILDREN)
	for label in [_title, _lines]:
		label.update_minimum_size()
	_frame.size = Vector2(slot.size.x, minf(_frame.get_combined_minimum_size().y, slot.size.y))


func _on_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT and map_view.mode == MapView.Mode.EXPLORATION:
		pressed.emit()


func _build() -> void:
	_frame = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = UiTheme.TOOLTIP_FILL
	style.border_color = UiTheme.TOOLTIP_EDGE
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(5)
	_frame.add_theme_stylebox_override("panel", style)
	_frame.clip_contents = true
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
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.custom_minimum_size = Vector2(1, 0)
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
	_lines.custom_minimum_size = Vector2(1, 0)
	_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_lines)
