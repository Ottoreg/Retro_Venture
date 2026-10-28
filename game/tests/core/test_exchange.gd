extends "res://tests/test_case.gd"
## Échange entre joueurs (jalon M4, GDD § 16.5), sans réseau. Frodon (p1) et Sam (p2) sur la carte
## « a », Merry (p3) sur « b ». Rien ne doit pouvoir être dupliqué ni perdu.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _maps := {}
var _world: World


func before_each() -> void:
	_maps = {
		"a": Fixtures.map({}, [], {"id": "a", "sorties": {"droite": "b"}}),
		"b": Fixtures.map({}, [], {"id": "b", "sorties": {"gauche": "a"}}),
	}
	_world = World.new(_maps["a"], Fixtures.data(), _loader, _character("Frodon"), "p1")
	_world.add_player(_character("Sam"), "p2", "a")
	_world.add_player(_character("Merry"), "p3", "b")
	var items := _world.data.items
	_inventory("p1").add(items["dent"], 5)
	_inventory("p1").add(items["heaume"], 1, {"vitalite": 10})
	_inventory("p1").ecus = 100
	_inventory("p2").add(items["tresor"], 2)
	_inventory("p2").ecus = 50


func _loader(map_id: String) -> GameMap:
	return _maps.get(map_id)


func _character(name: String) -> Character:
	var character := Fixtures.character()
	character.display_name = name
	return character


func _inventory(player_id: String) -> Inventory:
	return _world.player(player_id).character.inventory


func _do(player_id: String, action: String, extra := {}) -> Array[Dictionary]:
	var command := {"type": Protocol.CMD_EXCHANGE, "entite": player_id, "action": action}
	command.merge(extra)
	return _world.execute(command)


func _open() -> void:
	_do("p1", Exchange.PROPOSE, {"joueur": "p2"})
	_do("p2", Exchange.ACCEPT, {"joueur": "p1"})


## Uid de l'objet `item_id` dans l'inventaire du joueur.
func _uid(player_id: String, item_id: String) -> String:
	for entry: Dictionary in _inventory(player_id).entries.values():
		if entry["objet"] == item_id:
			return entry["uid"]
	return ""


## Exemplaires de chaque objet et brumes des deux joueurs réunis : ce qui ne doit jamais changer.
func _totals() -> Dictionary:
	var totals := {"brumes": 0}
	for player_id in ["p1", "p2"]:
		totals["brumes"] += _inventory(player_id).ecus
		for entry: Dictionary in _inventory(player_id).entries.values():
			totals[entry["objet"]] = totals.get(entry["objet"], 0) + int(entry["quantite"])
	return totals


func test_echange_complet() -> void:
	var before := _totals()
	var asked := _do("p1", Exchange.PROPOSE, {"joueur": "p2"})
	assert_eq(asked[0]["type"], Protocol.EVT_EXCHANGE_REQUEST)
	assert_eq(asked[0][Protocol.FIELD_FOR], "p2")
	assert_eq(asked[0]["nom"], "Frodon")
	var opened := _do("p2", Exchange.ACCEPT, {"joueur": "p1"})
	assert_eq(Fixtures.of_type(opened, Protocol.EVT_EXCHANGE).size(), 2, "les deux voient l'échange")
	_do("p1", Exchange.ITEM, {"objet": _uid("p1", "dent"), "quantite": 3})
	_do("p1", Exchange.ITEM, {"objet": _uid("p1", "heaume"), "quantite": 1})
	_do("p1", Exchange.ECUS, {"brumes": 40})
	var views := _do("p2", Exchange.ITEM, {"objet": "tresor", "quantite": 2})
	var seen: Dictionary = views.filter(func(e: Dictionary) -> bool: return e[Protocol.FIELD_FOR] == "p2")[0]
	assert_eq(seen["sien"]["brumes"], 40, "Sam voit les brumes de Frodon")
	assert_eq(seen["sien"]["objets"].size(), 2)
	assert_eq(_do("p1", Exchange.VALIDATE)[0]["raison"], Protocol.REASON_TOO_SOON, "pas tout de suite après un changement")
	_world.update(Exchange.VALIDATE_DELAY)
	var half := _do("p1", Exchange.VALIDATE)
	assert_true(half[0]["valide_moi"])
	assert_eq(_inventory("p2").quantity_of("dent"), 0, "rien ne bouge avant les deux validations")
	var done := _do("p2", Exchange.VALIDATE)
	assert_eq(Fixtures.of_type(done, Protocol.EVT_EXCHANGE_CLOSED).size(), 2)
	assert_eq(Fixtures.of_type(done, Protocol.EVT_EXCHANGE_CLOSED)[0]["raison"], Exchange.CLOSED_DONE)
	assert_eq(Fixtures.of_type(done, Protocol.EVT_INVENTORY).size(), 2, "inventaire des deux")
	assert_eq(_inventory("p1").quantity_of("dent"), 2)
	assert_eq(_inventory("p2").quantity_of("dent"), 3)
	assert_eq(_inventory("p2").quantity_of("heaume"), 1)
	var heaume: Dictionary = _inventory("p2").entries[_uid("p2", "heaume")]
	assert_eq(heaume["jets"], {"vitalite": 10}, "les jets suivent l'objet")
	assert_eq(_inventory("p1").quantity_of("tresor"), 2)
	assert_eq(_inventory("p1").ecus, 60)
	assert_eq(_inventory("p2").ecus, 90)
	assert_eq(_totals(), before, "rien de créé ni de perdu")
	assert_eq(_world.take_exchanges(), [["p1", "p2"]], "à sauvegarder ensemble")
	assert_eq(_world.take_exchanges(), [])
	assert_true(_world.player("p1").exchange == null)
	assert_true(_world.player("p2").exchange == null)


