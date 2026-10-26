class_name CombatHud
extends CanvasLayer
## Bordures d'interface autour de la zone de jeu (`ScreenLayout`), toujours affichées. Barre du bas,
## comme dans Dofus : historique, points de vie dans un cœur rouge qui se vide, PA dans une étoile
## bleue, PM dans une case verte, sorts en icônes, bouton de tour (en combat) et menus. Bandes
## latérales : nom de la carte, minicarte et suivi des quêtes à gauche ; messages, puis ordre de jeu
## (ou résumé du personnage) à droite. Aussi : écran de fin de combat.

const BAR_HEIGHT := ScreenLayout.BOTTOM
## Hauteur réservée aux messages en haut de la bande droite (quatre lignes).
const MESSAGE_HEIGHT := 80.0
## Message quand le sac déborde (butin en surplus).
const OVERLOAD_TEXT := "Inventaire surchargé ! Faites de la place (vendre, jeter, ranger au coffre) pour pouvoir combattre à nouveau."
## Noms courts des éléments pour les résistances du combattant survolé.
const RESISTANCE_NAMES := {"acier": "Acier", "flamme": "Flamme", "givre": "Givre", "tempete": "Tempête", "sacre": "Sacré", "impie": "Impie"}
const SPELL_KEYS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0]
## Deuxième jeu de raccourcis : la rangée des chiffres d'un clavier AZERTY, sans Maj.
const SPELL_CHARS := "&é\"'(-è_çà"
## Clé des places de sorts créés encore vides dans `_spell_buttons`.
## Emplacements de la barre d'objets, hors combat (un peu plus petits que les sorts : la barre
## tient avec le bouton « S'asseoir » et la minicarte).
const ITEM_SLOTS := 8
const ITEM_SLOT_SIZE := 44.0
const EMPTY_SLOT_PREFIX := "_place_vide_"
const MENUS := [["personnage", "icone_personnage", "Personnage (C)"], ["inventaire", "icone_inventaire", "Inventaire (I)"],
	["sorts", "icone_sorts", "Sorts (S)"], ["metiers", "icone_metiers", "Métiers (J)"], ["carte", "icone_carte", "Carte du monde (M)"],
	["quetes", "icone_quetes", "Quêtes (Q)"]]

## Un bouton de menu de la barre : « personnage », « inventaire », « sorts », « metiers », « carte » ou « quetes ».
signal menu_pressed(menu: String)


## Jauge dessinée : PV dans un cœur qui se vide par le haut, PA dans une étoile, PM dans une case.
class Gauge extends Control:
	var kind := "pv"
	var value := 0
	var maximum := 0

	func show_values(p_value: int, p_maximum: int) -> void:
		if p_value != value or p_maximum != maximum:
			value = p_value
			maximum = p_maximum
			queue_redraw()

	func _draw() -> void:
		var center := size / 2.0
		var font := ThemeDB.fallback_font
		if kind == "pv":
			var empty := Art.texture("coeur_vide")
			var full := Art.texture("coeur_plein")
			var drawn := Vector2(64, 58)
			var origin := center - drawn / 2.0
			draw_texture_rect(empty, Rect2(origin, drawn), false)
			var ratio := clampf(float(value) / maxf(1.0, maximum), 0.0, 1.0)
			var source_top := full.get_height() * (1.0 - ratio)
			draw_texture_rect_region(full, Rect2(origin + Vector2(0, drawn.y * (1.0 - ratio)), Vector2(drawn.x, drawn.y * ratio)),
				Rect2(0, source_top, full.get_width(), full.get_height() - source_top))
			_number(font, center + Vector2(0, -2), str(value), 20)
			_number(font, center + Vector2(0, 14), "/%d" % maximum, 11)
		else:
			var image := "etoile_pa" if kind == "pa" else "case_pm"
			var drawn := Vector2(52, 52) if kind == "pa" else Vector2(60, 40)
			draw_texture_rect(Art.texture(image), Rect2(center - drawn / 2.0, drawn), false)
			_number(font, center + Vector2(0, 1), str(value), 20)

	func _number(font: Font, at: Vector2, text: String, font_size: int) -> void:
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var spot := at + Vector2(-width / 2.0, font_size * 0.36)
		draw_string_outline(font, spot, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, Color(0.1, 0.05, 0.02))
		draw_string(font, spot, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)


## États élémentaires de l'Arcaniste : 3 petites orbes, à la couleur de chaque état (du plus ancien
## en haut au plus récent en bas), grises quand la place est libre.
class ElementOrbs extends Control:
	var states: Array = []

	func _init() -> void:
		custom_minimum_size = Vector2(22, 72)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func show_states(p_states: Array) -> void:
		if p_states != states:
			states = p_states.duplicate()
			var names: PackedStringArray = []
			for i in Fighter.ELEMENT_STATE_MAX:
				names.append(SpellsWindow.ELEMENT_LABELS.get(states[i], states[i]) if i < states.size() else "libre")
			tooltip_text = "États élémentaires (Composition) : %s\n+%d %% de dégâts dans leur élément chacun" % [
				" · ".join(names), Fighter.ELEMENT_STATE_BONUS]
			queue_redraw()

	func _draw() -> void:
		for i in Fighter.ELEMENT_STATE_MAX:
			var center := Vector2(size.x / 2.0, size.y / 2.0 + (i - 1) * 22.0)
			var filled := i < states.size()
			var color: Color = MapView.element_color(states[i]) if filled else Color(0.22, 0.18, 0.14)
			draw_circle(center, 8.0, color)
			if filled:
				draw_circle(center + Vector2(-2.5, -2.5), 2.5, Color(1, 1, 1, 0.55))
			draw_arc(center, 8.0, 0.0, TAU, 24, Color(0.1, 0.06, 0.03), 1.5, true)


## Emplacement de sort : cadre, icône, raccourci et coût en PA. `empty` : place d'un sort créé pas
## encore remplie (Arcaniste). Clic gauche : choisir le sort ; clic droit : le lancer sur soi.
class SpellSlot extends Control:
	signal pressed
	signal self_cast
	var icon: Texture2D
	var key_label := ""
	var cost := 0
	var selected := false
	var usable := true
	var empty := false

	func _init() -> void:
		custom_minimum_size = Vector2(50, 50)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		# Accepté avant le signal : la barre peut être refaite (et ce contrôle retiré de l'arbre),
		# et un clic non accepté passerait à la carte en dessous (déplacement).
		if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			pressed.emit()
		elif click != null and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT:
			accept_event()
			self_cast.emit()

	func _draw() -> void:
		var frame := Rect2(Vector2(1, 1), Vector2(48, 48))
		if empty:
			draw_texture_rect(Art.texture("case_sort"), frame, false, Color(0.5, 0.5, 0.5, 0.7))
			draw_rect(frame.grow(-6), Color(0.75, 0.6, 1.0, 0.5), false, 1.5)
			var mark_font := ThemeDB.fallback_font
			var mark_width := mark_font.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
			draw_string(mark_font, Vector2(25 - mark_width / 2.0, 33), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.75, 0.6, 1.0, 0.7))
			return
		draw_texture_rect(Art.texture("case_sort"), frame, false)
		if icon != null:
			draw_texture_rect(icon, frame.grow(-3), false, Color.WHITE if usable else Color(0.45, 0.45, 0.45))
		if selected:
			draw_rect(frame.grow(-1), Color(1.0, 0.82, 0.3), false, 3.0)
		var font := ThemeDB.fallback_font
		draw_string_outline(font, Vector2(5, 15), key_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color.BLACK)
		draw_string(font, Vector2(5, 15), key_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.95, 0.8))
		var price := str(cost)
		var spot := Vector2(44 - font.get_string_size(price, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x, 45)
		draw_string_outline(font, spot, price, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color.BLACK)
		draw_string(font, spot, price, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.85, 1.0))


