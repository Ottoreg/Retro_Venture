class_name GameData
extends RefCounted
## Contenu du jeu chargé depuis `res://data/` : sorts, monstres, Voies (classes) et races.
## Fabrique aussi les combattants correspondants.

const DATA_ROOT := "res://data"

## id → Spell
var spells: Dictionary = {}
## id → Dictionary (données brutes vérifiées)
var monsters: Dictionary = {}
## id → Dictionary (données brutes vérifiées)
var voies: Dictionary = {}
## id → Dictionary (données brutes vérifiées)
var races: Dictionary = {}
## id → Dictionary (données brutes vérifiées)
var items: Dictionary = {}
## id → Dictionary (données brutes vérifiées) : métiers de récolte et d'artisanat.
var jobs: Dictionary = {}
## Caractère du plan → ressource récoltable { marqueur, nom, objet, niveau, … , metier: id du métier }.
var nodes: Dictionary = {}
## id de l'objet fabriqué → recette { objet, niveau, ingredients, xp, metier: id du métier }.
var recipes: Dictionary = {}
## Pierres de Passage : id → { id, nom, carte } (on voyage de l'une à l'autre).
var passages: Dictionary = {}

const STARTING_ECUS := 20

const CAMPS := ["allie", "ennemi", "neutre"]
## Effets de passif de race gérés : portée des sorts, % d'XP de métier en plus.
const PASSIVE_EFFECTS := ["portee", "xp_metier"]


## Charge tout le contenu ; les fichiers invalides sont signalés et ignorés.
static func load_all(root := DATA_ROOT) -> GameData:
	return from_dicts(_read_folder(root.path_join("sorts")), _read_folder(root.path_join("monstres")),
		_read_folder(root.path_join("voies")), _read_folder(root.path_join("races")), _read_folder(root.path_join("objets")),
		_read_folder(root.path_join("metiers")), _read_folder(root.path_join("passages")))


## Construit le contenu à partir de données déjà lues (utile pour les tests).
static func from_dicts(spell_list: Array, monster_list: Array, voie_list: Array, race_list: Array = [], item_list: Array = [],
		job_list: Array = [], passage_list: Array = []) -> GameData:
	var data := GameData.new()
	for raw: Variant in item_list:
		var errors := Item.validate(raw) if typeof(raw) == TYPE_DICTIONARY else PackedStringArray(["objet attendu"])
		if _report("objet", raw, errors):
			data.items[raw["id"]] = raw
	for raw: Variant in spell_list:
		var errors := Spell.validate(raw) if typeof(raw) == TYPE_DICTIONARY else PackedStringArray(["objet attendu"])
		if _report("sort", raw, errors):
			data.spells[raw["id"]] = Spell.from_dict(raw)
	for raw: Variant in monster_list:
		var errors := validate_monster(raw, data.spells, data.items) if typeof(raw) == TYPE_DICTIONARY else PackedStringArray(["objet attendu"])
		if _report("monstre", raw, errors):
			data.monsters[raw["id"]] = raw
	for raw: Variant in voie_list:
		var errors := validate_voie(raw, data.spells, data.items) if typeof(raw) == TYPE_DICTIONARY else PackedStringArray(["objet attendu"])
		if _report("voie", raw, errors):
			data.voies[raw["id"]] = raw
	for raw: Variant in race_list:
		var errors := validate_race(raw, data.spells) if typeof(raw) == TYPE_DICTIONARY else PackedStringArray(["objet attendu"])
		if _report("race", raw, errors):
			data.races[raw["id"]] = raw
	for raw: Variant in job_list:
		var errors := Profession.validate(raw, data.items) if typeof(raw) == TYPE_DICTIONARY else PackedStringArray(["objet attendu"])
		if errors.is_empty():
			errors = data._validate_job_links(raw)
		if _report("métier", raw, errors):
			data._add_job(raw)
	for raw: Variant in passage_list:
		var errors := validate_passage(raw) if typeof(raw) == TYPE_DICTIONARY else PackedStringArray(["objet attendu"])
		if _report("pierre de passage", raw, errors):
			data.passages[raw["id"]] = raw
	return data


