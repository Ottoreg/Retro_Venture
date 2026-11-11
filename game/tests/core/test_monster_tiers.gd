extends "res://tests/test_case.gd"
## Paliers des monstres (11/11/2026, demande de l'auteur) : 1 à 5 comme la forge, caractéristiques fixes,
## menace et facteur de difficulté selon les paliers, plus de niveau ni de tirage.

const Fixtures := preload("res://tests/helpers/fixtures.gd")


func test_palier_et_caracteristiques_fixes() -> void:
	var monster := Fixtures.monster("rat", 20, 0, 0, 10, ["frappe"])
	monster["palier"] = 3
	var data := GameData.from_dicts(Fixtures.spells(), [monster], [], [], Fixtures.items())
	var first := data.create_monster("rat", "a")
	var second := data.create_monster("rat", "b")
	assert_eq([first.tier, first.max_hp], [3, 20])
	assert_eq(second.max_hp, first.max_hp, "deux monstres d'une famille sont identiques")
	assert_eq(data.monster_tier("inconnu"), 1)
	assert_eq(data.create_monster("rat", "a").to_dict()["palier"], 3, "envoyé au client")


func test_validation_du_palier() -> void:
	var base := Fixtures.data()
	var monster := Fixtures.monster("rat", 20, 0, 0, 10, ["frappe"])
	assert_true(GameData.validate_monster(monster, base.spells, base.items).is_empty(), "palier 1 par défaut")
	for bad: Variant in [0, 6, "2"]:
		monster["palier"] = bad
		assert_false(GameData.validate_monster(monster, base.spells, base.items).is_empty(), "palier %s refusé" % str(bad))
	monster["palier"] = 2
	for old: String in ["niveau", "niveaux", "par_niveau"]:
		var legacy := monster.duplicate()
		legacy[old] = 1
		assert_true(" ".join(GameData.validate_monster(legacy, base.spells, base.items)).contains(old), old + " n'existe plus")


func test_difficulte_selon_les_paliers() -> void:
	assert_eq(Progression.player_tier(0), 1, "Inconnu compté 1")
	assert_eq(Progression.player_tier(5000), 2, "Compagnon")
	assert_eq(Progression.player_tier(10000000), Forge.MAX_TIER)
	assert_eq(Progression.difficulty([1], [1]), 0.5, "un monstre de son palier")
	assert_eq(Progression.difficulty([2, 2, 2], [2]), 1.5, "trois monstres de son palier")
	assert_eq(Progression.difficulty([1], [5]), 0.1, "un monstre bien plus faible")
