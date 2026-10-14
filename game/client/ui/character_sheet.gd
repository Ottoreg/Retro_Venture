class_name CharacterSheet
extends CanvasLayer
## Fiche du personnage (touche C) : niveau, expérience, PV, caractéristiques et points à répartir.

const GOLD := Color(0.95, 0.76, 0.3)
const STAT_HELP := {
	"vitalite": "+1 PV par point",
	"sagesse": "+1 % d'expérience par point",
	"force": "+1 % de dégâts d'acier et +1 initiative par point",
	"intelligence": "+1 % de dégâts de flamme et de soins, +1 initiative par point",
	"chance": "+1 % de dégâts de givre et +1 initiative par point",
	"agilite": "+1 % de dégâts de tempête et +1 initiative par point",
}
## Valeurs secondaires affichées : [clé de la fiche, nom, aide].
const DERIVED := [
	["pa", "PA", "Points d'action : pour lancer des sorts"],
	["pm", "PM", "Points de mouvement : une case par point en combat"],
	["initiative", "Initiative", "Ordre de jeu en combat : base de la Voie + Force, Intelligence, Chance et Agilité + équipement"],
	["prospection", "Prospection", "Chances de butin : 100 + Chance / 10 + équipement"],
	["dommages", "Dommages", "Dégâts bruts ajoutés à chaque ligne de dégâts, quel que soit l'élément (ni multipliés, ni réduits par les résistances)"],
	["critique", "Critique (%)", "Chance de coup critique d'un sort ordinaire (5 % + équipement) : dégâts, soins, boucliers et poisons × 1,5"],
]

var map_view: MapView

var _panel: PanelContainer
var _title: Label
var _subtitle: Label
var _xp_bar: ProgressBar
var _xp_label: Label
var _hp_label: Label
var _points_label: Label
var _stat_values := {}
var _stat_buttons := {}
## Valeurs secondaires : PA, PM, initiative, prospection.
var _derived_values := {}


func _ready() -> void:
	_build()
	_panel.visible = false


func setup(p_map_view: MapView) -> void:
	map_view = p_map_view
	map_view.character_changed.connect(refresh)
	map_view.combat_started.connect(func() -> void: _panel.visible = false)


func toggle() -> void:
	if map_view == null or map_view.mode == MapView.Mode.COMBAT:
		return
	_panel.visible = not _panel.visible
	refresh()


func is_open() -> bool:
	return _panel.visible


func refresh() -> void:
	if map_view == null or not _panel.visible:
		return
	var world := map_view.world
	var sheet := world.character.sheet(world.data)
	_title.text = sheet["nom"]
	_subtitle.text = "Niveau %d — %s %s" % [sheet["niveau"], sheet["race_nom"], sheet["voie_nom"]]
	var span := maxi(1, int(sheet["xp_suivant"]) - int(sheet["xp_niveau"]))
	_xp_bar.value = 100.0 * (int(sheet["xp"]) - int(sheet["xp_niveau"])) / span
	_xp_label.text = "Expérience : %d / %d" % [sheet["xp"], sheet["xp_suivant"]]
	_hp_label.text = "Points de vie : %d / %d" % [sheet["pv"], sheet["pv_max"]]
	var points: int = sheet["points"]
	_points_label.text = "Points à répartir : %d" % points
	_points_label.modulate = GOLD if points > 0 else Color(0.7, 0.7, 0.7)
	for stat_name: String in _stat_values:
		_stat_values[stat_name].text = str(sheet["caracteristiques"][stat_name])
		_stat_buttons[stat_name].disabled = points <= 0
	for key: String in _derived_values:
		_derived_values[key].text = str(sheet[key])


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_C:
		toggle()
		get_viewport().set_input_as_handled()


func _on_plus_pressed(stat_name: String) -> void:
	map_view.send_command({"type": Protocol.CMD_SPEND_POINTS, "entite": World.PLAYER_ID, "carac": stat_name, "points": 1})


# --- Construction des contrôles ----------------------------------------------------------------

func _build() -> void:
	_panel = PanelContainer.new()
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.offset_left = -330
	_panel.offset_right = -16
	_panel.offset_top = 70
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.1, 0.07, 0.95)
	style.border_color = Color(0.55, 0.42, 0.22)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(14)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_panel.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	_title = _label(22, GOLD)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var close := Button.new()
	close.text = "×"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(toggle)
	header.add_child(close)
	_subtitle = _label(15, Color(0.85, 0.82, 0.75))
	box.add_child(_subtitle)
	_xp_bar = ProgressBar.new()
	_xp_bar.show_percentage = false
	_xp_bar.custom_minimum_size = Vector2(0, 10)
	box.add_child(_xp_bar)
	_xp_label = _label(13, Color(0.75, 0.72, 0.65))
	box.add_child(_xp_label)
	_hp_label = _label(15, Color(0.95, 0.5, 0.45))
	box.add_child(_hp_label)
	_points_label = _label(16, GOLD)
	box.add_child(_points_label)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	box.add_child(grid)
	for stat_name in Character.STATS:
		var name_label := _label(15, Color.WHITE)
		name_label.text = Character.STAT_NAMES[stat_name]
		name_label.tooltip_text = STAT_HELP.get(stat_name, "")
		name_label.mouse_filter = Control.MOUSE_FILTER_PASS
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value_label := _label(15, Color.WHITE)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.custom_minimum_size = Vector2(40, 0)
		var plus := Button.new()
		plus.text = "+"
		plus.focus_mode = Control.FOCUS_NONE
		plus.tooltip_text = "Investir 1 point : %s" % STAT_HELP.get(stat_name, "")
		plus.pressed.connect(_on_plus_pressed.bind(stat_name))
		grid.add_child(name_label)
		grid.add_child(value_label)
		grid.add_child(plus)
		_stat_values[stat_name] = value_label
		_stat_buttons[stat_name] = plus
	var derived := GridContainer.new()
	derived.columns = 4
	derived.add_theme_constant_override("h_separation", 10)
	box.add_child(derived)
	for entry: Array in DERIVED:
		var name_label := _label(14, Color(0.8, 0.78, 0.7))
		name_label.text = entry[1]
		name_label.tooltip_text = entry[2]
		name_label.mouse_filter = Control.MOUSE_FILTER_PASS
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value_label := _label(14, Color.WHITE)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.custom_minimum_size = Vector2(36, 0)
		derived.add_child(name_label)
		derived.add_child(value_label)
		_derived_values[entry[0]] = value_label
	var hint := _label(12, Color(0.6, 0.58, 0.52))
	hint.text = "Touche C : ouvrir / fermer"
	box.add_child(hint)


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
