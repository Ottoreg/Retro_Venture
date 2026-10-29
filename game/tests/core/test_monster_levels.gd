extends "res://tests/test_case.gd"
## Niveaux des monstres : tirage pondéré dans la tranche de la famille, caractéristiques selon le
## niveau (butin inchangé), élites à niveau fixe, niveaux des groupes en combat, à la réapparition
## et dans la sauvegarde.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _maps := {}


func before_each() -> void:
	var cells: Array[Vector2i] = [Fixtures.center(), Fixtures.center() + Vector2i(0, 3), Fixtures.center() + Vector2i(3, 0)]
	_maps = {
		"a": Fixtures.map({cells[0]: "1"}, [{"monstres": ["rat", "rat", "costaud"]}], {"id": "a"}),
		# Déjà 3 groupes : une élite y prend la place d'un rat.
		"b": Fixtures.map({cells[0]: "1", cells[1]: "2", cells[2]: "3"},
			[{"monstres": ["mannequin", "rat"]}, {"monstres": ["rat", "rat"]}, {"monstres": ["loup"]}], {"id": "b"}),
	}


## Données de test + « rat » (niveaux 1 à 3, surtout 1, butin incertain), « costaud » (niveaux 2
## à 4, jamais 2, un PM de plus par niveau par exception) et « chef », l'élite des rats (niveau 6,
## fixe).
static func _data() -> GameData:
	var monsters := []
	for id in ["mannequin", "loup"]:
		monsters.append(Fixtures.monster(id, 30, 0, 0, 10, ["frappe"]))
	var rat := Fixtures.monster("rat", 20, 0, 0, 10, ["frappe"], {"acier": 5})
	rat["niveau"] = 1
	rat["niveaux"] = {"min": 1, "max": 3, "poids": [6, 3, 1]}
	rat["caracteristiques"]["force"] = 10
	rat["par_niveau"] = {"pv": 5, "initiative": 10, "xp": 4, "force": 20, "agilite": 2, "resistances": {"acier": 5, "givre": -5}}
	# Taux inférieurs à 1, quantités et brumes variables : un niveau qui changerait les taux, les
	# quantités ou les brumes se verrait sur quelques combats.
	rat["butin"] = [{"objet": "dent", "taux": 0.5, "quantite": [1, 3]}, {"objet": "bague", "taux": 0.3}]
	rat["ecus"] = [1, 9]
	monsters.append(rat)
	var strong := Fixtures.monster("costaud", 40, 4, 2, 10, ["frappe"])
	strong["niveau"] = 2
	strong["niveaux"] = {"min": 2, "max": 4, "poids": [0, 1, 3]}
	strong["par_niveau"] = {"pm": 1}
	monsters.append(strong)
	var chief := Fixtures.monster("chef", 60, 0, 0, 10, ["frappe"])
	chief["niveau"] = 6
	chief["elite"] = true
	chief["famille"] = "rat"
	monsters.append(chief)
	var base := Fixtures.data()
	return GameData.from_dicts(Fixtures.spells(), monsters, base.voies.values(), base.races.values(), Fixtures.items())


func _loader(map_id: String) -> GameMap:
	return _maps.get(map_id)


func _world(start := "a") -> World:
	var world := World.new(_maps[start], _data(), _loader, Fixtures.character())
	world.map_ids = [start]
	return world


## Gagne le combat contre ce groupe (le joueur achève le dernier monstre) ; renvoie la fin du combat.
func _win_against(world: World, group_id: String) -> Dictionary:
	world.execute({"type": Protocol.CMD_ENGAGE, "entite": World.PLAYER_ID, "groupe": group_id})
	var last: Fighter = null
	for fighter in world.combat.fighters:
		if fighter.team != Fighter.TEAM_PLAYERS:
			fighter.hp = 0
			last = fighter
	last.hp = 1
	var player := world.combat.get_fighter(World.PLAYER_ID)
	for neighbor in IsoGrid.neighbors_4(last.cell):
		if world.combat.is_free(neighbor):
			player.cell = neighbor
			break
	world.execute({"type": Protocol.CMD_READY, "entite": World.PLAYER_ID})
	var events := world.execute({"type": Protocol.CMD_CAST, "entite": World.PLAYER_ID, "sort": "frappe", "cible": last.cell})
	return Fixtures.of_type(events, Protocol.EVT_COMBAT_ENDED)[0]