## Emplacement de la barre d'objets (hors combat). Vide et inactif tant que le jeu n'a pas
## d'objets consommables : la barre est seulement montrée.
class ItemSlot extends Control:
	var key_label := ""

	func _init() -> void:
		custom_minimum_size = Vector2(ITEM_SLOT_SIZE, ITEM_SLOT_SIZE)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _draw() -> void:
		var frame := Rect2(Vector2(1, 1), Vector2(ITEM_SLOT_SIZE - 2, ITEM_SLOT_SIZE - 2))
		draw_texture_rect(Art.texture("case_sort"), frame, false, Color(0.6, 0.6, 0.6, 0.8))
		var font := ThemeDB.fallback_font
		draw_string_outline(font, Vector2(5, 15), key_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color.BLACK)
		draw_string(font, Vector2(5, 15), key_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.95, 0.8, 0.6))


## Icône du bouton du mode tactique : un damier isométrique de 3 × 3 cases grises, plus claires et
## le bouton cerclé d'or quand le mode est actif. Dessinée (pas de glyphe : la police n'en a pas).
class TacticalIcon extends Control:
	var button: Button

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var on := button != null and button.button_pressed
		var fill := Color(0.86, 0.86, 0.84) if on else Color(0.6, 0.6, 0.58)
		var line := Color(0.2, 0.2, 0.2)
		var half := Vector2(5.0, 2.9)  # Demi-diagonales d'une case.
		var top := Vector2(size.x / 2.0, size.y / 2.0 - 3.0 * half.y)
		for row in 3:
			for col in 3:
				var c := top + Vector2((col - row) * half.x, (col + row + 1) * half.y)
				var diamond := PackedVector2Array([c + Vector2(0, -half.y), c + Vector2(half.x, 0),
						c + Vector2(0, half.y), c + Vector2(-half.x, 0)])
				draw_colored_polygon(diamond, fill.darkened(0.18) if (row + col) % 2 else fill)
				diamond.append(diamond[0])
				draw_polyline(diamond, line, 1.0, true)
		if on:
			draw_rect(Rect2(Vector2.ONE, size - Vector2(2, 2)), Color(1.0, 0.82, 0.3), false, 2.0)


## Portrait de l'ordre de jeu : le combattant dessiné en petit dans un cadre à la couleur de son
## camp, sa barre de PV en bas ; doré et plus grand quand c'est son tour. Nom et PV en infobulle.
class TurnPortrait extends Control:
	const SIZE := Vector2(44, 50)
	const CURRENT_SIZE := Vector2(52, 58)
	var actor_id := ""
	var look: Dictionary = {}
	var kind := ""
	var team := 0
	var hp := 0
	var max_hp := 1
	var current := false

	func _init() -> void:
		custom_minimum_size = SIZE
		size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		clip_contents = true
		mouse_filter = Control.MOUSE_FILTER_STOP

	## Met à jour le portrait d'après les données affichées par la carte (`MapView.actor`).
	func show_actor(data: Dictionary, is_current: bool) -> void:
		hp = int(data["hp"])
		max_hp = maxi(1, int(data["max_hp"]))
		team = clampi(int(data["team"]), 0, 1)
		kind = data.get("kind", "")
		tooltip_text = "%s\nPV %d / %d%s" % [data["name"], hp, max_hp, "\nC'est son tour" if is_current else ""]
		if is_current != current:
			current = is_current
			custom_minimum_size = CURRENT_SIZE if current else SIZE
		queue_redraw()

	func _draw() -> void:
		var frame := Rect2(Vector2.ZERO, size)
		var camp: Color = MapView.COLOR_TEAM[team]
		draw_rect(frame, Color(0.16, 0.12, 0.08).lerp(Color(camp, 1.0), 0.25))
		if look.has("rig"):
			# En buste : les jambes sous le cadre.
			var zoom := size.y / 52.0
			Rig.draw(self, look, Vector2(size.x / 2.0, size.y + 26.0 * zoom), {"facing": 1.0, "zoom": zoom})
		elif look.has("image"):
			# Un monstre dessiné d'un bloc : en entier, à la taille du cadre.
			var image := Art.texture(look["image"], look.get("couleurs", {}))
			var drawn := image.get_size() / Art.SCALE if image != null else size
			var zoom := minf((size.x - 4.0) / drawn.x, (size.y - 8.0) / drawn.y)
			var anchor := Art.anchor(look["image"]) * zoom
			var spot := Vector2((size.x - drawn.x * zoom) / 2.0, size.y - 8.0 - drawn.y * zoom) + anchor
			Art.draw(self, look["image"], spot, look.get("couleurs", {}), false, look.get("teinte", Color.WHITE), zoom)
		else:
			var font := ThemeDB.fallback_font
			var initial := kind.left(1).to_upper()
			draw_string(font, Vector2(0, size.y * 0.62), initial, HORIZONTAL_ALIGNMENT_CENTER, size.x, 22, Color.WHITE)
		var ratio := clampf(float(hp) / max_hp, 0.0, 1.0)
		var bar := Rect2(Vector2(3, size.y - 7), Vector2(size.x - 6, 4))
		draw_rect(bar, Color(0, 0, 0, 0.75))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), Color(0.3, 0.85, 0.3) if ratio > 0.3 else Color(0.9, 0.3, 0.2))
		draw_rect(frame.grow(-1), Color(1.0, 0.82, 0.3) if current else Color(camp, 1.0), false, 3.0 if current else 2.0)


## Ligne de l'ordre de jeu, dans la bande droite : le portrait, le nom (doré quand c'est son tour)
## et les PV.
class OrderRow extends HBoxContainer:
	var portrait := TurnPortrait.new()
	var _name := Label.new()
	var _hp := Label.new()

	func _init() -> void:
		add_theme_constant_override("separation", 6)
		add_child(portrait)
		var column := VBoxContainer.new()
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 0)
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(column)
		for label: Label in [_name, _hp]:
			label.clip_text = true
			label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			label.custom_minimum_size = Vector2(1, 0)
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			column.add_child(label)
		_name.add_theme_font_size_override("font_size", 12)
		_hp.add_theme_font_size_override("font_size", 11)
		_hp.add_theme_color_override("font_color", UiTheme.TEXT_DIM)

	func show_actor(data: Dictionary, is_current: bool) -> void:
		portrait.show_actor(data, is_current)
		_name.text = data["name"]
		_name.add_theme_color_override("font_color", UiTheme.GOLD if is_current else UiTheme.TEXT)
		_hp.text = "PV %d / %d" % [data["hp"], data["max_hp"]]


## Une case de la grille de composition : 3 orbes à la couleur des états, le nom du sort que
## « Fusion arcanique » en tirerait, et son raccourci.
class CompositionChoice extends Control:
	signal pressed
	var states: Array = []
	var created_name := ""
	var key_label := ""
	var current := false
	var _hovered := false

	func _init() -> void:
		custom_minimum_size = Vector2(108, 54)
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_entered.connect(func() -> void: _hovered = true; queue_redraw())
		mouse_exited.connect(func() -> void: _hovered = false; queue_redraw())

	func _gui_input(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		# Accepté avant le signal : choisir referme la grille (retirée de l'arbre aussitôt), et un
		# clic non accepté passerait à la carte en dessous (déplacement vers la case).
		if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			pressed.emit()

	func _draw() -> void:
		var frame := Rect2(Vector2(1, 1), size - Vector2(2, 2))
		draw_rect(frame, Color(0.32, 0.24, 0.42) if _hovered else Color(0.2, 0.15, 0.26))
		draw_rect(frame, Color(1.0, 0.82, 0.3) if current else Color(0.5, 0.4, 0.62), false, 2.0 if current else 1.0)
		for i in states.size():
			var center := Vector2(size.x / 2.0 + (i - 1) * 20.0, 18)
			draw_circle(center, 7.5, MapView.element_color(states[i]))
			draw_circle(center + Vector2(-2.5, -2.5), 2.2, Color(1, 1, 1, 0.55))
			draw_arc(center, 7.5, 0.0, TAU, 24, Color(0.1, 0.06, 0.03), 1.5, true)
		var font := ThemeDB.fallback_font
		var width := font.get_string_size(created_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(font, Vector2((size.x - width) / 2.0, 44), created_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.95, 0.8))
		draw_string_outline(font, Vector2(4, 12), key_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 4, Color.BLACK)
		draw_string(font, Vector2(4, 12), key_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 0.95, 0.8))


var map_view: MapView

