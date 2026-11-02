extends "res://tests/test_case.gd"
## Métiers : récolte (bûcheron), repousse des ressources, réputation et compétences de métier,
## sauvegarde (la forge : `test_forge.gd`).

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _world: World
var _map: GameMap


static func _items() -> Array:
	var items := Fixtures.items()
	items.append({"id": "buche", "nom": "Bûche", "type": "ressource", "rarete": "commun"})
	items.append({"id": "buche_rare", "nom": "Bûche de cœur", "type": "ressource", "rarete": "rare"})
	return items


static func _jobs() -> Array:
	return [
		{"id": "bucheron", "nom": "Bûcheron", "type": "recolte", "ressources": [
			{"marqueur": "F", "nom": "Frêne", "objet": "buche", "niveau": 1, "quantite": [2, 2], "xp": 10,
				"repousse": [60, 120], "apparence": "arbre", "couleur": "79a845", "rare": "buche_rare"},
			{"marqueur": "C", "nom": "Chêne", "objet": "buche", "niveau": 3, "quantite": [1, 1], "xp": 5,
				"repousse": [60, 60], "apparence": "arbre"},
		]},
		{"id": "forgeron", "nom": "Forgeron", "type": "artisanat"},
	]


func before_each() -> void:
	_map = Fixtures.map({Fixtures.center(): "F", GameMap.plan_cell(0, 4): "C"})
	var data := GameData.from_dicts(Fixtures.spells(), [], [], [], _items(), _jobs())
	_world = World.new(_map, data, Callable(), Fixtures.character())
	_world.rare_harvest_chance = 0.0  # récoltes normales, sauf dans le test des récoltes rares


func _command(type: String, extra := {}) -> Array[Dictionary]:
	var command := {"type": type, "entite": World.PLAYER_ID}
	command.merge(extra, true)
	return _world.execute(command)


func _go_next_to(cell: Vector2i) -> void:
	var path := _map.approach_path(_world.position_of(World.PLAYER_ID), cell)
	if not path.is_empty():
		_command(Protocol.CMD_MOVE, {"cible": path[-1]})
	assert_true(GameMap.is_adjacent(_world.position_of(World.PLAYER_ID), cell), "à côté de %s" % cell)


## Récolte complète : la commande, puis le temps de récolte (les événements de la fin).
func _harvest(cell: Vector2i) -> Array[Dictionary]:
	var started := _command(Protocol.CMD_HARVEST, {"case": cell})
	assert_eq(started[0]["type"], Protocol.EVT_HARVEST_STARTED)
	assert_eq(started[0]["duree"], Profession.harvest_time(int(_world.resource_node(cell).get("niveau", 1))))
	return _world.update(started[0]["duree"])


func _assert_refused(events: Array[Dictionary], reason: String, message := "") -> void:
	assert_eq(events.size(), 1, message)
	assert_eq(events[0]["type"], Protocol.EVT_REFUSED, message)
	assert_eq(events[0].get("raison"), reason, message)


func test_reputation_selon_la_difficulte() -> void:
	assert_eq(Profession.reputation_gain(10, 1, 0, 0), 10, "à sa mesure : la base")
	assert_eq(Profession.reputation_gain(10, 3, 0, 0), 30, "palier 3 pour un débutant : × 3")
	assert_eq(Profession.reputation_gain(10, 1, 100000, 0), 2, "trop facile : × 0,2")
	assert_eq(Profession.reputation_gain(10, 1, 0, 10), 11, "bonus de race")


func test_ressources_sur_la_carte() -> void:
	assert_eq(_map.resource_nodes.get(Fixtures.center()), "F")
	assert_false(_map.is_walkable(Fixtures.center()), "une ressource bloque le passage")
	assert_eq(_map.obstacles[Fixtures.center()], GameMap.RESOURCE_OBSTACLE)
	assert_eq(_world.resource_node(Fixtures.center())["nom"], "Frêne")
	assert_eq(_world.resource_node(Fixtures.center())["metier"], "bucheron")
	assert_true(_world.resource_node(GameMap.plan_cell(1, 1)).is_empty())


