extends "res://tests/test_case.gd"
## Client en ligne (GDD § 16.5, jalon M1) : la carte joue avec une connexion asynchrone (les
## réponses arrivent après l'envoi, comme d'un serveur) et montre les autres joueurs de la carte.


## Connexion locale qui garde chaque réponse jusqu'au `take_replies` suivant, comme le réseau.
class DelayedConnection extends LocalConnection:
	var held: Array = []

	func _init(p_world: World) -> void:
		super(p_world)
		asynchronous = true

	func send(command: Dictionary) -> Array[Dictionary]:
		held.append(super.send(command))
		return [] as Array[Dictionary]

	func take_replies() -> Array:
		var replies := held
		held = []
		return replies


func before_each() -> void:
	Session.quest_pin = {}
	Options.path = "user://options_tests.cfg"
	Options.reset()


func _run_until_idle(view: MapView) -> void:
	for i in 1000:
		if not view.is_busy():
			return
		view.advance(0.5)


func _scene() -> Node:
	var scene: Node = load("res://client/world/world.tscn").instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(scene)
	return scene


func test_combat_avec_des_reponses_differees() -> void:
	var scene := _scene()
	var view: MapView = scene.get_node("MapView")
	var connection := DelayedConnection.new(view.server)
	view.setup(connection)
	var group: Dictionary = view.world.groups()[0]
	view._on_click(group["case"])
	assert_true(view.is_busy(), "en attente de la réponse")
	assert_eq(connection.held.size(), 1, "un seul envoi avant la réponse")
	_run_until_idle(view)
	assert_eq(view.mode, MapView.Mode.COMBAT, "marche puis combat, réponse par réponse")
	view.request_start_fight()
	_run_until_idle(view)
	assert_true(view.is_player_turn())
	for i in 100:
		if view.mode == MapView.Mode.EXPLORATION:
			break
		view.request_end_turn()
		_run_until_idle(view)
	assert_eq(view.mode, MapView.Mode.EXPLORATION, "combat fini")
	assert_false(view.is_busy())
	var target := view.world.position_of(view.world.player_id) + Vector2i(1, 0)
	if not view.current_map().is_walkable(target):
		target = view.world.position_of(view.world.player_id) + Vector2i(0, 1)
	view._on_click(target)
	_run_until_idle(view)
	assert_eq(view.world.position_of(view.world.player_id), target, "on marche encore après le combat")
	scene.queue_free()


func test_autres_joueurs_de_la_carte() -> void:
	var scene := _scene()
	var view: MapView = scene.get_node("MapView")
	var world := view.server
	var sam := Character.create("Sam", "gobelin", "rodeur")
	var cell := world.position_of(world.player_id)
	world.add_player(sam, "j:sam", world.map.id, cell)
	view.refresh_state()
	view._load_exploration_actors()
	assert_true(view._actors.has("j:sam"), "Sam est affiché")
	assert_eq(view._actors["j:sam"]["race"], "gobelin")
	assert_eq(view._actors["j:sam"]["kind"], "rodeur", "dessiné avec la tenue de sa Voie")
	assert_true(view.actor_look("j:sam").has("rig"), "en personnage articulé")
	assert_eq(view._describe(cell), "Sam\nNiveau 1, Gobelin Rôdeur\nCliquer pour l'inviter dans le groupe", "son nom au survol")
	var target := cell + Vector2i(1, 0)
	var moved: Array[Dictionary] = world.execute({"type": Protocol.CMD_MOVE, "entite": "j:sam", "cible": target})
	view.world.apply_event(moved[0])
	view._apply_world_change(moved[0])
	for i in 20:
		view.advance(0.5)
	assert_eq(Vector2i(view._actors["j:sam"]["pos"]), target, "Sam marche jusqu'à sa case")
	var engaged := {"type": Protocol.EVT_GROUP_ENGAGED, "carte": world.map.id, "groupe": view.world.groups()[0]["id"], "entite": "j:sam"}
	view.world.apply_event(engaged)
	view._apply_world_change(engaged)
	assert_false(view._actors.has(engaged["groupe"]), "le groupe qu'il combat disparaît")
	var left := {"type": Protocol.EVT_PLAYER_LEFT, "carte": world.map.id, "entite": "j:sam"}
	view.world.apply_event(left)
	view._apply_world_change(left)
	assert_false(view._actors.has("j:sam"), "Sam est parti")
	scene.queue_free()


