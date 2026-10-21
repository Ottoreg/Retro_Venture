extends "res://tests/test_case.gd"
## Expérience après les combats, points de caractéristique et sauvegarde du monde.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _maps := {}


func before_each() -> void:
	_maps = {
		"ouest": Fixtures.map({}, [], {"id": "ouest", "sorties": {"droite": "est"}}),
		"est": Fixtures.map({Fixtures.center(): "1", GameMap.plan_cell(2, 2): "2"},
			[{"monstres": ["mannequin"]}, {"monstres": ["mannequin"]}], {"id": "est", "sorties": {"gauche": "ouest"}}),
	}


func _loader(map_id: String) -> GameMap:
	return _maps.get(map_id)


func _world() -> World:
	return World.new(_maps["est"], Fixtures.data(), _loader, Fixtures.character())


func _win_against(world: World, group_id: String) -> Array[Dictionary]:
	world.execute({"type": Protocol.CMD_ENGAGE, "entite": World.PLAYER_ID, "groupe": group_id})
	var monster := world.combat.get_fighter("%s_1" % group_id)
	var player := world.combat.get_fighter(World.PLAYER_ID)
	for neighbor in IsoGrid.neighbors_4(monster.cell):
		if world.combat.is_free(neighbor):
			player.cell = neighbor
			break
	monster.hp = 1
	world.execute({"type": Protocol.CMD_READY, "entite": World.PLAYER_ID})
	return world.execute({"type": Protocol.CMD_CAST, "entite": World.PLAYER_ID, "sort": "frappe", "cible": monster.cell})


func test_experience_et_niveau_apres_victoire() -> void:
	var world := _world()
	var events := _win_against(world, "groupe_1")
	var xp := Fixtures.of_type(events, Protocol.EVT_XP)
	assert_eq(xp.size(), 1)
	var gain := roundi(20 * Character.XP_RATE)
	assert_eq(xp[0]["gain"], gain, "10 XP × XP_RATE × (100 + 100 de Sagesse) %")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_COMBAT_ENDED)[0]["xp"], gain, "XP affichée en fin de combat")
	assert_eq(world.character.xp, gain)
	world.character.xp = 75
	var more := _win_against(world, "groupe_2")
	var levels := Fixtures.of_type(more, Protocol.EVT_LEVEL_UP)
	assert_eq(levels.size(), 1, "80 XP et plus (sous 280) : niveau 2")
	assert_eq(levels[0]["points"], Character.POINTS_PER_LEVEL)
	assert_eq(Fixtures.of_type(more, Protocol.EVT_CHARACTER)[0]["personnage"]["niveau"], 2)


func test_investir_des_points() -> void:
	var world := _world()
	world.character.add_xp(80)
	var events := world.execute({"type": Protocol.CMD_SPEND_POINTS, "entite": World.PLAYER_ID, "carac": "force", "points": 2})
	assert_eq(events[0]["type"], Protocol.EVT_CHARACTER)
	assert_eq(events[0]["personnage"]["caracteristiques"]["force"], 52)
	assert_eq(events[0]["personnage"]["points"], 3)
	var refused := world.execute({"type": Protocol.CMD_SPEND_POINTS, "entite": World.PLAYER_ID, "carac": "force", "points": 9})
	assert_eq(refused[0]["raison"], Protocol.REASON_NOT_ENOUGH_POINTS)
	var reset := world.execute({"type": Protocol.CMD_RESET_POINTS, "entite": World.PLAYER_ID})
	assert_eq(reset[0]["personnage"]["points"], 5, "points rendus")
	assert_eq(reset[0]["personnage"]["caracteristiques"]["force"], 50)
	var nothing := world.execute({"type": Protocol.CMD_RESET_POINTS, "entite": World.PLAYER_ID})
	assert_eq(nothing[0]["raison"], Protocol.REASON_NOTHING_TO_RESET)


func test_sauvegarde_et_reprise() -> void:
	var world := _world()
	_win_against(world, "groupe_1")
	world.character.add_xp(500)
	world.character.spend_points("chance", 5)
	var position := world.position_of(World.PLAYER_ID)
	var save: Variant = JSON.parse_string(JSON.stringify(world.save_data()))
	assert_true(typeof(save) == TYPE_DICTIONARY, "sauvegarde sérialisable en JSON")

	var restored := World.from_save(save, Fixtures.data(), _loader)
	assert_true(restored != null, "monde restauré")
	assert_eq(restored.map.id, "est")
	assert_eq(restored.position_of(World.PLAYER_ID), position)
	assert_eq(restored.character.to_dict(), world.character.to_dict())
	assert_eq(restored.groups().size(), 1, "le groupe vaincu ne revient pas")
	assert_eq(restored.groups()[0]["id"], "groupe_2")


func test_sauvegardes_invalides() -> void:
	assert_true(World.from_save({}, Fixtures.data(), _loader) == null, "vide")
	var save := _world().save_data()
	save["carte"] = "disparue"
	assert_true(World.from_save(save, Fixtures.data(), _loader) == null, "carte inconnue")
	var no_loader := _world().save_data()
	assert_true(World.from_save(no_loader, Fixtures.data(), Callable()) == null, "sans chargeur de cartes")
