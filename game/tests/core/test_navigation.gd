extends "res://tests/test_case.gd"
## PNJ, sorties de carte et changement de carte.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

## Carte de test 9 × 9 : lignes impaires de 9 cases, paires de 8 (+ demi-case de bord).
const LAST_LINE := 8
const LAST_CHAR := 8

var _maps := {}


func before_each() -> void:
	_maps = {
		"ouest": Fixtures.map({}, [], {"id": "ouest", "sorties": {"droite": "est"}}),
		"est": Fixtures.map({Fixtures.center(): "1"}, [{"monstres": ["mannequin"]}], {"id": "est", "sorties": {"gauche": "ouest"}}),
	}


func _loader(map_id: String) -> GameMap:
	return _maps.get(map_id)


func _world() -> World:
	return World.new(_maps["ouest"], Fixtures.data(), _loader)


func _move(world: World, target: Vector2i, exit := "") -> Array[Dictionary]:
	return world.execute({"type": Protocol.CMD_MOVE, "entite": World.PLAYER_ID, "cible": target, "sortie": exit})


# --- Bords et sorties ---

func test_directions_de_sortie() -> void:
	var map: GameMap = _maps["ouest"]
	assert_eq(map.exit_directions(GameMap.plan_cell(4, LAST_CHAR)), ["droite"] as Array[String], "bord droit")
	assert_eq(map.exit_directions(GameMap.plan_cell(3, LAST_CHAR)), ["droite"] as Array[String], "bord droit, ligne décalée")
	assert_eq(map.exit_directions(GameMap.plan_cell(4, 0)).size(), 0, "bord gauche sans sortie")
	assert_eq(map.exit_directions(Fixtures.center()).size(), 0, "milieu de carte")
	var corners: GameMap = Fixtures.map({}, [], {"sorties": {"haut": "a", "gauche": "b"}})
	assert_eq(corners.exit_directions(GameMap.plan_cell(0, 0)), ["haut", "gauche"] as Array[String], "coin haut gauche")


func test_case_d_arrivee() -> void:
	var map: GameMap = _maps["est"]
	# Sorti par la droite d'une carte, on arrive sur le bord gauche, à la même hauteur.
	var arrival := map.arrival_cell("droite", GameMap.plan_cell(4, LAST_CHAR))
	assert_eq(arrival, GameMap.plan_cell(4, 0))
	assert_eq(map.arrival_cell("gauche", GameMap.plan_cell(3, 1)), GameMap.plan_cell(3, LAST_CHAR))
	assert_eq(map.arrival_cell("bas", GameMap.plan_cell(LAST_LINE, 3)), GameMap.plan_cell(0, 3))
	assert_eq(map.arrival_cell("haut", GameMap.plan_cell(0, 5)), GameMap.plan_cell(LAST_LINE, 5))


func test_arrivee_sur_obstacle_decalee() -> void:
	var blocked: GameMap = Fixtures.map({GameMap.plan_cell(4, 0): "R"})
	var arrival := blocked.arrival_cell("droite", GameMap.plan_cell(4, LAST_CHAR))
	assert_true(blocked.is_walkable(arrival), "case praticable la plus proche")
	assert_eq(IsoGrid.distance(arrival, GameMap.plan_cell(4, 0)), 1)


func test_validation_pnj_et_sorties() -> void:
	var base := {"id": "test", "plan": Fixtures.plan_with({Fixtures.center(): "a"})}
	var valid := base.duplicate(true)
	valid["pnj"] = [{"marqueur": "a", "id": "p", "nom": "P", "repliques": ["Bonjour"]}]
	assert_eq(GameMap.validate(valid).size(), 0, "PNJ valide")
	var cases := {
		"PNJ absent de la liste": {},
		"répliques vides": {"pnj": [{"marqueur": "a", "id": "p", "nom": "P", "repliques": []}]},
		"marqueur invalide": {"pnj": [{"marqueur": "A", "id": "p", "nom": "P", "repliques": ["x"]}]},
		"sortie inconnue": {"pnj": valid["pnj"], "sorties": {"nord": "x"}},
		"sortie sans carte": {"pnj": valid["pnj"], "sorties": {"haut": ""}},
	}
	for label: String in cases:
		var data := base.duplicate(true)
		data.merge(cases[label], true)
		assert_true(GameMap.validate(data).size() > 0, label)


# --- Changement de carte ---

