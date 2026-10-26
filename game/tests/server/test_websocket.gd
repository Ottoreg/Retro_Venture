extends "res://tests/test_case.gd"
## Jalon M1 (GDD § 16.5) de bout en bout sur de vrais WebSocket, en local : un `GameServer` derrière
## un `WebSocketHost`, deux clients `RemoteConnection` qui se connectent, créent leur personnage,
## se voient et reçoivent leurs réponses plus tard (connexion asynchrone).

const Fixtures := preload("res://tests/helpers/fixtures.gd")
## Attente maximale d'une étape (s).
const TIMEOUT := 5.0

var _maps := {}
var _host: WebSocketHost
var _url := ""


func before_each() -> void:
	_maps = {"test": Fixtures.map({Fixtures.center(): "1"}, [{"monstres": ["mannequin"]}], {"id": "test"})}
	var server := GameServer.new(Fixtures.data(), _loader, CharacterStore.new(), AccountCheck.new(), [], "test")
	_host = WebSocketHost.new(server)
	_host.listen(0, "127.0.0.1")
	_url = "ws://127.0.0.1:%d" % _host.port()


func _loader(map_id: String) -> GameMap:
	return _maps.get(map_id)


func _client(pseudo: String) -> RemoteConnection:
	return RemoteConnection.new(_url, "dev:%s" % pseudo, Fixtures.data(), _loader)


## Fait tourner serveur et clients jusqu'à ce que `done` soit vrai (ou TIMEOUT).
func _run_until(clients: Array, done: Callable) -> bool:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < TIMEOUT * 1000.0:
		_host.poll()
		for client: RemoteConnection in clients:
			client.poll()
		if done.call():
			return true
		OS.delay_msec(2)
	return false


func _ready_client(pseudo: String, others: Array = []) -> RemoteConnection:
	var client := _client(pseudo)
	var clients := others + [client]
	_run_until(clients, func() -> bool: return client.status in [RemoteConnection.Status.NEEDS_CHARACTER, RemoteConnection.Status.CLOSED])
	client.create_character(pseudo, "testeur", "test")
	_run_until(clients, func() -> bool: return client.status in [RemoteConnection.Status.READY, RemoteConnection.Status.CLOSED])
	return client


func test_deux_clients_se_voient_par_websocket() -> void:
	var frodon := _ready_client("Frodon")
	assert_eq(frodon.status, RemoteConnection.Status.READY, frodon.error_message)
	assert_eq(frodon.state.character.display_name, "Frodon")
	assert_eq(frodon.state.map.id, "test")
	var sam := _ready_client("Sam", [frodon])
	assert_eq(sam.status, RemoteConnection.Status.READY, sam.error_message)
	assert_eq(sam.state.other_players().size(), 1, "Sam voit Frodon")
	assert_true(_run_until([frodon, sam], func() -> bool: return frodon.state.other_players().size() == 1), "Frodon voit arriver Sam")
	assert_eq(_host.peer_count(), 2)

	var target := Fixtures.center() + Vector2i(1, 0)
	var sent := sam.send({"type": Protocol.CMD_MOVE, "entite": sam.state.player_id, "cible": target})
	assert_eq(sent, [] as Array[Dictionary], "asynchrone : rien tout de suite")
	var replies := []
	assert_true(_run_until([frodon, sam], func() -> bool:
		replies.append_array(sam.take_replies())
		return not replies.is_empty()), "la réponse arrive")
	assert_eq(replies[0][0]["type"], Protocol.EVT_MOVED)
	assert_eq(sam.state.position_of(sam.state.player_id), target, "copie rechargée avec la réponse")
	var pushed: Array[Dictionary] = []
	assert_true(_run_until([frodon, sam], func() -> bool:
		pushed.append_array(frodon.update(0.0))
		return not Fixtures.of_type(pushed, Protocol.EVT_MOVED).is_empty()), "Frodon reçoit le déplacement")
	assert_eq(Fixtures.of_type(pushed, Protocol.EVT_PLAYER_JOINED).size(), 1, "après l'arrivée de Sam")
	assert_eq(frodon.state.position_of(sam.state.player_id), target)

	sam.close()
	assert_true(_run_until([frodon], func() -> bool: return frodon.state.other_players().is_empty()), "Frodon voit partir Sam")
	frodon.close()


