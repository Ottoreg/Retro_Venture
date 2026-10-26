class_name GameServer
extends RefCounted
## Serveur de jeu (GDD § 16.5, jalon M1), sans réseau : il reçoit le texte des messages de chaque
## client (`receive`), fait tourner le `World` partagé, qui fait autorité, et dit quoi envoyer à qui
## (`message_out`). `WebSocketHost` le branche sur les vrais WebSocket ; les tests l'appellent
## directement. Un client = un pair (`peer_id`) = au plus un compte et son personnage.

## Texte à envoyer au pair.
signal message_out(peer_id: int, text: String)
## Le pair est renvoyé (après un MSG_ERROR) : fermer sa connexion.
signal peer_kicked(peer_id: int)

## Sauvegarde de tous les personnages connectés, en secondes (en plus des fins de combat, des
## changements de carte et des déconnexions).
const SAVE_INTERVAL := 60.0
## Messages par seconde permis à un client (et réserve pour un court rafale).
const MESSAGE_RATE := 15.0
const MESSAGE_BURST := 40.0
## Durée d'un tour de joueur en combat (GDD § 7.2 : 30 s en multi).
const TURN_SECONDS := 30.0
## Carte de départ quand la race n'en donne pas.
const DEFAULT_START_MAP := "brumerive_0_0"

var world: World
var data: GameData
var store: CharacterStore
var accounts: AccountCheck
## Pair → { compte, joueur (id du personnage, "" avant son chargement), credit (messages permis),
## occupe (vérification du jeton ou chargement en cours) }.
var _sessions: Dictionary = {}
## Id de personnage → pair.
var _peer_of: Dictionary = {}
var _map_loader: Callable
## Carte de départ par défaut (race sans carte de départ, carte sauvegardée introuvable).
var _default_map := DEFAULT_START_MAP
var _save_time := 0.0
var _number := 0


func _init(p_data: GameData, p_map_loader: Callable, p_store: CharacterStore, p_accounts: AccountCheck,
		map_ids: Array[String] = [], default_map := DEFAULT_START_MAP) -> void:
	data = p_data
	_map_loader = p_map_loader
	store = p_store
	accounts = p_accounts
	_default_map = default_map
	world = World.for_server(p_map_loader.call(default_map), data, p_map_loader)
	world.map_ids = map_ids
	world.turn_seconds = TURN_SECONDS


func peer_connected(peer_id: int) -> void:
	_sessions[peer_id] = {"compte": "", "joueur": "", "credit": MESSAGE_BURST, "occupe": false}


## Le pair est parti (ou renvoyé) : son personnage est sauvegardé et quitte le monde, sauf en plein
## combat avec d'autres joueurs : il y reste absent jusqu'à la fin (ou son retour, voir `_hello`).
func peer_disconnected(peer_id: int) -> void:
	var session: Dictionary = _sessions.get(peer_id, {})
	_sessions.erase(peer_id)
	var player_id: String = session.get("joueur", "")
	if player_id.is_empty() or _peer_of.get(player_id) != peer_id:
		return
	_peer_of.erase(player_id)
	await _save(player_id)
	if world.player(player_id) != null:
		_route(world.disconnect_player(player_id), "")
	await _release_departed()


## Les joueurs absents dont le combat est fini sont sauvegardés (avec ce qu'ils y ont gagné) puis
## quittent le monde.
func _release_departed() -> void:
	for player_id in world.take_departed():
		if _peer_of.has(player_id) or world.player(player_id) == null:
			continue
		await _save(player_id)
		if not _peer_of.has(player_id) and world.is_away(player_id):  # Pas revenu pendant la sauvegarde.
			_route(world.remove_player(player_id), "")


## Nombre de joueurs en jeu.
func player_count() -> int:
	return _peer_of.size()


