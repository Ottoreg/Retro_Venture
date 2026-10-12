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
	view.world.character.add_xp(80)
	view.send_command({"type": Protocol.CMD_SPEND_POINTS, "entite": World.PLAYER_ID, "carac": "agilite", "points": 1})
	assert_eq(sheet._stat_values["agilite"].text, "11", "10 de race + 1 point investi")
	scene.free()

	# Reprise de la partie sauvegardée.
	Session.new_character = null
	Session.continue_game = true
	var resumed: Node = load("res://client/world/world.tscn").instantiate()
	tree.root.add_child(resumed)
	var resumed_view: MapView = resumed.get_node("MapView")
	assert_eq(resumed_view.world.character.display_name, "Grik", "partie reprise")
	assert_eq(resumed_view.world.character.stat("agilite", resumed_view.world.data), 11)
	resumed.free()
	Session.continue_game = false
