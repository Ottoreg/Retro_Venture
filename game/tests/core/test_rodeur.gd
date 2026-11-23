extends "res://tests/test_case.gd"
## Rôdeur (GDD § 4.3) : Traces (Voie Acier), Mines et Détonateur, Mâchoire de loup, Piège à fil, Écran de fumée et Fusée
## éclairante (Voie Flamme), passif « Rabatteur », rangs de maîtrise. Sorts tirés des données du jeu, sans coup critique.

const Fixtures := preload("res://tests/helpers/fixtures.gd")
const RIGHT := Vector2i(1, 0)

var C := Fixtures.center()


func _data() -> GameData:
	var spells := Fixtures.spells()
	var voie: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/voies/rodeur.json"))
	for spell_id: String in voie["sorts"]:
		var spell: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sorts/%s.json" % spell_id))
		spell["critique"] = 0
		spells.append(spell)
	var races := [{"id": "testeur", "nom": "Testeur", "camp": "allie", "carte_depart": "test", "passif": {"nom": "Aucun", "effets": []}}]
	return GameData.from_dicts(spells, [Fixtures.monster("mannequin", 300, 6, 0, 10, ["frappe"]), Fixtures.monster("coureur", 300, 0, 6, 10, ["frappe"])],
		[voie], races, Fixtures.items(), [], [])


## Le Rôdeur en C (rang + 1 du passif : `passive`) contre des monstres (`kind`), sur une carte changée par `changes`.
func _fight(monsters: Array, kind := "mannequin", changes := {}, passive := 0) -> Combat:
	var data := _data()
	var fighters: Array[Fighter] = []
	var player := data.create_player("rodeur", Fixtures.PLAYER, "Testeur")
	player.cell = C
	player.passives["rabatteur"] = passive
	player.max_hp = 500
	player.hp = 500
	fighters.append(player)
	for i in monsters.size():
		var monster := data.create_monster(kind, "m%d" % i)
		monster.cell = monsters[i]
		fighters.append(monster)
	var placement: Array[Vector2i] = [C]
	var combat := Combat.new(Fixtures.map(changes), fighters, placement, 1)
	combat.start()
	combat.execute(Fixtures.cmd(Protocol.CMD_READY))
	return combat


func _cast(combat: Combat, spell_id: String, target: Vector2i) -> Array[Dictionary]:
	combat.get_fighter(Fixtures.PLAYER).pa = 20
	return combat.execute(Fixtures.cmd(Protocol.CMD_CAST, {"sort": spell_id, "cible": target}))


## Met le sort `spell_id` du Rôdeur au rang `rank`.
func _rank(combat: Combat, spell_id: String, rank: int) -> void:
	var spells := combat.get_fighter(Fixtures.PLAYER).spells
	for i in spells.size():
		if spells[i].id == spell_id:
			spells[i] = spells[i].mastered(rank)


func test_vingt_sorts_et_passif() -> void:
	var data := GameData.load_all()
	assert_eq(data.voies["rodeur"]["sorts"].size(), 20, "10 sorts Acier et 10 Flamme")
	assert_eq(data.voies["rodeur"]["passif"]["effet"], "rabatteur")
	assert_eq((data.spells["rodeur_fleche"] as Spell).effects[0]["element"], "acier", "la Flèche passe en Acier")
	for spell_id: String in data.voies["rodeur"]["sorts"]:
		assert_true((data.spells[spell_id] as Spell).mastered(5) != null, spell_id)


func test_traces_et_coup_de_dague() -> void:
	var combat := _fight([C + Vector2i(3, 0)])
	var dummy := combat.get_fighter("m0")
	var player := combat.get_fighter(Fixtures.PLAYER)
	_cast(combat, "rodeur_fleche", dummy.cell)
	assert_eq(dummy.stacks(Spell.EFFECT_TRACE), 1, "un tir Acier pose une Trace")
	_cast(combat, "rodeur_pister", dummy.cell)
	_cast(combat, "rodeur_tir_percant", dummy.cell)
	assert_eq(dummy.stacks(Spell.EFFECT_TRACE), Combat.TRACE_MAX, "3 Traces au plus")
	dummy.cell = C + RIGHT
	assert_eq(combat.damage_bonus(player, dummy, player.get_spell("rodeur_dague").effects[0]), 90, "+30 % par Trace")
	_rank(combat, "rodeur_dague", 5)
	_cast(combat, "rodeur_dague", dummy.cell)
	assert_eq(dummy.stacks(Spell.EFFECT_TRACE), 0, "les Traces partent")
	assert_eq(dummy.pm_malus, 3, "rang 5 : 1 PM retiré par Trace")