var _bar: PanelContainer
var _hp_gauge: Gauge
var _pa_gauge: Gauge
var _pm_gauge: Gauge
var _spells_box: HBoxContainer
## Hors combat : barre d'objets (ITEM_SLOTS emplacements) à la place des sorts.
var _items_box: HBoxContainer
## Orbes des états élémentaires (Voies qui composent : Arcaniste).
var _orbs: ElementOrbs
## En combat, au survol d'un combattant : ses informations à la place de la barre de sorts.
var _target_box: HBoxContainer
var _target_name: Label
var _target_level: Label
var _target_stats: Label
var _target_resistances := {}
## Id du combattant survolé ("" si aucun).
var _target_id := ""
var _turn_button: Button
var _ready_styled := false
var _ready_pulse := 0.0
const READY_FILL := Color("3f7a2c")
const READY_PULSE_PERIOD := 1.4
## Bascule du mode tactique (en combat seulement ; touche T).
var _tactical_button: Button
## Hors combat : s'asseoir pour régénérer plus vite (touche A).
var _sit_button: Button
var _menu_buttons := {}
## Ordre de jeu, dans la bande droite : une ligne (portrait, nom, PV) par combattant vivant ;
## « Placement » à la place pendant le placement.
var _order_label: Label
var _order_box: VBoxContainer
## Lignes affichées : id → OrderRow, et ordre des ids affichés.
var _portraits: Dictionary = {}
var _shown_order: Array[String] = []
## Historique (combat, commerce), à gauche de la barre du bas, en combat comme en exploration.
var message_log: MessageLog
## Marchand de la dernière boutique ouverte (pour l'historique du commerce).
var _merchant_name := ""
var _message_label: Label
var _message_time := 0.0
var _result_panel: PanelContainer
var _result_title: Label
## Durée du combat, sous le titre.
var _result_info: Label
## Tableau des combattants (bandeaux « Gagnants » et « Perdants », une ligne par combattant).
var _result_rows: VBoxContainer
## Réveil après une défaite, sous le tableau.
var _result_detail: Label
var _overload_label: Label
## Emplacements de sorts affichés : id du sort → SpellSlot.
var _spell_buttons: Dictionary = {}
var _shown_spells: Array[String] = []
var _refresh_time := 0.0
## Bandes latérales (voir `_build_bands`).
var _left_band: PanelContainer
var _right_band: PanelContainer
## Emplacements de la minicarte et du suivi des quêtes, dans la bande gauche.
## Nom de la carte, en haut de la bande gauche (posé par la scène du monde).
var map_title: Label
var minimap_slot: Control
var quest_slot: Control
## Résumé du personnage, hors combat, dans la bande droite.
var _summary: VBoxContainer
var _summary_name: Label
var _summary_level: Label
var _summary_xp: ProgressBar
var _summary_money: Label
## Groupe de joueurs (multijoueur), sous le résumé : ses membres et « Quitter le groupe ».
var _party_box: VBoxContainer
var _party_lines: Label
## Temps restant du placement ou du tour (en ligne), sous les messages.
var _timer_label: Label
## Grille flottante d'un sort de composition (Arcaniste), ouverte au-dessus de son emplacement ou à
## la souris ; un fond transparent la ferme au clic ailleurs. `null` quand elle est fermée.
var _composition: Control
var _composition_spell := ""
var _composition_choices: PackedStringArray = []


func _ready() -> void:
	_build()
	_turn_button.visible = false
	_tactical_button.visible = false
	_order_label.visible = false
	_order_box.visible = false
	_result_panel.visible = false


func setup(p_map_view: MapView) -> void:
	map_view = p_map_view
	map_view.combat_started.connect(_on_combat_started)
	map_view.combat_state_changed.connect(_refresh)
	map_view.combat_message.connect(show_message)
	map_view.combat_logged.connect(message_log.add_line)
	map_view.shop_opened.connect(func(event: Dictionary) -> void: _merchant_name = event["nom"].get_slice(",", 0))
	map_view.trade_result.connect(_on_trade_result)
	map_view.combat_ended.connect(_on_combat_ended)
	map_view.exploration_resumed.connect(_on_exploration_resumed)
	map_view.character_changed.connect(_refresh_exploration)
	map_view.inventory_changed.connect(_refresh_exploration)
	map_view.hovered_cell_changed.connect(_on_hovered_cell_changed)
	map_view.sitting_changed.connect(_on_sitting_changed)
	map_view.party_changed.connect(_refresh_party)
	_refresh_exploration()
	_refresh_party()


func show_message(text: String) -> void:
	_message_label.text = text
	_message_label.modulate.a = 1.0
	_message_time = 1.8


func _process(delta: float) -> void:
	_pulse_ready_button(delta)
	if map_view != null:
		var left := ceili(map_view.turn_time_left) if map_view.mode == MapView.Mode.COMBAT else 0
		_timer_label.visible = left > 0
		_timer_label.text = "%s : %d s" % ["Placement" if map_view.is_placement() else "Tour", left]
	if _message_time > 0.0:
		_message_time -= delta
		_message_label.modulate.a = clampf(_message_time / 0.5, 0.0, 1.0)
	# Hors combat, les PV remontent tout seuls : la jauge suit.
	_refresh_time += delta
	if _refresh_time >= 0.5:
		_refresh_time = 0.0
		_refresh_exploration()


func _unhandled_key_input(event: InputEvent) -> void:
	if map_view == null or not event.is_pressed() or event.is_echo():
		return
	if (event as InputEventKey).keycode == KEY_H:
		message_log.toggle_fold()
		get_viewport().set_input_as_handled()
		return
	if map_view.mode != MapView.Mode.COMBAT:
		if (event as InputEventKey).keycode == KEY_A:
			map_view.toggle_sit()
			get_viewport().set_input_as_handled()
		return
	var key := (event as InputEventKey).keycode
	var index := spell_key_index(event as InputEventKey)
	var fighter := map_view.player_fighter()
	if _composition != null and (index >= 0 or event.is_action_pressed("ui_cancel")):
		# Grille ouverte : les touches des sorts choisissent une combinaison.
		if index >= 0 and index < _composition_choices.size():
			_choose_composition(_composition_choices[index])
		else:
			close_composition()
		get_viewport().set_input_as_handled()
	elif index >= 0 and fighter != null and index < fighter.spells.size():
		_use_spell(fighter.spells[index].id, Rect2(get_viewport().get_mouse_position(), Vector2.ZERO))
		get_viewport().set_input_as_handled()
	elif key == KEY_T:
		toggle_tactical()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and map_view.selected_spell != "":
		map_view.select_spell(map_view.selected_spell)
		get_viewport().set_input_as_handled()


## Place dans la barre du sort d'une touche (0 pour la première), ou -1 : chiffre, caractère de la
## rangée AZERTY (& é " ' ( - è _ ç à), ou touche à la place d'un chiffre quel que soit le clavier.
static func spell_key_index(event: InputEventKey) -> int:
	var index := SPELL_KEYS.find(event.keycode)
	if index < 0 and event.unicode > 0:
		index = SPELL_CHARS.find(char(event.unicode))
	if index < 0 and event.physical_keycode != KEY_NONE:
		index = SPELL_KEYS.find(event.physical_keycode)
	return index


## Icône d'un sort (l'attaque de l'arme prend l'icône de l'arme portée).
static func spell_icon(spell_id: String, world: ClientState) -> Texture2D:
	var image := "sort_" + spell_id
	if spell_id == "arme" and world != null:
		var weapon := world.character.inventory.equipped_entry("arme")
		image = Art.manifest().get("icones_armes", {}).get(weapon.get("objet", ""), "sort_arme_epee")
	return Art.texture(image if Art.has_image(image) else "sort_inconnu")


