extends "res://tests/test_case.gd"
## Réapparition des monstres, PV gardés entre les combats, portes, maison : lit et coffre.

const Fixtures := preload("res://tests/helpers/fixtures.gd")
const HOUSE_PLAN := ["$...=", " ....", ".....", " ....", "@.+.."]

var _maps := {}
var _world: World
## Porte du village (coin haut droit) ; coffre, lit et porte de la maison.
var _door := GameMap.plan_cell(0, 8)
var _chest := GameMap.plan_cell(0, 0)
var _bed := GameMap.plan_cell(0, 4)
var _house_door := GameMap.plan_cell(4, 2)


func before_each() -> void:
	_maps = {
		"test": _village({"monstres": ["mannequin"]}),
		"maison": GameMap.from_dict({
			"id": "maison", "nom": "Maison", "instance": "joueur", "sol": "parquet", "portes": ["test"],
			"plan": HOUSE_PLAN,
		}),
	}
	_world = World.new(_maps["test"], Fixtures.data(), _loader, Fixtures.character())


func _village(group: Dictionary) -> GameMap:
	return Fixtures.map({Fixtures.center(): "1", GameMap.plan_cell(0, 8): "+"}, [group], {"portes": ["maison"]})


func _loader(map_id: String) -> GameMap:
	return _maps.get(map_id)


func _command(type: String, extra := {}) -> Array[Dictionary]:
	var command := {"type": type, "entite": World.PLAYER_ID}
	command.merge(extra, true)
	return _world.execute(command)


func _assert_refused(events: Array[Dictionary], reason: String, message := "") -> void:
	assert_eq(events.size(), 1, message)
	assert_eq(events[0]["type"], Protocol.EVT_REFUSED, message)
	assert_eq(events[0].get("raison"), reason, message)


## Gagne le combat contre le groupe : le joueur frappe le mannequin à 1 PV.
func _win_fight(player_damage := 0) -> void:
	_command(Protocol.CMD_ENGAGE, {"groupe": "groupe_1"})
	var monster := _world.combat.get_fighter("groupe_1_1")
	var player := _world.combat.get_fighter(World.PLAYER_ID)
	for neighbor in IsoGrid.neighbors_4(monster.cell):
		if _world.combat.is_free(neighbor):
			player.cell = neighbor
			break
	monster.hp = 1
	player.hp -= player_damage
	_command(Protocol.CMD_READY)
	_command(Protocol.CMD_CAST, {"sort": "frappe", "cible": monster.cell})
	assert_false(_world.in_combat(), "combat gagné")


func _go_next_to(cell: Vector2i) -> void:
	var path := _world.map.approach_path(_world.position_of(World.PLAYER_ID), cell)
	if not path.is_empty():
		_command(Protocol.CMD_MOVE, {"cible": path[-1]})


# --- Réapparition des monstres ------------------------------------------------------------------

func test_le_groupe_reapparait_apres_deux_a_trois_minutes() -> void:
	_win_fight()
	assert_eq(_world.groups().size(), 0, "groupe vaincu")
	_command(Protocol.CMD_MOVE, {"cible": GameMap.plan_cell(0, 0)})
	assert_true(_world.update(119.0).is_empty(), "pas avant deux minutes")
	var events := _world.update(61.0)
	assert_eq(events.size(), 1, "revenu avant trois minutes")
	assert_eq(events[0]["type"], Protocol.EVT_GROUP_RESPAWNED)
	assert_eq(events[0]["groupe"]["id"], "groupe_1")
	assert_eq(_world.groups().size(), 1)
	assert_eq(_world.position_of("groupe_1"), Fixtures.center())
	_command(Protocol.CMD_ENGAGE, {"groupe": "groupe_1"})
	assert_true(_world.in_combat(), "on peut le combattre à nouveau")


