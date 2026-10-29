extends "res://tests/test_case.gd"
## Progression par la pratique (GDD § 4.5) : facteur de difficulté, gains d'un combat, ce que le
## combat note, caractéristiques pratiquées, rangs de maîtrise des sorts et sorts de rang II.

const Fixtures := preload("res://tests/helpers/fixtures.gd")
const RIGHT := Vector2i(1, 0)
const LEFT := Vector2i(-1, 0)

var C := Fixtures.center()


func _hero_fight(monsters: Array, data := Fixtures.data(), character := Fixtures.character()) -> Combat:
	var fighters: Array[Fighter] = []
	var hero := data.create_character_fighter(character, Fixtures.PLAYER)
	hero.cell = C
	fighters.append(hero)
	for i in monsters.size():
		var monster := data.create_monster(monsters[i][0], "m%d" % i)
		monster.cell = monsters[i][1]
		fighters.append(monster)
	var placement: Array[Vector2i] = [C]
	var combat := Combat.new(Fixtures.map(), fighters, placement, 1)
	combat.start()
	combat.execute(Fixtures.cmd(Protocol.CMD_READY))
	return combat


func _cast(combat: Combat, spell_id: String, target: Vector2i) -> Array[Dictionary]:
	return combat.execute(Fixtures.cmd(Protocol.CMD_CAST, {"sort": spell_id, "cible": target}))


func test_facteur_de_difficulte() -> void:
	assert_eq(Progression.difficulty([1], [1]), 0.5, "un monstre de son niveau : un peu en dessous")
	assert_eq(Progression.difficulty([1, 1], [1]), 1.0, "deux : à sa mesure")
	assert_eq(Progression.difficulty([3], [1]), 1.5, "bien au-dessus")
	assert_eq(Progression.difficulty([30], [1]), 1.5, "borné")
	assert_eq(Progression.difficulty([1], [10]), 0.1, "très en dessous : presque rien")
	assert_eq(Progression.difficulty([3, 3], [2, 1]), 1.0, "en groupe, contre la force de tout le groupe")
	assert_eq(Progression.difficulty([], [1]), 0.0, "aucun monstre")
	assert_true(Progression.difficulty([2], [3]) > Progression.difficulty([2], [4]), "entre deux points, interpolé")


func test_menace_en_mots() -> void:
	assert_eq(Progression.threat_name(0.1), "négligeable")
	assert_eq(Progression.threat_name(0.5), "faible")
	assert_eq(Progression.threat_name(1.0), "à votre mesure")
	assert_eq(Progression.threat_name(1.5), "redoutable")
	var character := Fixtures.character()
	assert_eq(MapView.threat_line([1, 1], character), "Menace : à votre mesure (gains × 1)")
	character.add_reputation(5000)
	assert_eq(MapView.threat_line([1, 1], character), "Menace : négligeable (gains × 0,1)", "un Compagnon contre deux monstres de niveau 1")


func test_tranche_de_niveaux_d_une_carte() -> void:
	var data := GameData.load_all()
	var map := DataLoader.load_map(DataLoader.map_path("brumerive_0_0"))
	var levels := data.map_level_range(map)
	assert_true(levels.x >= 1 and levels.x <= levels.y and levels.y <= 3, "Brumerive (0, 0) : premier palier (%s)" % str(levels))
	assert_eq(data.map_level_range(GameMap.new()), Vector2i.ZERO, "sans groupe")


func test_niveau_equivalent_tire_de_la_reputation() -> void:
	assert_eq(Progression.equivalent_level(0), 1)
	assert_eq(Progression.equivalent_level(22), 1, "l'ancienne courbe sans le × 3,5 : 80 / 3,5 pour le niveau 2")
	assert_eq(Progression.equivalent_level(23), 2)
	var compagnon := Progression.equivalent_level(5000)
	assert_true(compagnon >= 12 and compagnon <= 14, "Compagnon vers la fin des zones de départ (niveau %d)" % compagnon)
	assert_eq(Progression.equivalent_level(100000000), Progression.MAX_EQUIVALENT_LEVEL)


func test_gains_d_un_combat() -> void:
	var gains := Progression.gains({"effet": {"acier": 10.0}, "utile": 4.0, "pv_recus": 50.0}, 1.0)
	assert_eq(gains["reputation"], 24, "(10 PA + la moitié de 4) × 2")
	assert_almost_eq(gains["caracteristiques"]["force"], 10 * Progression.STAT_PER_PA, 0.0001, "l'Acier fait la Force")
	assert_almost_eq(gains["caracteristiques"]["vitalite"], 1.0, 0.0001, "les coups reçus font la Vitalité")
	assert_false(gains["caracteristiques"].has("intelligence"))
	var halved := Progression.gains({"effet": {"acier": 10.0}}, 0.5, 3.0)
	assert_eq(halved["reputation"], 13, "facteur 0,5, plus la part des monstres vaincus")
	var sacred: Dictionary = Progression.gains({"effet": {"sacre": 10.0}}, 1.0)["caracteristiques"]
	assert_almost_eq(sacred["force"], 5 * Progression.STAT_PER_PA, 0.0001, "Sacré : Force et Intelligence par moitié")
	assert_almost_eq(sacred["intelligence"], 5 * Progression.STAT_PER_PA, 0.0001)
	var endless := Progression.gains({"effet": {"acier": 120.0}, "pv_recus": 1000.0}, 1.0)
	assert_eq(endless["reputation"], roundi(Progression.MAX_PA_PER_COMBAT * Progression.REPUTATION_PER_PA), "PA plafonnés par combat")
	assert_almost_eq(endless["caracteristiques"]["vitalite"], Progression.MAX_HP_PER_COMBAT * Progression.VITALITY_PER_HP, 0.0001)
	assert_eq(Progression.gains({}, 1.0)["reputation"], 0, "rien fait, rien gagné")


