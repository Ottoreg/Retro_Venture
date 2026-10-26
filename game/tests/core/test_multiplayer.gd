extends "res://tests/test_case.gd"
## Jalon M0 du multijoueur (GDD § 16.5) : deux joueurs sur une même carte vivante (`MapInstance`),
## sans réseau. Chacun agit par l'id de son personnage, et `World.recipients` dit qui reçoit quoi.

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


## Une case de la carte d'où l'on peut sortir dans cette direction.
func _exit_cell(game_map: GameMap, direction: String) -> Vector2i:
	for cell: Vector2i in game_map.cells():
		if game_map.is_walkable(cell) and direction in game_map.exit_directions(cell):
			return cell
	return GameMap.NO_CELL


func _sorted(ids: Array[String]) -> Array:
	var sorted := ids.duplicate()
	sorted.sort()
	return sorted


func test_deux_joueurs_sur_la_meme_carte_vivante() -> void:
	var p1 := _world.player("p1")
	var p2 := _world.player("p2")
	assert_true(p1.instance == p2.instance, "une seule MapInstance pour la carte « a »")
	assert_eq(p1.instance.player_ids(), ["p1", "p2"])
	assert_eq(p1.cell, _maps["a"].spawn)
	assert_eq(p2.cell, _maps["a"].spawn)
	assert_true(p1.instance.groups.has("groupe_1"), "les groupes sont ceux de la carte, pour tous")
	assert_eq(_world.character.display_name, "Frodon", "la façade solo montre le premier joueur")
	assert_true(_world.add_player(_character("Gollum"), "p2") == null, "un id déjà connecté est refusé")


func test_chacun_agit_par_son_id() -> void:
	var target := Fixtures.center() + Vector2i(1, 0)
	var events := _as("p2", Protocol.CMD_MOVE, {"cible": target})
	assert_eq(events[0]["type"], Protocol.EVT_MOVED)
	assert_eq(events[0]["entite"], "p2")
	assert_eq(_world.player("p2").cell, target)
	assert_eq(_world.player("p1").cell, _maps["a"].spawn, "l'autre n'a pas bougé")
	_as("p1", Protocol.CMD_SIT)
	assert_true(_world.player("p1").sitting)
	assert_false(_world.player("p2").sitting)


func test_portee_des_evenements() -> void:
	var moved := _as("p2", Protocol.CMD_MOVE, {"cible": Fixtures.center() + Vector2i(1, 0)})
	assert_eq(moved[0]["carte"], "a")
	assert_eq(_sorted(_world.recipients(moved[0], "p2")), ["p1", "p2"], "un déplacement se voit de toute la carte")
	var sat := _as("p1", Protocol.CMD_SIT)
	assert_eq(_sorted(_world.recipients(sat[0], "p1")), ["p1", "p2"])
	var refused := _as("p2", Protocol.CMD_RESET_POINTS)
	assert_eq(refused[0]["type"], Protocol.EVT_REFUSED)
	assert_eq(_world.recipients(refused[0], "p2"), ["p2"], "un refus ne regarde que son joueur")
	var wounded := _world.player("p1").character
	wounded.hp_lost = 5
	var regen := Fixtures.of_type(_world.update(World.REGEN_SECONDS), Protocol.EVT_REGEN)
	assert_eq(regen.size(), 1, "seul le blessé se régénère")
	assert_eq(_world.recipients(regen[0]), ["p1"], "personnel, d'après son `entite`")


