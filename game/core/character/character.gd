class_name Character
extends RefCounted
## Le personnage du joueur : identité, race, Voie, niveau, expérience et caractéristiques.
## C'est lui qui est sauvegardé entre deux parties (voir `to_dict` / `from_dict`).

const STATS := ["vitalite", "sagesse", "force", "intelligence", "chance", "agilite"]
const STAT_NAMES := {
	"vitalite": "Vitalité", "sagesse": "Sagesse", "force": "Force",
	"intelligence": "Intelligence", "chance": "Chance", "agilite": "Agilité",
}
const MAX_LEVEL := 30
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


## Valeur totale d'une caractéristique : points investis + bonus de race.
func stat(stat_name: String, data: GameData = null) -> int:
	var total := int(invested.get(stat_name, 0))
	if data != null and data.races.has(race_id):
		total += int(data.races[race_id].get("bonus", {}).get(stat_name, 0))
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
	}


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
	}


## Personnage relu depuis une sauvegarde, ou `null` si elle est invalide.
static func from_dict(data: Dictionary) -> Character:
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
	return character