func test_pratique_d_une_caracteristique() -> void:
	var character := Fixtures.character()
	assert_eq(character.practice_stat("force", 0.6), 0, "une fraction se garde")
	assert_eq(character.practice_stat("force", 0.6), 1, "et s'ajoute au gain suivant")
	assert_almost_eq(character.practiced["force"], 0.2, 0.02)
	character.earned["agilite"] = 50
	assert_eq(character.practice_stat("agilite", 4.0), 2, "à mi-plafond, deux fois plus lent")
	character.earned["intelligence"] = Character.STAT_CAP
	assert_eq(character.practice_stat("intelligence", 10.0), 0, "rien au plafond")
	assert_eq(character.practice_stat("sagesse", 10.0), 0, "caractéristique inconnue")
	var reloaded := Character.from_dict(JSON.parse_string(JSON.stringify(character.to_dict())))
	assert_almost_eq(reloaded.practiced["force"], character.practiced["force"], 0.0001, "les fractions sont sauvegardées")


func test_le_combat_note_les_sorts_a_effet_reel() -> void:
	var combat := _hero_fight([["mannequin", C + RIGHT]])
	_cast(combat, "piqure", C + LEFT)
	assert_false(combat.practice.has(Fixtures.PLAYER), "un sort dans le vide ne compte pas")
	_cast(combat, "frappe", C + RIGHT)
	assert_eq(combat.practice[Fixtures.PLAYER]["effet"], {"acier": 3.0}, "dégâts infligés : les PA du sort, par élément")
	_cast(combat, "entrave", C + RIGHT)
	assert_eq(combat.practice[Fixtures.PLAYER]["utile"], 1.0, "un sort utilitaire qui touche")


func test_soin_seulement_sur_des_pv_perdus() -> void:
	var combat := _hero_fight([["mannequin", C + Vector2i(4, 0)]])
	_cast(combat, "soin", C)
	assert_false(combat.practice.has(Fixtures.PLAYER), "soin à pleine vie : rien")
	var other := _hero_fight([["mannequin", C + Vector2i(4, 0)]])
	other.get_fighter(Fixtures.PLAYER).hp -= 20
	_cast(other, "soin", C)
	assert_eq(other.practice[Fixtures.PLAYER]["effet"], {"flamme": 2.0})


func test_bouclier_qui_absorbe_et_coups_recus() -> void:
	var data := Fixtures.data()
	var shield_data := {"id": "egide", "nom": "Égide", "cout_pa": 2, "portee": {"min": 0, "max": 0},
		"effets": [{"type": "bouclier", "element": "givre", "min": 10, "max": 10}]}
	data.spells["egide"] = Spell.from_dict(shield_data)
	data.voies["test"]["sorts"].append("egide")
	var combat := _hero_fight([["mannequin", C + Vector2i(4, 0)]], data)
	_cast(combat, "egide", C)
	assert_false(combat.practice.has(Fixtures.PLAYER), "un bouclier ne compte que s'il absorbe")
	var events: Array[Dictionary] = []
	combat._hurt(combat.get_fighter(Fixtures.PLAYER), 14, "acier", events)
	var entry: Dictionary = combat.practice[Fixtures.PLAYER]
	assert_eq(entry["effet"], {"givre": 2.0}, "le bouclier a absorbé : son lanceur progresse")
	assert_eq(entry["pv_recus"], 4.0, "seuls les PV réellement perdus comptent pour la Vitalité")
	combat._hurt(combat.get_fighter(Fixtures.PLAYER), 0, "acier", events)
	assert_eq(entry["effet"], {"givre": 2.0}, "une seule fois par bouclier")


func test_poison_compte_a_chaque_tour_qui_blesse() -> void:
	var combat := _hero_fight([["mannequin", C + Vector2i(2, 0)]])
	_cast(combat, "venin", C + Vector2i(2, 0))
	assert_eq(combat.practice[Fixtures.PLAYER]["utile"], 1.0)
	combat.execute(Fixtures.cmd(Protocol.CMD_END_TURN))
	assert_almost_eq(float(combat.practice[Fixtures.PLAYER]["effet"].get("acier", 0.0)), 1.0 / 3.0, 0.001,
		"un tiers des PA par tour du poison qui blesse")


