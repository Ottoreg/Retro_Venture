class_name DataLoader
extends RefCounted
## Chargement des fichiers de contenu JSON de `res://data/`.


## Contenu du fichier JSON, ou `null` (avec une erreur affichée) s'il est absent ou invalide.
static func load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("Fichier introuvable : %s" % path)
		return null
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		push_error("JSON invalide dans %s, ligne %d : %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	return json.data


## Chemins des fichiers `.json` d'un dossier et de ses sous-dossiers, triés.
static func list_json(dir_path: String) -> PackedStringArray:
	var files: PackedStringArray = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return files
	for sub in dir.get_directories():
		files.append_array(list_json(dir_path.path_join(sub)))
	for file in dir.get_files():
		if file.ends_with(".json"):
			files.append(dir_path.path_join(file))
	files.sort()
	return files


## Ids de toutes les cartes du jeu (fichiers de `res://data/cartes/`), triés.
static func map_ids() -> Array[String]:
	var ids: Array[String] = []
	for path in list_json("res://data/cartes"):
		ids.append(path.get_file().get_basename())
	return ids


## Chemin du fichier d'une carte, d'après son id.
static func map_path(map_id: String) -> String:
	return "res://data/cartes/%s.json" % map_id


## Carte chargée depuis un fichier, ou `null` (avec les erreurs affichées) si elle est invalide.
static func load_map(path: String) -> GameMap:
	var data: Variant = load_json(path)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Carte %s : objet JSON attendu" % path)
		return null
	var errors := GameMap.validate(data)
	if not errors.is_empty():
		push_error("Carte %s invalide :\n- %s" % [path, "\n- ".join(errors)])
		return null
	return GameMap.from_dict(data)