func test_mines_et_detonateur() -> void:
	var combat := _fight([C + Vector2i(3, 0)])
	var dummy := combat.get_fighter("m0")
	assert_eq(_cast(combat, "rodeur_detonateur", C)[0]["raison"], Protocol.REASON_NO_TRAP, "rien à faire sauter")
	for cell in [C + Vector2i(0, 3), C + Vector2i(3, 1), C + Vector2i(2, 0)]:
		_cast(combat, "rodeur_mine", cell)
	assert_eq(combat.traps.size(), 2, "2 Mines à la fois : la plus ancienne part")
	var hp := dummy.hp
	var events := _cast(combat, "rodeur_detonateur", C)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_TRAP_TRIGGERED).size(), 2, "toutes les Mines sautent")
	assert_true(combat.traps.is_empty())
	assert_true(dummy.hp < hp, "deux explosions autour de lui")


func test_rabatteur() -> void:
	for passive in [1, 4, 6]:
		var combat := _fight([C + Vector2i(2, 0)], "coureur", {}, passive)
		var dummy := combat.get_fighter("m0")
		var player := combat.get_fighter(Fixtures.PLAYER)
		_cast(combat, "rodeur_collet", C + Vector2i(4, 0))
		player.pa = 5
		var events := combat.execute(Fixtures.cmd(Protocol.CMD_CAST, {"sort": "rodeur_fleche_de_rabat", "cible": dummy.cell}))
		assert_eq(Fixtures.of_type(events, Protocol.EVT_TRAP_TRIGGERED).size(), 1, "poussé dans le Collet")
		var lost: Array = Fixtures.of_type(events, Protocol.EVT_DAMAGE).map(func(event: Dictionary) -> int: return event["valeur"])
		assert_true(lost[-1] >= roundi(7 * 1.2), "dégâts du piège + 20 % au moins")
		assert_eq(dummy.next_turn_pm() == 0, passive >= 4, "rang 3 : immobilisé")
		assert_eq(player.pa, 2 + int(passive >= 6), "rang 5 : 1 PA rendu")


func test_machoire_de_loup() -> void:
	var combat := _fight([C + Vector2i(0, 3)], "coureur")
	var runner := combat.get_fighter("m0")
	var jaw := C + Vector2i(0, 2)
	_cast(combat, "rodeur_machoire_de_loup", jaw)
	combat._push(C, runner, 1, true, [] as Array[Dictionary])
	assert_true(runner.has_state(Spell.STATE_CHAINED), "attiré dans la Mâchoire, il est enchaîné")
	assert_true(combat.reachable_cells(runner).keys().all(func(cell: Vector2i) -> bool: return IsoGrid.distance(cell, jaw) <= Combat.CHAIN_RADIUS),
		"il ne s'éloigne pas à plus de 3 cases du piège")
	combat.get_fighter(Fixtures.PLAYER).cell = C + Vector2i(-3, 0)
	combat._push(C + Vector2i(0, 3), runner, 6, false, [] as Array[Dictionary])
	assert_eq(runner.cell, C + Vector2i(0, -1), "une poussée s'arrête au bout de la chaîne")


func test_piege_a_fil() -> void:
	var combat := _fight([C + Vector2i(0, -3)], "coureur")
	_cast(combat, "rodeur_piege_a_fil", C + Vector2i(2, 0))
	var trap: Dictionary = combat.traps[0]
	assert_eq(trap["declencheurs"], [C + Vector2i(2, -1), C + Vector2i(2, 0), C + Vector2i(2, 1), C + Vector2i(2, 2)], "4 cases perpendiculaires au Rôdeur")
	var runner := combat.get_fighter("m0")
	runner.cell = C + Vector2i(3, 0)
	var hp := runner.hp
	var events: Array[Dictionary] = []
	combat._push(C + Vector2i(4, 0), runner, 1, false, events)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_TRAP_TRIGGERED).size(), 1, "traverser un fil fait tout sauter")
	assert_true(runner.hp < hp)


