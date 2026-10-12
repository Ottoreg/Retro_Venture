extends "res://tests/test_case.gd"
## Pierres de Passage : on voyage de l'une à l'autre, entre des cartes qui ne sont pas reliées.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _maps := {}
var _world: World
var _stone := Fixtures.center()


func before_each() -> void:
	_maps = {}
	for map_id in ["a", "b", "c"]:
		_maps[map_id] = Fixtures.map({Fixtures.center(): "*"}, [], {"id": map_id})
	var passages := [
		{"id": "pierre_a", "nom": "A", "carte": "a"},
		{"id": "pierre_b", "nom": "B", "carte": "b"},
		{"id": "pierre_c", "nom": "C", "carte": "c"},
	]
	var data := GameData.from_dicts(Fixtures.spells(), [], [], [], [], [], passages)
	_world = World.new(_maps["a"], data, _loader, Fixtures.character())


func _loader(map_id: String) -> GameMap:
	return _maps.get(map_id)


func _command(type: String, extra := {}) -> Array[Dictionary]:
	var command := {"type": type, "entite": World.PLAYER_ID}
	command.merge(extra, true)
	return _world.execute(command)


func _go_next_to_stone() -> void:
	var path := _world.map.approach_path(_world.position_of(World.PLAYER_ID), _stone)
	if not path.is_empty():
		_command(Protocol.CMD_MOVE, {"cible": path[-1]})


func _assert_refused(events: Array[Dictionary], reason: String, message := "") -> void:
	assert_eq(events.size(), 1, message)
	assert_eq(events[0]["type"], Protocol.EVT_REFUSED, message)
	assert_eq(events[0].get("raison"), reason, message)


func test_la_pierre_sur_la_carte() -> void:
	var map: GameMap = _maps["a"]
	assert_eq(map.travel_stone(), _stone)
	assert_false(map.is_walkable(_stone), "la pierre bloque sa case")
	var beside := map.beside(_stone)
	assert_true(map.is_walkable(beside) and GameMap.is_adjacent(beside, _stone), "case d'arrivée à côté de la pierre")
	assert_eq(Fixtures.map().travel_stone(), Vector2i(-1, -1), "pas de pierre")


func test_menu_de_la_pierre() -> void:
	_assert_refused(_command(Protocol.CMD_USE, {"case": _stone}), Protocol.REASON_TOO_FAR)
	_go_next_to_stone()
	var events := _command(Protocol.CMD_USE, {"case": _stone})
	assert_eq(events[0]["type"], Protocol.EVT_TRAVEL_MENU)
	assert_eq(events[0]["ici"], "pierre_a")
	assert_eq(events[0]["destinations"].size(), 3)


func test_voyager() -> void:
	_go_next_to_stone()
	var events := _command(Protocol.CMD_TRAVEL, {"case": _stone, "destination": "pierre_c"})
	assert_eq(events[0]["type"], Protocol.EVT_MAP_CHANGED)
	assert_eq(_world.map.id, "c")
	var arrival := _world.position_of(World.PLAYER_ID)
	assert_true(GameMap.is_adjacent(arrival, _world.map.travel_stone()), "on arrive à côté de la pierre")
	# Et retour.
	assert_eq(_command(Protocol.CMD_TRAVEL, {"case": _stone, "destination": "pierre_a"})[0]["type"], Protocol.EVT_MAP_CHANGED)
	assert_eq(_world.map.id, "a")


func test_voyages_refuses() -> void:
	_assert_refused(_command(Protocol.CMD_TRAVEL, {"case": _stone, "destination": "pierre_b"}), Protocol.REASON_TOO_FAR)
	_go_next_to_stone()
	_assert_refused(_command(Protocol.CMD_TRAVEL, {"case": _stone, "destination": "pierre_a"}), Protocol.REASON_ALREADY_THERE)
	_assert_refused(_command(Protocol.CMD_TRAVEL, {"case": _stone, "destination": "nulle_part"}), Protocol.REASON_UNKNOWN_ENTITY)
	_assert_refused(_command(Protocol.CMD_TRAVEL, {"case": _stone, "destination": 3}), Protocol.REASON_INVALID_COMMAND)
	_assert_refused(_command(Protocol.CMD_TRAVEL, {"case": GameMap.plan_cell(1, 1), "destination": "pierre_b"}), Protocol.REASON_UNKNOWN_ENTITY, "pas une pierre")
	assert_eq(_world.map.id, "a", "on n'a pas bougé")
	assert_false(GameData.validate_passage({"id": "x", "nom": "X"}).is_empty(), "il faut une carte")
