extends "res://tests/test_case.gd"
## Vérifie tous les fichiers de contenu de `res://data/`.

const DATA_ROOT := "res://data"


func test_fichiers_json_valides() -> void:
	var files := _find_json(DATA_ROOT)
	assert_true(files.size() > 0, "au moins un fichier de données")
	for path in files:
		var json := JSON.new()
		var error := json.parse(FileAccess.get_file_as_string(path))
		assert_eq(error, OK, "%s ligne %d : %s" % [path, json.get_error_line(), json.get_error_message()])


func test_cartes_valides() -> void:
	for path in _find_json(DATA_ROOT.path_join("cartes")):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(data) != TYPE_DICTIONARY:
			assert_true(false, "%s : objet JSON attendu" % path)
			continue
		var errors := GameMap.validate(data)
		assert_eq(errors.size(), 0, "%s : %s" % [path, "; ".join(errors)])
		assert_eq(str(data.get("id")), path.get_file().get_basename(), "%s : l'id doit correspondre au nom du fichier" % path)


func test_toutes_les_cases_praticables_sont_accessibles() -> void:
	for path in _find_json(DATA_ROOT.path_join("cartes")):
		var map := DataLoader.load_map(path)
		if map == null:
			continue  # Déjà signalé par test_cartes_valides.
		for cell: Vector2i in map.cells():
			if map.is_walkable(cell) and cell != map.spawn:
				assert_true(map.find_path(map.spawn, cell).size() > 0, "%s : case %s inaccessible depuis le départ" % [path, cell])


func test_carte_de_depart_chargeable() -> void:
	var map := DataLoader.load_map("res://data/cartes/brumerive_0_0.json")
	assert_true(map != null, "carte de départ")


func test_sorts_monstres_et_voies_valides() -> void:
	var spells := {}
	for path in DataLoader.list_json(DATA_ROOT.path_join("sorts")):
		var data: Variant = DataLoader.load_json(path)
		var errors := Spell.validate(data) if typeof(data) == TYPE_DICTIONARY else PackedStringArray(["objet JSON attendu"])
		assert_eq(errors.size(), 0, "%s : %s" % [path, "; ".join(errors)])
		_assert_id_matches_file(data, path)
		if errors.is_empty():
			spells[data["id"]] = Spell.from_dict(data)
	var items := {}
	for path in DataLoader.list_json(DATA_ROOT.path_join("objets")):
		var data: Variant = DataLoader.load_json(path)
		var errors := Item.validate(data) if typeof(data) == TYPE_DICTIONARY else PackedStringArray(["objet JSON attendu"])
		assert_eq(errors.size(), 0, "%s : %s" % [path, "; ".join(errors)])
		_assert_id_matches_file(data, path)
		if errors.is_empty():
			items[data["id"]] = data
	for path in DataLoader.list_json(DATA_ROOT.path_join("monstres")):
		var data: Variant = DataLoader.load_json(path)
		var errors := GameData.validate_monster(data, spells, items) if typeof(data) == TYPE_DICTIONARY else PackedStringArray(["objet JSON attendu"])
		assert_eq(errors.size(), 0, "%s : %s" % [path, "; ".join(errors)])
		_assert_id_matches_file(data, path)
	for path in DataLoader.list_json(DATA_ROOT.path_join("races")):
		var data: Variant = DataLoader.load_json(path)
		var errors := GameData.validate_race(data, spells) if typeof(data) == TYPE_DICTIONARY else PackedStringArray(["objet JSON attendu"])
		assert_eq(errors.size(), 0, "%s : %s" % [path, "; ".join(errors)])
		_assert_id_matches_file(data, path)
	for path in DataLoader.list_json(DATA_ROOT.path_join("voies")):
		var data: Variant = DataLoader.load_json(path)
		var errors := GameData.validate_voie(data, spells, items) if typeof(data) == TYPE_DICTIONARY else PackedStringArray(["objet JSON attendu"])
		assert_eq(errors.size(), 0, "%s : %s" % [path, "; ".join(errors)])
		_assert_id_matches_file(data, path)


func test_monstres_des_cartes_existants() -> void:
	var game_data := GameData.load_all()
	assert_true(game_data.voies.has(World.DEFAULT_VOIE), "Voie de départ « %s »" % World.DEFAULT_VOIE)
	for path in _find_json(DATA_ROOT.path_join("cartes")):
		var map := DataLoader.load_map(path)
		if map == null:
			continue
		for group in map.groups:
			for monster_id: String in group["monstres"]:
				assert_true(game_data.monsters.has(monster_id), "%s : monstre inconnu « %s »" % [path, monster_id])


func test_metiers_valides() -> void:
	var items := {}
	for path in DataLoader.list_json(DATA_ROOT.path_join("objets")):
		var data: Variant = DataLoader.load_json(path)
		if typeof(data) == TYPE_DICTIONARY:
			items[data.get("id")] = data
	var paths := DataLoader.list_json(DATA_ROOT.path_join("metiers"))
	assert_true(paths.size() >= 3, "bûcheron, mineur, forgeron")
	for path in paths:
		var data: Variant = DataLoader.load_json(path)
		var errors := Profession.validate(data, items) if typeof(data) == TYPE_DICTIONARY else PackedStringArray(["objet JSON attendu"])
		assert_eq(errors.size(), 0, "%s : %s" % [path, "; ".join(errors)])
		_assert_id_matches_file(data, path)
	var game_data := GameData.load_all()
	assert_eq(game_data.jobs.size(), paths.size(), "tous les métiers sont chargés")


