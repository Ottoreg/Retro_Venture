extends "res://tests/test_case.gd"
## Options (enregistrées hors sauvegarde), menu pause, menu principal, mode tactique en combat,
## style des infobulles.

const TEST_OPTIONS := "user://options_tests.cfg"


func before_each() -> void:
	Options.path = TEST_OPTIONS
	Options.reset()
	DirAccess.remove_absolute(TEST_OPTIONS)


func _run_until_idle(view: MapView) -> void:
	for i in 1000:
		if not view.is_busy():
			return
		view.advance(0.5)


func _cancel() -> InputEventAction:
	var cancel := InputEventAction.new()
	cancel.action = "ui_cancel"
	cancel.pressed = true
	return cancel


func test_options_enregistrees() -> void:
	Options.volume = 35
	Options.fullscreen = true
	Options.window_size = 2
	Options.tactical = true
	Options.tactical_pawns = true
	Options.save_options()
	Options.reset()
	assert_false(Options.tactical)
	assert_false(Options.tactical_pawns, "personnages visibles par défaut en mode tactique")
	Options.load_options(true)
	assert_eq(Options.volume, 35)
	assert_true(Options.fullscreen)
	assert_eq(Options.window_size, 2)
	assert_true(Options.tactical, "le mode tactique est retenu")
	assert_true(Options.tactical_pawns, "les pions aussi")
	# Valeurs hors bornes dans le fichier : ramenées dans les bornes.
	var file := ConfigFile.new()
	file.set_value("son", "volume", 250)
	file.set_value("affichage", "taille", 9)
	file.save(TEST_OPTIONS)
	Options.load_options(true)
	assert_eq(Options.volume, 100)
	assert_eq(Options.window_size, Options.WINDOW_SIZES.size() - 1)
	Options.reset()


func test_fenetre_des_options() -> void:
	var window := OptionsWindow.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(window)
	window.open()
	var controls := window.controls()
	(controls["volume"] as HSlider).value = 50
	assert_eq(Options.volume, 50, "le volume change aussitôt")
	(controls["tactique"] as Button).button_pressed = true
	assert_true(Options.tactical)
	assert_eq((controls["tactique"] as Button).text, "Activé")
	assert_false((controls["pions"] as Button).button_pressed)
	(controls["pions"] as Button).button_pressed = true
	assert_true(Options.tactical_pawns)
	Options.reset()
	Options.load_options(true)
	assert_eq(Options.volume, 50, "et il est enregistré")
	assert_true(Options.tactical)
	assert_true(Options.tactical_pawns)
	window.close()
	assert_false(window.is_open())
	window.free()
	Options.reset()


func test_menu_pause() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var scene: Node = load("res://client/world/world.tscn").instantiate()
	tree.root.add_child(scene)
	var pause: PauseMenu = scene.pause_menu
	# Échap sans fenêtre ouverte : le menu pause, le jeu s'arrête.
	scene._unhandled_input(_cancel())
	assert_true(pause.is_open(), "menu pause ouvert")
	assert_true(tree.paused, "jeu en pause")
	var buttons := pause.buttons()
	for text in ["Reprendre", "Options", "Donner son avis", "Menu principal"]:
		assert_true(buttons.has(text), "bouton %s" % text)
	assert_false((buttons["Menu principal"] as Button).disabled)
	(buttons["Options"] as Button).pressed.emit()
	assert_true(pause.options.is_open(), "options depuis la pause")
	pause.options.close()
	(buttons["Reprendre"] as Button).pressed.emit()
	assert_false(pause.is_open())
	assert_false(tree.paused, "le jeu reprend")
	# En combat : pas de retour au menu (on ne sauvegarde pas en combat).
	var view: MapView = scene.get_node("MapView")
	view._on_click(view.world.groups()[0]["case"])
	_run_until_idle(view)
	assert_eq(view.mode, MapView.Mode.COMBAT)
	scene._unhandled_input(_cancel())
	assert_true(pause.is_open())
	assert_true((pause.buttons()["Menu principal"] as Button).disabled, "pas de menu principal en combat")
	pause.close()
	assert_false(tree.paused)
	scene.free()


