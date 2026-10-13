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
	var cheapest := -1
	for i in shop._shop["articles"].size():
		var article: Dictionary = shop._shop["articles"][i]
		if article["type"] == Item.TYPE_RESOURCE and (cheapest < 0 or int(article["prix"]) < int(shop._shop["articles"][cheapest]["prix"])):
			cheapest = i
	var resource: Dictionary = shop._shop["articles"][cheapest]
	assert_eq(resource["type"], Item.TYPE_RESOURCE)
	shop._on_item_selected(cheapest)
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


func test_maison_lit_et_coffre() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var scene: Node = load("res://client/world/world.tscn").instantiate()
	tree.root.add_child(scene)
	var view: MapView = scene.get_node("MapView")
	var chest_window: ChestWindow = scene.get_node("ChestWindow")
	var village := view.current_map()
	assert_eq(village.doors.size(), 1, "la porte de la maison")
	var door: Vector2i = village.doors.keys()[0]
	assert_true(view._describe(door).begins_with("Porte"), view._describe(door))

	view._on_click(door)
	_run_until_idle(view)
	assert_eq(view.world.map.id, "maison_joueur", "dans la maison")
	assert_eq(view.current_map().id, "maison_joueur")
	var house := view.current_map()
	var bed := Vector2i(-99, -99)
	var chest := Vector2i(-99, -99)
	for cell: Vector2i in house.obstacles:
		if house.obstacles[cell] == "lit":
			bed = cell
		elif house.obstacles[cell] == "coffre":
			chest = cell

	# Le lit rend tous les PV.
	var character := view.world.character
	character.hp_lost = 30
	view._on_click(bed)
	_run_until_idle(view)
	assert_eq(character.hp_lost, 0, "PV au maximum après une nuit")

	# Le coffre : déposer puis reprendre une pile de ressources.
	character.inventory.add(view.world.data.items["peau_de_loup"], 3)
	view._on_click(chest)
	_run_until_idle(view)
	assert_true(chest_window.is_open(), "coffre ouvert")
	chest_window._select("peau_de_loup", false)
	assert_eq(int(chest_window._quantity.value), 3, "toute la pile par défaut")
	chest_window._on_deposit_pressed()
	assert_eq(character.chest.quantity_of("peau_de_loup"), 3, "rangé dans le coffre")
	assert_eq(character.inventory.quantity_of("peau_de_loup"), 0)
	assert_eq(chest_window._chest_list.item_count, 1, "le coffre affiche la pile")
	chest_window._select("peau_de_loup", true)
	chest_window._quantity.value = 1
	chest_window._on_withdraw_pressed()
	assert_eq(character.inventory.quantity_of("peau_de_loup"), 1, "une peau reprise")
	chest_window.close()

	# Ressortir.
	view._on_click(house.door_to(village.id))
	_run_until_idle(view)
	assert_eq(view.world.map.id, village.id, "de retour au village")
	assert_eq(view.world.position_of(World.PLAYER_ID), door, "devant la porte")
	scene.free()


func test_reapparition_des_monstres_et_fenetre_des_metiers() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var scene: Node = load("res://client/world/world.tscn").instantiate()
	tree.root.add_child(scene)
	var view: MapView = scene.get_node("MapView")
	var world := view.world

	# Un groupe vaincu (simulé) revient tout seul sur la carte affichée.
	var group: Dictionary = world.groups()[0]
	world._schedule_respawn(world.map.id, group)
	world._groups.erase(group["id"])
	world._positions.erase(group["id"])
	view._load_exploration_actors()
	assert_false(view._actors.has(group["id"]), "groupe vaincu")
	view._process(200.0)
	assert_true(view._actors.has(group["id"]), "le groupe est réapparu à l'écran")
	assert_eq(world.groups().size(), 3)

	# Fenêtre des métiers : un onglet par métier.
	var jobs: JobsWindow = scene.get_node("JobsWindow")
	jobs.toggle()
	assert_true(jobs.is_open())
	assert_eq(jobs._tabs.tab_count, world.data.jobs.size(), "un onglet par métier")
	jobs.select_job("forgeron")
	assert_eq(jobs.current_job(), "forgeron")
	assert_eq(jobs._title.text, "Forgeron")
	assert_eq(jobs._list.item_count, world.data.jobs["forgeron"]["recettes"].size(), "toutes les recettes")
	jobs.select_job("bucheron")
	assert_eq(jobs._list.item_count, world.data.jobs["bucheron"]["ressources"].size(), "toutes les ressources")
	jobs.toggle()
	scene.free()


