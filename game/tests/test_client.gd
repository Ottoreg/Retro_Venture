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



func test_interrompre_la_marche_vers_un_combat_ou_une_sortie() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var scene: Node = load("res://client/world/world.tscn").instantiate()
	tree.root.add_child(scene)
	var view: MapView = scene.get_node("MapView")
	var map := view.current_map()
	var start := view.world.position_of(World.PLAYER_ID)

	# Vers un groupe de monstres, puis contrordre : pas de combat.
	var group: Dictionary = view.world.groups()[0]
	view._on_click(group["case"])
	view._process(0.1)
	assert_true(view.is_busy(), "en marche vers le groupe")
	assert_false(view.world.in_combat(), "le combat attend l'arrivée")
	view._on_click(start)
	_run_until_idle(view)
	assert_eq(view.mode, MapView.Mode.EXPLORATION, "pas de combat")
	assert_false(view.world.in_combat())
	assert_eq(view.world.position_of(World.PLAYER_ID), start)

	# Vers la sortie, puis contrordre : on reste sur la carte.
	var exit_cell := Vector2i(-1, -1)
	for cell: Vector2i in map.cells():
		if map.is_walkable(cell) and "droite" in map.exit_directions(cell):
			exit_cell = cell
			break
	view._on_click(exit_cell)
	view._process(0.1)
	assert_true(view.is_busy(), "en marche vers la sortie")
	assert_eq(view.world.map.id, map.id, "le changement de carte attend l'arrivée")
	view._on_click(start)
	_run_until_idle(view)
	assert_eq(view.world.map.id, map.id, "toujours sur la même carte")
	assert_eq(view.current_map().id, map.id)
	assert_eq(view.world.position_of(World.PLAYER_ID), start)
	scene.free()


func test_boutique_du_marchand() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var scene: Node = load("res://client/world/world.tscn").instantiate()
	tree.root.add_child(scene)
	var view: MapView = scene.get_node("MapView")
	var shop: ShopWindow = scene.get_node("ShopWindow")
	var merchant: Dictionary = {}
	for npc: Dictionary in view.current_map().npcs:
		if npc["marchand"]:
			merchant = npc
	assert_false(merchant.is_empty(), "un marchand au village")

	view._on_click(merchant["case"])
	_run_until_idle(view)
	assert_true(shop.is_open(), "la boutique s'ouvre")
	assert_false(view._bubble.visible, "pas de bulle de dialogue")
	assert_eq(shop._list.item_count, view.world.data.items.size(), "tous les objets en vente")

	# Achat d'une ressource en plusieurs exemplaires.
	var inventory := view.world.character.inventory
	inventory.ecus = 500
	var resource: Dictionary = shop._shop["articles"][-1]
	assert_eq(resource["type"], Item.TYPE_RESOURCE)
	shop._on_item_selected(shop._list.item_count - 1)
	assert_true(shop._quantity_box.visible, "quantité réglable pour une ressource")
	shop._quantity.value = 3
	shop._on_action_pressed()
	assert_eq(inventory.quantity_of(resource["objet"]), 3, "achat effectué")
	assert_eq(inventory.ecus, 500 - 3 * int(resource["prix"]))
	assert_true(shop._message.text.begins_with("Acheté"), shop._message.text)

	# Revente de ces ressources.
	shop._on_tab_pressed(ShopWindow.SELL)
	shop._selected = resource["objet"]
	shop.refresh()
	shop._quantity.value = 3
	shop._on_action_pressed()
	assert_eq(inventory.quantity_of(resource["objet"]), 0, "vente effectuée")
	assert_eq(inventory.ecus, 500 - 3 * int(resource["prix"]) + 3 * Item.sell_price(view.world.data.items[resource["objet"]]))
	assert_true(shop._message.text.begins_with("Vendu"), shop._message.text)

	# L'arme de départ est portée : elle ne se vend pas.
	var weapon := inventory.equipped_entry("arme")
	shop._selected = weapon["uid"]
	shop.refresh()
	assert_true(shop._action_button.disabled, "objet porté : bouton désactivé")

	shop.close()
	assert_false(shop.is_open())
	scene.free()


func test_recolte_et_repousse() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var scene: Node = load("res://client/world/world.tscn").instantiate()
	tree.root.add_child(scene)
	var view: MapView = scene.get_node("MapView")
	var map := view.current_map()
	var notices: Array[String] = []
	view.notice.connect(func(text: String) -> void: notices.append(text))

	# Un frêne du village : le joueur marche jusqu'à lui et le coupe.
	var ash := Vector2i(-1, -1)
	for cell: Vector2i in map.resource_nodes:
		if view.world.resource_node(cell).get("objet") == "bois_de_frene":
			ash = cell
			break
	assert_true(map.is_inside(ash), "un frêne au village")
	assert_true(view._describe(ash).begins_with("Frêne"), view._describe(ash))
	view._on_click(ash)
	_run_until_idle(view)
	var inventory := view.world.character.inventory
	assert_true(inventory.quantity_of("bois_de_frene") > 0, "bois récolté")
	assert_true(GameMap.is_adjacent(view.world.position_of(World.PLAYER_ID), ash), "à côté de l'arbre")
	assert_true(view.world.is_depleted(ash), "arbre coupé")
	assert_true(view.world.character.job_xp("bucheron") > 0, "XP de bûcheron")

	# Déjà coupé : un message, pas de marche.
	view._on_click(ash)
	assert_false(view.is_busy(), "pas de marche vers un arbre coupé")
	assert_eq(notices.size(), 1, "message affiché")

	# Repousse au bout de deux minutes au plus.
	view._process(121.0)
	assert_false(view.world.is_depleted(ash), "l'arbre a repoussé")
	scene.free()


func test_atelier_du_forgeron() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var scene: Node = load("res://client/world/world.tscn").instantiate()
	tree.root.add_child(scene)
	var view: MapView = scene.get_node("MapView")
	var craft: CraftWindow = scene.get_node("CraftWindow")
	var smith: Dictionary = {}
	for npc: Dictionary in view.current_map().npcs:
		if npc["atelier"] == "forgeron":
			smith = npc
	assert_false(smith.is_empty(), "un forgeron au village")

	view._on_click(smith["case"])
	_run_until_idle(view)
	assert_true(craft.is_open(), "l'atelier s'ouvre")
	var inventory := view.world.character.inventory
	inventory.add(view.world.data.items["minerai_de_cuivre"], 4)
	var index := -1
	for i in craft._list.item_count:
		if craft._list.get_item_metadata(i) == "anneau_de_cuivre":
			index = i
	assert_true(index >= 0, "recette de l'anneau de cuivre")
	craft._on_item_selected(index)
	assert_false(craft._craft_button.disabled, "ingrédients réunis")
	craft._on_craft_pressed()
	assert_eq(inventory.quantity_of("anneau_de_cuivre"), 1, "anneau fabriqué")
	assert_eq(inventory.quantity_of("minerai_de_cuivre"), 0, "minerai consommé")
	assert_true(craft._message.text.begins_with("Fabriqué"), craft._message.text)
	assert_true(view.world.character.job_level("forgeron") >= 2, "XP de forgeron")
	assert_true(craft._craft_button.disabled, "plus assez de minerai")
	craft.close()
	scene.free()
