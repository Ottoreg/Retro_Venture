extends SceneTree
## Joueur automatique pour essayer le multijoueur seul (GDD § 16.5, jalon M1) : il se connecte à un
## serveur de développement, crée son personnage au besoin, puis marche au hasard sur sa carte. Il
## répond aux messages privés (jalon M3), pour essayer le chat seul. Il accepte les échanges (jalon
## M4) sans rien proposer, et valide dès que l'autre a validé : un don, pour essayer l'échange seul.
##   godot --headless --path game -s res://tools/bot.gd -- [adresse] [pseudo] [secondes]
## Par défaut : ws://localhost:8080, « Robotin », sans limite de durée.

const STEP_SECONDS := 3.0

var _connection: RemoteConnection
var _left := -1.0
var _step := 0.0
var _rng := RandomNumberGenerator.new()
## Échange en cours (dernier EVT_EXCHANGE), {} sans ; secondes avant de valider (-1 : rien à faire).
var _exchange := {}
var _validate_in := -1.0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var url := args[0] if args.size() > 0 else "ws://localhost:8080"
	var pseudo := args[1] if args.size() > 1 else "Robotin"
	_left = float(args[2]) if args.size() > 2 else -1.0
	_rng.randomize()
	_connection = RemoteConnection.new(url, AccountCheck.DEV_PREFIX + pseudo, GameData.load_all(),
		func(map_id: String) -> GameMap: return DataLoader.load_map(DataLoader.map_path(map_id)), DataLoader.map_ids())
	print("Connexion de %s à %s…" % [pseudo, url])


func _process(delta: float) -> bool:
	if _left >= 0.0:
		_left -= delta
		if _left < 0.0:
			_connection.close()
			return true
	var events := _connection.update(delta)
	for reply: Array in _connection.take_replies():
		for event: Dictionary in reply:
			events.append(event)  # Réponses à ses commandes : ses propres échanges (accepté, validé).
	for event in events:
		_answer(event)
	match _connection.status:
		RemoteConnection.Status.CLOSED:
			printerr("Connexion fermée : %s" % _connection.error_message)
			return true
		RemoteConnection.Status.NEEDS_CHARACTER:
			var pseudo := _connection.account.trim_prefix(AccountCheck.DEV_PREFIX).capitalize()
			_connection.create_character(pseudo, "humain", "guerrier")
		RemoteConnection.Status.READY:
			if not _exchange.is_empty():
				_validate_in -= delta
				if _validate_in < 0.0 and _validate_in > -1.0:
					_exchange_command(Exchange.VALIDATE)
					_validate_in = -1.0
				return false  # Pas de promenade pendant un échange.
			_step -= delta
			if _step <= 0.0:
				_step = STEP_SECONDS
				_walk()
	return false


## Quelques cases au hasard autour de lui.
func _walk() -> void:
	var state := _connection.state
	var here := state.position_of(state.player_id)
	for attempt in 20:
		var target := here + Vector2i(_rng.randi_range(-3, 3), _rng.randi_range(-3, 3))
		if target != here and state.map.is_walkable(target) and state.map.exit_directions(target).is_empty() \
				and not state.map.doors.has(target) and state.group_at(target).is_empty():
			_connection.send({"type": Protocol.CMD_MOVE, "entite": state.player_id, "cible": target})
			print("%s marche vers %s (%s)" % [state.player_name, target, state.map.display_name])
			return


## Répond à un message privé d'un joueur, et aux échanges.
func _answer(event: Dictionary) -> void:
	match event["type"]:
		Protocol.EVT_EXCHANGE_REQUEST:
			print("%s me propose un échange : j'accepte." % event["nom"])
			_exchange_command(Exchange.ACCEPT, {"joueur": event["de"]})
		Protocol.EVT_EXCHANGE:
			_exchange = event
			_validate_in = float(event["attente"]) + 0.3 if event["valide_lui"] and not event["valide_moi"] else -1.0
		Protocol.EVT_EXCHANGE_CLOSED:
			print("Échange avec %s : %s." % [event["nom"], event["raison"]])
			_exchange = {}
	if event["type"] != Protocol.EVT_CHAT or event["canal"] != Chat.PRIVATE or event["de"] == _connection.state.player_id:
		return
	print("%s me dit : %s" % [event["auteur"], event["texte"]])
	_connection.send({"type": Protocol.CMD_CHAT, "entite": _connection.state.player_id, "canal": Chat.PRIVATE,
		"a": event["auteur"], "texte": "Bip boup, %s ! « %s », bien reçu. Je ne suis qu'un robot." % [event["auteur"], event["texte"]]})


func _exchange_command(action: String, extra := {}) -> void:
	var command := {"type": Protocol.CMD_EXCHANGE, "entite": _connection.state.player_id, "action": action}
	command.merge(extra)
	_connection.send(command)