func test_mode_tactique_retenu_d_un_combat_a_l_autre() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var scene: Node = load("res://client/world/world.tscn").instantiate()
	tree.root.add_child(scene)
	var view: MapView = scene.get_node("MapView")
	var hud: CombatHud = scene.get_node("CombatHud")
	assert_false(hud._tactical_button.visible, "pas de bouton tactique en exploration")
	view._on_click(view.world.groups()[0]["case"])
	_run_until_idle(view)
	assert_true(hud._tactical_button.visible, "bouton tactique en combat")
	assert_false(hud._tactical_button.button_pressed)
	var key := InputEventKey.new()
	key.keycode = KEY_T
	key.pressed = true
	hud._unhandled_key_input(key)
	assert_true(view.tactical, "touche T : mode tactique")
	assert_true(hud._tactical_button.button_pressed)
	Options.reset()
	Options.load_options(true)
	assert_true(Options.tactical, "enregistré dans les options")
	scene.free()
	# Nouvelle scène, nouveau combat : le mode tactique est toujours là.
	scene = load("res://client/world/world.tscn").instantiate()
	tree.root.add_child(scene)
	view = scene.get_node("MapView")
	hud = scene.get_node("CombatHud")
	view._on_click(view.world.groups()[0]["case"])
	_run_until_idle(view)
	assert_true(view.tactical)
	assert_true(hud._tactical_button.button_pressed, "le bouton suit")
	hud.toggle_tactical()
	assert_false(Options.tactical)
	scene.free()


func test_menu_principal() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var menu: Node = load("res://client/main/main.tscn").instantiate()
	tree.root.add_child(menu)
	var options_button: Button = menu.find_child("Options", true, false)
	assert_true(options_button != null, "bouton Options")
	options_button.pressed.emit()
	assert_true(menu.options_window.is_open(), "fenêtre des options")
	assert_true(menu.find_child("Quit", true, false) != null, "bouton Quitter hors navigateur")
	assert_true(menu.find_child("Feedback", true, false) != null, "bouton du questionnaire des testeurs")
	menu.free()


func test_historique_a_canaux() -> void:
	Session.message_log_folded = false
	Session.message_log_channel = MessageLog.CHANNEL_ALL
	var log := MessageLog.new()
	log.start_combat()
	log.add_line("Grondin perd 5 PV")
	log.add_entry(MessageLog.CHANNEL_TRADE, "Achat : Épée, −10 brumes")
	log.start_combat()  # Le combat suivant n'efface pas le précédent.
	assert_true(log.plain_text().contains("Grondin perd 5 PV") and log.plain_text().contains("Nouveau combat"))
	assert_true(log.plain_text().contains("Achat : Épée"), "« Tout » mêle les canaux")
	log.select_channel(MessageLog.CHANNEL_TRADE)
	assert_eq(log.plain_text(), "Achat : Épée, −10 brumes", "onglet Commerce : seulement le commerce")
	log.add_line("Grondin lance Morsure")
	assert_false(log.plain_text().contains("Morsure"), "une ligne de combat n'apparaît pas dans Commerce")
	log.select_channel(MessageLog.CHANNEL_COMBAT)
	assert_true(log.plain_text().contains("Morsure") and not log.plain_text().contains("Achat"))
	# Un message de chat : l'auteur devant le texte.
	log.select_channel(MessageLog.CHANNEL_ALL)
	log.add_entry(MessageLog.CHANNEL_TRADE, "Je vends des peaux", "Pippin")
	assert_true(log.plain_text().ends_with("Pippin : Je vends des peaux"), log.plain_text())
	# Chaque canal garde ses dernières lignes, sans chasser celles des autres.
	for i in MessageLog.MAX_LINES + 5:
		log.add_line("coup %d" % i)
	assert_eq(log.lines(MessageLog.CHANNEL_COMBAT).size(), MessageLog.MAX_LINES)
	assert_eq(log.lines(MessageLog.CHANNEL_TRADE).size(), 2, "le commerce reste")
	assert_eq(log.lines(MessageLog.CHANNEL_COMBAT)[-1], "coup %d" % (MessageLog.MAX_LINES + 4))
	log.free()


