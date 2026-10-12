extends "res://tests/test_case.gd"
## Test de bout en bout de la scène du monde : exploration → combat → retour, sans affichage.
## Les animations sont accélérées en appelant `_process` à la main.


func _run_until_idle(view: MapView) -> void:
	for i in 1000:
		if not view.is_busy() or view._paused:
			return
		view._process(0.5)


func test_scene_du_monde_jusqu_au_combat_et_retour() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var scene: Node = load("res://client/world/world.tscn").instantiate()
	tree.root.add_child(scene)
	var view: MapView = scene.get_node("MapView")
	var hud: CombatHud = scene.get_node("CombatHud")
	assert_true(view.world != null, "monde créé")
	assert_eq(view.world.groups().size(), 3, "groupes de monstres de Brumerive")

	# Clic sur un groupe : le joueur marche jusqu'à lui et le combat commence.
	var group: Dictionary = view.world.groups()[0]
	view._on_click(group["case"])
	_run_until_idle(view)
	assert_eq(view.mode, MapView.Mode.COMBAT, "mode combat")
	assert_true(view.is_placement(), "phase de placement")
	assert_eq(hud._spell_buttons.size(), 5, "un bouton par sort du Guerrier, plus le sort racial")

	view.request_start_fight()
	_run_until_idle(view)
	assert_true(view.is_player_turn(), "la main revient au joueur")
	var fighter := view.player_fighter()
	view.select_spell(fighter.spells[0].id)
	assert_eq(view.selected_spell, fighter.spells[0].id, "sort sélectionné")
	view.select_spell(fighter.spells[0].id)
	assert_eq(view.selected_spell, "", "second clic : sort désélectionné")

	# Le joueur passe ses tours jusqu'à la fin du combat.
	for i in 100:
		if view._paused:
			break
		view.request_end_turn()
		_run_until_idle(view)
	assert_true(view._paused, "écran de fin de combat")
	assert_true(hud._result_panel.visible, "panneau de résultat affiché")
	hud._on_continue_pressed()
	_run_until_idle(view)
	assert_eq(view.mode, MapView.Mode.EXPLORATION, "retour en exploration")
	assert_false(view.world.in_combat())
	scene.free()


func test_pnj_et_changement_de_carte() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var scene: Node = load("res://client/world/world.tscn").instantiate()
	tree.root.add_child(scene)
	var view: MapView = scene.get_node("MapView")
	var map := view.current_map()

	# Parler au PNJ : le joueur s'approche, la bulle s'affiche, chaque clic passe à la suite.
	assert_true(map.npcs.size() > 0, "un PNJ au village")
	var npc: Dictionary = map.npcs[0]
	view._on_click(npc["case"])
	_run_until_idle(view)
	assert_true(view._bubble.visible, "bulle de dialogue affichée")
	assert_eq(view._bubble_text.text, npc["repliques"][0])
	for i in npc["repliques"].size():
		view._next_dialogue_line()
	assert_false(view._bubble.visible, "bulle fermée après la dernière réplique")

	# Sortie par le bord droit.
	var exit_cell := Vector2i(-1, -1)
	for cell: Vector2i in map.cells():
		if map.is_walkable(cell) and "droite" in map.exit_directions(cell):
			exit_cell = cell
			break
	assert_true(map.is_inside(exit_cell), "case de sortie trouvée")
	view._on_click(exit_cell)
	_run_until_idle(view)
	assert_eq(view.world.map.id, map.exits["droite"])
	assert_eq(view.current_map().id, map.exits["droite"], "la vue affiche la nouvelle carte")
	assert_true(view.current_map().is_walkable(view.world.position_of(World.PLAYER_ID)))
	scene.free()
