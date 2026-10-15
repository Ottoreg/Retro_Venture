class_name Character
extends RefCounted
## Le personnage du joueur : identité, race, Voie, niveau, expérience et caractéristiques.
## C'est lui qui est sauvegardé entre deux parties (voir `to_dict` / `from_dict`).

const STATS := ["vitalite", "sagesse", "force", "intelligence", "chance", "agilite"]
const STAT_NAMES := {
	"vitalite": "Vitalité", "sagesse": "Sagesse", "force": "Force",
	"intelligence": "Intelligence", "chance": "Chance", "agilite": "Agilité",
}
## Caractéristiques qui s'ajoutent à l'initiative.
const INITIATIVE_STATS := ["force", "intelligence", "chance", "agilite"]
const MAX_LEVEL := 30
## Multiplicateur de l'XP de combat. Alpha 1 : ×3,5, pour finir tout le contenu (1 → 30) en 4 à 5 h
## et tester les mécaniques plutôt que la progression ; remettre 1.0 (~15 h pour les 30 premiers
## niveaux) quand on testera la vraie progression.
const XP_RATE := 3.5
const POINTS_PER_LEVEL := 5
const HP_PER_LEVEL := 5
const NAME_MIN_LENGTH := 2
const NAME_MAX_LENGTH := 20

var display_name := "Aventurier"
var race_id := "humain"
var voie_id := "guerrier"
var level := 1
## Expérience totale accumulée depuis le niveau 1.
var xp := 0
## Points investis par caractéristique (hors bonus de race).
var invested: Dictionary = {}
var unspent_points := 0
var inventory := Inventory.new()
## XP de métier : id du métier → XP totale (un métier absent est au niveau 1).
var jobs: Dictionary = {}
## Points de vie perdus (les PV actuels valent PV max − PV perdus, au moins 1). Ils se gardent
## d'un combat à l'autre ; on les regagne peu à peu, ou d'un coup en dormant dans son lit.
var hp_lost := 0
## Coffre de la maison du joueur.
var chest := Inventory.new()
const CHEST_ENTRIES := 100
## Pierres de Passage découvertes (ids) : on peut y voyager. Celle de la zone de départ de la race
## en fait toujours partie (voir `World`).
var known_passages: Array[String] = []
## Pierre de Passage où l'on se réveille après une défaite (la dernière utilisée), ou "".
var respawn_passage := ""
## Cartes où le personnage est déjà allé (ids, sans doublon), pour la future carte du monde.
var visited_maps: Array[String] = []


const BASE_PROSPECTION := 100


func _init() -> void:
	chest.capacity = CHEST_ENTRIES


static func create(p_name: String, p_race: String, p_voie: String) -> Character:
	var character := Character.new()
	character.display_name = p_name.strip_edges()
	character.race_id = p_race
	character.voie_id = p_voie
	return character


## XP totale nécessaire pour atteindre `target_level` (0 pour le niveau 1).
static func xp_for_level(target_level: int) -> int:
	var total := 0
	for n in range(1, target_level):
		total += 60 * n + 20 * n * n
	return total


## Raison pour laquelle le nom est refusé, ou "".
static func name_error(candidate: String) -> String:
	var cleaned := candidate.strip_edges()
	if cleaned.length() < NAME_MIN_LENGTH or cleaned.length() > NAME_MAX_LENGTH:
		return "Le nom doit faire entre %d et %d caractères." % [NAME_MIN_LENGTH, NAME_MAX_LENGTH]
	var allowed := RegEx.create_from_string("^[\\p{L}][\\p{L} '\\-]*$")
	if allowed.search(cleaned) == null:
		return "Le nom ne peut contenir que des lettres, des espaces, des apostrophes et des tirets."
	return ""


