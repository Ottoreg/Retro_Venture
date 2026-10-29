extends "res://tests/test_case.gd"
## Écran de création du personnage et arrivée du personnage créé dans le monde.


func test_ecran_de_creation() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var scene = load("res://client/creation/creation.tscn").instantiate()
	tree.root.add_child(scene)
	assert_eq(scene.race_id, "humain", "première race sélectionnée")
	assert_eq(scene._race_buttons.size(), 3, "Humain, Gobelin, Elfe")
	assert_eq(scene._voie_buttons.size(), 4, "Guerrier, Rôdeur, Arcaniste, Théologue")
	scene._name_edit.text = "A"
	assert_true(scene.validation_error() != "", "nom trop court refusé")
	scene._name_edit.text = "Elara"
	scene._select_race("elfe")
	scene._select_voie("arcaniste")
	assert_eq(scene.validation_error(), "")
	var hero: Character = scene.build_character()
	assert_eq(hero.display_name, "Elara")
	assert_eq(hero.race_id, "elfe")
	assert_eq(hero.voie_id, "arcaniste")
	assert_true(scene._summary.text.contains("Pas léger"), "sort racial dans le récapitulatif")
	assert_true(scene._race_text.text.contains("Neutre"), "camp affiché")
	scene.free()


func test_le_personnage_cree_arrive_dans_le_monde() -> void:
	Session.new_character = Character.create("Grik", "gobelin", "rodeur")
	Session.continue_game = false
	var tree := Engine.get_main_loop() as SceneTree
	var scene: Node = load("res://client/world/world.tscn").instantiate()
	tree.root.add_child(scene)
	var view: MapView = scene.get_node("MapView")
	assert_eq(view.server.character.display_name, "Grik")
	assert_eq(view.server.character.race_id, "gobelin")
	assert_eq(view.server.player_voie, "rodeur")
	assert_true(SaveGame.exists(), "partie sauvegardée dès l'arrivée")
	assert_eq(SaveGame.read()["personnage"]["nom"], "Grik")

	var sheet: CharacterSheet = scene.get_node("CharacterSheet")
	sheet.toggle()
	assert_true(sheet.is_open(), "fiche ouverte")
	assert_eq(sheet._title.text, "Grik")
	# Plus d'équipement de départ : un arc porté pour la provenance.
	var bow := view.server.character.inventory.add(view.server.data.items["arc_de_frene"], 1, {"agilite": 3})
	view.server.character.inventory.equip(bow, "arme")
	view.refresh_state()
	var agility_before := view.server.character.stat("agilite", view.server.data)
	assert_eq(agility_before, 3, "pas de bonus de race, seulement l'arc")
	view.server.character.gain_stat("agilite", 1)
	view.server.character.add_reputation(1200)
	view.refresh_state()
	sheet.refresh()
	assert_eq(sheet._stat_values["agilite"].text, str(agility_before + 1), "un point gagné de plus")
	var tooltip: String = sheet._stat_values["agilite"].tooltip_text
	assert_true(tooltip.contains("Gagnés par la pratique : 1"), tooltip)
	assert_true(tooltip.contains("Arc de frêne"), "l'arc dans la provenance : " + tooltip)
	assert_eq(sheet._stat_caps["agilite"].text, "1 / %d" % Character.STAT_CAP)
	assert_eq(sheet._points_label.text, "Points de maîtrise : 2")
	assert_true(sheet._subtitle.text.begins_with("Apprenti"), sheet._subtitle.text)
	assert_eq(sheet._class_choice.get_item_text(sheet._class_choice.selected).get_slice(" (", 0), "Rôdeur", "classe active choisie")
	# Une commande qui change la fiche (un rang de maîtrise) déclenche la sauvegarde.
	view.send_command({"type": Protocol.CMD_RAISE_SPELL, "entite": World.PLAYER_ID, "sort": "rodeur_fleche"})
	assert_eq(view.server.character.spell_rank("rodeur_fleche"), 1)
	scene.free()

	# Reprise de la partie sauvegardée.
	Session.new_character = null
	Session.continue_game = true
	var resumed: Node = load("res://client/world/world.tscn").instantiate()
	tree.root.add_child(resumed)
	var resumed_view: MapView = resumed.get_node("MapView")
	assert_eq(resumed_view.server.character.display_name, "Grik", "partie reprise")
	assert_eq(resumed_view.server.character.stat("agilite", resumed_view.server.data), agility_before + 1)
	assert_eq(resumed_view.server.character.inventory.equipped_entry("arme")["objet"], "arc_de_frene", "équipement repris")
	resumed.free()
	Session.continue_game = false


