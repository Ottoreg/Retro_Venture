extends "res://tests/test_case.gd"
## Mode héros (GDD § 4.6) : plusieurs héros d'un même joueur, cachés sauf celui qu'il contrôle,
## qui le suivent partout, combattent avec lui (il les joue tous) et sont sauvegardés ensemble.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _maps := {}
var _world: World


func before_each() -> void:
	_maps = {
		"a": Fixtures.map({Fixtures.center(): "1"}, [{"monstres": ["mannequin"]}], {"id": "a", "sorties": {"droite": "b"}}),
		"b": Fixtures.map({}, [], {"id": "b", "sorties": {"gauche": "a"}}),
	}
	_world = World.new(_maps["a"], Fixtures.data(), _loader, _character("Frodon"))


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


func test_equipe_cachee_qui_suit_le_heros_controle() -> void:
	var sam := _world.add_hero(_character("Sam"))
	_world.add_hero(_character("Merry"))
	_world.add_hero(_character("Pippin"))
	assert_eq(_world.add_hero(_character("Boromir")), null, "quatre héros au plus")
	assert_eq(_world.player(World.PLAYER_ID).heroes.size(), 4)
	assert_true(sam.hidden)
	assert_eq(sam.instance.player_ids(), [World.PLAYER_ID] as Array[String], "les héros cachés ne sont pas sur la carte")
	var snapshot := _world.snapshot()
	assert_eq(snapshot["joueurs"], [], "personne d'autre à afficher")
	assert_eq(snapshot["heros"].map(func(hero: Dictionary) -> String: return hero["nom"]), ["Frodon", "Sam", "Merry", "Pippin"])
	assert_eq(_as(sam.id, Protocol.CMD_SIT, {"assis": true})[0]["type"], Protocol.EVT_REFUSED, "un héros caché ne joue pas")
	# Le héros contrôlé change de carte : les autres le suivent sur sa case.
	var border: Vector2i = _maps["a"].exit_cells()["droite"][0]
	_as(World.PLAYER_ID, Protocol.CMD_MOVE, {"cible": border, "sortie": "droite"})
	assert_eq(_world.map.id, "b")
	assert_eq(sam.map.id, "b", "le héros caché suit")
	assert_eq(sam.cell, _world.position_of(World.PLAYER_ID))
	# Contrôler Sam : il apparaît, Frodon se cache.
	var events := _as(World.PLAYER_ID, Protocol.CMD_SWITCH_HERO, {"heros": sam.id})
	assert_eq(events, [{"type": Protocol.EVT_HERO_CHANGED, "heros": sam.id, Protocol.FIELD_FOR: World.PLAYER_ID}] as Array[Dictionary])
	assert_eq(_world.player_id, sam.id, "la façade solo suit le héros contrôlé")
	assert_true(_world.player(World.PLAYER_ID).hidden)
	assert_eq(sam.instance.player_ids(), [sam.id] as Array[String])
	assert_eq(_as(sam.id, Protocol.CMD_SWITCH_HERO, {"heros": "inconnu"})[0]["type"], Protocol.EVT_REFUSED)


func test_toute_l_equipe_combat_et_partage_les_gains() -> void:
	var sam := _world.add_hero(_character("Sam"))
	_as(World.PLAYER_ID, Protocol.CMD_ENGAGE, {"groupe": "groupe_1"})
	var combat := _world.combat
	assert_eq(sam.combat, combat, "le héros caché entre dans le combat")
	assert_eq(combat.player_fighters().size(), 2)
	_as(World.PLAYER_ID, Protocol.CMD_READY)
	assert_eq(combat.state, Combat.State.FIGHTING, "« Prêt » vaut pour toute l'équipe")
	# Chaque héros joue son tour : le joueur les contrôle tous.
	var first := combat.current_fighter()
	_as(first.id, Protocol.CMD_END_TURN)
	assert_ne(combat.current_fighter().id, first.id)
	while combat.current_fighter().team != Fighter.TEAM_PLAYERS:
		_world.update(1.0)
	var player := combat.current_fighter()
	var monster := combat.get_fighter("groupe_1_1")
	for neighbor in IsoGrid.neighbors_4(monster.cell):
		if combat.is_free(neighbor):
			player.cell = neighbor
			break
	monster.hp = 1
	var events := _as(player.id, Protocol.CMD_CAST, {"sort": "frappe", "cible": monster.cell})
	assert_false(_world.in_combat())
	assert_eq(sam.combat, null)
	var ended := Fixtures.of_type(events, Protocol.EVT_COMBAT_ENDED)
	assert_eq(ended.size(), 2, "un tableau de fin par héros")
	assert_eq(ended[0]["gains"].size(), 2, "gains partagés comme en groupe")
	assert_true(sam.hidden, "toujours caché après le combat")
	assert_eq(sam.cell, _world.position_of(World.PLAYER_ID))