func test_un_changement_retire_les_validations() -> void:
	_open()
	_do("p1", Exchange.ITEM, {"objet": _uid("p1", "dent"), "quantite": 5})
	_world.update(Exchange.VALIDATE_DELAY)
	_do("p2", Exchange.VALIDATE)
	var changed := _do("p1", Exchange.ITEM, {"objet": _uid("p1", "dent"), "quantite": 1})
	assert_false(changed[0]["valide_lui"] or changed[0]["valide_moi"])
	assert_eq(_do("p1", Exchange.VALIDATE)[0]["raison"], Protocol.REASON_TOO_SOON)
	_world.update(Exchange.VALIDATE_DELAY)
	_do("p1", Exchange.VALIDATE)
	assert_eq(_inventory("p2").quantity_of("dent"), 0, "la validation de Sam est tombée")
	_do("p2", Exchange.VALIDATE)
	assert_eq(_inventory("p2").quantity_of("dent"), 1, "la dernière offre")


func test_offres_refusees() -> void:
	_open()
	var heaume := _uid("p1", "heaume")
	_inventory("p1").equip(heaume, "coiffe")
	assert_eq(_do("p1", Exchange.ITEM, {"objet": heaume, "quantite": 1})[0]["raison"], Protocol.REASON_ITEM_WORN)
	assert_eq(_do("p1", Exchange.ITEM, {"objet": "dent", "quantite": 6})[0]["raison"], Protocol.REASON_INVALID_COMMAND)
	assert_eq(_do("p1", Exchange.ITEM, {"objet": "tresor", "quantite": 1})[0]["raison"], Protocol.REASON_UNKNOWN_ITEM)
	assert_eq(_do("p1", Exchange.ECUS, {"brumes": 101})[0]["raison"], Protocol.REASON_NOT_ENOUGH_ECUS)
	assert_eq(_do("p1", Exchange.ECUS, {"brumes": -1})[0]["raison"], Protocol.REASON_NOT_ENOUGH_ECUS)


func test_pendant_un_echange_on_ne_fait_rien_d_autre() -> void:
	_open()
	var moved := _world.execute({"type": Protocol.CMD_MOVE, "entite": "p1", "cible": _maps["a"].spawn + Vector2i(1, 0)})
	assert_eq(moved[0]["raison"], Protocol.REASON_IN_EXCHANGE)
	var dropped := _world.execute({"type": Protocol.CMD_DROP, "entite": "p2", "objet": "tresor", "quantite": 1})
	assert_eq(dropped[0]["raison"], Protocol.REASON_IN_EXCHANGE, "pas de quoi vider son offre en douce")
	var chat := _world.execute({"type": Protocol.CMD_CHAT, "entite": "p1", "canal": Chat.LOCAL, "texte": "Ça marche ?"})
	assert_eq(chat[0]["type"], Protocol.EVT_CHAT, "le chat reste permis")


