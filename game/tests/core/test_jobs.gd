extends "res://tests/test_case.gd"
## Métiers : récolte (bûcheron), repousse des ressources, artisanat (forgeron), sauvegarde.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _world: World
var _map: GameMap


static func _items() -> Array:
	var items := Fixtures.items()
	items.append({"id": "buche", "nom": "Bûche", "type": "ressource", "rarete": "commun"})
	return items


static func _jobs() -> Array:
	return [
		{"id": "bucheron", "nom": "Bûcheron", "type": "recolte", "ressources": [
			{"marqueur": "F", "nom": "Frêne", "objet": "buche", "niveau": 1, "quantite": [2, 2], "xp": 10,
				"repousse": [60, 120], "apparence": "arbre", "couleur": "79a845"},
			{"marqueur": "C", "nom": "Chêne", "objet": "buche", "niveau": 3, "quantite": [1, 1], "xp": 5,
				"repousse": [60, 60], "apparence": "arbre"},
		]},
		{"id": "forgeron", "nom": "Forgeron", "type": "artisanat", "recettes": [
			{"objet": "heaume", "niveau": 2, "xp": 5, "ingredients": {"buche": 1}},
			{"objet": "bague", "niveau": 1, "xp": 10, "ingredients": {"buche": 3, "dent": 1}},
		]},
	]


func before_each() -> void:
	_map = Fixtures.map({Fixtures.center(): "F", GameMap.plan_cell(0, 4): "C", GameMap.plan_cell(8, 8): "a"}, [], {"pnj": [
		{"marqueur": "a", "id": "forge", "nom": "Forge", "atelier": "forgeron", "repliques": ["Salut"]},
	]})
	var data := GameData.from_dicts(Fixtures.spells(), [], [], [], _items(), _jobs())
	_world = World.new(_map, data, Callable(), Fixtures.character())


func _command(type: String, extra := {}) -> Array[Dictionary]:
	var command := {"type": type, "entite": World.PLAYER_ID}
	command.merge(extra, true)
	return _world.execute(command)


func _go_next_to(cell: Vector2i) -> void:
	var path := _map.approach_path(_world.position_of(World.PLAYER_ID), cell)
	if not path.is_empty():
		_command(Protocol.CMD_MOVE, {"cible": path[-1]})
	assert_true(GameMap.is_adjacent(_world.position_of(World.PLAYER_ID), cell), "à côté de %s" % cell)


func _assert_refused(events: Array[Dictionary], reason: String, message := "") -> void:
	assert_eq(events.size(), 1, message)
	assert_eq(events[0]["type"], Protocol.EVT_REFUSED, message)
	assert_eq(events[0].get("raison"), reason, message)


func test_courbe_d_experience() -> void:
	assert_eq(Profession.xp_for_level(1), 0)
	assert_eq(Profession.xp_for_level(2), 10)
	assert_eq(Profession.level_for_xp(9), 1)
	assert_eq(Profession.level_for_xp(10), 2)
	assert_eq(Profession.level_for_xp(1000000), Profession.MAX_LEVEL)


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
	var events := _command(Protocol.CMD_HARVEST, {"case": tree})
	assert_eq(events[0]["type"], Protocol.EVT_HARVESTED)
	assert_eq(events[0]["objet"], "buche")
	assert_eq(events[0]["quantite"], 2)
	var job := Fixtures.of_type(events, Protocol.EVT_JOB)
	assert_eq(job.size(), 1)
	assert_eq(job[0]["metier"], "bucheron")
	assert_eq(job[0]["gain"], 10)
	assert_eq(str(job[0]["niveaux"]), "[2]", "bûcheron niveau 2")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_INVENTORY).size(), 1)
	assert_eq(_world.character.inventory.quantity_of("buche"), 2)
	assert_eq(_world.character.job_level("bucheron"), 2)
	assert_true(_world.is_depleted(tree), "l'arbre est coupé")
	_assert_refused(_command(Protocol.CMD_HARVEST, {"case": tree}), Protocol.REASON_DEPLETED)
	_assert_refused(_command(Protocol.CMD_HARVEST, {"case": GameMap.plan_cell(1, 1)}), Protocol.REASON_UNKNOWN_ENTITY)
	_assert_refused(_command(Protocol.CMD_HARVEST, {"case": "arbre"}), Protocol.REASON_INVALID_COMMAND)


