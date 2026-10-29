class_name Quest
extends RefCounted
## Règles des quêtes (données de `data/quetes/`, format dans `data/README.md`) : catégories, types
## d'objectifs, conditions, récompenses. L'avancement d'un personnage est dans `QuestLog` ; c'est
## `World` qui le fait progresser.

const CATEGORIES := ["tutoriel", "principale", "secondaire"]
const OBJ_TALK := "parler"
const OBJ_DEFEAT := "vaincre"
const OBJ_DEFEAT_GROUP := "vaincre_groupe"
const OBJ_HARVEST := "recolter"
const OBJ_CRAFT := "fabriquer"
const OBJ_BRING := "apporter"
const OBJ_EQUIP := "equiper"
const OBJ_GO := "aller"
const OBJECTIVES := [OBJ_TALK, OBJ_DEFEAT, OBJ_DEFEAT_GROUP, OBJ_HARVEST, OBJ_CRAFT, OBJ_BRING, OBJ_EQUIP, OBJ_GO]
## Objectifs qui se comptent (les autres sont faits ou pas).
const COUNTED := [OBJ_DEFEAT, OBJ_HARVEST, OBJ_CRAFT, OBJ_BRING]
## Objectifs remplis en parlant au PNJ (« rendre ») : seulement une fois les autres objectifs de
## l'étape remplis.
const TALK_OBJECTIVES := [OBJ_TALK, OBJ_BRING]
## Textes d'un PNJ dans une quête : proposition et en cours (donneur), objectif (son objectif rempli,
## la quête continue ; à défaut, « fin »), fin (quête terminée en lui parlant).
const DIALOGUE_KEYS := ["proposition", "en_cours", "objectif", "fin"]
const CONDITION_KEYS := ["camp", "race", "voie", "niveau_min", "quetes_terminees", "une_quete_terminee"]


## XP d'un « combat de référence » au niveau `level` (2 monstres de ce niveau, voir
## `docs/design/chantier3_brouillon/src/balance.py`).
static func reference_xp(level: int) -> int:
	return 2 * roundi(7.0 * level + 0.27 * level * level)


## Réputation de la récompense d'une quête : combats de référence × XP de ce combat au niveau de la
## quête (l'XP d'un monstre vaut sa réputation, GDD § 8.1).
static func reward_reputation(quest: Dictionary) -> int:
	var units := float(quest.get("recompenses", {}).get("xp_cr", 0))
	return roundi(units * reference_xp(int(quest.get("niveau", 1))))


## Nombre à atteindre pour un objectif (1 pour ceux qui ne se comptent pas).
static func goal(objective: Dictionary) -> int:
	return int(objective.get("nombre", 1)) if objective["type"] in COUNTED else 1