func test_sauvegarde_de_l_equipe() -> void:
	var sam := _world.add_hero(_character("Sam"))
	_world.add_hero(_character("Merry"))
	_as(World.PLAYER_ID, Protocol.CMD_SWITCH_HERO, {"heros": sam.id})
	var restored := World.from_save(_world.save_data(), _world.data, _loader)
	assert_eq(restored.player_name, "Sam", "le héros contrôlé")
	assert_eq(restored.snapshot()["heros"].map(func(hero: Dictionary) -> String: return hero["nom"]), ["Frodon", "Sam", "Merry"],
		"dans l'ordre de l'équipe")
	assert_eq(World.from_save(World.new(_maps["a"], Fixtures.data(), _loader).save_data(), _world.data, _loader)._solo().heroes,
		[] as Array[String], "sans héros : pas d'équipe")


func test_echange_entre_heros_sans_demande() -> void:
	var sam := _world.add_hero(_character("Sam"))
	_world.character.inventory.ecus = 50
	var opened := _as(World.PLAYER_ID, Protocol.CMD_EXCHANGE, {"action": Exchange.PROPOSE, "joueur": sam.id})
	assert_eq(opened[0]["type"], Protocol.EVT_EXCHANGE, "ouvert tout de suite, sans proposition à accepter")
	_as(World.PLAYER_ID, Protocol.CMD_EXCHANGE, {"action": Exchange.ECUS, "brumes": 30})
	_world.update(Exchange.VALIDATE_DELAY)
	_as(World.PLAYER_ID, Protocol.CMD_EXCHANGE, {"action": Exchange.VALIDATE})
	assert_eq(sam.character.inventory.ecus, 30, "une seule validation : le joueur joue les deux héros")
	assert_eq(_world.character.inventory.ecus, 20)
	assert_eq(sam.exchange, null)


func test_un_heros_recoit_tout_le_butin() -> void:
	var sam := _world.add_hero(_character("Sam"))
	assert_eq(_as(World.PLAYER_ID, Protocol.CMD_HERO_RECEIVER, {"heros": "inconnu"})[0]["type"], Protocol.EVT_REFUSED)
	_as(World.PLAYER_ID, Protocol.CMD_HERO_RECEIVER, {"heros": sam.id})
	assert_eq(_world.player(World.PLAYER_ID).hero_receiver, sam.id, "pour toute l'équipe")
	assert_eq(World.from_save(_world.save_data(), _world.data, _loader).player("heros_2").hero_receiver, "heros_2", "sauvegardé")
	var ecus := sam.character.inventory.ecus
	_as(World.PLAYER_ID, Protocol.CMD_ENGAGE, {"groupe": "groupe_1"})
	var combat := _world.combat
	_as(World.PLAYER_ID, Protocol.CMD_READY)
	while combat.current_fighter().team != Fighter.TEAM_PLAYERS:
		_world.update(1.0)
	var player := combat.current_fighter()
	var monster := combat.get_fighter("groupe_1_1")
	for neighbor in IsoGrid.neighbors_4(monster.cell):
		if combat.is_free(neighbor):
			player.cell = neighbor
			break
	monster.hp = 1
	var ended := Fixtures.of_type(_as(player.id, Protocol.CMD_CAST, {"sort": "frappe", "cible": monster.cell}), Protocol.EVT_COMBAT_ENDED)
	var gains: Dictionary = ended[0]["gains"]
	assert_eq(gains[World.PLAYER_ID]["ecus"], 0, "rien pour les autres")
	assert_eq(gains[World.PLAYER_ID]["butin"], [])
	assert_eq(sam.character.inventory.ecus - ecus, gains[sam.id]["ecus"], "tout pour Sam")