func test_repousse_entre_une_et_deux_minutes() -> void:
	var tree := Fixtures.center()
	_go_next_to(tree)
	_command(Protocol.CMD_HARVEST, {"case": tree})
	assert_true(_world.update(59.0).is_empty(), "pas avant une minute")
	assert_true(_world.is_depleted(tree))
	var events := _world.update(61.0)
	assert_eq(events.size(), 1, "repoussé avant deux minutes")
	assert_eq(events[0]["type"], Protocol.EVT_RESOURCE_RESPAWNED)
	assert_eq(events[0]["case"], tree)
	assert_false(_world.is_depleted(tree))
	assert_eq(_command(Protocol.CMD_HARVEST, {"case": tree})[0]["type"], Protocol.EVT_HARVESTED, "on peut le recouper")


func test_niveau_de_metier_requis() -> void:
	var oak := GameMap.plan_cell(0, 4)
	assert_eq(_world.harvest_refusal(oak), Protocol.REASON_JOB_LEVEL)
	_go_next_to(oak)
	_assert_refused(_command(Protocol.CMD_HARVEST, {"case": oak}), Protocol.REASON_JOB_LEVEL)
	_world.character.jobs["bucheron"] = Profession.xp_for_level(3)
	assert_eq(_world.harvest_refusal(oak), "")
	assert_eq(_command(Protocol.CMD_HARVEST, {"case": oak})[0]["type"], Protocol.EVT_HARVESTED)


func test_inventaire_plein() -> void:
	var inventory := _world.character.inventory
	while not inventory.is_full():
		inventory.add(_world.data.items["bague"], 1, {})
	assert_eq(_world.harvest_refusal(Fixtures.center()), Protocol.REASON_INVENTORY_FULL)
	inventory.remove(inventory.entries.keys()[0])
	inventory.add(_world.data.items["buche"], 1)
	assert_true(inventory.is_full())
	assert_eq(_world.harvest_refusal(Fixtures.center()), "", "la pile de bûches existe déjà")


func test_atelier_du_forgeron() -> void:
	var events := _command(Protocol.CMD_TALK, {"pnj": "forge"})
	assert_eq(Fixtures.of_type(events, Protocol.EVT_DIALOGUE).size(), 0, "pas de simple dialogue")
	var workshops := Fixtures.of_type(events, Protocol.EVT_WORKSHOP)
	assert_eq(workshops.size(), 1)
	assert_eq(workshops[0]["metier"], "forgeron")
	assert_eq(workshops[0]["nom_metier"], "Forgeron")
	var recipes: Array = workshops[0]["recettes"]
	assert_eq(recipes.size(), 2)
	assert_eq(recipes[0]["objet"], "bague", "triées par niveau")
	assert_eq(recipes[0]["ingredients"], [{"objet": "buche", "nom": "Bûche", "quantite": 3}, {"objet": "dent", "nom": "Dent", "quantite": 1}])


