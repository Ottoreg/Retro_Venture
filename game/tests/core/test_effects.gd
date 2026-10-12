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
