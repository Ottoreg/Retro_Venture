extends "res://tests/test_case.gd"
## Serveur de jeu du jalon M1 (GDD § 16.5), sans réseau : les messages JSON de deux clients passent
## par `GameServer.receive`, ses réponses par le signal `message_out`. Comptes de développement
## (« dev:Pseudo ») et personnages en mémoire.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _maps := {}
var _server: GameServer
var _store: CharacterStore
## Pair → messages reçus du serveur (relus).
var _inbox := {}
var _kicked: Array[int] = []


func before_each() -> void:
	_maps = {
		"test": Fixtures.map({Fixtures.center(): "1"}, [{"monstres": ["mannequin"]}], {"id": "test", "sorties": {"droite": "b"}}),
		"b": Fixtures.map({}, [], {"id": "b", "sorties": {"gauche": "test"}}),
	}
	_store = CharacterStore.new()
	_server = GameServer.new(Fixtures.data(), _loader, _store, AccountCheck.new(), [], "test")
	_server.message_out.connect(func(peer_id: int, text: String) -> void:
		if not _inbox.has(peer_id):
			_inbox[peer_id] = []
		_inbox[peer_id].append(Protocol.decode(text)))
	_server.peer_kicked.connect(func(peer_id: int) -> void: _kicked.append(peer_id))


func _loader(map_id: String) -> GameMap:
	return _maps.get(map_id)


func _send(peer_id: int, message: Dictionary) -> void:
	_server.receive(peer_id, Protocol.encode(message, 1))


## Messages reçus par le pair depuis le dernier appel.
func _take(peer_id: int) -> Array:
	var messages: Array = _inbox.get(peer_id, [])
	_inbox[peer_id] = []
	return messages


func _of_type(messages: Array, type: String) -> Array:
	return messages.filter(func(message: Dictionary) -> bool: return message["type"] == type)


## Événements de type `type` dans les MSG_EVENTS reçus.
func _pushed(messages: Array, type: String) -> Array:
	var found := []
	for message: Dictionary in _of_type(messages, Protocol.MSG_EVENTS):
		for event: Dictionary in message["evenements"]:
			if event["type"] == type:
				found.append(event)
	return found


## Connecte un client et crée son personnage (s'il n'en a pas) ; renvoie son id de personnage.
func _join(peer_id: int, pseudo: String) -> String:
	_server.peer_connected(peer_id)
	_send(peer_id, {"type": Protocol.MSG_HELLO, "jeton": "dev:%s" % pseudo})
	var welcome: Array = _of_type(_inbox.get(peer_id, []), Protocol.MSG_WELCOME)
	if not welcome.is_empty() and not welcome[0]["personnage"]:
		_send(peer_id, {"type": Protocol.MSG_CREATE, "nom": pseudo, "race": "testeur", "voie": "test"})
	return "j:dev:%s" % pseudo.to_lower()


func _command(peer_id: int, command: Dictionary) -> Dictionary:
	_send(peer_id, {"type": Protocol.MSG_COMMAND, "commande": command})
	var replies := _of_type(_take(peer_id), Protocol.MSG_REPLY)
	return replies[-1] if not replies.is_empty() else {}


func test_connexion_et_creation_du_personnage() -> void:
	_server.peer_connected(1)
	_send(1, {"type": Protocol.MSG_HELLO, "jeton": "dev:Frodon"})
	var messages := _take(1)
	assert_eq(messages.size(), 1)
	assert_eq(messages[0]["type"], Protocol.MSG_WELCOME)
	assert_false(messages[0]["personnage"], "nouveau compte : pas encore de personnage")
	_send(1, {"type": Protocol.MSG_CREATE, "nom": "Frodon", "race": "testeur", "voie": "test"})
	messages = _take(1)
	assert_eq(messages[0]["type"], Protocol.EVT_SNAPSHOT)
	assert_eq(messages[0]["personnage"]["nom"], "Frodon")
	assert_eq(messages[0]["carte"], "test", "carte de départ de la race")
	assert_false(_store.load_character("dev:frodon").is_empty(), "sauvegardé dès sa création")
	assert_eq(_server.player_count(), 1)


