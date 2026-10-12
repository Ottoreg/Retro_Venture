extends "res://tests/test_case.gd"

## Carte 5 colonnes × 6 rangées. La 3e ligne est un mur percé d'un passage à droite.
var _data: Dictionary


func before_each() -> void:
	_data = {
		"id": "test",
		"nom": "Carte de test",
		"plan": [
			"@....",
			" ....",
			"MMMM.",
			" ....",
			"R....",
		],
	}


func _map() -> GameMap:
	assert_eq(GameMap.validate(_data).size(), 0, "plan de test valide")
	return GameMap.from_dict(_data)


func test_carte_valide() -> void:
	var map := _map()
	assert_eq(map.id, "test")
	assert_eq(map.display_name, "Carte de test")
	assert_eq(map.columns, 5)
	assert_eq(map.rows, 6)
	assert_eq(map.spawn, GameMap.plan_cell(0, 0))
	assert_eq(map.screen_rect(), Rect2(0, 0, 320, 96))
	# 3 lignes de 5 cases + 2 lignes décalées de 4 cases.
	assert_eq(map.cells().size(), 23)
	assert_eq(map.obstacles.size(), 5)
	assert_eq(map.obstacles[GameMap.plan_cell(4, 0)], "rocher")


func test_cases_du_plan_a_l_ecran() -> void:
	var map := _map()
	assert_eq(IsoGrid.cell_to_screen(GameMap.plan_cell(0, 0)), Vector2(32, 16), "1re case, 1re ligne")
	assert_eq(IsoGrid.cell_to_screen(GameMap.plan_cell(1, 1)), Vector2(64, 32), "ligne décalée")
	for cell: Vector2i in map.cells():
		assert_true(map.screen_rect().has_point(IsoGrid.cell_to_screen(cell)), "case %s dans le cadre" % cell)


func test_le_cadre_est_entierement_couvert() -> void:
	var map := _map()
	var known := {}
	for cell: Vector2i in map.cells():
		known[cell] = true
	for cell in map.border_cells():
		assert_false(known.has(cell), "une demi-case de bord n'est pas jouable")
		known[cell] = true
	var rect := map.screen_rect()
	for y in range(1, int(rect.size.y), 3):
		for x in range(1, int(rect.size.x), 3):
			var cell := IsoGrid.screen_to_cell(Vector2(x, y))
			assert_true(known.has(cell), "point (%d, %d) couvert" % [x, y])


func test_validation_des_erreurs() -> void:
	var cases := {
		"id manquant": {"id": ""},
		"plan absent": {"plan": null},
		"nombre de lignes pair": {"plan": ["@....", " ....", ".....", " ...."]},
		"ligne trop courte": {"plan": ["@....", " ...", "....."]},
		"ligne décalée sans espace": {"plan": ["@....", ".....", "....."]},
		"caractère inconnu": {"plan": ["@...?", " ....", "....."]},
		"pas de départ": {"plan": [".....", " ....", "....."]},
		"deux départs": {"plan": ["@...@", " ....", "....."]},
		"ligne qui n'est pas du texte": {"plan": ["@....", 3, "....."]},
	}
	for label: String in cases:
		var data := _data.duplicate(true)
		data.merge(cases[label], true)
		assert_true(GameMap.validate(data).size() > 0, label)


func test_cases_praticables() -> void:
	var map := _map()
	assert_true(map.is_walkable(GameMap.plan_cell(0, 0)))
	assert_false(map.is_walkable(GameMap.plan_cell(2, 1)), "mur")
	assert_false(map.is_walkable(map.border_cells()[0]), "demi-case du bord")
	assert_false(map.is_walkable(Vector2i(50, 50)), "hors carte")


func test_chemin_de_combat_par_le_passage() -> void:
	var map := _map()
	var target := GameMap.plan_cell(4, 1)
	var path := map.find_path(map.spawn, target, true)
	assert_true(path.size() > 0, "chemin trouvé")
	assert_eq(path[-1], target)
	assert_true(GameMap.plan_cell(2, 4) in path, "passe par l'ouverture du mur")
	var previous := map.spawn
	for cell in path:
		assert_eq(IsoGrid.distance(previous, cell), 1, "pas de %s à %s" % [previous, cell])
		assert_true(map.is_walkable(cell), "case %s praticable" % cell)
		previous = cell


func test_exploration_plus_courte_qu_en_combat() -> void:
	var map := _map()
	var from := GameMap.plan_cell(4, 1)
	var to := GameMap.plan_cell(4, 2)
	# Case voisine sur la même ligne : un pas « horizontal » en exploration, deux en combat.
	assert_eq(map.find_path(from, to).size(), 1)
	assert_eq(map.find_path(from, to, true).size(), 2)


func test_pas_de_passage_entre_deux_pointes() -> void:
	var from := GameMap.plan_cell(2, 1)
	var to := GameMap.plan_cell(2, 2)
	_data["plan"] = ["@....", " .R..", ".....", " ....", "....."]
	assert_eq(_map().find_path(from, to).size(), 1, "longe la pointe d'un seul rocher")
	_data["plan"][3] = " .R.."
	assert_true(_map().find_path(from, to).size() != 1, "ne passe pas entre deux rochers qui se touchent")


func test_chemin_impossible() -> void:
	var map := _map()
	assert_eq(map.find_path(map.spawn, GameMap.plan_cell(2, 1)).size(), 0, "cible bloquée")
	assert_eq(map.find_path(map.spawn, map.spawn).size(), 0, "déjà sur place")
	assert_eq(map.find_path(map.spawn, map.border_cells()[0]).size(), 0, "demi-case du bord")
	_data["plan"][2] = "MMMMM"
	var closed := _map()
	assert_eq(closed.find_path(closed.spawn, GameMap.plan_cell(4, 1)).size(), 0, "mur fermé")
