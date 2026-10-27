class_name MessageLog
extends PanelContainer
## Historique commun, à gauche de la barre du bas, en combat comme en exploration : une
## ligne par message, rangée dans un canal (combat, commerce). Des onglets filtrent les canaux
## (« Tout » les mêle) ; le bouton « – » (ou la touche H) le replie. Rien ne s'efface entre deux
## combats : un séparateur marque le début de chacun.
##
## Chat (GDD § 16.5, jalon M3) : en ligne, une ligne de saisie sous le texte envoie la commande
## `ecrire` sur le canal de l'onglet ouvert, ou sur celui d'un préfixe (`/g`, `/w Pseudo`…). Les
## messages des joueurs arrivent par `MapView.chat_received` : chaque canal a sa couleur et le nom
## de l'auteur est cliquable (menu : message privé, invitation…).

const WIDTH := 340.0
## Lignes gardées par canal : un long combat ne chasse pas l'historique du commerce.
const MAX_LINES := 300

const CHANNEL_ALL := "tout"
const CHANNEL_COMBAT := "combat"
## Commerce : les achats et ventes chez les marchands et les annonces des joueurs (`Chat.TRADE`),
## d'une autre couleur, partagent un seul onglet (choix de l'auteur).
const CHANNEL_TRADE := Chat.TRADE
## Canaux dans l'ordre des onglets : nom de l'onglet (les canaux du chat viennent de `Chat`).
const CHANNELS := {
	CHANNEL_COMBAT: "Combat",
	Chat.LOCAL: "Local",
	Chat.PARTY: "Groupe",
	CHANNEL_TRADE: "Commerce",
	Chat.RECRUIT: "Recrut.",
	Chat.PRIVATE: "Privé",
}
## Couleur des messages de chaque canal du chat (le reste garde la couleur du texte).
const CHANNEL_COLORS := {
	Chat.LOCAL: "#e8e2d0",
	Chat.PARTY: "#8fd0f0",
	Chat.TRADE: "#f0c070",
	Chat.RECRUIT: "#b0e090",
	Chat.PRIVATE: "#e0a0e8",
}
## Canal où écrire quand l'onglet ouvert n'en est pas un du chat (Tout, Combat).
const DEFAULT_CHANNEL := Chat.LOCAL
## Préfixe d'un canal tapé au début du message (`/w Pseudo bonjour`), et `/r` : répondre au dernier privé.
const PREFIXES := {
	"/l": Chat.LOCAL,
	"/g": Chat.PARTY,
	"/c": Chat.TRADE,
	"/rec": Chat.RECRUIT,
	"/w": Chat.PRIVATE,
}
const REPLY_PREFIX := "/r"
## Métadonnée d'un nom d'auteur cliquable.
const AUTHOR_META := "joueur:"
const SEPARATOR_COLOR := "#c9a04e"

## Nom d'un joueur cliqué dans l'historique (menu du chat).
signal author_clicked(player_name: String)
## Message à envoyer : { canal, texte } et `a` (pseudo) en privé.
signal chat_submitted(command: Dictionary)

var _text: RichTextLabel
var _fold: Button
var _input: LineEdit
var _tabs: Dictionary = {}
## Nom du joueur, pour reconnaître ses propres messages privés (réglé par `CombatHud`).
var own_name := ""
## Dernier joueur à nous avoir écrit en privé (`/r`).
var _last_whisper := ""
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


## Message de chat reçu (EVT_CHAT) : rangé dans son canal, à sa couleur, l'auteur cliquable. Le
## texte d'un joueur est échappé (jamais de BBCode venu d'un autre joueur).
func add_chat(event: Dictionary) -> void:
	var channel := str(event["canal"])
	var author := str(event["auteur"])
	var color: String = CHANNEL_COLORS.get(channel, "#e8e2d0")
	var text := "[color=%s]%s[/color]" % [color, escape(str(event["texte"]))]
	if channel == Chat.PRIVATE:
		# Privé : qui parle à qui (« à Sam » pour le message qu'on envoie).
		var to := str(event.get("a", ""))
		if author == own_name:
			text = "[color=%s]à %s :[/color] %s" % [color, escape(to), text]
			author = ""
		else:
			_last_whisper = author
	add_entry(channel, text, author)


## Texte d'un joueur sans BBCode : les crochets restent lisibles mais ne sont plus des balises.
static func escape(text: String) -> String:
	return text.replace("[", "[lb]")


## Annonce du jeu dans le chat (un ami arrive ou part), sur le canal Privé, en doré.
func add_notice(text: String) -> void:
	add_entry(Chat.PRIVATE, "[color=%s]%s[/color]" % [SEPARATOR_COLOR, escape(text)])


## Refus du serveur (EVT_REFUSED sur `ecrire`) : dit dans l'historique, sur le canal visé.
func add_chat_refusal(event: Dictionary) -> void:
	var reason := str(event.get("raison", ""))
	var text := "Message impossible."
	if reason == Protocol.REASON_CHAT_FLOOD:
		text = "Vous écrivez trop vite : attendez %d s." % int(event.get("attente", 0))
	elif reason == Protocol.REASON_PLAYER_OFFLINE:
		text = "Ce joueur n'est pas connecté."
	elif reason == Protocol.REASON_NOT_IN_PARTY:
		text = "Vous n'êtes dans aucun groupe."
	add_entry(channel(), "[color=%s]%s[/color]" % [SEPARATOR_COLOR, text])


