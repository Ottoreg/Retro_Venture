class_name UiTheme
extends RefCounted
## Thème de l'interface : bois sombre et liserés dorés, accordé aux images du jeu. Appliqué à toute
## la fenêtre (menus, fenêtres, barre de combat) par `apply`.

const WOOD := Color("2a1f15")
const WOOD_LIGHT := Color("4a3622")
const WOOD_HOVER := Color("5e4429")
const INK := Color("1e160f")
const GOLD := Color("c9a04e")
const BRONZE := Color("8d6b38")
const TEXT := Color("f0e6cc")
const TEXT_DIM := Color("8a7c66")
## Infobulles et bulles de survol (voir `tooltip_style`).
const TOOLTIP_FILL := Color(0.13, 0.1, 0.07, 0.97)
const TOOLTIP_EDGE := Color(0.55, 0.42, 0.22)
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
		default.merge_with(build())
		default.set_meta("retro_venture", true)


static func build() -> Theme:
	var theme := Theme.new()
	# Boutons
	theme.set_stylebox("normal", "Button", _box(WOOD_LIGHT, BRONZE))
	theme.set_stylebox("hover", "Button", _box(WOOD_HOVER, GOLD))
	theme.set_stylebox("pressed", "Button", _box(WOOD, GOLD))
	theme.set_stylebox("hover_pressed", "Button", _box(WOOD, GOLD))
	theme.set_stylebox("disabled", "Button", _box(Color("33281c"), Color("54442f")))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", GOLD)
	theme.set_color("font_hover_pressed_color", "Button", GOLD)
	theme.set_color("font_focus_color", "Button", TEXT)
	theme.set_color("font_disabled_color", "Button", TEXT_DIM)
	# Fenêtres, listes, champs
	theme.set_stylebox("panel", "PanelContainer", _box(Color(0.13, 0.1, 0.07, 0.97), BRONZE, 2, 6, 14))
	theme.set_stylebox("panel", "Panel", _box(Color(0.13, 0.1, 0.07, 0.97), BRONZE, 2, 6, 14))
	theme.set_stylebox("panel", "ItemList", _box(INK, Color("5a4630"), 1, 4, 6))
	theme.set_stylebox("focus", "ItemList", StyleBoxEmpty.new())
	theme.set_stylebox("selected", "ItemList", _box(Color("6b4a26"), GOLD, 1, 3, 2))
	theme.set_stylebox("selected_focus", "ItemList", _box(Color("6b4a26"), GOLD, 1, 3, 2))
	theme.set_stylebox("hovered", "ItemList", _box(Color("3a2a1a"), Color("3a2a1a"), 0, 3, 2))
	theme.set_color("font_color", "ItemList", TEXT)
	theme.set_stylebox("normal", "LineEdit", _box(INK, BRONZE, 1, 4, 6))
	theme.set_stylebox("focus", "LineEdit", _box(INK, GOLD, 1, 4, 6))
	theme.set_color("font_color", "LineEdit", TEXT)
	theme.set_color("font_placeholder_color", "LineEdit", TEXT_DIM)
	theme.set_color("caret_color", "LineEdit", GOLD)
	theme.set_stylebox("background", "ProgressBar", _box(INK, Color("5a4630"), 1, 3, 0))
	theme.set_stylebox("fill", "ProgressBar", _box(GOLD, GOLD.darkened(0.3), 1, 3, 0))
	# Onglets
	theme.set_stylebox("tab_selected", "TabBar", _box(WOOD_HOVER, GOLD, 1, 4, 8))
	theme.set_stylebox("tab_unselected", "TabBar", _box(WOOD, Color("5a4630"), 1, 4, 8))
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
	var style := _box(TOOLTIP_FILL, TOOLTIP_EDGE, 2, 6, 10)
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
	var style := _box(Color(0.13, 0.1, 0.07, 0.97), Color(0.55, 0.42, 0.22), 2, 6, 14)
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
