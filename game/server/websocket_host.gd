class_name WebSocketHost
extends RefCounted
## Branche un `GameServer` sur de vrais WebSocket (GDD § 16.5) : écoute un port TCP, accepte les
## clients, leur passe le texte des messages dans les deux sens. En clair (ws://) : le chiffrement
## (wss://) est fait devant, par le tunnel Cloudflare ou Caddy. Appeler `poll` à chaque image.

## Taille maximale d'un message reçu d'un client (les commandes sont petites).
const MAX_INBOUND := 1 << 16
## Réserve d'envoi : un instantané peut peser quelques centaines de Ko.
const MAX_OUTBOUND := 1 << 22

var server: GameServer
var _tcp := TCPServer.new()
## Pair → WebSocketPeer.
var _peers: Dictionary = {}
## Pairs à fermer après l'envoi de leur dernier message.
var _closing: Dictionary = {}
var _next_id := 1


func _init(p_server: GameServer) -> void:
	server = p_server
	server.message_out.connect(_on_message_out)
	server.peer_kicked.connect(func(peer_id: int) -> void: _closing[peer_id] = true)


## Écoute le port ; renvoie le code d'erreur de Godot (OK si tout va bien).
func listen(port: int, bind_address := "*") -> Error:
	return _tcp.listen(port, bind_address)


func stop() -> void:
	for peer: WebSocketPeer in _peers.values():
		peer.close(1001, "Serveur arrêté.")
	_tcp.stop()


## Port réellement écouté (utile avec le port 0 : choisi par le système).
func port() -> int:
	return _tcp.get_local_port()


func peer_count() -> int:
	return _peers.size()


func poll() -> void:
	while _tcp.is_connection_available():
		var peer := WebSocketPeer.new()
		peer.inbound_buffer_size = MAX_INBOUND
		peer.outbound_buffer_size = MAX_OUTBOUND
		if peer.accept_stream(_tcp.take_connection()) != OK:
			continue
		var peer_id := _next_id
		_next_id += 1
		_peers[peer_id] = peer
		server.peer_connected(peer_id)
	for peer_id: int in _peers.keys():
		var peer: WebSocketPeer = _peers[peer_id]
		peer.poll()
		var state := peer.get_ready_state()
		if state == WebSocketPeer.STATE_OPEN:
			if _closing.has(peer_id):
				_closing.erase(peer_id)
				peer.close(1000, "")
				continue
			while peer.get_available_packet_count() > 0 and _peers.has(peer_id):
				var packet := peer.get_packet()
				if peer.was_string_packet():
					server.receive(peer_id, packet.get_string_from_utf8())
		elif state == WebSocketPeer.STATE_CLOSED:
			_peers.erase(peer_id)
			_closing.erase(peer_id)
			server.peer_disconnected(peer_id)


func _on_message_out(peer_id: int, text: String) -> void:
	var peer: WebSocketPeer = _peers.get(peer_id)
	if peer != null and peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
		peer.send_text(text)