## Infobulles lisibles : fond presque opaque et liseré bronze (comme la grille de Composition), dans le
## thème de la fenêtre comme dans le thème par défaut (barres posées dans un CanvasLayer).
func test_infobulles_opaques() -> void:
	for theme: Theme in [UiTheme.build(), _default_theme_after_apply()]:
		var panel := theme.get_stylebox("panel", "TooltipPanel") as StyleBoxFlat
		assert_true(panel != null, "style des infobulles")
		if panel != null:
			assert_true(panel.bg_color.a >= 0.95, "fond presque opaque")
			assert_eq(panel.border_width_top, 2, "liseré de 2 px")
	assert_true(UiTheme.tooltip_style().bg_color.a >= 0.95, "bulles de survol")


func _default_theme_after_apply() -> Theme:
	UiTheme.apply(Engine.get_main_loop() as SceneTree)
	return ThemeDB.get_default_theme()


## Infobulle d'un objet du sac : comparée à l'objet porté au même emplacement (gains en vert,
## pertes en rouge), ou à un emplacement libre.
func test_infobulle_objet_comparee_a_l_equipement() -> void:
	var data := GameData.load_all()
	var inventory := Inventory.new()
	var worn := inventory.add(data.items["bottes_de_marche"], 1, {"agilite": 3, "initiative": 10})
	var bag := inventory.add(data.items["bottes_courant_d_air"], 1, {"agilite": 5, "initiative": 10})
	var sheet := _sheet_entry(data, inventory, bag)
	var free := ItemTooltipList.comparison_lines(sheet, data, inventory)
	assert_true(free.has("[color=#%s]Emplacement libre :[/color]" % ItemTooltipList.DIM.to_html(false)), "\n".join(free))
	assert_true(free.has("[color=#%s]+5 Agilité[/color]" % ItemTooltipList.GAIN.to_html(false)), "tout est gagné")
	inventory.equip(worn, "bottes")
	var lines := ItemTooltipList.comparison_lines(sheet, data, inventory)
	assert_true(lines.has("[color=#%s]+2 Agilité[/color]" % ItemTooltipList.GAIN.to_html(false)), "\n".join(lines))
	assert_false("\n".join(lines).contains("Initiative"), "pas de ligne pour une stat égale")
	var back := ItemTooltipList.comparison_lines(_sheet_entry(data, inventory, worn), data, inventory)
	assert_true("\n".join(back).contains("Porté"), "l'objet porté ne se compare pas à lui-même")
	inventory.equip(bag, "bottes")
	var loss := ItemTooltipList.comparison_lines(_sheet_entry(data, inventory, worn), data, inventory)
	assert_true(loss.has("[color=#%s]-2 Agilité[/color]" % ItemTooltipList.LOSS.to_html(false)), "\n".join(loss))
	# Article de marchand : la plage de ses bonus, moins l'objet porté.
	var article := {"objet": "bottes_de_marche", "nom": "Bottes de marche", "type": "bottes", "rarete": "commun", "niveau": 1,
		"conditions": {}, "bonus": data.items["bottes_de_marche"]["bonus"]}
	var text := ItemTooltipList.tooltip_text_for(article, data, inventory)
	assert_true(text.contains("-4 à -2 Agilité"), text)
	assert_true(text.contains("-5 à +5 Initiative"), text)
	# Arme : dégâts moyens comparés.
	var bow := inventory.add(data.items["arc_de_frene"], 1, {"agilite": 3})
	inventory.equip(inventory.add(data.items["baton_de_novice"], 1, {"intelligence": 3}), "arme")
	var weapon := "\n".join(ItemTooltipList.comparison_lines(_sheet_entry(data, inventory, bow), data, inventory))
	assert_true(weapon.contains("+1 dégâts moyens") or weapon.contains("+1,0 dégâts moyens"), weapon)