func receive(peer_id: int, text: String) -> void:
	var session: Dictionary = _sessions.get(peer_id, {})
	if session.is_empty():
		return
	if session["credit"] < 1.0:
		_kick(peer_id, Protocol.ERROR_RATE, "Trop de messages : connexion fermée.")
		return
	session["credit"] -= 1.0
	var header := {}
	var message := Protocol.decode(text, header)
	if message.is_empty():
		if typeof(header.get("v")) in [TYPE_INT, TYPE_FLOAT] and int(header["v"]) != Protocol.VERSION:
			_kick(peer_id, Protocol.ERROR_VERSION, "Votre version du jeu n'est plus à jour : rechargez la page (ou retéléchargez le jeu).")
		else:
			_kick(peer_id, Protocol.ERROR_INVALID, "Message illisible.")
		return
	if session["occupe"]:
		return  # Pas de message pendant la vérification du jeton ou un chargement.
	match message["type"]:
		Protocol.MSG_HELLO:
			if session["compte"].is_empty():
				await _hello(peer_id, message)
		Protocol.MSG_CREATE:
			if not session["compte"].is_empty() and session["joueur"].is_empty():
				await _create(peer_id, message)
		Protocol.MSG_COMMAND:
			_command(peer_id, message)
		Protocol.MSG_SNAPSHOT_REQUEST:
			if not session["joueur"].is_empty():
				_write(peer_id, world.snapshot(session["joueur"]))
		_:
			_kick(peer_id, Protocol.ERROR_INVALID, "Message inconnu.")


## Fait passer le temps du monde et envoie ce qui en découle ; sauvegarde régulière.
func update(delta: float) -> void:
	for session: Dictionary in _sessions.values():
		session["credit"] = minf(MESSAGE_BURST, session["credit"] + MESSAGE_RATE * delta)
	_route(world.update(delta), "")
	await _release_departed()
	_save_time += delta
	if _save_time >= SAVE_INTERVAL:
		_save_time = 0.0
		await save_all()


## Sauvegarde tous les personnages connectés (aussi à l'arrêt du serveur).
func save_all() -> void:
	for player_id: String in _peer_of.keys():
		await _save(player_id)


func _hello(peer_id: int, message: Dictionary) -> void:
	var session: Dictionary = _sessions[peer_id]
	session["occupe"] = true
	var account: String = await accounts.account_of(str(message.get("jeton", "")))
	if not _sessions.has(peer_id):
		return  # Parti entre-temps.
	if account.is_empty():
		session["occupe"] = false
		_kick(peer_id, Protocol.ERROR_AUTH, "Connexion refusée : reconnectez-vous.")
		return
	# Le même compte déjà connecté (onglet oublié, connexion coupée) : l'ancienne session part.
	for other_id: int in _sessions.keys():
		if other_id != peer_id and _sessions[other_id]["compte"] == account:
			_kick(other_id, Protocol.ERROR_ALREADY_CONNECTED, "Ce compte vient de se connecter ailleurs.")
			await peer_disconnected(other_id)
	var player_id := "j:%s" % account
	if world.is_away(player_id) and not _peer_of.has(player_id):
		# Revenu pendant son combat de groupe : il le retrouve (le personnage est encore dans le monde).
		session["compte"] = account
		session["occupe"] = false
		session["joueur"] = player_id
		_peer_of[player_id] = peer_id
		_write(peer_id, {"type": Protocol.MSG_WELCOME, "compte": account, "personnage": true})
		_route(world.reconnect(player_id), "")
		_write(peer_id, world.snapshot(player_id))
		return
	var saved: Dictionary = await store.load_character(account)
	if not _sessions.has(peer_id):
		return
	session["compte"] = account
	session["occupe"] = false
	_write(peer_id, {"type": Protocol.MSG_WELCOME, "compte": account, "personnage": not saved.is_empty()})
	if not saved.is_empty():
		_enter(peer_id, _restored_character(saved), saved)


func _create(peer_id: int, message: Dictionary) -> void:
	var session: Dictionary = _sessions[peer_id]
	var pseudo := str(message.get("nom", "")).strip_edges()
	var race := str(message.get("race", ""))
	var voie := str(message.get("voie", ""))
	var error := Character.name_error(pseudo)
	if error.is_empty() and (not data.races.has(race) or not data.voies.has(voie)):
		error = "Race ou Voie inconnue."
	if not error.is_empty():
		_kick(peer_id, Protocol.ERROR_INVALID, error)
		return
	session["occupe"] = true
	var taken: bool = await store.name_taken(pseudo, session["compte"])
	if not _sessions.has(peer_id):
		return
	session["occupe"] = false
	if taken:
		_kick(peer_id, Protocol.ERROR_NAME_TAKEN, "Le pseudo « %s » est déjà pris." % pseudo)
		return
	var character := Character.create(pseudo, race, voie)
	data.give_starting_kit(character)
	var start := str(data.races.get(race, {}).get("carte_depart", _default_map))
	_enter(peer_id, character, {"carte": start})
	await _save(session["joueur"])


