class_name QuestLog
extends RefCounted
## Avancement des quêtes d'un personnage (sauvegardé avec lui) : pour chaque quête commencée, son
## état, son étape et le compteur de chaque objectif de l'étape. Les règles sont dans `World`.

const ACTIVE := "en_cours"
const DONE := "terminee"

## id de quête → { etat, etape: int, compteurs: Array[int] }
var entries: Dictionary = {}
## Quête suivie (affichée sous la minicarte), ou "".
var tracked := ""


func status(quest_id: String) -> String:
	return entries.get(quest_id, {}).get("etat", "")


func is_done(quest_id: String) -> bool:
	return status(quest_id) == DONE


func is_active(quest_id: String) -> bool:
	return status(quest_id) == ACTIVE


func active_ids() -> Array[String]:
	var ids: Array[String] = []
	for quest_id: String in entries:
		if entries[quest_id]["etat"] == ACTIVE:
			ids.append(quest_id)
	return ids


func step(quest_id: String) -> int:
	return int(entries.get(quest_id, {}).get("etape", 0))


func counters(quest_id: String) -> Array:
	return entries.get(quest_id, {}).get("compteurs", [])


## Commence une quête (ou passe à l'étape `step_index`) avec des compteurs à zéro.
func set_step(quest_id: String, step_index: int, objective_count: int) -> void:
	var counts: Array = []
	counts.resize(objective_count)
	counts.fill(0)
	entries[quest_id] = {"etat": ACTIVE, "etape": step_index, "compteurs": counts}


func finish(quest_id: String) -> void:
	entries[quest_id] = {"etat": DONE, "etape": 0, "compteurs": []}
	if tracked == quest_id:
		tracked = ""


func to_dict() -> Dictionary:
	return {"quetes": entries.duplicate(true), "suivie": tracked}


## Journal relu d'une sauvegarde : les entrées mal formées sont ignorées (les quêtes inconnues le
## sont plus tard, par `World`).
static func from_dict(saved: Variant) -> QuestLog:
	var log := QuestLog.new()
	if typeof(saved) != TYPE_DICTIONARY:
		return log
	var quests: Variant = saved.get("quetes", {})
	if typeof(quests) == TYPE_DICTIONARY:
		for quest_id: Variant in quests:
			var entry: Variant = quests[quest_id]
			if typeof(quest_id) != TYPE_STRING or typeof(entry) != TYPE_DICTIONARY or entry.get("etat") not in [ACTIVE, DONE]:
				continue
			var counts: Array = []
			for value: Variant in entry.get("compteurs", []):
				counts.append(maxi(0, int(value)) if typeof(value) in [TYPE_INT, TYPE_FLOAT] else 0)
			log.entries[quest_id] = {"etat": entry["etat"], "etape": maxi(0, int(entry.get("etape", 0))), "compteurs": counts}
	if typeof(saved.get("suivie")) == TYPE_STRING:
		log.tracked = saved["suivie"]
	return log