## La liste du sac de l'inventaire fait son infobulle en texte riche, au thème des infobulles.
func test_infobulle_objet_en_texte_riche() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var scene: Node = load("res://client/world/world.tscn").instantiate()
	tree.root.add_child(scene)
	var window: InventoryWindow = scene.get_node("InventoryWindow")
	window.toggle()
	assert_true(window._list.item_count > 0, "le sac de départ n'est pas vide")
	var tooltip := window._list.get_item_tooltip(0)
	assert_true(tooltip.begins_with("[color="), tooltip)
	var label: RichTextLabel = window._list._make_custom_tooltip(tooltip)
	assert_true(label.bbcode_enabled and label.fit_content, "texte riche à sa taille")
	label.free()
	scene.free()


## Le sac a trois onglets : chaque objet est rangé selon son type.
func test_onglets_du_sac() -> void:
	assert_eq(InventoryWindow.bag_tab("anneau"), InventoryWindow.BagTab.EQUIPMENT)
	assert_eq(InventoryWindow.bag_tab("arme"), InventoryWindow.BagTab.EQUIPMENT)
	assert_eq(InventoryWindow.bag_tab(Item.TYPE_RESOURCE), InventoryWindow.BagTab.RESOURCES)
	assert_eq(InventoryWindow.bag_tab(Item.TYPE_QUEST), InventoryWindow.BagTab.RESOURCES, "objets de quête avec les ressources")
	assert_eq(InventoryWindow.bag_tab("consommable"), InventoryWindow.BagTab.CONSUMABLES)
	var tree := Engine.get_main_loop() as SceneTree
	var scene: Node = load("res://client/world/world.tscn").instantiate()
	tree.root.add_child(scene)
	var view: MapView = scene.get_node("MapView")
	var data := view.world.data
	var inventory := view.world.character.inventory
	inventory.add(data.items["bois_de_frene"] if data.items.has("bois_de_frene") else _first_resource(data), 3, {})
	var window: InventoryWindow = scene.get_node("InventoryWindow")
	window.toggle()
	var sheet: Array = view.world.character.inventory_sheet(data)["objets"]
	for tab in InventoryWindow.BAG_TAB_NAMES.size():
		window.show_bag_tab(tab)
		var expected := sheet.filter(func(entry: Dictionary) -> bool: return InventoryWindow.bag_tab(entry["type"]) == tab)
		assert_eq(window._list.item_count, expected.size(), "onglet %s" % InventoryWindow.BAG_TAB_NAMES[tab])
	window.show_bag_tab(InventoryWindow.BagTab.RESOURCES)
	assert_true(window._list.item_count > 0, "la ressource ajoutée est dans l'onglet Ressources")
	# Cliquer un emplacement porté ramène aux équipements.
	var worn := ""
	for slot: String in window._slot_buttons:
		if not str(window._slot_buttons[slot].get_meta("uid", "")).is_empty():
			worn = slot
	if not worn.is_empty():
		window._on_slot_pressed(worn)
		assert_eq(window._bag_tabs.current_tab, InventoryWindow.BagTab.EQUIPMENT)
	scene.free()


func _first_resource(data: GameData) -> Dictionary:
	for id: String in data.items:
		if data.items[id]["type"] == Item.TYPE_RESOURCE:
			return data.items[id]
	return {}


func _sheet_entry(data: GameData, inventory: Inventory, uid: String) -> Dictionary:
	var character := Character.new()
	character.inventory = inventory
	for entry: Dictionary in character.inventory_sheet(data)["objets"]:
		if entry["uid"] == uid:
			return entry
	return {}