## Remplit la barre de sorts (si la liste a changé).
## Remplit la barre de sorts (si la liste a changé). Une Voie qui crée des sorts (Arcaniste) a ses
## places de sorts créés au bout de la barre, vides tant qu'elles ne sont pas remplies, et ses orbes
## d'états élémentaires à côté des jauges.
func _show_spells(spells: Array[Spell]) -> void:
	var creates := false
	for spell in spells:
		if spell.composes():
			creates = true
	var created_count := 0
	if creates:
		for spell in spells:
			if _is_created(spell, spells):
				created_count += 1
	var ids: Array[String] = []
	for spell in spells:
		ids.append(spell.id)
	var empty_slots := maxi(0, Fighter.CREATED_SPELL_SLOTS - created_count) if creates else 0
	for i in empty_slots:
		ids.append(EMPTY_SLOT_PREFIX + str(i))
	_orbs.visible = creates
	if ids == _shown_spells and _spell_buttons.size() == ids.size():
		return
	_shown_spells = ids
	for child in _spells_box.get_children():
		_spells_box.remove_child(child)  # Hors de la boîte tout de suite : les nouveaux prennent leur place.
		child.queue_free()
	_spell_buttons.clear()
	for i in ids.size():
		var slot := SpellSlot.new()
		slot.key_label = str((i + 1) % 10) if i < SPELL_KEYS.size() else ""
		if i < spells.size():
			var spell := spells[i]
			slot.icon = spell_icon(spell.id, map_view.world)
			slot.cost = spell.pa_cost
			slot.tooltip_text = _spell_tooltip(spell)
			if i < SPELL_KEYS.size():
				slot.tooltip_text += "\nRaccourci : %s ou %s" % [slot.key_label, SPELL_CHARS[i]]
			slot.tooltip_text += "\nClic droit : lancer sur soi"
			slot.pressed.connect(_on_spell_pressed.bind(spell.id))
			slot.self_cast.connect(_on_spell_self_cast.bind(spell.id))
		else:
			slot.empty = true
			slot.usable = false
			slot.tooltip_text = "Place pour un sort créé (vide)\nChoisissez 3 états élémentaires avec Composition, puis lancez Fusion arcanique."
		_spells_box.add_child(slot)
		_spell_buttons[ids[i]] = slot


## Le sort est-il un sort créé (une combinaison d'un sort « creer_sort » de la liste) ?
static func _is_created(spell: Spell, spells: Array[Spell]) -> bool:
	for other in spells:
		if spell in other.create_effect().get("sorts", {}).values():
			return true
	return false


func _on_spell_pressed(spell_id: String) -> void:
	if map_view.mode == MapView.Mode.COMBAT:
		var slot: SpellSlot = _spell_buttons[spell_id]
		_use_spell(spell_id, slot.get_global_rect(), slot)


## Clic droit sur un sort : lancé sur soi (un sort de composition ouvre sa grille, comme au clic).
func _on_spell_self_cast(spell_id: String) -> void:
	if map_view.mode != MapView.Mode.COMBAT:
		return
	var fighter := map_view.player_fighter()
	var spell: Spell = fighter.get_spell(spell_id) if fighter != null else null
	if spell != null and not spell.state_choices().is_empty():
		_on_spell_pressed(spell_id)
	else:
		close_composition()
		map_view.cast_on_self(spell_id)


## Choisit un sort en combat ; un sort de composition des états ouvre sa grille au-dessus de
## `slot` (l'emplacement cliqué) ou de `anchor` (la souris, pour un raccourci) ; un 2e appel la referme.
func _use_spell(spell_id: String, anchor: Rect2, slot: Control = null) -> void:
	var fighter := map_view.player_fighter()
	var spell: Spell = fighter.get_spell(spell_id) if fighter != null else null
	if spell == null or spell.state_choices().is_empty():
		close_composition()
		map_view.select_spell(spell_id)
	elif _composition != null and _composition_spell == spell_id:
		close_composition()
	else:
		open_composition(spell, anchor, slot)


## Ouvre la grille des combinaisons de `spell` : chaque case montre ses 3 états et le sort que
## « Fusion arcanique » en tirerait ; celle des états actuels est encadrée.
func open_composition(spell: Spell, anchor: Rect2, slot: Control = null) -> void:
	close_composition()
	var fighter := map_view.player_fighter()
	if fighter == null or not map_view.can_plan():
		return
	if map_view.selected_spell != "":
		map_view.select_spell(map_view.selected_spell)
	var created := {}
	for other in fighter.spells:
		created.merge(other.create_effect().get("sorts", {}))
	var current := Spell.combination_key(fighter.element_states) if fighter.element_states.size() == Fighter.ELEMENT_STATE_MAX else ""
	_composition_spell = spell.id
	_composition_choices = spell.state_choices()
	var veil := Control.new()
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	veil.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			veil.accept_event()  # Un clic à côté referme la grille sans agir sur la carte.
			close_composition())
	add_child(veil)
	_composition = veil
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.13, 0.1, 0.16, 0.97)))
	veil.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := _label(13, Color(0.85, 0.75, 1.0))
	title.text = "%s : choisissez vos 3 états" % spell.display_name
	box.add_child(title)
	var grid := GridContainer.new()
	grid.columns = ceili(sqrt(_composition_choices.size()))
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	box.add_child(grid)
	for i in _composition_choices.size():
		var key := _composition_choices[i]
		var choice := CompositionChoice.new()
		choice.states = Array(key.split("+"))
		var result: Spell = created.get(key)
		choice.created_name = result.display_name if result != null else ""
		choice.key_label = str((i + 1) % 10) if i < SPELL_KEYS.size() else ""
		choice.current = key == current
		choice.tooltip_text = MapView.element_states_text(choice.states) + (" » " + choice.created_name if result != null else "")
		choice.pressed.connect(_choose_composition.bind(key))
		grid.add_child(choice)
	_place_composition(panel, anchor, slot)
	# Encore une fois après la mise en page (une barre qui vient de changer n'est pas encore placée).
	_place_composition.call_deferred(panel, anchor, slot)


## Pose la grille au-dessus de `slot` (s'il y en a un) ou de `anchor`, centrée, sans sortir de l'écran.
func _place_composition(panel: Control, anchor: Rect2, slot: Control) -> void:
	if not is_instance_valid(panel):
		return
	if slot != null and _spell_buttons.has(_composition_spell):
		anchor = (_spell_buttons[_composition_spell] as Control).get_global_rect()  # La barre a pu être refaite.
	var screen := get_viewport().get_visible_rect().size
	var wanted := panel.get_combined_minimum_size()
	var spot := Vector2(anchor.get_center().x - wanted.x / 2.0, anchor.position.y - wanted.y - 6.0)
	panel.position = Vector2(clampf(spot.x, 4.0, maxf(4.0, screen.x - wanted.x - 4.0)), clampf(spot.y, 4.0, maxf(4.0, screen.y - wanted.y - 4.0)))


func close_composition() -> void:
	if _composition != null:
		_composition.queue_free()
		remove_child(_composition)
		_composition = null
		_composition_spell = ""
		_composition_choices = []


## Combinaison choisie dans la grille (« flamme+flamme+givre »).
func _choose_composition(states: String) -> void:
	var spell_id := _composition_spell
	close_composition()
	map_view.cast_composition(spell_id, states)


## La grille ouverte (pour les tests) : ses combinaisons, dans l'ordre, ou vide si elle est fermée.
func composition_choices() -> PackedStringArray:
	return _composition_choices.duplicate()


## Position de la grille ouverte à l'écran (pour les tests), ou `Rect2()`.
func composition_rect() -> Rect2:
	return (_composition.get_child(0) as Control).get_global_rect() if _composition != null else Rect2()


# --- Réactions aux événements de la carte ------------------------------------------------------

## Barre du bas (la minicarte s'y pose).
func bar() -> Control:
	return _bar


func _on_combat_started() -> void:
	_result_panel.visible = false
	_summary.visible = false
	_turn_button.visible = true
	_tactical_button.visible = true
	_tactical_button.set_pressed_no_signal(map_view.tactical)
	_sit_button.visible = false
	_items_box.visible = false
	_spells_box.visible = true
	message_log.start_combat()
	_shown_spells.clear()
	_shown_order.clear()  # Mêmes ids d'un combat à l'autre, pas forcément les mêmes monstres.
	var fighter := map_view.player_fighter()
	if fighter != null:
		_show_spells(fighter.spells)
	for menu: String in _menu_buttons:
		_menu_buttons[menu].disabled = true
	show_message("Choisissez un cercle bleu, puis « Prêt »")
	_refresh()


# --- Combattant survolé ------------------------------------------------------------------------

