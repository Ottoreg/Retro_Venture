extends "res://tests/test_case.gd"
## Amis, ignorés et signalements (jalon M3, GDD § 16.5), sans réseau. Frodon et Sam sur la carte
## « a », Merry sur « b ».

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


func _relation(player_id: String, action: String, other: String) -> Array[Dictionary]:
	return _as(player_id, Protocol.CMD_RELATIONS, {"action": action, "nom": other})


func _friends_of(player_id: String) -> Array:
	return _world.relations_view(_world.player(player_id))["amis"]


func test_ami_a_sens_unique_statut_si_reciproque() -> void:
	var events := _relation("p1", Relations.ADD, "merry")
	assert_eq(events[0]["type"], Protocol.EVT_RELATIONS)
	assert_eq(events[0][Protocol.FIELD_FOR], "p1")
	assert_eq(events[0]["amis"][0]["nom"], "Merry", "le pseudo tel qu'il s'écrit")
	assert_false(events[0]["amis"][0]["en_ligne"], "Merry ne compte pas Frodon parmi ses amis : statut caché")
	events = _relation("p3", Relations.ADD, "Frodon")
	var mine: Array = Fixtures.of_type(events, Protocol.EVT_RELATIONS).filter(func(e: Dictionary) -> bool:
		return e[Protocol.FIELD_FOR] == "p1")
	assert_eq(mine.size(), 1, "Frodon voit tout de suite Merry apparaître")
	assert_true(mine[0]["amis"][0]["en_ligne"])
	assert_eq(mine[0]["amis"][0]["carte"], "b")
	assert_false(mine[0]["amis"][0]["combat"])
	assert_eq(_relation("p1", Relations.ADD, "Merry")[0]["amis"].size(), 1, "pas de doublon")
	_relation("p1", Relations.REMOVE, "MERRY")
	assert_eq(_friends_of("p1"), [])


func test_ami_hors_ligne_et_refus() -> void:
	var events := _relation("p1", Relations.ADD, "Gandalf")
	assert_eq(events[0]["amis"], [{"nom": "Gandalf", "en_ligne": false, "carte": "", "combat": false}],
		"un pseudo hors ligne s'ajoute, sans statut")
	assert_eq(_relation("p1", Relations.ADD, "Frodon")[0]["raison"], Protocol.REASON_INVALID_COMMAND, "pas soi-même")
	assert_eq(_relation("p1", Relations.ADD, "x")[0]["raison"], Protocol.REASON_INVALID_COMMAND, "pseudo invalide")
	assert_eq(_relation("p1", "adorer", "Sam")[0]["raison"], Protocol.REASON_INVALID_COMMAND)
	assert_eq(_relation("p1", "", "")[0]["type"], Protocol.EVT_RELATIONS, "action vide : la liste, à jour")
	for i in Relations.MAX_ENTRIES:
		_world.player("p1").ignored.append("Orque" + "abcdefghijklmnopqrstuvwxyz"[i % 26] + "abcdefghij"[i / 26])
	assert_eq(_relation("p1", Relations.IGNORE, "Sam")[0]["raison"], Protocol.REASON_LIST_FULL)


func test_annonce_de_connexion_et_de_depart() -> void:
	_relation("p1", Relations.ADD, "Merry")
	_relation("p3", Relations.ADD, "Frodon")
	_relation("p2", Relations.ADD, "Merry")  # Sam compte Merry, mais Merry ne le compte pas.
	var left := Fixtures.of_type(_world.remove_player("p3"), Protocol.EVT_RELATIONS)
	assert_eq(left.size(), 2, "Frodon et Sam ont Merry parmi leurs amis")
	var for_frodon: Dictionary = left.filter(func(e: Dictionary) -> bool: return e[Protocol.FIELD_FOR] == "p1")[0]
	assert_eq(for_frodon["annonce"], "Merry vient de partir.")
	assert_false(for_frodon["amis"][0]["en_ligne"])
	var for_sam: Dictionary = left.filter(func(e: Dictionary) -> bool: return e[Protocol.FIELD_FOR] == "p2")[0]
	assert_eq(for_sam["annonce"], "", "pas d'annonce sans amitié réciproque")
	var merry := _world.add_player(_character("Merry"), "p3", "b")
	_world.restore_relations("p3", {"amis": ["Frodon"], "ignores": []})
	var back := _world.presence_events(merry, true)
	assert_eq(back.filter(func(e: Dictionary) -> bool: return e[Protocol.FIELD_FOR] == "p1")[0]["annonce"], "Merry vient de se connecter.")


