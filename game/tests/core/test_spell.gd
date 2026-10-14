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
	assert_eq(spell.crit_chance, 0, "sorts de test sans coup critique")
	var data := _valid()
	data.erase("critique")
	assert_eq(Spell.from_dict(data).crit_chance, Spell.DEFAULT_CRIT_CHANCE, "5 % de coups critiques par défaut")
	assert_eq(spell.effects[0]["duree"], 0)


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
		"effet inconnu": {"effets": [{"type": "malediction", "min": 1, "max": 2}]},
		"poison sans durée": {"effets": [{"type": "poison", "element": "givre", "min": 1, "max": 2}]},
		"bonus d'une caractéristique inconnue": {"effets": [{"type": "bonus", "carac": "charisme", "min": 1, "max": 1, "duree": 2}]},
		"résistance sans élément": {"effets": [{"type": "malus", "carac": "resistance", "min": 10, "max": 10, "duree": 1}]},
		"glyphe sans effets": {"effets": [{"type": "glyphe", "duree": 2, "effets": []}]},
		"piège dans une glyphe": {"effets": [{"type": "glyphe", "duree": 2, "effets": [{"type": "piege", "effets": [{"type": "poussee", "min": 1, "max": 1}]}]}]},
		"piège et autre effet": {"effets": [{"type": "piege", "effets": [{"type": "poussee", "min": 1, "max": 1}]},
			{"type": "degats", "element": "acier", "min": 1, "max": 1}]},
		"piège à zone inconnue": {"effets": [{"type": "piege", "zone": {"type": "croix_latine"}, "effets": [{"type": "poussee", "min": 1, "max": 1}]}]},
		"critique au-delà de 100 %": {"critique": 150},
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
	# Lancer vers +x depuis (0, 0) sur (2, 0) : (2..5, 0) en ligne, et (4, ±1) de chaque côté de la 3e.
	var cells := cross.zone_cells(Vector2i(2, 0), Vector2i.ZERO)
	cells.sort()
	var expected: Array[Vector2i] = [Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, -1), Vector2i(4, 0), Vector2i(4, 1), Vector2i(5, 0)]
	assert_eq(cells, expected)
	# Vers −y : la croix suit le sens du lancer.
	cells = cross.zone_cells(Vector2i(0, -1), Vector2i.ZERO)
	cells.sort()
	expected = [Vector2i(-1, -3), Vector2i(0, -4), Vector2i(0, -3), Vector2i(0, -2), Vector2i(0, -1), Vector2i(1, -3)]
	assert_eq(cells, expected)