func test_refus_a_la_connexion() -> void:
	_server.peer_connected(1)
	_send(1, {"type": Protocol.MSG_HELLO, "jeton": "n'importe quoi"})
	assert_eq(_take(1)[0]["raison"], Protocol.ERROR_AUTH)
	assert_eq(_kicked, [1] as Array[int])
	_server.peer_connected(2)
	_server.receive(2, '{"v": 1, "n": 1, "type": "bonjour", "jeton": "dev:Sam"}')
	assert_eq(_take(2)[0]["raison"], Protocol.ERROR_VERSION, "ancienne version du protocole")
	_server.peer_connected(3)
	_send(3, {"type": Protocol.MSG_HELLO, "jeton": "dev:Sam"})
	_send(3, {"type": Protocol.MSG_CREATE, "nom": "S4m!", "race": "testeur", "voie": "test"})
	assert_eq(_of_type(_take(3), Protocol.MSG_ERROR)[0]["raison"], Protocol.ERROR_INVALID, "pseudo invalide")
	_join(4, "Merry")
	_server.peer_connected(5)
	_send(5, {"type": Protocol.MSG_HELLO, "jeton": "dev:Pippin"})
	_send(5, {"type": Protocol.MSG_CREATE, "nom": "merry", "race": "testeur", "voie": "test"})
	assert_eq(_of_type(_take(5), Protocol.MSG_ERROR)[0]["raison"], Protocol.ERROR_NAME_TAKEN, "pseudo unique, majuscules comprises")


func test_trop_de_messages() -> void:
	_join(1, "Frodon")
	for i in int(GameServer.MESSAGE_BURST) + 1:
		_send(1, {"type": Protocol.MSG_SNAPSHOT_REQUEST})
	assert_eq(_of_type(_take(1), Protocol.MSG_ERROR)[0]["raison"], Protocol.ERROR_RATE)
	assert_true(1 in _kicked)


func test_deux_joueurs_se_voient() -> void:
	var frodon := _join(1, "Frodon")
	_take(1)
	var sam := _join(2, "Sam")
	var arrived := _pushed(_take(1), Protocol.EVT_PLAYER_JOINED)
	assert_eq(arrived.size(), 1, "Frodon voit arriver Sam")
	assert_eq(arrived[0]["joueur"]["id"], sam)
	assert_eq(arrived[0]["joueur"]["nom"], "Sam")
	var snapshot: Dictionary = _of_type(_take(2), Protocol.EVT_SNAPSHOT)[0]
	assert_eq(snapshot["joueurs"].size(), 1, "Sam voit Frodon déjà là")
	assert_eq(snapshot["joueurs"][0]["id"], frodon)


func test_deplacement_vu_par_l_autre_et_entite_imposee() -> void:
	var frodon := _join(1, "Frodon")
	var sam := _join(2, "Sam")
	_take(1)
	_take(2)
	var target := Fixtures.center() + Vector2i(1, 0)
	# Sam prétend déplacer Frodon : le serveur remplace `entite` par celui de sa session.
	var reply := _command(2, {"type": Protocol.CMD_MOVE, "entite": frodon, "cible": target})
	assert_eq(reply["evenements"][0]["type"], Protocol.EVT_MOVED)
	assert_eq(reply["evenements"][0]["entite"], sam)
	assert_eq(reply["instantane"]["position"], target, "la réponse porte l'instantané")
	assert_eq(_server.world.player(frodon).cell, _maps["test"].spawn, "Frodon n'a pas bougé")
	var seen := _pushed(_take(1), Protocol.EVT_MOVED)
	assert_eq(seen.size(), 1, "Frodon voit Sam marcher")
	assert_eq(seen[0]["entite"], sam)


## Frodon gagne son combat contre le groupe de la carte (mannequin à 1 PV).
func _win(peer_id: int, player_id: String) -> Dictionary:
	if not _server.world.player(player_id).in_combat():
		_command(peer_id, {"type": Protocol.CMD_ENGAGE, "groupe": "groupe_1"})
	var combat: Combat = _server.world.player(player_id).combat
	var monster: Fighter = combat.get_fighter("groupe_1_1")
	var player: Fighter = combat.get_fighter(player_id)
	for neighbor in IsoGrid.neighbors_4(monster.cell):
		if combat.is_free(neighbor):
			player.cell = neighbor
			break
	monster.hp = 1
	_command(peer_id, {"type": Protocol.CMD_READY})
	return _command(peer_id, {"type": Protocol.CMD_CAST, "sort": "frappe", "cible": monster.cell})


