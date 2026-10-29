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
## Pierres de Passage : id → { id, nom, carte, prix, toujours_connue } (on voyage de l'une à l'autre ;
## `prix` et `toujours_connue` sont optionnels, voir `passage_price` et `passage_always_known`).
var passages: Dictionary = {}
## Panoplies : id → { id, nom, objets: Array (ids), bonus: { nombre de pièces (texte) → { stat: valeur } } }.
var sets: Dictionary = {}
## id d'objet → id de sa panoplie.
var item_sets: Dictionary = {}
## Quêtes : id → données (voir `Quest`).
var quests: Dictionary = {}

const STARTING_ECUS := 20

const CAMPS := ["allie", "ennemi", "neutre"]
## Effets de passif de race gérés : portée des sorts, % d'XP de métier en plus, prospection en
## plus, % de brumes de fin de combat en plus.
const PASSIVE_EFFECTS := ["portee", "xp_metier", "prospection", "ecus"]
## Caractéristiques d'un monstre (facultatives dans « caracteristiques », 0 par défaut) : comme
## celles des joueurs, +1 % de dégâts de leur élément par point.
const MONSTER_STATS := ["force", "intelligence", "perception", "agilite"]
## Ce que « par_niveau » ajoute pour chaque niveau au-dessus du niveau de base (« resistances » à
## part ; « pa » et « pm » seulement par exception, pour une famille dont la mécanique en dépend).
const PER_LEVEL_KEYS := ["pv", "initiative", "xp", "force", "intelligence", "perception", "agilite", "pa", "pm"]
## Effets qu'un monstre ne peut pas s'appliquer en changeant de phase (rien à viser au sol, nulle
## part où sauter, personne à pousser ni à attirer).
const PHASE_FORBIDDEN_EFFECTS := [Spell.EFFECT_GLYPH, Spell.EFFECT_TRAP, Spell.EFFECT_TELEPORT, Spell.EFFECT_PUSH, Spell.EFFECT_PULL,
	Spell.EFFECT_CHARGE, Spell.EFFECT_CREATE_SPELL, Spell.EFFECT_ELEMENT_STATE, Spell.EFFECT_COMPOSE_STATES,
	Spell.EFFECT_REMOVE_STATES]
## Pas de soin au changement de phase, ni en effet ni en sort appris : un monstre qui se soigne en
## passant sous un seuil peut enfermer le joueur dans un combat sans fin.
const PHASE_NO_HEAL := "pas de soin au changement de phase (risque de combat sans fin)"


## Charge tout le contenu ; les fichiers invalides sont signalés et ignorés.
static func load_all(root := DATA_ROOT) -> GameData:
	return from_dicts(_read_folder(root.path_join("sorts")), _read_folder(root.path_join("monstres")),
		_read_folder(root.path_join("voies")), _read_folder(root.path_join("races")), _read_folder(root.path_join("objets")),
		_read_folder(root.path_join("metiers")), _read_folder(root.path_join("passages")), _read_folder(root.path_join("panoplies")),
		_read_folder(root.path_join("quetes")))


