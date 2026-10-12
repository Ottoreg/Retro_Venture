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