## Valeur totale d'une caractéristique : points investis + bonus de race + équipement.
func stat(stat_name: String, data: GameData = null) -> int:
	var total := int(invested.get(stat_name, 0)) + inventory.bonus(stat_name)
	if data != null and data.races.has(race_id):
		total += int(data.races[race_id].get("bonus", {}).get(stat_name, 0))
	return total + set_bonus(stat_name, data)


## Bonus d'équipement hors caractéristiques : prospection, initiative, portee, pa, pm, dommages, critique
## (jets des objets portés, plus les bonus de panoplie si `data` est fourni).
func extra(stat_name: String, data: GameData = null) -> int:
	return inventory.bonus(stat_name) + set_bonus(stat_name, data)


## Bonus de panoplie actif pour cette stat (0 sans données).
func set_bonus(stat_name: String, data: GameData) -> int:
	if data == null or data.sets.is_empty():
		return 0
	return int(data.set_bonuses(inventory).get(stat_name, 0))


## Prospection : 100 + Chance / 10 + équipement + passif de race. Augmente les chances de butin.
@warning_ignore("integer_division")
func prospection(data: GameData = null) -> int:
	var passive := data.passive_value(race_id, "prospection") if data != null else 0
	return BASE_PROSPECTION + stat("chance", data) / 10 + extra("prospection", data) + passive


## Initiative : base de la Voie + Force, Intelligence, Chance et Agilité + équipement. Décide de
## l'ordre de jeu en combat.
func initiative(data: GameData = null) -> int:
	var voie: Dictionary = data.voies.get(voie_id, {}) if data != null else {}
	var total := int(voie.get("caracteristiques", {}).get("initiative", 0)) + extra("initiative", data)
	for stat_name in INITIATIVE_STATS:
		total += stat(stat_name, data)
	return total


## Ajoute de l'expérience ; renvoie les niveaux atteints (vide si aucun).
func add_xp(amount: int) -> Array[int]:
	var reached: Array[int] = []
	xp += maxi(0, amount)
	while level < MAX_LEVEL and xp >= xp_for_level(level + 1):
		level += 1
		unspent_points += POINTS_PER_LEVEL
		reached.append(level)
	return reached


func job_xp(job_id: String) -> int:
	return int(jobs.get(job_id, 0))


func job_level(job_id: String) -> int:
	return Profession.level_for_xp(job_xp(job_id))


## Bonus d'XP de métier en % (passif de race « xp_metier »).
func job_xp_bonus(data: GameData) -> int:
	return data.passive_value(race_id, "xp_metier") if data != null else 0


## Ajoute de l'XP de métier ; renvoie les niveaux de métier atteints (vide si aucun).
func add_job_xp(job_id: String, amount: int) -> Array[int]:
	var before := job_level(job_id)
	jobs[job_id] = job_xp(job_id) + maxi(0, amount)
	var reached: Array[int] = []
	for level_reached in range(before + 1, job_level(job_id) + 1):
		reached.append(level_reached)
	return reached


## Métiers affichables, dans l'ordre des données : { id, nom, type, niveau, xp, xp_niveau, xp_suivant }.
func jobs_sheet(data: GameData) -> Array:
	var listed: Array = []
	if data == null:
		return listed
	for job_id: String in data.jobs:
		var level := job_level(job_id)
		listed.append({
			"id": job_id,
			"nom": data.jobs[job_id]["nom"],
			"type": data.jobs[job_id]["type"],
			"niveau": level,
			"xp": job_xp(job_id),
			"xp_niveau": Profession.xp_for_level(level),
			"xp_suivant": Profession.xp_for_level(level + 1) if level < Profession.MAX_LEVEL else job_xp(job_id),
		})
	return listed


## Ajoute une Pierre de Passage aux pierres découvertes ; vrai si elle ne l'était pas encore.
func discover_passage(passage_id: String) -> bool:
	if passage_id.is_empty() or passage_id in known_passages:
		return false
	known_passages.append(passage_id)
	return true


