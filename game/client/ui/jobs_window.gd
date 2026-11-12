class_name JobsWindow
extends CanvasLayer
## Fenêtre des métiers (touche J) : un onglet par métier, avec sa réputation et son palier, ses
## compétences où placer les points de maîtrise, et la liste de ses ressources (récolte) ou ce qu'il
## sait lire des ressources à forger (artisanat). Instance de métier (GDD § 10.3, `Plots`) : double-clic sur une ressource
## pour la débloquer, bouton « Instance » pour la disposition (emplacements vus de haut, clic : poser la ressource choisie).

const GOLD := Color(0.95, 0.76, 0.3)

var map_view: MapView

var _panel: PanelContainer
var _tabs: TabBar
var _title: Label
var _description: Label
var _level: Label
var _xp_bar: ProgressBar
var _xp_label: Label
var _skills: VBoxContainer
var _list_title: Label
var _list: ItemList
var _job_ids: Array[String] = []
var _list_markers: Array = []
var _instance_button: Button
var _plot_box: VBoxContainer
var _plot_info: Label
var _plot_choice: OptionButton
var _plot_view: Control


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
	var reputation_value := character.job_reputation(job_id)
	var tier := Character.tier_index(reputation_value)
	var floor_value := int(Character.REPUTATION_TIERS[tier][0])
	var last := tier == Character.REPUTATION_TIERS.size() - 1
	var next_value := reputation_value if last else int(Character.REPUTATION_TIERS[tier + 1][0])
	var harvest: bool = job["type"] == Profession.TYPE_HARVEST
	_title.text = job["nom"]
	_description.text = "%s (%s)" % [job.get("description", ""), "récolte" if harvest else "artisanat"]
	_level.text = "%s  ·  %d point%s de maîtrise à placer" % [Character.tier_name(tier), character.job_points(job_id),
		"s" if character.job_points(job_id) > 1 else ""]
	_xp_bar.value = 100.0 if last else 100.0 * (reputation_value - floor_value) / (next_value - floor_value)
	_xp_label.text = "Réputation : %d%s" % [reputation_value, "" if last else " / %d (%s)" % [next_value, Character.tier_name(tier + 1)]]
	for row in _skills.get_children():
		row.queue_free()
	for skill_id: String in Profession.skills(job["type"]):
		_add_skill(job_id, job["type"], skill_id, character)
	_list.clear()
	_list_markers.clear()
	var opened := harvest and not Plots.level(reputation_value).is_empty()
	_instance_button.visible = harvest
	_instance_button.disabled = not opened
	_instance_button.tooltip_text = "" if opened else "Instance de métier : à %d de réputation, au Cadastre de Hautepierre." % Plots.OPEN_REPUTATION
	_plot_box.visible = opened and _instance_button.button_pressed
	_list.visible = not _plot_box.visible
	_skills.visible = not _plot_box.visible
	_list_title.visible = not _plot_box.visible
	if _plot_box.visible:
		_refresh_plots(job_id, character)
	if harvest:
		_list_title.text = "Ressources (récolter en cliquant dessus sur la carte%s)" % (" ; double-clic : débloquer pour l'instance" if opened else "")
		var unlocked: Array = character.plot_state(job_id)["debloquees"]
		for node: Dictionary in job["ressources"]:
			var item: Dictionary = world.data.items.get(node["objet"], {})
			var amount: Array = node.get("quantite", [1, 1])
			var regrowth: Array = node["repousse"]
			_list_markers.append(node["marqueur"])
			_add_line("Palier %d — %s : %s ×%d à %d, repousse en %d à %d s%s" % [node.get("niveau", 1), node["nom"],
				item.get("nom", node["objet"]), amount[0], amount[1], regrowth[0], regrowth[1], "" if not opened else " · instance : %s" % (
				"débloquée" if node["marqueur"] in unlocked else "%d pt" % Plots.unlock_cost(int(node.get("niveau", 1))))],
				str(item.get("rarete", "commun")), node["objet"])
	else:
		_list_title.text = "Forge (à l'enclume de votre maison)"
		_add_line("Caractéristiques des ressources lues : %s" % ("jusqu'au palier %d" % Progression.equivalent_level(reputation_value)
			if Forge.reveals(character, 1) else "aucune (forgez une première fois)"), "commun", "forge_epee")


## Ligne d'une compétence : rang, effet, et bouton pour y placer des points (rang n : n points).
func _add_skill(job_id: String, type: String, skill_id: String, character: Character) -> void:
	var skill: Array = Profession.SKILLS[type][skill_id]
	var rank := character.job_rank(job_id, skill_id)
	var row := HBoxContainer.new()
	var label := _label(14, Color(0.9, 0.86, 0.75))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = "%s, rang %d / %d : %s" % [skill[0], rank, Character.SPELL_MAX_RANK,
		skill[1] % String.num(Profession.skill_value(type, skill_id, rank))]
	row.add_child(label)
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	var maxed := rank >= Character.SPELL_MAX_RANK
	button.text = "Rang maximal" if maxed else "Rang %d (%d pt%s)" % [rank + 1, rank + 1, "s" if rank > 0 else ""]
	var missing := rank + 1 - character.job_points(job_id)
	UiTheme.lock(button, "" if maxed or missing <= 0 else "Il vous manque %d point%s de métier." % [missing, "s" if missing > 1 else ""])
	button.disabled = button.disabled or maxed
	button.pressed.connect(func() -> void: map_view.send_command({"type": Protocol.CMD_RAISE_SPELL,
		"entite": map_view.world.player_id, "metier": job_id, "competence": skill_id}))
	row.add_child(button)
	_skills.add_child(row)