func test_fabriquer() -> void:
	var inventory := _world.character.inventory
	_assert_refused(_command(Protocol.CMD_CRAFT, {"pnj": "forge", "recette": "bague"}), Protocol.REASON_TOO_FAR)
	_command(Protocol.CMD_TALK, {"pnj": "forge"})
	_assert_refused(_command(Protocol.CMD_CRAFT, {"pnj": "forge", "recette": "bague"}), Protocol.REASON_MISSING_INGREDIENTS)
	_assert_refused(_command(Protocol.CMD_CRAFT, {"pnj": "forge", "recette": "epee"}), Protocol.REASON_UNKNOWN_ITEM, "pas de recette")
	inventory.add(_world.data.items["buche"], 7)
	inventory.add(_world.data.items["dent"], 2)
	_assert_refused(_command(Protocol.CMD_CRAFT, {"pnj": "forge", "recette": "heaume"}), Protocol.REASON_JOB_LEVEL)

	var events := _command(Protocol.CMD_CRAFT, {"pnj": "forge", "recette": "bague", "quantite": 2})
	assert_eq(events[0]["type"], Protocol.EVT_CRAFTED)
	assert_eq(events[0]["quantite"], 2)
	assert_eq(inventory.quantity_of("bague"), 2, "deux bagues, chacune avec ses jets")
	for entry: Dictionary in inventory.entries.values():
		if entry["objet"] == "bague":
			assert_eq(entry["jets"], {"force": 5})
	assert_eq(inventory.quantity_of("buche"), 1, "ingrédients consommés")
	assert_eq(inventory.quantity_of("dent"), 0)
	var job := Fixtures.of_type(events, Protocol.EVT_JOB)[0]
	assert_eq(job["gain"], 20)
	assert_eq(str(job["niveaux"]), "[2]")
	assert_eq(_command(Protocol.CMD_CRAFT, {"pnj": "forge", "recette": "heaume"})[0]["type"], Protocol.EVT_CRAFTED, "niveau 2 atteint")
	assert_eq(inventory.quantity_of("buche"), 0)


func test_sauvegarde_et_fiche_des_metiers() -> void:
	_world.character.add_job_xp("forgeron", 42)
	var copy := Character.from_dict(_world.character.to_dict(), _world.data.items)
	assert_eq(copy.job_xp("forgeron"), 42)
	assert_eq(copy.job_level("forgeron"), Profession.level_for_xp(42))
	var jobs: Array = _world.character.sheet(_world.data)["metiers"]
	assert_eq(jobs.size(), 2)
	assert_eq(jobs[1]["id"], "forgeron")
	assert_eq(jobs[1]["niveau"], 3)
	assert_eq(jobs[0]["niveau"], 1, "bûcheron jamais pratiqué")


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
	var bad_recipe: Dictionary = _jobs()[1]
	bad_recipe["recettes"][0]["ingredients"] = {"inconnu": 2}
	assert_false(Profession.validate(bad_recipe, items).is_empty(), "ingrédient inconnu")
	assert_false(Profession.validate({"id": "x", "nom": "X", "type": "magie"}, items).is_empty())
	# Deux métiers qui utilisent le même marqueur, ou deux recettes du même objet : refusé.
	var data := GameData.from_dicts([], [], [], [], _items(), _jobs())
	assert_false(data._validate_job_links(_jobs()[0]).is_empty(), "marqueurs déjà utilisés")
	assert_false(data._validate_job_links(_jobs()[1]).is_empty(), "recettes déjà existantes")


func test_bonus_d_xp_de_metier_des_humains() -> void:
	var races := [{"id": "humain", "nom": "Humain", "camp": "allie", "carte_depart": "test", "bonus": {},
		"passif": {"nom": "Polyvalence", "effets": [{"type": "xp_metier", "valeur": 10}]}}]
	var data := GameData.from_dicts(Fixtures.spells(), [], [], races, _items(), _jobs())
	var character := Character.create("Humain", "humain", "test")
	assert_eq(character.job_xp_bonus(data), 10)
	_world = World.new(_map, data, Callable(), character)
	_go_next_to(Fixtures.center())
	var events := _command(Protocol.CMD_HARVEST, {"case": Fixtures.center()})
	assert_eq(Fixtures.of_type(events, Protocol.EVT_JOB)[0]["gain"], 11, "10 XP + 10 %")
	assert_eq(character.job_xp("bucheron"), 11)