func test_ecran_de_connexion_serveur_de_developpement() -> void:
	var maps := {"test": preload("res://tests/helpers/fixtures.gd").map({}, [], {"id": "test"})}
	var loader := func(map_id: String) -> GameMap: return maps.get(map_id)
	var server := GameServer.new(preload("res://tests/helpers/fixtures.gd").data(), loader, CharacterStore.new(), AccountCheck.new(), [], "test")
	var host := WebSocketHost.new(server)
	host.listen(0, "127.0.0.1")
	Options.server_address = "ws://127.0.0.1:%d" % host.port()
	OnlineScreen.force_dev = true
	var screen: OnlineScreen = load(OnlineScreen.SCENE).instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(screen)
	OnlineScreen.force_dev = false
	assert_true(screen._pseudo != null and screen._email == null, "sans Supabase : un pseudo suffit")
	screen._pseudo.text = "Frodon"
	screen._on_connect_pressed()
	var connection := Session.online_connection
	assert_true(connection != null, "connexion ouverte")
	var start := Time.get_ticks_msec()
	while connection.status != RemoteConnection.Status.NEEDS_CHARACTER and Time.get_ticks_msec() - start < 5000:
		host.poll()
		connection.poll()
		OS.delay_msec(2)
	assert_eq(connection.status, RemoteConnection.Status.NEEDS_CHARACTER, "compte neuf : création du personnage")
	assert_eq(Session.online_login, {"jeton": "dev:Frodon"}, "connexion retenue pour une reprise")
	connection.close()
	Session.online_connection = null
	screen.queue_free()
	# Connexion coupée en jeu : l'écran la rouvre tout seul, sans redemander le pseudo.
	Session.online_resume = true
	OnlineScreen.force_dev = true
	var again: OnlineScreen = load(OnlineScreen.SCENE).instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(again)
	OnlineScreen.force_dev = false
	assert_false(Session.online_resume, "reprise lancée une seule fois")
	connection = Session.online_connection
	assert_true(connection != null, "connexion rouverte sans rien demander")
	start = Time.get_ticks_msec()
	while connection != null and connection.status != RemoteConnection.Status.NEEDS_CHARACTER and Time.get_ticks_msec() - start < 5000:
		host.poll()
		connection.poll()
		OS.delay_msec(2)
	assert_eq(connection.status, RemoteConnection.Status.NEEDS_CHARACTER, "même compte retrouvé")
	connection.close()
	Session.online_connection = null
	Session.online_login = {}
	again.queue_free()


func test_adresse_supabase_sans_chemin_de_l_api() -> void:
	var host := Node.new()
	assert_eq(Supabase.new("https://abc.supabase.co/rest/v1/", "cle", host).url, "https://abc.supabase.co")
	assert_eq(Supabase.new("https://abc.supabase.co/", "cle", host).url, "https://abc.supabase.co")
	host.free()


## Connexions locales de plusieurs joueurs sur un même monde : ce que la commande de l'un produit pour
## les autres leur arrive à leur prochain `update`, comme par le serveur (`World.recipients`).
class SharedConnection extends LocalConnection:
	var others: Array = []
	var inbox: Array[Dictionary] = []

	func send(command: Dictionary) -> Array[Dictionary]:
		var events := world.execute(_through_wire(command))
		for other: SharedConnection in others:
			var theirs: Array[Dictionary] = []
			for event in events:
				if other.player_id in world.recipients(event, player_id):
					theirs.append(event)
			other.inbox.append_array(other._received(theirs, player_id))
		return _received(events, player_id)

	func update(delta: float) -> Array[Dictionary]:
		var events := inbox
		inbox = []
		events.append_array(super.update(delta))
		return events