func test_ressources_et_ateliers_des_cartes() -> void:
	var game_data := GameData.load_all()
	for path in _find_json(DATA_ROOT.path_join("cartes")):
		var map := DataLoader.load_map(path)
		if map == null:
			continue
		for cell: Vector2i in map.resource_nodes:
			var marker: String = map.resource_nodes[cell]
			assert_true(game_data.nodes.has(marker), "%s : aucune ressource de métier n'utilise « %s »" % [path, marker])
			var reachable := GameMap.is_adjacent(map.spawn, cell) or not map.approach_path(map.spawn, cell).is_empty()
			assert_true(reachable, "%s : ressource %s inaccessible" % [path, cell])
		for npc: Dictionary in map.npcs:
			var workshop: String = npc["atelier"]
			if not workshop.is_empty():
				assert_eq(str(game_data.jobs.get(workshop, {}).get("type")), Profession.TYPE_CRAFT, "%s : atelier « %s » inconnu" % [path, workshop])


func test_sorties_des_cartes_reciproques() -> void:
	for path in _find_json(DATA_ROOT.path_join("cartes")):
		var map := DataLoader.load_map(path)
		if map == null:
			continue
		for direction: String in map.exits:
			var neighbor := DataLoader.load_map(DataLoader.map_path(map.exits[direction]))
			assert_true(neighbor != null, "%s : la sortie « %s » mène à une carte inexistante (%s)" % [path, direction, map.exits[direction]])
			if neighbor == null:
				continue
			var back: String = GameMap.OPPOSITE_DIRECTION[direction]
			assert_eq(neighbor.exits.get(back, ""), map.id, "%s : la carte %s doit avoir une sortie « %s » qui ramène ici" % [path, neighbor.id, back])
			var edge_cells := 0
			for cell: Vector2i in map.cells():
				if map.is_walkable(cell) and direction in map.exit_directions(cell):
					edge_cells += 1
			assert_true(edge_cells > 0, "%s : aucune case praticable sur le bord « %s »" % [path, direction])


func test_portes_reciproques() -> void:
	var door_count := 0
	for path in _find_json(DATA_ROOT.path_join("cartes")):
		var map := DataLoader.load_map(path)
		if map == null:
			continue
		for cell: Vector2i in map.doors:
			door_count += 1
			var target := DataLoader.load_map(DataLoader.map_path(map.doors[cell]))
			assert_true(target != null, "%s : la porte %s mène à une carte inexistante (%s)" % [path, cell, map.doors[cell]])
			if target != null:
				assert_true(map.id in target.doors.values(), "%s : la carte %s doit avoir une porte qui ramène ici" % [path, target.id])
	assert_true(door_count >= 2, "au moins la porte de la maison et celle qui en sort")
	var house := DataLoader.load_map(DataLoader.map_path("maison_joueur"))
	assert_true(house != null and house.instance == "joueur", "maison du joueur, instanciée par joueur en multi")
	if house != null:
		assert_true("coffre" in house.obstacles.values() and "lit" in house.obstacles.values(), "un coffre et un lit")


func test_pierres_de_passage_et_zones_de_depart() -> void:
	var game_data := GameData.load_all()
	assert_true(game_data.passages.size() >= 3, "une pierre par zone de départ")
	var with_stone := {}
	for passage_id: String in game_data.passages:
		var map := DataLoader.load_map(DataLoader.map_path(game_data.passages[passage_id]["carte"]))
		assert_true(map != null, "pierre « %s » : carte introuvable" % passage_id)
		if map != null:
			assert_ne(map.travel_stone(), Vector2i(-1, -1), "pierre « %s » : pas de « * » sur la carte %s" % [passage_id, map.id])
			with_stone[map.id] = true
	for path in _find_json(DATA_ROOT.path_join("cartes")):
		var map := DataLoader.load_map(path)
		if map != null and map.travel_stone() != Vector2i(-1, -1):
			assert_true(with_stone.has(map.id), "%s : une pierre sans entrée dans data/passages" % path)
	for race_id: String in game_data.races:
		var start := str(game_data.races[race_id]["carte_depart"])
		assert_true(DataLoader.load_map(DataLoader.map_path(start)) != null, "race « %s » : carte de départ %s" % [race_id, start])
		assert_true(with_stone.has(start), "race « %s » : sa première carte a une Pierre de Passage" % race_id)
	assert_eq(str(game_data.races["gobelin"]["carte_depart"]), "crasse_roc_0_0")
	assert_eq(str(game_data.races["elfe"]["carte_depart"]), "sylvebrume_0_0")
	for path in _find_json(DATA_ROOT.path_join("cartes")):
		var map := DataLoader.load_map(path)
		if map != null and not map.palette.is_empty():
			assert_true(Art.manifest()["palettes"].has(map.palette), "%s : palette « %s » inconnue" % [path, map.palette])


func _assert_id_matches_file(data: Variant, path: String) -> void:
	if typeof(data) == TYPE_DICTIONARY:
		assert_eq(str(data.get("id")), path.get_file().get_basename(), "%s : l'id doit correspondre au nom du fichier" % path)


func _find_json(dir_path: String) -> PackedStringArray:
	return DataLoader.list_json(dir_path)
