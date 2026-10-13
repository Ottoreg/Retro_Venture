extends "res://tests/test_case.gd"
## Caractéristiques en combat, bonus de portée et effets sans dégâts.

const Fixtures := preload("res://tests/helpers/fixtures.gd")
const RIGHT := Vector2i(1, 0)

var C := Fixtures.center()


## Combat contre des monstres [[id, case], …], avec le personnage de test (Force 50, portée +1).
func _hero_fight(monsters: Array) -> Combat:
	var data := Fixtures.data()
	var fighters: Array[Fighter] = []
	var hero := data.create_character_fighter(Fixtures.character(), Fixtures.PLAYER)
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


func test_la_force_augmente_les_degats() -> void:
	var combat := _hero_fight([["mannequin", C + RIGHT]])
	var damage := Fixtures.of_type(_cast(combat, "frappe", C + RIGHT), Protocol.EVT_DAMAGE)
	assert_eq(damage[0]["valeur"], 15, "10 × (100 + 50) %")


func test_bonus_de_portee_sur_les_sorts_a_distance() -> void:
	var combat := _hero_fight([["mannequin", C + Vector2i(4, -1)]])
	assert_eq(Fixtures.of_type(_cast(combat, "tir", C + Vector2i(4, -1)), Protocol.EVT_DAMAGE).size(), 1, "portée 4 + 1")
	var melee := _hero_fight([["mannequin", C + Vector2i(2, 0)]])
	assert_eq(_cast(melee, "frappe", C + Vector2i(2, 0))[0]["raison"], Protocol.REASON_OUT_OF_RANGE, "pas de bonus au corps à corps")


func test_teleportation() -> void:
	var combat := _hero_fight([["mannequin", C + RIGHT]])
	var events := _cast(combat, "bond", C + Vector2i(0, 3))
	assert_eq(Fixtures.of_type(events, Protocol.EVT_TELEPORTED).size(), 1)
	assert_eq(combat.get_fighter(Fixtures.PLAYER).cell, C + Vector2i(0, 3))
	var blocked := _hero_fight([["mannequin", C + RIGHT]])
	assert_eq(_cast(blocked, "bond", C + RIGHT)[0]["raison"], Protocol.REASON_OCCUPIED)
	assert_eq(blocked.get_fighter(Fixtures.PLAYER).pa, 6, "aucun PA dépensé")


func test_gain_de_pa() -> void:
	var combat := _hero_fight([["mannequin", C + Vector2i(3, 3)]])
	var events := _cast(combat, "elan", C)
	var status := Fixtures.of_type(events, Protocol.EVT_STATUS)
	assert_eq(status[0]["effet"], Spell.EFFECT_GAIN_PA)
	assert_eq(combat.get_fighter(Fixtures.PLAYER).pa, 7, "6 − 1 + 2")


func test_retrait_de_pm_au_prochain_tour() -> void:
	var combat := _hero_fight([["loup", C + RIGHT]])
	_cast(combat, "entrave", C + RIGHT)
	var events := combat.execute(Fixtures.cmd(Protocol.CMD_END_TURN))
	var wolf_turn := Fixtures.of_type(events, Protocol.EVT_TURN_STARTED)[0]
	assert_eq(wolf_turn["entite"], "m0")
	assert_eq(wolf_turn["pm"], 3, "4 PM − 1")


func _hit(combat: Combat, caster: Fighter, target: Fighter, element: String) -> int:
	var events: Array[Dictionary] = []
	var before := target.hp
	target.hp = 1000
	combat._apply_effect(caster, target, {"type": Spell.EFFECT_DAMAGE, "element": element, "min": 10, "max": 10}, events)
	var dealt := 1000 - target.hp
	target.hp = before
	return dealt