## Survol d'une case en combat : un combattant vivant y est-il ? Ses infos remplacent les sorts.
func _on_hovered_cell_changed(cell: Vector2i, _description: String) -> void:
	var fighter: Fighter = null
	if map_view.mode == MapView.Mode.COMBAT and map_view.world.combat != null:
		fighter = map_view.world.combat.fighter_at(cell)
	_target_id = fighter.id if fighter != null else ""
	_show_target()


func _show_target() -> void:
	var fighter: Fighter = null
	if not _target_id.is_empty() and map_view.mode == MapView.Mode.COMBAT and map_view.world.combat != null:
		fighter = map_view.world.combat.get_fighter(_target_id)
	if fighter == null or not fighter.is_alive():
		_target_id = ""
		_target_box.visible = false
		_spells_box.visible = map_view.mode == MapView.Mode.COMBAT
		return
	var shown := map_view.actor(fighter.id)  # Ce qu'affiche la carte (les animations peuvent être en retard).
	_target_name.text = fighter.display_name
	_target_name.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0) if fighter.team == Fighter.TEAM_PLAYERS else Color(1.0, 0.62, 0.5))
	_target_level.text = "Niveau %d" % fighter.level  # Pour un monstre, celui tiré à son apparition.
	# PA et PM : ce qu'il lui reste pendant son tour, sinon ce qu'il aura au prochain (PM retirés compris).
	var pa := fighter.next_turn_pa()
	var pm := fighter.next_turn_pm()
	if map_view.current_turn == fighter.id:
		pa = shown.get("pa", fighter.pa)
		pm = shown.get("pm", fighter.pm)
	_target_stats.text = "PV %d / %d%s\nPA %d / %d   ·   PM %d / %d" % [shown.get("hp", fighter.hp), fighter.max_hp,
		"   ·   bouclier %d" % shown["bouclier"] if int(shown.get("bouclier", 0)) > 0 else "",
		pa, fighter.max_pa, pm, fighter.max_pm]
	var states: PackedStringArray = []
	for state: Dictionary in fighter.states_snapshot():
		states.append(MapView.state_text(state))
	if not states.is_empty():
		_target_stats.text += "\n" + "   ·   ".join(states)
	if not fighter.element_states.is_empty():
		_target_stats.text += "\nÉtats élémentaires : " + MapView.element_states_text(fighter.element_states)
	for element: String in _target_resistances:
		var label: Label = _target_resistances[element]
		label.text = "%s %s" % [RESISTANCE_NAMES[element], percent_text(fighter.resistance(element))]
	_target_box.visible = true
	_spells_box.visible = false


## « +10 % », « -5 % », « +12,5 % », « 0 % ».
static func percent_text(value: float) -> String:
	if is_zero_approx(value):
		return "0 %"
	var text := "%+d" % roundi(value) if is_equal_approx(value, roundf(value)) else ("%+.1f" % value).replace(".", ",")
	return text + " %"


func _on_combat_ended(result: Dictionary) -> void:
	_turn_button.visible = false
	_order_label.visible = false
	_order_box.visible = false
	var victory: bool = result["vainqueur"] == Fighter.TEAM_PLAYERS
	_result_title.text = "Victoire !" if victory else "Défaite…"
	var turns := int(result.get("tours", 0))
	_result_info.text = "Combat terminé" + (" · durée : %d tour%s" % [turns, "s" if turns > 1 else ""] if turns > 0 else "")
	_result_detail.text = "" if victory else MapView.wake_up_text(result.get("reveil", {}))
	_result_detail.visible = not _result_detail.text.is_empty()
	_overload_label.visible = result.get("surcharge", false)
	for child in _result_rows.get_children():
		child.queue_free()
	_result_rows.add_child(_result_header())
	var roster: Array = result.get("combattants", [])
	if roster.is_empty() and map_view != null:
		roster = [{"id": map_view.world.player_id, "nom": map_view.world.player_name, "niveau": map_view.world.character.level,
			"equipe": Fighter.TEAM_PLAYERS, "vivant": victory}]
	for winners: bool in [true, false]:
		var rows := roster.filter(func(entry: Dictionary) -> bool: return (int(entry["equipe"]) == int(result["vainqueur"])) == winners)
		if rows.is_empty():
			continue
		_result_rows.add_child(_result_band("Gagnants" if winners else "Perdants", winners))
		for i in rows.size():
			_result_rows.add_child(_result_row(rows[i], result, i % 2 == 1))
	_result_panel.visible = true


## Colonnes du tableau de fin, comme celui de Dofus Rétro : nom, niveau, jauge d'expérience, XP et
## brumes gagnées, butin.
const RESULT_COLUMNS := [["Nom", 190], ["Niv.", 64], ["Expérience", 150], ["XP", 72], ["Brumes", 60], ["Butin", 248]]


func _result_header() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for column: Array in RESULT_COLUMNS:
		var cell := _label(13, UiTheme.TEXT_DIM)
		cell.text = column[0]
		cell.custom_minimum_size.x = column[1]
		if column[0] != "Nom":
			cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(_cell(cell))
	return _result_strip(row, Color(0, 0, 0, 0), 0)


## Bandeau d'un camp : doré pour les gagnants, rouge sombre pour les perdants.
func _result_band(text: String, winners: bool) -> Control:
	var title := _label(15, UiTheme.GOLD if winners else Color(0.9, 0.5, 0.42))
	title.text = text
	var fill := Color("4a3622") if winners else Color("3e2119")
	return _result_strip(title, fill, 1, UiTheme.BRONZE if winners else Color("6e3426"))


## Ligne d'un combattant. Les gains (XP, brumes, butin) vont au joueur ; un combattant tombé est grisé.
func _result_row(entry: Dictionary, result: Dictionary, odd: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var is_player: bool = entry["id"] == map_view.world.player_id
	var alive: bool = entry.get("vivant", true)
	var text_color := UiTheme.TEXT if alive else UiTheme.TEXT_DIM
	var cells: Array[Control] = []
	var name_label := _label(15, Color(1.0, 0.9, 0.6) if is_player and alive else text_color)
	name_label.text = str(entry["nom"]) + ("" if alive else " (K.O.)")
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.clip_text = true
	cells.append(name_label)
	var levels: Array = result.get("niveaux", []) if is_player else []
	var level_label := _label(15, UiTheme.GOLD if not levels.is_empty() else text_color)
	level_label.text = "%d » %d" % [int(entry["niveau"]), int(levels[-1])] if not levels.is_empty() else str(int(entry["niveau"]))
	if not levels.is_empty():
		level_label.tooltip_text = "Niveau %d atteint !" % int(levels[-1])
		level_label.mouse_filter = Control.MOUSE_FILTER_STOP
	cells.append(level_label)
	cells.append(_xp_gauge() if is_player and map_view != null else Control.new())
	var xp_label := _label(15, Color(0.75, 0.9, 1.0))
	var coins_label := _label(15, UiTheme.GOLD)
	var loot := HFlowContainer.new()
	loot.add_theme_constant_override("h_separation", 3)
	loot.add_theme_constant_override("v_separation", 3)
	if is_player:
		xp_label.text = "+%d" % int(result.get("xp", 0)) if int(result.get("xp", 0)) > 0 else "0"
		coins_label.text = "+%d" % int(result.get("ecus", 0)) if int(result.get("ecus", 0)) > 0 else "0"
		for drop: Dictionary in result.get("butin", []):
			loot.add_child(_loot_slot(drop, 34))
	cells.append(xp_label)
	cells.append(coins_label)
	cells.append(loot)
	for i in cells.size():
		var cell := cells[i]
		cell.custom_minimum_size.x = RESULT_COLUMNS[i][1]
		if cell is Label and i > 0:
			cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(_cell(cell))
	return _result_strip(row, Color(UiTheme.WOOD_LIGHT, 0.35) if odd else Color(UiTheme.INK, 0.6), 0)


## Jauge d'expérience du joueur après le combat, avec le pourcentage du niveau en cours.
func _xp_gauge() -> Control:
	var character: Character = map_view.world.character
	var gauge := ProgressBar.new()
	gauge.custom_minimum_size = Vector2(0, 16)
	gauge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gauge.show_percentage = false
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.06, 0.045, 0.03)
	back.border_color = UiTheme.BRONZE
	back.set_border_width_all(1)
	back.set_corner_radius_all(3)
	gauge.add_theme_stylebox_override("background", back)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.36, 0.62, 0.86)
	fill.set_corner_radius_all(3)
	gauge.add_theme_stylebox_override("fill", fill)
	var floor_xp := Character.xp_for_level(character.level)
	var next_xp := Character.xp_for_level(character.level + 1)
	gauge.max_value = 1.0
	gauge.step = 0.0
	gauge.value = 1.0 if character.level >= Character.MAX_LEVEL else clampf(float(character.xp - floor_xp) / (next_xp - floor_xp), 0.0, 1.0)
	gauge.tooltip_text = "%d / %d XP" % [character.xp, next_xp] if character.level < Character.MAX_LEVEL else "Niveau maximal"
	var percent := _label(11, Color.WHITE)
	percent.text = "%d %%" % floori(gauge.value * 100)
	percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	percent.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	percent.set_anchors_preset(Control.PRESET_FULL_RECT)
	percent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gauge.add_child(percent)
	return gauge