func test_recolter() -> void:
	var tree := Fixtures.center()
	_assert_refused(_command(Protocol.CMD_HARVEST, {"case": tree}), Protocol.REASON_TOO_FAR)
	_go_next_to(tree)
	var events := _harvest(tree)
	assert_eq(events[0]["type"], Protocol.EVT_HARVESTED)
	assert_eq(events[0]["objet"], "buche")
	assert_eq(events[0]["quantite"], 2)
	var job := Fixtures.of_type(events, Protocol.EVT_JOB)
	assert_eq(job.size(), 1)
	assert_eq(job[0]["metier"], "bucheron")
	assert_eq(job[0]["gain"], 10)
	assert_eq(job[0]["reputation"], 10)
	assert_eq(job[0]["paliers"], [], "pas encore Apprenti")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_INVENTORY).size(), 1)
	assert_eq(_world.character.inventory.quantity_of("buche"), 2)
	assert_eq(_world.character.job_reputation("bucheron"), 10)
	assert_true(_world.is_depleted(tree), "l'arbre est coupé")
	_assert_refused(_command(Protocol.CMD_HARVEST, {"case": tree}), Protocol.REASON_DEPLETED)
	_assert_refused(_command(Protocol.CMD_HARVEST, {"case": GameMap.plan_cell(1, 1)}), Protocol.REASON_UNKNOWN_ENTITY)
	_assert_refused(_command(Protocol.CMD_HARVEST, {"case": "arbre"}), Protocol.REASON_INVALID_COMMAND)


func test_recolte_rare() -> void:
	# 1 % par défaut ; ici forcée : un seul exemplaire de la ressource rare, à la place de la récolte.
	assert_eq(Profession.RARE_CHANCE, 0.01)
	_world.rare_harvest_chance = 1.0
	var tree := Fixtures.center()
	_go_next_to(tree)
	var events := _harvest(tree)
	assert_eq(events[0]["type"], Protocol.EVT_HARVESTED)
	assert_true(events[0]["rare"])
	assert_eq(events[0]["objet"], "buche_rare")
	assert_eq(events[0]["quantite"], 1, "un seul exemplaire")
	assert_eq(_world.character.inventory.quantity_of("buche_rare"), 1)
	assert_eq(_world.character.inventory.quantity_of("buche"), 0, "à la place de la récolte normale")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_JOB)[0]["gain"], 10, "même réputation de métier")
	# Le chêne n'a pas de ressource rare : récolte normale même à 100 %.

	var oak := GameMap.plan_cell(0, 4)
	_go_next_to(oak)
	var normal := _harvest(oak)
	assert_false(normal[0]["rare"])
	assert_eq(normal[0]["objet"], "buche")


func test_temps_de_recolte() -> void:
	assert_eq(Profession.harvest_time(1), 1.75)
	assert_true(Profession.harvest_time(22) > Profession.harvest_time(3), "plus long pour une ressource difficile")
	assert_eq(Profession.harvest_time(22, 5), 3.5, "Célérité au rang 5 : moitié moins")
	assert_eq(Profession.harvest_time(1, 5), Profession.HARVEST_MIN_TIME, "jamais moins d'une seconde")
	_world.character.jobs["bucheron"] = {"reputation": 0, "points": 0, "competences": {"celerite": 2}}
	var tree := Fixtures.center()
	_go_next_to(tree)
	assert_true(is_equal_approx(_command(Protocol.CMD_HARVEST, {"case": tree})[0]["duree"], 1.4), "Célérité au rang 2 : -20 %")
	assert_true(_world.update(1.0).is_empty(), "pas encore fini")
	assert_eq(_world.update(1.0)[0]["type"], Protocol.EVT_HARVESTED)
	# S'en aller interrompt la récolte.
	_world.update(121.0)
	_command(Protocol.CMD_HARVEST, {"case": tree})
	_command(Protocol.CMD_MOVE, {"cible": _world.position_of(World.PLAYER_ID) + Vector2i(0, 1)})
	assert_true(_world.update(5.0).is_empty(), "récolte abandonnée")
	assert_false(_world.is_depleted(tree))