func _add_line(text: String, rarity: String, item_id: String) -> void:
	var index := _list.add_item(text, InventoryWindow.item_icon(item_id))
	_list.set_item_custom_fg_color(index, InventoryWindow.rarity_color(rarity))


## Disposition de l'instance : ressource à poser (ou « Retirer »), emplacements de la carte vus de haut.
func _refresh_plots(job_id: String, character: Character) -> void:
	var world := map_view.world
	var state := character.plot_state(job_id)
	var chosen: Variant = _plot_choice.get_item_metadata(_plot_choice.selected) if _plot_choice.selected >= 0 else null
	_plot_choice.clear()
	_plot_choice.add_item("Retirer")
	_plot_choice.set_item_metadata(0, "")
	for marker: String in state["debloquees"]:
		_plot_choice.add_item(world.data.nodes[marker]["nom"])
		_plot_choice.set_item_metadata(_plot_choice.item_count - 1, marker)
		if marker == chosen or chosen == null:
			_plot_choice.select(_plot_choice.item_count - 1)
	_plot_info.text = "Emplacements : %d / %d. Choisissez une ressource débloquée, puis cliquez un emplacement." % [
		state["parcelles"].size(), Plots.level(character.job_reputation(job_id))[1]]
	for child in _plot_view.get_children():
		child.queue_free()
	var plot_map := world.map_by_id(Plots.MAPS[job_id])
	var cells: Array = plot_map.plot_cells.keys() if plot_map != null else []
	var top_left := Vector2(INF, INF)
	for cell: Vector2i in cells:
		top_left = top_left.min(IsoGrid.cell_to_screen(cell))
	for cell: Vector2i in cells:
		var plot: Array = state["parcelles"].get(Plots.key(cell), [])
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.size = Vector2(30, 18)
		button.position = (IsoGrid.cell_to_screen(cell) - top_left) * 0.45 + Vector2(40, 4)
		button.add_theme_font_size_override("font_size", 10)
		var node: Dictionary = world.data.nodes.get(plot[0], {}) if not plot.is_empty() else {}
		var left := ceili((float(plot[1]) - Time.get_unix_time_from_system()) / 60.0) if not plot.is_empty() else 0
		button.text = str(node.get("nom", "")).left(3)
		button.tooltip_text = "Emplacement libre" if node.is_empty() else "%s : %s" % [node["nom"], "mûre" if left <= 0 else "mûre dans %d min" % left]
		button.pressed.connect(func() -> void: map_view.send_command({"type": Protocol.CMD_PLOT, "entite": world.player_id, "metier": job_id,
			"case": cell, "marqueur": _plot_choice.get_item_metadata(_plot_choice.selected)}))
		_plot_view.add_child(button)


## Un onglet par métier des données, dans leur ordre.
func _update_tabs(world: ClientState) -> void:
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
	var frame := UiTheme.window_frame(self, "Métiers", toggle, false)
	_panel = frame.panel
	var column: VBoxContainer = frame.column
	_instance_button = UiTheme.header_add(frame, Button.new())
	_instance_button.text = "Instance"
	_instance_button.toggle_mode = true
	_instance_button.focus_mode = Control.FOCUS_NONE
	_instance_button.toggled.connect(func(_on: bool) -> void: refresh())
	_tabs = UiTheme.tabs([], _on_tab_changed)
	column.add_child(_tabs)

	_title = _label(20, Color(0.95, 0.92, 0.85))
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
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
	_skills = VBoxContainer.new()
	column.add_child(_skills)
	_list_title = _label(15, Color(0.85, 0.82, 0.72))
	column.add_child(_list_title)
	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.fixed_icon_size = Vector2i(28, 28)
	_list.item_activated.connect(func(index: int) -> void: map_view.send_command({"type": Protocol.CMD_UNLOCK_PLOT,
		"entite": map_view.world.player_id, "metier": current_job(), "marqueur": _list_markers[index]}) if index < _list_markers.size() else null)
	column.add_child(_list)
	_plot_box = VBoxContainer.new()
	_plot_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_plot_box)
	var plot_header := HBoxContainer.new()
	_plot_box.add_child(plot_header)
	_plot_info = _label(13, Color(0.85, 0.82, 0.72))
	_plot_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_plot_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	plot_header.add_child(_plot_info)
	_plot_choice = OptionButton.new()
	_plot_choice.focus_mode = Control.FOCUS_NONE
	plot_header.add_child(_plot_choice)
	_plot_view = Control.new()
	_plot_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_plot_view.clip_contents = true
	_plot_box.add_child(_plot_view)
	var hint := _label(12, Color(0.6, 0.58, 0.52))
	hint.text = "Touche J : ouvrir / fermer"
	column.add_child(hint)


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