func test_combat_de_groupe_vu_des_deux_clients() -> void:
	var scene := _scene()
	var frodon_view: MapView = scene.get_node("MapView")
	var world := frodon_view.server
	var group: Dictionary = frodon_view.world.groups()[0]
	world.add_player(Character.create("Sam", "humain", World.DEFAULT_VOIE), "j:sam", world.map.id, world.position_of(world.player_id))
	world.data.give_starting_kit(world.player("j:sam").character)
	var frodon := SharedConnection.new(world)
	var sam := SharedConnection.new(world, "j:sam")
	frodon.others = [sam]
	sam.others = [frodon]
	frodon_view.setup(frodon)
	var sam_view := MapView.new()
	scene.add_child(sam_view)
	sam_view.setup(sam)
	# Groupe : Frodon invite Sam, qui accepte.
	frodon_view.send_command({"type": Protocol.CMD_PARTY_INVITE, "entite": world.player_id, "joueur": "j:sam"})
	var invited := []
	sam_view.party_invited.connect(func(event: Dictionary) -> void: invited.append(event))
	sam_view.advance(0.1)
	assert_eq(invited.size(), 1, "Sam reçoit l'invitation")
	var party_shown := []
	sam_view.party_changed.connect(func() -> void: party_shown.append(true))
	sam_view.send_command({"type": Protocol.CMD_PARTY_ANSWER, "entite": "j:sam", "chef": world.player_id, "accepte": true})
	_run_until_idle(sam_view)
	assert_false(party_shown.is_empty(), "le groupe s'affiche aussi chez Sam, qui n'est pas le chef")
	frodon_view.advance(0.1)
	assert_true(frodon_view.world.is_party_member("j:sam"), "Frodon voit Sam dans son groupe")
	# Frodon attaque : Sam voit les épées, et Frodon disparaît.
	frodon_view._on_click(group["case"])
	_run_until_idle(frodon_view)
	assert_eq(frodon_view.mode, MapView.Mode.COMBAT)
	sam_view.advance(0.1)
	var swords := sam_view.world.fight_at(group["case"])
	assert_false(swords.is_empty(), "les épées du combat chez Sam")
	assert_false(sam_view._actors.has(world.player_id), "Frodon n'est plus sur la carte de Sam")
	assert_true(sam_view._describe(group["case"]).begins_with("Combat de"), "épées décrites au survol")
	sam_view._on_click(group["case"])
	_run_until_idle(sam_view)
	assert_eq(sam_view.mode, MapView.Mode.COMBAT, "Sam a rejoint le combat")
	assert_true(sam_view._actors.has(world.player_id), "il y voit Frodon")
	frodon_view.advance(0.1)
	_run_until_idle(frodon_view)
	assert_true(frodon_view._actors.has("j:sam"), "Frodon voit Sam arriver")
	frodon_view.request_start_fight()
	_run_until_idle(frodon_view)
	assert_true(frodon_view.is_placement(), "on attend Sam")
	sam_view.request_start_fight()
	_run_until_idle(sam_view)
	frodon_view.advance(0.1)
	_run_until_idle(frodon_view)
	assert_false(frodon_view.is_placement(), "le combat commence chez Frodon aussi")
	var ended := []
	sam_view.combat_ended.connect(func(result: Dictionary) -> void: ended.append(result))
	for i in 200:
		if frodon_view.mode == MapView.Mode.EXPLORATION and sam_view.mode == MapView.Mode.EXPLORATION:
			break
		for view: MapView in [frodon_view, sam_view]:
			view.advance(0.5)
			if view.is_player_turn():
				view.request_end_turn()
			_run_until_idle(view)
	assert_eq(frodon_view.mode, MapView.Mode.EXPLORATION, "combat fini chez Frodon")
	assert_eq(sam_view.mode, MapView.Mode.EXPLORATION, "et chez Sam")
	assert_eq(ended.size(), 1, "Sam a eu sa fin de combat")
	scene.queue_free()


func test_retour_en_plein_combat_barre_de_combat() -> void:
	var first := _scene()
	var view: MapView = first.get_node("MapView")
	var group: Dictionary = view.world.groups()[0]
	view._on_click(group["case"])
	_run_until_idle(view)
	view.request_start_fight()
	_run_until_idle(view)
	assert_eq(view.mode, MapView.Mode.COMBAT)
	# Reconnexion : la carte se charge sur un monde déjà en combat, puis l'interface s'y branche
	# (ordre de `world_scene._ready`).
	var again := MapView.new()
	first.add_child(again)
	again.setup(LocalConnection.new(view.server))
	var hud := CombatHud.new()
	first.add_child(hud)
	hud.setup(again)
	again.announce_combat()
	assert_eq(again.mode, MapView.Mode.COMBAT)
	assert_true(hud._turn_button.visible, "bouton « Fin du tour » au retour")
	assert_false(hud._sit_button.visible, "plus de « S'asseoir »")
	assert_true(hud._spells_box.visible, "barre des sorts")
	first.queue_free()


