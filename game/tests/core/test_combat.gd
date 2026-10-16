extends "res://tests/test_case.gd"

const Fixtures := preload("res://tests/helpers/fixtures.gd")
const RIGHT := Vector2i(1, 0)
const DOWN := Vector2i(0, 1)

var C := Fixtures.center()


func _fight(monsters: Array, changes := {}) -> Combat:
	var combat := Fixtures.combat(Fixtures.map(changes), C, monsters)
	combat.start()
	combat.execute(Fixtures.cmd(Protocol.CMD_READY))
	return combat


func _cast(combat: Combat, spell_id: String, target: Vector2i) -> Array[Dictionary]:
	return combat.execute(Fixtures.cmd(Protocol.CMD_CAST, {"sort": spell_id, "cible": target}))


func _end_turn(combat: Combat) -> Array[Dictionary]:
	return combat.execute(Fixtures.cmd(Protocol.CMD_END_TURN))


func _player(combat: Combat) -> Fighter:
	return combat.get_fighter(Fixtures.PLAYER)


func _assert_refused(events: Array[Dictionary], reason: String) -> void:
	assert_eq(events.size(), 1)
	if events.size() == 1:
		assert_eq(events[0]["type"], Protocol.EVT_REFUSED)
		assert_eq(events[0]["raison"], reason)


# --- Placement et ordre de jeu ---

func test_placement() -> void:
	var combat := Fixtures.combat(Fixtures.map(), C, [["mannequin", C + Vector2i(0, -1)]])
	var start := combat.start()
	assert_eq(start[0]["type"], Protocol.EVT_COMBAT_STARTED)
	assert_eq(start[0]["combattants"].size(), 2)
	var events := combat.execute(Fixtures.cmd(Protocol.CMD_PLACE, {"cible": C + Vector2i(-1, 0)}))
	assert_eq(events[0]["type"], Protocol.EVT_PLACED)
	assert_eq(_player(combat).cell, C + Vector2i(-1, 0))
	_assert_refused(combat.execute(Fixtures.cmd(Protocol.CMD_PLACE, {"cible": C + Vector2i(3, 3)})), Protocol.REASON_NOT_PLACEMENT_CELL)
	_assert_refused(combat.execute(Fixtures.cmd(Protocol.CMD_PLACE, {"cible": C + Vector2i(0, -1)})), Protocol.REASON_OCCUPIED)
	_assert_refused(combat.execute(Fixtures.cmd(Protocol.CMD_MOVE, {"cible": C})), Protocol.REASON_WRONG_PHASE)


func test_ordre_par_initiative() -> void:
	var combat := Fixtures.combat(Fixtures.map(), C, [["rapide", C + Vector2i(3, 0)], ["mannequin", C + Vector2i(0, 3)]])
	combat.start()
	var events := combat.execute(Fixtures.cmd(Protocol.CMD_READY))
	assert_eq(events[0]["type"], Protocol.EVT_FIGHT_BEGINS)
	assert_eq(events[0]["ordre"], ["m0", Fixtures.PLAYER, "m1"] as Array[String])
	# Le monstre rapide joue (et ne fait rien), puis la main passe au joueur.
	var starts := Fixtures.of_type(events, Protocol.EVT_TURN_STARTED)
	assert_eq(starts.size(), 2)
	assert_eq(starts[0]["entite"], "m0")
	assert_eq(starts[1]["entite"], Fixtures.PLAYER)
	assert_eq(combat.current_fighter(), _player(combat))
	assert_eq(combat.round_number, 1)


# --- Déplacements ---

func test_deplacement_et_pm() -> void:
	var combat := _fight([["mannequin", C + RIGHT]])
	var events := combat.execute(Fixtures.cmd(Protocol.CMD_MOVE, {"cible": C + Vector2i(-2, 0)}))
	assert_eq(events[0]["type"], Protocol.EVT_MOVED)
	assert_eq(events[0]["chemin"].size(), 2)
	assert_eq(events[0]["pm"], 1)
	_assert_refused(combat.execute(Fixtures.cmd(Protocol.CMD_MOVE, {"cible": C + Vector2i(-2, 3)})), Protocol.REASON_NOT_ENOUGH_PM)
	_assert_refused(combat.execute(Fixtures.cmd(Protocol.CMD_MOVE, {"cible": C + RIGHT})), Protocol.REASON_OCCUPIED)
	_assert_refused(combat.execute({"type": Protocol.CMD_MOVE, "entite": "m0", "cible": C}), Protocol.REASON_NOT_YOUR_TURN)