func test_pierre_de_passage() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var scene: Node = load("res://client/world/world.tscn").instantiate()
	tree.root.add_child(scene)
	var view: MapView = scene.get_node("MapView")
	var travel: TravelWindow = scene.get_node("TravelWindow")
	var stone := view.current_map().travel_stone()
	assert_ne(stone, Vector2i(-1, -1), "une Pierre de Passage à Brumerive")
	assert_true(view._describe(stone).begins_with("Pierre de Passage"), view._describe(stone))

	view._on_click(stone)
	_run_until_idle(view)
	assert_true(travel.is_open(), "la liste des destinations s'ouvre")
	var buttons := travel.destination_buttons()
	assert_eq(buttons.size(), view.world.data.passages.size())
	var target: Button = null
	for button in buttons:
		assert_true(button.disabled == button.text.contains("vous êtes ici"), button.text)
		if button.text.begins_with("Crasse-Roc"):
			target = button
	assert_true(target != null, "Crasse-Roc parmi les destinations")
	target.pressed.emit()
	_run_until_idle(view)
	assert_false(travel.is_open())
	assert_eq(view.world.map.id, "crasse_roc_0_0", "téléporté à Crasse-Roc")
	assert_eq(view.current_map().id, "crasse_roc_0_0")
	assert_eq(Art.palette, "crasse_roc", "couleurs de la zone gobeline")
	scene.free()


func test_chaque_race_part_de_sa_zone() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	for pair in [["gobelin", "crasse_roc_0_0"], ["elfe", "sylvebrume_0_0"], ["humain", "brumerive_0_0"]]:
		Session.continue_game = false
		Session.new_character = Character.create("Essai", pair[0], "guerrier")
		var scene: Node = load("res://client/world/world.tscn").instantiate()
		tree.root.add_child(scene)
		var view: MapView = scene.get_node("MapView")
		assert_eq(view.world.map.id, pair[1], "départ des %ss" % pair[0])
		scene.free()
	Session.new_character = null


func test_barre_d_action_et_fenetre_des_sorts() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var scene: Node = load("res://client/world/world.tscn").instantiate()
	tree.root.add_child(scene)
	var view: MapView = scene.get_node("MapView")
	var hud: CombatHud = scene.get_node("CombatHud")
	var spells: SpellsWindow = scene.get_node("SpellsWindow")
	var world := view.world

	# En exploration aussi, la barre montre les PV (cœur), PA (étoile), PM (case) et les sorts en icônes.
	hud._refresh_exploration()
	var sheet := world.character.sheet(world.data)
	assert_eq(hud._hp_gauge.value, int(sheet["pv"]))
	assert_eq(hud._hp_gauge.maximum, int(sheet["pv_max"]))
	assert_eq(hud._pa_gauge.value, int(sheet["pa"]))
	assert_eq(hud._pm_gauge.value, int(sheet["pm"]))
	assert_eq(hud._spell_buttons.size(), 6, "sorts du personnage dans la barre")
	for spell_id: String in hud._spell_buttons:
		var slot: CombatHud.SpellSlot = hud._spell_buttons[spell_id]
		assert_true(slot.icon != null, "icône du sort %s" % spell_id)
		assert_true(slot.icon != Art.texture("sort_inconnu"), "icône dessinée pour %s" % spell_id)
	assert_eq(hud._menu_buttons.size(), 4, "personnage, inventaire, sorts, métiers")

	# Un clic sur un sort hors combat ouvre sa fiche dans la fenêtre des sorts.
	var first: String = hud._shown_spells[1]
	hud._on_spell_pressed(first)
	assert_true(spells.is_open(), "fenêtre des sorts ouverte")
	assert_eq(spells._selected, first)
	assert_eq(spells._tabs.tab_count, 3, "Voie, race, arme")
	assert_eq(spells._title.text, world.data.spells[first].display_name)
	var voie: Dictionary = world.data.voies[world.character.voie_id]
	assert_eq(spells._list.item_count, voie["sorts"].size(), "tous les sorts de la Voie")

	# Onglet de la race, puis fermeture par le bouton de menu de la barre.
	spells._tabs.current_tab = 1
	assert_eq(spells._list.item_count, 1, "le sort racial")
	assert_eq(spells._selected, world.data.races[world.character.race_id]["sort"])
	hud.menu_pressed.emit("sorts")
	assert_false(spells.is_open())
	hud.menu_pressed.emit("metiers")
	assert_true((scene.get_node("JobsWindow") as JobsWindow).is_open(), "le bouton métiers ouvre la fenêtre")
	scene.free()


