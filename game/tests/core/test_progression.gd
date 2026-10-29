extends "res://tests/test_case.gd"
## Réputation après les combats, maîtrise des sorts, changement de classe et sauvegarde du monde.

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


func test_reputation_apres_victoire() -> void:
	var world := _world()
	var events := _win_against(world, "groupe_1")
	var gains := Fixtures.of_type(events, Protocol.EVT_REPUTATION)
	assert_eq(gains.size(), 1)
	# Niveau 1 contre un monstre de niveau 1 : facteur 0,5 ; une Frappe à 3 PA (2 de réputation par PA)
	# et un quart des 10 XP du mannequin.
	assert_eq(Fixtures.of_type(events, Protocol.EVT_COMBAT_ENDED)[0]["difficulte"], 0.5)
	assert_eq(gains[0]["gain"], roundi(3 * Progression.REPUTATION_PER_PA * 0.5 + 10 * Progression.KILL_SHARE * 0.5))
	assert_eq(gains[0]["voie"], "test", "réputation de la classe active")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_COMBAT_ENDED)[0]["reputation"], gains[0]["gain"], "affichée en fin de combat")
	assert_eq(world.character.reputation(), gains[0]["gain"])
	world.character.add_reputation(999 - world.character.reputation())
	var more := _win_against(world, "groupe_2")
	var tiers := Fixtures.of_type(more, Protocol.EVT_REPUTATION_TIER)
	assert_eq(tiers.size(), 1, "1 000 de réputation : palier Apprenti")
	assert_eq(tiers[0]["nom"], "Apprenti")
	assert_eq(tiers[0]["points"], 2, "points de maîtrise à placer")
	assert_eq(Fixtures.of_type(more, Protocol.EVT_CHARACTER)[0]["personnage"]["palier_nom"], "Apprenti")


func test_maitriser_un_sort() -> void:
	var world := _world()
	var refused := world.execute({"type": Protocol.CMD_RAISE_SPELL, "entite": World.PLAYER_ID, "sort": "frappe"})
	assert_eq(refused[0]["raison"], Protocol.REASON_NOT_ENOUGH_POINTS)
	world.character.add_reputation(Character.REPUTATION_PER_MASTERY_POINT)
	var events := world.execute({"type": Protocol.CMD_RAISE_SPELL, "entite": World.PLAYER_ID, "sort": "frappe"})
	assert_eq(events[0]["type"], Protocol.EVT_CHARACTER)
	assert_eq(events[0]["personnage"]["maitrises"], {"frappe": 1})
	var unknown := world.execute({"type": Protocol.CMD_RAISE_SPELL, "entite": World.PLAYER_ID, "sort": "inconnu"})
	assert_eq(unknown[0]["raison"], Protocol.REASON_INVALID_COMMAND)


func test_changer_de_classe_hors_combat() -> void:
	var world := _world()
	var other: Dictionary = world.data.voies["test"].duplicate(true)
	other["id"] = "autre"
	other["nom"] = "Autre"
	world.data.voies["autre"] = other
	var command := {"type": Protocol.CMD_SWITCH_CLASS, "entite": World.PLAYER_ID, "voie": "autre"}
	assert_eq(world.execute(command)[0]["raison"], Protocol.REASON_REPUTATION_TOO_LOW)
	world.character.add_reputation(Character.NEW_CLASS_REPUTATION)
	var items := world.character.inventory.entries.size()
	var events := world.execute(command)
	assert_eq(events[0]["type"], Protocol.EVT_CLASS_SWITCHED)
	assert_eq(world.character.voie_id, "autre")
	assert_true(world.character.inventory.entries.size() > items, "équipement de départ de la nouvelle classe, dans le sac")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_CHARACTER)[0]["personnage"]["voie"], "autre")
	var unknown := world.execute({"type": Protocol.CMD_SWITCH_CLASS, "entite": World.PLAYER_ID, "voie": "inconnue"})
	assert_eq(unknown[0]["raison"], Protocol.REASON_INVALID_COMMAND)
	# En combat : refusé (seules les commandes de combat passent).
	world.execute({"type": Protocol.CMD_ENGAGE, "entite": World.PLAYER_ID, "groupe": "groupe_1"})
	var back := world.execute({"type": Protocol.CMD_SWITCH_CLASS, "entite": World.PLAYER_ID, "voie": "test"})
	assert_eq(back[0]["type"], Protocol.EVT_REFUSED)
	assert_eq(world.character.voie_id, "autre")


func test_sauvegarde_et_reprise() -> void:
	var world := _world()
	_win_against(world, "groupe_1")
	world.character.add_reputation(500)
	world.character.gain_stat("perception", 5)
	var position := world.position_of(World.PLAYER_ID)
	var save: Variant = JSON.parse_string(JSON.stringify(world.save_data()))
	assert_true(typeof(save) == TYPE_DICTIONARY, "sauvegarde sérialisable en JSON")

	var restored := World.from_save(save, Fixtures.data(), _loader)
	assert_true(restored != null, "monde restauré")
	assert_eq(restored.map.id, "est")
	assert_eq(restored.position_of(World.PLAYER_ID), position)
	assert_eq(JSON.stringify(restored.character.to_dict()), JSON.stringify(world.character.to_dict()))
	assert_eq(restored.groups().size(), 1, "le groupe vaincu ne revient pas")
	assert_eq(restored.groups()[0]["id"], "groupe_2")


func test_sauvegardes_invalides() -> void:
	assert_true(World.from_save({}, Fixtures.data(), _loader) == null, "vide")
	var save := _world().save_data()
	save["carte"] = "disparue"
	assert_true(World.from_save(save, Fixtures.data(), _loader) == null, "carte inconnue")
	var no_loader := _world().save_data()
	assert_true(World.from_save(no_loader, Fixtures.data(), Callable()) == null, "sans chargeur de cartes")
