extends "res://tests/test_case.gd"
## Statistiques de combat (GDD § 4.4, § 7.2, § 10.4) : tacle et fuite, esquive des retraits de PA / PM,
## épines, réduction de dégâts fixe, dégâts spectraux et dévastateurs fixes, dommages de mêlée.

const Fixtures := preload("res://tests/helpers/fixtures.gd")
const RIGHT := Vector2i(1, 0)

var C := Fixtures.center()


func _fight(monsters: Array) -> Combat:
	var combat := Fixtures.combat(Fixtures.map(), C, monsters)
	combat.start()
	combat.execute(Fixtures.cmd(Protocol.CMD_READY))
	return combat


func _hit(combat: Combat, caster: Fighter, target: Fighter, amount: int, element := "acier") -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	combat._apply_effect(caster, target, {"type": Spell.EFFECT_DAMAGE, "element": element, "min": amount, "max": amount}, events)
	return events


func test_tacle_et_fuite() -> void:
	var combat := _fight([["mannequin", C + RIGHT]])
	var player := combat.get_fighter(Fixtures.PLAYER)
	assert_eq(combat.tackle_ratio(player, C), 0.5, "(0 + 2) / (2 × (0 + 2))")
	assert_eq(combat.tackle_ratio(player, C - RIGHT), 1.0, "sans ennemi au contact")
	assert_eq(combat.movement_zone(player).size(), combat.reachable_cells(player, 2).size(), "zone : PM après le tacle")
	var events := combat.execute(Fixtures.cmd(Protocol.CMD_MOVE, {"cible": C - RIGHT * 3}))
	assert_eq([events[0]["effet"], events[0]["valeur"]], ["tacle", 1], "3 PM → 2 gardés")
	assert_eq(events[1]["chemin"].size(), 2, "il ne va que jusqu'où ses PM le portent")
	assert_eq(player.pm, 0)
	player.combat_stats["fuite"] = 2
	assert_eq(combat.tackle_ratio(player, C - RIGHT * 2), 1.0, "plus de mannequin au contact")
	player.cell = C
	assert_eq(combat.tackle_ratio(player, C), 1.0, "fuite 2 contre tacle 0 : (2 + 2) / 4")
	player.stats["agilite"] = 0
	combat.get_fighter("m0").stats["agilite"] = 100
	player.combat_stats["fuite"] = 0
	assert_eq(combat.tackle_ratio(player, C), 2.0 / 24, "10 de tacle par 100 d'Agilité")
	combat.get_fighter("m0").states.append({"type": Spell.EFFECT_STATE, "etat": Spell.STATE_UNBLOCKABLE, "tours": 1})
	assert_eq(combat.tackle_ratio(player, C), 1.0, "un inblocable ne tacle pas")


func test_esquive_des_retraits() -> void:
	var combat := _fight([["mannequin", C + RIGHT]])
	var player := combat.get_fighter(Fixtures.PLAYER)
	var dummy := combat.get_fighter("m0")
	var events: Array[Dictionary] = []
	var malus := {"type": Spell.EFFECT_MALUS, "carac": "pa", "min": 3, "max": 3, "duree": 1}
	combat._apply_effect(player, dummy, malus, events)
	assert_eq(dummy.modifier("pa"), -3, "sans esquive, tout passe")
	dummy.states.clear()
	dummy.combat_stats["retrait_pa"] = 200
	player.combat_stats["retrait_pa"] = 110
	combat.rng.seed = 7
	var landed := 0
	for i in 200:
		landed += combat._landed_removal(player, dummy, "pa", 1, events)
	assert_true(landed > 0 and landed < 40, "90 % d'esquive au plus : %d sur 200" % landed)
	dummy.combat_stats["retrait_pa"] = 0
	dummy.combat_stats["retrait_pm"] = 100
	combat._apply_effect(player, dummy, {"type": Spell.EFFECT_REMOVE_PM, "min": 2, "max": 2}, events)
	assert_eq(events[-1]["effet"], "esquive", "retrait de PM esquivé")
	assert_eq(combat._landed_removal(dummy, dummy, "pm", 2, events), 2, "un allié n'esquive pas")