func test_combat_calcule_par_le_serveur_et_sauvegarde() -> void:
	var frodon := _join(1, "Frodon")
	_join(2, "Sam")
	_take(1)
	_take(2)
	_command(1, {"type": Protocol.CMD_ENGAGE, "groupe": "groupe_1"})
	var engaged := _pushed(_take(2), Protocol.EVT_GROUP_ENGAGED)
	assert_eq(engaged.size(), 1, "le groupe attaqué disparaît pour Sam")
	assert_eq(engaged[0]["groupe"], "groupe_1")
	var sam_reply := _command(2, {"type": Protocol.CMD_ENGAGE, "groupe": "groupe_1"})
	assert_eq(sam_reply["evenements"][0]["raison"], Protocol.REASON_GROUP_IN_COMBAT)
	assert_eq(sam_reply["instantane"]["groupes"], [], "pas dans l'instantané de Sam")
	_take(2)
	var reply := _win(1, frodon)
	var ended: Array = reply["evenements"].filter(func(event: Dictionary) -> bool: return event["type"] == Protocol.EVT_COMBAT_ENDED)
	assert_eq(ended.size(), 1, "combat gagné")
	var saved: Dictionary = _store.load_character("dev:frodon")
	assert_true(int(saved["personnage"]["classes"][saved["personnage"]["voie"]]["reputation"]) > 0, "la réputation du combat est enregistrée dès la fin du combat")
	assert_eq(_pushed(_take(2), Protocol.EVT_GROUP_RELEASED), [], "un groupe vaincu ne revient pas")


func test_groupe_libere_si_le_joueur_part_en_combat() -> void:
	_join(1, "Frodon")
	_join(2, "Sam")
	_command(1, {"type": Protocol.CMD_ENGAGE, "groupe": "groupe_1"})
	_take(2)
	_server.peer_disconnected(1)
	var messages := _take(2)
	var released := _pushed(messages, Protocol.EVT_GROUP_RELEASED)
	assert_eq(released.size(), 1, "le groupe abandonné réapparaît pour Sam")
	assert_eq(released[0]["groupe"]["id"], "groupe_1")
	assert_eq(_pushed(messages, Protocol.EVT_PLAYER_LEFT).size(), 1, "et Frodon s'en va")


func test_reconnexion_au_meme_endroit() -> void:
	var frodon := _join(1, "Frodon")
	var exit := Vector2i(-1, -1)
	for cell: Vector2i in _maps["test"].cells():
		if _maps["test"].is_walkable(cell) and "droite" in _maps["test"].exit_directions(cell):
			exit = cell
			break
	_command(1, {"type": Protocol.CMD_MOVE, "cible": exit, "sortie": "droite"})
	var target := Fixtures.center() + Vector2i(0, 1)
	_command(1, {"type": Protocol.CMD_MOVE, "cible": target})
	_server.peer_disconnected(1)
	assert_eq(_server.player_count(), 0)
	assert_true(_server.world.player(frodon) == null)
	_join(7, "Frodon")
	var messages := _take(7)
	assert_true(_of_type(messages, Protocol.MSG_WELCOME)[0]["personnage"], "le compte a déjà son personnage")
	var snapshot: Dictionary = _of_type(messages, Protocol.EVT_SNAPSHOT)[0]
	assert_eq(snapshot["carte"], "b", "sur la carte où on l'a laissé")
	assert_eq(snapshot["position"], target, "et sur sa case")


func test_meme_compte_connecte_ailleurs() -> void:
	_join(1, "Frodon")
	_join(2, "Frodon")
	assert_eq(_of_type(_take(1), Protocol.MSG_ERROR)[0]["raison"], Protocol.ERROR_ALREADY_CONNECTED)
	assert_true(1 in _kicked)
	assert_eq(_server.player_count(), 1)
	assert_false(_of_type(_take(2), Protocol.EVT_SNAPSHOT).is_empty(), "la nouvelle connexion reprend le personnage")


func test_le_temps_passe_pour_tous() -> void:
	var frodon := _join(1, "Frodon")
	_take(1)
	_server.world.player(frodon).character.hp_lost = 5
	_server.update(World.REGEN_SECONDS)
	assert_eq(_pushed(_take(1), Protocol.EVT_REGEN).size(), 1, "régénération envoyée sans commande")


