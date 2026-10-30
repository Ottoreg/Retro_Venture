extends "res://tests/test_case.gd"
## Chat par canaux (jalon M3, GDD § 16.5), sans réseau : qui reçoit chaque canal, texte nettoyé,
## anti-flood, journal pour les signalements. Frodon et Sam sur la carte « a », Merry sur « b ».

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _maps := {}
var _world: World


func before_each() -> void:
	_maps = {
		"a": Fixtures.map({Fixtures.center(): "1"}, [{"monstres": ["mannequin"]}], {"id": "a", "sorties": {"droite": "b"}}),
		"b": Fixtures.map({}, [], {"id": "b", "sorties": {"gauche": "a"}}),
	}
	_world = World.new(_maps["a"], Fixtures.data(), _loader, _character("Frodon"), "p1")
	_world.add_player(_character("Sam"), "p2", "a")
	_world.add_player(_character("Merry"), "p3", "b")


func _loader(map_id: String) -> GameMap:
	return _maps.get(map_id)


func _character(name: String) -> Character:
	var character := Fixtures.character()
	character.display_name = name
	return character


func _as(player_id: String, type: String, extra := {}) -> Array[Dictionary]:
	var command := {"type": type, "entite": player_id}
	command.merge(extra)
	return _world.execute(command)


func _say(player_id: String, channel: String, text: String, to := "") -> Array[Dictionary]:
	var extra := {"canal": channel, "texte": text}
	if not to.is_empty():
		extra["a"] = to
	return _as(player_id, Protocol.CMD_CHAT, extra)


## Destinataires des messages (champ `pour`), triés.
func _receivers(events: Array[Dictionary]) -> Array:
	var ids := events.map(func(event: Dictionary) -> String: return event[Protocol.FIELD_FOR])
	ids.sort()
	return ids


func test_local_pour_la_carte_de_l_auteur() -> void:
	var events := _say("p1", Chat.LOCAL, "Bonjour la Comté")
	assert_eq(_receivers(events), ["p1", "p2"], "Merry, sur une autre carte, n'entend pas")
	assert_eq(events[0]["type"], Protocol.EVT_CHAT)
	assert_eq(events[0]["auteur"], "Frodon")
	assert_eq(events[0]["de"], "p1")
	assert_eq(events[0]["texte"], "Bonjour la Comté")
	for event in events:
		assert_eq(_world.recipients(event, "p1"), [event[Protocol.FIELD_FOR]], "routé vers son seul destinataire")
		assert_false(Protocol.needs_snapshot(event), "la copie du client l'applique seule")


func test_prive_entre_deux_cartes() -> void:
	var events := _say("p1", Chat.PRIVATE, "Tu as l'anneau ?", "merry")
	assert_eq(_receivers(events), ["p1", "p3"], "le destinataire et l'auteur (son propre message)")
	assert_eq(events[0]["a"], "Merry", "pseudo trouvé sans tenir compte des majuscules")
	var offline := _say("p1", Chat.PRIVATE, "Ohé ?", "Gollum")
	assert_eq(offline[0]["type"], Protocol.EVT_REFUSED)
	assert_eq(offline[0]["raison"], Protocol.REASON_PLAYER_OFFLINE)
	assert_eq(_say("p1", Chat.PRIVATE, "Moi-même", "Frodon")[0]["type"], Protocol.EVT_REFUSED)


func test_groupe_meme_sur_deux_cartes() -> void:
	var refused := _say("p1", Chat.PARTY, "Personne ?")
	assert_eq(refused[0]["raison"], Protocol.REASON_NOT_IN_PARTY)
	_as("p1", Protocol.CMD_PARTY_INVITE, {"joueur": "p3"})
	_as("p3", Protocol.CMD_PARTY_ANSWER, {"chef": "p1", "accepte": true})
	var events := _say("p3", Chat.PARTY, "J'arrive")
	assert_eq(_receivers(events), ["p1", "p3"], "Sam, hors du groupe, n'entend pas")


func test_commerce_et_recrutement_pour_tout_le_serveur() -> void:
	assert_eq(_receivers(_say("p2", Chat.TRADE, "Vends bois de frêne")), ["p1", "p2", "p3"])
	assert_eq(_receivers(_say("p2", Chat.RECRUIT, "Groupe pour Grondin")), ["p1", "p2", "p3"])
	var again := _say("p2", Chat.TRADE, "Vends bois de frêne, encore")
	assert_eq(again[0]["raison"], Protocol.REASON_CHAT_FLOOD, "un message par minute sur ces canaux")
	assert_eq(again[0]["attente"], 60)
	assert_eq(_say("p2", Chat.LOCAL, "Mais je peux parler ici")[0]["type"], Protocol.EVT_CHAT)
	_world.clock += Chat.WORLD_CHANNEL_DELAY
	assert_eq(_say("p2", Chat.TRADE, "Vends bois de frêne, dernière")[0]["type"], Protocol.EVT_CHAT)


