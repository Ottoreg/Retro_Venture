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
	for path in DataLoader.list_json(DATA_ROOT.path_join("monstres")):
		var data: Variant = DataLoader.load_json(path)
		var errors := GameData.validate_monster(data, spells) if typeof(data) == TYPE_DICTIONARY else PackedStringArray(["objet JSON attendu"])
		assert_eq(errors.size(), 0, "%s : %s" % [path, "; ".join(errors)])
		_assert_id_matches_file(data, path)
	for path in DataLoader.list_json(DATA_ROOT.path_join("voies")):
		var data: Variant = DataLoader.load_json(path)
		var errors := GameData.validate_voie(data, spells) if typeof(data) == TYPE_DICTIONARY else PackedStringArray(["objet JSON attendu"])
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


func _assert_id_matches_file(data: Variant, path: String) -> void:
	if typeof(data) == TYPE_DICTIONARY:
		assert_eq(str(data.get("id")), path.get_file().get_basename(), "%s : l'id doit correspondre au nom du fichier" % path)


func _find_json(dir_path: String) -> PackedStringArray:
	return DataLoader.list_json(dir_path)
