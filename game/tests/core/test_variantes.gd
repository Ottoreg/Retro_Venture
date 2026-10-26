extends "res://tests/test_case.gd"
## Variantes corrompues des zones de départ : un groupe `apres_boss` n'apparaît qu'une fois ce boss
## vaincu, tout de suite sur les cartes déjà visitées, et le déblocage est sauvegardé.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _maps := {}
var _world: World


func before_each() -> void:
	var cells: Array[Vector2i] = [Fixtures.center(), Fixtures.center() + Vector2i(0, 3), Fixtures.center() + Vector2i(3, 0)]
	_maps = {
		# Le repaire du boss, avec un groupe de variantes en attente.
		"repaire": Fixtures.map({cells[0]: "1", cells[1]: "2"},
			[{"monstres": ["patron"]}, {"monstres": ["loup"], "apres_boss": "patron"}], {"id": "repaire"}),
		# Une autre carte de la zone, avec ses variantes à elle.
		"voisine": Fixtures.map({cells[0]: "1", cells[2]: "2"},
			[{"monstres": ["mannequin"]}, {"monstres": ["loup"], "apres_boss": "patron"}], {"id": "voisine"}),
	}
	_world = World.new(_maps["voisine"], _data(), _loader, Fixtures.character())


func _data() -> GameData:
	var monsters := []
	for id in ["mannequin", "loup"]:
		monsters.append(Fixtures.monster(id, 30, 0, 0, 10, ["frappe"]))
	var boss := Fixtures.monster("patron", 60, 0, 0, 10, ["frappe"])
	boss["boss"] = true
	monsters.append(boss)
	var base := Fixtures.data()
	return GameData.from_dicts(Fixtures.spells(), monsters, base.voies.values(), base.races.values(), Fixtures.items())


func _loader(map_id: String) -> GameMap:
	return _maps.get(map_id)


func _command(type: String, extra := {}) -> Array[Dictionary]:
	var command := {"type": type, "entite": World.PLAYER_ID}
	command.merge(extra, true)
	return _world.execute(command)


func _win_against(group_id: String) -> void:
	_command(Protocol.CMD_ENGAGE, {"groupe": group_id})
	var last: Fighter = null
	for fighter in _world.combat.fighters:
		if fighter.team != Fighter.TEAM_PLAYERS:
			fighter.hp = 0
			last = fighter
	last.hp = 1
	var player := _world.combat.get_fighter(World.PLAYER_ID)
	for neighbor in IsoGrid.neighbors_4(last.cell):
		if _world.combat.is_free(neighbor):
			player.cell = neighbor
			break
	_command(Protocol.CMD_READY)
	_command(Protocol.CMD_CAST, {"sort": "frappe", "cible": last.cell})
	assert_false(_world.in_combat(), "combat gagné")


func test_le_format_des_groupes_apres_boss() -> void:
	var errors := GameMap.validate({"id": "x", "plan": Fixtures.plan_with({Fixtures.center(): "1"}),
		"groupes": [{"monstres": ["loup"], "apres_boss": 3}], "placement": Fixtures.OPEN_PLACEMENT.duplicate()})
	assert_true("apres_boss" in " ".join(errors), str(errors))
	assert_eq(_maps["repaire"].groups[1]["apres_boss"], "patron")


func test_variantes_apres_le_boss() -> void:
	assert_eq(_world.groups().size(), 1, "pas de variantes avant le boss")
	_world._set_map(_world._solo(), _maps["repaire"], _maps["repaire"].spawn)
	assert_eq(_world.groups().size(), 1, "seulement le boss dans son repaire")
	_win_against("groupe_1")
	assert_true(_world.defeated_bosses.has("patron"))
	var events := _world.update(0.1)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_GROUP_RESPAWNED).size(), 1, "les variantes paraissent tout de suite")
	assert_true(_world.has_entity("groupe_2"))
	assert_true(_world._groups_of("voisine").has("groupe_2"), "et sur la carte déjà visitée")
	# Vaincues, elles reviennent comme un groupe ordinaire.
	_win_against("groupe_2")
	_world._positions[World.PLAYER_ID] = _maps["repaire"].spawn  # Le joueur quitte la case du groupe.
	_world.update(float(GameMap.DEFAULT_RESPAWN[1]) + 1.0)
	assert_true(_world.has_entity("groupe_2"), "de retour après leur délai")


func test_deblocage_sauvegarde() -> void:
	_world._set_map(_world._solo(), _maps["repaire"], _maps["repaire"].spawn)
	_win_against("groupe_1")
	var save: Variant = JSON.parse_string(JSON.stringify(_world.save_data()))
	var restored := World.from_save(save, _data(), _loader)
	assert_true(restored.defeated_bosses.has("patron"))
	# Une carte jamais visitée a ses variantes dès la première visite.
	_maps["loin"] = Fixtures.map({Fixtures.center(): "1"}, [{"monstres": ["loup"], "apres_boss": "patron"}], {"id": "loin"})
	assert_eq(restored._groups_of("loin").size(), 1)
	var fresh := World.new(_maps["loin"], _data(), _loader, Fixtures.character())
	assert_eq(fresh.groups().size(), 0, "boss jamais vaincu : rien")
