class_name UiTheme
extends RefCounted
## Thème de l'interface : fonds sombres et liserés (pierre et argent par défaut, autres thèmes dans `THEMES`),
## accordé aux images du jeu. Appliqué à toute la fenêtre (menus, fenêtres, barre de combat) par `apply`.

## Thèmes de couleurs (choix dans les options, `Options.ui_theme`) : fonds, bordures, boutons, listes ;
## l'or des titres et la couleur des textes restent communs. fond : fenêtres et bulles ; bord : leur
## liseré ; bois / bois_clair / survol : boutons ; encre : listes et champs ; bronze : liserés des boutons ;
## lisere : liserés discrets ; choix : ligne choisie ; decor : fond des menus.
const THEMES := {
	"pierre": {"nom": "Pierre et argent", "bois": "2a2a2c", "bois_clair": "47474b", "survol": "5a5a60", "encre": "1c1c1e",
		"bronze": "8f8a7e", "fond": "222224", "bord": "9a9384", "lisere": "4e4c48", "choix": "5d5a50", "decor": "262628"},
	"bois": {"nom": "Bois et or", "bois": "2a1f15", "bois_clair": "4a3622", "survol": "5e4429", "encre": "1e160f",
		"bronze": "8d6b38", "fond": "211a12", "bord": "8c6b38", "lisere": "5a4630", "choix": "6b4a26", "decor": "2b2118"},
	"ardoise": {"nom": "Ardoise et acier", "bois": "1d2430", "bois_clair": "34405a", "survol": "45536f", "encre": "141a24",
		"bronze": "6f87a8", "fond": "18202b", "bord": "7d93b2", "lisere": "3c4a60", "choix": "3e5276", "decor": "1c2330"},
	"foret": {"nom": "Forêt et mousse", "bois": "1e2a1d", "bois_clair": "34482f", "survol": "44603d", "encre": "141d14",
		"bronze": "7f9a52", "fond": "18231a", "bord": "8aa35a", "lisere": "3f5536", "choix": "4a6a34", "decor": "1d281c"},
}
## Thème par défaut (choix de l'auteur, 12/11/2026).
const DEFAULT_THEME := "pierre"
const GOLD := Color("c9a04e")
const TEXT := Color("f0e6cc")
const TEXT_DIM := Color("8a7c66")
## Couleurs du thème choisi (`set_theme`).
static var WOOD := Color("2a1f15")
static var WOOD_LIGHT := Color("4a3622")
static var WOOD_HOVER := Color("5e4429")
static var INK := Color("1e160f")
static var BRONZE := Color("8d6b38")
static var SEAM := Color("5a4630")
static var SELECTED := Color("6b4a26")
static var BACKDROP := Color("2b2118")
## Fenêtres, infobulles et bulles de survol (voir `tooltip_style`).
static var TOOLTIP_FILL := Color(0.13, 0.1, 0.07, 0.97)
static var TOOLTIP_EDGE := Color(0.55, 0.42, 0.22)
## Styles créés par les fenêtres et recolorés au changement de thème : [WeakRef, rôle du fond, rôle du liseré, opacité].
static var _themed: Array = []
## Calque des bulles de survol dessinées par le jeu : au-dessus de tout (bandes, barre, fenêtres,
## menu pause à 50, options à 60). Les infobulles natives de Godot sont déjà au premier plan et
## recalées dans l'écran.
const TOOLTIP_LAYER := 100
## Taille fixe de toutes les fenêtres qui s'ouvrent (décision de l'auteur, 12/11/2026), pour un écran de 1280 × 720.
const WINDOW_SIZE := Vector2(1120, 610)


## Applique le thème, une seule fois, au thème par défaut : celui de la fenêtre racine ne parvient pas
## aux fenêtres, bandes et barres posées dans un CanvasLayer (boutons, onglets et infobulles y
## restaient gris, au style de Godot).
static func apply(_tree: SceneTree = null) -> void:
	var default := ThemeDB.get_default_theme()
	if not default.has_meta("retro_venture"):
		default.set_meta("retro_venture", true)
		Options.load_options()
		set_theme(Options.ui_theme)


## Passe au thème `id` (de THEMES), en direct : thème par défaut, styles des fenêtres, puis tout se redessine.
static func set_theme(id: String) -> void:
	var colors: Dictionary = THEMES.get(id, THEMES[DEFAULT_THEME])
	WOOD = Color(colors["bois"])
	WOOD_LIGHT = Color(colors["bois_clair"])
	WOOD_HOVER = Color(colors["survol"])
	INK = Color(colors["encre"])
	BRONZE = Color(colors["bronze"])
	SEAM = Color(colors["lisere"])
	SELECTED = Color(colors["choix"])
	BACKDROP = Color(colors["decor"])
	TOOLTIP_FILL = Color(colors["fond"], 0.97)
	TOOLTIP_EDGE = Color(colors["bord"])
	RenderingServer.set_default_clear_color(BACKDROP)  # Fond de l'écran autour de la carte.
	ThemeDB.get_default_theme().merge_with(build())
	_themed = _themed.filter(func(entry: Array) -> bool: return entry[0].get_ref() != null)
	for entry: Array in _themed:
		_paint(entry[0].get_ref(), entry[1], entry[2], entry[3])
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.propagate_notification(Control.NOTIFICATION_THEME_CHANGED)
		tree.root.propagate_call("queue_redraw")