## Construit le contenu à partir de données déjà lues (utile pour les tests).
static func from_dicts(spell_list: Array, monster_list: Array, voie_list: Array, race_list: Array = [], item_list: Array = [],
		job_list: Array = [], passage_list: Array = [], set_list: Array = [], quest_list: Array = []) -> GameData:
	var data := GameData.new()
	for raw: Variant in item_list:
		var errors := Item.validate(raw) if typeof(raw) == TYPE_DICTIONARY else PackedStringArray(["objet attendu"])
		if _report("objet", raw, errors):
			data.items[raw["id"]] = raw
	for raw: Variant in spell_list:
		var errors := Spell.validate(raw) if typeof(raw) == TYPE_DICTIONARY else PackedStringArray(["objet attendu"])
		if _report("sort", raw, errors):
			data.spells[raw["id"]] = Spell.from_dict(raw)
	# « creer_sort » : chaque combinaison doit nommer un sort connu (qui ne crée rien lui-même).
	for spell_id: String in data.spells.keys():
		var link_errors := data._link_created_spells(data.spells[spell_id])
		if not _report("sort", {"id": spell_id}, link_errors):
			data.spells.erase(spell_id)
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
	for raw: Variant in set_list:
		var errors := data.validate_set(raw) if typeof(raw) == TYPE_DICTIONARY else PackedStringArray(["objet attendu"])
		if _report("panoplie", raw, errors):
			data.sets[raw["id"]] = raw
			for item_id: String in raw["objets"]:
				data.item_sets[item_id] = raw["id"]
	for raw: Variant in quest_list:
		var errors := Quest.validate(raw) if typeof(raw) == TYPE_DICTIONARY else PackedStringArray(["objet attendu"])
		if _report("quête", raw, errors):
			data.quests[raw["id"]] = raw
	# Liens entre quêtes une fois toutes lues : une quête aux liens cassés est retirée.
	var broken: Array[String] = []
	for quest_id: String in data.quests:
		if not _report("quête", data.quests[quest_id], data.validate_quest_links(data.quests[quest_id])):
			broken.append(quest_id)
	for quest_id in broken:
		data.quests.erase(quest_id)
	return data


