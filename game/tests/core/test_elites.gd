extends "res://tests/test_case.gd"
## Monstres élites : apparition globale toutes les 5 à 6 minutes sur une carte de leur famille,
## une seule en vie par espèce, rang d'ancienneté et bonus de butin, sauvegarde.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _maps := {}
var _world: World


func before_each() -> void:
	var cells: Array[Vector2i] = [Fixtures.center(), Fixtures.center() + Vector2i(0, 3), Fixtures.center() + Vector2i(3, 0)]
	_maps = {
		# Une carte de la famille avec un seul groupe, une autre déjà pleine (3 groupes).
		"a": Fixtures.map({cells[0]: "1"}, [{"monstres": ["mannequin"]}], {"id": "a"}),
		"b": Fixtures.map({cells[0]: "1", cells[1]: "2", cells[2]: "3"},
			[{"monstres": ["mannequin", "loup"]}, {"monstres": ["mannequin"]}, {"monstres": ["loup"]}], {"id": "b"}),
		# Pas de mannequin ici : l'élite n'y apparaît jamais.
		"c": Fixtures.map({cells[0]: "1"}, [{"monstres": ["loup"]}], {"id": "c"}),
	}
	_world = _new_world("c", ["a", "b", "c"])


func _new_world(start: String, ids: Array[String]) -> World:
	var world := World.new(_maps[start], _data(), _loader, Fixtures.character())
	world.map_ids = ids
	return world


## Données de test + « chef », l'élite des mannequins (trésor à 50 %).
func _data() -> GameData:
	var monsters := []
	for id in ["mannequin", "blinde", "loup", "archer", "rapide"]:
		monsters.append(Fixtures.monster(id, 30, 0, 0, 10, ["frappe"]))
	var chief := Fixtures.monster("chef", 60, 0, 0, 10, ["frappe"])
	chief["elite"] = true
	chief["famille"] = "mannequin"
	chief["butin"] = [{"objet": "tresor", "taux": 0.5}]
	monsters.append(chief)
	var base := Fixtures.data()
	return GameData.from_dicts(Fixtures.spells(), monsters, base.voies.values(), base.races.values(), Fixtures.items())


func _loader(map_id: String) -> GameMap:
	return _maps.get(map_id)


func _command(type: String, extra := {}) -> Array[Dictionary]:
	var command := {"type": type, "entite": World.PLAYER_ID}
	command.merge(extra, true)
	return _world.execute(command)


## Gagne le combat contre ce groupe (les autres monstres tombent, le joueur achève le dernier).
func _win_against(group_id: String) -> Array[Dictionary]:
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
	return _command(Protocol.CMD_CAST, {"sort": "frappe", "cible": last.cell})


func test_apparition_toutes_les_5_a_6_minutes_ou_que_soit_le_joueur() -> void:
	_world.update(1.0)
	_world.update(298.0)
	assert_true(_world.elite_location("chef").is_empty(), "pas avant 5 minutes")
	_world.update(62.0)
	var where := _world.elite_location("chef")
	assert_false(where.is_empty(), "apparue avant 6 minutes, alors que le joueur est sur une autre carte")
	assert_true(where["carte"] in ["a", "b"], "sur une carte de sa famille (%s)" % str(where))


func test_nouveau_groupe_ou_remplacement_selon_la_place() -> void:
	# Carte « a » : un seul groupe, l'élite arrive dans un groupe à elle.
	_world.map_ids = ["a"]
	assert_true(_world.spawn_elite("chef"))
	var states: Dictionary = _world._groups_of("a")
	assert_eq(states.size(), 2, "un groupe de plus")
	var group: Dictionary = states["elite_chef"]
	assert_eq(group["monstres"][0], "chef")
	assert_true(group["monstres"].size() <= 2)
	assert_eq(group["elite"], "chef")
	# Carte « b » : déjà 3 groupes, l'élite prend la place d'un mannequin.
	_world = _new_world("c", ["b"])
	assert_true(_world.spawn_elite("chef"))
	states = _world._groups_of("b")
	assert_eq(states.size(), 3, "pas de groupe en plus")
	var where := _world.elite_location("chef")
	var replaced: Dictionary = states[where["groupe"]]
	assert_true("chef" in replaced["monstres"], str(replaced))
	assert_true(where["groupe"] in ["groupe_1", "groupe_2"], "dans un groupe qui avait un mannequin")
	assert_true(replaced["monstres"].size() <= GameMap.MAX_GROUP_SIZE)
	# Aucune carte de sa famille : pas d'apparition.
	_world = _new_world("c", ["c"])
	assert_false(_world.spawn_elite("chef"))


