extends "res://tests/test_case.gd"
## Théologue (GDD § 4.3) : Terre consacrée, Procession, Génuflexion (Voie Sacrée), Hérésie, Bûcher, Commandement (Voie Flamme)
## et passif « Faire la quête » (Foi). Sorts tirés des données du jeu, sans coup critique.

const Fixtures := preload("res://tests/helpers/fixtures.gd")
const RIGHT := Vector2i(1, 0)
const ALLY := "allie"

var C := Fixtures.center()


func _data() -> GameData:
	var spells := Fixtures.spells()
	var voie: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/voies/theologue.json"))
	for spell_id: String in voie["sorts"]:
		var spell: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sorts/%s.json" % spell_id))
		spell["critique"] = 0
		spells.append(spell)
	var races := [{"id": "testeur", "nom": "Testeur", "camp": "allie", "carte_depart": "test", "passif": {"nom": "Aucun", "effets": []}}]
	return GameData.from_dicts(spells, [Fixtures.monster("mannequin", 200, 6, 0, 10, ["frappe"]), Fixtures.monster("coureur", 200, 6, 3, 10, ["frappe"])],
		[voie], races, Fixtures.items(), [], [])


## Le Théologue en C (rang + 1 du passif : `passive`), un allié en `ally` s'il est donné, contre des monstres (`kind`).
func _fight(monsters: Array, kind := "mannequin", passive := 0, ally := Fighter.NO_CELL) -> Combat:
	var data := _data()
	var fighters: Array[Fighter] = []
	var player := data.create_player("theologue", Fixtures.PLAYER, "Testeur")
	player.cell = C
	player.passives["faire_la_quete"] = passive
	player.max_hp = 500
	player.hp = 100
	fighters.append(player)
	if ally != Fighter.NO_CELL:
		var friend := data.create_player("theologue", ALLY, "Allié")
		friend.cell = ally
		friend.initiative = 1
		friend.max_hp = 500
		friend.hp = 100
		fighters.append(friend)
	for i in monsters.size():
		var monster := data.create_monster(kind, "m%d" % i)
		monster.cell = monsters[i]
		fighters.append(monster)
	var placement: Array[Vector2i] = [C, ally]
	var combat := Combat.new(Fixtures.map(), fighters, placement, 1)
	combat.start()
	combat.execute(Fixtures.cmd(Protocol.CMD_READY))
	combat.execute(Fixtures.cmd(Protocol.CMD_READY, {"entite": ALLY}))
	return combat


func _cast(combat: Combat, spell_id: String, target: Vector2i) -> Array[Dictionary]:
	combat.get_fighter(Fixtures.PLAYER).pa = 20
	return combat.execute(Fixtures.cmd(Protocol.CMD_CAST, {"sort": spell_id, "cible": target}))


func test_vingt_sorts_et_passif() -> void:
	var data := _data()
	assert_eq(data.voies["theologue"]["sorts"].size(), 20, "10 sorts Sacrés et 10 sorts Flamme")
	assert_eq(data.voies["theologue"]["passif"]["effet"], Combat.THEOLOGIAN_PASSIVE)


func test_heresie_et_bucher() -> void:
	var combat := _fight([C + Vector2i(2, 0), C + Vector2i(0, 2)])
	var accused := combat.get_fighter("m0")
	_cast(combat, "theologue_accusation", accused.cell)
	assert_eq(accused.stacks(Spell.EFFECT_HERESY), 2, "Accusation : +2 crans")
	_cast(combat, "theologue_tison", accused.cell)
	assert_eq(accused.stacks(Spell.EFFECT_HERESY), 3, "un sort Flamme qui touche : +1 cran")
	for i in 3:
		_cast(combat, "theologue_accusation" if i < 1 else "theologue_tison", accused.cell)
	assert_eq(accused.stacks(Spell.EFFECT_HERESY), Combat.HERESY_MAX, "5 crans au plus")
	_cast(combat, "theologue_absolution", accused.cell)
	assert_eq(accused.stacks(Spell.EFFECT_HERESY), Combat.HERESY_MAX, "Absolution ne retire pas l'Hérésie")
	var refused := _cast(combat, "theologue_bucher", C + Vector2i(0, 2))
	assert_eq(refused[0].get("raison"), Protocol.REASON_NO_HERESY, "pas de Bûcher sans Hérésie")
	var before := accused.hp
	_cast(combat, "theologue_bucher", accused.cell)
	assert_true(before - accused.hp >= 20 and before - accused.hp <= 30, "4 à 6 par cran (5 crans) : %d" % (before - accused.hp))
	assert_eq(accused.stacks(Spell.EFFECT_HERESY), 0, "les crans sont consommés")