func _assert_levels_in_range(data: GameData, group: Dictionary, message: String) -> void:
	assert_eq(group["niveaux"].size(), group["monstres"].size(), "%s : un niveau par monstre" % message)
	for i in mini(group["niveaux"].size(), group["monstres"].size()):
		assert_true(data.is_monster_level(group["monstres"][i], group["niveaux"][i]), "%s : %s" % [message, str(group)])


func test_tirage_pondere_selon_la_famille() -> void:
	var data := _data()
	assert_eq(data.monster_level_range("rat"), Vector2i(1, 3))
	assert_eq(data.monster_level_range("chef"), Vector2i(6, 6), "élite : niveau fixe")
	assert_eq(data.monster_level_range("mannequin"), Vector2i(1, 1), "sans « niveaux » : son niveau")
	var rats := {1: 0, 2: 0, 3: 0}
	var strong := {2: 0, 3: 0, 4: 0}
	var rng := RandomNumberGenerator.new()
	var draws := 3000
	for seed_value in draws:
		rng.seed = seed_value
		rats[data.roll_monster_level("rat", rng)] += 1
		strong[data.roll_monster_level("costaud", rng)] += 1
	# Poids 6, 3 et 1 : environ 60 %, 30 % et 10 %.
	assert_almost_eq(rats[1] / float(draws), 0.6, 0.04, "rat de niveau 1 : %s" % str(rats))
	assert_almost_eq(rats[2] / float(draws), 0.3, 0.04, "rat de niveau 2 : %s" % str(rats))
	assert_almost_eq(rats[3] / float(draws), 0.1, 0.03, "rat de niveau 3 : %s" % str(rats))
	assert_eq(strong[2], 0, "poids nul : jamais tiré")
	assert_true(strong[4] > 2 * strong[3], "la famille forte tire surtout haut (%s)" % str(strong))
	assert_false(data.is_monster_level("costaud", 2), "poids nul : pas un niveau possible")
	assert_true(data.is_monster_level("costaud", 3))
	assert_false(data.is_monster_level("costaud", 5), "hors de la tranche")
	assert_true(data.is_monster_level("chef", 6))
	assert_false(data.is_monster_level("chef", 5), "élite : seulement son niveau")
	for i in 20:
		assert_eq(data.roll_monster_level("chef", rng), 6, "élite : toujours son niveau")
	assert_eq(str(data.roll_group_levels(["chef", "mannequin"], rng)), str([6, 1]))


func test_caracteristiques_selon_le_niveau() -> void:
	var data := _data()
	var base := data.create_monster("rat", "r1")
	assert_eq(base.level, 1, "-1 : niveau de base")
	assert_eq(base.max_hp, 20)
	assert_eq(base.stat("force"), 10, "Force des données")
	assert_eq(base.stat("intelligence"), 0, "0 par défaut")
	var top := data.create_monster("rat", "r3", 3)
	assert_eq(top.level, 3)
	assert_eq(top.max_hp, 30, "+5 PV par niveau")
	assert_eq(top.hp, 30, "PV au maximum")
	assert_eq(top.initiative, 30, "+10 d'initiative par niveau")
	assert_eq(top.xp, 18, "+4 XP par niveau")
	assert_eq(top.stat("force"), 50, "+20 de Force par niveau")
	assert_eq(top.stat("agilite"), 4)
	assert_eq(top.resistance("acier"), 15.0, "résistances ajoutées")
	assert_eq(top.resistance("givre"), -10.0)
	assert_eq(top.power("acier"), 50, "+1 % de dégâts d'Acier par point de Force, comme un joueur")
	assert_eq(str([top.max_pa, top.max_pm]), str([base.max_pa, base.max_pm]), "PA et PM identiques dans la famille")
	assert_eq(top.to_dict()["niveau"], 3, "niveau envoyé au client")
	assert_eq(data.create_monster("rat", "r9", 9).level, 3, "ramené dans la tranche")
	assert_eq(data.create_monster("chef", "c", 2).level, 6, "élite : niveau fixe")
	# Exception déclarée : le costaud gagne un PM par niveau.
	var strong := data.create_monster("costaud", "s", 4)
	assert_eq(strong.max_pm, 4)
	assert_eq(strong.pm, 4)
	assert_eq(strong.max_pa, 4, "PA inchangés")


