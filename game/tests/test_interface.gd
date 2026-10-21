extends "res://tests/test_case.gd"
## Options (enregistrées hors sauvegarde), menu pause, menu principal, mode tactique en combat.

const TEST_OPTIONS := "user://options_tests.cfg"


func before_each() -> void:
	Options.path = TEST_OPTIONS
	Options.reset()
	DirAccess.remove_absolute(TEST_OPTIONS)
	Session.minimap_folded = false


func _run_until_idle(view: MapView) -> void:
	for i in 1000:
		if not view.is_busy() or view._paused:
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
	Options.save_options()
	Options.reset()
	assert_false(Options.tactical)
	Options.load_options(true)
	assert_eq(Options.volume, 35)
	assert_true(Options.fullscreen)
	assert_eq(Options.window_size, 2)
	assert_true(Options.tactical, "le mode tactique est retenu")
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
	Options.reset()
	Options.load_options(true)
	assert_eq(Options.volume, 50, "et il est enregistré")
	assert_true(Options.tactical)
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