## Personnage d'un état sauvegardé (`World.player_save`).
func _restored_character(saved: Dictionary) -> Character:
	var character: Variant = null
	if typeof(saved.get("personnage")) == TYPE_DICTIONARY:
		character = Character.from_dict(saved["personnage"], data.items)
	return character


## Met le personnage du pair dans le monde, sur sa carte et sa case sauvegardées (ou au départ de
## la carte), et lui envoie son instantané ; les autres joueurs de la carte l'apprennent.
func _enter(peer_id: int, character: Character, saved: Dictionary) -> void:
	var session: Dictionary = _sessions[peer_id]
	if character == null:
		_kick(peer_id, Protocol.ERROR_SERVER, "Personnage illisible : prévenez l'auteur du jeu.")
		return
	var player_id := "j:%s" % session["compte"]
	var map_id := str(saved.get("carte", _default_map))
	if _map_loader.call(map_id) == null:
		map_id = _default_map
	var cell := GameMap.NO_CELL
	var position: Variant = saved.get("position")
	if typeof(position) == TYPE_ARRAY and position.size() == 2:
		cell = Vector2i(int(position[0]), int(position[1]))
	var p := world.add_player(character, player_id, map_id, cell)
	if p == null:
		_kick(peer_id, Protocol.ERROR_SERVER, "Impossible d'entrer dans le monde.")
		return
	session["joueur"] = player_id
	_peer_of[player_id] = peer_id
	_write(peer_id, world.snapshot(player_id))
	var joined := {"type": Protocol.EVT_PLAYER_JOINED, "carte": p.map.id, "joueur": world.player_view(p)}
	for other_id in p.instance.player_ids():
		if other_id != player_id and _peer_of.has(other_id):
			_write(_peer_of[other_id], {"type": Protocol.MSG_EVENTS, "evenements": [joined]})


func _command(peer_id: int, message: Dictionary) -> void:
	var player_id: String = _sessions[peer_id]["joueur"]
	var command: Variant = message.get("commande")
	if player_id.is_empty() or typeof(command) != TYPE_DICTIONARY:
		_kick(peer_id, Protocol.ERROR_INVALID, "Commande invalide.")
		return
	command["entite"] = player_id  # Jamais celle du client : celle de sa session.
	var events := world.execute(command)
	_route(events, player_id)
	# Sauvegarde de chaque joueur dont le combat finit (ceux du groupe aussi) ou qui change de carte.
	var saved := {}
	for event in events:
		if event["type"] in [Protocol.EVT_COMBAT_ENDED, Protocol.EVT_MAP_CHANGED]:
			var owner := str(event.get(Protocol.FIELD_FOR, player_id))
			if not saved.has(owner) and _peer_of.has(owner):
				saved[owner] = true
				_save(owner)
	_release_departed()


## Envoie à chacun les événements qui le regardent (`World.recipients`) : à l'auteur de la commande
## (`sender`), sa réponse avec son instantané ; aux autres, un MSG_EVENTS.
func _route(events: Array[Dictionary], sender: String) -> void:
	var per_player := {}
	for event in events:
		for player_id in world.recipients(event, sender):
			if not per_player.has(player_id):
				per_player[player_id] = []
			per_player[player_id].append(event)
	for player_id: String in per_player:
		if player_id != sender and _peer_of.has(player_id):
			var message := {"type": Protocol.MSG_EVENTS, "evenements": per_player[player_id]}
			for event: Dictionary in per_player[player_id]:
				if Protocol.needs_snapshot(event):
					message["instantane"] = world.snapshot(player_id)  # La copie du client ne saurait pas les appliquer.
					break
			_write(_peer_of[player_id], message)
	if not sender.is_empty() and _peer_of.has(sender):
		_write(_peer_of[sender], {"type": Protocol.MSG_REPLY, "evenements": per_player.get(sender, []),
			"instantane": world.snapshot(sender)})


func _save(player_id: String) -> void:
	var state := world.player_save(player_id)
	var account := player_id.trim_prefix("j:")
	if state.is_empty():
		return
	var ok: bool = await store.save_character(account, str(state["personnage"].get("nom", "")), state)
	if not ok:
		push_error("Sauvegarde impossible du personnage de %s" % account)


func _write(peer_id: int, message: Dictionary) -> void:
	_number += 1
	message_out.emit(peer_id, Protocol.encode(message, _number))


func _kick(peer_id: int, reason: String, text: String) -> void:
	_write(peer_id, {"type": Protocol.MSG_ERROR, "raison": reason, "message": text})
	peer_kicked.emit(peer_id)
