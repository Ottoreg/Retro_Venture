extends "res://tests/test_case.gd"
## Combat lancé depuis l'exploration : engagement, placement, retour en exploration.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _world: World


func _world_with(monster_id: String) -> World:
	var map := Fixtures.map({Fixtures.center(): "1"}, [{"monstres": [monster_id]}])
	var world := World.new(map, Fixtures.data())
	world.player_voie = "test"
	return world


func _engage(world: World) -> Array[Dictionary]:
	return world.execute({"type": Protocol.CMD_ENGAGE, "entite": World.PLAYER_ID, "groupe": "groupe_1"})


## Met le joueur au contact du monstre (placement direct, pour les tests).
func _stick_player_to_monster(world: World) -> Fighter:
	var monster := world.combat.get_fighter("groupe_1_1")
	var player := world.combat.get_fighter(World.PLAYER_ID)
	for neighbor in IsoGrid.neighbors_4(monster.cell):
		if world.combat.is_free(neighbor):
			player.cell = neighbor
			break
	return monster


func test_groupes_de_la_carte() -> void:
	_world = _world_with("mannequin")
	assert_eq(_world.groups().size(), 1)
	assert_eq(_world.group_at(Fixtures.center())["monstres"], ["mannequin"])
	assert_eq(_world.position_of("groupe_1"), Fixtures.center())


func test_engager_un_groupe() -> void:
	_world = _world_with("mannequin")
	var events := _engage(_world)
	assert_eq(events[0]["type"], Protocol.EVT_MOVED, "le joueur marche jusqu'au groupe")
	var start := Fixtures.of_type(events, Protocol.EVT_COMBAT_STARTED)
	assert_eq(start.size(), 1)
	assert_eq(start[0]["groupe"], "groupe_1")
	assert_eq(start[0]["combattants"].size(), 2)
	var placement: Array = start[0]["placement"]
	assert_true(placement.size() > 0, "cases de placement proposées")
	for cell: Vector2i in placement:
		assert_true(_world.map.is_walkable(cell), "case de placement praticable")
		assert_true(IsoGrid.distance(cell, Fixtures.center()) >= 2, "placement à distance du groupe")
	assert_true(_world.in_combat())
	var refused := _world.execute({"type": Protocol.CMD_ENGAGE, "entite": World.PLAYER_ID, "groupe": "groupe_1"})
	assert_eq(refused[0]["type"], Protocol.EVT_REFUSED, "pas d'exploration pendant un combat")


func test_engagements_refuses() -> void:
	_world = _world_with("mannequin")
	var unknown := _world.execute({"type": Protocol.CMD_ENGAGE, "entite": World.PLAYER_ID, "groupe": "groupe_9"})
	assert_eq(unknown[0]["raison"], Protocol.REASON_UNKNOWN_ENTITY)
	var no_data := World.new(_world.map)
	var refused := no_data.execute({"type": Protocol.CMD_ENGAGE, "entite": World.PLAYER_ID, "groupe": "groupe_1"})
	assert_eq(refused[0]["type"], Protocol.EVT_REFUSED)
	assert_false(no_data.in_combat())


func test_victoire_retour_en_exploration() -> void:
	_world = _world_with("mannequin")
	_engage(_world)
	var monster := _stick_player_to_monster(_world)
	monster.hp = 5
	_world.execute({"type": Protocol.CMD_READY, "entite": World.PLAYER_ID})
	var events := _world.execute({"type": Protocol.CMD_CAST, "entite": World.PLAYER_ID, "sort": "frappe", "cible": monster.cell})
	var back := Fixtures.of_type(events, Protocol.EVT_EXPLORATION)
	assert_eq(back.size(), 1)
	assert_eq(back[0]["groupe_vaincu"], "groupe_1")
	assert_eq(back[0]["position"], Fixtures.center(), "le joueur reste là où était le groupe")
	assert_false(_world.in_combat())
	assert_eq(_world.groups().size(), 0, "le groupe a disparu")


func test_defaite_retour_au_depart() -> void:
	_world = _world_with("loup")
	_engage(_world)
	_stick_player_to_monster(_world)
	_world.combat.get_fighter(World.PLAYER_ID).hp = 1
	_world.execute({"type": Protocol.CMD_READY, "entite": World.PLAYER_ID})
	var events := _world.execute({"type": Protocol.CMD_END_TURN, "entite": World.PLAYER_ID})
	var back := Fixtures.of_type(events, Protocol.EVT_EXPLORATION)
	assert_eq(back.size(), 1)
	assert_eq(back[0]["groupe_vaincu"], "")
	assert_eq(_world.position_of(World.PLAYER_ID), _world.map.spawn)
	assert_eq(_world.groups().size(), 1, "le groupe est toujours là")