func test_fenetre_d_inventaire() -> void:
	Session.new_character = Character.create("Brindille", "humain", "guerrier")
	Session.continue_game = false
	var tree := Engine.get_main_loop() as SceneTree
	var scene: Node = load("res://client/world/world.tscn").instantiate()
	tree.root.add_child(scene)
	var view: MapView = scene.get_node("MapView")
	var window: InventoryWindow = scene.get_node("InventoryWindow")
	var inventory := view.server.character.inventory
	assert_true(inventory.entries.is_empty(), "plus d'équipement de départ")
	assert_eq(inventory.ecus, GameData.STARTING_ECUS)
	var epee: Dictionary = view.server.data.items["epee_de_fer"]
	inventory.equip(inventory.add(epee, 1, Item.roll_bonuses(epee, RandomNumberGenerator.new())), "arme")
	view.refresh_state()
	window.toggle()
	assert_true(window.is_open())
	assert_eq(_bag_count(window), inventory.entries.size(), "chaque objet dans un onglet du sac")
	assert_eq(window._slot_buttons["arme"].text, "Épée de fer")
	assert_eq(window._slot_buttons["arme"].icon, InventoryWindow.item_icon("epee_de_fer"), "icône de l'arme portée")
	assert_eq(window._relic_slots.size(), 8, "huit cases de Reliques")
	for relic in window._relic_slots:
		assert_true(relic.is_visible_in_tree(), "visibles dès le début")
	for i in window._list.item_count:
		assert_true(window._list.get_item_icon(i) != Art.texture("objet_inconnu"), "icône dans le sac")

	# Retirer puis remettre l'épée, depuis la fenêtre.
	var sword: String = inventory.equipped["arme"]
	window._selected = sword
	window._on_unequip_pressed()
	assert_false(inventory.equipped.has("arme"), "épée retirée")
	assert_eq(window._slot_buttons["arme"].text, "—")
	window._on_equip_pressed()
	assert_eq(inventory.equipped.get("arme"), sword, "épée remise")

	# Double-clic : retirer puis équiper ; glisser : du sac vers l'emplacement, et retour au sac.
	window.toggle_worn(sword)
	assert_false(inventory.equipped.has("arme"), "double-clic sur l'épée portée : retirée")
	window.toggle_worn(sword)
	assert_eq(inventory.equipped.get("arme"), sword, "double-clic sur l'épée du sac : équipée")
	window._drop_on_bag(Vector2.ZERO, {"objet": sword, "emplacement": "arme"})
	assert_false(inventory.equipped.has("arme"), "épée glissée vers le sac : retirée")
	var dragged := {"objet": sword, "emplacement": ""}
	assert_false(window.can_drop_on_slot(dragged, "coiffe"), "une épée ne va pas sur la tête")
	assert_true(window.can_drop_on_slot(dragged, "arme"))
	window.drop_on_slot(dragged, "arme")
	assert_eq(inventory.equipped.get("arme"), sword, "épée glissée sur l'emplacement d'arme : équipée")

	# Détail de l'épée : ses jets, et les jets possibles tant qu'on tient Ctrl.
	window._selected = sword
	window.refresh()
	var rolled: int = inventory.entries[sword]["jets"]["force"]
	assert_true(window._details.text.contains("+%d Force" % rolled), window._details.text)
	assert_false(window._details.text.contains("Jets possibles"))
	var ctrl := InputEventKey.new()
	ctrl.keycode = KEY_CTRL
	ctrl.pressed = true
	window._input(ctrl)
	var span: Array = view.server.data.items["epee_de_fer"]["bonus"]["force"]
	assert_true(window._details.text.contains("Jets possibles"), window._details.text)
	assert_true(window._details.text.contains("+%d à %d Force" % [span[0], span[1]]), window._details.text)
	ctrl.pressed = false
	window._input(ctrl)
	assert_false(window._details.text.contains("Jets possibles"), "Ctrl relâché : retour aux jets de l'objet")

	# Objet de panoplie : la panoplie, les pièces portées et les paliers dans le détail.
	var template: Dictionary = view.server.data.items["amulette_pyromane_repenti"]
	var amulet := inventory.add(template, 1, Item.roll_bonuses(template, RandomNumberGenerator.new()))
	view.refresh_state()
	window._selected = amulet
	window.refresh()
	assert_true(window._details.text.contains("Panoplie du Pyromane Repenti — 0 / 6"), window._details.text)
	window._on_equip_pressed()  # Plus de niveau requis.
	assert_true(window._details.text.contains("Panoplie du Pyromane Repenti — 1 / 6"), window._details.text)

	# Un objet ramassé apparaît dans la liste.
	inventory.add(view.server.data.items["croc_de_loup"], 3)
	view.refresh_state()
	window.refresh()
	assert_eq(_bag_count(window), inventory.entries.size(), "chaque objet dans un onglet du sac")
	window._selected = "croc_de_loup"
	window._on_drop_pressed()
	assert_eq(inventory.quantity_of("croc_de_loup"), 0, "jeté")
	scene.free()


## Nombre d'objets du sac, tous onglets confondus (revient ensuite à l'onglet Équipements).
func _bag_count(window: InventoryWindow) -> int:
	var count := 0
	for tab in InventoryWindow.BAG_TAB_NAMES.size():
		window.show_bag_tab(tab)
		count += window._list.item_count
	window.show_bag_tab(InventoryWindow.BagTab.EQUIPMENT)
	return count