func test_ressource_reservee_pendant_la_recolte() -> void:
	var tree := Fixtures.center()
	_world.add_player(Fixtures.character(), "p2", _map.id)
	_go_next_to(tree)
	_command(Protocol.CMD_HARVEST, {"case": tree})
	var path := _map.approach_path(_world.position_of("p2"), tree)
	if not path.is_empty():
		_world.execute({"type": Protocol.CMD_MOVE, "entite": "p2", "cible": path[-1]})
	var refused := _world.execute({"type": Protocol.CMD_HARVEST, "entite": "p2", "case": tree})
	assert_eq(refused[0].get("raison"), Protocol.REASON_HARVEST_TAKEN, "un autre joueur la récolte")
	assert_eq(_harvest(tree)[0]["type"], Protocol.EVT_HARVESTED, "le premier peut la reprendre et la finir")


func test_repousse_entre_une_et_deux_minutes() -> void:
	var tree := Fixtures.center()
	_go_next_to(tree)
	_harvest(tree)
	assert_true(_world.update(59.0).is_empty(), "pas avant une minute")
	assert_true(_world.is_depleted(tree))
	var events := _world.update(61.0)
	assert_eq(events.size(), 1, "repoussé avant deux minutes")
	assert_eq(events[0]["type"], Protocol.EVT_RESOURCE_RESPAWNED)
	assert_eq(events[0]["case"], tree)
	assert_false(_world.is_depleted(tree))
	assert_eq(_harvest(tree)[0]["type"], Protocol.EVT_HARVESTED, "on peut le recouper")


func test_recolte_ouverte_des_le_debut() -> void:
	var oak := GameMap.plan_cell(0, 4)
	assert_eq(_world.harvest_refusal(oak), "", "palier 3 sans réputation : permis")
	_go_next_to(oak)
	var events := _harvest(oak)
	assert_eq(events[0]["type"], Protocol.EVT_HARVESTED)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_JOB)[0]["gain"], 15, "5 × 3 : plus difficile, plus de réputation")


func test_competences_de_metier() -> void:
	_world.character.add_job_reputation("bucheron", 2 * Character.REPUTATION_PER_MASTERY_POINT)
	assert_eq(_world.character.job_points("bucheron"), 2)
	var raise := {"metier": "bucheron", "competence": "abondance"}
	assert_eq(_command(Protocol.CMD_RAISE_SPELL, raise)[0]["type"], Protocol.EVT_CHARACTER, "rang 1 : 1 point")
	_assert_refused(_command(Protocol.CMD_RAISE_SPELL, raise), Protocol.REASON_NOT_ENOUGH_POINTS, "rang 2 : 2 points")
	_assert_refused(_command(Protocol.CMD_RAISE_SPELL, {"metier": "bucheron", "competence": "precision"}),
		Protocol.REASON_INVALID_COMMAND, "compétence de la forge")
	_assert_refused(_command(Protocol.CMD_RAISE_SPELL, {"metier": "cuisinier", "competence": "abondance"}), Protocol.REASON_INVALID_COMMAND)
	assert_eq(_world.character.job_rank("bucheron", "abondance"), 1)
	# Abondance au rang 5 : 100 % de chances d'une ressource de plus.
	_world.character.jobs["bucheron"]["competences"]["abondance"] = 5
	_go_next_to(Fixtures.center())
	assert_eq(_harvest(Fixtures.center())[0]["quantite"], 3)