static func validate_passage(data: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	for key in ["id", "nom", "carte"]:
		if typeof(data.get(key)) != TYPE_STRING or str(data.get(key)).is_empty():
			errors.append("« %s » doit être un texte non vide" % key)
	return errors


## Erreurs qui dépendent des autres métiers : marqueurs de ressources et objets fabriqués uniques.
func _validate_job_links(job: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	for node: Dictionary in job.get("ressources", []):
		if nodes.has(node["marqueur"]):
			errors.append("marqueur « %s » déjà utilisé par %s" % [node["marqueur"], nodes[node["marqueur"]]["nom"]])
	for recipe: Dictionary in job.get("recettes", []):
		if recipes.has(recipe["objet"]):
			errors.append("« %s » a déjà une recette" % recipe["objet"])
	return errors


func _add_job(job: Dictionary) -> void:
	jobs[job["id"]] = job
	for node: Dictionary in job.get("ressources", []):
		var entry := node.duplicate(true)
		entry["metier"] = job["id"]
		nodes[node["marqueur"]] = entry
	for recipe: Dictionary in job.get("recettes", []):
		var entry := recipe.duplicate(true)
		entry["metier"] = job["id"]
		recipes[recipe["objet"]] = entry


static func validate_race(data: Dictionary, known_spells: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(data.get("id")) != TYPE_STRING or str(data.get("id")).is_empty():
		errors.append("« id » doit être un texte non vide")
	if typeof(data.get("nom")) != TYPE_STRING:
		errors.append("« nom » doit être un texte")
	if data.get("camp") not in CAMPS:
		errors.append("« camp » doit valoir %s" % str(CAMPS))
	var bonus: Variant = data.get("bonus", {})
	if typeof(bonus) != TYPE_DICTIONARY:
		errors.append("« bonus » doit être un objet { caractéristique: valeur }")
	else:
		for stat_name: Variant in bonus:
			if stat_name not in Character.STATS or not Spell._is_int_at_least(bonus[stat_name], 0):
				errors.append("bonus invalide : %s (caractéristiques : %s)" % [str(stat_name), str(Character.STATS)])
	var passive: Variant = data.get("passif", {})
	if typeof(passive) != TYPE_DICTIONARY or typeof(passive.get("nom")) != TYPE_STRING:
		errors.append("« passif » doit être un objet avec un « nom »")
	else:
		var effect: Variant = passive.get("effet", {})
		if typeof(effect) != TYPE_DICTIONARY or (not effect.is_empty() and (str(effect.get("type")) not in PASSIVE_EFFECTS or not Spell._is_int_at_least(effect.get("valeur"), 1))):
			errors.append("« passif.effet » : { type, valeur } attendu, types gérés : %s" % str(PASSIVE_EFFECTS))
	if data.has("sort") and not known_spells.has(data["sort"]):
		errors.append("sort racial inconnu : %s" % str(data["sort"]))
	if typeof(data.get("carte_depart")) != TYPE_STRING:
		errors.append("« carte_depart » doit être un id de carte")
	return errors


static func validate_monster(data: Dictionary, known_spells: Dictionary, known_items: Dictionary = {}) -> PackedStringArray:
	var errors := _validate_common(data, known_spells)
	if typeof(data.get("elite", false)) != TYPE_BOOL:
		errors.append("« elite » doit être vrai ou faux")
	if data.get("elite", false) == true and (typeof(data.get("famille")) != TYPE_STRING or str(data.get("famille")).is_empty()):
		errors.append("un monstre élite doit indiquer sa « famille » (l'id du monstre normal)")
	var loot: Variant = data.get("butin", [])
	if typeof(loot) != TYPE_ARRAY:
		errors.append("« butin » doit être une liste")
	else:
		for drop: Variant in loot:
			if typeof(drop) != TYPE_DICTIONARY or not known_items.has(drop.get("objet")):
				errors.append("butin : objet inconnu %s" % str(drop))
				continue
			var rate: Variant = drop.get("taux")
			if typeof(rate) not in [TYPE_INT, TYPE_FLOAT] or float(rate) <= 0.0 or float(rate) > 1.0:
				errors.append("butin « %s » : « taux » doit être entre 0 et 1" % drop["objet"])
			var amount: Variant = drop.get("quantite", [1, 1])
			if typeof(amount) != TYPE_ARRAY or amount.size() != 2 or not Spell._is_int_at_least(amount[0], 1) \
					or not Spell._is_int_at_least(amount[1], 1) or int(amount[0]) > int(amount[1]):
				errors.append("butin « %s » : « quantite » doit être [min, max]" % drop["objet"])
	var coins: Variant = data.get("ecus", [0, 0])
	if typeof(coins) != TYPE_ARRAY or coins.size() != 2 or not Spell._is_int_at_least(coins[0], 0) \
			or not Spell._is_int_at_least(coins[1], 0) or int(coins[0]) > int(coins[1]):
		errors.append("« ecus » doit être [min, max]")
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


static func validate_voie(data: Dictionary, known_spells: Dictionary, known_items: Dictionary = {}) -> PackedStringArray:
	var errors := _validate_common(data, known_spells)
	var kit: Variant = data.get("equipement_depart", [])
	if typeof(kit) != TYPE_ARRAY:
		errors.append("« equipement_depart » doit être une liste d'objets")
	else:
		for item_id: Variant in kit:
			if not known_items.has(item_id):
				errors.append("équipement de départ inconnu : %s" % str(item_id))
	return errors


## Équipement de départ de la Voie (équipé) et quelques écus, pour un personnage tout neuf.
func give_starting_kit(character: Character) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(character.display_name)
	character.inventory.ecus += STARTING_ECUS
	for item_id: String in voies.get(character.voie_id, {}).get("equipement_depart", []):
		var template: Dictionary = items[item_id]
		var uid := character.inventory.add(template, 1, Item.roll_bonuses(template, rng))
		if not uid.is_empty() and Item.is_equipment(template):
			var slots: Array = Item.SLOTS_BY_TYPE[template["type"]]
			for slot: String in slots:
				if not character.inventory.equipped.has(slot):
					character.inventory.equip(uid, slot)
					break


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


## Combattant d'un personnage joueur : Voie, niveau, caractéristiques, sort et passif de race.
func create_character_fighter(character: Character, fighter_id: String) -> Fighter:
	if not voies.has(character.voie_id):
		return null
	var fighter := _create_fighter(voies[character.voie_id], fighter_id, character.display_name, Fighter.TEAM_PLAYERS)
	fighter.race = character.race_id
	for stat_name in Character.STATS:
		fighter.stats[stat_name] = character.stat(stat_name, self)
	fighter.max_hp = character.max_hp(self)
	fighter.hp = character.hp(self)  # Les PV perdus se gardent d'un combat à l'autre.
	# Initiative : base de la Voie + Force, Intelligence, Chance et Agilité + équipement.
	fighter.initiative = character.initiative(self)
	var race: Dictionary = races.get(character.race_id, {})
	if race.has("sort") and spells.has(race["sort"]):
		fighter.spells.append(spells[race["sort"]])
	var passive_effect: Dictionary = race.get("passif", {}).get("effet", {})
	if str(passive_effect.get("type")) == "portee":
		fighter.range_bonus = int(passive_effect["valeur"])
	# Équipement : bonus hors caractéristiques et attaque de l'arme.
	fighter.max_pa += character.extra("pa")
	fighter.pa = fighter.max_pa
	fighter.max_pm += character.extra("pm")
	fighter.pm = fighter.max_pm
	fighter.range_bonus += character.extra("portee")
	fighter.prospection = character.prospection(self)
	var weapon := character.inventory.equipped_entry("arme")
	if not weapon.is_empty() and items.has(weapon["objet"]):
		fighter.spells.insert(0, Spell.from_dict(Item.weapon_spell_data(items[weapon["objet"]])))
	return fighter


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