## Liens d'une quête vers le reste du contenu : monstres, objets, métiers, races, Voies, quêtes.
func validate_quest_links(quest: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	var conditions: Dictionary = quest.get("conditions", {})
	for quest_id: String in conditions.get("quetes_terminees", []) + conditions.get("une_quete_terminee", []):
		if not quests.has(quest_id) or quest_id == quest["id"]:
			errors.append("quête requise inconnue : %s" % quest_id)
	if conditions.has("race") and not races.has(conditions["race"]):
		errors.append("race inconnue : %s" % conditions["race"])
	if conditions.has("voie") and not voies.has(conditions["voie"]):
		errors.append("Voie inconnue : %s" % conditions["voie"])
	var entries: Array = quest.get("donne", []) + quest.get("recompenses", {}).get("objets", [])
	for entry: Dictionary in entries:
		if not items.has(entry["objet"]):
			errors.append("objet inconnu : %s" % entry["objet"])
	for step: Dictionary in quest["etapes"]:
		for objective: Dictionary in step["objectifs"]:
			var type: String = objective["type"]
			if objective.has("monstre") and not monsters.has(objective["monstre"]):
				errors.append("monstre inconnu : %s" % objective["monstre"])
			if objective.has("objet") and not items.has(objective["objet"]):
				errors.append("objet inconnu : %s" % objective["objet"])
			if objective.has("metier") and not jobs.has(objective["metier"]):
				errors.append("métier inconnu : %s" % objective["metier"])
			if type == Quest.OBJ_DEFEAT_GROUP and not monsters.get(objective["monstre"], {}).get("boss", false):
				errors.append("« vaincre_groupe » : %s n'est pas un boss" % objective["monstre"])
			for monster_id: Variant in objective.get("butin", {}).get("monstres", []):
				if not monsters.has(monster_id):
					errors.append("butin de quête : monstre inconnu %s" % str(monster_id))
	return errors


## Panoplie : au moins deux équipements connus, chacun dans une seule panoplie ; bonus par nombre de
## pièces portées (de 2 au nombre de pièces), en caractéristiques ou bonus d'équipement.
func validate_set(data: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	for key in ["id", "nom"]:
		if typeof(data.get(key)) != TYPE_STRING or str(data.get(key)).is_empty():
			errors.append("« %s » doit être un texte non vide" % key)
	var pieces: Variant = data.get("objets")
	if typeof(pieces) != TYPE_ARRAY or pieces.size() < 2:
		errors.append("« objets » doit lister au moins deux équipements")
		return errors
	var seen := {}
	for item_id: Variant in pieces:
		if typeof(item_id) != TYPE_STRING or not items.has(item_id) or not Item.is_equipment(items[item_id]):
			errors.append("objet de panoplie inconnu ou qui n'est pas un équipement : %s" % str(item_id))
		elif seen.has(item_id) or item_sets.has(item_id):
			errors.append("« %s » est déjà dans une panoplie" % item_id)
		seen[item_id] = true
	var tiers: Variant = data.get("bonus")
	if typeof(tiers) != TYPE_DICTIONARY or tiers.is_empty():
		errors.append("« bonus » doit être un objet { nombre de pièces: { stat: valeur } }")
		return errors
	for count: Variant in tiers:
		if not str(count).is_valid_int() or int(str(count)) < 2 or int(str(count)) > pieces.size():
			errors.append("bonus : « %s » doit être un nombre de pièces entre 2 et %d" % [str(count), pieces.size()])
		elif typeof(tiers[count]) != TYPE_DICTIONARY:
			errors.append("bonus %s : objet { stat: valeur } attendu" % str(count))
		else:
			for stat: Variant in tiers[count]:
				if stat not in Item.bonus_stats() or typeof(tiers[count][stat]) not in [TYPE_INT, TYPE_FLOAT]:
					errors.append("bonus %s : « %s » n'est pas un bonus possible" % [str(count), str(stat)])
	return errors


## Bonus de panoplie actif pour ce nombre de pièces portées : le palier le plus haut atteint ({} sous 2).
func set_tier(set_id: String, worn: int) -> Dictionary:
	var best := {}
	var best_count := 0
	var tiers: Dictionary = sets.get(set_id, {}).get("bonus", {})
	for count: Variant in tiers:
		var needed := int(str(count))
		if needed <= worn and needed > best_count:
			best_count = needed
			best = tiers[count]
	return best


## Pièces portées par panoplie : id de panoplie → nombre.
func worn_sets(inventory: Inventory) -> Dictionary:
	var counts := {}
	var counted := {}
	for uid: String in inventory.equipped.values():
		var item_id: String = inventory.entries[uid]["objet"]
		if item_sets.has(item_id) and not counted.has(item_id):
			counted[item_id] = true
			counts[item_sets[item_id]] = int(counts.get(item_sets[item_id], 0)) + 1
	return counts


## Total des bonus de panoplie actifs d'un inventaire : stat → valeur.
func set_bonuses(inventory: Inventory) -> Dictionary:
	var totals := {}
	var counts := worn_sets(inventory)
	for set_id: String in counts:
		var tier := set_tier(set_id, counts[set_id])
		for stat: String in tier:
			totals[stat] = int(totals.get(stat, 0)) + int(tier[stat])
	return totals


## Pierre de Passage : `id`, `nom` et `carte` obligatoires ; `prix` (brumes pour y voyager, entier ≥ 0)
## et `toujours_connue` (vrai ou faux) optionnels.
static func validate_passage(data: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	for key in ["id", "nom", "carte"]:
		if typeof(data.get(key)) != TYPE_STRING or str(data.get(key)).is_empty():
			errors.append("« %s » doit être un texte non vide" % key)
	if not Spell._is_int_at_least(data.get("prix", 0), 0):
		errors.append("« prix » doit être un entier ≥ 0 (brumes)")
	if typeof(data.get("toujours_connue", false)) != TYPE_BOOL:
		errors.append("« toujours_connue » doit être vrai ou faux")
	return errors


## Écus à payer pour voyager jusqu'à cette Pierre de Passage (0 par défaut).
func passage_price(passage_id: String) -> int:
	return int(passages.get(passage_id, {}).get("prix", 0))


## Vrai si on peut voyager jusqu'à cette pierre sans l'avoir découverte (`toujours_connue`).
func passage_always_known(passage_id: String) -> bool:
	return passages.get(passage_id, {}).get("toujours_connue", false) == true


## Pierre de Passage de la zone de départ d'une race (celle dont la `carte` est sa `carte_depart`),
## ou "" s'il n'y en a pas.
func start_passage(race_id: String) -> String:
	var start_map := str(races.get(race_id, {}).get("carte_depart", ""))
	if start_map.is_empty():
		return ""
	for passage_id: String in passages:
		if passages[passage_id]["carte"] == start_map:
			return passage_id
	return ""


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
		var effects: Variant = passive.get("effets", [])
		var valid := typeof(effects) == TYPE_ARRAY
		if valid:
			for effect: Variant in effects:
				valid = valid and typeof(effect) == TYPE_DICTIONARY and str(effect.get("type")) in PASSIVE_EFFECTS \
					and Spell._is_int_at_least(effect.get("valeur"), 1)
		if not valid:
			errors.append("« passif.effets » : liste de { type, valeur } attendue, types gérés : %s" % str(PASSIVE_EFFECTS))
	if data.has("sort") and not known_spells.has(data["sort"]):
		errors.append("sort racial inconnu : %s" % str(data["sort"]))
	if typeof(data.get("carte_depart")) != TYPE_STRING:
		errors.append("« carte_depart » doit être un id de carte")
	return errors


static func validate_monster(data: Dictionary, known_spells: Dictionary, known_items: Dictionary = {}) -> PackedStringArray:
	var errors := _validate_common(data, known_spells)
	if not Spell._is_int_at_least(data.get("niveau", 1), 1):
		errors.append("« niveau » doit être un entier ≥ 1")
	var stats: Variant = data.get("caracteristiques")
	if typeof(stats) == TYPE_DICTIONARY:
		for stat_name: String in MONSTER_STATS:
			if not Spell._is_int_at_least(stats.get(stat_name, 0), 0):
				errors.append("« caracteristiques.%s » doit être un entier ≥ 0" % stat_name)
	if typeof(data.get("elite", false)) != TYPE_BOOL:
		errors.append("« elite » doit être vrai ou faux")
	if data.get("elite", false) == true and (typeof(data.get("famille")) != TYPE_STRING or str(data.get("famille")).is_empty()):
		errors.append("un monstre élite doit indiquer sa « famille » (l'id du monstre normal)")
	if typeof(data.get("boss", false)) != TYPE_BOOL:
		errors.append("« boss » doit être vrai ou faux")
	elif data.get("boss", false) == true and (data.get("elite", false) == true or data.has("famille")):
		errors.append("un boss est un monstre unique : ni « elite » ni « famille »")
	errors.append_array(_validate_levels(data))
	errors.append_array(_validate_phases(data.get("phases", []), known_spells))
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
	if str(data.get("ia", CombatAI.BASIC)) not in CombatAI.BEHAVIOURS:
		errors.append("« ia » doit valoir %s" % str(CombatAI.BEHAVIOURS))
	var resistances: Variant = data.get("resistances", {})
	if typeof(resistances) != TYPE_DICTIONARY:
		errors.append("« resistances » doit être un objet { element: % }")
	else:
		for element: Variant in resistances:
			if element not in Spell.ELEMENTS or typeof(resistances[element]) not in [TYPE_INT, TYPE_FLOAT]:
				errors.append("résistance invalide : %s" % str(element))
	return errors


## « niveaux » (tranche et poids du tirage à l'apparition) et « par_niveau » (ajouts pour chaque
## niveau au-dessus de « niveau »).
static func _validate_levels(data: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	if data.has("niveaux"):
		var levels: Variant = data["niveaux"]
		var base := int(data.get("niveau", 1)) if Spell._is_int_at_least(data.get("niveau", 1), 1) else 1
		if data.get("elite", false) == true or data.get("boss", false) == true:
			errors.append("« niveaux » : un élite ou un boss a un niveau fixe (« niveau » seulement)")
		elif typeof(levels) != TYPE_DICTIONARY or not Spell._is_int_at_least(levels.get("min"), 1) \
				or not Spell._is_int_at_least(levels.get("max"), 1) or int(levels["max"]) < int(levels["min"]):
			errors.append("« niveaux » doit être { min, max, poids } avec 1 ≤ min ≤ max")
		elif int(levels["min"]) != base:
			errors.append("« niveaux.min » doit être égal à « niveau » (%d)" % base)
		else:
			var weights: Variant = levels.get("poids")
			var count := int(levels["max"]) - int(levels["min"]) + 1
			var valid: bool = typeof(weights) == TYPE_ARRAY and weights.size() == count
			var total := 0
			if valid:
				for weight: Variant in weights:
					if Spell._is_int_at_least(weight, 0):
						total += int(weight)
					else:
						valid = false
			if not valid or total <= 0:
				errors.append("« niveaux.poids » : un entier ≥ 0 par niveau de %d à %d (%d en tout), de somme non nulle"
					% [int(levels["min"]), int(levels["max"]), count])
	var per_level: Variant = data.get("par_niveau", {})
	if typeof(per_level) != TYPE_DICTIONARY:
		errors.append("« par_niveau » doit être un objet { caractéristique: ajout par niveau }")
		return errors
	for key: Variant in per_level:
		if key == "resistances":
			var resistances: Variant = per_level[key]
			if typeof(resistances) != TYPE_DICTIONARY:
				errors.append("« par_niveau.resistances » doit être un objet { element: entier }")
				continue
			for element: Variant in resistances:
				var value: Variant = resistances[element]
				if element not in Spell.ELEMENTS or typeof(value) not in [TYPE_INT, TYPE_FLOAT] or float(value) != floorf(float(value)):
					errors.append("par_niveau : résistance invalide : %s" % str(element))
		elif key not in PER_LEVEL_KEYS or not Spell._is_int_at_least(per_level[key], 0):
			errors.append("par_niveau : « %s » doit être l'un de %s (entier ≥ 0) ou « resistances »" % [str(key), str(PER_LEVEL_KEYS)])
	return errors


## « phases » : seuils de PV en % (de 1 à 99, strictement décroissants), avec leur message, les sorts
## gagnés et les effets que le monstre s'applique (voir `PHASE_FORBIDDEN_EFFECTS`).
static func _validate_phases(phases: Variant, known_spells: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(phases) != TYPE_ARRAY:
		errors.append("« phases » doit être une liste de { pv, message, sorts, effets }")
		return errors
	var previous := 100
	for i in phases.size():
		var phase: Variant = phases[i]
		var label := "phase %d" % (i + 1)
		if typeof(phase) != TYPE_DICTIONARY:
			errors.append("%s : objet { pv, message, sorts, effets } attendu" % label)
			continue
		var threshold: Variant = phase.get("pv")
		if not Spell._is_int_at_least(threshold, 1) or int(threshold) > 99:
			errors.append("%s : « pv » doit être un entier de 1 à 99 (%% des PV max)" % label)
		elif int(threshold) >= previous:
			errors.append("%s : « pv » doit être plus bas que celui de la phase précédente (%d)" % [label, previous])
		else:
			previous = int(threshold)
		if typeof(phase.get("message")) != TYPE_STRING or str(phase.get("message")).is_empty():
			errors.append("%s : « message » doit être un texte non vide" % label)
		var spell_ids: Variant = phase.get("sorts", [])
		if typeof(spell_ids) != TYPE_ARRAY:
			errors.append("%s : « sorts » doit être une liste d'identifiants de sorts" % label)
		else:
			for spell_id: Variant in spell_ids:
				if not known_spells.has(spell_id):
					errors.append("%s : sort inconnu : %s" % [label, str(spell_id)])
				elif _heals(known_spells[spell_id].effects):
					errors.append("%s : sort %s : %s" % [label, str(spell_id), PHASE_NO_HEAL])
		var effects: Variant = phase.get("effets", [])
		if typeof(effects) != TYPE_ARRAY:
			errors.append("%s : « effets » doit être une liste d'effets" % label)
			continue
		var on_self: Array = []
		for effect: Variant in effects:
			if typeof(effect) == TYPE_DICTIONARY and effect.get("type") in PHASE_FORBIDDEN_EFFECTS:
				errors.append("%s : effet « %s » impossible sur soi-même" % [label, effect["type"]])
			elif typeof(effect) == TYPE_DICTIONARY and effect.get("type") == Spell.EFFECT_HEAL:
				errors.append("%s : %s" % [label, PHASE_NO_HEAL])
			else:
				on_self.append(effect)
		for error in Spell._validate_effects(on_self, true):
			errors.append("%s : %s" % [label, error])
	return errors


## Vrai si ces effets (ou ceux d'une glyphe ou d'un piège parmi eux) soignent.
static func _heals(effects: Array) -> bool:
	for effect: Variant in effects:
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		if effect.get("type") == Spell.EFFECT_HEAL:
			return true
		if typeof(effect.get("effets")) == TYPE_ARRAY and _heals(effect["effets"]):
			return true
	return false


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


## Équipement de départ de la Voie (équipé) et quelques brumes, pour un personnage tout neuf.
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


## Équipement de départ d'une classe qu'on commence en cours de partie (`World._switch_class`) : dans
## le sac, sans rien retirer de ce qu'on porte.
func give_class_kit(character: Character, class_id: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(character.display_name + class_id)
	for item_id: String in voies.get(class_id, {}).get("equipement_depart", []):
		var template: Dictionary = items[item_id]
		character.inventory.add(template, 1, Item.roll_bonuses(template, rng))


## Tranche de niveaux d'un monstre : Vector2i(min, max). Sans « niveaux » (élites, boss…), son
## niveau fixe aux deux bouts.
func monster_level_range(monster_id: String) -> Vector2i:
	var data: Dictionary = monsters.get(monster_id, {})
	var base := int(data.get("niveau", 1))
	if not data.has("niveaux"):
		return Vector2i(base, base)
	return Vector2i(base, int(data["niveaux"]["max"]))


## Niveau d'un monstre qui apparaît : tiré dans sa tranche selon les « poids » de sa famille (un
## poids nul n'est jamais tiré) ; son niveau fixe, sans tirage, s'il n'en a pas.
func roll_monster_level(monster_id: String, rng: RandomNumberGenerator) -> int:
	var levels := monster_level_range(monster_id)
	if levels.x == levels.y:
		return levels.x
	var weights: Array = monsters[monster_id]["niveaux"]["poids"]
	var total := 0
	for weight: Variant in weights:
		total += int(weight)
	var roll := rng.randi_range(1, total)
	for i in weights.size():
		roll -= int(weights[i])
		if roll <= 0:
			return levels.x + i
	return levels.y


## Niveaux tirés pour une liste de monstres, dans le même ordre (voir `roll_monster_level`).
func roll_group_levels(monster_ids: Array, rng: RandomNumberGenerator) -> Array:
	var levels: Array = []
	for monster_id: String in monster_ids:
		levels.append(roll_monster_level(monster_id, rng))
	return levels


## Vrai si le monstre peut avoir le niveau `level` : un entier de sa tranche, de poids non nul (un
## poids nul n'est jamais tiré).
func is_monster_level(monster_id: String, level: Variant) -> bool:
	if not Spell._is_int_at_least(level, 1):
		return false
	var levels := monster_level_range(monster_id)
	if int(level) < levels.x or int(level) > levels.y:
		return false
	var data: Dictionary = monsters.get(monster_id, {})
	return not data.has("niveaux") or int(data["niveaux"]["poids"][int(level) - levels.x]) > 0


## Monstre prêt à combattre au niveau `level` (-1 : son niveau de base ; ramené dans sa tranche),
## ou `null` si l'id est inconnu. Chaque niveau au-dessus du niveau de base ajoute « par_niveau »
## (PV, initiative, XP, caractéristiques, résistances, et par exception PA et PM). Le butin, lui,
## ne dépend pas du niveau : il est lu dans les données du monstre (voir `World._loot`).
func create_monster(monster_id: String, fighter_id: String, level := -1) -> Fighter:
	if not monsters.has(monster_id):
		return null
	var data: Dictionary = monsters[monster_id]
	var levels := monster_level_range(monster_id)
	var fighter := _create_fighter(data, fighter_id, str(data["nom"]), Fighter.TEAM_MONSTERS)
	fighter.level = levels.x if level < 0 else clampi(level, levels.x, levels.y)
	fighter.ai = str(data.get("ia", "basique"))
	fighter.xp = int(data.get("xp", 0))
	for stat_name: String in MONSTER_STATS:
		fighter.stats[stat_name] = int(data["caracteristiques"].get(stat_name, 0))
	for element: String in data.get("resistances", {}):
		fighter.resistances[element] = int(data["resistances"][element])
	# Ajouts pour chaque niveau au-dessus du niveau de base.
	var steps := fighter.level - levels.x
	var per_level: Dictionary = data.get("par_niveau", {})
	fighter.max_hp += steps * int(per_level.get("pv", 0))
	fighter.hp = fighter.max_hp
	fighter.initiative += steps * int(per_level.get("initiative", 0))
	fighter.xp += steps * int(per_level.get("xp", 0))
	fighter.max_pa += steps * int(per_level.get("pa", 0))
	fighter.pa = fighter.max_pa
	fighter.max_pm += steps * int(per_level.get("pm", 0))
	fighter.pm = fighter.max_pm
	for stat_name: String in MONSTER_STATS:
		fighter.stats[stat_name] += steps * int(per_level.get(stat_name, 0))
	var extra_resistances: Dictionary = per_level.get("resistances", {})
	for element: String in extra_resistances:
		fighter.resistances[element] = int(fighter.resistances.get(element, 0)) + steps * int(extra_resistances[element])
	for phase: Dictionary in data.get("phases", []):
		var gained: Array[Spell] = []
		for spell_id: String in phase.get("sorts", []):
			gained.append(spells[spell_id])
		fighter.phases.append({"pv": int(phase["pv"]), "message": str(phase["message"]), "sorts": gained,
			"effets": Spell.normalized_effects(phase.get("effets", []))})
	return fighter


## Personnage joueur de la Voie donnée, ou `null` si elle est inconnue.
func create_player(voie_id: String, fighter_id: String, player_name: String) -> Fighter:
	if not voies.has(voie_id):
		return null
	return _create_fighter(voies[voie_id], fighter_id, player_name, Fighter.TEAM_PLAYERS)


## Somme des effets de passif d'une race pour ce type (`PASSIVE_EFFECTS`), 0 sans passif.
func passive_value(race_id: String, effect_type: String) -> int:
	var total := 0
	for effect: Dictionary in races.get(race_id, {}).get("passif", {}).get("effets", []):
		if effect.get("type") == effect_type:
			total += int(effect.get("valeur", 0))
	return total


## Combattant d'un personnage joueur : Voie, niveau, caractéristiques, sort et passif de race.
func create_character_fighter(character: Character, fighter_id: String) -> Fighter:
	if not voies.has(character.voie_id):
		return null
	var fighter := _create_fighter(voies[character.voie_id], fighter_id, character.display_name, Fighter.TEAM_PLAYERS)
	fighter.race = character.race_id
	fighter.level = 0  # Un joueur n'a pas de niveau (GDD § 4.5) ; celui des monstres reste leur menace.
	for stat_name in Character.STATS:
		fighter.stats[stat_name] = character.stat(stat_name, self)
	fighter.max_hp = character.max_hp(self)
	fighter.hp = character.hp(self)  # Les PV perdus se gardent d'un combat à l'autre.
	# Initiative : base de la Voie + Force, Intelligence, Perception et Agilité + équipement.
	fighter.initiative = character.initiative(self)
	var race: Dictionary = races.get(character.race_id, {})
	if race.has("sort") and spells.has(race["sort"]):
		fighter.spells.append(spells[race["sort"]])
	fighter.range_bonus = passive_value(character.race_id, "portee")
	# Équipement : bonus hors caractéristiques et attaque de l'arme.
	fighter.max_pa += character.extra("pa", self)
	fighter.pa = fighter.max_pa
	fighter.max_pm += character.extra("pm", self)
	fighter.pm = fighter.max_pm
	fighter.range_bonus += character.extra("portee", self)
	fighter.prospection = character.prospection(self)
	fighter.dommages = character.extra("dommages", self)
	fighter.crit_bonus = character.extra("critique", self)
	var weapon := character.inventory.equipped_entry("arme")
	if not weapon.is_empty() and items.has(weapon["objet"]):
		fighter.weapon = weapon["objet"]
		fighter.spells.insert(0, Spell.from_dict(Item.weapon_spell_data(items[weapon["objet"]])))
	return fighter


## Un joueur recréé d'après son profil (`Fighter.profile`), chez les autres joueurs de son combat ;
## `null` si sa Voie est inconnue.
func create_profile_fighter(profile: Dictionary, fighter_id: String) -> Fighter:
	if not voies.has(profile.get("voie", "")):
		return null
	var fighter := _create_fighter(voies[profile["voie"]], fighter_id, str(profile["nom"]), Fighter.TEAM_PLAYERS)
	fighter.race = str(profile["race"])
	fighter.level = int(profile["niveau"])
	fighter.stats = (profile["caracs"] as Dictionary).duplicate()
	fighter.max_hp = int(profile["pv_max"])
	fighter.hp = fighter.max_hp
	fighter.max_pa = int(profile["pa"])
	fighter.pa = fighter.max_pa
	fighter.max_pm = int(profile["pm"])
	fighter.pm = fighter.max_pm
	fighter.initiative = int(profile["initiative"])
	fighter.range_bonus = int(profile["portee"])
	fighter.prospection = int(profile["prospection"])
	fighter.dommages = int(profile["dommages"])
	fighter.crit_bonus = int(profile["critique"])
	fighter.resistances = (profile["resistances"] as Dictionary).duplicate()
	fighter.spells.clear()
	for spell_id: String in profile["sorts"]:
		if spells.has(spell_id):
			fighter.spells.append(spells[spell_id])
	fighter.weapon = str(profile.get("arme", ""))
	if items.has(fighter.weapon):
		fighter.spells.insert(0, Spell.from_dict(Item.weapon_spell_data(items[fighter.weapon])))
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
## Relie les combinaisons d'un effet « creer_sort » à leurs sorts (`effet.sorts` : clé → Spell).
func _link_created_spells(spell: Spell) -> PackedStringArray:
	var errors: PackedStringArray = []
	var effect := spell.create_effect()
	if effect.is_empty():
		return errors
	var linked := {}
	for key: String in effect["combinaisons"]:
		var created: Spell = spells.get(effect["combinaisons"][key])
		if created == null:
			errors.append("creer_sort : sort inconnu pour %s : %s" % [key, effect["combinaisons"][key]])
		elif not created.create_effect().is_empty():
			errors.append("creer_sort : le sort %s crée lui-même un sort" % created.id)
		else:
			linked[key] = created
	effect["sorts"] = linked
	return errors


static func _report(kind: String, raw: Variant, errors: PackedStringArray) -> bool:
	if errors.is_empty():
		return true
	var label := str(raw.get("id", "?")) if typeof(raw) == TYPE_DICTIONARY else "?"
	push_error("%s « %s » invalide :\n- %s" % [kind, label, "\n- ".join(errors)])
	return false
