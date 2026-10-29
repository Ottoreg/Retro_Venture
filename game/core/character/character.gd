class_name Character
extends RefCounted
## Le personnage du joueur : identité, race, classe active, réputation et maîtrises de chaque
## classe, caractéristiques gagnées. C'est lui qui est sauvegardé entre deux parties (voir `to_dict` /
## `from_dict`). Pas de niveau (GDD § 4.5) : on progresse par la réputation (cumulée, elle débloque)
## et les points de maîtrise (à répartir), propres à chaque classe ; les caractéristiques se gagnent
## par la pratique, jusqu'à un plafond, et suivent le personnage d'une classe à l'autre.

const STATS := ["vitalite", "force", "intelligence", "perception", "agilite"]
const STAT_NAMES := {
	"vitalite": "Vitalité", "force": "Force",
	"intelligence": "Intelligence", "perception": "Perception", "agilite": "Agilité",
}
## Caractéristiques qui s'ajoutent à l'initiative.
const INITIATIVE_STATS := ["force", "intelligence", "perception", "agilite"]
## Plafond des points gagnés par la pratique, le même pour chaque caractéristique (décision de
## l'auteur du 29/10/2026, GDD § 4.5) ; le reste vient de l'équipement et des panoplies.
const STAT_CAP := 300
const VITALITY_CAP := 300
## Paliers de réputation d'une classe : [réputation minimale, nom] (pistes, GDD § 4.5).
const REPUTATION_TIERS := [[0, "Inconnu"], [1000, "Apprenti"], [5000, "Compagnon"], [15000, "Vétéran"],
	[40000, "Maître"], [100000, "Légende"]]
## Réputation qu'il faut dans une classe (la meilleure) pour en commencer une autre.
const NEW_CLASS_REPUTATION := 5000
## Un point de maîtrise à répartir par tranche de cette réputation, dans la classe qui la gagne.
const REPUTATION_PER_MASTERY_POINT := 500
## Rang de maîtrise maximal d'un sort ; monter au rang n coûte n points.
const SPELL_MAX_RANK := 5
## Bonus hors caractéristiques dont la fiche donne aussi la provenance (équipement, panoplie).
const SOURCED_EXTRAS := ["pa", "pm", "initiative", "prospection", "dommages", "critique"]
const NAME_MIN_LENGTH := 2
const NAME_MAX_LENGTH := 20

var display_name := "Aventurier"
var race_id := "humain"
## Classe active (une seule à la fois, changée hors combat).
var voie_id := "guerrier"
## Classes commencées : id de Voie → { reputation, points (de maîtrise, pas encore placés),
## sorts: { id du sort → rang de maîtrise } }. Une classe inactive garde tout.
var classes: Dictionary = {}
## Points gagnés par la pratique, par caractéristique (hors bonus de race), plafonnés.
var earned: Dictionary = {}
## Fractions de point déjà pratiquées, par caractéristique (entre 0 et 1) : elles s'ajoutent aux
## gains suivants.
var practiced: Dictionary = {}
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
## Quêtes commencées et terminées.
var quests := QuestLog.new()


const BASE_PROSPECTION := 100


func _init() -> void:
	chest.capacity = CHEST_ENTRIES


static func create(p_name: String, p_race: String, p_voie: String) -> Character:
	var character := Character.new()
	character.display_name = p_name.strip_edges()
	character.race_id = p_race
	character.voie_id = p_voie
	character._start_class(p_voie)
	return character


## Index du palier de réputation atteint avec `reputation_value` (0 : Inconnu).
static func tier_index(reputation_value: int) -> int:
	var index := 0
	for i in REPUTATION_TIERS.size():
		if reputation_value >= int(REPUTATION_TIERS[i][0]):
			index = i
	return index


static func tier_name(index: int) -> String:
	return str(REPUTATION_TIERS[clampi(index, 0, REPUTATION_TIERS.size() - 1)][1])


## Plafond des points gagnés dans une caractéristique.
static func stat_cap(stat_name: String) -> int:
	return VITALITY_CAP if stat_name == "vitalite" else STAT_CAP


## Raison pour laquelle le nom est refusé, ou "".
static func name_error(candidate: String) -> String:
	var cleaned := candidate.strip_edges()
	if cleaned.length() < NAME_MIN_LENGTH or cleaned.length() > NAME_MAX_LENGTH:
		return "Le nom doit faire entre %d et %d caractères." % [NAME_MIN_LENGTH, NAME_MAX_LENGTH]
	var allowed := RegEx.create_from_string("^[\\p{L}][\\p{L} '\\-]*$")
	if allowed.search(cleaned) == null:
		return "Le nom ne peut contenir que des lettres, des espaces, des apostrophes et des tirets."
	return ""