## Ajoute une carte aux cartes visitées (sans doublon) ; vrai si c'est la première visite.
func visit_map(map_id: String) -> bool:
	if map_id.is_empty() or map_id in visited_maps:
		return false
	visited_maps.append(map_id)
	return true


## Investit des points ; renvoie la raison du refus, ou "".
func spend_points(stat_name: String, points: int) -> String:
	if stat_name not in STATS or points <= 0:
		return Protocol.REASON_INVALID_COMMAND
	if points > unspent_points:
		return Protocol.REASON_NOT_ENOUGH_POINTS
	invested[stat_name] = int(invested.get(stat_name, 0)) + points
	unspent_points -= points
	return ""


## Fiche affichable : identité, niveau, XP, caractéristiques totales, PV maximum.
func sheet(data: GameData) -> Dictionary:
	var stats := {}
	for stat_name in STATS:
		stats[stat_name] = stat(stat_name, data)
	var voie: Dictionary = data.voies.get(voie_id, {}) if data != null else {}
	var race: Dictionary = data.races.get(race_id, {}) if data != null else {}
	return {
		"nom": display_name,
		"race": race_id,
		"race_nom": race.get("nom", race_id),
		"voie": voie_id,
		"voie_nom": voie.get("nom", voie_id),
		"niveau": level,
		"xp": xp,
		"xp_niveau": xp_for_level(level),
		"xp_suivant": xp_for_level(level + 1) if level < MAX_LEVEL else xp,
		"points": unspent_points,
		"caracteristiques": stats,
		"pv_max": max_hp(data),
		"pv": hp(data),
		"prospection": prospection(data),
		"dommages": extra("dommages", data),
		"critique": Spell.DEFAULT_CRIT_CHANCE + extra("critique", data),
		"initiative": initiative(data),
		"pa": int(voie.get("caracteristiques", {}).get("pa", 0)) + extra("pa", data),
		"pm": int(voie.get("caracteristiques", {}).get("pm", 0)) + extra("pm", data),
		"ecus": inventory.ecus,
		"metiers": jobs_sheet(data),
	}


## Inventaire affichable : objets avec leur modèle (nom, type, rareté, niveau…), emplacements, écus.
func inventory_sheet(data: GameData) -> Dictionary:
	return {"objets": _entries_sheet(inventory, data), "equipement": inventory.equipped.duplicate(), "ecus": inventory.ecus,
		"places": inventory.capacity}


## Contenu du coffre de la maison, comme l'inventaire.
func chest_sheet(data: GameData) -> Dictionary:
	return {"objets": _entries_sheet(chest, data), "places": chest.capacity}


static func _entries_sheet(source: Inventory, data: GameData) -> Array:
	var listed: Array = []
	for entry: Dictionary in source.entries.values():
		var template: Dictionary = data.items.get(entry["objet"], {}) if data != null else {}
		listed.append({
			"uid": entry["uid"],
			"objet": entry["objet"],
			"nom": template.get("nom", entry["objet"]),
			"type": template.get("type", ""),
			"rarete": template.get("rarete", "commun"),
			"niveau": int(template.get("niveau", 1)),
			"description": template.get("description", ""),
			"quantite": entry["quantite"],
			"jets": entry["jets"].duplicate(),
			"conditions": template.get("conditions", {}).duplicate(),
			"emplacement": source.slot_of(entry["uid"]),
		})
	listed.sort_custom(_inventory_order)
	return listed


## Tri de l'inventaire : par type, puis par nom.
static func _inventory_order(a: Dictionary, b: Dictionary) -> bool:
	if a["type"] != b["type"]:
		return str(a["type"]) < str(b["type"])
	if a["nom"] != b["nom"]:
		return str(a["nom"]) < str(b["nom"])
	return str(a["uid"]) < str(b["uid"])


## PV actuels (au moins 1).
func hp(data: GameData) -> int:
	return maxi(1, max_hp(data) - hp_lost)


