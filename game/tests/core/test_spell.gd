extends "res://tests/test_case.gd"

const Fixtures := preload("res://tests/helpers/fixtures.gd")


func _valid() -> Dictionary:
	return Fixtures.spells()[0].duplicate(true)


func test_sorts_de_test_valides() -> void:
	for data: Dictionary in Fixtures.spells():
		assert_eq(Spell.validate(data).size(), 0, "sort %s" % data["id"])


func test_lecture() -> void:
	var spell := Spell.from_dict(_valid())
	assert_eq(spell.id, "frappe")
	assert_eq(spell.pa_cost, 3)
	assert_eq(spell.range_min, 1)
	assert_eq(spell.range_max, 1)
	assert_true(spell.needs_line_of_sight, "ligne de vue par défaut")
	assert_eq(spell.casts_per_turn, 2)
	assert_eq(spell.cooldown, 0)
	assert_true(spell.deals_damage())
	assert_eq(spell.max_damage(), 10)


func test_erreurs() -> void:
	var cases := {
		"coût absent": {"cout_pa": null},
		"coût négatif": {"cout_pa": -1},
		"portée inversée": {"portee": {"min": 3, "max": 1}},
		"zone inconnue": {"zone": {"type": "ligne"}},
		"cercle sans taille": {"zone": {"type": "cercle"}},
		"croix sans lancer en ligne": {"zone": {"type": "croix_latine"}},
		"cibles inconnues": {"effets": [{"type": "degats", "element": "acier", "min": 1, "max": 2, "cibles": "amis"}]},
		"aucun effet": {"effets": []},
		"effet inconnu": {"effets": [{"type": "poison", "min": 1, "max": 2}]},
		"dégâts sans élément": {"effets": [{"type": "degats", "min": 1, "max": 2}]},
		"min supérieur à max": {"effets": [{"type": "soin", "min": 5, "max": 2}]},
		"relance négative": {"relance": {"par_tour": -1}},
	}
	for label: String in cases:
		var data := _valid()
		data.merge(cases[label], true)
		assert_true(Spell.validate(data).size() > 0, label)


func test_zones() -> void:
	var single := Spell.from_dict(_valid())
	assert_eq(single.zone_cells(Vector2i(2, 2)), [Vector2i(2, 2)] as Array[Vector2i])
	var circle := Spell.from_dict(Fixtures.spells()[3])
	var cells := circle.zone_cells(Vector2i(0, 0))
	assert_eq(cells.size(), 5, "cercle de taille 1 : la case et ses 4 voisines")
	for cell in cells:
		assert_true(IsoGrid.distance(cell, Vector2i.ZERO) <= 1)


func test_croix_latine() -> void:
	var cross := Spell.from_dict(Fixtures.spells()[8])
	assert_eq(cross.zone_type, Spell.ZONE_LATIN_CROSS)
	assert_true(cross.cast_in_line)
	# Lancer vers +x depuis (0, 0) sur (2, 0) : (2..5, 0) en ligne, et (3, ±1) de chaque côté de la 2e.
	var cells := cross.zone_cells(Vector2i(2, 0), Vector2i.ZERO)
	cells.sort()
	var expected: Array[Vector2i] = [Vector2i(2, 0), Vector2i(3, -1), Vector2i(3, 0), Vector2i(3, 1), Vector2i(4, 0), Vector2i(5, 0)]
	assert_eq(cells, expected)
	# Vers −y : la croix suit le sens du lancer.
	cells = cross.zone_cells(Vector2i(0, -1), Vector2i.ZERO)
	cells.sort()
	expected = [Vector2i(-1, -2), Vector2i(0, -4), Vector2i(0, -3), Vector2i(0, -2), Vector2i(0, -1), Vector2i(1, -2)]
	assert_eq(cells, expected)