## Valeur totale d'une caractéristique : points gagnés + équipement (une race ne donne pas de
## caractéristiques, seulement son passif et son sort).
func stat(stat_name: String, data: GameData = null) -> int:
	return int(earned.get(stat_name, 0)) + inventory.bonus(stat_name) + set_bonus(stat_name, data)


## Bonus d'équipement hors caractéristiques : prospection, initiative, portee, pa, pm, dommages, critique
## (jets des objets portés, plus les bonus de panoplie si `data` est fourni).
func extra(stat_name: String, data: GameData = null) -> int:
	return inventory.bonus(stat_name) + set_bonus(stat_name, data)


## Bonus de panoplie actif pour cette stat (0 sans données).
func set_bonus(stat_name: String, data: GameData) -> int:
	if data == null or data.sets.is_empty():
		return 0
	return int(data.set_bonuses(inventory).get(stat_name, 0))


## Prospection : 100 + équipement + passif de race (plus de lien avec une caractéristique, GDD § 4.4).
## Augmente les chances de butin.
func prospection(data: GameData = null) -> int:
	var passive := data.passive_value(race_id, "prospection") if data != null else 0
	return BASE_PROSPECTION + extra("prospection", data) + passive


## Initiative : base de la Voie + Force, Intelligence, Perception et Agilité + équipement. Décide de
## l'ordre de jeu en combat.
func initiative(data: GameData = null) -> int:
	var voie: Dictionary = data.voies.get(voie_id, {}) if data != null else {}
	var total := int(voie.get("caracteristiques", {}).get("initiative", 0)) + extra("initiative", data)
	for stat_name in INITIATIVE_STATS:
		total += stat(stat_name, data)
	return total


func _start_class(class_id: String) -> void:
	if not classes.has(class_id):
		classes[class_id] = {"reputation": 0, "points": 0, "sorts": {}}


## Réputation dans une classe (la classe active par défaut ; 0 si elle n'est pas commencée).
func reputation(class_id := "") -> int:
	return int(classes.get(voie_id if class_id.is_empty() else class_id, {}).get("reputation", 0))


## Palier de réputation de la classe active (index dans `REPUTATION_TIERS`).
func tier() -> int:
	return tier_index(reputation())


## Points de maîtrise pas encore placés dans la classe active.
func mastery_points() -> int:
	return int(classes.get(voie_id, {}).get("points", 0))


## Rang de maîtrise d'un sort dans la classe active (0 : pas de point placé).
func spell_rank(spell_id: String) -> int:
	return int(classes.get(voie_id, {}).get("sorts", {}).get(spell_id, 0))


## Ajoute de la réputation à la classe active, avec ses points de maîtrise (un par tranche de
## `REPUTATION_PER_MASTERY_POINT`) ; renvoie les paliers atteints (index, vide si aucun).
@warning_ignore("integer_division")
func add_reputation(amount: int) -> Array[int]:
	_start_class(voie_id)
	var entry: Dictionary = classes[voie_id]
	var before := int(entry["reputation"])
	var after := before + maxi(0, amount)
	entry["reputation"] = after
	entry["points"] = int(entry["points"]) + after / REPUTATION_PER_MASTERY_POINT - before / REPUTATION_PER_MASTERY_POINT
	var reached: Array[int] = []
	for index in range(tier_index(before) + 1, tier_index(after) + 1):
		reached.append(index)
	return reached


## Place des points de maîtrise pour monter un sort d'un rang (rang n : n points) ; renvoie la
## raison du refus, ou "". `spell_ids` : les sorts de la classe active.
func raise_spell(spell_id: String, spell_ids: Array) -> String:
	if spell_id not in spell_ids:
		return Protocol.REASON_INVALID_COMMAND
	var rank := spell_rank(spell_id)
	if rank >= SPELL_MAX_RANK:
		return Protocol.REASON_INVALID_COMMAND
	if mastery_points() < rank + 1:
		return Protocol.REASON_NOT_ENOUGH_POINTS
	var entry: Dictionary = classes[voie_id]
	entry["points"] = int(entry["points"]) - (rank + 1)
	entry["sorts"][spell_id] = rank + 1
	return ""


## Ajoute des points gagnés par la pratique à une caractéristique, sans dépasser son plafond ;
## renvoie les points réellement ajoutés.
func gain_stat(stat_name: String, amount: int) -> int:
	if stat_name not in STATS or amount <= 0:
		return 0
	var before := int(earned.get(stat_name, 0))
	earned[stat_name] = mini(stat_cap(stat_name), before + amount)
	return int(earned[stat_name]) - before


