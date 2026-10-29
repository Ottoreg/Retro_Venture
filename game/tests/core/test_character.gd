extends "res://tests/test_case.gd"

const Fixtures := preload("res://tests/helpers/fixtures.gd")


func test_paliers_de_reputation() -> void:
	assert_eq(Character.tier_index(0), 0)
	assert_eq(Character.tier_index(999), 0)
	assert_eq(Character.tier_index(1000), 1)
	assert_eq(Character.tier_name(Character.tier_index(5000)), "Compagnon")
	assert_eq(Character.tier_index(10000000), Character.REPUTATION_TIERS.size() - 1, "dernier palier")
	for i in range(1, Character.REPUTATION_TIERS.size()):
		assert_true(int(Character.REPUTATION_TIERS[i][0]) > int(Character.REPUTATION_TIERS[i - 1][0]), "paliers croissants")


func test_reputation_et_points_de_maitrise() -> void:
	var hero := _bare()
	assert_eq(hero.reputation(), 0, "une classe commence à zéro")
	assert_eq(hero.add_reputation(400).size(), 0)
	assert_eq(hero.mastery_points(), 0)
	assert_eq(hero.add_reputation(700), [1] as Array[int], "palier Apprenti à 1 000")
	assert_eq(hero.mastery_points(), 2, "un point par tranche de %d" % Character.REPUTATION_PER_MASTERY_POINT)
	var reached := hero.add_reputation(20000)
	assert_eq(reached, [2, 3] as Array[int], "plusieurs paliers d'un coup")
	assert_eq(hero.reputation(), 21100)
	assert_eq(hero.add_reputation(-50).size(), 0, "jamais de baisse")
	assert_eq(hero.reputation(), 21100)


func test_maitrise_des_sorts() -> void:
	var hero := _bare()
	var spells := ["frappe", "tir"]
	assert_eq(hero.raise_spell("frappe", spells), Protocol.REASON_NOT_ENOUGH_POINTS)
	hero.add_reputation(3 * Character.REPUTATION_PER_MASTERY_POINT)
	assert_eq(hero.raise_spell("frappe", spells), "", "rang 1 : 1 point")
	assert_eq(hero.raise_spell("frappe", spells), "", "rang 2 : 2 points")
	assert_eq(hero.spell_rank("frappe"), 2)
	assert_eq(hero.mastery_points(), 0)
	assert_eq(hero.raise_spell("frappe", spells), Protocol.REASON_NOT_ENOUGH_POINTS)
	assert_eq(hero.raise_spell("boule", spells), Protocol.REASON_INVALID_COMMAND, "pas un sort de la classe")
	hero.add_reputation(100 * Character.REPUTATION_PER_MASTERY_POINT)
	for i in 3:
		hero.raise_spell("frappe", spells)
	assert_eq(hero.spell_rank("frappe"), Character.SPELL_MAX_RANK)
	assert_eq(hero.raise_spell("frappe", spells), Protocol.REASON_INVALID_COMMAND, "rang maximal")


## Personnage de test sans caractéristiques gagnées.
func _bare() -> Character:
	return Character.create("Testeur", "testeur", "test")


func test_caracteristiques_gagnees_et_plafonnees() -> void:
	var hero := _bare()
	assert_eq(hero.gain_stat("force", 30), 30)
	assert_eq(hero.gain_stat("force", 400), Character.STAT_CAP - 30, "plafond")
	assert_eq(Character.STAT_CAP, 300, "300 par caractéristique (décision de l'auteur)")
	assert_eq(hero.gain_stat("force", 5), 0)
	assert_eq(hero.gain_stat("vitalite", 400), Character.VITALITY_CAP, "la Vitalité au même plafond")
	assert_eq(Character.VITALITY_CAP, Character.STAT_CAP)
	assert_eq(hero.gain_stat("sagesse", 5), 0, "Sagesse supprimée")
	assert_eq(hero.gain_stat("force", -3), 0)
	var data := Fixtures.data()
	assert_eq(hero.stat("force", data), Character.STAT_CAP, "pas de bonus de race")
	assert_eq(hero.stat("force"), Character.STAT_CAP, "sans données : points gagnés seulement")