func test_anti_flood() -> void:
	for i in Chat.FLOOD_MESSAGES:
		assert_eq(_say("p1", Chat.LOCAL, "message %d" % i)[0]["type"], Protocol.EVT_CHAT)
	_world.clock += 4.0
	var refused := _say("p1", Chat.LOCAL, "un de trop")
	assert_eq(refused[0]["raison"], Protocol.REASON_CHAT_FLOOD)
	assert_eq(refused[0]["attente"], 6, "jusqu'à ce que le premier ait 10 s")
	assert_eq(_say("p2", Chat.LOCAL, "Sam, lui, peut")[0]["type"], Protocol.EVT_CHAT)
	_world.clock += 6.0
	assert_eq(_say("p1", Chat.LOCAL, "de nouveau")[0]["type"], Protocol.EVT_CHAT)


func test_prive_a_un_pseudo_avec_espaces() -> void:
	_world.add_player(_character("Soso la fusée"), "p4", "b")
	_world.add_player(_character("Soso"), "p5", "b")
	# `/w Soso la fusée salut` : le client ne sait pas où finit le pseudo et envoie le premier mot.
	var events := _say("p1", Chat.PRIVATE, "la fusée salut", "Soso")
	assert_eq(_receivers(events), ["p1", "p4"], "le plus long pseudo connecté l'emporte")
	assert_eq(events[0]["texte"], "salut", "le pseudo est ôté du texte")
	assert_eq(events[0]["a"], "Soso la fusée")
	events = _say("p1", Chat.PRIVATE, "SALUT", "soso LA fusée")
	assert_eq(_receivers(events), ["p1", "p4"], "pseudo complet (menu du pseudo, /r), majuscules ignorées")
	assert_eq(events[0]["texte"], "SALUT")
	events = _say("p1", Chat.PRIVATE, "la forme ?", "Soso")
	assert_eq(_receivers(events), ["p1", "p5"], "sinon le premier mot")
	assert_eq(events[0]["texte"], "la forme ?")
	assert_eq(_say("p1", Chat.PRIVATE, "salut", "Soso la")[0]["raison"], Protocol.REASON_PLAYER_OFFLINE)


func test_texte_nettoye() -> void:
	var events := _say("p1", Chat.LOCAL, "  Salut\n[color=red]toi[/color]\t ")
	assert_eq(events[0]["texte"], "Salut [color=red]toi[/color]", "sans contrôle ni espaces autour ; le client échappe les crochets")
	assert_eq(_say("p1", Chat.LOCAL, "x".repeat(500))[0]["texte"].length(), Chat.MAX_LENGTH)
	assert_eq(_say("p1", Chat.LOCAL, "   ")[0]["raison"], Protocol.REASON_INVALID_COMMAND)
	assert_eq(_say("p1", "taverne", "Où ?")[0]["raison"], Protocol.REASON_INVALID_COMMAND)
	assert_eq(_as("p1", Protocol.CMD_CHAT, {"canal": Chat.LOCAL, "texte": 3})[0]["raison"], Protocol.REASON_INVALID_COMMAND)


func test_en_combat_et_absent() -> void:
	_as("p1", Protocol.CMD_PARTY_INVITE, {"joueur": "p2"})
	_as("p2", Protocol.CMD_PARTY_ANSWER, {"chef": "p1", "accepte": true})
	_as("p1", Protocol.CMD_ENGAGE, {"groupe": "groupe_1"})
	assert_true(_world.player("p1").in_combat())
	assert_eq(_receivers(_say("p1", Chat.LOCAL, "À l'attaque")), ["p1", "p2"], "on écrit en plein combat")
	_as("p2", Protocol.CMD_JOIN_COMBAT, {"groupe": "groupe_1"})
	_world.disconnect_player("p2")
	assert_true(_world.player("p2").away)
	assert_eq(_receivers(_say("p1", Chat.PARTY, "Sam ?")), ["p1"], "un absent ne reçoit rien")
	assert_eq(_say("p3", Chat.PRIVATE, "Sam ?", "Sam")[0]["raison"], Protocol.REASON_PLAYER_OFFLINE)


func test_journal_pour_les_signalements() -> void:
	_say("p2", Chat.LOCAL, "premier")
	_say("p1", Chat.LOCAL, "autre auteur")
	_say("p2", Chat.PRIVATE, "deuxième", "Merry")
	var recent := _world.chat.recent_by("p2")
	assert_eq(recent.map(func(line: Dictionary) -> String: return line["texte"]), ["premier", "deuxième"])
	assert_eq(recent[1]["canal"], Chat.PRIVATE)
	assert_eq(recent[1]["a"], "p3")
	for i in Chat.JOURNAL_SIZE + 5:
		_world.chat.record("p1", "Frodon", Chat.LOCAL, "ligne %d" % i, float(i))
	assert_eq(_world.chat.journal[Chat.LOCAL].size(), Chat.JOURNAL_SIZE, "journal borné par canal")
	assert_eq(_world.chat.recent_by("p1", 3).size(), 3)