## Frodon (le monde de la scène) et Sam, chacun avec sa vue, sur la même carte.
func _two_clients(scene: Node) -> Array[MapView]:
	var frodon_view: MapView = scene.get_node("MapView")
	var world := frodon_view.server
	world.add_player(Character.create("Sam", "humain", World.DEFAULT_VOIE), "j:sam", world.map.id, world.position_of(world.player_id))
	world.data.give_starting_kit(world.player("j:sam").character)
	var frodon := SharedConnection.new(world)
	var sam := SharedConnection.new(world, "j:sam")
	frodon.others = [sam]
	sam.others = [frodon]
	frodon_view.setup(frodon)
	var sam_view := MapView.new()
	scene.add_child(sam_view)
	sam_view.setup(sam)
	var views: Array[MapView] = [frodon_view, sam_view]
	return views


func _run_both(views: Array[MapView]) -> void:
	for i in 400:
		for view in views:
			view.advance(0.25)
		if views.all(func(view: MapView) -> bool: return not view.is_busy()):
			return


func test_suivre_un_membre_du_groupe_jusque_sur_une_autre_carte() -> void:
	var scene := _scene()
	var views := _two_clients(scene)
	var frodon_view := views[0]
	var sam_view := views[1]
	var world := frodon_view.server
	frodon_view.send_command({"type": Protocol.CMD_PARTY_INVITE, "entite": world.player_id, "joueur": "j:sam"})
	sam_view.send_command({"type": Protocol.CMD_PARTY_ANSWER, "entite": "j:sam", "chef": world.player_id, "accepte": true})
	_run_both(views)
	sam_view.toggle_follow(world.player_id)
	assert_eq(sam_view.follow_id, world.player_id)
	# Frodon marche : Sam part au même endroit.
	var map := frodon_view.current_map()
	var start := world.position_of(world.player_id)
	var target := start
	for cell: Vector2i in map.cells():
		if map.is_walkable(cell) and map.exit_directions(cell).is_empty() and map.npc_at(cell).is_empty() \
				and frodon_view.world.group_at(cell).is_empty() and not map.resource_nodes.has(cell) and absi(cell.x - start.x) + absi(cell.y - start.y) in range(3, 6) \
				and not map.find_path(start, cell).is_empty():
			target = cell
			break
	frodon_view._on_click(target)
	_run_both(views)
	assert_eq(world.position_of("j:sam"), target, "Sam a suivi Frodon")
	# Frodon change de carte par une sortie : Sam aussi.
	var exit := Vector2i(-1, -1)
	for cell: Vector2i in map.cells():
		if map.is_walkable(cell) and not map.exit_directions(cell).is_empty() and not map.find_path(target, cell).is_empty():
			exit = cell
			break
	frodon_view._on_click(exit)
	_run_both(views)
	assert_ne(world.player(world.player_id).map.id, map.id, "Frodon a changé de carte")
	assert_eq(world.player("j:sam").map.id, world.player(world.player_id).map.id, "Sam l'a suivi")
	assert_eq(sam_view.world.party_member(world.player_id)["carte"], world.player(world.player_id).map.id, "carte du membre connue")
	# Un clic pour marcher arrête de suivre.
	var elsewhere := sam_view.world.position_of("j:sam")
	for cell: Vector2i in sam_view.current_map().cells():
		if sam_view.current_map().is_walkable(cell) and sam_view.world.player_at(cell).is_empty():
			elsewhere = cell
			break
	sam_view._explore(elsewhere)
	assert_eq(sam_view.follow_id, "")
	scene.queue_free()