func test_delai_de_reapparition_et_joueur_sur_la_case() -> void:
	_maps["test"] = _village({"monstres": ["mannequin"], "reapparition": [10, 10]})
	_world = World.new(_maps["test"], Fixtures.data(), _loader, Fixtures.character())
	_win_fight()
	assert_eq(_world.position_of(World.PLAYER_ID), Fixtures.center(), "le joueur est resté sur la case du groupe")
	assert_true(_world.update(30.0).is_empty(), "pas de réapparition sous les pieds du joueur")
	_command(Protocol.CMD_MOVE, {"cible": GameMap.plan_cell(0, 0)})
	assert_eq(_world.update(World.RESPAWN_RETRY).size(), 1, "dès qu'il s'en va")


func test_reapparition_pendant_qu_on_est_ailleurs() -> void:
	_win_fight()
	_go_next_to(_door)
	_command(Protocol.CMD_MOVE, {"cible": _door, "porte": true})
	assert_eq(_world.map.id, "maison")
	assert_true(_world.update(200.0).is_empty(), "rien à signaler dans la maison")
	_command(Protocol.CMD_MOVE, {"cible": _world.map.door_to("test"), "porte": true})
	assert_eq(_world.map.id, "test")
	assert_eq(_world.groups().size(), 1, "le groupe est revenu entre-temps")


func test_reapparition_sauvegardee() -> void:
	_win_fight()
	_command(Protocol.CMD_MOVE, {"cible": GameMap.plan_cell(0, 0)})
	_world.update(100.0)
	var restored := World.from_save(JSON.parse_string(JSON.stringify(_world.save_data())), Fixtures.data(), _loader)
	assert_true(restored != null)
	assert_eq(restored.groups().size(), 0, "toujours vaincu après la reprise")
	assert_true(restored.update(19.0).is_empty(), "il restait au moins 20 s")
	assert_eq(restored.update(61.0).size(), 1, "puis il revient")


func test_reapparition_invalide() -> void:
	var data := {"id": "x", "plan": Fixtures.plan_with({Fixtures.center(): "1"}), "groupes": [{"monstres": ["a"], "reapparition": [0, 5]}]}
	assert_false(GameMap.validate(data).is_empty())


# --- Points de vie ------------------------------------------------------------------------------

func test_les_pv_perdus_se_gardent() -> void:
	var character := _world.character
	var max_hp := character.max_hp(_world.data)
	_win_fight(10)
	assert_eq(character.hp(_world.data), max_hp - 10, "PV d'après le combat")
	assert_eq(_world.character.sheet(_world.data)["pv"], max_hp - 10)
	_command(Protocol.CMD_MOVE, {"cible": GameMap.plan_cell(0, 0)})
	_world.update(200.0)  # Le groupe revient (et les PV aussi).
	character.hp_lost = 10
	_command(Protocol.CMD_ENGAGE, {"groupe": "groupe_1"})
	assert_eq(_world.combat.get_fighter(World.PLAYER_ID).hp, max_hp - 10, "le combat suivant commence blessé")


func test_regeneration_hors_combat() -> void:
	_world.character.hp_lost = 10
	_world.update(World.REGEN_SECONDS * 2)
	assert_eq(_world.character.hp_lost, 8, "un PV toutes les %d s" % World.REGEN_SECONDS)
	_world.update(World.REGEN_SECONDS * 0.5)
	_world.update(World.REGEN_SECONDS * 0.5)
	assert_eq(_world.character.hp_lost, 7, "le temps s'accumule")
	_world.update(1000.0)
	assert_eq(_world.character.hp_lost, 0)


func test_defaite_avec_un_pv() -> void:
	_maps["test"] = _village({"monstres": ["loup"]})
	_world = World.new(_maps["test"], Fixtures.data(), _loader, Fixtures.character())
	_command(Protocol.CMD_ENGAGE, {"groupe": "groupe_1"})
	var monster := _world.combat.get_fighter("groupe_1_1")
	var player := _world.combat.get_fighter(World.PLAYER_ID)
	for neighbor in IsoGrid.neighbors_4(monster.cell):
		if _world.combat.is_free(neighbor):
			player.cell = neighbor
			break
	player.hp = 1
	_command(Protocol.CMD_READY)
	_command(Protocol.CMD_END_TURN)
	assert_false(_world.in_combat(), "combat perdu")
	assert_eq(_world.character.hp(_world.data), 1, "vaincu : 1 PV")