func test_commandement() -> void:
	var combat := _fight([C + Vector2i(4, 0)], "coureur")
	var runner := combat.get_fighter("m0")
	_cast(combat, "theologue_commandement", runner.cell)
	assert_true(runner.has_state(Spell.STATE_COMMANDMENT))
	var before := runner.hp
	var events := combat.execute(Fixtures.cmd(Protocol.CMD_END_TURN))
	var walked := 0
	for moved in Fixtures.of_type(events, Protocol.EVT_MOVED):
		walked += moved["chemin"].size()
	assert_true(walked > 0, "le monstre marche quand même")
	assert_eq(before - runner.hp, Combat.PENANCE * walked, "une Pénitence par case marchée")
	assert_eq(runner.stacks(Spell.EFFECT_HERESY), mini(walked, Combat.HERESY_MAX), "et un cran d'Hérésie")


func test_terre_consacree() -> void:
	var combat := _fight([C + Vector2i(2, 0)])
	var player := combat.get_fighter(Fixtures.PLAYER)
	var dummy := combat.get_fighter("m0")
	_cast(combat, "theologue_terre_consacree", C + RIGHT)
	assert_true(combat.consecrated(C, player.team, false), "croix de 5 cases autour de la case visée")
	assert_false(combat.consecrated(C, dummy.team, false), "seulement pour son camp")
	assert_eq(combat.heal_boost(player, {}), Combat.CONSECRATED_HEAL, "+20 % de soins reçus")
	var events := _cast(combat, "theologue_imposition", C)
	var healed := int(Fixtures.of_type(events, Protocol.EVT_HEAL)[0]["valeur"])
	assert_true(healed >= 14 and healed <= 22, "12 à 18 × 1,2 : %d" % healed)
	var before := dummy.hp
	combat.execute(Fixtures.cmd(Protocol.CMD_END_TURN))
	assert_true(before - dummy.hp >= 5, "l'ennemi qui y commence son tour se brûle")


func test_faire_la_quete() -> void:
	var combat := _fight([C + Vector2i(2, 0)], "mannequin", 1)
	var player := combat.get_fighter(Fixtures.PLAYER)
	for i in 3:
		_cast(combat, "theologue_tison", C + Vector2i(2, 0))
	assert_eq(player.stacks(Combat.FAITH), 3, "1 Foi par sort qui blesse un ennemi")
	_cast(combat, "theologue_accusation", C + Vector2i(2, 0))
	assert_eq(player.stacks(Combat.FAITH), 3, "pas de Foi sans dégâts")
	var events := _cast(combat, "theologue_imposition", C)
	var healed := int(Fixtures.of_type(events, Protocol.EVT_HEAL)[0]["valeur"])
	assert_true(healed >= 14 and healed <= 21, "+6 %% par Foi au rang 0 : %d" % healed)
	assert_eq(player.stacks(Combat.FAITH), 0, "le soin dépense toute la Foi")


func test_faire_la_quete_rang_5() -> void:
	var combat := _fight([C + Vector2i(3, 0)], "mannequin", 6, C + Vector2i(0, 2))
	var player := combat.get_fighter(Fixtures.PLAYER)
	var ally := combat.get_fighter(ALLY)
	player.states.append({"type": Combat.FAITH, "valeur": Combat.FAITH_MAX, "tours": Combat.LASTING_TURNS, "sort": "", "lanceur": player.id, "retirable": false})
	_cast(combat, "theologue_imposition", C + Vector2i(0, 1))
	assert_eq(ally.hp, 100, "personne sur la case visée : pas de soin autour")
	ally.cell = C + Vector2i(0, 1)
	player.states.append({"type": Combat.FAITH, "valeur": Combat.FAITH_MAX, "tours": Combat.LASTING_TURNS, "sort": "", "lanceur": player.id, "retirable": false})
	combat.get_fighter(Fixtures.PLAYER)._casts_this_turn.clear()
	_cast(combat, "theologue_imposition", C)
	assert_true(ally.hp > 100, "à 5 Foi, l'allié au contact reçoit la moitié du soin")


func test_procession_et_controles() -> void:
	var combat := _fight([C + Vector2i(2, 0)], "mannequin", 0, C + Vector2i(0, 3))
	var player := combat.get_fighter(Fixtures.PLAYER)
	var dummy := combat.get_fighter("m0")
	assert_eq(_cast(combat, "theologue_procession", dummy.cell)[0].get("raison"), Protocol.REASON_OCCUPIED, "pas d'échange avec un ennemi")
	_cast(combat, "theologue_procession", C + Vector2i(0, 3))
	assert_eq(player.cell, C + Vector2i(0, 3), "échange avec l'allié")
	assert_eq(combat.get_fighter(ALLY).cell, C)
	dummy.cell = player.cell + Vector2i(0, -2)
	_cast(combat, "theologue_genuflexion", dummy.cell)
	assert_eq(dummy.modifier("degats_infliges"), -15.0, "Génuflexion : −15 % de dégâts infligés")
	_cast(combat, "theologue_la_question", dummy.cell)
	assert_true(dummy.states.any(func(state: Dictionary) -> bool: return state.get("carac") == "pa" and state["type"] == Spell.EFFECT_MALUS), "La Question : −2 PA")