func test_sauvegarde_des_listes() -> void:
	_relation("p1", Relations.ADD, "Merry")
	_relation("p1", Relations.IGNORE, "Sam")
	var saved := _world.player_save("p1")
	assert_eq(saved["amis"], ["Merry"])
	assert_eq(saved["ignores"], ["Sam"])
	_world.restore_relations("p2", {"amis": ["Frodon", "frodon", 3, "", "Merry"], "ignores": "rien"})
	assert_eq(_world.player("p2").friends, ["Frodon", "Merry"] as Array[String], "liste nettoyée")
	assert_eq(_world.player("p2").ignored, [] as Array[String])
	assert_eq(_world.snapshot("p1")["relations"]["ignores"], ["Sam"], "dans l'instantané")
	_relation("p1", Relations.ADD, "Sam")
	assert_eq(_world.player("p1").ignored, [] as Array[String], "ami ou ignoré, pas les deux")


func test_un_ignore_n_atteint_plus_rien() -> void:
	_relation("p1", Relations.IGNORE, "Sam")
	var said := _as("p2", Protocol.CMD_CHAT, {"canal": Chat.LOCAL, "texte": "Ohé Frodon"})
	var receivers := said.map(func(e: Dictionary) -> String: return e[Protocol.FIELD_FOR])
	assert_eq(receivers, ["p2"], "Frodon ne reçoit pas les messages de Sam")
	var whispered := _as("p2", Protocol.CMD_CHAT, {"canal": Chat.PRIVATE, "texte": "Tu m'ignores ?", "a": "Frodon"})
	assert_eq(whispered.size(), 1, "le privé semble parti, sans arriver")
	assert_eq(whispered[0][Protocol.FIELD_FOR], "p2")
	assert_eq(_as("p2", Protocol.CMD_PARTY_INVITE, {"joueur": "p1"}), [] as Array[Dictionary], "invitation retenue, sans refus")
	assert_true(_world.player("p1").invitations.is_empty())
	var mine := _as("p1", Protocol.CMD_CHAT, {"canal": Chat.LOCAL, "texte": "Moi je parle"})
	assert_eq(mine.size(), 2, "ignorer ne coupe que dans un sens")


func test_signalement() -> void:
	_as("p2", Protocol.CMD_CHAT, {"canal": Chat.LOCAL, "texte": "Message un peu fort"})
	var events := _as("p1", Protocol.CMD_REPORT, {"nom": "sam", "motif": "insultes", "commentaire": "Il insulte\nles gens"})
	assert_eq(events[0]["type"], Protocol.EVT_REPORTED)
	assert_eq(events[0]["nom"], "Sam")
	var reports := _world.take_reports()
	assert_eq(reports.size(), 1)
	assert_eq(reports[0]["auteur"], "p1")
	assert_eq(reports[0]["cible"], "p2")
	assert_eq(reports[0]["cible_nom"], "Sam")
	assert_eq(reports[0]["motif"], "insultes")
	assert_eq(reports[0]["commentaire"], "Il insulte les gens")
	assert_eq(reports[0]["carte"], "a")
	assert_eq(reports[0]["messages"].size(), 1, "ses derniers messages joints")
	assert_eq(reports[0]["messages"][0]["texte"], "Message un peu fort")
	assert_eq(_world.take_reports(), [] as Array[Dictionary], "pris une seule fois")
	var again := _as("p1", Protocol.CMD_REPORT, {"nom": "Sam", "motif": "spam"})
	assert_eq(again[0]["raison"], Protocol.REASON_ALREADY_REPORTED, "une fois par heure")
	_world.clock += Relations.REPORT_DELAY
	assert_eq(_as("p1", Protocol.CMD_REPORT, {"nom": "Sam", "motif": "spam"})[0]["type"], Protocol.EVT_REPORTED)
	assert_eq(_as("p1", Protocol.CMD_REPORT, {"nom": "Sam", "motif": "rien"})[0]["raison"], Protocol.REASON_INVALID_COMMAND)
	assert_eq(_as("p1", Protocol.CMD_REPORT, {"nom": "Frodon", "motif": "spam"})[0]["raison"], Protocol.REASON_UNKNOWN_ENTITY)
	assert_eq(_as("p1", Protocol.CMD_REPORT, {"nom": "Gandalf", "motif": "spam"})[0]["raison"], Protocol.REASON_UNKNOWN_ENTITY)


func test_signaler_un_joueur_parti_apres_avoir_ecrit() -> void:
	_as("p3", Protocol.CMD_CHAT, {"canal": Chat.TRADE, "texte": "Achetez mon or pas cher"})
	_world.remove_player("p3")
	var events := _as("p1", Protocol.CMD_REPORT, {"nom": "Merry", "motif": "spam"})
	assert_eq(events[0]["type"], Protocol.EVT_REPORTED)
	var report: Dictionary = _world.take_reports()[0]
	assert_eq(report["cible"], "p3", "retrouvé par le journal du chat")
	assert_eq(report["carte"], "")
	assert_eq(report["messages"][0]["canal"], Chat.TRADE)
