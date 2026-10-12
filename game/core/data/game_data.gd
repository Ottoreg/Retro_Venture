class_name GameData
extends RefCounted
## Contenu du jeu chargé depuis `res://data/` : sorts, monstres et Voies (classes).
## Fabrique aussi les combattants correspondants.

const DATA_ROOT := "res://data"

## id → Spell
var spells: Dictionary = {}
## id → Dictionary (données brutes vérifiées)
var monsters: Dictionary = {}
## id → Dictionary (données brutes vérifiées)
var voies: Dictionary = {}


## Charge tout le contenu ; les fichiers invalides sont signalés et ignorés.
static func load_all(root := DATA_ROOT) -> GameData:
	return from_dicts(_read_folder(root.path_join("sorts")), _read_folder(root.path_join("monstres")), _read_folder(root.path_join("voies")))


## Construit le contenu à partir de données déjà lues (utile pour les tests).
static func from_dicts(spell_list: Array, monster_list: Array, voie_list: Array) -> GameData:
	var data := GameData.new()
	for raw: Variant in spell_list:
		var errors := Spell.validate(raw) if typeof(raw) == TYPE_DICTIONARY else PackedStringArray(["objet attendu"])
		if _report("sort", raw, errors):
			data.spells[raw["id"]] = Spell.from_dict(raw)
	for raw: Variant in monster_list:
		var errors := validate_monster(raw, data.spells) if typeof(raw) == TYPE_DICTIONARY else PackedStringArray(["objet attendu"])
		if _report("monstre", raw, errors):
			data.monsters[raw["id"]] = raw
	for raw: Variant in voie_list:
		var errors := validate_voie(raw, data.spells) if typeof(raw) == TYPE_DICTIONARY else PackedStringArray(["objet attendu"])
		if _report("voie", raw, errors):
			data.voies[raw["id"]] = raw
	return data


static func validate_monster(data: Dictionary, known_spells: Dictionary) -> PackedStringArray:
	var errors := _validate_common(data, known_spells)
	if not Spell._is_int_at_least(data.get("xp", 0), 0):
		errors.append("« xp » doit être un entier positif ou nul")
	if str(data.get("ia", "basique")) != "basique":
		errors.append("« ia » : seule la valeur « basique » existe pour l'instant")
	var resistances: Variant = data.get("resistances", {})
	if typeof(resistances) != TYPE_DICTIONARY:
		errors.append("« resistances » doit être un objet { element: % }")
	else:
		for element: Variant in resistances:
			if element not in Spell.ELEMENTS or typeof(resistances[element]) not in [TYPE_INT, TYPE_FLOAT]:
				errors.append("résistance invalide : %s" % str(element))
	return errors


static func validate_voie(data: Dictionary, known_spells: Dictionary) -> PackedStringArray:
	return _validate_common(data, known_spells)


## Monstre prêt à combattre, ou `null` si l'id est inconnu.
func create_monster(monster_id: String, fighter_id: String) -> Fighter:
	if not monsters.has(monster_id):
		return null
	var data: Dictionary = monsters[monster_id]
	var fighter := _create_fighter(data, fighter_id, str(data["nom"]), Fighter.TEAM_MONSTERS)
	fighter.ai = str(data.get("ia", "basique"))
	fighter.xp = int(data.get("xp", 0))
	for element: String in data.get("resistances", {}):
		fighter.resistances[element] = int(data["resistances"][element])
	return fighter


## Personnage joueur de la Voie donnée, ou `null` si elle est inconnue.
func create_player(voie_id: String, fighter_id: String, player_name: String) -> Fighter:
	if not voies.has(voie_id):
		return null
	return _create_fighter(voies[voie_id], fighter_id, player_name, Fighter.TEAM_PLAYERS)


func _create_fighter(data: Dictionary, fighter_id: String, fighter_name: String, team: int) -> Fighter:
	var fighter := Fighter.new()
	fighter.id = fighter_id
	fighter.display_name = fighter_name
	fighter.team = team
	fighter.kind = data["id"]
	var stats: Dictionary = data["caracteristiques"]
	fighter.max_hp = int(stats["pv"])
	fighter.hp = fighter.max_hp
	fighter.max_pa = int(stats["pa"])
	fighter.pa = fighter.max_pa
	fighter.max_pm = int(stats["pm"])
	fighter.pm = fighter.max_pm
	fighter.initiative = int(stats.get("initiative", 0))
	for spell_id: String in data["sorts"]:
		fighter.spells.append(spells[spell_id])
	return fighter


static func _validate_common(data: Dictionary, known_spells: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(data.get("id")) != TYPE_STRING or str(data.get("id")).is_empty():
		errors.append("« id » doit être un texte non vide")
	if typeof(data.get("nom")) != TYPE_STRING:
		errors.append("« nom » doit être un texte")
	var stats: Variant = data.get("caracteristiques")
	if typeof(stats) != TYPE_DICTIONARY:
		errors.append("« caracteristiques » doit être un objet { pv, pa, pm, initiative }")
	else:
		if not Spell._is_int_at_least(stats.get("pv"), 1):
			errors.append("« caracteristiques.pv » doit être un entier ≥ 1")
		for key in ["pa", "pm"]:
			if not Spell._is_int_at_least(stats.get(key), 0):
				errors.append("« caracteristiques.%s » doit être un entier ≥ 0" % key)
		if not Spell._is_int_at_least(stats.get("initiative", 0), 0):
			errors.append("« caracteristiques.initiative » doit être un entier ≥ 0")
	var spell_ids: Variant = data.get("sorts")
	if typeof(spell_ids) != TYPE_ARRAY or spell_ids.is_empty():
		errors.append("« sorts » doit être une liste non vide d'identifiants de sorts")
	else:
		for spell_id: Variant in spell_ids:
			if not known_spells.has(spell_id):
				errors.append("sort inconnu : %s" % str(spell_id))
	return errors


static func _read_folder(dir_path: String) -> Array:
	var result: Array = []
	for path in DataLoader.list_json(dir_path):
		var data: Variant = DataLoader.load_json(path)
		if data != null:
			result.append(data)
	return result


## Affiche les erreurs éventuelles ; vrai si l'élément est valide.
static func _report(kind: String, raw: Variant, errors: PackedStringArray) -> bool:
	if errors.is_empty():
		return true
	var label := str(raw.get("id", "?")) if typeof(raw) == TYPE_DICTIONARY else "?"
	push_error("%s « %s » invalide :\n- %s" % [kind, label, "\n- ".join(errors)])
	return false
