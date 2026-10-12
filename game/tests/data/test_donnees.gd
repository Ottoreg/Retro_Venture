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


func test_carte_de_depart_chargeable() -> void:
	var map := DataLoader.load_map("res://data/cartes/brumerive_0_0.json")
	assert_true(map != null, "carte de départ")


func _find_json(dir_path: String) -> PackedStringArray:
	var files: PackedStringArray = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return files
	for sub in dir.get_directories():
		files.append_array(_find_json(dir_path.path_join(sub)))
	for file in dir.get_files():
		if file.ends_with(".json"):
			files.append(dir_path.path_join(file))
	return files