func test_version_differente_refusee() -> void:
	var peer := WebSocketPeer.new()
	peer.connect_to_url(_url)
	var answer := []
	_run_until([], func() -> bool:
		peer.poll()
		if peer.get_ready_state() == WebSocketPeer.STATE_OPEN and answer.is_empty():
			answer.append("envoyé")
			peer.send_text('{"v": 1, "n": 1, "type": "bonjour", "jeton": "dev:Sam"}')
		while peer.get_available_packet_count() > 0:
			answer.append(Protocol.decode(peer.get_packet().get_string_from_utf8()))
		return answer.size() > 1)
	assert_eq(answer.size(), 2)
	assert_eq(answer[1].get("raison"), Protocol.ERROR_VERSION)
	assert_true(_run_until([], func() -> bool:
		peer.poll()
		return peer.get_ready_state() == WebSocketPeer.STATE_CLOSED), "le serveur ferme la connexion")


## Envoie une commande et attend sa réponse (événements renvoyés) ; les événements reçus sans
## commande s'accumulent dans `pushed`.
func _ask(client: RemoteConnection, clients: Array, command: Dictionary, pushed: Array) -> Array:
	client.send(command)
	var reply := []
	_run_until(clients, func() -> bool:
		pushed.append_array(client.update(0.0))
		var replies := client.take_replies()
		if not replies.is_empty():
			reply = replies[0]
		return not replies.is_empty())
	return reply


func test_combat_de_groupe_et_retour_dans_le_combat() -> void:
	var frodon := _ready_client("Frodon")
	var sam := _ready_client("Sam", [frodon])
	var clients := [frodon, sam]
	var seen := []
	_ask(frodon, clients, {"type": Protocol.CMD_PARTY_INVITE, "entite": "", "joueur": sam.state.player_id}, seen)
	var invitations := []
	_run_until(clients, func() -> bool:
		invitations.append_array(sam.update(0.0).filter(func(e: Dictionary) -> bool: return e["type"] == Protocol.EVT_PARTY_INVITE))
		return not invitations.is_empty())
	assert_eq(invitations.size(), 1, "Sam est invité")
	_ask(sam, clients, {"type": Protocol.CMD_PARTY_ANSWER, "entite": "", "chef": frodon.state.player_id, "accepte": true}, seen)
	assert_true(sam.state.is_party_member(frodon.state.player_id))
	var group_id: String = frodon.state.groups()[0]["id"]
	_ask(frodon, clients, {"type": Protocol.CMD_ENGAGE, "entite": "", "groupe": group_id}, seen)
	assert_true(frodon.state.in_combat())
	_run_until(clients, func() -> bool:
		sam.update(0.0)
		return not sam.state.fights().is_empty())
	assert_eq(sam.state.fights().size(), 1, "Sam voit les épées")
	_ask(sam, clients, {"type": Protocol.CMD_JOIN_COMBAT, "entite": "", "groupe": group_id}, seen)
	assert_true(sam.state.in_combat(), "Sam est dans le combat")
	assert_true(sam.state.combat.get_fighter(frodon.state.player_id) != null, "avec Frodon recréé dans sa copie")
	_run_until(clients, func() -> bool:
		frodon.update(0.0)
		return frodon.state.combat.player_fighters().size() == 2)
	assert_eq(frodon.state.combat.player_fighters().size(), 2, "la copie de Frodon voit Sam arriver")
	# Sam perd la connexion, puis revient : il retrouve son combat.
	sam.close()
	var again := _client("Sam")
	_run_until([frodon, again], func() -> bool: return again.status in [RemoteConnection.Status.READY, RemoteConnection.Status.CLOSED])
	assert_eq(again.status, RemoteConnection.Status.READY, again.error_message)
	assert_true(again.state.in_combat(), "de retour dans le combat")
	frodon.close()
	again.close()