func test_regarder_le_combat_d_un_autre_joueur() -> void:
	var scene := _scene()
	var views := _two_clients(scene)
	var frodon_view := views[0]
	var sam_view := views[1]
	var group: Dictionary = frodon_view.world.groups()[0]
	frodon_view._on_click(group["case"])
	_run_until_idle(frodon_view)
	var hud: CombatHud = scene.get_node("CombatHud")
	assert_true(hud._lock_box.visible, "verrous pour celui qui a engagé le combat")
	sam_view.advance(0.1)
	assert_true(sam_view._describe(group["case"]).contains("regarder"), "les épées proposent de regarder")
	sam_view._on_click(group["case"])
	_run_until_idle(sam_view)
	assert_eq(sam_view.mode, MapView.Mode.COMBAT, "Sam regarde le combat")
	assert_true(sam_view.world.spectating)
	assert_true(sam_view._actors.has(frodon_view.world.player_id), "il y voit Frodon")
	sam_view._on_click(sam_view.world.combat.placement_cells[0])
	assert_false(sam_view.is_busy(), "un spectateur ne joue pas")
	frodon_view.request_start_fight()
	_run_until_idle(frodon_view)
	for i in 200:
		if sam_view.mode == MapView.Mode.EXPLORATION:
			break
		frodon_view.advance(0.5)
		if frodon_view.is_player_turn():
			frodon_view.request_end_turn()
		_run_until_idle(frodon_view)
		sam_view.advance(0.5)
		_run_until_idle(sam_view)
	assert_eq(sam_view.mode, MapView.Mode.EXPLORATION, "le combat fini, Sam revient sur la carte")
	assert_false(sam_view.world.spectating)
	scene.queue_free()


func test_inventaire_consultable_en_combat() -> void:
	var scene := _scene()
	var view: MapView = scene.get_node("MapView")
	var inventory: InventoryWindow = scene.get_node("InventoryWindow")
	var group: Dictionary = view.world.groups()[0]
	view._on_click(group["case"])
	_run_until_idle(view)
	assert_eq(view.mode, MapView.Mode.COMBAT)
	inventory.toggle()
	assert_true(inventory.is_open(), "s'ouvre en combat")
	assert_true(inventory.is_read_only())
	var worn: Dictionary = view.world.character.inventory.entries
	var uid: String = worn.keys()[0]
	var slot := view.world.character.inventory.slot_of(uid)
	inventory.toggle_worn(uid)
	assert_eq(view.world.character.inventory.slot_of(uid), slot, "rien ne change")
	assert_false(view.is_busy(), "aucune commande envoyée")
	scene.queue_free()


## Chat de bout en bout (jalon M3, lot 2) : Frodon écrit dans la ligne de saisie, Sam le lit dans
## son historique, et le menu d'un auteur prépare un message privé.
func test_chat_entre_deux_clients() -> void:
	var scene := _scene()
	var views := _two_clients(scene)
	var frodon_view := views[0]
	var sam_view := views[1]
	var frodon_hud := CombatHud.new()
	scene.add_child(frodon_hud)
	frodon_hud.setup(frodon_view)
	var sam_hud := CombatHud.new()
	scene.add_child(sam_hud)
	sam_hud.setup(sam_view)
	var party_ui := PartyUi.new()
	scene.add_child(party_ui)
	party_ui.setup(sam_view)
	sam_hud.message_log.author_clicked.connect(party_ui.on_author_clicked)
	party_ui.whisper_requested.connect(sam_hud.message_log.whisper_to)
	var frodon: String = frodon_view.world.player_name
	var sam: String = sam_view.world.player_name
	# `SharedConnection` répond tout de suite (elle ne pose pas `asynchronous`) : la ligne de saisie
	# s'allume comme elle le ferait en ligne.
	for hud: CombatHud in [frodon_hud, sam_hud]:
		hud.message_log.set_chat_enabled(true)
	assert_true(frodon_hud.message_log._input.visible, "ligne de saisie en ligne")

	# Frodon écrit en local : les deux le lisent, lui compris.
	frodon_hud.message_log.select_channel(Chat.LOCAL)
	frodon_hud.message_log._on_submitted("Bonjour la Comté")
	_run_until_idle(frodon_view)
	assert_true("%s : Bonjour la Comté" % frodon in frodon_hud.message_log.visible_lines(), str(frodon_hud.message_log.visible_lines()))
	sam_view.advance(0.1)
	_run_until_idle(sam_view)
	assert_true("%s : Bonjour la Comté" % frodon in sam_hud.message_log.visible_lines(), "Sam le lit aussi")
	assert_eq(sam_hud.message_log.lines(Chat.LOCAL).size(), 1, "rangé dans le canal Local")

	# Un message privé de Frodon : Sam répond par `/r`.
	frodon_hud.message_log._on_submitted("/w %s tu es là ?" % sam)
	_run_until_idle(frodon_view)
	sam_view.advance(0.1)
	_run_until_idle(sam_view)
	assert_true(sam_hud.message_log.lines(Chat.PRIVATE)[0].contains("tu es là ?"))
	sam_hud.message_log._on_submitted("/r présent")
	_run_until_idle(sam_view)
	frodon_view.advance(0.1)
	_run_until_idle(frodon_view)
	assert_true("%s : présent" % sam in frodon_hud.message_log.visible_lines(), str(frodon_hud.message_log.visible_lines()))

	# Clic sur le nom de Frodon dans l'historique de Sam : son menu, puis la ligne préparée.
	sam_hud.message_log._on_meta_clicked(MessageLog.AUTHOR_META + frodon.uri_encode())
	assert_true(party_ui._menu.item_count >= 2, "menu de l'auteur (inviter, message privé)")
	party_ui._on_menu_pressed(1)
	assert_eq(sam_hud.message_log._input.text, "/w %s " % frodon)

	# Trop vite : le refus du serveur est annoncé au joueur.
	frodon_hud.message_log.select_channel(Chat.LOCAL)
	for i in Chat.FLOOD_MESSAGES + 1:
		frodon_hud.message_log._on_submitted("message %d" % i)
		_run_until_idle(frodon_view)
	var tail := "\n".join(frodon_hud.message_log.visible_lines().slice(-3))
	assert_true(tail.contains("trop vite"), tail)
	scene.queue_free()