func test_la_copie_du_client_suit_les_autres_joueurs() -> void:
	var frodon := _join(1, "Frodon")
	var copy := ClientState.new(Fixtures.data(), _loader)
	copy.load_snapshot(_of_type(_take(1), Protocol.EVT_SNAPSHOT)[0])
	var sam := _join(2, "Sam")
	_command(2, {"type": Protocol.CMD_MOVE, "cible": Fixtures.center() + Vector2i(1, 0)})
	_command(2, {"type": Protocol.CMD_SIT, "assis": true})
	for message: Dictionary in _of_type(_take(1), Protocol.MSG_EVENTS):
		for event: Dictionary in message["evenements"]:
			assert_true(copy.apply_event(event), "%s appliqué sans instantané" % event["type"])
	assert_eq(copy.other_players().size(), 1)
	assert_eq(copy.position_of(sam), Fixtures.center() + Vector2i(1, 0))
	assert_true(copy.other_players()[0]["assis"])
	_command(1, {"type": Protocol.CMD_ENGAGE, "groupe": "groupe_1"})
	var sam_copy := ClientState.new(Fixtures.data(), _loader)
	sam_copy.load_snapshot(_command(2, {"type": Protocol.CMD_SIT, "assis": false})["instantane"])
	assert_true(sam_copy.group("groupe_1").is_empty(), "le groupe combattu par Frodon n'est plus vu")
	assert_eq(copy.player_id, frodon)


## Frodon (chef) invite Sam ; Frodon engage, Sam rejoint ; les deux sont prêts.
func _group_fight(frodon: String, sam: String) -> Combat:
	_command(1, {"type": Protocol.CMD_PARTY_INVITE, "joueur": sam})
	assert_eq(_pushed(_take(2), Protocol.EVT_PARTY_INVITE).size(), 1, "Sam reçoit l'invitation")
	_command(2, {"type": Protocol.CMD_PARTY_ANSWER, "chef": frodon, "accepte": true})
	assert_eq(_pushed(_take(1), Protocol.EVT_PARTY).size(), 1, "Frodon voit son groupe")
	_command(1, {"type": Protocol.CMD_ENGAGE, "groupe": "groupe_1"})
	var swords := _pushed(_take(2), Protocol.EVT_GROUP_ENGAGED)
	assert_eq(swords[0]["case"], _server.world.player(frodon).cell, "Sam voit les épées du combat")
	var joined := _command(2, {"type": Protocol.CMD_JOIN_COMBAT, "groupe": "groupe_1"})
	assert_eq(joined["evenements"][1]["type"], Protocol.EVT_COMBAT_STARTED)
	var seen: Array = _of_type(_take(1), Protocol.MSG_EVENTS)
	assert_true(seen[0].has("instantane"), "Frodon reçoit l'arrivée de Sam avec son instantané")
	_command(1, {"type": Protocol.CMD_READY})
	_command(2, {"type": Protocol.CMD_READY})
	_take(1)
	return _server.world.player(frodon).combat


func test_combat_de_groupe_deconnexion_et_retour() -> void:
	var frodon := _join(1, "Frodon")
	var sam := _join(2, "Sam")
	_take(1)
	_take(2)
	var combat := _group_fight(frodon, sam)
	assert_eq(combat.state, Combat.State.FIGHTING)
	_server.peer_disconnected(2)
	assert_true(_server.world.is_away(sam), "Sam reste dans le combat")
	assert_eq(_pushed(_take(1), Protocol.EVT_FIGHTER_AWAY).size(), 1, "Frodon le sait")
	_join(3, "Sam")
	var back := _take(3)
	assert_true(_of_type(back, Protocol.MSG_WELCOME)[0]["personnage"])
	var snapshot: Dictionary = _of_type(back, Protocol.EVT_SNAPSHOT)[0]
	assert_true(snapshot["combat"] != null, "Sam retrouve son combat")
	assert_false(_server.world.is_away(sam))
	_take(1)
	_practiced(sam)
	var reply := _win(1, frodon)
	assert_eq(reply["evenements"].filter(func(e: Dictionary) -> bool: return e["type"] == Protocol.EVT_COMBAT_ENDED).size(), 1,
		"Frodon reçoit sa fin de combat")
	var pushed := _of_type(_take(3), Protocol.MSG_EVENTS)
	var ends := _pushed(pushed, Protocol.EVT_COMBAT_ENDED)
	assert_eq(ends.size(), 1, "Sam reçoit la sienne")
	assert_true(int(ends[0]["reputation"]) > 0, "avec sa part")
	assert_true(pushed[-1].has("instantane"))
	assert_true(_reputation(_store.load_character("dev:sam")) > 0, "Sam est sauvegardé aussi")