## Une cellule du tableau, centrée verticalement dans sa ligne.
func _cell(cell: Control) -> Control:
	cell.size_flags_vertical = Control.SIZE_SHRINK_CENTER if cell is Label or cell is ProgressBar else Control.SIZE_FILL
	return cell


## Bande pleine largeur du tableau (en-tête, bandeau de camp, ligne).
func _result_strip(content: Control, fill: Color, border: int, edge := UiTheme.BRONZE) -> PanelContainer:
	var strip := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(border)
	style.set_corner_radius_all(3)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	strip.add_theme_stylebox_override("panel", style)
	strip.add_child(content)
	return strip


## Case du butin : l'icône sur un fond de la couleur de la rareté, la quantité en bas, le nom en
## infobulle.
func _loot_slot(drop: Dictionary, size := 52) -> Control:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(size, size)
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	var quantity := int(drop["quantite"])
	slot.tooltip_text = "%s%s" % [drop["nom"], " ×%d" % quantity if quantity > 1 else ""]
	var style := _panel_style(Color(InventoryWindow.rarity_color(drop["rarete"]), 0.18))
	style.border_color = InventoryWindow.rarity_color(drop["rarete"]).darkened(0.3)
	style.set_border_width_all(1)
	style.set_content_margin_all(2)
	slot.add_theme_stylebox_override("panel", style)
	var icon := TextureRect.new()
	icon.texture = InventoryWindow.item_icon(drop.get("objet", ""))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon)
	if quantity > 1:
		var amount := _label(11 if size < 44 else 13, Color.WHITE)
		amount.text = str(quantity)
		amount.size_flags_horizontal = Control.SIZE_SHRINK_END
		amount.size_flags_vertical = Control.SIZE_SHRINK_END
		amount.add_theme_color_override("font_outline_color", Color.BLACK)
		amount.add_theme_constant_override("outline_size", 4)
		amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(amount)
	return slot


func _on_exploration_resumed() -> void:
	close_composition()
	_target_id = ""
	_summary.visible = true
	_show_target()
	_turn_button.visible = false
	_tactical_button.visible = false
	_sit_button.visible = true
	_on_sitting_changed(map_view.world.sitting)
	_order_label.visible = false
	_order_box.visible = false
	for menu: String in _menu_buttons:
		_menu_buttons[menu].disabled = false
	_shown_spells.clear()
	_refresh_exploration()


## Achat ou vente réussi : une ligne dans le canal du commerce (objet, quantité, marchand, prix).
func _on_trade_result(event: Dictionary) -> void:
	if event["type"] != Protocol.EVT_TRADE:
		return
	message_log.add_entry(MessageLog.CHANNEL_TRADE, trade_line(event, _merchant_name))


static func trade_line(event: Dictionary, merchant: String) -> String:
	var amount := " ×%d" % event["quantite"] if int(event["quantite"]) > 1 else ""
	var where := " chez %s" % merchant if not merchant.is_empty() else ""
	if event["operation"] == "achat":
		return "[color=#e8b04a]Achat[/color] : %s%s%s, [color=#ff8a70]−%d brumes[/color]" % [event["nom"], amount, where, event["prix"]]
	return "[color=#e8b04a]Vente[/color] : %s%s%s, [color=#8fe07a]+%d brumes[/color]" % [event["nom"], amount, where, event["prix"]]


## Le récap de fin de combat ne bloque rien : le combat est déjà fini et le joueur reprend
## l'exploration dessous ; « Fermer », Échap ou le combat suivant le referment.
func is_result_open() -> bool:
	return _result_panel.visible


func close_result() -> void:
	_result_panel.visible = false


## Mode tactique : vue simplifiée de la grille, retenue d'un combat à l'autre.
func toggle_tactical() -> void:
	map_view.tactical = not map_view.tactical
	_tactical_button.set_pressed_no_signal(map_view.tactical)


func _on_sitting_changed(sitting: bool) -> void:
	_sit_button.set_pressed_no_signal(sitting)
	_sit_button.text = "Se lever" if sitting else "S'asseoir"


func _on_turn_button_pressed() -> void:
	if map_view.is_placement():
		map_view.request_start_fight()
	else:
		map_view.request_end_turn()


## Hors combat : PV, PA et PM du personnage, barre d'objets à la place des sorts (les sorts se
## consultent dans leur fenêtre, touche S).
func _refresh_exploration() -> void:
	if map_view == null or map_view.world == null or map_view.mode == MapView.Mode.COMBAT:
		return
	var world := map_view.world
	var sheet := world.character.sheet(world.data)
	_hp_gauge.show_values(int(sheet["pv"]), int(sheet["pv_max"]))
	_pa_gauge.show_values(int(sheet["pa"]), int(sheet["pa"]))
	_pm_gauge.show_values(int(sheet["pm"]), int(sheet["pm"]))
	_spells_box.visible = false
	_items_box.visible = true
	_orbs.visible = false  # Les états élémentaires ne durent qu'un combat.
	_show_summary(sheet)


## En combat : met à jour la barre à partir de ce qu'affiche la carte.
func _refresh() -> void:
	if map_view == null or map_view.mode != MapView.Mode.COMBAT:
		return
	if not _target_id.is_empty():
		_show_target()
	var player := map_view.actor(map_view.world.player_id)
	if not player.is_empty():
		_hp_gauge.show_values(int(player["hp"]), int(player["max_hp"]))
		_pa_gauge.show_values(int(player["pa"]), int(player["pa"]))
		_pm_gauge.show_values(int(player["pm"]), int(player["pm"]))
	var player_turn := map_view.can_plan()
	if not player_turn:
		close_composition()
	if map_view.is_placement():
		_turn_button.text = "Prêt"
		_turn_button.disabled = map_view.is_busy()
	else:
		_turn_button.text = "Fin du tour"
		_turn_button.disabled = not player_turn
	_style_turn_button(map_view.is_placement())
	_orbs.show_states(player.get("etats_elementaires", []))
	var fighter := map_view.player_fighter()
	if fighter != null:
		_show_spells(fighter.spells)  # Un sort créé change la barre (Arcaniste).
	for spell_id: String in _spell_buttons:
		var slot: SpellSlot = _spell_buttons[spell_id]
		var spell: Spell = fighter.get_spell(spell_id) if fighter != null else null
		slot.usable = player_turn and spell != null and fighter.cast_blocker(spell).is_empty()
		slot.selected = spell_id == map_view.selected_spell
		slot.queue_redraw()
	_show_order()