func test_les_combattants_bloquent_le_passage() -> void:
	# Mannequins en travers : il faut les contourner, ce qui coûte plus de PM.
	var combat := _fight([["mannequin", C + RIGHT], ["mannequin", C + RIGHT + DOWN], ["mannequin", C + RIGHT - DOWN]])
	var reachable := combat.reachable_cells(_player(combat))
	assert_false(reachable.has(C + Vector2i(2, 0)), "case derrière le mur de mannequins hors d'atteinte avec 3 PM")
	assert_false(reachable.has(C + RIGHT), "case occupée")


# --- Sorts ---

func test_degats_et_pa() -> void:
	var combat := _fight([["mannequin", C + RIGHT]])
	var events := _cast(combat, "frappe", C + RIGHT)
	assert_eq(events[0]["type"], Protocol.EVT_SPELL_CAST)
	assert_eq(events[0]["pa"], 3)
	var damage := Fixtures.of_type(events, Protocol.EVT_DAMAGE)
	assert_eq(damage.size(), 1)
	assert_eq(damage[0]["valeur"], 10)
	assert_eq(damage[0]["pv"], 20)
	_cast(combat, "frappe", C + RIGHT)
	assert_eq(combat.get_fighter("m0").hp, 10)
	_assert_refused(_cast(combat, "frappe", C + RIGHT), Protocol.REASON_NOT_ENOUGH_PA)


func test_limite_de_lancers_par_tour() -> void:
	var combat := _fight([["mannequin", C + RIGHT]])
	_cast(combat, "piqure", C + RIGHT)
	_cast(combat, "piqure", C + RIGHT)
	_assert_refused(_cast(combat, "piqure", C + RIGHT), Protocol.REASON_SPELL_LIMIT)
	_end_turn(combat)
	assert_eq(Fixtures.of_type(_cast(combat, "piqure", C + RIGHT), Protocol.EVT_DAMAGE).size(), 1, "limite remise à zéro au tour suivant")


func test_resistances() -> void:
	var combat := _fight([["blinde", C + RIGHT]])
	var damage := Fixtures.of_type(_cast(combat, "frappe", C + RIGHT), Protocol.EVT_DAMAGE)
	assert_eq(damage[0]["valeur"], 5, "50 % de résistance à l'acier")


func test_portee() -> void:
	var combat := _fight([["mannequin", C + RIGHT], ["mannequin", C + Vector2i(0, 4)]])
	_assert_refused(_cast(combat, "tir", C + RIGHT), Protocol.REASON_OUT_OF_RANGE)
	_assert_refused(_cast(combat, "frappe", C + Vector2i(0, 4)), Protocol.REASON_OUT_OF_RANGE)
	assert_eq(Fixtures.of_type(_cast(combat, "tir", C + Vector2i(0, 4)), Protocol.EVT_DAMAGE).size(), 1)


func test_ligne_de_vue() -> void:
	var target := C + Vector2i(3, 0)
	var blocked := _fight([["mannequin", target]], {C + RIGHT: "R"})
	_assert_refused(_cast(blocked, "tir", target), Protocol.REASON_NO_LINE_OF_SIGHT)
	var water := _fight([["mannequin", target]], {C + RIGHT: "E"})
	assert_eq(Fixtures.of_type(_cast(water, "tir", target), Protocol.EVT_DAMAGE).size(), 1, "l'eau ne bloque pas la vue")
	var body := _fight([["mannequin", target], ["mannequin", C + Vector2i(2, 0)]])
	_assert_refused(_cast(body, "tir", target), Protocol.REASON_NO_LINE_OF_SIGHT)
	var view := body.spell_range(_player(body), body.get_fighter("m0").spells[0])
	assert_true(view.has("visibles") and view.has("masquees"))


func test_zone_autour_du_lanceur() -> void:
	var combat := _fight([["mannequin", C + RIGHT], ["mannequin", C + DOWN], ["mannequin", C + Vector2i(2, 0)]])
	var damage := Fixtures.of_type(_cast(combat, "zone", C), Protocol.EVT_DAMAGE)
	assert_eq(damage.size(), 2, "les deux voisins, pas le lanceur ni la case à 2 pas")
	assert_eq(_player(combat).hp, 50)