func test_la_force_du_monstre_augmente_ses_degats() -> void:
	var data := _data()
	var rat := data.create_monster("rat", "r", 3)
	var player := data.create_player("test", Fixtures.PLAYER, "Testeur")
	var fighters: Array[Fighter] = [player, rat]
	var combat := Combat.new(Fixtures.map(), fighters, [Fixtures.center()] as Array[Vector2i], 1)
	var events: Array[Dictionary] = []
	combat._apply_effect(rat, player, {"type": Spell.EFFECT_DAMAGE, "element": "acier", "min": 10, "max": 10}, events)
	assert_eq(events[0]["valeur"], 15, "10 dégâts d'Acier, +50 % avec 50 de Force")


func test_le_combat_cree_chaque_monstre_a_son_niveau() -> void:
	var world := _world()
	var group: Dictionary = world.group("groupe_1")
	_assert_levels_in_range(world.data, group, "groupe composé")
	group["niveaux"] = [3, 1, 4]
	var events := world.execute({"type": Protocol.CMD_ENGAGE, "entite": World.PLAYER_ID, "groupe": "groupe_1"})
	var foes: Array[Fighter] = []
	for fighter in world.combat.fighters:
		if fighter.team != Fighter.TEAM_PLAYERS:
			foes.append(fighter)
	assert_eq(foes.size(), 3)
	assert_eq(str([foes[0].level, foes[1].level, foes[2].level]), str([3, 1, 4]), "dans l'ordre du groupe")
	assert_eq(str([foes[0].max_hp, foes[1].max_hp]), str([30, 20]))
	var player := world.combat.get_fighter(World.PLAYER_ID)
	assert_eq(player.level, 0, "un joueur n'a pas de niveau")
	var started := Fixtures.of_type(events, Protocol.EVT_COMBAT_STARTED)[0]
	var shown := {}
	for snapshot: Dictionary in started["combattants"]:
		shown[snapshot["id"]] = snapshot["niveau"]
	assert_eq(shown[foes[2].id], 4, "niveau de chaque combattant dans l'événement")


func test_le_butin_ne_depend_pas_du_niveau() -> void:
	# Mêmes combats (même graine, donc même tirage), seul le niveau du rat change. Son butin est
	# incertain (voir `_data`) : sur plusieurs combats, un taux, une quantité ou des brumes qui
	# dépendraient du niveau changeraient le résultat d'au moins l'un d'eux.
	var outcomes := {}
	for attempt in 12:
		var results := []
		for level in [1, 3]:
			_maps["a"] = Fixtures.map({Fixtures.center(): "1"}, [{"monstres": ["rat"]}], {"id": "a"})
			var world := _world()
			world.group("groupe_1")["niveaux"] = [level]
			world._combat_count = attempt  # Graine du combat, qui tire aussi le butin.
			var ended := _win_against(world, "groupe_1")
			results.append(ended)
			assert_eq(ended["vainqueur"], Fighter.TEAM_PLAYERS)
		var label := "combat %d" % attempt
		assert_eq(str(results[1]["butin"]), str(results[0]["butin"]), "%s : même butin au niveau 3 qu'au niveau 1" % label)
		assert_eq(results[1]["ecus"], results[0]["ecus"], "%s : mêmes brumes" % label)
		assert_true(int(results[1]["xp"]) > int(results[0]["xp"]), "%s : mais plus d'XP" % label)
		outcomes[str([results[0]["butin"], results[0]["ecus"]])] = true
	assert_true(outcomes.size() >= 6, "butin et brumes varient d'un combat à l'autre (%d résultats différents)" % outcomes.size())