# --- Portes, lit et coffre ----------------------------------------------------------------------

func test_portes() -> void:
	assert_eq(_maps["test"].doors.get(_door), "maison")
	assert_true(_maps["test"].is_walkable(_door), "on marche sur une porte")
	_assert_refused(_command(Protocol.CMD_MOVE, {"cible": GameMap.plan_cell(1, 1), "porte": true}), Protocol.REASON_NO_EXIT)
	var events := _command(Protocol.CMD_MOVE, {"cible": _door, "porte": true})
	assert_eq(events[0]["type"], Protocol.EVT_MOVED, "on marche jusqu'à la porte")
	assert_eq(events[-1]["type"], Protocol.EVT_MAP_CHANGED)
	assert_eq(_world.map.id, "maison")
	assert_eq(_world.map.instance, "joueur", "maison instanciée par joueur en multi")
	assert_eq(_world.position_of(World.PLAYER_ID), _house_door, "on arrive sur la porte de la maison")
	events = _command(Protocol.CMD_MOVE, {"cible": _house_door, "porte": true})
	assert_eq(events[-1]["type"], Protocol.EVT_MAP_CHANGED, "on peut ressortir sans bouger")
	assert_eq(_world.map.id, "test")
	assert_eq(_world.position_of(World.PLAYER_ID), _door, "devant chez soi")


func test_portes_invalides() -> void:
	var data := {"id": "x", "plan": Fixtures.plan_with({GameMap.plan_cell(0, 8): "+"}), "portes": []}
	assert_false(GameMap.validate(data).is_empty(), "une porte sans destination")
	data["portes"] = ["a", "b"]
	assert_false(GameMap.validate(data).is_empty(), "plus de destinations que de portes")
	data["portes"] = ["a"]
	assert_true(GameMap.validate(data).is_empty())


func _enter_house() -> void:
	_command(Protocol.CMD_MOVE, {"cible": _door, "porte": true})


func test_dormir_dans_son_lit() -> void:
	_enter_house()
	var bed := _bed
	assert_eq(_world.map.obstacles.get(bed), "lit")
	_world.character.hp_lost = 25
	_assert_refused(_command(Protocol.CMD_USE, {"case": bed}), Protocol.REASON_TOO_FAR)
	_go_next_to(bed)
	var events := _command(Protocol.CMD_USE, {"case": bed})
	assert_eq(events[0]["type"], Protocol.EVT_RESTED)
	assert_eq(events[0]["gain"], 25)
	assert_eq(events[0]["pv"], events[0]["pv_max"])
	assert_eq(_world.character.hp_lost, 0, "tous les PV")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_CHARACTER).size(), 1)
	_assert_refused(_command(Protocol.CMD_USE, {"case": GameMap.plan_cell(1, 1)}), Protocol.REASON_UNKNOWN_ENTITY)


func test_coffre() -> void:
	var inventory := _world.character.inventory
	var chest_store := _world.character.chest
	inventory.add(_world.data.items["dent"], 5)
	var ring := inventory.add(_world.data.items["bague"], 1, {"force": 4})
	_enter_house()
	var chest := _chest
	_assert_refused(_command(Protocol.CMD_DEPOSIT, {"case": chest, "objet": "dent"}), Protocol.REASON_TOO_FAR)
	_go_next_to(chest)
	var opened := _command(Protocol.CMD_USE, {"case": chest})
	assert_eq(opened[0]["type"], Protocol.EVT_CHEST)
	assert_eq(opened[0]["coffre"]["objets"].size(), 0, "coffre vide")
	assert_eq(opened[0]["coffre"]["places"], Character.CHEST_ENTRIES)

	var events := _command(Protocol.CMD_DEPOSIT, {"case": chest, "objet": "dent", "quantite": 3})
	assert_eq(events[0]["type"], Protocol.EVT_CHEST)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_INVENTORY).size(), 1)
	assert_eq(inventory.quantity_of("dent"), 2)
	assert_eq(chest_store.quantity_of("dent"), 3)
	_command(Protocol.CMD_DEPOSIT, {"case": chest, "objet": ring})
	assert_eq(inventory.quantity_of("bague"), 0)
	var stored_ring: Dictionary = chest_store.entries.values().filter(func(e: Dictionary) -> bool: return e["objet"] == "bague")[0]
	assert_eq(stored_ring["jets"], {"force": 4}, "les jets sont conservés")
	_command(Protocol.CMD_WITHDRAW, {"case": chest, "objet": "dent", "quantite": 3})
	assert_eq(inventory.quantity_of("dent"), 5)
	assert_eq(chest_store.quantity_of("dent"), 0)

	# Sauvegarde du coffre avec le personnage.
	var copy := Character.from_dict(_world.character.to_dict(), _world.data.items)
	assert_eq(copy.chest.quantity_of("bague"), 1)
	assert_eq(copy.chest.capacity, Character.CHEST_ENTRIES)