func test_changer_de_carte_et_revenir() -> void:
	var world := _world()
	var edge := GameMap.plan_cell(4, LAST_CHAR)
	var events := _move(world, edge, "droite")
	assert_eq(events[0]["type"], Protocol.EVT_MOVED)
	assert_eq(events[-1]["type"], Protocol.EVT_MAP_CHANGED)
	assert_eq(events[-1]["carte"], "est")
	assert_eq(world.map.id, "est")
	assert_eq(world.position_of(World.PLAYER_ID), GameMap.plan_cell(4, 0))
	assert_eq(world.groups().size(), 1, "les groupes de la nouvelle carte")
	assert_eq(world.neighbor_name("gauche"), "ouest")

	var back := _move(world, GameMap.plan_cell(4, 0), "gauche")
	assert_eq(back.size(), 1, "déjà au bord : changement direct")
	assert_eq(world.map.id, "ouest")
	assert_eq(world.groups().size(), 0)


func test_les_groupes_vaincus_ne_reviennent_pas() -> void:
	var world := _world()
	_move(world, GameMap.plan_cell(4, LAST_CHAR), "droite")
	world.execute({"type": Protocol.CMD_ENGAGE, "entite": World.PLAYER_ID, "groupe": "groupe_1"})
	var monster := world.combat.get_fighter("groupe_1_1")
	var player := world.combat.get_fighter(World.PLAYER_ID)
	for neighbor in IsoGrid.neighbors_4(monster.cell):
		if world.combat.is_free(neighbor):
			player.cell = neighbor
			break
	monster.hp = 1
	world.execute({"type": Protocol.CMD_READY, "entite": World.PLAYER_ID})
	world.execute({"type": Protocol.CMD_CAST, "entite": World.PLAYER_ID, "sort": "frappe", "cible": monster.cell})
	assert_false(world.in_combat())
	assert_eq(world.groups().size(), 0)
	_move(world, GameMap.plan_cell(4, 0), "gauche")
	_move(world, GameMap.plan_cell(4, LAST_CHAR), "droite")
	assert_eq(world.groups().size(), 0, "le groupe vaincu n'est pas revenu")


func test_sorties_refusees() -> void:
	var world := _world()
	assert_eq(_move(world, Fixtures.center(), "droite")[0]["raison"], Protocol.REASON_NO_EXIT, "pas au bord")
	assert_eq(_move(world, GameMap.plan_cell(4, 0), "gauche")[0]["raison"], Protocol.REASON_NO_EXIT, "pas de sortie à gauche")
	var lost := World.new(Fixtures.map({}, [], {"sorties": {"droite": "nulle_part"}}), null, _loader)
	assert_eq(_move(lost, GameMap.plan_cell(4, LAST_CHAR), "droite")[0]["raison"], Protocol.REASON_UNKNOWN_MAP)
	assert_eq(lost.map.id, "test", "on reste sur place")


# --- PNJ ---

func test_parler_a_un_pnj() -> void:
	var npc_cell := Fixtures.center()
	var map := Fixtures.map({npc_cell: "a"}, [], {"pnj": [{"marqueur": "a", "id": "alric", "nom": "Alric", "repliques": ["Bonjour", "Au revoir"]}]})
	assert_false(map.is_walkable(npc_cell), "le PNJ bloque sa case")
	var world := World.new(map)
	var events := world.execute({"type": Protocol.CMD_TALK, "entite": World.PLAYER_ID, "pnj": "alric"})
	assert_eq(events[0]["type"], Protocol.EVT_MOVED, "le joueur va jusqu'au PNJ")
	assert_eq(events[-1]["type"], Protocol.EVT_DIALOGUE)
	assert_eq(events[-1]["nom"], "Alric")
	assert_eq(events[-1]["repliques"], ["Bonjour", "Au revoir"])
	var player := world.position_of(World.PLAYER_ID)
	assert_true(maxi(absi(player.x - npc_cell.x), absi(player.y - npc_cell.y)) <= 1, "à côté du PNJ")
	var again := world.execute({"type": Protocol.CMD_TALK, "entite": World.PLAYER_ID, "pnj": "alric"})
	assert_eq(again.size(), 1, "déjà à côté : dialogue direct")
	var unknown := world.execute({"type": Protocol.CMD_TALK, "entite": World.PLAYER_ID, "pnj": "personne"})
	assert_eq(unknown[0]["raison"], Protocol.REASON_UNKNOWN_ENTITY)