## Canal où part le prochain message (celui de l'onglet, sinon Local).
func typing_channel() -> String:
	var channel := channel()
	return channel if channel in Chat.CHANNELS else DEFAULT_CHANNEL


## Ouvre (ou ferme) la ligne de saisie du chat ; vrai si elle est ouverte ensuite.
func toggle_typing() -> bool:
	if not _input.visible:
		return false
	if _input.has_focus():
		_input.release_focus()
		return false
	if is_folded():
		toggle_fold()
	_input.grab_focus()
	_refresh_placeholder()
	return true


## Vrai quand le joueur écrit (les raccourcis de l'interface se taisent).
func is_typing() -> bool:
	return _input.visible and _input.has_focus()


## Montre la ligne de saisie (en ligne seulement).
func set_chat_enabled(enabled: bool) -> void:
	_input.visible = enabled


## Prépare un message privé pour ce joueur.
func whisper_to(player_name: String) -> void:
	if not _input.visible:
		return
	select_channel(Chat.PRIVATE)
	_input.text = "/w %s " % player_name
	if is_folded():
		toggle_fold()
	_input.grab_focus()
	_input.caret_column = _input.text.length()


## Commande à envoyer pour ce qui est tapé ({} si rien à envoyer), d'après le canal de l'onglet,
## les préfixes (`/g`, `/w Pseudo`, `/r`) et le dernier privé reçu.
static func parse_input(text: String, tab_channel: String, last_whisper := "") -> Dictionary:
	var rest := text.strip_edges()
	var channel := tab_channel
	var target := ""
	if rest.begins_with("/"):
		var word := rest.split(" ", true, 1)[0].to_lower()
		rest = rest.trim_prefix(rest.split(" ", true, 1)[0]).strip_edges()
		if word == REPLY_PREFIX:
			if last_whisper.is_empty():
				return {}
			channel = Chat.PRIVATE
			target = last_whisper
		elif PREFIXES.has(word):
			channel = PREFIXES[word]
			if channel == Chat.PRIVATE:
				var parts := rest.split(" ", true, 1)
				target = parts[0]
				rest = parts[1].strip_edges() if parts.size() > 1 else ""
		else:
			return {}  # Préfixe inconnu : rien d'envoyé (le joueur corrige).
	elif channel == Chat.PRIVATE:
		if last_whisper.is_empty():
			return {}
		target = last_whisper
	if rest.is_empty() or channel == Chat.PRIVATE and target.is_empty():
		return {}
	var command := {"canal": channel, "texte": rest}
	if channel == Chat.PRIVATE:
		command["a"] = target
	return command


## Lignes de l'onglet ouvert telles que le joueur les lit (auteur compris), sans BBCode : le texte
## riche ne se met à jour qu'à la frame suivante, les tests lisent donc celles-ci.
func visible_lines() -> PackedStringArray:
	var shown: PackedStringArray = []
	for entry: Dictionary in _entries:
		if _visible_in_tab(entry):
			shown.append(_strip(_format(entry)))
	return shown


## Texte sans ses balises BBCode.
static func _strip(text: String) -> String:
	var clean := ""
	var depth := 0
	for i in text.length():
		var glyph := text[i]
		if glyph == "[":
			depth += 1
		elif glyph == "]":
			depth = maxi(0, depth - 1)
		elif depth == 0:
			clean += glyph
	return clean


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
	if _input != null:
		_refresh_placeholder()


func is_folded() -> bool:
	return Session.message_log_folded


func toggle_fold() -> void:
	Session.message_log_folded = not Session.message_log_folded
	_apply_fold()


func _visible_in_tab(entry: Dictionary) -> bool:
	return Session.message_log_channel == CHANNEL_ALL or entry["canal"] == Session.message_log_channel


func _format(entry: Dictionary) -> String:
	var author := str(entry["auteur"])
	if author.is_empty():
		return entry["texte"]
	# Chat : le nom de l'auteur ouvre son menu (message privé, invitation…).
	if entry["canal"] in Chat.CHANNELS:
		return "[url=%s%s][b]%s[/b][/url] : %s" % [AUTHOR_META, author.uri_encode(), escape(author), entry["texte"]]
	return "[b]%s[/b] : %s" % [escape(author), entry["texte"]]


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
	if _input != null and folded:
		_input.release_focus()
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
	_text.meta_clicked.connect(_on_meta_clicked)
	column.add_child(_text)
	_input = LineEdit.new()
	_input.visible = false  # En ligne seulement (`set_chat_enabled`).
	_input.max_length = Chat.MAX_LENGTH
	_input.add_theme_font_size_override("font_size", 12)
	_input.text_submitted.connect(_on_submitted)
	column.add_child(_input)


## Nom d'auteur cliqué : son menu (message privé, invitation…).
func _on_meta_clicked(meta: Variant) -> void:
	var text := str(meta)
	if text.begins_with(AUTHOR_META):
		author_clicked.emit(text.substr(AUTHOR_META.length()).uri_decode())


func _on_submitted(text: String) -> void:
	var command := parse_input(text, typing_channel(), _last_whisper)
	if command.is_empty():
		_input.release_focus()
		return
	_input.clear()
	select_channel(command["canal"])
	chat_submitted.emit(command)


func _refresh_placeholder() -> void:
	var channel := typing_channel()
	var label: String = CHANNELS.get(channel, channel)
	_input.placeholder_text = "Écrire (%s) : /l /g /c /rec /w Pseudo /r" % label.to_lower()


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
