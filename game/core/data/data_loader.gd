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