func test_elements_sacre_et_impie() -> void:
	var combat := _hero_fight([["mannequin", C + RIGHT]])
	var hero := combat.get_fighter(Fixtures.PLAYER)
	var dummy := combat.get_fighter("m0")
	hero.stats = {"force": 40, "intelligence": 20, "agilite": 10, "chance": 30}
	assert_eq(hero.power("sacre"), 60, "Force + Intelligence : 1 % par point de chacune")
	assert_eq(hero.power("impie"), 40, "Agilité + Chance")
	hero.stats = {"intelligence": 100}
	assert_eq(hero.power("sacre"), 100, "100 d'Intelligence seule…")
	hero.stats = {"force": 50, "intelligence": 50}
	assert_eq(hero.power("sacre"), 100, "… autant que 50 Force + 50 Intelligence")
	assert_eq(hero.power("flamme"), 50, "mais moins de Flamme")
	hero.stats = {"force": 40, "intelligence": 20, "agilite": 10, "chance": 30}
	dummy.resistances = {"flamme": 10, "acier": 5, "sacre": 5}
	assert_eq(dummy.resistance("sacre"), 12.5, "(10 + 5) / 2 + 5")
	dummy.resistances = {"flamme": 10, "acier": -5, "sacre": 15}
	assert_eq(dummy.resistance("sacre"), 17.5, "(10 − 5) / 2 + 15")
	dummy.resistances = {"tempete": -10, "givre": 30, "impie": -5}
	assert_eq(dummy.resistance("impie"), 5.0, "(−10 + 30) / 2 − 5")
	dummy.resistances = {"acier": 20, "flamme": 0, "tempete": -10, "givre": 30}
	assert_eq(dummy.resistance("sacre"), 10.0, "moyenne Acier et Flamme, sans résistance propre")
	assert_eq(dummy.resistance("impie"), 10.0, "moyenne Tempête et Givre")
	assert_eq(_hit(combat, hero, dummy, "sacre"), 14, "10 × 160 % × 90 % = 14,4")
	assert_eq(_hit(combat, hero, dummy, "impie"), 13, "10 × 140 % × 90 % = 12,6")
	assert_eq(CombatHud.percent_text(12.5), "+12,5 %")
	assert_eq(CombatHud.percent_text(-5.0), "-5 %")
	assert_eq(CombatHud.percent_text(0.0), "0 %")


func test_les_dommages_s_ajoutent_bruts() -> void:
	var combat := _hero_fight([["mannequin", C + RIGHT]])
	var hero := combat.get_fighter(Fixtures.PLAYER)
	var dummy := combat.get_fighter("m0")
	hero.stats = {}
	dummy.resistances = {"givre": 50}
	assert_eq(_hit(combat, hero, dummy, "givre"), 5, "sans Dommages : 10 × 50 %")
	hero.dommages = 5
	assert_eq(_hit(combat, hero, dummy, "givre"), 10, "+5 Dommages : +5 dégâts, non réduits par la résistance")
	assert_eq(_hit(combat, hero, dummy, "sacre"), 15, "quel que soit l'élément")
	var events: Array[Dictionary] = []
	hero.hp = 10
	combat._apply_effect(hero, hero, {"type": Spell.EFFECT_HEAL, "element": "givre", "min": 5, "max": 5}, events)
	assert_eq(hero.hp, 15, "pas sur les soins")


func test_les_dommages_viennent_de_l_equipement() -> void:
	var data := Fixtures.data()
	var character := Fixtures.character()
	var template := {"id": "poing", "nom": "Poing", "type": "anneau", "rarete": "commun", "niveau": 1, "bonus": {"dommages": [3, 3]}}
	var uid := character.inventory.add(template, 1, Item.roll_bonuses(template, RandomNumberGenerator.new()))
	character.inventory.equip(uid, "anneau_1")
	assert_eq(character.sheet(data)["dommages"], 3, "dans la fiche")
	assert_eq(data.create_character_fighter(character, Fixtures.PLAYER).dommages, 3, "en combat")


