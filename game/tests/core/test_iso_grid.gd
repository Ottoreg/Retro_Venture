extends "res://tests/test_case.gd"


func test_centre_des_cases() -> void:
	assert_eq(IsoGrid.cell_to_screen(Vector2i(0, 0)), Vector2(0, 0))
	assert_eq(IsoGrid.cell_to_screen(Vector2i(1, 0)), Vector2(32, 16), "x descend vers la droite")
	assert_eq(IsoGrid.cell_to_screen(Vector2i(0, 1)), Vector2(-32, 16), "y descend vers la gauche")
	assert_eq(IsoGrid.cell_to_screen(Vector2i(3, 3)), Vector2(0, 96))


func test_aller_retour_case_ecran() -> void:
	for y in range(-3, 10):
		for x in range(-3, 10):
			var cell := Vector2i(x, y)
			assert_eq(IsoGrid.screen_to_cell(IsoGrid.cell_to_screen(cell)), cell, "case %s" % cell)


func test_point_dans_le_losange() -> void:
	# Points proches des coins du losange de la case (0, 0), mais à l'intérieur.
	for point in [Vector2(30, 0), Vector2(-30, 0), Vector2(0, 14), Vector2(0, -14), Vector2(10, 5)]:
		assert_eq(IsoGrid.screen_to_cell(point), Vector2i(0, 0), "point %s" % point)
	# Juste après le coin droit : case voisine à droite à l'écran.
	assert_eq(IsoGrid.screen_to_cell(Vector2(34, 0)), Vector2i(1, -1))
	assert_eq(IsoGrid.screen_to_cell(Vector2(0, 18)), Vector2i(1, 1))


func test_distance_et_voisins() -> void:
	assert_eq(IsoGrid.distance(Vector2i(0, 0), Vector2i(3, -2)), 5)
	var neighbors := IsoGrid.neighbors_4(Vector2i(2, 2))
	assert_eq(neighbors.size(), 4)
	for neighbor in neighbors:
		assert_eq(IsoGrid.distance(neighbor, Vector2i(2, 2)), 1)


func test_profondeur() -> void:
	assert_true(IsoGrid.depth(Vector2(2, 3)) > IsoGrid.depth(Vector2(1, 3)), "plus bas à l'écran = devant")
