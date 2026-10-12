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
	assert_eq(hud._spell_buttons.size(), 6, "attaque de l'épée de départ, 4 sorts du Guerrier, sort racial")

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


func test_nouveau_clic_pendant_la_marche() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var scene: Node = load("res://client/world/world.tscn").instantiate()
	tree.root.add_child(scene)
	var view: MapView = scene.get_node("MapView")
	var map := view.current_map()
	var start := view.world.position_of(World.PLAYER_ID)

	# Case la plus lointaine du départ, sans PNJ ni sortie.
	var far := start
	var longest := 0
	for cell: Vector2i in map.cells():
		if not map.is_walkable(cell) or not map.exit_directions(cell).is_empty():
			continue
		var length := map.find_path(start, cell).size()
		if length > longest:
			longest = length
			far = cell
	assert_true(longest >= 4, "trajet assez long pour être interrompu")

	view._on_click(far)
	view._process(0.1)
	assert_true(view.is_busy(), "le joueur est en train de marcher")
	view._on_click(start)
	assert_eq(view._pending_click, MapView.NO_CELL, "le clic n'attend pas la fin de la marche")
	_run_until_idle(view)
	assert_eq(view.world.position_of(World.PLAYER_ID), start, "nouvelle destination prise en compte")
	var shown: Vector2 = view.actor(World.PLAYER_ID)["pos"]
	assert_eq(Vector2i(shown.round()), start, "l'affichage suit le noyau")
	scene.free()