func test_deconnexion_en_plein_echange() -> void:
	var before := _totals()
	_open()
	_do("p1", Exchange.ITEM, {"objet": _uid("p1", "dent"), "quantite": 5})
	_do("p2", Exchange.ECUS, {"brumes": 50})
	_world.update(Exchange.VALIDATE_DELAY)
	_do("p1", Exchange.VALIDATE)
	var frodon := _world.player("p1")
	var events := _world.remove_player("p2")
	var closed := Fixtures.of_type(events, Protocol.EVT_EXCHANGE_CLOSED).filter(func(e: Dictionary) -> bool:
		return e[Protocol.FIELD_FOR] == "p1")
	assert_eq(closed.size(), 1)
	assert_eq(closed[0]["raison"], Exchange.CLOSED_LEFT)
	assert_true(frodon.exchange == null, "Frodon est libre")
	assert_eq(frodon.character.inventory.quantity_of("dent"), 5, "rien n'a bougé")
	assert_eq(frodon.character.inventory.ecus, 100)
	assert_eq(_world.take_exchanges(), [])
	_world.add_player(_character("Sam"), "p2", "a")
	assert_eq(_do("p1", Exchange.VALIDATE)[0]["raison"], Protocol.REASON_INVALID_COMMAND, "plus d'échange")
	assert_eq(before["dent"], 5)


func test_annuler_ferme_l_echange_ou_la_proposition() -> void:
	_open()
	var cancelled := _do("p2", Exchange.CANCEL)
	assert_eq(Fixtures.of_type(cancelled, Protocol.EVT_EXCHANGE_CLOSED).size(), 2)
	assert_eq(cancelled[0]["raison"], Exchange.CLOSED_CANCELLED)
	assert_true(_world.player("p1").exchange == null)
	# Proposition en attente retirée : Sam l'apprend.
	_do("p1", Exchange.PROPOSE, {"joueur": "p2"})
	var left := _do("p1", Exchange.CANCEL)
	assert_eq(left[0][Protocol.FIELD_FOR], "p2")
	assert_eq(_do("p2", Exchange.ACCEPT, {"joueur": "p1"})[0]["raison"], Protocol.REASON_NO_INVITATION)


func test_proposition_refusee_ou_impossible() -> void:
	assert_eq(_do("p1", Exchange.PROPOSE, {"joueur": "p3"})[0]["raison"], Protocol.REASON_UNKNOWN_ENTITY, "pas sur la même carte")
	assert_eq(_do("p1", Exchange.PROPOSE, {"joueur": "p1"})[0]["raison"], Protocol.REASON_UNKNOWN_ENTITY)
	_do("p1", Exchange.PROPOSE, {"joueur": "p2"})
	var declined := _do("p2", Exchange.DECLINE, {"joueur": "p1"})
	assert_eq(declined[0]["type"], Protocol.EVT_EXCHANGE_CLOSED)
	assert_eq(declined[0][Protocol.FIELD_FOR], "p1")
	assert_eq(declined[0]["raison"], Exchange.CLOSED_DECLINED)
	_world.player("p2").ignored.append("Frodon")
	assert_eq(_do("p1", Exchange.PROPOSE, {"joueur": "p2"}), [] as Array[Dictionary], "ignoré : perdu sans le dire")
	_world.player("p2").ignored.clear()
	_open()
	_world.add_player(_character("Pippin"), "p4", "a")
	assert_eq(_do("p4", Exchange.PROPOSE, {"joueur": "p1"})[0]["raison"], Protocol.REASON_PLAYER_BUSY)


func test_sac_plein_rien_ne_bouge() -> void:
	var sam := _inventory("p2")
	sam.capacity = sam.entries.size()  # Plus une place.
	var before := _totals()
	_open()
	_do("p1", Exchange.ITEM, {"objet": _uid("p1", "heaume"), "quantite": 1})
	_world.update(Exchange.VALIDATE_DELAY)
	_do("p1", Exchange.VALIDATE)
	var refused := _do("p2", Exchange.VALIDATE)
	assert_eq(refused[0]["type"], Protocol.EVT_EXCHANGE)
	assert_false(refused[0]["erreur"].is_empty(), "les deux voient pourquoi")
	assert_false(refused[0]["valide_moi"] or refused[0]["valide_lui"])
	assert_eq(_totals(), before)
	assert_eq(_inventory("p1").quantity_of("heaume"), 1)
	assert_eq(_world.take_exchanges(), [])
	# Sam donne son trésor en même temps : sa place se libère, l'échange passe.
	_do("p2", Exchange.ITEM, {"objet": "tresor", "quantite": 2})
	_world.update(Exchange.VALIDATE_DELAY)
	_do("p1", Exchange.VALIDATE)
	_do("p2", Exchange.VALIDATE)
	assert_eq(sam.quantity_of("heaume"), 1)
	assert_eq(_totals(), before)