func test_une_seule_en_vie_puis_retour_apres_sa_defaite() -> void:
	_world = _new_world("a", ["a"])
	assert_true(_world.spawn_elite("chef"))
	assert_false(_world.spawn_elite("chef"), "déjà en vie")
	for i in 30:
		_world.update(60.0)
	assert_eq(_world._groups_of("a").size(), 2, "toujours une seule élite")
	assert_eq(_world.elite_location("chef")["groupe"], "elite_chef")
	var events := _win_against("elite_chef")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_COMBAT_ENDED)[0]["vainqueur"], Fighter.TEAM_PLAYERS)
	assert_true(_world.elite_location("chef").is_empty(), "vaincue")
	assert_false(_world.has_entity("elite_chef"))
	_world.update(299.0)
	assert_true(_world.elite_location("chef").is_empty(), "pas de retour avant 5 minutes")
	_world.update(62.0)
	assert_false(_world.elite_location("chef").is_empty(), "de retour 5 à 6 minutes après")
	assert_true(_world._respawns.get("a", {}).is_empty(), "son groupe n'est pas un groupe de la carte à faire revenir")


func test_rang_d_anciennete_et_butin() -> void:
	_world = _new_world("a", ["a"])
	assert_true(_world.spawn_elite("chef"))
	var group: Dictionary = _world._groups_of("a")["elite_chef"]
	assert_eq(_world.elite_rank(group), 0)
	_world.clock += 3 * World.ELITE_RANK_SECONDS + 1.0
	assert_eq(_world.elite_rank(group), 3, "un rang par minute")
	_world.clock += 60 * World.ELITE_RANK_SECONDS
	assert_eq(_world.elite_rank(group), World.ELITE_MAX_RANK, "10 au plus")
	# Rang 10 : +100 % de chances de butin, le trésor à 50 % devient certain.
	_win_against("elite_chef")
	assert_eq(_world.character.inventory.quantity_of("tresor"), 1, "trésor garanti avec le bonus de l'élite")


func test_elite_sauvegardee() -> void:
	_world = _new_world("a", ["a", "b"])
	_world.map_ids = ["b"]
	assert_true(_world.spawn_elite("chef"))
	var where := _world.elite_location("chef")
	_world.clock += 4 * World.ELITE_RANK_SECONDS + 5.0
	var save: Variant = JSON.parse_string(JSON.stringify(_world.save_data()))
	var restored := World.from_save(save, _data(), _loader)
	assert_eq(where["carte"], "b")
	assert_eq(str(restored.elite_location("chef")), str(where), "même carte, même groupe")
	var group: Dictionary = restored._groups_of("b")[where["groupe"]]
	assert_true("chef" in group["monstres"])
	assert_eq(restored.elite_rank(group), 4, "l'ancienneté continue")
	# Vaincue avant la sauvegarde : la prochaine tentative reprend où elle en était.
	_world = _new_world("a", ["a"])
	_world.spawn_elite("chef")
	_win_against("elite_chef")
	_world.update(100.0)
	save = JSON.parse_string(JSON.stringify(_world.save_data()))
	restored = World.from_save(save, _data(), _loader)
	restored.map_ids = ["a"]
	restored.update(150.0)
	assert_true(restored.elite_location("chef").is_empty(), "pas encore")
	restored.update(120.0)
	assert_false(restored.elite_location("chef").is_empty(), "le délai a continué après la reprise")
