extends "res://tests/test_case.gd"

## Carte 5×5 coupée par un mur en x = 2, avec un passage en (2, 4).
var _data: Dictionary


func before_each() -> void:
	_data = {
		"id": "test",
		"nom": "Carte de test",
		"largeur": 5,
		"hauteur": 5,
		"depart": [0, 0],
		"obstacles": {"mur": [[2, 0], [2, 1], [2, 2], [2, 3]]},
	}


func test_carte_valide() -> void:
	assert_eq(GameMap.validate(_data).size(), 0)
	var map := GameMap.from_dict(_data)
	assert_eq(map.id, "test")
	assert_eq(map.display_name, "Carte de test")
	assert_eq(map.size, Vector2i(5, 5))
	assert_eq(map.spawn, Vector2i(0, 0))
	assert_eq(map.obstacles.size(), 4)


func test_validation_des_erreurs() -> void:
	var cases := {
		"id manquant": {"id": ""},
		"largeur nulle": {"largeur": 0},
		"hauteur absente": {"hauteur": null},
		"départ hors carte": {"depart": [9, 9]},
		"départ sur obstacle": {"depart": [2, 0]},
		"départ mal formé": {"depart": [1]},
		"obstacle hors carte": {"obstacles": {"arbre": [[7, 1]]}},
		"obstacle en double": {"obstacles": {"arbre": [[1, 1]], "rocher": [[1, 1]]}},
		"obstacles mal formés": {"obstacles": [[1, 1]]},
	}
	for label: String in cases:
		var data := _data.duplicate(true)
		data.merge(cases[label], true)
		assert_true(GameMap.validate(data).size() > 0, label)


func test_cases_praticables() -> void:
	var map := GameMap.from_dict(_data)
	assert_true(map.is_walkable(Vector2i(0, 0)))
	assert_false(map.is_walkable(Vector2i(2, 1)), "mur")
	assert_false(map.is_walkable(Vector2i(-1, 0)), "hors carte")
	assert_false(map.is_walkable(Vector2i(5, 0)), "hors carte")


func test_chemin_de_combat_contourne_le_mur() -> void:
	var map := GameMap.from_dict(_data)
	var path := map.find_path(Vector2i(0, 0), Vector2i(4, 0), true)
	# Descendre de 4, traverser de 4, remonter de 4.
	assert_eq(path.size(), 12)
	assert_eq(path[-1], Vector2i(4, 0))
	var previous := Vector2i(0, 0)
	for cell in path:
		assert_eq(IsoGrid.distance(previous, cell), 1, "pas de %s à %s" % [previous, cell])
		assert_true(map.is_walkable(cell), "case %s praticable" % cell)
		previous = cell


func test_chemin_d_exploration_en_diagonale() -> void:
	_data["obstacles"] = {}
	var map := GameMap.from_dict(_data)
	assert_eq(map.find_path(Vector2i(0, 0), Vector2i(3, 3)).size(), 3, "exploration : 8 directions")
	assert_eq(map.find_path(Vector2i(0, 0), Vector2i(3, 3), true).size(), 6, "combat : 4 directions")


func test_pas_de_coin_coupe() -> void:
	_data["obstacles"] = {"rocher": [[1, 0]]}
	var map := GameMap.from_dict(_data)
	var path := map.find_path(Vector2i(0, 0), Vector2i(1, 1))
	assert_eq(path, [Vector2i(0, 1), Vector2i(1, 1)] as Array[Vector2i])


func test_chemin_impossible() -> void:
	var map := GameMap.from_dict(_data)
	assert_eq(map.find_path(Vector2i(0, 0), Vector2i(2, 2)).size(), 0, "cible bloquée")
	assert_eq(map.find_path(Vector2i(0, 0), Vector2i(0, 0)).size(), 0, "déjà sur place")
	assert_eq(map.find_path(Vector2i(0, 0), Vector2i(9, 9)).size(), 0, "hors carte")
	_data["obstacles"]["mur"].append([2, 4])
	var closed := GameMap.from_dict(_data)
	assert_eq(closed.find_path(Vector2i(0, 0), Vector2i(4, 0)).size(), 0, "zone fermée")