## Ajuste les PV perdus pour avoir `value` PV (entre 1 et le maximum).
func set_hp(value: int, data: GameData) -> void:
	hp_lost = max_hp(data) - clampi(value, 1, max_hp(data))


func max_hp(data: GameData) -> int:
	if data == null or not data.voies.has(voie_id):
		return 0
	var base := int(data.voies[voie_id]["caracteristiques"]["pv"])
	return base + (level - 1) * HP_PER_LEVEL + stat("vitalite", data)


func to_dict() -> Dictionary:
	return {
		"nom": display_name,
		"race": race_id,
		"voie": voie_id,
		"niveau": level,
		"xp": xp,
		"caracteristiques": invested.duplicate(),
		"points": unspent_points,
		"inventaire": inventory.to_dict(),
		"metiers": jobs.duplicate(),
		"pv_perdus": hp_lost,
		"coffre": chest.to_dict(),
		"pierres_connues": known_passages.duplicate(),
		"point_de_resurrection": respawn_passage,
		"cartes_visitees": visited_maps.duplicate(),
	}


## Personnage relu depuis une sauvegarde, ou `null` si elle est invalide. Les objets inconnus de
## `known_items` (id → données) sont ignorés. Une vieille sauvegarde sans pierres connues ni point de
## résurrection les reçoit de `World` (pierre de la zone de départ de la race).
static func from_dict(data: Dictionary, known_items: Dictionary = {}) -> Character:
	for key in ["nom", "race", "voie"]:
		if typeof(data.get(key)) != TYPE_STRING:
			return null
	for key in ["niveau", "xp", "points"]:
		if typeof(data.get(key)) not in [TYPE_INT, TYPE_FLOAT]:
			return null
	var character := Character.create(data["nom"], data["race"], data["voie"])
	character.level = clampi(int(data["niveau"]), 1, MAX_LEVEL)
	character.xp = maxi(0, int(data["xp"]))
	character.unspent_points = maxi(0, int(data["points"]))
	var stats: Variant = data.get("caracteristiques", {})
	if typeof(stats) == TYPE_DICTIONARY:
		for stat_name: Variant in stats:
			if stat_name in STATS and typeof(stats[stat_name]) in [TYPE_INT, TYPE_FLOAT]:
				character.invested[stat_name] = maxi(0, int(stats[stat_name]))
	var lost: Variant = data.get("pv_perdus", 0)
	if typeof(lost) in [TYPE_INT, TYPE_FLOAT]:
		character.hp_lost = maxi(0, int(lost))
	if typeof(data.get("coffre")) == TYPE_DICTIONARY:
		character.chest = Inventory.from_dict(data["coffre"], known_items)
		character.chest.capacity = CHEST_ENTRIES
		character.chest.equipped.clear()
	var saved_jobs: Variant = data.get("metiers", {})
	if typeof(saved_jobs) == TYPE_DICTIONARY:
		for job_id: Variant in saved_jobs:
			if typeof(saved_jobs[job_id]) in [TYPE_INT, TYPE_FLOAT]:
				character.jobs[str(job_id)] = maxi(0, int(saved_jobs[job_id]))
	if typeof(data.get("inventaire")) == TYPE_DICTIONARY:
		character.inventory = Inventory.from_dict(data["inventaire"], known_items)
	character.known_passages = _string_list(data.get("pierres_connues", []))
	if typeof(data.get("point_de_resurrection")) == TYPE_STRING:
		character.respawn_passage = data["point_de_resurrection"]
	character.visited_maps = _string_list(data.get("cartes_visitees", []))
	return character


## Textes d'une liste sauvegardée, sans doublon ni texte vide (les autres valeurs sont ignorées).
static func _string_list(saved: Variant) -> Array[String]:
	var result: Array[String] = []
	if typeof(saved) != TYPE_ARRAY:
		return result
	for value: Variant in saved:
		if typeof(value) == TYPE_STRING and not str(value).is_empty() and value not in result:
			result.append(value)
	return result