func test_soin_et_delai_de_relance() -> void:
	var combat := _fight([["mannequin", C + Vector2i(3, 3)]])
	_player(combat).hp = 30
	var heal := Fixtures.of_type(_cast(combat, "soin", C), Protocol.EVT_HEAL)
	assert_eq(heal[0]["valeur"], 10)
	assert_eq(_player(combat).hp, 40)
	_end_turn(combat)
	_assert_refused(_cast(combat, "soin", C), Protocol.REASON_SPELL_COOLDOWN)
	_end_turn(combat)
	assert_eq(Fixtures.of_type(_cast(combat, "soin", C), Protocol.EVT_HEAL).size(), 1, "disponible 2 tours plus tard")
	assert_eq(_player(combat).hp, 50, "le soin ne dépasse pas les PV max")


# --- Fin du combat ---

func test_victoire() -> void:
	var combat := _fight([["mannequin", C + RIGHT]])
	_cast(combat, "frappe", C + RIGHT)
	_cast(combat, "frappe", C + RIGHT)
	_end_turn(combat)
	var events := _cast(combat, "frappe", C + RIGHT)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_DIED).size(), 1)
	var end := Fixtures.of_type(events, Protocol.EVT_COMBAT_ENDED)
	assert_eq(end.size(), 1)
	assert_eq(end[0]["vainqueur"], Fighter.TEAM_PLAYERS)
	assert_eq(end[0]["xp"], 10)
	assert_eq(combat.state, Combat.State.FINISHED)
	_assert_refused(_end_turn(combat), Protocol.REASON_WRONG_PHASE)


func test_defaite() -> void:
	var combat := _fight([["loup", C + RIGHT]])
	_player(combat).hp = 5
	var events := _end_turn(combat)
	var end := Fixtures.of_type(events, Protocol.EVT_COMBAT_ENDED)
	assert_eq(end.size(), 1)
	assert_eq(end[0]["vainqueur"], Fighter.TEAM_MONSTERS)
	assert_eq(end[0]["xp"], 0)
	assert_false(_player(combat).is_alive())


# --- IA ---

func test_ia_de_melee_s_approche_et_frappe() -> void:
	var combat := _fight([["loup", C + Vector2i(3, 0)]])
	var events := _end_turn(combat)
	var moves := Fixtures.of_type(events, Protocol.EVT_MOVED)
	assert_eq(moves.size(), 1)
	assert_eq(moves[0]["entite"], "m0")
	assert_eq(IsoGrid.distance(combat.get_fighter("m0").cell, C), 1, "le loup est au contact")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_DAMAGE).size(), 2, "deux frappes avec 6 PA")
	assert_eq(_player(combat).hp, 30)
	assert_eq(events[-1]["type"], Protocol.EVT_TURN_STARTED)
	assert_eq(events[-1]["entite"], Fixtures.PLAYER, "la main revient au joueur")


func test_ia_a_distance_recule_pour_tirer() -> void:
	var combat := _fight([["archer", C + RIGHT]])
	var events := _end_turn(combat)
	var distance := IsoGrid.distance(combat.get_fighter("m0").cell, C)
	assert_true(distance >= 2, "l'archer prend ses distances (distance %d)" % distance)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_DAMAGE).size(), 1)
	assert_eq(_player(combat).hp, 45)


func test_ia_bloquee_finit_son_tour() -> void:
	# Loup enfermé derrière des rochers : il ne peut ni frapper ni approcher.
	var wolf := C + Vector2i(3, 0)
	var walls := {}
	for neighbor in IsoGrid.neighbors_4(wolf):
		walls[neighbor] = "R"
	var combat := _fight([["loup", wolf]], walls)
	var events := _end_turn(combat)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_DAMAGE).size(), 0)
	assert_eq(combat.current_fighter(), _player(combat))


func test_les_pnj_ne_bloquent_pas_le_combat() -> void:
	# Un PNJ au milieu de la carte : obstacle en exploration, case libre en combat (il n'y est pas).
	var npc_cell := Fixtures.center() + Vector2i(1, 0)
	var game_map := Fixtures.map({npc_cell: "a"}, [], {"pnj": [{"marqueur": "a", "id": "badaud", "nom": "Badaud", "repliques": ["…"]}]})
	assert_false(game_map.is_walkable(npc_cell), "bloquée en exploration")
	assert_true(game_map.is_walkable_in_combat(npc_cell), "libre en combat")
	var combat := Fixtures.combat(game_map, Fixtures.center(), [["mannequin", Fixtures.center() + Vector2i(4, 0)]])
	assert_true(combat.is_free(npc_cell))
	assert_true(combat.reachable_cells(combat.get_fighter(Fixtures.PLAYER)).has(npc_cell), "on peut y marcher")