func test_rangs_de_maitrise_d_un_sort() -> void:
	var raw := {"id": "coup", "nom": "Coup", "cout_pa": 4, "portee": {"min": 1, "max": 3}, "relance": {"delai": 2},
		"effets": [{"type": "degats", "element": "acier", "min": 10, "max": 20}],
		"maitrise": {"3": {"critique": 5, "portee_max": 1}, "5": {"cout_pa": 3, "delai": 1,
			"effets": [{"type": "retrait_pm", "min": 1, "max": 1}]}}}
	assert_eq(Spell.validate(raw), PackedStringArray())
	var spell := Spell.from_dict(raw)
	assert_true(spell.mastered(0) == spell, "rang 0 : le sort des données")
	var first := spell.mastered(1)
	assert_eq([first.effects[0]["min"], first.effects[0]["max"]], [11, 22], "+10 % par rang")
	assert_eq(first.crit_chance, Spell.DEFAULT_CRIT_CHANCE)
	assert_eq(spell.effects[0]["min"], 10, "le sort des données ne change pas")
	var third := spell.mastered(3)
	assert_eq([third.crit_chance, third.range_max, third.pa_cost], [Spell.DEFAULT_CRIT_CHANCE + 5, 4, 4], "rang 3")
	var fifth := spell.mastered(5)
	assert_eq([fifth.effects[0]["min"], fifth.pa_cost, fifth.cooldown, fifth.effects.size()], [15, 3, 1, 2], "rang 5")
	assert_eq(fifth.range_max, 4, "les changements du rang 3 restent")
	assert_true(Spell.validate({"id": "x", "nom": "X", "cout_pa": 1, "portee": {"min": 0, "max": 0},
		"effets": [{"type": "degats", "element": "acier", "min": 1, "max": 1}], "maitrise": {"6": {}}}).size() > 0, "rang 6 refusé")
	assert_true(Spell.validate({"id": "x", "nom": "X", "cout_pa": 1, "portee": {"min": 0, "max": 0},
		"effets": [{"type": "degats", "element": "acier", "min": 1, "max": 1}], "maitrise": {"3": {"vol": 1}}}).size() > 0, "changement inconnu")


func test_le_combattant_a_les_rangs_de_sa_classe() -> void:
	var data := Fixtures.data()
	var character := Fixtures.character()
	character.add_reputation(3 * Character.REPUTATION_PER_MASTERY_POINT)
	assert_eq(character.raise_spell("frappe", data.class_spells("test", character.reputation())), "")
	assert_eq(character.raise_spell("frappe", data.class_spells("test", character.reputation())), "")
	var fighter := data.create_character_fighter(character, Fixtures.PLAYER)
	assert_eq(fighter.get_spell("frappe").effects[0]["min"], 12, "Frappe au rang 2 : +20 %")
	assert_eq(fighter.get_spell("piqure").effects[0]["min"], 1)
	var profile := fighter.profile()
	assert_eq(profile["maitrises"], {"frappe": 2}, "les rangs voyagent avec le profil")
	var copy := data.create_profile_fighter(JSON.parse_string(JSON.stringify(profile)), "copie")
	assert_eq(copy.get_spell("frappe").effects[0]["min"], 12, "chez les autres joueurs aussi")


func test_sorts_de_rang_2_debloques_par_la_reputation() -> void:
	var data := Fixtures.data()
	data.voies["test"]["sorts_rang_2"] = {"soin_distance": 1000}
	assert_eq(GameData.validate_voie(data.voies["test"], data.spells, data.items), PackedStringArray())
	assert_false("soin_distance" in data.class_spells("test", 999))
	assert_true("soin_distance" in data.class_spells("test", 1000))
	var character := Fixtures.character()
	assert_true(data.create_character_fighter(character, Fixtures.PLAYER).get_spell("soin_distance") == null)
	assert_eq(character.raise_spell("soin_distance", data.class_spells("test", character.reputation())),
		Protocol.REASON_INVALID_COMMAND, "pas encore débloqué")
	character.add_reputation(1000)
	assert_true(data.create_character_fighter(character, Fixtures.PLAYER).get_spell("soin_distance") != null)
	var invalid: Dictionary = data.voies["test"].duplicate(true)
	invalid["sorts_rang_2"] = {"inconnu": 5000, "frappe": 10}
	assert_eq(GameData.validate_voie(invalid, data.spells, data.items).size(), 2, "sort inconnu, et déjà de rang I")


func test_guerrier_voie_pilote() -> void:
	var data := GameData.load_all()
	for spell_id: String in data.voies["guerrier"]["sorts"] + data.voies["guerrier"]["sorts_rang_2"].keys():
		assert_false(data.spells[spell_id].mastery.is_empty(), "%s a ses rangs de maîtrise" % spell_id)
	assert_eq(data.voies["guerrier"]["sorts_rang_2"]["guerrier_cri_de_guerre"], 5000, "Compagnon")
	assert_eq(data.spells["guerrier_hache"].mastered(5).pa_cost, 3, "Lancer de hache à 3 PA au rang 5")
	assert_eq(data.spells["guerrier_tourbillon"].mastered(5).zone_size, 2)
