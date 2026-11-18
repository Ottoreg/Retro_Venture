extends "res://tests/test_case.gd"
## Orc et Squelette (GDD § 4.2) : Peau épaisse, Déjà mort, Cri de guerre et Remonter les os.

const Fixtures := preload("res://tests/helpers/fixtures.gd")
const RIGHT := Vector2i(1, 0)

var C := Fixtures.center()


func test_passifs_et_sorts() -> void:
	var data := GameData.load_all()
	var orc := data.create_character_fighter(Character.create("Grok", "orc", "guerrier"), "orc")
	var bones := data.create_character_fighter(Character.create("Osric", "squelette", "guerrier"), "os")
	assert_eq([orc.passives["reduction_melee"], bones.passives["deja_mort"]], [10, 1])
	assert_true(orc.spells.any(func(s: Spell) -> bool: return s.id == "orc_cri_de_guerre"), "sort racial de l'orc")
	assert_true(bones.spells.any(func(s: Spell) -> bool: return s.id == "squelette_remonter_les_os"), "sort racial du squelette")
	var combat := Fixtures.combat(Fixtures.map(), C, [["mannequin", C + RIGHT], ["mannequin", C + RIGHT * 3]])
	combat.start()
	var player := combat.get_fighter(Fixtures.PLAYER)
	var near := combat.get_fighter("m0")
	near.passives = {"reduction_melee": 10}
	assert_eq(Combat.damage_value(player, near, "acier", 100), 90, "Peau épaisse : −10 % au contact")
	assert_eq(Combat.damage_value(player, combat.get_fighter("m1"), "acier", 100), 100, "à distance : rien")
	near.passives = {"deja_mort": 1}
	var events: Array[Dictionary] = []
	var blow := {"type": Spell.EFFECT_DAMAGE, "element": "acier", "min": 999, "max": 999}
	combat._apply_effect(player, near, blow, events)
	assert_eq(near.hp, 1, "Déjà mort : survit à 1 PV")
	combat._apply_effect(player, near, blow, events)
	assert_false(near.is_alive(), "une seule fois par combat")
	player.hp = 10
	var heal: Dictionary = data.spells["squelette_remonter_les_os"].effects[0]
	combat._apply_effect(player, player, heal, events)
	assert_eq(player.hp, 10 + roundi(player.max_hp * 0.15), "Remonter les os : 15 % des PV max")
	var cry: Dictionary = data.spells["orc_cri_de_guerre"].effects[0]
	combat._apply_effect(player, player, cry, events)
	assert_eq(Combat.dealt_factor(player), 1.1, "Cri de guerre : +10 % de dégâts")
