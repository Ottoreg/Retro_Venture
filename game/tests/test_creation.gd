extends "res://tests/test_case.gd"
## Écran de création du personnage et arrivée du personnage créé dans le monde.


func test_ecran_de_creation() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var scene = load("res://client/creation/creation.tscn").instantiate()
	tree.root.add_child(scene)
	assert_eq(scene.race_id, "humain", "première race sélectionnée")
	assert_eq(scene._race_buttons.size(), 3, "Humain, Gobelin, Elfe")
	assert_eq(scene._voie_buttons.size(), 3, "Guerrier, Rôdeur, Arcaniste")
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
	assert_eq(view.world.character.display_name, "Grik")
	assert_eq(view.world.character.race_id, "gobelin")
	assert_eq(view.world.player_voie, "rodeur")
	assert_true(SaveGame.exists(), "partie sauvegardée dès l'arrivée")
	assert_eq(SaveGame.read()["personnage"]["nom"], "Grik")

	var sheet: CharacterSheet = scene.get_node("CharacterSheet")
	sheet.toggle()
	assert_true(sheet.is_open(), "fiche ouverte")
	assert_eq(sheet._title.text, "Grik")
	var agility_before := view.world.character.stat("agilite", view.world.data)
	assert_true(agility_before > 10, "10 de race + le bonus de l'arc de départ")
	view.world.character.add_xp(80)
	view.send_command({"type": Protocol.CMD_SPEND_POINTS, "entite": World.PLAYER_ID, "carac": "agilite", "points": 1})
	assert_eq(sheet._stat_values["agilite"].text, str(agility_before + 1), "un point investi de plus")
	scene.free()

	# Reprise de la partie sauvegardée.
	Session.new_character = null
	Session.continue_game = true
	var resumed: Node = load("res://client/world/world.tscn").instantiate()
	tree.root.add_child(resumed)
	var resumed_view: MapView = resumed.get_node("MapView")
	assert_eq(resumed_view.world.character.display_name, "Grik", "partie reprise")
	assert_eq(resumed_view.world.character.stat("agilite", resumed_view.world.data), agility_before + 1)
	assert_eq(resumed_view.world.character.inventory.equipped_entry("arme")["objet"], "arc_de_frene", "équipement repris")
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
	var inventory := view.world.character.inventory
	assert_eq(inventory.equipped_entry("arme")["objet"], "epee_de_fer", "épée de départ portée")
	assert_eq(inventory.ecus, GameData.STARTING_ECUS)
	window.toggle()
	assert_true(window.is_open())
	assert_eq(window._list.item_count, inventory.entries.size())
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
	var span: Array = view.world.data.items["epee_de_fer"]["bonus"]["force"]
	assert_true(window._details.text.contains("Jets possibles"), window._details.text)
	assert_true(window._details.text.contains("+%d à %d Force" % [span[0], span[1]]), window._details.text)
	ctrl.pressed = false
	window._input(ctrl)
	assert_false(window._details.text.contains("Jets possibles"), "Ctrl relâché : retour aux jets de l'objet")

	# Un objet ramassé apparaît dans la liste.
	inventory.add(view.world.data.items["croc_de_loup"], 3)
	window.refresh()
	assert_eq(window._list.item_count, inventory.entries.size())
	window._selected = "croc_de_loup"
	window._on_drop_pressed()
	assert_eq(inventory.quantity_of("croc_de_loup"), 0, "jeté")
	scene.free()
