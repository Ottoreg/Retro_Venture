class_name RemoteConnection
extends GameConnection
## Connexion distante (GDD § 16.5, jalon M1) : un WebSocket vers le serveur de jeu, qui fait
## autorité. Les commandes partent en JSON (`Protocol.MSG_COMMAND`) ; chaque réponse arrive plus tard
## avec ses événements et l'instantané qui suit (`take_replies`), et les événements des autres
## joueurs et du temps qui passe arrivent par `update`. Tout passe par `poll`, appelé à chaque image.

enum Status {
	## Ouverture du WebSocket.
	CONNECTING,
	## Jeton envoyé (`Protocol.MSG_HELLO`), on attend la réponse du serveur.
	AUTHENTICATING,
	## Compte sans personnage : envoyer `create_character`.
	NEEDS_CHARACTER,
	## Personnage chargé, copie de l'état prête : on peut jouer.
	READY,
	## Connexion fermée (voir `error_message`).
	CLOSED,
}

var status := Status.CONNECTING
## Raison de la fermeture, à montrer au joueur ("" tant que tout va bien).
var error_message := ""
## Compte du joueur, donné par le serveur.
var account := ""
var _socket := WebSocketPeer.new()
var _token := ""
var _number := 0
## Réponses reçues, pas encore prises (une liste d'événements par commande).
var _replies: Array = []
## Événements reçus sans commande, pas encore pris.
var _pushed: Array[Dictionary] = []


## `url` : adresse du serveur (ws:// ou wss://) ; `token` : jeton du compte (voir `Protocol.MSG_HELLO`).
func _init(url: String, token: String, data: GameData, map_loader: Callable, map_ids: Array[String] = []) -> void:
	asynchronous = true
	_token = token
	state = ClientState.new(data, map_loader)
	state.map_ids = map_ids
	_socket.inbound_buffer_size = 1 << 22  # Un instantané peut peser quelques centaines de Ko.
	var error := _socket.connect_to_url(url)
	if error != OK:
		_close("Adresse du serveur invalide : %s" % url)


func send(command: Dictionary) -> Array[Dictionary]:
	_write({"type": Protocol.MSG_COMMAND, "commande": command})
	return [] as Array[Dictionary]


## Crée le personnage du compte (statut NEEDS_CHARACTER) ; l'instantané suit.
func create_character(character_name: String, race: String, voie: String) -> void:
	_write({"type": Protocol.MSG_CREATE, "nom": character_name, "race": race, "voie": voie})
	status = Status.AUTHENTICATING


func take_replies() -> Array:
	poll()
	var replies := _replies
	_replies = []
	return replies


func update(delta: float) -> Array[Dictionary]:
	state.advance(delta)
	poll()
	var events := _pushed
	_pushed = []
	return events


func is_open() -> bool:
	return status != Status.CLOSED


func close() -> void:
	_socket.close()
	status = Status.CLOSED


## Lit tout ce qui est arrivé.
func poll() -> void:
	if status == Status.CLOSED:
		return
	_socket.poll()
	match _socket.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if status == Status.CONNECTING:
				status = Status.AUTHENTICATING
				_write({"type": Protocol.MSG_HELLO, "jeton": _token})
			while _socket.get_available_packet_count() > 0:
				_receive(_socket.get_packet().get_string_from_utf8())
				if status == Status.CLOSED:
					return
		WebSocketPeer.STATE_CLOSED:
			var reason := _socket.get_close_reason()
			_close("Connexion au serveur perdue." if reason.is_empty() else reason)


func _receive(text: String) -> void:
	var header := {}
	var message := Protocol.decode(text, header)
	if message.is_empty():
		if header.get("v") != null and int(header["v"]) != Protocol.VERSION:
			_close("Le serveur n'a pas la même version du jeu : mettez le jeu à jour (rechargez la page).")
		return
	match message["type"]:
		Protocol.MSG_WELCOME:
			account = str(message.get("compte", ""))
			status = Status.AUTHENTICATING if message.get("personnage", false) else Status.NEEDS_CHARACTER
		Protocol.EVT_SNAPSHOT:
			state.load_snapshot(message)
			status = Status.READY
		Protocol.MSG_REPLY:
			var events := _events_of(message)
			for event in events:
				state.apply_event(event)
			state.load_snapshot(message["instantane"])
			_replies.append(events)
		Protocol.MSG_EVENTS:
			var stale := false
			for event in _events_of(message):
				stale = not state.apply_event(event) or stale
				_pushed.append(event)
			if stale:
				_write({"type": Protocol.MSG_SNAPSHOT_REQUEST})
		Protocol.MSG_ERROR:
			_close(str(message.get("message", "Le serveur a refusé la connexion.")))


static func _events_of(message: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for event: Variant in message.get("evenements", []):
		if typeof(event) == TYPE_DICTIONARY and event.has("type"):
			events.append(event)
	return events


func _write(message: Dictionary) -> void:
	if _socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	_number += 1
	_socket.send_text(Protocol.encode(message, _number))


func _close(message: String) -> void:
	if status != Status.CLOSED:
		error_message = message
	status = Status.CLOSED
	_socket.close()