## Donne à `style` les couleurs du thème (rôles : "fond", "bord", "encre", "lisere", "bronze", "bois_clair"…)
## et le recolore à chaque changement de thème.
static func themed(style: StyleBoxFlat, fill: String, border: String, alpha := 1.0) -> StyleBoxFlat:
	_themed.append([weakref(style), fill, border, alpha])
	_paint(style, fill, border, alpha)
	return style


static func _paint(style: StyleBoxFlat, fill: String, border: String, alpha: float) -> void:
	style.bg_color = Color(role(fill), alpha)
	style.border_color = role(border)


## Couleur d'un rôle du thème choisi.
static func role(name: String) -> Color:
	return {"fond": TOOLTIP_FILL, "bord": TOOLTIP_EDGE, "encre": INK, "lisere": SEAM, "bronze": BRONZE, "bois": WOOD,
		"bois_clair": WOOD_LIGHT, "choix": SELECTED, "decor": BACKDROP}[name]


static func build() -> Theme:
	var theme := Theme.new()
	# Boutons
	theme.set_stylebox("normal", "Button", _box(WOOD_LIGHT, BRONZE))
	theme.set_stylebox("hover", "Button", _box(WOOD_HOVER, GOLD))
	theme.set_stylebox("pressed", "Button", _box(WOOD, GOLD))
	theme.set_stylebox("hover_pressed", "Button", _box(WOOD, GOLD))
	theme.set_stylebox("disabled", "Button", _box(WOOD.lerp(INK, 0.3), SEAM))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", GOLD)
	theme.set_color("font_hover_pressed_color", "Button", GOLD)
	theme.set_color("font_focus_color", "Button", TEXT)
	theme.set_color("font_disabled_color", "Button", TEXT_DIM)
	# Fenêtres, listes, champs
	theme.set_stylebox("panel", "PanelContainer", _box(TOOLTIP_FILL, BRONZE, 2, 6, 14))
	theme.set_stylebox("panel", "Panel", _box(TOOLTIP_FILL, BRONZE, 2, 6, 14))
	theme.set_stylebox("panel", "ItemList", _box(INK, SEAM, 1, 4, 6))
	theme.set_stylebox("focus", "ItemList", StyleBoxEmpty.new())
	theme.set_stylebox("selected", "ItemList", _box(SELECTED, GOLD, 1, 3, 2))
	theme.set_stylebox("selected_focus", "ItemList", _box(SELECTED, GOLD, 1, 3, 2))
	theme.set_stylebox("hovered", "ItemList", _box(Color("3a2a1a"), Color("3a2a1a"), 0, 3, 2))
	theme.set_color("font_color", "ItemList", TEXT)
	theme.set_stylebox("normal", "LineEdit", _box(INK, BRONZE, 1, 4, 6))
	theme.set_stylebox("focus", "LineEdit", _box(INK, GOLD, 1, 4, 6))
	theme.set_color("font_color", "LineEdit", TEXT)
	theme.set_color("font_placeholder_color", "LineEdit", TEXT_DIM)
	theme.set_color("caret_color", "LineEdit", GOLD)
	theme.set_stylebox("background", "ProgressBar", _box(INK, SEAM, 1, 3, 0))
	theme.set_stylebox("fill", "ProgressBar", _box(GOLD, GOLD.darkened(0.3), 1, 3, 0))
	# Onglets
	theme.set_stylebox("tab_selected", "TabBar", _box(WOOD_HOVER, GOLD, 1, 4, 8))
	theme.set_stylebox("tab_unselected", "TabBar", _box(WOOD, SEAM, 1, 4, 8))
	theme.set_stylebox("tab_hovered", "TabBar", _box(WOOD_LIGHT, BRONZE, 1, 4, 8))
	theme.set_stylebox("tab_focus", "TabBar", StyleBoxEmpty.new())
	theme.set_color("font_selected_color", "TabBar", GOLD)
	theme.set_color("font_unselected_color", "TabBar", TEXT)
	theme.set_color("font_hovered_color", "TabBar", Color.WHITE)
	theme.set_color("font_color", "Label", TEXT)
	_tooltips(theme)
	return theme


