class_name CombatLog
extends PanelContainer
## Historique du combat, en bas à gauche au-dessus de la barre : sorts lancés et leurs effets, une
## ligne par événement, dégâts, soins et boucliers à la couleur de leur élément. Le bouton « – » (ou
## la touche H) le replie ; il se vide au début de chaque combat.

const WIDTH := 380.0
const HEIGHT := 170.0
const MAX_LINES := 300

var _text: RichTextLabel
var _fold: Button
var _lines: PackedStringArray = []


func _init() -> void:
	_build()
	visible = false


## Nouveau combat : historique vide, affiché.
func start() -> void:
	_lines.clear()
	_text.clear()
	visible = true
	_apply_fold()


func add_line(line: String) -> void:
	_lines.append(line)
	if _lines.size() > MAX_LINES:
		_lines.remove_at(0)
		_text.text = "\n".join(_lines)
	elif _lines.size() == 1:
		_text.text = line
	else:
		_text.append_text("\n" + line)


## Texte de l'historique sans BBCode (pour les tests).
func plain_text() -> String:
	return _text.get_parsed_text()


func lines() -> PackedStringArray:
	return _lines


func is_folded() -> bool:
	return Session.combat_log_folded


func toggle_fold() -> void:
	Session.combat_log_folded = not Session.combat_log_folded
	_apply_fold()


func _apply_fold() -> void:
	_text.visible = not Session.combat_log_folded
	_fold.text = "+" if Session.combat_log_folded else "–"
	_fold.tooltip_text = "Déplier l'historique (H)" if Session.combat_log_folded else "Replier l'historique (H)"
	custom_minimum_size = Vector2(WIDTH, 0 if Session.combat_log_folded else HEIGHT)
	offset_top = offset_bottom - (24.0 if Session.combat_log_folded else HEIGHT)
	reset_size()


func _build() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.05, 0.82)
	style.border_color = Color(0.55, 0.42, 0.22)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(5)
	add_theme_stylebox_override("panel", style)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "Historique du combat"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", UiTheme.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_fold = Button.new()
	_fold.flat = true
	_fold.focus_mode = Control.FOCUS_NONE
	_fold.custom_minimum_size = Vector2(18, 16)
	_fold.add_theme_font_size_override("font_size", 12)
	_fold.pressed.connect(toggle_fold)
	header.add_child(_fold)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_following = true
	_text.selection_enabled = false
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", 12)
	_text.add_theme_font_size_override("bold_font_size", 12)
	_text.add_theme_color_override("default_color", UiTheme.TEXT)
	column.add_child(_text)
