extends "res://tests/test_case.gd"

const Fixtures := preload("res://tests/helpers/fixtures.gd")


func test_courbe_d_experience() -> void:
	assert_eq(Character.xp_for_level(1), 0)
	assert_eq(Character.xp_for_level(2), 80)
	assert_eq(Character.xp_for_level(3), 280)
	for level in range(2, Character.MAX_LEVEL):
		assert_true(Character.xp_for_level(level + 1) > Character.xp_for_level(level), "courbe croissante")


func test_montee_de_niveau() -> void:
	var hero := Fixtures.character()
	assert_eq(hero.add_xp(79).size(), 0)
	assert_eq(hero.add_xp(1), [2] as Array[int])
	assert_eq(hero.unspent_points, Character.POINTS_PER_LEVEL)
	var levels := hero.add_xp(1000)
	assert_true(levels.size() >= 2, "plusieurs niveaux d'un coup")
	assert_eq(hero.level, levels[-1])
	hero.add_xp(100000000)
	assert_eq(hero.level, Character.MAX_LEVEL, "niveau plafonné")


func test_repartition_des_points() -> void:
	var hero := Fixtures.character()
	hero.add_xp(80)
	assert_eq(hero.spend_points("force", 3), "")
	assert_eq(hero.unspent_points, 2)
	assert_eq(hero.spend_points("force", 3), Protocol.REASON_NOT_ENOUGH_POINTS)
	assert_eq(hero.spend_points("charisme", 1), Protocol.REASON_INVALID_COMMAND)
	assert_eq(hero.spend_points("force", 0), Protocol.REASON_INVALID_COMMAND)
	var data := Fixtures.data()
	assert_eq(hero.stat("force", data), 53, "3 points + 50 de bonus de race")
	assert_eq(hero.stat("force"), 3, "sans données : points investis seulement")


func test_noms() -> void:
	assert_eq(Character.name_error("Éléa d'Arc-en-Ciel"), "")
	assert_eq(Character.name_error("  Bob  "), "")
	assert_true(Character.name_error("A") != "", "trop court")
	assert_true(Character.name_error("Un nom beaucoup trop long pour un héros") != "", "trop long")
	assert_true(Character.name_error("Bob<3") != "", "caractères interdits")
	assert_true(Character.name_error("'Bob") != "", "doit commencer par une lettre")


func test_fiche_et_pv() -> void:
	var data := Fixtures.data()
	var hero := Fixtures.character()
	hero.add_xp(280)
	var sheet := hero.sheet(data)
	assert_eq(sheet["niveau"], 3)
	assert_eq(sheet["voie_nom"], "Test")
	assert_eq(sheet["race_nom"], "Testeur")
	assert_eq(sheet["caracteristiques"]["vitalite"], 7)
	assert_eq(sheet["pv_max"], 50 + 2 * Character.HP_PER_LEVEL + 7)


func test_sauvegarde_du_personnage() -> void:
	var hero := Fixtures.character()
	hero.add_xp(300)
	hero.spend_points("agilite", 4)
	var copy := Character.from_dict(hero.to_dict())
	assert_eq(copy.to_dict(), hero.to_dict())
	assert_true(Character.from_dict({"nom": "X"}) == null, "sauvegarde incomplète refusée")


func test_combattant_du_personnage() -> void:
	var data := Fixtures.data()
	var fighter := data.create_character_fighter(Fixtures.character(), Fixtures.PLAYER)
	assert_eq(fighter.max_hp, 57)
	assert_eq(fighter.stat("force"), 50)
	assert_eq(fighter.range_bonus, 1)
	assert_true(fighter.get_spell("bond") != null, "sort racial ajouté")
	assert_eq(fighter.race, "testeur")
	var unknown := Character.create("Perdu", "testeur", "voie_inconnue")
	assert_true(data.create_character_fighter(unknown, "x") == null)


func test_initiative_et_prospection_dans_la_fiche() -> void:
	var data := Fixtures.data()
	var character := Fixtures.character()
	character.add_xp(500)
	character.spend_points("agilite", 3)
	character.spend_points("chance", 2)
	var sheet := character.sheet(data)
	var fighter := data.create_character_fighter(character, Fixtures.PLAYER)
	assert_eq(sheet["initiative"], fighter.initiative, "même initiative qu'en combat")
	assert_eq(sheet["prospection"], fighter.prospection)
	assert_eq(sheet["initiative"], character.initiative(data))