func test_coffre_refus() -> void:
	var inventory := _world.character.inventory
	var worn := inventory.add(_world.data.items["bague"], 1, {})
	inventory.equip(worn, "anneau_1")
	inventory.add(_world.data.items["dent"], 2)
	_enter_house()
	var chest := _chest
	_go_next_to(chest)
	_assert_refused(_command(Protocol.CMD_DEPOSIT, {"case": chest, "objet": worn}), Protocol.REASON_ITEM_WORN)
	_assert_refused(_command(Protocol.CMD_DEPOSIT, {"case": chest, "objet": "dent", "quantite": 3}), Protocol.REASON_INVALID_COMMAND)
	_assert_refused(_command(Protocol.CMD_WITHDRAW, {"case": chest, "objet": "dent"}), Protocol.REASON_UNKNOWN_ITEM, "pas dans le coffre")
	_assert_refused(_command(Protocol.CMD_DEPOSIT, {"case": _bed, "objet": "dent"}), Protocol.REASON_UNKNOWN_ENTITY, "le lit n'est pas un coffre")
	while not _world.character.chest.is_full():
		_world.character.chest.add(_world.data.items["bague"], 1, {})
	_assert_refused(_command(Protocol.CMD_DEPOSIT, {"case": chest, "objet": "dent"}), Protocol.REASON_INVENTORY_FULL)


func test_groupe_tire_au_sort_a_chaque_apparition() -> void:
	_maps["test"] = _village({"parmi": ["mannequin", "blinde"], "nombre": [3, 3], "reapparition": [10, 10]})
	_world = World.new(_maps["test"], Fixtures.data(), _loader, Fixtures.character())
	var group: Dictionary = _world.groups()[0]
	assert_eq(group["monstres"].size(), 3, "trois monstres tirés")
	for monster_id: String in group["monstres"]:
		assert_true(monster_id in ["mannequin", "blinde"], monster_id)
	assert_true(_maps["test"].groups[0]["monstres"].is_empty(), "la carte n'est pas modifiée")
	_command(Protocol.CMD_ENGAGE, {"groupe": "groupe_1"})
	assert_true(_world.in_combat())
	for i in 3:
		assert_true(_world.combat.get_fighter("groupe_1_%d" % (i + 1)) != null, "membre %d au combat" % (i + 1))


func test_groupe_tire_au_sort_a_la_reapparition() -> void:
	_maps["test"] = _village({"parmi": ["mannequin", "blinde"], "nombre": [2, 2], "reapparition": [10, 10]})
	_world = World.new(_maps["test"], Fixtures.data(), _loader, Fixtures.character())
	var kinds := {}
	for round_index in 12:
		var group: Dictionary = _world.groups()[0]
		assert_eq(group["monstres"].size(), 2)
		kinds[str(group["monstres"])] = true
		# Le groupe est vaincu (simulé), puis revient avec un nouveau tirage.
		_world._schedule_respawn(_world.map.id, group)
		_world._groups.erase("groupe_1")
		_world._positions.erase("groupe_1")
		var events := _world.update(10.0)
		assert_eq(events.size(), 1, "réapparu")
		assert_eq(events[0]["groupe"]["monstres"].size(), 2)
	assert_true(kinds.size() > 1, "plusieurs compositions au fil des réapparitions (%s)" % str(kinds.keys()))
