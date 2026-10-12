class_name SaveGame
extends RefCounted
## Sauvegarde de la partie dans `user://` (un fichier sur PC, le stockage du navigateur sur le web).

const PATH := "user://sauvegarde.json"


static func exists() -> bool:
	return FileAccess.file_exists(PATH)


## Contenu de la sauvegarde, ou `{}` si elle est absente ou illisible.
static func read() -> Dictionary:
	if not exists():
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return data if typeof(data) == TYPE_DICTIONARY else {}


static func write(data: Dictionary) -> bool:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Sauvegarde impossible : %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


## Résumé affiché dans le menu (« Elara, Elfe Rôdeur niveau 3 »), ou "".
static func summary() -> String:
	var save := read()
	var hero: Variant = save.get("personnage")
	if typeof(hero) != TYPE_DICTIONARY:
		return ""
	return "%s — niveau %d" % [str(hero.get("nom", "?")), int(hero.get("niveau", 1))]
