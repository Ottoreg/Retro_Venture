extends "res://tests/test_case.gd"
## Mode admin (tests du jeu) : mot de passe, objets, brumes, réputation et points de métier et de classe,
## téléportation.

const Fixtures := preload("res://tests/helpers/fixtures.gd")
const JobsTest := preload("res://tests/core/test_jobs.gd")

var _world: World


func before_each() -> void:
	var voies := [{"id": "test", "nom": "Test", "caracteristiques": {"pv": 50, "pa": 6, "pm": 3, "initiative": 100}, "sorts": ["frappe"]}]
	var data := GameData.from_dicts(Fixtures.spells(), [], voies, [], JobsTest._items(), JobsTest._jobs())
	_world = World.new(Fixtures.map(), data, func(id: String) -> GameMap:
		return GameMap.from_dict({"id": id, "plan": Fixtures.plan_with({})}) if id == "ailleurs" else null, Fixtures.character())


func _admin(action: String, extra := {}) -> Array[Dictionary]:
	var command := {"type": Protocol.CMD_ADMIN, "entite": World.PLAYER_ID, "action": action}
	command.merge(extra, true)
	return _world.execute(command)


func test_mot_de_passe() -> void:
	assert_eq(_admin("brumes", {"quantite": 10})[0]["raison"], Protocol.REASON_NOT_ADMIN, "pas avant l'activation")
	assert_eq(_admin("activer", {"mdp": "0000"})[0]["raison"], Protocol.REASON_NOT_ADMIN, "mauvais mot de passe")
	assert_eq(_admin("activer", {"mdp": World.ADMIN_PASSWORD})[0]["type"], Protocol.EVT_CHARACTER)
	assert_true(_world.snapshot()["admin"], "le client le sait")


func test_dons() -> void:
	_admin("activer", {"mdp": World.ADMIN_PASSWORD})
	var character := _world.character
	var ecus := character.inventory.ecus
	_admin("brumes", {"quantite": 500})
	assert_eq(character.inventory.ecus, ecus + 500)
	_admin("objet", {"objet": "buche", "quantite": 30})
	assert_eq(character.inventory.quantity_of("buche"), 30)
	assert_eq(_admin("objet", {"objet": "inconnu", "quantite": 1})[0]["raison"], Protocol.REASON_INVALID_COMMAND)
	_admin("reputation_metier", {"metier": "bucheron", "quantite": 2500})
	assert_eq([character.job_reputation("bucheron"), character.job_points("bucheron")], [2500, 5], "points gagnés avec la réputation")
	_admin("points_metier", {"metier": "bucheron", "quantite": 3})
	assert_eq([character.job_reputation("bucheron"), character.job_points("bucheron")], [2500, 8])
	var points := character.mastery_points()
	_admin("reputation_classe", {"voie": character.voie_id, "quantite": 1000})
	_admin("points_classe", {"voie": character.voie_id, "quantite": 4})
	assert_eq(character.mastery_points(), points + 2 + 4)


func test_teleportation() -> void:
	_admin("activer", {"mdp": World.ADMIN_PASSWORD})
	assert_eq(_admin("teleporter", {"carte": "nulle_part"})[0]["raison"], Protocol.REASON_UNKNOWN_MAP)
	assert_true(_admin("teleporter", {"carte": "ailleurs"}).any(func(e: Dictionary) -> bool: return e["type"] == Protocol.EVT_MAP_CHANGED))
	assert_eq(_world.snapshot()["carte"], "ailleurs")