func test_les_elites_gardent_leur_niveau_fixe() -> void:
	var data := _data()
	var chief: Dictionary = data.monsters["chef"].duplicate(true)
	chief["niveaux"] = {"min": 6, "max": 8, "poids": [1, 1, 1]}
	var errors := GameData.validate_monster(chief, data.spells, data.items)
	assert_true("niveau fixe" in "; ".join(errors), "élite : « niveaux » refusé (%s)" % str(errors))
	# Nouveau groupe : l'élite à son niveau, le rat qui l'accompagne parfois dans sa tranche.
	for attempt in 6:
		var world := _world()
		assert_true(world.spawn_elite("chef"))
		var group: Dictionary = world.group("elite_chef")
		assert_eq(group["niveaux"][0], 6)
		_assert_levels_in_range(world.data, group, "groupe de l'élite")
	# Carte pleine : l'élite prend la place d'un rat et son niveau ; les autres gardent le leur.
	var world := _world("b")
	var before := {}
	for group: Dictionary in world.groups():
		before[group["id"]] = group["niveaux"].duplicate()
	var spawned: Array[Dictionary] = []
	assert_true(world.spawn_elite("chef", spawned))
	var replaced: Dictionary = world.group(world.elite_location("chef")["groupe"])
	var slot: int = replaced["monstres"].find("chef")
	assert_eq(replaced["niveaux"][slot], 6)
	for i in replaced["monstres"].size():
		if i != slot:
			assert_eq(replaced["niveaux"][i], before[replaced["id"]][i], "les autres gardent leur niveau")
	assert_eq(str(spawned[0]["groupe"]["niveaux"]), str(replaced["niveaux"]), "niveaux dans l'événement")


func test_la_reapparition_tire_de_nouveaux_niveaux() -> void:
	var world := _world()
	_win_against(world, "groupe_1")
	assert_true(world.group("groupe_1").is_empty(), "vaincu")
	world.execute({"type": Protocol.CMD_MOVE, "entite": World.PLAYER_ID, "cible": GameMap.plan_cell(0, 0)})
	var events := world.update(GameMap.DEFAULT_RESPAWN[1] + 1.0)
	var respawned := Fixtures.of_type(events, Protocol.EVT_GROUP_RESPAWNED)
	assert_eq(respawned.size(), 1)
	_assert_levels_in_range(world.data, respawned[0]["groupe"], "groupe réapparu")
	assert_eq(str(world.group("groupe_1")["niveaux"]), str(respawned[0]["groupe"]["niveaux"]))