## Amis, ignorés et signalement côté client (jalon M3, lots 3 et 4) : menu du pseudo, fenêtre Amis,
## annonce d'arrivée, fenêtre du signalement.
func test_amis_et_signalement_entre_deux_clients() -> void:
	var scene := _scene()
	var views := _two_clients(scene)
	var frodon_view := views[0]
	var sam_view := views[1]
	var hud := CombatHud.new()
	scene.add_child(hud)
	hud.setup(frodon_view)
	hud.message_log.set_chat_enabled(true)
	var party_ui := PartyUi.new()
	scene.add_child(party_ui)
	party_ui.setup(frodon_view)
	var friends := FriendsWindow.new()
	scene.add_child(friends)
	friends.setup(frodon_view)
	friends.enabled = true
	var sam: String = sam_view.world.player_name

	# Menu du pseudo : « Ajouter Sam en ami », puis « Retirer ».
	party_ui._on_player_clicked("j:sam", sam)
	assert_true(party_ui._menu.get_item_text(party_ui._menu.get_item_index(3)).begins_with("Ajouter"))
	party_ui._on_menu_pressed(3)
	_run_until_idle(frodon_view)
	assert_true(frodon_view.world.has_relation("amis", sam), "la copie du client connaît la liste")
	party_ui._on_player_clicked("j:sam", sam)
	assert_true(party_ui._menu.get_item_text(party_ui._menu.get_item_index(3)).begins_with("Retirer"))

	# Fenêtre Amis : Sam hors de vue tant qu'il ne compte pas Frodon parmi ses amis.
	friends.open()
	_run_until_idle(frodon_view)
	assert_true(friends.is_open())
	assert_eq(friends.friend_lines(), PackedStringArray(["%s (hors ligne)" % sam]))
	sam_view.send_command({"type": Protocol.CMD_RELATIONS, "entite": "j:sam", "action": Relations.ADD,
		"nom": frodon_view.world.player_name})
	_run_until_idle(sam_view)
	frodon_view.advance(0.1)
	_run_until_idle(frodon_view)
	friends.refresh()
	assert_true(friends.friend_lines()[-1].contains("en ligne"), str(friends.friend_lines()))

	# Ignorer depuis le menu, puis signaler : la fenêtre du motif, puis l'accusé du serveur.
	party_ui._on_player_clicked("j:sam", sam)
	party_ui._on_menu_pressed(4)
	_run_until_idle(frodon_view)
	assert_true(frodon_view.world.has_relation("ignores", sam))
	assert_false(frodon_view.world.has_relation("amis", sam), "ignoré, il n'est plus ami")
	party_ui._on_menu_pressed(5)
	assert_true(party_ui.is_reporting())
	party_ui._report_comment.text = "Il insulte"
	var sent := []
	frodon_view.report_sent.connect(func(event: Dictionary) -> void: sent.append(event))
	party_ui._send_report()
	_run_until_idle(frodon_view)
	assert_eq(sent.size(), 1, "le serveur accuse réception")
	var report: Dictionary = frodon_view.server.take_reports()[0]
	assert_eq(report["cible_nom"], sam)
	assert_eq(report["motif"], Relations.REPORT_REASONS.keys()[0])
	assert_eq(report["commentaire"], "Il insulte")
	scene.queue_free()