## Placement : « Prêt » en vert et or, plus grand, qui pulse doucement pour qu'on le trouve ;
## « Fin du tour » garde le style des autres boutons.
func _style_turn_button(ready: bool) -> void:
	if ready == _ready_styled:
		return
	_ready_styled = ready
	_ready_pulse = 0.0
	_turn_button.self_modulate = Color.WHITE
	if not ready:
		for state: String in ["normal", "hover", "pressed", "hover_pressed"]:
			_turn_button.remove_theme_stylebox_override(state)
		_turn_button.remove_theme_font_size_override("font_size")
		_turn_button.remove_theme_color_override("font_color")
		_turn_button.remove_theme_color_override("font_outline_color")
		_turn_button.remove_theme_constant_override("outline_size")
		return
	_turn_button.add_theme_stylebox_override("normal", _ready_style(READY_FILL, UiTheme.GOLD))
	_turn_button.add_theme_stylebox_override("hover", _ready_style(READY_FILL.lightened(0.18), Color("f3d68a")))
	_turn_button.add_theme_stylebox_override("pressed", _ready_style(READY_FILL.darkened(0.25), UiTheme.GOLD))
	_turn_button.add_theme_stylebox_override("hover_pressed", _ready_style(READY_FILL.darkened(0.25), UiTheme.GOLD))
	_turn_button.add_theme_font_size_override("font_size", 22)
	_turn_button.add_theme_color_override("font_color", Color.WHITE)
	_turn_button.add_theme_color_override("font_outline_color", Color(0.05, 0.12, 0.03))
	_turn_button.add_theme_constant_override("outline_size", 4)


func _ready_style(fill: Color, edge: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(edge, 0.45)
	style.shadow_size = 6
	style.content_margin_left = 10
	style.content_margin_right = 10
	return style


func _pulse_ready_button(delta: float) -> void:
	if not _ready_styled or _turn_button.disabled:
		if _turn_button != null:
			_turn_button.self_modulate = Color.WHITE
		return
	_ready_pulse = fmod(_ready_pulse + delta, READY_PULSE_PERIOD)
	var glow := 0.5 + 0.5 * sin(_ready_pulse / READY_PULSE_PERIOD * TAU)
	_turn_button.self_modulate = Color.WHITE.lerp(Color(1.25, 1.2, 0.9), glow)


## Ordre de jeu : une ligne par combattant vivant, dans l'ordre, refaite quand un combattant
## meurt ; « Placement » avant le début du combat.
func _show_order() -> void:
	var placement := map_view.turn_order.is_empty()
	_order_label.visible = placement
	_order_box.visible = not placement
	var alive: Array[String] = []
	for actor_id in map_view.turn_order:
		var data := map_view.actor(actor_id)
		if not data.is_empty() and data["alive"]:
			alive.append(actor_id)
	if alive != _shown_order:
		_shown_order = alive
		for child in _order_box.get_children():
			_order_box.remove_child(child)
			child.queue_free()
		_portraits.clear()
		for actor_id in alive:
			var line := OrderRow.new()
			line.portrait.actor_id = actor_id
			line.portrait.look = map_view.actor_look(actor_id)
			_order_box.add_child(line)
			_portraits[actor_id] = line
	for actor_id: String in _portraits:
		(_portraits[actor_id] as OrderRow).show_actor(map_view.actor(actor_id), actor_id == map_view.current_turn)


## Ids des lignes de l'ordre de jeu, dans l'ordre (pour les tests).
func order_portraits() -> Array[String]:
	return _shown_order.duplicate()


static func _spell_tooltip(spell: Spell) -> String:
	return "\n".join(SpellsWindow.describe(spell))


# --- Construction des contrôles ----------------------------------------------------------------

func _build() -> void:
	_bar = PanelContainer.new()
	_bar.anchor_left = 0.0
	_bar.anchor_right = 1.0
	_bar.anchor_top = 1.0
	_bar.anchor_bottom = 1.0
	_bar.offset_top = -BAR_HEIGHT
	_bar.add_theme_stylebox_override("panel", _panel_style(Color(0.13, 0.1, 0.07, 0.97)))
	add_child(_bar)

	# Barre du bas : l'historique à gauche (comme le chat de Dofus), au milieu les jauges et les
	# boutons au-dessus des sorts (ou des objets), les menus à droite.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_bar.add_child(row)
	message_log = MessageLog.new()
	row.add_child(message_log)
	row.add_child(VSeparator.new())
	var middle := VBoxContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	middle.add_theme_constant_override("separation", 10)
	row.add_child(middle)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 14)
	middle.add_child(top_row)
	var bottom_row := HBoxContainer.new()
	bottom_row.custom_minimum_size = Vector2(0, 56)
	middle.add_child(bottom_row)

	_hp_gauge = _gauge("pv", Vector2(70, 72), "Points de vie")
	_pa_gauge = _gauge("pa", Vector2(56, 72), "Points d'action (PA) : pour lancer des sorts")
	_pm_gauge = _gauge("pm", Vector2(64, 72), "Points de mouvement (PM) : une case par point")
	for gauge in [_hp_gauge, _pa_gauge, _pm_gauge]:
		top_row.add_child(gauge)
	_orbs = ElementOrbs.new()
	_orbs.visible = false
	_orbs.show_states([])
	top_row.add_child(_orbs)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(spacer)

	_spells_box = HBoxContainer.new()
	_spells_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_spells_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_spells_box.add_theme_constant_override("separation", 4)
	bottom_row.add_child(_spells_box)
	_items_box = HBoxContainer.new()
	_items_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_items_box.add_theme_constant_override("separation", 4)
	bottom_row.add_child(_items_box)
	for i in ITEM_SLOTS:
		var item_slot := ItemSlot.new()
		item_slot.key_label = str(i + 1)
		item_slot.tooltip_text = "Emplacement d'objet : les consommables (à venir) s'y rangeront"
		_items_box.add_child(item_slot)
	_build_target_box(bottom_row)

	_turn_button = Button.new()
	_turn_button.custom_minimum_size = Vector2(140, 50)
	_turn_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_turn_button.focus_mode = Control.FOCUS_NONE
	_turn_button.pressed.connect(_on_turn_button_pressed)
	top_row.add_child(_turn_button)
	_tactical_button = Button.new()
	_tactical_button.toggle_mode = true
	_tactical_button.tooltip_text = "Mode tactique (T) : cases à plat, obstacles en blocs, décor masqué, combattants en pions"
	_tactical_button.custom_minimum_size = Vector2(34, 34)
	var tactical_icon := TacticalIcon.new()
	tactical_icon.button = _tactical_button
	tactical_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tactical_button.add_child(tactical_icon)
	_tactical_button.draw.connect(tactical_icon.queue_redraw)  # Suit aussi set_pressed_no_signal.
	_tactical_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_tactical_button.focus_mode = Control.FOCUS_NONE
	_tactical_button.pressed.connect(toggle_tactical)
	top_row.add_child(_tactical_button)
	_sit_button = Button.new()
	_sit_button.toggle_mode = true
	_sit_button.text = "S'asseoir"
	_sit_button.tooltip_text = "S'asseoir (A) : les PV remontent %d fois plus vite. On se relève en marchant." % int(World.SIT_REGEN_FACTOR)
	_sit_button.custom_minimum_size = Vector2(96, 34)
	_sit_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_sit_button.focus_mode = Control.FOCUS_NONE
	_sit_button.pressed.connect(func() -> void:
		map_view.toggle_sit()
		_on_sitting_changed(map_view.world.sitting))  # Refusé pendant une animation : le bouton revient.
	top_row.add_child(_sit_button)

	row.add_child(VSeparator.new())
	var menus := GridContainer.new()
	menus.columns = 3
	menus.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	menus.add_theme_constant_override("h_separation", 6)
	menus.add_theme_constant_override("v_separation", 6)
	row.add_child(menus)
	for menu: Array in MENUS:
		var button := Button.new()
		button.icon = Art.texture(menu[1])
		button.expand_icon = true
		button.custom_minimum_size = Vector2(44, 42)
		button.tooltip_text = menu[2]
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func() -> void: menu_pressed.emit(menu[0]))
		menus.add_child(button)
		_menu_buttons[menu[0]] = button

	_build_bands()

	_result_panel = PanelContainer.new()
	_result_panel.set_anchors_preset(Control.PRESET_CENTER)
	_result_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_result_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_result_panel.add_theme_stylebox_override("panel", UiTheme.window_style())
	add_child(_result_panel)
	var result_box := VBoxContainer.new()
	result_box.add_theme_constant_override("separation", 8)
	_result_panel.add_child(result_box)
	_result_title = _label(28, Color(0.95, 0.76, 0.3))
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_info = _label(14, UiTheme.TEXT_DIM)
	_result_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_rows = VBoxContainer.new()
	_result_rows.add_theme_constant_override("separation", 3)
	_result_detail = _label(15, UiTheme.TEXT)
	_result_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_detail.custom_minimum_size = Vector2(500, 0)
	_overload_label = _label(15, Color(1.0, 0.55, 0.4))
	_overload_label.text = OVERLOAD_TEXT
	_overload_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overload_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_overload_label.custom_minimum_size = Vector2(500, 0)
	_overload_label.visible = false
	var close_button := Button.new()
	close_button.text = "Fermer"
	close_button.custom_minimum_size = Vector2(160, 38)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.pressed.connect(close_result)
	result_box.add_child(_result_title)
	result_box.add_child(_result_info)
	result_box.add_child(_result_rows)
	result_box.add_child(_result_detail)
	result_box.add_child(_overload_label)
	result_box.add_child(close_button)