## Infobulles : le fond presque opaque et le liseré bronze de la grille de Composition.
static func _tooltips(theme: Theme) -> void:
	theme.set_stylebox("panel", "TooltipPanel", tooltip_style())
	theme.set_color("font_color", "TooltipLabel", TEXT)
	theme.set_color("font_outline_color", "TooltipLabel", Color(0, 0, 0, 0))


## Fond commun des infobulles et des bulles de survol (carte, prévisions) : bois sombre presque
## opaque, liseré bronze de 2 px, comme la grille de Composition de l'Arcaniste.
static func tooltip_style() -> StyleBoxFlat:
	var style := themed(_box(TOOLTIP_FILL, TOOLTIP_EDGE, 2, 6, 10), "fond", "bord", TOOLTIP_FILL.a)
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


## Zone défilante d'une fenêtre. Règle de l'interface : une fenêtre garde toujours sa taille, et ce
## qui ne tient pas (fiche d'objet avec sa panoplie, texte de quête, longue liste) défile dedans au
## lieu de l'agrandir (`tests/test_interface.gd` le vérifie sur chaque fenêtre). Sans `height`, la
## zone prend la place libre ; avec, elle a cette hauteur fixe (une réplique d'accueil, par exemple).
static func scroll_area(content: Control, height := 0.0) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if height > 0.0:
		scroll.custom_minimum_size = Vector2(0, height)
	else:
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	return scroll


## Cadre commun des fenêtres qui s'ouvrent : une seule grande taille fixe (celle de l'Enclume), centrée,
## qui peut couvrir la carte, les bandes et la barre du bas ; fond assombri qui ferme la fenêtre au clic
## (`backdrop`) ; en-tête avec le titre et le bouton ×. Les infos et onglets de l'en-tête s'ajoutent par
## `header_add`, avant le ×. Rend {backdrop, panel, column, header, title}.
static func window_frame(owner: Node, title: String, close: Callable, backdrop := true) -> Dictionary:
	var frame := {"backdrop": null}
	if backdrop:
		frame.backdrop = ColorRect.new()
		frame.backdrop.color = Color(0, 0, 0, 0.35)
		frame.backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
		frame.backdrop.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed:
				close.call())
		owner.add_child(frame.backdrop)
	frame.panel = PanelContainer.new()
	frame.panel.set_anchors_preset(Control.PRESET_CENTER)
	frame.panel.offset_left = -WINDOW_SIZE.x / 2
	frame.panel.offset_right = WINDOW_SIZE.x / 2
	frame.panel.offset_top = -WINDOW_SIZE.y / 2
	frame.panel.offset_bottom = WINDOW_SIZE.y / 2
	frame.panel.add_theme_stylebox_override("panel", window_style())
	owner.add_child(frame.panel)
	frame.column = VBoxContainer.new()
	frame.column.add_theme_constant_override("separation", 8)
	frame.panel.add_child(frame.column)
	frame.header = HBoxContainer.new()
	frame.header.add_theme_constant_override("separation", 10)
	frame.column.add_child(frame.header)
	frame.title = Label.new()
	frame.title.text = title
	frame.title.add_theme_font_size_override("font_size", 22)
	frame.title.add_theme_color_override("font_color", GOLD)
	frame.title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.title.clip_text = true
	frame.header.add_child(frame.title)
	var close_button := Button.new()
	close_button.text = "×"
	close_button.tooltip_text = "Fermer (Échap)"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.custom_minimum_size = Vector2(32, 32)
	close_button.pressed.connect(close)
	frame.header.add_child(close_button)
	return frame


## Ajoute un contrôle à l'en-tête d'une fenêtre, avant le bouton ×.
static func header_add(frame: Dictionary, control: Control) -> Control:
	frame.header.add_child(control)
	frame.header.move_child(control, frame.header.get_child_count() - 2)
	return control


## Onglets communs des fenêtres (style du thème) : `names` dans l'ordre, `selected` appelé avec l'indice.
static func tabs(names: Array, selected: Callable) -> TabBar:
	var bar := TabBar.new()
	bar.focus_mode = Control.FOCUS_NONE
	bar.clip_tabs = false
	for tab_name: String in names:
		bar.add_tab(tab_name)
	bar.tab_changed.connect(selected)
	return bar


## Fond des fenêtres posées au milieu de l'écran (options, pause…).
static func window_style() -> StyleBoxFlat:
	var style := themed(_box(TOOLTIP_FILL, TOOLTIP_EDGE, 2, 6, 14), "fond", "bord", TOOLTIP_FILL.a)
	style.set_content_margin_all(18)
	return style


static func _box(fill: Color, border: Color, border_width := 1, radius := 4, margin := 8) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = margin
	box.content_margin_right = margin
	box.content_margin_top = margin * 0.5
	box.content_margin_bottom = margin * 0.5
	return box