## Sam a lancé des sorts à effet réel pendant le combat (sa pratique, GDD § 4.5).
func _practiced(player_id: String) -> void:
	_server.world.player(player_id).combat.practice[player_id] = {"effet": {"acier": 30.0}, "utile": 0.0, "pv_recus": 0.0}


func test_absent_a_la_fin_du_combat_sauvegarde_puis_retire() -> void:
	var frodon := _join(1, "Frodon")
	var sam := _join(2, "Sam")
	_take(1)
	_take(2)
	_group_fight(frodon, sam)
	_server.peer_disconnected(2)
	_practiced(sam)
	_win(1, frodon)
	assert_true(_server.world.player(sam) == null, "Sam quitte le monde à la fin du combat")
	assert_true(_reputation(_store.load_character("dev:sam")) > 0, "avec ce qu'il y a gagné")


## Jalon M3 : les listes d'amis et d'ignorés suivent le personnage d'une connexion à l'autre, les
## amis apprennent son arrivée, et un signalement part dans le magasin du serveur.
func test_amis_sauvegardes_et_signalement() -> void:
	var frodon := _join(1, "Frodon")
	var sam := _join(2, "Sam")
	_take(1)
	_take(2)
	_command(1, {"type": Protocol.CMD_RELATIONS, "action": Relations.ADD, "nom": "Sam"})
	_command(2, {"type": Protocol.CMD_RELATIONS, "action": Relations.ADD, "nom": "Frodon"})
	_command(1, {"type": Protocol.CMD_RELATIONS, "action": Relations.IGNORE, "nom": "Gollum"})
	_server.peer_disconnected(1)
	assert_eq(_pushed(_take(2), Protocol.EVT_RELATIONS)[-1]["annonce"], "Frodon vient de partir.")
	assert_eq(_store.load_character("dev:frodon")["amis"], ["Sam"], "sauvegardées avec le personnage")
	_join(1, "Frodon")
	var snapshot: Dictionary = _of_type(_take(1), Protocol.EVT_SNAPSHOT)[0]
	assert_eq(snapshot["relations"]["ignores"], ["Gollum"], "retrouvées à la connexion")
	assert_true(snapshot["relations"]["amis"][0]["en_ligne"], "Sam, ami réciproque, est en ligne")
	assert_eq(_pushed(_take(2), Protocol.EVT_RELATIONS)[-1]["annonce"], "Frodon vient de se connecter.")

	_command(2, {"type": Protocol.CMD_CHAT, "canal": Chat.LOCAL, "texte": "Grossièreté"})
	var reply := _command(1, {"type": Protocol.CMD_REPORT, "nom": "Sam", "motif": "insultes", "commentaire": "à vérifier"})
	assert_eq(reply["evenements"][0]["type"], Protocol.EVT_REPORTED)
	assert_eq(_store.reports.size(), 1, "le signalement est enregistré")
	var report: Dictionary = _store.reports[0]
	assert_eq(report["auteur"], "dev:frodon", "les comptes, sans « j: »")
	assert_eq(report["cible"], "dev:sam")
	assert_eq(report["messages"][0]["texte"], "Grossièreté")
	assert_false(report["messages"][0].has("de"), "pas d'id de joueur dans le journal enregistré")
	assert_true(frodon != sam)


