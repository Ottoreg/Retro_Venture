extends "res://tests/test_case.gd"
## Donjons (GDD § 12) : clé consommée à l'entrée, instance privée, aucune réapparition, réveil au vestibule, sortie du
## boss une fois la salle vidée, instance fermée quand on en sort.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _world: World


func _map(id: String, npcs: Array, groups := [], extra := {}) -> GameMap:
	var changes := {}
	for npc: Dictionary in npcs:
		changes[npc["case"]] = npc["marqueur"]
	if not groups.is_empty():
		changes[Fixtures.center()] = "1"
	var data := {"id": id, "plan": Fixtures.plan_with(changes), "groupes": groups, "pnj": npcs.map(func(npc: Dictionary) -> Dictionary:
		return {"marqueur": npc["marqueur"], "id": npc["id"], "nom": npc["id"], "repliques": ["…"], "entree": npc["entree"]})}
	if not groups.is_empty():
		data["placement"] = Fixtures.OPEN_PLACEMENT.duplicate()
	data.merge(extra)
	assert_true(GameMap.validate(data).is_empty(), str(GameMap.validate(data)))
	return GameMap.from_dict(data)


func _gate(id: String, marker: String, column: int, entry: Dictionary) -> Dictionary:
	return {"id": id, "marqueur": marker, "case": GameMap.plan_cell(column, 4), "entree": entry}


func before_each() -> void:
	var maps := {
		"vestibule": _map("vestibule", [_gate("sortie", "a", 2, {"carte": "dehors"}), _gate("couloir", "b", 7, {"carte": "salle"})], [],
			{"donjon": "vestibule"}),
		"salle": _map("salle", [_gate("fond", "a", 2, {"carte": "dehors", "salle_videe": true})], [{"monstres": ["loup"]}],
			{"donjon": "vestibule"}),
	}
	var outside := _map("dehors", [_gate("portier", "a", 2, {"carte": "vestibule", "cle": "dent"})])
	maps["dehors"] = outside
	_world = World.new(outside, Fixtures.data(), func(id: String) -> GameMap: return maps.get(id))
	_world.player_voie = "test"


func _talk(npc_id: String) -> void:
	_world.execute({"type": Protocol.CMD_TALK, "entite": World.PLAYER_ID, "pnj": npc_id})


func _dungeon_keys() -> Array:
	return _world.instances.keys().filter(func(key: String) -> bool: return "#" in key)


func _fight(won: bool) -> void:
	_world.execute({"type": Protocol.CMD_ENGAGE, "entite": World.PLAYER_ID, "groupe": "groupe_1"})
	var monster := _world.combat.get_fighter("groupe_1_1")
	var player := _world.combat.get_fighter(World.PLAYER_ID)
	for neighbor in IsoGrid.neighbors_4(monster.cell):
		if _world.combat.is_free(neighbor):
			player.cell = neighbor
			break
	_world.execute({"type": Protocol.CMD_READY, "entite": World.PLAYER_ID})
	if won:
		monster.hp = 1
		_world.execute({"type": Protocol.CMD_CAST, "entite": World.PLAYER_ID, "sort": "frappe", "cible": monster.cell})
	else:
		player.hp = 1
		_world.execute({"type": Protocol.CMD_END_TURN, "entite": World.PLAYER_ID})
	assert_false(_world.in_combat())


func test_cle_instance_et_sortie() -> void:
	_talk("portier")
	assert_eq(_world.map.id, "dehors", "pas d'entrée sans clé")
	_world.character.inventory.add(_world.data.items["dent"], 2)
	_talk("portier")
	assert_eq([_world.map.id, _world.character.inventory.quantity_of("dent")], ["vestibule", 1], "une clé consommée")
	_talk("couloir")
	assert_eq(_world.map.id, "salle")
	assert_eq(_dungeon_keys().size(), 2, "salles privées : « carte#propriétaire »")
	_talk("fond")
	assert_eq(_world.map.id, "salle", "la sortie du boss attend que la salle soit vidée")
	_fight(true)
	_world.update(10000.0)
	assert_eq(_world.groups().size(), 0, "aucune réapparition en donjon")
	assert_false(_world.save_data()["groupes_restants"].keys().any(func(key: String) -> bool: return "#" in key), "jamais sauvegardée")
	_talk("fond")
	assert_eq(_world.map.id, "dehors")
	assert_eq(_dungeon_keys(), [], "instance fermée en sortant")
	_talk("portier")
	_talk("couloir")
	assert_eq(_world.groups().size(), 1, "nouvelle instance, nouvelle clé")


func test_defaite_au_vestibule() -> void:
	_world.character.inventory.add(_world.data.items["dent"])
	_talk("portier")
	_talk("couloir")
	_fight(false)
	assert_eq(_world.map.id, "vestibule", "réveil au vestibule")
	_talk("couloir")
	assert_eq(_world.groups().size(), 1, "le groupe est resté en place")


func test_instance_du_groupe() -> void:
	var mate := _world.add_player(Fixtures.character(), "ami")
	var stranger := _world.add_player(Fixtures.character(), "inconnu")
	mate.party_leader = World.PLAYER_ID
	_world.players[World.PLAYER_ID].party_leader = World.PLAYER_ID
	for id: String in [World.PLAYER_ID, "ami", "inconnu"]:
		_world.players[id].character.inventory.add(_world.data.items["dent"])
		_world.execute({"type": Protocol.CMD_TALK, "entite": id, "pnj": "portier"})
	assert_eq(mate.instance, _world.players[World.PLAYER_ID].instance, "même instance pour le groupe")
	assert_ne(stranger.instance, mate.instance, "une autre pour un joueur hors du groupe")
	_world.remove_player("inconnu")
	assert_true(_world.instances.has("vestibule#inconnu"), "attend 15 minutes un joueur déconnecté")
	_world.update(World.DUNGEON_GRACE + 1.0)
	assert_false(_world.instances.has("vestibule#inconnu"))


## La Grange du Père Fauchard (contenu provisoire) : gardien sur la ferme de Brumerive, salles voisines du vestibule.
func test_grange_du_pere_fauchard() -> void:
	var data := GameData.load_all()
	var loader := func(id: String) -> GameMap: return DataLoader.load_map(DataLoader.map_path(id))
	var world := World.new(loader.call("brumerive_1_2"), data, loader)
	world.character.inventory.add(data.items["cle_de_la_grange"])
	world.execute({"type": Protocol.CMD_TALK, "entite": World.PLAYER_ID, "pnj": "gardien_de_la_grange"})
	assert_eq(world.map.id, "grange_vestibule")
	for side: String in ["haut", "droite", "bas"]:
		var room := loader.call(world.map.exits[side]) as GameMap
		assert_eq(room.dungeon, "grange_vestibule", "%s : salle du donjon" % room.id)
		assert_false(room.groups.is_empty(), "%s : des monstres" % room.id)
	assert_true(data.monsters["pere_fauchard"].get("boss", false))
	assert_eq(data.items["plan_cle_de_la_grange"]["recette"]["objet"], "cle_de_la_grange")
	assert_true((loader.call("grange_bureau") as GameMap).get_npc("porte_de_derriere")["entree"]["salle_videe"], "sortie après le boss")