## Erreurs de format d'une quête (vide si elle est valide). Les liens vers les monstres, objets,
## métiers et quêtes connus sont vérifiés par `GameData.validate_quest_links` ; les PNJ et les
## cartes par les tests de données.
static func validate(data: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	for key in ["id", "nom", "pnj"]:
		if typeof(data.get(key)) != TYPE_STRING or str(data.get(key)).is_empty():
			errors.append("« %s » doit être un texte non vide" % key)
	if data.get("categorie") not in CATEGORIES:
		errors.append("« categorie » doit valoir %s" % str(CATEGORIES))
	if not Spell._is_int_at_least(data.get("niveau"), 1):
		errors.append("« niveau » doit être un entier ≥ 1")
	if typeof(data.get("description", "")) != TYPE_STRING:
		errors.append("« description » doit être un texte")
	errors.append_array(_validate_conditions(data.get("conditions", {})))
	errors.append_array(_validate_items(data.get("donne", []), "donne"))
	var steps: Variant = data.get("etapes")
	if typeof(steps) != TYPE_ARRAY or steps.is_empty():
		errors.append("« etapes » doit être une liste non vide")
	else:
		for i in steps.size():
			var step: Variant = steps[i]
			var objectives: Variant = step.get("objectifs") if typeof(step) == TYPE_DICTIONARY else null
			if typeof(objectives) != TYPE_ARRAY or objectives.is_empty():
				errors.append("étape %d : « objectifs » doit être une liste non vide" % (i + 1))
				continue
			for objective: Variant in objectives:
				for error in _validate_objective(objective):
					errors.append("étape %d : %s" % [i + 1, error])
	var dialogues: Variant = data.get("dialogues", {})
	if typeof(dialogues) != TYPE_DICTIONARY:
		errors.append("« dialogues » doit être un objet { pnj: { proposition, en_cours, fin } }")
	else:
		for npc_id: Variant in dialogues:
			var texts: Variant = dialogues[npc_id]
			if typeof(texts) != TYPE_DICTIONARY:
				errors.append("dialogues de « %s » : objet attendu" % str(npc_id))
				continue
			for key: Variant in texts:
				if key not in DIALOGUE_KEYS or typeof(texts[key]) != TYPE_ARRAY or texts[key].is_empty() \
						or not texts[key].all(func(line: Variant) -> bool: return typeof(line) == TYPE_STRING):
					errors.append("dialogues de « %s » : « %s » doit être une liste de textes (%s)" % [str(npc_id), str(key), str(DIALOGUE_KEYS)])
	var rewards: Variant = data.get("recompenses", {})
	if typeof(rewards) != TYPE_DICTIONARY:
		errors.append("« recompenses » doit être un objet { xp_cr, ecus, objets }")
	else:
		var units: Variant = rewards.get("xp_cr", 0)
		if typeof(units) not in [TYPE_INT, TYPE_FLOAT] or float(units) < 0.0:
			errors.append("« xp_cr » doit être un nombre ≥ 0")
		if not Spell._is_int_at_least(rewards.get("ecus", 0), 0):
			errors.append("« ecus » doit être un entier ≥ 0")
		errors.append_array(_validate_items(rewards.get("objets", []), "objets"))
	return errors


static func _validate_conditions(conditions: Variant) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(conditions) != TYPE_DICTIONARY:
		errors.append("« conditions » doit être un objet")
		return errors
	for key: Variant in conditions:
		if key not in CONDITION_KEYS:
			errors.append("condition inconnue « %s » (%s)" % [str(key), str(CONDITION_KEYS)])
	for key in ["camp", "race", "voie"]:
		if conditions.has(key) and typeof(conditions[key]) != TYPE_STRING:
			errors.append("condition « %s » : texte attendu" % key)
	if conditions.has("camp") and conditions["camp"] not in GameData.CAMPS:
		errors.append("condition « camp » : %s" % str(GameData.CAMPS))
	if conditions.has("niveau_min") and not Spell._is_int_at_least(conditions["niveau_min"], 1):
		errors.append("condition « niveau_min » : entier ≥ 1")
	for key in ["quetes_terminees", "une_quete_terminee"]:
		var ids: Variant = conditions.get(key, [])
		if typeof(ids) != TYPE_ARRAY or not ids.all(func(id: Variant) -> bool: return typeof(id) == TYPE_STRING):
			errors.append("condition « %s » : liste d'ids de quêtes" % key)
	return errors


static func _validate_items(entries: Variant, key: String) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(entries) != TYPE_ARRAY:
		errors.append("« %s » doit être une liste de { objet, nombre }" % key)
		return errors
	for entry: Variant in entries:
		if typeof(entry) != TYPE_DICTIONARY or typeof(entry.get("objet")) != TYPE_STRING or not Spell._is_int_at_least(entry.get("nombre", 1), 1):
			errors.append("« %s » : { objet, nombre ≥ 1 } attendu" % key)
	return errors


static func _validate_objective(objective: Variant) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(objective) != TYPE_DICTIONARY or objective.get("type") not in OBJECTIVES:
		errors.append("objectif : « type » parmi %s" % str(OBJECTIVES))
		return errors
	var type: String = objective["type"]
	var needs := {
		OBJ_TALK: ["pnj"], OBJ_DEFEAT: ["monstre"], OBJ_DEFEAT_GROUP: ["monstre"], OBJ_HARVEST: ["objet"],
		OBJ_CRAFT: [], OBJ_BRING: ["objet", "pnj"], OBJ_EQUIP: [], OBJ_GO: ["carte"],
	}
	for key: String in needs[type]:
		if typeof(objective.get(key)) != TYPE_STRING or str(objective[key]).is_empty():
			errors.append("objectif « %s » : « %s » attendu" % [type, key])
	if type == OBJ_CRAFT and not (objective.has("objet") or objective.has("metier")):
		errors.append("objectif « fabriquer » : « objet » ou « metier » attendu")
	if type == OBJ_EQUIP and not (objective.has("objet") or objective.has("emplacement")):
		errors.append("objectif « equiper » : « objet » ou « emplacement » attendu")
	if type == OBJ_EQUIP and objective.has("emplacement") and objective["emplacement"] not in Inventory.SLOTS:
		errors.append("objectif « equiper » : emplacement parmi %s" % str(Inventory.SLOTS))
	if type in COUNTED and not Spell._is_int_at_least(objective.get("nombre", 1), 1):
		errors.append("objectif « %s » : « nombre » entier ≥ 1" % type)
	if typeof(objective.get("texte", "")) != TYPE_STRING:
		errors.append("objectif « %s » : « texte » doit être un texte" % type)
	if objective.has("butin"):
		var loot: Variant = objective["butin"]
		if type != OBJ_BRING or typeof(loot) != TYPE_DICTIONARY or typeof(loot.get("monstres")) != TYPE_ARRAY \
				or loot["monstres"].is_empty() or typeof(loot.get("taux")) not in [TYPE_INT, TYPE_FLOAT] \
				or float(loot["taux"]) <= 0.0 or float(loot["taux"]) > 1.0:
			errors.append("« butin » (objectif « apporter » seulement) : { monstres: [ids], taux: ]0, 1] }")
	return errors