func test_tous_les_membres_d_un_groupe_sont_affiches() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var scene: Node = load("res://client/world/world.tscn").instantiate()
	tree.root.add_child(scene)
	var view: MapView = scene.get_node("MapView")
	for group: Dictionary in view.world.groups():
		var actor: Dictionary = view._actors[group["id"]]
		assert_eq(str(actor["members"]), str(group["monstres"]), "chaque membre du groupe est dessiné")
		assert_true(actor["members"].size() <= GameMap.MAX_GROUP_SIZE)
	var mixed: Dictionary = view._actors["groupe_3"]
	assert_eq(mixed["name"], "Groupe : Gobelin frondeur, Loup des collines", "groupe mixte nommé au survol")
	assert_eq(view._actors["groupe_2"]["name"], "Groupe : 2 × Loup des collines")
	assert_eq(view._actors["groupe_1"]["name"], "Loup des collines")

	# En haut de l'écran, seulement le nom de la carte ; ce qu'on survole va dans une bulle.
	var info: Label = scene.get_node("%Info")
	assert_eq(info.text, view.current_map().display_name, "le nom de la carte, rien d'autre")
	view._set_hovered(view.world.groups()[0]["case"])
	assert_eq(info.text, view.current_map().display_name)
	assert_true(scene._hover_bubble.visible, "bulle au survol d'un groupe")
	var hovered: Dictionary = view.world.groups()[0]
	var expected: PackedStringArray = []
	for monster_id: String in hovered["monstres"]:
		expected.append("Niv. %d %s" % [view.world.data.monsters[monster_id]["niveau"], view.world.data.monsters[monster_id]["nom"]])
	assert_eq(scene._hover_label.text, "\n".join(expected), "un monstre par ligne, niveau devant")
	view._set_hovered(view.current_map().spawn)
	assert_false(scene._hover_bubble.visible, "pas de bulle sur une case vide")

	# Les groupes se promènent : la carte les fait marcher jusqu'à leur nouvelle case.
	var walked := false
	for i in 60:
		view._process(1.0)
		if not view._group_walks.is_empty():
			walked = true
			break
	assert_true(walked, "un groupe s'est mis en marche")
	var walker: String = view._group_walks.keys()[0]
	for i in 20:
		view._process(0.2)
	assert_false(view._group_walks.has(walker), "promenade terminée")
	assert_eq(Vector2i(view._actors[walker]["pos"].round()), view.world.position_of(walker), "arrivé là où le monde l'a mis")
	scene.free()


func test_sac_surcharge_pas_de_combat() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var scene: Node = load("res://client/world/world.tscn").instantiate()
	tree.root.add_child(scene)
	var view: MapView = scene.get_node("MapView")
	var inventory := view.world.character.inventory
	inventory.capacity = inventory.entries.size() - 1  # Le sac déborde d'un objet.
	var messages: Array[String] = []
	view.notice.connect(func(text: String) -> void: messages.append(text))
	var start := view.world.position_of(World.PLAYER_ID)
	view._on_click(view.world.groups()[0]["case"])
	_run_until_idle(view)
	assert_eq(view.mode, MapView.Mode.EXPLORATION, "pas de combat")
	assert_eq(view.world.position_of(World.PLAYER_ID), start, "le personnage ne part même pas")
	assert_eq(messages, [CombatHud.OVERLOAD_TEXT] as Array[String], "on lui dit de faire de la place")
	var window: InventoryWindow = scene.get_node("InventoryWindow")
	window.toggle()
	assert_true(window._overload.visible, "l'inventaire le signale aussi")
	scene.free()


func test_couronne_d_anciennete_d_une_elite() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var scene: Node = load("res://client/world/world.tscn").instantiate()
	tree.root.add_child(scene)
	var view: MapView = scene.get_node("MapView")
	var world := view.world
	world.map_ids = [world.map.id]
	var events: Array[Dictionary] = []
	assert_true(world.spawn_elite("loup_alpha", events), "le Loup alpha apparaît à Brumerive")
	for event in events:
		view._apply_world_change(event)
	var where := world.elite_location("loup_alpha")
	var cell: Vector2i = world.group(where["groupe"])["case"]
	assert_true(view._actors[where["groupe"]]["members"].has("loup_alpha"), "dessiné sur la carte")
	world.clock += 7 * World.ELITE_RANK_SECONDS + 1.0
	view._set_hovered(cell)
	var crown: EliteCrown = scene._hover_crown
	assert_eq(crown.rank, 7)
	assert_eq(crown.diamonds(), 5, "5 losanges")
	assert_eq(crown.triangles(), 2, "puis des triangles au-dessus")
	assert_true(scene._hover_label.text.contains("Loup alpha (élite)"), scene._hover_label.text)
	assert_true(scene._hover_label.text.contains("Butin : +70 %"), scene._hover_label.text)
	view._set_hovered(view.current_map().spawn)
	assert_false(scene._hover_bubble.visible)
	scene.free()
