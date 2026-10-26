extends SceneTree
## Serveur de jeu sans affichage (GDD § 16.5, jalon M1) :
##   godot --headless --path game -s res://server/server_main.gd
## Réglages par variables d'environnement (voir server/README.md et .env.example) :
## - RV_PORT : port WebSocket (8080) ;
## - SUPABASE_URL et SUPABASE_SECRET_KEY : comptes et personnages dans Supabase ; sans elles,
##   serveur de développement (pseudos « dev: » sans mot de passe, personnages dans RV_DATA_DIR) ;
## - RV_TUNNEL_METRICS : adresse des métriques de cloudflared (http://tunnel:2000), pour lire
##   l'adresse publique du tunnel rapide ; ou RV_PUBLIC_ADDRESS (wss://…) si elle est fixe ;
## - RV_POSTE : nom du poste, montré si un autre serveur tourne déjà.
## Avec Supabase, l'adresse publique est écrite dans la table `serveur_actuel`, qui sert aussi de
## garde-fou : le serveur refuse de démarrer si un autre est vivant (marqueur de moins de 90 s).

const HEARTBEAT_SECONDS := 30.0
const TUNNEL_RETRY_SECONDS := 3.0
const FPS := 30

var _server: GameServer
var _host: WebSocketHost
var _supabase: Supabase
var _instance_id := ""
var _poste := ""
var _public_address := ""
var _heartbeat := 0.0
var _tunnel_wait := 0.0
var _running := false


func _initialize() -> void:
	Engine.max_fps = FPS
	_start.call_deferred()  # La racine n'est dans l'arbre qu'après `_initialize` (requêtes HTTP).


func _start() -> void:
	var data := GameData.load_all()
	var load_map := func(map_id: String) -> GameMap: return DataLoader.load_map(DataLoader.map_path(map_id))
	var supabase_url := OS.get_environment("SUPABASE_URL")
	var secret := OS.get_environment("SUPABASE_SECRET_KEY")
	_poste = OS.get_environment("RV_POSTE")
	if _poste.is_empty():
		_poste = OS.get_environment("HOSTNAME")
	_instance_id = "%s-%d" % [_poste, Time.get_unix_time_from_system()]
	var store: CharacterStore
	var accounts: AccountCheck
	if not supabase_url.is_empty() and not secret.is_empty():
		_supabase = Supabase.new(supabase_url, secret, root)
		var other := await _live_server()
		if not other.is_empty() and str(other.get("instance", "")) != _instance_id:
			printerr("Un autre serveur tourne déjà (poste « %s ») : arrêtez-le d'abord, ou attendez 90 s après son arrêt." % other.get("poste", "?"))
			quit(1)
			return
		store = SupabaseStore.new(_supabase)
		accounts = SupabaseAccounts.new(_supabase)
		print("Comptes et personnages : Supabase (%s)" % supabase_url)
	else:
		var directory := OS.get_environment("RV_DATA_DIR")
		store = CharacterStore.new(directory if not directory.is_empty() else "user://serveur")
		accounts = AccountCheck.new()
		print("Serveur de développement : pseudos « dev: », personnages dans %s" % store.directory)
	_server = GameServer.new(data, load_map, store, accounts, DataLoader.map_ids())
	_host = WebSocketHost.new(_server)
	var port := int(OS.get_environment("RV_PORT")) if not OS.get_environment("RV_PORT").is_empty() else 8080
	var error := _host.listen(port)
	if error != OK:
		printerr("Impossible d'écouter le port %d (erreur %d)." % [port, error])
		quit(1)
		return
	_public_address = OS.get_environment("RV_PUBLIC_ADDRESS")
	print("Serveur Retro Venture (protocole %d) à l'écoute sur le port %d." % [Protocol.VERSION, port])
	_running = true
	if _supabase != null:
		_publish()


func _process(delta: float) -> bool:
	if not _running:
		return false
	_host.poll()
	_server.update(delta)
	if _supabase == null:
		return false
	if _public_address.is_empty():
		_tunnel_wait -= delta
		if _tunnel_wait <= 0.0:
			_tunnel_wait = TUNNEL_RETRY_SECONDS
			_find_tunnel_address()
	_heartbeat -= delta
	if _heartbeat <= 0.0:
		_publish()
	return false


func _finalize() -> void:
	if _host != null:
		_host.stop()


## Le serveur vivant d'après Supabase ({ instance, poste, adresse }), ou {}.
func _live_server() -> Dictionary:
	var answer: Dictionary = await _supabase.request(HTTPClient.METHOD_GET,
		"/rest/v1/%s?select=instance,poste,adresse" % Supabase.LIVE_SERVER_VIEW)
	if answer["code"] == 200 and typeof(answer["data"]) == TYPE_ARRAY and not answer["data"].is_empty():
		return answer["data"][0]
	return {}


## Rafraîchit le marqueur « serveur actuel » (et l'adresse publique, une fois connue).
func _publish() -> void:
	_heartbeat = HEARTBEAT_SECONDS
	var row := {"id": 1, "instance": _instance_id, "poste": _poste, "adresse": _public_address,
		"vu": Time.get_datetime_string_from_system(true) + "Z"}
	var answer: Dictionary = await _supabase.request(HTTPClient.METHOD_POST, "/rest/v1/serveur_actuel?on_conflict=id", row,
		["Prefer: resolution=merge-duplicates,return=minimal"])
	if answer["code"] not in [200, 201, 204]:
		printerr("Marqueur « serveur actuel » pas écrit (code %d)." % answer["code"])


## Adresse du tunnel rapide de Cloudflare, lue dans les métriques de cloudflared.
func _find_tunnel_address() -> void:
	var metrics := OS.get_environment("RV_TUNNEL_METRICS")
	if metrics.is_empty():
		return
	var http := HTTPRequest.new()
	http.timeout = 5.0
	root.add_child(http)
	if http.request(metrics.trim_suffix("/") + "/quicktunnel") != OK:
		http.queue_free()
		return
	var result: Array = await http.request_completed
	http.queue_free()
	var json := JSON.new()  # Sans message d'erreur tant que le tunnel n'est pas prêt (réponse vide).
	var parsed: Variant = json.data if json.parse((result[3] as PackedByteArray).get_string_from_utf8()) == OK else null
	if typeof(parsed) == TYPE_DICTIONARY and not str(parsed.get("hostname", "")).is_empty() and _public_address.is_empty():
		_public_address = "wss://%s" % parsed["hostname"]
		print("Adresse publique : %s" % _public_address)
		_publish()