## Échange (jalon M4) : les deux personnages sont sauvegardés ensemble dès la fin de l'échange ; une
## déconnexion en plein échange ne déplace rien ; si la base ne répond pas, ils restent liés et ne
## sont jamais écrits l'un sans l'autre.
func test_echange_sauvegarde_les_deux_ensemble() -> void:
	var frodon := _join(1, "Frodon")
	var sam := _join(2, "Sam")
	var items: Dictionary = _server.world.data.items
	_server.world.player(frodon).character.inventory.add(items["dent"], 4)
	_server.world.player(frodon).character.inventory.ecus = 0
	_server.world.player(sam).character.inventory.ecus = 30
	_take(1)
	_take(2)
	_command(1, {"type": Protocol.CMD_EXCHANGE, "action": Exchange.PROPOSE, "joueur": sam})
	assert_eq(_pushed(_take(2), Protocol.EVT_EXCHANGE_REQUEST)[0]["nom"], "Frodon")
	_command(2, {"type": Protocol.CMD_EXCHANGE, "action": Exchange.ACCEPT, "joueur": frodon})
	assert_eq(_pushed(_take(1), Protocol.EVT_EXCHANGE).size(), 1, "Frodon voit l'échange s'ouvrir")
	_command(1, {"type": Protocol.CMD_EXCHANGE, "action": Exchange.ITEM, "objet": "dent", "quantite": 4})
	_command(2, {"type": Protocol.CMD_EXCHANGE, "action": Exchange.ECUS, "brumes": 30})
	_server.update(Exchange.VALIDATE_DELAY)
	_command(1, {"type": Protocol.CMD_EXCHANGE, "action": Exchange.VALIDATE})
	_store.fail_saves = true  # La base ne répond plus au moment de conclure.
	_command(2, {"type": Protocol.CMD_EXCHANGE, "action": Exchange.VALIDATE})
	var pushed := _take(1)
	assert_eq(_pushed(pushed, Protocol.EVT_EXCHANGE_CLOSED)[0]["raison"], Exchange.CLOSED_DONE)
	var with_inventory := _of_type(pushed, Protocol.MSG_EVENTS).filter(func(m: Dictionary) -> bool: return m.has("instantane"))
	assert_eq(with_inventory.size(), 1, "Frodon reçoit son inventaire et l'instantané")
	assert_eq(int(_store.load_character("dev:frodon")["personnage"]["inventaire"]["ecus"]), 20, "pas encore écrit (brumes de départ)")
	assert_true(_server.has_unsaved_exchange(sam))
	# Sam part : sa sauvegarde échoue aussi ; son état est gardé, jamais écrit sans celui de Frodon.
	_server.peer_disconnected(2)
	assert_eq(int(_store.load_character("dev:sam")["personnage"]["inventaire"]["ecus"]), 20)
	_store.fail_saves = false
	_server.save_all()  # Frodon seul est connecté : Sam est écrit avec lui.
	assert_false(_server.has_unsaved_exchange(frodon))
	assert_eq(int(_store.load_character("dev:frodon")["personnage"]["inventaire"]["ecus"]), 30)
	var sam_saved: Dictionary = _store.load_character("dev:sam")["personnage"]["inventaire"]
	var dents := 0
	for entry: Dictionary in sam_saved["objets"]:
		if entry["objet"] == "dent":
			dents += int(entry["quantite"])
	assert_eq(dents, 4, "Sam a les dents dans la base")


func test_deconnexion_en_plein_echange_ne_deplace_rien() -> void:
	var frodon := _join(1, "Frodon")
	var sam := _join(2, "Sam")
	_server.world.player(frodon).character.inventory.ecus = 50
	_command(1, {"type": Protocol.CMD_EXCHANGE, "action": Exchange.PROPOSE, "joueur": sam})
	_command(2, {"type": Protocol.CMD_EXCHANGE, "action": Exchange.ACCEPT, "joueur": frodon})
	_command(1, {"type": Protocol.CMD_EXCHANGE, "action": Exchange.ECUS, "brumes": 50})
	_server.update(Exchange.VALIDATE_DELAY)
	_command(2, {"type": Protocol.CMD_EXCHANGE, "action": Exchange.VALIDATE})
	_take(2)
	_server.peer_disconnected(1)
	assert_eq(_pushed(_take(2), Protocol.EVT_EXCHANGE_CLOSED)[0]["raison"], Exchange.CLOSED_LEFT)
	assert_eq(int(_store.load_character("dev:frodon")["personnage"]["inventaire"]["ecus"]), 50)
	assert_eq(_server.world.player(sam).character.inventory.ecus, 20, "ses brumes de départ, sans celles de Frodon")
	assert_true(_server.world.player(sam).exchange == null, "Sam est libre")


static func _reputation(state: Dictionary) -> int:
	var hero: Dictionary = state["personnage"]
	return int(hero["classes"][hero["voie"]]["reputation"])