func test_niveaux_sauvegardes_et_restaures() -> void:
	var world := _world()
	world.group("groupe_1")["niveaux"] = [3, 2, 4]
	var save: Dictionary = JSON.parse_string(JSON.stringify(world.save_data()))
	var restored := World.from_save(save, _data(), _loader)
	assert_eq(str(restored.group("groupe_1")["niveaux"]), str([3, 2, 4]), "mêmes niveaux après la reprise")
	# Vieille sauvegarde, sans niveaux : on les tire à nouveau.
	var entry: Dictionary = save["groupes_restants"]["a"][0]
	entry.erase("niveaux")
	restored = World.from_save(save, _data(), _loader)
	assert_eq(str(restored.group("groupe_1")["monstres"]), str(["rat", "rat", "costaud"]), "même composition")
	_assert_levels_in_range(restored.data, restored.group("groupe_1"), "niveaux tirés à nouveau")
	# Niveaux hors tranche (données changées depuis) : tirés à nouveau, les bons sont gardés.
	entry["niveaux"] = [9, 2, 2.5]
	restored = World.from_save(save, _data(), _loader)
	var levels: Array = restored.group("groupe_1")["niveaux"]
	assert_eq(levels[1], 2, "niveau valable gardé")
	assert_true(levels[0] in [1, 2, 3], "rat : %s" % str(levels))
	assert_true(levels[2] in [3, 4], "costaud : jamais 2 (poids nul) : %s" % str(levels))
	# Niveau de la tranche mais de poids nul (poids changés depuis) : il ne peut plus être tiré, on le
	# tire à nouveau.
	entry["niveaux"] = [1, 3, 2]
	restored = World.from_save(save, _data(), _loader)
	levels = restored.group("groupe_1")["niveaux"]
	assert_eq(str(levels.slice(0, 2)), str([1, 3]), "niveaux possibles gardés")
	assert_true(levels[2] in [3, 4], "costaud de niveau 2 (poids nul) : tiré à nouveau : %s" % str(levels))
	# Élite apparue en plus des groupes de la carte, dans une vieille sauvegarde sans niveaux : l'élite
	# reprend son niveau fixe, le rat qui l'accompagne un niveau de sa tranche.
	world = _world()
	assert_true(world.spawn_elite("chef"))
	save = JSON.parse_string(JSON.stringify(world.save_data()))
	var elite_entry: Dictionary = {}
	for saved_group: Dictionary in save["groupes_restants"]["a"]:
		if saved_group["id"] == "elite_chef":
			elite_entry = saved_group
	assert_eq(elite_entry.get("elite", ""), "chef", "groupe de l'élite sauvegardé")
	elite_entry["monstres"] = ["chef", "rat"]  # Toujours avec un rat (une fois sur deux d'habitude).
	elite_entry.erase("niveaux")
	restored = World.from_save(save, _data(), _loader)
	var elite_group: Dictionary = restored.group("elite_chef")
	assert_eq(elite_group.get("elite", ""), "chef", "élite restaurée")
	assert_eq(str(elite_group.get("monstres")), str(["chef", "rat"]))
	assert_eq(elite_group["niveaux"][0], 6, "élite : son niveau fixe")
	_assert_levels_in_range(restored.data, elite_group, "groupe de l'élite restauré")


func test_erreurs_de_validation_des_niveaux() -> void:
	var data := _data()
	var cases := [
		[{"niveau": 0}, "« niveau »"],
		[{"niveaux": {"min": 2, "max": 3, "poids": [1, 1]}}, "égal à « niveau »"],
		[{"niveaux": {"min": 1, "max": 3, "poids": [1, 1]}}, "poids"],
		[{"niveaux": {"min": 1, "max": 3, "poids": [0, 0, 0]}}, "poids"],
		[{"niveaux": {"min": 1, "max": 2, "poids": [1, -1]}}, "poids"],
		[{"niveaux": {"min": 3, "max": 1, "poids": [1]}}, "min ≤ max"],
		[{"niveaux": [1, 3]}, "{ min, max, poids }"],
		[{"par_niveau": {"pv": -2}}, "par_niveau"],
		[{"par_niveau": {"vitalite": 2}}, "par_niveau"],
		[{"par_niveau": {"resistances": {"bois": 2}}}, "résistance invalide"],
		[{"par_niveau": 3}, "« par_niveau »"],
		[{"caracteristiques": {"pv": 10, "pa": 6, "pm": 3, "force": -5}}, "caracteristiques.force"],
		[{"boss": "oui"}, "« boss »"],
		[{"boss": true, "famille": "rat"}, "unique"],
		[{"boss": true, "niveaux": {"min": 1, "max": 2, "poids": [1, 1]}}, "niveau fixe"],
	]
	for case: Array in cases:
		var monster := Fixtures.monster("essai", 20, 6, 3, 10, ["frappe"])
		monster["niveau"] = 1
		monster.merge(case[0], true)
		var errors := "; ".join(GameData.validate_monster(monster, data.spells, data.items))
		assert_true(errors.contains(case[1]), "%s : « %s » attendu dans « %s »" % [str(case[0]), case[1], errors])
	var valid := Fixtures.monster("essai", 20, 6, 3, 10, ["frappe"])
	valid.merge({"niveau": 2, "niveaux": {"min": 2, "max": 4, "poids": [5, 0, 1]}, "boss": false,
		"caracteristiques": {"pv": 10, "pa": 6, "pm": 3, "perception": 4},
		"par_niveau": {"pv": 2, "pa": 1, "resistances": {"impie": -3}}}, true)
	assert_eq(GameData.validate_monster(valid, data.spells, data.items).size(), 0, "monstre valide")