## Pratique d'une caractéristique (`amount` points, fractions comprises, voir `Progression`) : plus
## lente près du plafond ; renvoie les points entiers gagnés. Rien au plafond.
func practice_stat(stat_name: String, amount: float) -> int:
	var points := int(earned.get(stat_name, 0))
	if stat_name not in STATS or amount <= 0.0 or points >= stat_cap(stat_name):
		return 0
	var total := float(practiced.get(stat_name, 0.0)) + amount * Progression.stat_pace(points, stat_cap(stat_name))
	var whole := floori(total)
	practiced[stat_name] = total - whole
	return gain_stat(stat_name, whole)


## Classes qu'on peut rendre actives : celles déjà commencées, et toutes les autres dès qu'une classe
## a `NEW_CLASS_REPUTATION` de réputation.
func can_switch_to(class_id: String) -> bool:
	if classes.has(class_id):
		return true
	for entry: Dictionary in classes.values():
		if int(entry["reputation"]) >= NEW_CLASS_REPUTATION:
			return true
	return false


## Rend une autre classe active (hors combat : à vérifier par l'appelant) ; renvoie la raison du
## refus, ou "". Une nouvelle classe part de zéro ; les caractéristiques suivent.
func switch_class(class_id: String) -> String:
	if class_id == voie_id:
		return Protocol.REASON_INVALID_COMMAND
	if not can_switch_to(class_id):
		return Protocol.REASON_REPUTATION_TOO_LOW
	_start_class(class_id)
	voie_id = class_id
	return ""


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


## Provenance d'une caractéristique ou d'un bonus d'équipement : { points, equipement,
## panoplie, objets: [[nom, valeur]…] } (seuls les objets portés qui donnent ce bonus).
func stat_sources(stat_name: String, data: GameData = null) -> Dictionary:
	var items: Array = []
	for slot: String in Inventory.SLOTS:
		var entry := inventory.equipped_entry(slot)
		var value := int(entry.get("jets", {}).get(stat_name, 0)) if not entry.is_empty() else 0
		if value != 0:
			var template: Dictionary = data.items.get(entry["objet"], {}) if data != null else {}
			items.append([template.get("nom", entry["objet"]), value])
	return {"points": int(earned.get(stat_name, 0)), "equipement": inventory.bonus(stat_name),
		"panoplie": set_bonus(stat_name, data), "objets": items}


