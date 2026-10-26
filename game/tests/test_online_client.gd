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
	assert_eq(view._describe(cell), "Sam\nNiveau 1, Gobelin Rôdeur", "son nom au survol")
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
	connection.close()
	Session.online_connection = null
	screen.queue_free()


func test_adresse_supabase_sans_chemin_de_l_api() -> void:
	var host := Node.new()
	assert_eq(Supabase.new("https://abc.supabase.co/rest/v1/", "cle", host).url, "https://abc.supabase.co")
	assert_eq(Supabase.new("https://abc.supabase.co/", "cle", host).url, "https://abc.supabase.co")
	host.free()