func test_bouclier() -> void:
	var combat := _hero_fight([["mannequin", C + RIGHT]])
	var hero := combat.get_fighter(Fixtures.PLAYER)
	var dummy := combat.get_fighter("m0")
	hero.stats = {"intelligence": 50}
	dummy.stats = {}
	var events: Array[Dictionary] = []
	combat._apply_effect(hero, hero, {"type": Spell.EFFECT_SHIELD, "element": "flamme", "min": 10, "max": 10}, events)
	assert_eq(hero.shield, 15, "bouclier de Flamme : 10 × (100 + 50 Intelligence) %")
	assert_eq(events[0]["effet"], Spell.EFFECT_SHIELD)
	var hp := hero.hp
	events.clear()
	combat._apply_effect(dummy, hero, {"type": Spell.EFFECT_DAMAGE, "element": "acier", "min": 10, "max": 10}, events)
	assert_eq(hero.hp, hp, "10 dégâts absorbés")
	assert_eq(hero.shield, 5)
	assert_eq(events[0]["absorbe"], 10)
	events.clear()
	combat._apply_effect(dummy, hero, {"type": Spell.EFFECT_DAMAGE, "element": "acier", "min": 10, "max": 10}, events)
	assert_eq(hero.hp, hp - 5, "5 absorbés, 5 sur les PV")
	assert_eq(hero.shield, 0)
	combat._apply_effect(hero, hero, {"type": Spell.EFFECT_SHIELD, "element": "flamme", "min": 10, "max": 10}, events)
	hero.start_turn()
	assert_eq(hero.shield, 0, "le bouclier tombe au début de son tour")


func test_soins_et_boucliers_montent_avec_leur_element() -> void:
	var combat := _hero_fight([["mannequin", C + RIGHT]])
	var hero := combat.get_fighter(Fixtures.PLAYER)
	hero.stats = {"force": 30, "intelligence": 20, "agilite": 40}
	var events: Array[Dictionary] = []
	hero.hp = 1
	combat._apply_effect(hero, hero, {"type": Spell.EFFECT_HEAL, "element": "sacre", "min": 10, "max": 10}, events)
	assert_eq(hero.hp, 1 + 15, "soin Sacré : Force + Intelligence (+50 %)")
	hero.hp = 1
	combat._apply_effect(hero, hero, {"type": Spell.EFFECT_HEAL, "element": "acier", "min": 10, "max": 10}, events)
	assert_eq(hero.hp, 1 + 13, "soin d'Acier : Force seule (+30 %)")
	combat._apply_effect(hero, hero, {"type": Spell.EFFECT_SHIELD, "element": "tempete", "min": 10, "max": 10}, events)
	assert_eq(hero.shield, 14, "bouclier de Tempête : Agilité (+40 %)")
	assert_true(Spell.validate({"id": "x", "nom": "X", "cout_pa": 1, "portee": {"min": 0, "max": 0},
		"effets": [{"type": "soin", "min": 1, "max": 2}]}).size() > 0, "un soin sans élément est refusé")


func test_sermon_en_ligne_degats_aux_ennemis_soin_aux_allies() -> void:
	var combat := _hero_fight([["mannequin", C + Vector2i(3, 0)], ["mannequin", C + Vector2i(2, 1)], ["mannequin", C + Vector2i(1, 1)]])
	assert_eq(_cast(combat, "sermon", C + Vector2i(1, 1))[0]["raison"], Protocol.REASON_NOT_IN_LINE, "en diagonale : refusé")
	var ally := combat.get_fighter("m1")
	ally.team = combat.get_fighter(Fixtures.PLAYER).team
	ally.hp = 10
	var events := _cast(combat, "sermon", C + Vector2i(1, 0))
	var damage := Fixtures.of_type(events, Protocol.EVT_DAMAGE)
	assert_eq(damage.size(), 1, "seul l'ennemi dans la croix est touché")
	assert_eq(damage[0]["entite"], "m0")
	var heal := Fixtures.of_type(events, Protocol.EVT_HEAL)
	assert_eq(heal.size(), 1, "l'allié sur le bras de la croix est soigné")
	assert_eq(heal[0]["entite"], "m1")
	assert_eq(ally.hp, 25, "10 + 10 × (100 + 50 Force) %")
	assert_eq(combat.get_fighter("m2").hp, 30, "hors de la croix")