func test_inventaire_plein() -> void:
	var inventory := _world.character.inventory
	while not inventory.is_full():
		inventory.add(_world.data.items["bague"], 1, {})
	assert_eq(_world.harvest_refusal(Fixtures.center()), Protocol.REASON_INVENTORY_FULL)
	inventory.remove(inventory.entries.keys()[0])
	inventory.add(_world.data.items["buche"], 1)
	assert_true(inventory.is_full())
	assert_eq(_world.harvest_refusal(Fixtures.center()), "", "la pile de bûches existe déjà")


func test_sauvegarde_et_fiche_des_metiers() -> void:
	assert_eq(_world.character.add_job_reputation("forgeron", 1200), [1], "Apprenti")
	assert_eq(_world.character.raise_skill("forgeron", "precision", Profession.skills(Profession.TYPE_CRAFT)), "")
	var copy := Character.from_dict(_world.character.to_dict(), _world.data.items)
	assert_eq(copy.job_reputation("forgeron"), 1200)
	assert_eq(copy.job_points("forgeron"), 1)
	assert_eq(copy.job_rank("forgeron", "precision"), 1)
	var jobs: Array = _world.character.sheet(_world.data)["metiers"]
	assert_eq(jobs.size(), 2)
	assert_eq(jobs[1]["id"], "forgeron")
	assert_eq(jobs[1]["palier"], 1)
	assert_eq(jobs[0]["reputation"], 0, "bûcheron jamais pratiqué")
	# Sauvegarde d'avant le lot 4 : l'XP de métier devient de la réputation.
	var old := _world.character.to_dict()
	old["metiers"] = {"bucheron": 600}
	assert_eq(Character.from_dict(old).job_points("bucheron"), 1)


func test_metiers_invalides() -> void:
	var items := {}
	for item: Dictionary in _items():
		items[item["id"]] = item
	assert_eq(Profession.validate(_jobs()[0], items).size(), 0)
	assert_eq(Profession.validate(_jobs()[1], items).size(), 0)
	var bad_marker: Dictionary = _jobs()[0]
	bad_marker["ressources"][0]["marqueur"] = "A"
	assert_false(Profession.validate(bad_marker, items).is_empty(), "« A » est déjà un arbre de décor")
	var bad_item: Dictionary = _jobs()[0]
	bad_item["ressources"][0]["objet"] = "bague"
	assert_false(Profession.validate(bad_item, items).is_empty(), "la récolte doit donner une ressource")
	for rare: String in ["bague", "inconnu", "buche"]:
		var bad_rare: Dictionary = _jobs()[0]
		bad_rare["ressources"][0]["rare"] = rare
		assert_false(Profession.validate(bad_rare, items).is_empty(), "« rare » : %s refusé" % rare)
	assert_false(Profession.validate({"id": "x", "nom": "X", "type": "magie"}, items).is_empty())
	# Deux métiers qui utilisent le même marqueur : refusé.
	var data := GameData.from_dicts([], [], [], [], _items(), _jobs())
	assert_false(data._validate_job_links(_jobs()[0]).is_empty(), "marqueurs déjà utilisés")


func test_bonus_de_reputation_de_metier_des_humains() -> void:
	var races := [{"id": "humain", "nom": "Humain", "camp": "allie", "carte_depart": "test",
		"passif": {"nom": "Polyvalence", "effets": [{"type": "reputation_metier", "valeur": 10}]}}]
	var data := GameData.from_dicts(Fixtures.spells(), [], [], races, _items(), _jobs())
	var character := Character.create("Humain", "humain", "test")
	assert_eq(character.job_reputation_bonus(data), 10)
	_world = World.new(_map, data, Callable(), character)
	_go_next_to(Fixtures.center())
	var events := _harvest(Fixtures.center())
	assert_eq(Fixtures.of_type(events, Protocol.EVT_JOB)[0]["gain"], 11, "10 + 10 %")
	assert_eq(character.job_reputation("bucheron"), 11)
