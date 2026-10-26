extends "res://tests/test_case.gd"
## Copie locale de l'état côté client (`ClientState`) et connexion locale (`LocalConnection`) :
## le client lit tout dans la copie, rechargée d'après les instantanés passés par le JSON du
## protocole (GDD § 16.5, jalon M0).

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _world: World
var _connection: LocalConnection


func before_each() -> void:
	var map := Fixtures.map({Fixtures.center(): "1"}, [{"monstres": ["mannequin"]}], {"id": "test"})
	_world = World.new(map, Fixtures.data(), func(id: String) -> GameMap: return map if id == "test" else null,
		Fixtures.character())
	_world.player_voie = "test"
	_connection = LocalConnection.new(_world)


func _send(type: String, extra := {}) -> Array[Dictionary]:
	var command := {"type": type, "entite": World.PLAYER_ID}
	command.merge(extra)
	return _connection.send(command)


func test_la_copie_offre_les_lectures_du_monde() -> void:
	var copy := _connection.state
	assert_eq(copy.player_id, World.PLAYER_ID)
	assert_true(copy.character != _world.character, "une copie, pas le personnage du monde")
	assert_eq(copy.character.to_dict(), _world.character.to_dict())
	assert_eq(copy.map.id, "test")
	assert_eq(copy.position_of(World.PLAYER_ID), _world.position_of(World.PLAYER_ID))
	assert_eq(copy.groups().size(), 1)
	assert_eq(copy.group_at(Fixtures.center())["monstres"], ["mannequin"])
	assert_eq(copy.visited_maps(), _world.visited_maps())
	assert_false(copy.in_combat())
	var target := Fixtures.center() + Vector2i(1, 1)
	var events := _send(Protocol.CMD_MOVE, {"cible": target})
	assert_eq(events[0]["type"], Protocol.EVT_MOVED)
	assert_eq(typeof(events[0]["depuis"]), TYPE_VECTOR2I, "événements relus du JSON")
	assert_eq(copy.position_of(World.PLAYER_ID), target, "copie rechargée après la commande")


func test_evenements_du_temps_sans_instantane() -> void:
	_world.character.hp_lost = 4
	_connection.refresh()
	var copy := _connection.state
	var character := copy.character
	_connection.update(World.REGEN_SECONDS)
	assert_true(copy.character == character, "pas rechargée pour une régénération")
	assert_eq(copy.character.hp_lost, 3, "mais à jour")


func test_combat_recree_dans_la_copie() -> void:
	_send(Protocol.CMD_ENGAGE, {"groupe": "groupe_1"})
	_send(Protocol.CMD_READY)
	var copy := _connection.state
	assert_true(copy.in_combat())
	var hero := copy.combat.get_fighter(World.PLAYER_ID)
	var real := _world.combat.get_fighter(World.PLAYER_ID)
	for spell_id: String in ["braise", "braise", "braise", "creer"]:
		var events := _send(Protocol.CMD_CAST, {"sort": spell_id, "cible": real.cell})
		assert_true(Fixtures.of_type(events, Protocol.EVT_REFUSED).is_empty(), "%s : %s" % [spell_id, events])
	hero = copy.combat.get_fighter(World.PLAYER_ID)
	assert_eq(hero.element_states, real.element_states, "états élémentaires")
	assert_eq(hero.created_spells, real.created_spells, "sort créé")
	assert_true(hero.get_spell(real.created_spells[0]) != null, "et appris dans la copie")
	assert_eq(hero.pa, real.pa)
	assert_eq(hero.cooldown_of(hero.get_spell("creer")), real.cooldown_of(real.get_spell("creer")))
	assert_eq(copy.combat.reachable_cells(hero), _world.combat.reachable_cells(real), "déplacements possibles")
	var created := hero.get_spell(real.created_spells[0])
	assert_eq(copy.combat.spell_range(hero, created), _world.combat.spell_range(real, created), "portée du sort")
	var monster := _world.combat.fighters.filter(func(f: Fighter) -> bool: return f.team == Fighter.TEAM_MONSTERS)[0] as Fighter
	assert_eq(copy.combat.movement_zone(copy.combat.get_fighter(monster.id)), _world.combat.movement_zone(monster))
	# Un piège des monstres n'arrive jamais chez le client.
	_world.combat.traps.append({"id": 99, "lanceur": monster, "equipe": monster.team, "case": Fixtures.center(),
		"cases": [Fixtures.center()] as Array[Vector2i], "effets": [], "sort": "Piège"})
	_connection.refresh()
	assert_eq(copy.combat.traps, [], "pièges invisibles de l'autre équipe")


func test_elite_qui_vieillit_cote_client() -> void:
	var group := _world.group("groupe_1")
	group["elite"] = "mannequin"  # Une élite apparue à l'instant.
	group["apparition"] = _world.clock
	_connection.refresh()
	var copy := _connection.state
	assert_eq(copy.elite_rank(copy.group("groupe_1")), 0)
	_connection.update(3 * World.ELITE_RANK_SECONDS + 1.0)
	assert_eq(copy.elite_rank(copy.group("groupe_1")), 3, "son âge avance avec le temps du client")
	assert_eq(_world.elite_rank(group), 3, "comme dans le monde")


func test_deux_clients_sur_la_meme_carte() -> void:
	var other := Fixtures.character()
	other.display_name = "Sam"
	_world.add_player(other, "p2", "test")
	var second := LocalConnection.new(_world, "p2")
	assert_eq(second.state.player_id, "p2")
	assert_eq(second.state.character.display_name, "Sam")
	assert_eq(second.state.other_players().size(), 1)
	assert_eq(second.state.other_players()[0]["id"], World.PLAYER_ID)
	var target := Fixtures.center() + Vector2i(0, 2)
	_send(Protocol.CMD_MOVE, {"cible": target})
	second.refresh()
	assert_eq(second.state.position_of(World.PLAYER_ID), target, "le second client voit le premier bouger")
	var moved := second.send({"type": Protocol.CMD_SIT, "entite": "p2"})
	assert_eq(moved[0]["entite"], "p2")
	assert_false(_connection.state.sitting, "chacun sa copie")
	assert_true(second.state.sitting)