func test_epines() -> void:
	var combat := _fight([["mannequin", C + RIGHT]])
	var player := combat.get_fighter(Fixtures.PLAYER)
	var dummy := combat.get_fighter("m0")
	dummy.max_hp = 1000
	dummy.hp = 1000
	dummy.combat_stats = {"epines_brutes_fixes": 3, "epines_flamme": 20}
	var hp := player.hp
	var events := _hit(combat, player, dummy, 10)
	assert_eq(hp - player.hp, 3 + 2, "3 brut + 20 % de 10 en Flamme")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_DAMAGE)[-1]["source"], "epines")
	player.resistances["flamme"] = 50
	player.combat_stats["reduction_degats"] = 1
	hp = player.hp
	_hit(combat, player, dummy, 20)
	assert_eq(hp - player.hp, (3 - 1) + (2 - 1), "Flamme : 4 × 50 %, puis la réduction fixe")
	dummy.combat_stats = {"epines_brutes": 100}
	hp = player.hp
	_hit(combat, player, dummy, 10)
	assert_eq(hp - player.hp, 6 - 1, "60 % des dégâts subis au plus")
	player.combat_stats["degats_spectraux"] = 50
	player.combat_stats["degats_spectraux_fixes"] = 1
	hp = player.hp
	_hit(combat, player, dummy, 11)
	assert_eq(hp - player.hp, 4 - 1, "11 − 5 spectraux (50 % au plus) = 6 comptés, 60 % renvoyés (3,6)")
	dummy.shield = 100
	hp = player.hp
	_hit(combat, player, dummy, 10)
	assert_eq(player.hp, hp, "un coup absorbé par le bouclier ne renvoie rien")
	dummy.shield = 0
	player.combat_stats = {"epines_brutes": 100}
	hp = dummy.hp
	_hit(combat, player, dummy, 10)
	assert_eq(hp - dummy.hp, 10, "pas d'épine sur épine")


func test_reduction_melee_et_devastateurs_fixes() -> void:
	var combat := _fight([["mannequin", C + RIGHT], ["mannequin", C + RIGHT * 3]])
	var player := combat.get_fighter(Fixtures.PLAYER)
	var near := combat.get_fighter("m0")
	var far := combat.get_fighter("m1")
	near.combat_stats["reduction_degats"] = 4
	assert_eq(Combat.damage_value(player, near, "acier", 10), 6, "réduction de dégâts fixe")
	near.combat_stats.clear()
	player.combat_stats["dommages_melee"] = 3
	assert_eq(Combat.damage_value(player, near, "acier", 100), 103, "au contact : +3 % finaux")
	assert_eq(Combat.damage_value(player, far, "acier", 100), 100, "à distance : rien")
	player.combat_stats = {"degats_devastateurs_fixes": 2, "degats_devastateurs": 10}
	_hit(combat, player, near, 10)
	assert_eq(near.max_hp, 30 - 3, "2 fixes + 10 % de 10")


func test_lignes_de_forge() -> void:
	for stat: String in Fighter.COMBAT_STATS:
		assert_true(stat in Item.EXTRA_STATS and Item.EXTRA_STAT_NAMES.has(stat) and Forge.WORDS.has(stat), stat)
	var caps := {"epines_brutes_fixes": 7, "epines_brutes": 5, "epines_flamme_fixes": 9, "epines_flamme": 6, "reduction_degats": 8,
		"degats_spectraux_fixes": 5, "degats_spectraux": 10, "degats_devastateurs_fixes": 5, "dommages_melee": 3}
	for stat: String in caps:
		assert_eq(Forge.line_cap(stat), caps[stat], "plafond de ligne (GDD § 4.4) : " + stat)