func test_changer_de_classe() -> void:
	var hero := Character.create("Hector", "humain", "guerrier")
	hero.gain_stat("force", 40)
	hero.add_reputation(1200)
	assert_false(hero.can_switch_to("arcaniste"), "pas avant %d de réputation" % Character.NEW_CLASS_REPUTATION)
	assert_eq(hero.switch_class("arcaniste"), Protocol.REASON_REPUTATION_TOO_LOW)
	assert_eq(hero.switch_class("guerrier"), Protocol.REASON_INVALID_COMMAND, "déjà active")
	hero.add_reputation(Character.NEW_CLASS_REPUTATION)
	var points := hero.mastery_points()
	assert_eq(hero.switch_class("arcaniste"), "")
	assert_eq(hero.voie_id, "arcaniste")
	assert_eq(hero.reputation(), 0, "la nouvelle classe repart de zéro")
	assert_eq(hero.mastery_points(), 0)
	assert_eq(hero.stat("force"), 40, "les caractéristiques suivent")
	assert_eq(hero.switch_class("guerrier"), "", "retour à une classe commencée")
	assert_eq(hero.reputation(), 1200 + Character.NEW_CLASS_REPUTATION, "elle a tout gardé")
	assert_eq(hero.mastery_points(), points)


func test_noms() -> void:
	assert_eq(Character.name_error("Éléa d'Arc-en-Ciel"), "")
	assert_eq(Character.name_error("  Bob  "), "")
	assert_true(Character.name_error("A") != "", "trop court")
	assert_true(Character.name_error("Un nom beaucoup trop long pour un héros") != "", "trop long")
	assert_true(Character.name_error("Bob<3") != "", "caractères interdits")
	assert_true(Character.name_error("'Bob") != "", "doit commencer par une lettre")


func test_fiche_et_pv() -> void:
	var data := Fixtures.data()
	var hero := _bare()
	hero.add_reputation(1500)
	hero.gain_stat("vitalite", 20)
	var sheet := hero.sheet(data)
	assert_eq(sheet["palier_nom"], "Apprenti")
	assert_eq(sheet["reputation"], 1500)
	assert_eq(sheet["reputation_suivante"], 5000)
	assert_eq(sheet["points_maitrise"], 3)
	assert_eq(sheet["voie_nom"], "Test")
	assert_eq(sheet["race_nom"], "Testeur")
	assert_eq(sheet["caracteristiques"]["vitalite"], 20, "pas de bonus de race")
	assert_eq(sheet["gagnes"]["vitalite"], 20)
	assert_eq(sheet["pv_max"], 50 + 20, "PV de la Voie + Vitalité, plus de PV par niveau")


func test_sauvegarde_du_personnage() -> void:
	var hero := _bare()
	hero.add_reputation(3000)
	hero.raise_spell("frappe", ["frappe"])
	hero.gain_stat("agilite", 4)
	var copy := Character.from_dict(JSON.parse_string(JSON.stringify(hero.to_dict())))
	assert_eq(JSON.stringify(copy.to_dict()), JSON.stringify(hero.to_dict()))
	assert_eq(copy.spell_rank("frappe"), 1)
	assert_true(Character.from_dict({"nom": "X"}) == null, "sauvegarde incomplète refusée")


func test_sauvegarde_d_avant_la_refonte() -> void:
	# Niveau, XP (×3,5 de l'alpha 1) et points investis : convertis en réputation et points gagnés.
	var old := {"nom": "Ancien", "race": "humain", "voie": "guerrier", "niveau": 5, "xp": 3500, "points": 2,
		"caracteristiques": {"force": 12, "chance": 3, "sagesse": 4}}
	var hero := Character.from_dict(old)
	assert_eq(hero.reputation(), 1000, "XP sans le ×3,5")
	assert_eq(hero.mastery_points(), 2)
	assert_eq(hero.stat("force"), 12)
	assert_eq(hero.stat("perception"), 3, "la Chance devient la Perception")
	assert_false(hero.earned.has("sagesse"), "la Sagesse disparaît")


