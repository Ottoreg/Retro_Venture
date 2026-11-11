extends "res://tests/test_case.gd"
## Instances de métier (GDD § 10.3, `Plots`) : ouverture par la réputation, ressources débloquées par la maîtrise,
## disposition, instance personnelle, pousse à l'horloge réelle (le temps dehors compte), demi-réputation, sauvegarde.

const Fixtures := preload("res://tests/helpers/fixtures.gd")
const JobsTest := preload("res://tests/core/test_jobs.gd")

var _world: World
var _now := 1000.0
var _plot := GameMap.plan_cell(4, 4)


func before_each() -> void:
	var gate := GameMap.plan_cell(2, 4)
	var maps := {"instance_bosquet": GameMap.from_dict({"id": "instance_bosquet", "plan": Fixtures.plan_with({}), "metier": "bucheron",
		"emplacements": [[4, 4], [6, 4]]})}
	var start := Fixtures.map({gate: "a"}, [], {"pnj": [{"marqueur": "a", "id": "commis", "nom": "Commis", "repliques": ["Non."],
		"entree": {"carte": "instance_bosquet"}}]})
	var data := GameData.from_dicts(Fixtures.spells(), [], [], [], JobsTest._items(), JobsTest._jobs())
	_world = World.new(start, data, func(id: String) -> GameMap: return GameMap.from_dict({"id": id, "plan": Fixtures.plan_with({}),
		"metier": "bucheron", "emplacements": [[4, 4], [6, 4]]}) if maps.has(id) else null, Fixtures.character())
	_world.wall_clock = func() -> float: return _now
	_world.rare_harvest_chance = 0.0


func _command(type: String, extra := {}) -> Array[Dictionary]:
	var command := {"type": type, "entite": World.PLAYER_ID}
	command.merge(extra, true)
	return _world.execute(command)


func _enter() -> bool:
	return _command(Protocol.CMD_TALK, {"pnj": "commis"}).any(func(e: Dictionary) -> bool: return e["type"] == Protocol.EVT_MAP_CHANGED)


func test_regles() -> void:
	assert_eq(Plots.level(2499), [])
	assert_eq(Plots.level(40000)[1], 25, "25 emplacements au palier Maître")
	assert_eq([Plots.unlock_cost(8), Plots.unlock_cost(15), Plots.unlock_cost(30)], [1, 2, 3])
	assert_eq(Plots.grow_time(22), 6900.0, "1 h 55 au niveau 22")
	assert_eq(Plots.grow_time(1, 30), 420.0, "bonus de pousse")


func test_ouverture_deblocage_et_disposition() -> void:
	assert_eq(_command(Protocol.CMD_UNLOCK_PLOT, {"metier": "bucheron", "marqueur": "F"})[0]["raison"], Protocol.REASON_REPUTATION_TOO_LOW)
	assert_false(_enter(), "fermée avant 2 500 de réputation")
	var character := _world.character
	character.add_job_reputation("bucheron", Plots.OPEN_REPUTATION)
	var points := character.job_points("bucheron")
	assert_eq(_command(Protocol.CMD_PLOT, {"metier": "bucheron", "case": _plot, "marqueur": "F"})[0]["raison"], Protocol.REASON_INVALID_COMMAND,
		"pas encore débloquée")
	assert_eq(_command(Protocol.CMD_UNLOCK_PLOT, {"metier": "bucheron", "marqueur": "C"})[0]["type"], Protocol.EVT_CHARACTER)
	assert_eq(character.job_points("bucheron"), points - 1, "1 point de maîtrise par ressource de niveau 8 au plus")
	_command(Protocol.CMD_UNLOCK_PLOT, {"metier": "bucheron", "marqueur": "F"})
	assert_eq(_command(Protocol.CMD_PLOT, {"metier": "bucheron", "case": GameMap.plan_cell(8, 4), "marqueur": "F"})[0]["raison"],
		Protocol.REASON_INVALID_COMMAND, "hors des emplacements")
	_command(Protocol.CMD_PLOT, {"metier": "bucheron", "case": _plot, "marqueur": "F"})
	assert_eq(character.plot_state("bucheron")["parcelles"], {Plots.key(_plot): ["F", _now + 600.0]}, "pousse de 10 min")
	var saved := Character.from_dict(character.to_dict(), _world.data.items)
	assert_eq(saved.plot_state("bucheron"), character.plot_state("bucheron"), "sauvegardée avec le personnage")


func test_instance_personnelle_et_pousse() -> void:
	_world.character.add_job_reputation("bucheron", Plots.OPEN_REPUTATION)
	_command(Protocol.CMD_UNLOCK_PLOT, {"metier": "bucheron", "marqueur": "F"})
	_command(Protocol.CMD_PLOT, {"metier": "bucheron", "case": _plot, "marqueur": "F"})
	assert_true(_enter())
	var snapshot := _world.snapshot()
	assert_eq(snapshot["parcelles"], [{"case": _plot, "marqueur": "F"}])
	assert_eq(snapshot["epuisees"], [_plot], "elle pousse encore")
	_now += 700.0  # Dehors ou non, le temps passe : à la prochaine entrée, la ressource est mûre.
	_command(Protocol.CMD_MOVE, {"cible": _world.map.approach_path(_world.position_of(World.PLAYER_ID), _plot)[-1]})
	assert_eq(_world.snapshot()["epuisees"], [_plot], "dans l'instance, la pousse suit l'horloge du monde")
	_world.update(700.0)
	assert_eq(_world.snapshot()["epuisees"], [], "mûre")
	var started := _command(Protocol.CMD_HARVEST, {"case": _plot})
	var finished := _world.update(started[0]["duree"])
	var job: Dictionary = finished.filter(func(e: Dictionary) -> bool: return e["type"] == Protocol.EVT_JOB)[0]
	assert_eq(job["gain"], Profession.reputation_gain(5, 1, Plots.OPEN_REPUTATION, 0), "la moitié de la réputation d'une récolte sauvage")
	assert_eq(_world.character.plot_state("bucheron")["parcelles"][Plots.key(_plot)][1], _now + 600.0, "elle repousse seule")
	var placed := _command(Protocol.CMD_PLOT, {"metier": "bucheron", "case": GameMap.plan_cell(6, 4), "marqueur": "F"})
	assert_eq(placed[0]["type"], Protocol.EVT_PLOTS, "dans l'instance, la carte change sous ses yeux")
	assert_eq(_world.map.resource_nodes.get(GameMap.plan_cell(6, 4)), "F")
	assert_true(GameMap.plan_cell(6, 4) in placed[0]["epuisees"], "elle pousse")
