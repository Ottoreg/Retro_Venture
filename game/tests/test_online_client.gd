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
	sam_view.send_command({"type": Protocol.CMD_PARTY_ANSWER, "entite": "j:sam", "chef": world.player_id, "accepte": true})
	_run_until_idle(sam_view)
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