func test_arrivee_et_depart_d_un_joueur() -> void:
	var exit := _exit_cell(_maps["a"], "droite")
	var events := _as("p2", Protocol.CMD_MOVE, {"cible": exit, "sortie": "droite"})
	var left := Fixtures.of_type(events, Protocol.EVT_PLAYER_LEFT)
	assert_eq(left.size(), 1)
	assert_eq(left[0]["carte"], "a")
	assert_true("p1" in _world.recipients(left[0], "p2"), "ceux de l'ancienne carte le voient partir")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_PLAYER_JOINED), [], "personne sur la carte « b »")
	assert_eq(_world.player("p2").map.id, "b")
	assert_eq(_world.player("p1").instance.player_ids(), ["p1"])
	events = _as("p2", Protocol.CMD_MOVE, {"cible": _exit_cell(_maps["b"], "gauche"), "sortie": "gauche"})
	var joined := Fixtures.of_type(events, Protocol.EVT_PLAYER_JOINED)
	assert_eq(joined.size(), 1)
	assert_eq(joined[0]["joueur"]["id"], "p2")
	assert_eq(joined[0]["joueur"]["nom"], "Sam")
	assert_eq(_world.recipients(joined[0], "p2"), ["p1", "p2"])
	assert_true(_world.instances["b"].groups.is_empty() and not _world.instances["b"].has_players(), "« b » reste en mémoire, vide")


func test_en_solo_aucun_evenement_de_joueur() -> void:
	var world := World.new(_maps["a"], Fixtures.data(), _loader, Fixtures.character())
	var events := world.execute({"type": Protocol.CMD_MOVE, "entite": World.PLAYER_ID, "cible": _exit_cell(_maps["a"], "droite"),
		"sortie": "droite"})
	assert_eq(Fixtures.of_type(events, Protocol.EVT_PLAYER_LEFT), [])
	assert_eq(Fixtures.of_type(events, Protocol.EVT_PLAYER_JOINED), [])


func test_un_groupe_en_combat_est_pris() -> void:
	_world.player("p1").character.voie_id = "test"
	_world.player("p2").character.voie_id = "test"
	var events := _as("p1", Protocol.CMD_ENGAGE, {"groupe": "groupe_1"})
	var started := Fixtures.of_type(events, Protocol.EVT_COMBAT_STARTED)
	assert_eq(started.size(), 1)
	assert_eq(_world.recipients(started[0], "p1"), ["p1"], "le combat ne regarde que ses participants")
	var refused := _as("p2", Protocol.CMD_ENGAGE, {"groupe": "groupe_1"})
	assert_eq(refused[0]["raison"], Protocol.REASON_GROUP_IN_COMBAT)
	var moved := _as("p2", Protocol.CMD_MOVE, {"cible": Fixtures.center() + Vector2i(0, 1)})
	assert_eq(moved[0]["type"], Protocol.EVT_MOVED, "l'autre joueur explore pendant ce temps")
	assert_true(_world.player("p1").in_combat())
	assert_false(_world.player("p2").in_combat())


func test_deconnexion() -> void:
	var events := _world.remove_player("p2")
	assert_eq(events.size(), 1)
	assert_eq(events[0]["type"], Protocol.EVT_PLAYER_LEFT)
	assert_eq(_world.recipients(events[0]), ["p1"])
	assert_true(_world.player("p2") == null)
	assert_eq(_world.player("p1").instance.player_ids(), ["p1"])
	assert_eq(_world.remove_player("p1"), [] as Array[Dictionary], "le joueur de la façade solo reste")


func test_evenements_de_carte_avec_leur_carte() -> void:
	# Tout événement de portée « carte » dit de quelle carte il s'agit (le serveur s'en sert).
	var events: Array[Dictionary] = []
	events.append_array(_as("p2", Protocol.CMD_MOVE, {"cible": Fixtures.center() + Vector2i(1, 0)}))
	events.append_array(_as("p1", Protocol.CMD_SIT))
	events.append_array(_as("p2", Protocol.CMD_MOVE, {"cible": _exit_cell(_maps["a"], "droite"), "sortie": "droite"}))
	events.append_array(_world.update(60.0))
	events.append_array(_as("p2", Protocol.CMD_MOVE, {"cible": _exit_cell(_maps["b"], "gauche"), "sortie": "gauche"}))
	var seen := {}
	for event in events:
		if event["type"] in Protocol.MAP_EVENTS:
			seen[event["type"]] = true
			assert_true(event.has("carte"), "%s a sa carte" % event["type"])
			assert_eq(Protocol.scope_of(event), Protocol.SCOPE_MAP)
	assert_true(seen.size() >= 4, "déplacement, assis, départ, arrivée (et promenade)")
