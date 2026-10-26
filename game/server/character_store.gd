class_name CharacterStore
extends RefCounted
## Personnages des comptes, côté serveur (GDD § 16.5) : un personnage par compte pour le prototype,
## avec son pseudo unique et son état ({ personnage, carte, position }, voir `World.player_save`).
## Cette version les garde en mémoire, et dans un dossier si on lui en donne un (serveur de
## développement) ; `SupabaseStore` les met dans la base. Les méthodes peuvent attendre (`await`).

## Dossier des fichiers ("" : en mémoire seulement).
var directory := ""
## Compte → { pseudo, etat }.
var _entries: Dictionary = {}


func _init(p_directory := "") -> void:
	directory = p_directory
	if directory.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		if file_name.ends_with(".json"):
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join(file_name)))
			if typeof(parsed) == TYPE_DICTIONARY and typeof(parsed.get("compte")) == TYPE_STRING:
				_entries[parsed["compte"]] = parsed


## État sauvegardé du personnage du compte, ou {} s'il n'en a pas.
func load_character(account: String) -> Dictionary:
	var entry: Dictionary = _entries.get(account, {})
	return entry.get("etat", {}).duplicate(true)


## Vrai si un autre compte porte déjà ce pseudo (sans tenir compte des majuscules).
func name_taken(pseudo: String, account: String) -> bool:
	for other: String in _entries:
		if other != account and str(_entries[other]["pseudo"]).to_lower() == pseudo.to_lower():
			return true
	return false


## Enregistre le personnage du compte ; faux en cas d'échec.
func save_character(account: String, pseudo: String, state: Dictionary) -> bool:
	var entry := {"compte": account, "pseudo": pseudo, "etat": state.duplicate(true)}
	_entries[account] = entry
	if directory.is_empty():
		return true
	var file := FileAccess.open(directory.path_join("%s.json" % account.md5_text()), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(entry))
	return true
