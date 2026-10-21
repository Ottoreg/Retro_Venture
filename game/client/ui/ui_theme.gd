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


## Applique le thème à la fenêtre, une seule fois. Les infobulles prennent aussi leur style dans le
## thème par défaut : celui de la fenêtre ne leur parvient pas toujours (barres posées dans un
## CanvasLayer), et elles restaient sinon grises et transparentes.
static func apply(tree: SceneTree) -> void:
	if tree != null and tree.root.theme == null:
		tree.root.theme = build()
	_tooltips(ThemeDB.get_default_theme())


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
