class_name MessageLog
extends PanelContainer
## Historique commun, à gauche de la barre du bas, en combat comme en exploration : une
## ligne par message, rangée dans un canal (combat, commerce). Des onglets filtrent les canaux
## (« Tout » les mêle) ; le bouton « – » (ou la touche H) le replie. Rien ne s'efface entre deux
## combats : un séparateur marque le début de chacun.
##
## Prévu pour le chat (GDD § 14.4) : un message a un canal, un auteur facultatif et une heure ; les
## canaux groupe, équipe et guilde s'ajouteront à `CHANNELS`, avec une ligne de saisie sous le texte.

const WIDTH := 340.0
## Lignes gardées par canal : un long combat ne chasse pas l'historique du commerce.
const MAX_LINES := 300

const CHANNEL_ALL := "tout"
const CHANNEL_COMBAT := "combat"
const CHANNEL_TRADE := "commerce"
## Canaux dans l'ordre des onglets : nom de l'onglet.
const CHANNELS := {
	CHANNEL_COMBAT: "Combat",
	CHANNEL_TRADE: "Commerce",
}
const SEPARATOR_COLOR := "#c9a04e"

var _text: RichTextLabel
var _fold: Button
var _tabs: Dictionary = {}
## Messages de tous les canaux, du plus ancien au plus récent : { canal, texte, auteur, heure }.
var _entries: Array[Dictionary] = []
var _shown := 0


func _init() -> void:
	_build()
	_show_channel()


func _ready() -> void:
	_apply_fold()


## Nouveau combat : un séparateur après l'historique des combats précédents, qui reste.
func start_combat() -> void:
	if _entries.any(func(entry: Dictionary) -> bool: return entry["canal"] == CHANNEL_COMBAT):
		add_entry(CHANNEL_COMBAT, "\n[color=%s]— Nouveau combat —[/color]" % SEPARATOR_COLOR)


## Ligne de combat (signal `MapView.combat_logged`).
func add_line(line: String) -> void:
	add_entry(CHANNEL_COMBAT, line)


## Ajoute un message (BBCode) à un canal ; `author` le fait précéder du nom de son auteur (chat).
func add_entry(channel: String, text: String, author := "") -> void:
	var entry := {"canal": channel, "texte": text, "auteur": author, "heure": Time.get_time_string_from_system()}
	_entries.append(entry)
	var count := 0
	for other: Dictionary in _entries:
		if other["canal"] == channel:
			count += 1
	if count > MAX_LINES:
		for i in _entries.size():
			if _entries[i]["canal"] == channel:
				_entries.remove_at(i)
				break
		_show_channel()
	elif _visible_in_tab(entry):
		_text.append_text(("\n" if _shown > 0 else "") + _format(entry))
		_shown += 1


## Texte affiché sans BBCode (pour les tests).
func plain_text() -> String:
	return _text.get_parsed_text()


## Textes d'un canal (tous si `channel` est « tout »).
func lines(channel := CHANNEL_ALL) -> PackedStringArray:
	var result: PackedStringArray = []
	for entry: Dictionary in _entries:
		if channel == CHANNEL_ALL or entry["canal"] == channel:
			result.append(entry["texte"])
	return result


func channel() -> String:
	return Session.message_log_channel


## Onglet choisi : n'affiche que ce canal (ou tous).
func select_channel(p_channel: String) -> void:
	Session.message_log_channel = p_channel
	_show_channel()


func is_folded() -> bool:
	return Session.message_log_folded


func toggle_fold() -> void:
	Session.message_log_folded = not Session.message_log_folded
	_apply_fold()


func _visible_in_tab(entry: Dictionary) -> bool:
	return Session.message_log_channel == CHANNEL_ALL or entry["canal"] == Session.message_log_channel


func _format(entry: Dictionary) -> String:
	if str(entry["auteur"]).is_empty():
		return entry["texte"]
	return "[b]%s[/b] : %s" % [entry["auteur"], entry["texte"]]


func _show_channel() -> void:
	for key: String in _tabs:
		_tabs[key].set_pressed_no_signal(key == Session.message_log_channel)
	var shown: PackedStringArray = []
	for entry: Dictionary in _entries:
		if _visible_in_tab(entry):
			shown.append(_format(entry))
	_shown = shown.size()
	_text.clear()
	_text.append_text("\n".join(shown))


func _apply_fold() -> void:
	var folded := Session.message_log_folded
	_text.visible = not folded
	_fold.text = "+" if folded else "–"
	_fold.tooltip_text = "Déplier l'historique (H)" if folded else "Replier l'historique (H)"
	custom_minimum_size = Vector2(WIDTH, 0)


func _build() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = UiTheme.INK
	style.border_color = UiTheme.TOOLTIP_EDGE
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(5)
	add_theme_stylebox_override("panel", style)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 2)
	column.add_child(header)
	var title := Label.new()
	title.text = "Historique"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", UiTheme.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var group := ButtonGroup.new()
	_add_tab(header, group, CHANNEL_ALL, "Tout")
	for key: String in CHANNELS:
		_add_tab(header, group, key, CHANNELS[key])
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


func _add_tab(header: HBoxContainer, group: ButtonGroup, key: String, label: String) -> void:
	var tab := Button.new()
	tab.text = label
	tab.toggle_mode = true
	tab.button_group = group
	tab.focus_mode = Control.FOCUS_NONE
	tab.add_theme_font_size_override("font_size", 11)
	tab.tooltip_text = "Tous les messages" if key == CHANNEL_ALL else "Messages : %s" % label.to_lower()
	tab.pressed.connect(select_channel.bind(key))
	header.add_child(tab)
	_tabs[key] = tab
