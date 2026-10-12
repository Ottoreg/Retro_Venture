extends "res://tests/test_case.gd"

var _world: World


func before_each() -> void:
	var map := GameMap.from_dict({
		"id": "test",
		"plan": [
			"@....",
			" ....",
			".....",
			" MMMM",
			".....",
		],
	})
	_world = World.new(map)


func _move(target: Variant, entity: Variant = World.PLAYER_ID) -> Array[Dictionary]:
	return _world.execute({"type": Protocol.CMD_MOVE, "entite": entity, "cible": target})


func _assert_refused(events: Array[Dictionary], reason: String) -> void:
	assert_eq(events.size(), 1)
	if events.size() == 1:
		assert_eq(events[0]["type"], Protocol.EVT_REFUSED)
		assert_eq(events[0]["raison"], reason)
	assert_eq(_world.position_of(World.PLAYER_ID), GameMap.plan_cell(0, 0), "le joueur n'a pas bougé")


func test_le_joueur_apparait_au_depart() -> void:
	assert_eq(_world.position_of(World.PLAYER_ID), GameMap.plan_cell(0, 0))


func test_deplacement_valide() -> void:
	var target := GameMap.plan_cell(0, 4)
	var events := _move(target)
	assert_eq(events.size(), 1)
	assert_eq(events[0]["type"], Protocol.EVT_MOVED)
	assert_eq(events[0]["entite"], World.PLAYER_ID)
	assert_eq(events[0]["depuis"], GameMap.plan_cell(0, 0))
	var path: Array[Vector2i] = events[0]["chemin"]
	assert_eq(path[-1], target)
	assert_eq(_world.position_of(World.PLAYER_ID), target)


func test_deplacements_refuses() -> void:
	_assert_refused(_move(GameMap.plan_cell(3, 2)), Protocol.REASON_BLOCKED)
	_assert_refused(_move(Vector2i(50, 50)), Protocol.REASON_OUT_OF_MAP)
	_assert_refused(_move(GameMap.plan_cell(4, 0)), Protocol.REASON_NO_PATH)
	_assert_refused(_move(GameMap.plan_cell(0, 0)), Protocol.REASON_ALREADY_THERE)
	_assert_refused(_move(GameMap.plan_cell(0, 1), "inconnu"), Protocol.REASON_UNKNOWN_ENTITY)
	_assert_refused(_move([1, 1]), Protocol.REASON_INVALID_COMMAND)


func test_commande_inconnue() -> void:
	_assert_refused(_world.execute({"type": "voler"}), Protocol.REASON_UNKNOWN_COMMAND)
	_assert_refused(_world.execute({}), Protocol.REASON_UNKNOWN_COMMAND)


func _move_from(target: Variant, stop: Variant) -> Array[Dictionary]:
	return _world.execute({"type": Protocol.CMD_MOVE, "entite": World.PLAYER_ID, "cible": target, "interrompre_a": stop})


func test_changer_de_destination_en_chemin() -> void:
	var first := _move(GameMap.plan_cell(0, 4))
	var first_path: Array[Vector2i] = first[0]["chemin"]
	var stop := first_path[0]
	var target := GameMap.plan_cell(2, 0)
	var events := _move_from(target, stop)
	assert_eq(events.size(), 1)
	assert_eq(events[0]["type"], Protocol.EVT_MOVED)
	assert_eq(events[0]["depuis"], stop, "repart de la case où il s'est arrêté")
	var path: Array[Vector2i] = events[0]["chemin"]
	assert_eq(path[-1], target)
	assert_eq(_world.position_of(World.PLAYER_ID), target)


func test_s_arreter_en_chemin() -> void:
	var first := _move(GameMap.plan_cell(0, 4))
	var first_path: Array[Vector2i] = first[0]["chemin"]
	var stop := first_path[0]
	var events := _move_from(stop, stop)
	assert_eq(events.size(), 1, "pas de refus « déjà sur place »")
	assert_eq(events[0]["type"], Protocol.EVT_MOVED)
	var path: Array[Vector2i] = events[0]["chemin"]
	assert_true(path.is_empty(), "il reste sur la case où il s'arrête")
	assert_eq(_world.position_of(World.PLAYER_ID), stop)


func test_interruption_hors_du_trajet_refusee() -> void:
	_assert_refused(_move_from(GameMap.plan_cell(0, 2), GameMap.plan_cell(2, 2)), Protocol.REASON_INVALID_COMMAND)
	_assert_refused(_move_from(GameMap.plan_cell(0, 2), "ici"), Protocol.REASON_INVALID_COMMAND)
