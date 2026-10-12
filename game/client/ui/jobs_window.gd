class_name JobsWindow
extends CanvasLayer
## Fenêtre des métiers (touche J) : un onglet par métier, avec son niveau, son expérience, et la
## liste de ses ressources (récolte) ou de ses recettes (artisanat).

const GOLD := Color(0.95, 0.76, 0.3)
const LOCKED := Color(0.5, 0.5, 0.5)

var map_view: MapView

var _panel: PanelContainer
var _tabs: TabBar
var _title: Label
var _description: Label
var _level: Label
var _xp_bar: ProgressBar
var _xp_label: Label
var _list_title: Label
var _list: ItemList
var _job_ids: Array[String] = []


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


## Métier de l'onglet choisi ("" s'il n'y en a pas).
func current_job() -> String:
	if _tabs.tab_count == 0:
		return ""
	return _job_ids[_tabs.current_tab]


func select_job(job_id: String) -> void:
	var index := _job_ids.find(job_id)
	if index >= 0:
		_tabs.current_tab = index
		refresh()


func refresh() -> void:
	if map_view == null or not _panel.visible:
		return
	var world := map_view.world
	_update_tabs(world)
	var job_id := current_job()
	if job_id.is_empty():
		_title.text = "Aucun métier"
		return
	var job: Dictionary = world.data.jobs[job_id]
	var character := world.character
	var level := character.job_level(job_id)
	var xp := character.job_xp(job_id)
	var floor_xp := Profession.xp_for_level(level)
	var next_xp := Profession.xp_for_level(level + 1) if level < Profession.MAX_LEVEL else xp
	var harvest: bool = job["type"] == Profession.TYPE_HARVEST
	_title.text = job["nom"]
	_description.text = "%s (%s)" % [job.get("description", ""), "récolte" if harvest else "artisanat"]
	_level.text = "Niveau %d / %d" % [level, Profession.MAX_LEVEL]
	_xp_bar.value = 100.0 * (xp - floor_xp) / maxi(1, next_xp - floor_xp)
	_xp_label.text = "Expérience : %d / %d" % [xp, next_xp]
	_list.clear()
	if harvest:
		_list_title.text = "Ressources (récolter en cliquant dessus sur la carte)"
		for node: Dictionary in job["ressources"]:
			var item: Dictionary = world.data.items.get(node["objet"], {})
			var amount: Array = node.get("quantite", [1, 1])
			var regrowth: Array = node["repousse"]
			_add_line("Niv. %d — %s : %s ×%d à %d, +%d XP, repousse en %d à %d s" % [node.get("niveau", 1), node["nom"],
				item.get("nom", node["objet"]), amount[0], amount[1], node.get("xp", 0), regrowth[0], regrowth[1]],
				level >= int(node.get("niveau", 1)), str(item.get("rarete", "commun")))
	else:
		_list_title.text = "Recettes (fabriquer à l'atelier)"
		var recipes: Array = job["recettes"].duplicate()
		recipes.sort_custom(_recipe_order)
		for recipe: Dictionary in recipes:
			var item: Dictionary = world.data.items.get(recipe["objet"], {})
			var parts: PackedStringArray = []
			for ingredient_id: String in recipe["ingredients"]:
				var ingredient: Dictionary = world.data.items.get(ingredient_id, {})
				parts.append("%d %s" % [recipe["ingredients"][ingredient_id], ingredient.get("nom", ingredient_id)])
			_add_line("Niv. %d — %s : %s, +%d XP" % [recipe.get("niveau", 1), item.get("nom", recipe["objet"]), ", ".join(parts), recipe.get("xp", 0)],
				level >= int(recipe.get("niveau", 1)), str(item.get("rarete", "commun")))


static func _recipe_order(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("niveau", 1)) < int(b.get("niveau", 1))


func _add_line(text: String, unlocked: bool, rarity: String) -> void:
	var index := _list.add_item(text if unlocked else "%s   (verrouillé)" % text)
	_list.set_item_custom_fg_color(index, InventoryWindow.rarity_color(rarity) if unlocked else LOCKED)
	_list.set_item_selectable(index, false)


## Un onglet par métier des données, dans leur ordre.
func _update_tabs(world: World) -> void:
	var ids: Array[String] = []
	for job_id: String in world.data.jobs:
		ids.append(job_id)
	if ids == _job_ids:
		return
	var previous := current_job()
	_job_ids = ids
	_tabs.clear_tabs()
	for job_id in _job_ids:
		_tabs.add_tab(world.data.jobs[job_id]["nom"])
	if _job_ids.has(previous):
		_tabs.current_tab = _job_ids.find(previous)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_J:
		toggle()
		get_viewport().set_input_as_handled()


func _on_tab_changed(_index: int) -> void:
	refresh()


# --- Construction des contrôles ----------------------------------------------------------------

func _build() -> void:
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.offset_left = -380
	_panel.offset_right = 380
	_panel.offset_top = 70
	_panel.offset_bottom = 540
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.1, 0.07, 0.96)
	style.border_color = Color(0.55, 0.42, 0.22)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(14)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var window_title := _label(22, GOLD)
	window_title.text = "Métiers"
	window_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(window_title)
	var close := Button.new()
	close.text = "×"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(toggle)
	header.add_child(close)

	_tabs = TabBar.new()
	_tabs.focus_mode = Control.FOCUS_NONE
	_tabs.tab_changed.connect(_on_tab_changed)
	column.add_child(_tabs)

	_title = _label(20, Color(0.95, 0.92, 0.85))
	column.add_child(_title)
	_description = _label(14, Color(0.8, 0.78, 0.7))
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_description)
	_level = _label(16, GOLD)
	column.add_child(_level)
	_xp_bar = ProgressBar.new()
	_xp_bar.show_percentage = false
	_xp_bar.custom_minimum_size = Vector2(0, 10)
	column.add_child(_xp_bar)
	_xp_label = _label(13, Color(0.75, 0.72, 0.65))
	column.add_child(_xp_label)
	_list_title = _label(15, Color(0.85, 0.82, 0.72))
	column.add_child(_list_title)
	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_list)
	var hint := _label(12, Color(0.6, 0.58, 0.52))
	hint.text = "Touche J : ouvrir / fermer"
	column.add_child(hint)


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