## Fiche affichable : identité, réputation et maîtrise de la classe active, caractéristiques totales
## (et points gagnés, avec leur plafond), PV maximum.
func sheet(data: GameData) -> Dictionary:
	var stats := {}
	var sources := {}
	for stat_name in STATS:
		stats[stat_name] = stat(stat_name, data)
		sources[stat_name] = stat_sources(stat_name, data)
	for stat_name in SOURCED_EXTRAS:
		sources[stat_name] = stat_sources(stat_name, data)
	var voie: Dictionary = data.voies.get(voie_id, {}) if data != null else {}
	var race: Dictionary = data.races.get(race_id, {}) if data != null else {}
	return {
		"nom": display_name,
		"race": race_id,
		"race_nom": race.get("nom", race_id),
		"voie": voie_id,
		"voie_nom": voie.get("nom", voie_id),
		"reputation": reputation(),
		"palier": tier(),
		"palier_nom": tier_name(tier()),
		"reputation_palier": int(REPUTATION_TIERS[tier()][0]),
		"reputation_suivante": int(REPUTATION_TIERS[tier() + 1][0]) if tier() + 1 < REPUTATION_TIERS.size() else reputation(),
		"points_maitrise": mastery_points(),
		"maitrises": classes.get(voie_id, {}).get("sorts", {}).duplicate(),
		"classes": _classes_sheet(data),
		"caracteristiques": stats,
		"gagnes": earned.duplicate(),
		"plafonds": _caps(),
		"provenance": sources,
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


static func _caps() -> Dictionary:
	var caps := {}
	for stat_name in STATS:
		caps[stat_name] = stat_cap(stat_name)
	return caps


## Classes commencées : [{ id, nom, reputation, palier_nom, active }], dans l'ordre des données.
func _classes_sheet(data: GameData) -> Array:
	var listed: Array = []
	var ids: Array = data.voies.keys() if data != null else classes.keys()
	for class_id: String in ids:
		if classes.has(class_id):
			var value := reputation(class_id)
			var voie: Dictionary = data.voies.get(class_id, {}) if data != null else {}
			listed.append({"id": class_id, "nom": voie.get("nom", class_id), "reputation": value,
				"palier_nom": tier_name(tier_index(value)), "active": class_id == voie_id})
	return listed


## Inventaire affichable : objets avec leur modèle (nom, type, rareté, niveau…), emplacements, brumes.
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
	return base + stat("vitalite", data)


func to_dict() -> Dictionary:
	return {
		"nom": display_name,
		"race": race_id,
		"voie": voie_id,
		"classes": classes.duplicate(true),
		"caracteristiques": earned.duplicate(),
		"pratique": practiced.duplicate(),
		"inventaire": inventory.to_dict(),
		"metiers": jobs.duplicate(),
		"pv_perdus": hp_lost,
		"coffre": chest.to_dict(),
		"pierres_connues": known_passages.duplicate(),
		"point_de_resurrection": respawn_passage,
		"cartes_visitees": visited_maps.duplicate(),
		"quetes": quests.to_dict(),
	}


## Personnage relu depuis une sauvegarde, ou `null` si elle est invalide. Les objets inconnus de
## `known_items` (id → données) sont ignorés. Une vieille sauvegarde sans pierres connues ni point de
## résurrection les reçoit de `World` (pierre de la zone de départ de la race). Une sauvegarde
## d'avant la refonte (niveau, XP, points investis) est convertie (`_from_levels`).
static func from_dict(data: Dictionary, known_items: Dictionary = {}) -> Character:
	for key in ["nom", "race", "voie"]:
		if typeof(data.get(key)) != TYPE_STRING:
			return null
	var character := Character.create(data["nom"], data["race"], data["voie"])
	var saved_classes: Variant = data.get("classes")
	if typeof(saved_classes) == TYPE_DICTIONARY:
		for class_id: Variant in saved_classes:
			var entry: Variant = saved_classes[class_id]
			if typeof(entry) == TYPE_DICTIONARY:
				character.classes[str(class_id)] = _class_entry(entry)
	elif typeof(data.get("xp")) in [TYPE_INT, TYPE_FLOAT]:
		character.add_reputation(_from_levels(int(data["xp"])))
	character._start_class(character.voie_id)
	var stats: Variant = data.get("caracteristiques", {})
	if typeof(stats) == TYPE_DICTIONARY:
		for stat_name: Variant in stats:
			var key := str(stat_name)
			key = "perception" if key == "chance" else key  # Avant le 29/10/2026 : Chance.
			if typeof(stats[stat_name]) in [TYPE_INT, TYPE_FLOAT]:
				character.gain_stat(key, int(stats[stat_name]))
	var saved_practice: Variant = data.get("pratique", {})
	if typeof(saved_practice) == TYPE_DICTIONARY:
		for stat_name: Variant in saved_practice:
			if str(stat_name) in STATS and typeof(saved_practice[stat_name]) in [TYPE_INT, TYPE_FLOAT]:
				character.practiced[str(stat_name)] = clampf(float(saved_practice[stat_name]), 0.0, 0.999)
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
	character.quests = QuestLog.from_dict(data.get("quetes", {}))
	return character


## Réputation d'un personnage sauvegardé avec l'ancien système : son XP totale sans le ×3,5 de
## l'alpha 1 (l'XP brute d'un monstre vaut sa réputation, GDD § 8.1).
static func _from_levels(old_xp: int) -> int:
	return roundi(maxi(0, old_xp) / 3.5)


## Classe sauvegardée, avec des valeurs sûres (entiers positifs, rangs de 1 à `SPELL_MAX_RANK`).
static func _class_entry(saved: Dictionary) -> Dictionary:
	var entry := {"reputation": 0, "points": 0, "sorts": {}}
	for key in ["reputation", "points"]:
		if typeof(saved.get(key)) in [TYPE_INT, TYPE_FLOAT]:
			entry[key] = maxi(0, int(saved[key]))
	var ranks: Variant = saved.get("sorts", {})
	if typeof(ranks) == TYPE_DICTIONARY:
		for spell_id: Variant in ranks:
			if typeof(ranks[spell_id]) in [TYPE_INT, TYPE_FLOAT] and int(ranks[spell_id]) > 0:
				entry["sorts"][str(spell_id)] = mini(int(ranks[spell_id]), SPELL_MAX_RANK)
	return entry


## Textes d'une liste sauvegardée, sans doublon ni texte vide (les autres valeurs sont ignorées).
static func _string_list(saved: Variant) -> Array[String]:
	var result: Array[String] = []
	if typeof(saved) != TYPE_ARRAY:
		return result
	for value: Variant in saved:
		if typeof(value) == TYPE_STRING and not str(value).is_empty() and value not in result:
			result.append(value)
	return result