func test_fumee_et_fusee() -> void:
	var combat := _fight([C + Vector2i(4, 0)])
	var dummy := combat.get_fighter("m0")
	var player := combat.get_fighter(Fixtures.PLAYER)
	_cast(combat, "rodeur_ecran_de_fumee", C)
	assert_false(LineOfSight.is_clear(dummy.cell, C + Vector2i(-2, 0), combat._sight_blocker(dummy)), "la fumée coupe la ligne de vue")
	combat._place_trap(dummy, player.get_spell("rodeur_collet"), player.get_spell("rodeur_collet").trap_effect(), C + Vector2i(3, 2), [] as Array[Dictionary])
	dummy.states.append({"type": Spell.EFFECT_STATE, "etat": Spell.STATE_INVISIBLE, "valeur": 0, "tours": 3, "sort": "test"})
	var events := _cast(combat, "rodeur_fusee_eclairante", C + Vector2i(3, 1))
	assert_true(Fixtures.of_type(events, Protocol.EVT_TRAP).any(func(event: Dictionary) -> bool: return event.get("revele", false)), "piège ennemi révélé")
	assert_false(dummy.is_invisible(), "invisible révélé")
	assert_eq(dummy.resistance("flamme"), -15.0, "+15 % de dégâts Flamme reçus")
	assert_eq(combat.snapshot()["pieges"].size(), 1, "le piège révélé est dans la copie du joueur")


func test_couvert_et_saut_a_la_poudre() -> void:
	var combat := _fight([C + Vector2i(1, 1)])
	var player := combat.get_fighter(Fixtures.PLAYER)
	var dummy := combat.get_fighter("m0")
	_cast(combat, "rodeur_couvert", C)
	assert_eq(player.modifier("reduction_distance"), 25)
	dummy.cell = C + Vector2i(3, 0)
	var far := Combat.damage_value(dummy, player, "acier", 20)
	dummy.cell = C + RIGHT
	assert_eq(far, 15, "−25 % à distance")
	assert_eq(Combat.damage_value(dummy, player, "acier", 20), 20, "rien au contact")
	var hp := dummy.hp
	_rank(combat, "rodeur_saut_a_la_poudre", 5)
	_cast(combat, "rodeur_saut_a_la_poudre", C + Vector2i(-3, 0))
	assert_eq(player.cell, C + Vector2i(-3, 0))
	assert_true(dummy.hp < hp, "explosion autour de la case de départ")
	assert_eq(combat.traps.size(), 1, "rang 5 : une Mine laissée au départ")
	assert_eq(combat.traps[0]["sort_id"], "rodeur_mine", "qui compte comme une Mine")


func test_rangs_de_maitrise() -> void:
	var data := _data()
	assert_eq((data.spells["rodeur_collet"] as Spell).mastered(5).max_traps, 2, "Collet rang 5 : 2 à la fois")
	assert_eq((data.spells["rodeur_collet"] as Spell).mastered(3).trap_effect()["effets"].size(), 3, "rang 3 : −1 PM de plus")
	var jaw := (data.spells["rodeur_machoire_de_loup"] as Spell).mastered(3)
	assert_eq(jaw.trap_effect()["effets"][1]["duree"], 4, "Mâchoire rang 3 : 4 tours")
	assert_eq((data.spells["rodeur_piege_a_fil"] as Spell).mastered(5).trap_effect()["zone"]["taille"], 4, "Piège à fil rang 5 : 6 cases")
	assert_eq((data.spells["rodeur_fleche"] as Spell).mastered(5).casts_per_turn, 3)
	var combat := _fight([C + Vector2i(4, 0)])
	var dummy := combat.get_fighter("m0")
	dummy.hp = 1
	_rank(combat, "rodeur_tir_de_grace", 5)
	_cast(combat, "rodeur_tir_de_grace", dummy.cell)
	assert_false(dummy.is_alive())
	assert_eq(combat.get_fighter(Fixtures.PLAYER).cast_count(combat.get_fighter(Fixtures.PLAYER).get_spell("rodeur_tir_de_grace")), 0, "rang 5 : relancé si la cible meurt")
