extends "res://tests/test_case.gd"
## Orc, Squelette et Géant (GDD § 4.2) : Peau épaisse, Déjà mort, Carrure, Cœur élémentaire, Cri de guerre et Remonter les os.

const Fixtures := preload("res://tests/helpers/fixtures.gd")
const RIGHT := Vector2i(1, 0)

var C := Fixtures.center()


func test_passifs_et_sorts() -> void:
	var data := GameData.load_all()
	var orc := data.create_character_fighter(Character.create("Grok", "orc", "guerrier"), "orc")
	var bones := data.create_character_fighter(Character.create("Osric", "squelette", "guerrier"), "os")
	assert_eq([orc.passives["reduction_melee"], bones.passives["deja_mort"]], [10, 1])
	var giant := Character.create("Gudrun", "geant", "guerrier")
	assert_true(data.create_character_fighter(giant, "g").spells.any(func(s: Spell) -> bool: return s.id == "geant_coup_de_semelle"), "sort racial du géant")
	var arkhe := data.create_character_fighter(Character.create("Ignis", "arkhe", "guerrier"), "a")
	assert_eq([arkhe.power("flamme"), arkhe.resistance("flamme"), arkhe.power("givre")], [5, 5.0, 0], "Cœur élémentaire : +5 % Flamme")
	assert_true(arkhe.spells.any(func(s: Spell) -> bool: return s.id == "arkhe_eruption"), "sort racial de l'Arkhé")
	var frost := data.create_character_fighter(Character.create("Givrine", "arkhe_givre", "guerrier"), "g")
	assert_eq([frost.power("givre"), frost.power("flamme")], [5, 0], "Arkhé Givre : Cœur élémentaire en Givre")
	assert_eq(data.spells["arkhe_eruption_givre"].effects[0]["element"], "givre", "Éruption de l'Arkhé Givre")
	assert_eq(giant.max_hp(data), Character.create("Hugo", "humain", "guerrier").max_hp(data) * 110 / 100, "Carrure : +10 % de PV max")
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


func test_mycelien_et_nain() -> void:
	var data := GameData.load_all()
	var shroom := data.create_character_fighter(Character.create("Lamelle", "mycelien_girolle", "guerrier"), "my")
	assert_eq(shroom.passives[Combat.SPORES], 3, "Sporée de la Girolle")
	assert_true(shroom.spells.any(func(s: Spell) -> bool: return s.id == "mycelien_ragot"), "Ragot")
	var dwarf := data.create_character_fighter(Character.create("Gimbo", "nain", "guerrier"), "n")
	assert_eq([dwarf.combat_stat("retrait_pa"), dwarf.combat_stat("retrait_pm")], [20, 20], "Têtu comme une mule")
	var fury: Spell = data.spells["nain_fureur_des_profondeurs"]
	assert_eq(dwarf.cast_blocker(fury), Protocol.REASON_HP_TOO_HIGH, "Fureur : pas à pleine vie")
	dwarf.hp = dwarf.max_hp / 2 - 1
	assert_eq(dwarf.cast_blocker(fury), "", "Fureur : sous 50 % de PV")
	var combat := Fixtures.combat(Fixtures.map(), C, [["mannequin", C + RIGHT], ["mannequin", C + RIGHT * 3]])
	combat.start()
	var player := combat.get_fighter(Fixtures.PLAYER)
	var near := combat.get_fighter("m0")
	var far := combat.get_fighter("m1")
	player.passives[Combat.SPORES] = 3
	var events: Array[Dictionary] = []
	var hit := {"type": Spell.EFFECT_DAMAGE, "element": "acier", "min": 1, "max": 1}
	for i in 2:
		combat._apply_effect(near, player, hit, events)
	combat._apply_effect(far, player, hit, events)
	var poisons := func(f: Fighter) -> int: return f.states.filter(func(s: Dictionary) -> bool: return s["type"] == Spell.EFFECT_POISON).size()
	assert_eq([poisons.call(near), poisons.call(far)], [1, 0], "Sporée : au contact, une fois par tour")