func test_pierres_et_cartes_sauvegardees() -> void:
	var hero := _bare()
	assert_true(hero.discover_passage("brumerive"))
	assert_false(hero.discover_passage("brumerive"), "déjà découverte")
	hero.respawn_passage = "brumerive"
	assert_true(hero.visit_map("brumerive_0_0"))
	assert_false(hero.visit_map("brumerive_0_0"), "pas de doublon")
	var copy := Character.from_dict(JSON.parse_string(JSON.stringify(hero.to_dict())))
	assert_eq(copy.known_passages, ["brumerive"] as Array[String])
	assert_eq(copy.respawn_passage, "brumerive")
	assert_eq(copy.visited_maps, ["brumerive_0_0"] as Array[String])
	# Valeurs abîmées : ignorées.
	var damaged := hero.to_dict()
	damaged["pierres_connues"] = ["brumerive", 3, "brumerive", ""]
	damaged["point_de_resurrection"] = 12
	damaged["cartes_visitees"] = "brumerive_0_0"
	var cleaned := Character.from_dict(damaged)
	assert_eq(cleaned.known_passages, ["brumerive"] as Array[String], "doublons et valeurs invalides ignorés")
	assert_eq(cleaned.respawn_passage, "")
	assert_true(cleaned.visited_maps.is_empty())
	# Vieille sauvegarde : rien de connu (le monde y ajoute la pierre de la zone de départ).
	for key: String in ["pierres_connues", "point_de_resurrection", "cartes_visitees"]:
		damaged.erase(key)
	assert_true(Character.from_dict(damaged).known_passages.is_empty())


func test_combattant_du_personnage() -> void:
	var data := Fixtures.data()
	var fighter := data.create_character_fighter(Fixtures.character(), Fixtures.PLAYER)
	assert_eq(fighter.max_hp, 57, "PV de la Voie + Vitalité gagnée")
	assert_eq(fighter.stat("force"), 50)
	assert_eq(fighter.range_bonus, 1)
	assert_true(fighter.get_spell("bond") != null, "sort racial ajouté")
	assert_eq(fighter.race, "testeur")
	var unknown := Character.create("Perdu", "testeur", "voie_inconnue")
	assert_true(data.create_character_fighter(unknown, "x") == null)


func test_initiative_et_prospection_dans_la_fiche() -> void:
	var data := Fixtures.data()
	var character := _bare()
	character.gain_stat("agilite", 3)
	character.gain_stat("perception", 2)
	var sheet := character.sheet(data)
	var fighter := data.create_character_fighter(character, Fixtures.PLAYER)
	assert_eq(sheet["initiative"], fighter.initiative, "même initiative qu'en combat")
	assert_eq(sheet["prospection"], fighter.prospection)
	assert_eq(sheet["initiative"], character.initiative(data))


func test_provenance_des_caracteristiques() -> void:
	var data := Fixtures.data()
	var character := _bare()
	character.gain_stat("force", 2)
	var sources := character.stat_sources("force", data)
	assert_eq(sources["points"], 2)
	assert_eq(sources["points"] + sources["equipement"] + sources["panoplie"], character.stat("force", data),
		"la provenance fait le total")
	var objects_total := 0
	for item: Array in sources["objets"]:
		objects_total += int(item[1])
	assert_eq(objects_total, sources["equipement"], "détail objet par objet")
	var sheet := character.sheet(data)
	assert_eq(sheet["provenance"]["force"], sources)
	assert_true(sheet["provenance"].has("pa"), "provenance des bonus d'équipement aussi")
	assert_eq(sheet["gagnes"], {"force": 2})