func _build_target_box(row: HBoxContainer) -> void:
	_target_box = HBoxContainer.new()
	_target_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_target_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_target_box.add_theme_constant_override("separation", 24)
	_target_box.visible = false
	row.add_child(_target_box)
	var identity := VBoxContainer.new()
	identity.alignment = BoxContainer.ALIGNMENT_CENTER
	_target_box.add_child(identity)
	_target_name = _label(18, Color(1.0, 0.62, 0.5))
	identity.add_child(_target_name)
	_target_level = _label(14, Color(0.85, 0.82, 0.72))
	identity.add_child(_target_level)
	_target_stats = _label(15, Color.WHITE)
	_target_stats.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_target_box.add_child(_target_stats)
	var resistances := GridContainer.new()
	resistances.columns = 3
	resistances.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	resistances.add_theme_constant_override("h_separation", 14)
	resistances.tooltip_text = "Résistances : dégâts reçus en moins (en négatif : en plus)"
	_target_box.add_child(resistances)
	for element: String in Spell.ELEMENTS:
		var label := _label(13, SpellsWindow.ELEMENT_COLORS.get(element, Color.WHITE))
		resistances.add_child(label)
		_target_resistances[element] = label


## Bandes latérales, hors de la zone de jeu (`ScreenLayout`) : à gauche la minicarte et le suivi des
## quêtes (posés par leurs calques sur `minimap_slot` et `quest_slot`), à droite l'ordre de jeu en
## combat, le résumé du personnage hors combat. Opaques : elles cachent aussi le décor qui déborde
## de la carte sur les côtés.
func _build_bands() -> void:
	_left_band = _band()
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_left_band.add_child(left)
	map_title = _label(15, UiTheme.GOLD)
	map_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(map_title)
	minimap_slot = Control.new()
	minimap_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(minimap_slot)
	quest_slot = Control.new()
	quest_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	quest_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(quest_slot)

	_right_band = _band()
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	_right_band.add_child(right)
	# Messages (« À vous de jouer », repère posé…) en haut de la bande droite, hors de la zone de jeu.
	# Place réservée : le message s'efface sans faire bouger le reste de la bande.
	_message_label = _label(15, Color(1, 0.95, 0.75))
	_message_label.custom_minimum_size = Vector2(0, MESSAGE_HEIGHT)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_message_label.max_lines_visible = 4
	_message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_message_label.modulate.a = 0.0
	right.add_child(_message_label)
	_timer_label = _label(14, Color(1.0, 0.8, 0.35))
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.visible = false
	right.add_child(_timer_label)
	right.add_child(HSeparator.new())
	_summary = VBoxContainer.new()
	_summary.add_theme_constant_override("separation", 4)
	right.add_child(_summary)
	_summary_name = _label(15, UiTheme.GOLD)
	_summary_name.clip_text = true
	_summary_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_summary.add_child(_summary_name)
	_summary_level = _label(12, UiTheme.TEXT)
	_summary_level.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary.add_child(_summary_level)
	_summary_xp = ProgressBar.new()
	_summary_xp.custom_minimum_size = Vector2(0, 10)
	_summary_xp.show_percentage = false
	_summary.add_child(_summary_xp)
	_summary_money = _label(12, UiTheme.TEXT)
	_summary.add_child(_summary_money)
	_party_box = VBoxContainer.new()
	_party_box.add_theme_constant_override("separation", 4)
	_summary.add_child(_party_box)
	_party_box.add_child(HSeparator.new())
	var party_title := _label(14, UiTheme.GOLD)
	party_title.text = "Groupe"
	_party_box.add_child(party_title)
	_party_lines = _label(12, UiTheme.TEXT)
	_party_lines.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_party_box.add_child(_party_lines)
	var leave := Button.new()
	leave.text = "Quitter le groupe"
	leave.pressed.connect(func() -> void: map_view.send_command({"type": Protocol.CMD_PARTY_LEAVE, "entite": map_view.world.player_id}))
	_party_box.add_child(leave)
	_party_box.visible = false
	_order_label = _label(15, UiTheme.GOLD)
	_order_label.text = "Placement"
	_order_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(_order_label)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(scroll)
	_order_box = VBoxContainer.new()
	_order_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_order_box.add_theme_constant_override("separation", 4)
	scroll.add_child(_order_box)
	get_viewport().size_changed.connect(_place_bands)
	_place_bands()


func _band() -> PanelContainer:
	var band := PanelContainer.new()
	var style := _panel_style(Color(0.13, 0.1, 0.07, 1.0))
	style.set_content_margin_all(6)
	band.add_theme_stylebox_override("panel", style)
	band.anchor_top = 0.0
	band.anchor_bottom = 1.0
	band.offset_top = ScreenLayout.TOP
	band.offset_bottom = -BAR_HEIGHT
	add_child(band)
	return band


## Largeur des bandes d'après l'écran ; la minicarte est carrée, en haut de la bande gauche.
func _place_bands() -> void:
	var width := ScreenLayout.band_width(get_viewport().get_visible_rect().size)
	_left_band.anchor_left = 0.0
	_left_band.anchor_right = 0.0
	_left_band.offset_left = 0.0
	_left_band.offset_right = width
	_right_band.anchor_left = 1.0
	_right_band.anchor_right = 1.0
	_right_band.offset_left = -width
	_right_band.offset_right = 0.0
	minimap_slot.custom_minimum_size = Vector2(0, minf(width - 12.0, 220.0))


## Bandes gauche et droite (pour les tests et les calques qui s'y posent).
func bands() -> Array[Control]:
	return [_left_band, _right_band]


## Hors combat, dans la bande droite : nom, niveau et Voie, expérience, brumes.
## Membres du groupe de joueurs (le chef d'une étoile) ; caché sans groupe.
func _refresh_party() -> void:
	if map_view == null or map_view.world == null:
		return
	var members: Array = map_view.world.party.get("membres", [])
	_party_box.visible = not members.is_empty()
	var lines: PackedStringArray = []
	for member: Dictionary in members:
		lines.append("%s%s, niv. %d%s" % ["★ " if member["id"] == map_view.world.party["chef"] else "", member["nom"],
			member["niveau"], " (déconnecté)" if member.get("absent", false) else ""])
	_party_lines.text = "\n".join(lines)


func _show_summary(sheet: Dictionary) -> void:
	_summary_name.text = sheet["nom"]
	_summary_level.text = "Niveau %d, %s %s" % [sheet["niveau"], sheet["race_nom"], sheet["voie_nom"]]
	var span := maxi(1, int(sheet["xp_suivant"]) - int(sheet["xp_niveau"]))
	_summary_xp.max_value = span
	_summary_xp.value = clampi(int(sheet["xp"]) - int(sheet["xp_niveau"]), 0, span)
	_summary_xp.tooltip_text = "Expérience : %d / %d" % [sheet["xp"], sheet["xp_suivant"]]
	_summary_money.text = "%d brumes" % sheet["ecus"]


func _gauge(kind: String, minimum: Vector2, tooltip: String) -> Gauge:
	var gauge := Gauge.new()
	gauge.kind = kind
	gauge.custom_minimum_size = minimum
	gauge.tooltip_text = tooltip
	gauge.mouse_filter = Control.MOUSE_FILTER_PASS
	return gauge


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	return label


func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.55, 0.42, 0.22)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	return style
