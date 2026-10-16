class_name QuestBook
extends RefCounted
## Les quêtes dans le monde : propositions des PNJ, avancement des objectifs d'après ce qui se passe
## (combats gagnés, récoltes, fabrications, équipement, carte actuelle, dialogues), butin de quête
## et récompenses. L'état est dans `Character.quests` (`QuestLog`).

const MARKER_AVAILABLE := "!"
const MARKER_TURN_IN := "?"
const MARKER_ACTIVE := "…"

var world: World
## Quêtes refusées (« Plus tard ») pendant cette partie : le marchand ou l'artisan qui la propose
## ouvre alors sa boutique ou son atelier au lieu de la reproposer.
var _declined: Dictionary = {}
## PNJ de toutes les cartes : id → { nom, carte } (rempli au premier besoin).
var _npc_index: Dictionary = {}


func _init(p_world: World) -> void:
	world = p_world


func _log() -> QuestLog:
	return world.character.quests


func _quests() -> Dictionary:
	return world.data.quests if world.data != null else {}


# --- Conditions et marques des PNJ ---------------------------------------------------------------

## Vrai si la quête peut être proposée au personnage : pas encore commencée, conditions remplies.
func is_available(quest_id: String) -> bool:
	if not _quests().has(quest_id) or not _log().status(quest_id).is_empty():
		return false
	var character := world.character
	var conditions: Dictionary = _quests()[quest_id].get("conditions", {})
	if character.level < int(conditions.get("niveau_min", 1)):
		return false
	if conditions.has("camp") and world.data.races.get(character.race_id, {}).get("camp", "") != conditions["camp"]:
		return false
	if conditions.has("race") and character.race_id != conditions["race"]:
		return false
	if conditions.has("voie") and character.voie_id != conditions["voie"]:
		return false
	for required: String in conditions.get("quetes_terminees", []):
		if not _log().is_done(required):
			return false
	var any_of: Array = conditions.get("une_quete_terminee", [])
	if not any_of.is_empty() and not any_of.any(func(id: String) -> bool: return _log().is_done(id)):
		return false
	return true


## Quêtes que ce PNJ peut proposer maintenant, par niveau puis par id.
func offers(npc_id: String) -> Array[String]:
	var ids: Array[String] = []
	for quest_id: String in _quests():
		if _quests()[quest_id]["pnj"] == npc_id and is_available(quest_id):
			ids.append(quest_id)
	ids.sort_custom(func(a: String, b: String) -> bool:
		var la := int(_quests()[a]["niveau"])
		var lb := int(_quests()[b]["niveau"])
		return la < lb if la != lb else a < b)
	return ids


## Marque au-dessus d'un PNJ : « ? » s'il a un objectif à remplir maintenant (parler, apporter avec
## les objets en poche), « ! » s'il propose une quête, « … » s'il a donné une quête en cours, ""
## sinon.
func marker(npc_id: String) -> String:
	var waiting := false
	for quest_id in _log().active_ids():
		if not _quests().has(quest_id):
			continue
		var objectives := _step_objectives(quest_id)
		var counts := _log().counters(quest_id)
		for i in objectives.size():
			if _can_complete_by_talking(objectives, counts, i, npc_id):
				return MARKER_TURN_IN
		waiting = waiting or _quests()[quest_id]["pnj"] == npc_id
	if not offers(npc_id).is_empty():
		return MARKER_AVAILABLE
	return MARKER_ACTIVE if waiting else ""


## Vrai si l'objectif `index` de l'étape se remplit maintenant en parlant à ce PNJ : c'est le sien,
## pas encore rempli, les objets en poche pour « apporter », et les autres objectifs (combats,
## récoltes…) déjà remplis.
func _can_complete_by_talking(objectives: Array, counts: Array, index: int, npc_id: String) -> bool:
	var objective: Dictionary = objectives[index]
	if objective.get("pnj", "") != npc_id or objective["type"] not in Quest.TALK_OBJECTIVES or counts[index] >= Quest.goal(objective):
		return false
	if objective["type"] == Quest.OBJ_BRING and world.character.inventory.quantity_of(objective["objet"]) < Quest.goal(objective):
		return false
	for i in objectives.size():
		if objectives[i]["type"] not in Quest.TALK_OBJECTIVES and counts[i] < Quest.goal(objectives[i]):
			return false
	return true


# --- Dialogue, acceptation ---------------------------------------------------------------------

## Le joueur parle à ce PNJ : objectifs « parler » et « apporter » remplis, quête rendue, ou quête
## proposée. Ajoute les événements et renvoie vrai si la quête a pris la parole (le marchand ou
## l'artisan n'ouvre alors pas sa boutique ou son atelier cette fois).
func talk(npc: Dictionary, events: Array[Dictionary]) -> bool:
	var npc_id: String = npc["id"]
	var lines: Array = []
	var changed := false
	for quest_id in _log().active_ids():
		if not _quests().has(quest_id):
			continue
		# Une étape rendue peut mener à une autre qui se rend au même PNJ : on recommence.
		var talked := true
		while talked and _log().is_active(quest_id):
			talked = false
			var objectives := _step_objectives(quest_id)
			var counts := _log().counters(quest_id)
			for i in objectives.size():
				if not _can_complete_by_talking(objectives, counts, i, npc_id):
					continue
				if objectives[i]["type"] == Quest.OBJ_BRING:
					_take_items(objectives[i]["objet"], Quest.goal(objectives[i]))
				counts[i] = Quest.goal(objectives[i])
				talked = true
			if talked:
				changed = true
				_advance(quest_id, events)
				if _log().is_done(quest_id):
					lines.append_array(_dialogue(quest_id, npc_id, "fin"))
				else:
					var said := _dialogue(quest_id, npc_id, "objectif")
					lines.append_array(said if not said.is_empty() else _dialogue(quest_id, npc_id, "fin"))
	if changed:
		_dialogue_event(npc, lines, "", events)
		_journal_events(events)
		return true
	var offered := offers(npc_id)
	var has_service: bool = npc.get("marchand", false) or not str(npc.get("atelier", "")).is_empty()
	if not offered.is_empty() and not (has_service and _declined.has(offered[0])):
		var quest: Dictionary = _quests()[offered[0]]
		events.append({
			"type": Protocol.EVT_QUEST_OFFER, "pnj": npc_id, "nom": npc["nom"], "case": npc["case"],
			"quete": quest["id"], "titre": quest["nom"], "niveau": int(quest["niveau"]),
			"repliques": _dialogue(quest["id"], npc_id, "proposition"),
			"objectifs": _objective_texts(quest["id"], 0), "recompenses": _reward_sheet(quest),
		})
		return true
	for quest_id in _log().active_ids():
		if _quests().has(quest_id) and _quests()[quest_id]["pnj"] == npc_id and not has_service:
			_dialogue_event(npc, _dialogue(quest_id, npc_id, "en_cours"), quest_id, events)
			return true
	return false


func accept(quest_id: String, events: Array[Dictionary]) -> String:
	if not _quests().has(quest_id):
		return Protocol.REASON_UNKNOWN_ENTITY
	var quest: Dictionary = _quests()[quest_id]
	var npc := world.map.get_npc(quest["pnj"])
	if npc.is_empty():
		return Protocol.REASON_UNKNOWN_ENTITY
	if not GameMap.is_adjacent(world.position_of(World.PLAYER_ID), npc["case"]):
		return Protocol.REASON_TOO_FAR
	if not is_available(quest_id):
		return Protocol.REASON_REQUIREMENTS
	_log().set_step(quest_id, 0, quest["etapes"][0]["objectifs"].size())
	_log().tracked = quest_id
	_declined.erase(quest_id)
	for entry: Dictionary in quest.get("donne", []):
		_give(entry["objet"], int(entry.get("nombre", 1)), [])
	if not quest.get("donne", []).is_empty():
		events.append_array(world._inventory_events())
	events.append({"type": Protocol.EVT_QUEST_PROGRESS, "quete": quest_id, "texte": "Nouvelle quête : %s" % quest["nom"]})
	refresh(events)
	_journal_events(events)
	return ""


func decline(quest_id: String) -> void:
	if _quests().has(quest_id):
		_declined[quest_id] = true


func track(quest_id: String, events: Array[Dictionary]) -> String:
	if not quest_id.is_empty() and not _log().is_active(quest_id):
		return Protocol.REASON_UNKNOWN_ENTITY
	_log().tracked = quest_id
	_journal_events(events)
	return ""


# --- Avancement --------------------------------------------------------------------------------

## Fait avancer les quêtes d'après les événements d'une commande (récoltes, fabrications), puis les
## objectifs d'état (équipement porté, carte actuelle).
func observe(events: Array[Dictionary]) -> void:
	if _log().active_ids().is_empty():
		return
	var before := _snapshot()
	for event in events.duplicate():
		if event["type"] == Protocol.EVT_HARVESTED:
			_count(Quest.OBJ_HARVEST, func(o: Dictionary) -> bool: return o["objet"] == event["objet"], int(event["quantite"]), events)
		elif event["type"] == Protocol.EVT_CRAFTED:
			_count(Quest.OBJ_CRAFT, func(o: Dictionary) -> bool:
				return o.get("objet", event["objet"]) == event["objet"] and o.get("metier", event["metier"]) == event["metier"],
				int(event["quantite"]), events)
	refresh(events)
	if _snapshot() != before:
		_journal_events(events)


## Combat gagné contre ces monstres (`kinds` : leurs ids) : butin de quête (ajouté au butin du
## combat), objectifs « vaincre » et « vaincre_groupe ».
func combat_won(kinds: Array, rng: RandomNumberGenerator, ended: Dictionary, events: Array[Dictionary]) -> void:
	if _log().active_ids().is_empty():
		return
	var found: Array = []
	for quest_id in _log().active_ids():
		if not _quests().has(quest_id):
			continue
		for objective: Dictionary in _step_objectives(quest_id):
			var loot: Dictionary = objective.get("butin", {})
			if loot.is_empty():
				continue
			for kind: String in kinds:
				if kind in loot["monstres"] and world.character.inventory.quantity_of(objective["objet"]) < Quest.goal(objective) \
						and rng.randf() < float(loot["taux"]):
					_give(objective["objet"], 1, found)
	if not found.is_empty():
		var merged: Array = ended.get("butin", [])
		merged.append_array(found)
		ended["butin"] = World._merged_loot(merged)
		events.append(world._inventory_event())
	for kind: String in kinds:
		var family: String = world.data.monsters.get(kind, {}).get("famille", "")
		_count(Quest.OBJ_DEFEAT, func(o: Dictionary) -> bool: return o["monstre"] == kind or o["monstre"] == family, 1, events)
		_count(Quest.OBJ_DEFEAT_GROUP, func(o: Dictionary) -> bool: return o["monstre"] == kind, 1, events)
	refresh(events)
	_journal_events(events)


## Objectifs d'état (équipement porté, carte actuelle) et passage aux étapes suivantes.
func refresh(events: Array[Dictionary]) -> void:
	for quest_id in _log().active_ids():
		if not _quests().has(quest_id):
			continue
		var objectives := _step_objectives(quest_id)
		var counts := _log().counters(quest_id)
		var changed := false
		for i in objectives.size():
			if counts[i] >= Quest.goal(objectives[i]):
				continue
			if (objectives[i]["type"] == Quest.OBJ_EQUIP and _is_equipped(objectives[i])) \
					or (objectives[i]["type"] == Quest.OBJ_GO and world.map.id == objectives[i]["carte"]):
				counts[i] = 1
				changed = true
				events.append({"type": Protocol.EVT_QUEST_PROGRESS, "quete": quest_id, "texte": "%s : fait" % _objective_text(objectives[i], 1)})
		if changed or _step_done(quest_id):
			_advance(quest_id, events)


func _count(type: String, matches: Callable, amount: int, events: Array[Dictionary]) -> void:
	for quest_id in _log().active_ids():
		if not _quests().has(quest_id):
			continue
		var objectives := _step_objectives(quest_id)
		var counts := _log().counters(quest_id)
		for i in objectives.size():
			var objective: Dictionary = objectives[i]
			if objective["type"] != type or counts[i] >= Quest.goal(objective) or not matches.call(objective):
				continue
			counts[i] = mini(Quest.goal(objective), counts[i] + amount)
			events.append({"type": Protocol.EVT_QUEST_PROGRESS, "quete": quest_id, "texte": _objective_text(objective, counts[i])})
		_advance(quest_id, events)


## Passe aux étapes suivantes tant que l'étape actuelle est remplie ; la quête finie, ses récompenses.
func _advance(quest_id: String, events: Array[Dictionary]) -> void:
	var quest: Dictionary = _quests()[quest_id]
	while _log().is_active(quest_id) and _step_done(quest_id):
		var next := _log().step(quest_id) + 1
		if next >= quest["etapes"].size():
			_finish(quest_id, events)
			return
		_log().set_step(quest_id, next, quest["etapes"][next]["objectifs"].size())
		events.append({"type": Protocol.EVT_QUEST_PROGRESS, "quete": quest_id, "texte": "%s : %s" % [quest["nom"], _objective_texts(quest_id, next)[0]["texte"]]})
		# L'étape suivante est peut-être déjà remplie (objet déjà porté, déjà sur la bonne carte).
		var objectives := _step_objectives(quest_id)
		var counts := _log().counters(quest_id)
		for i in objectives.size():
			if (objectives[i]["type"] == Quest.OBJ_EQUIP and _is_equipped(objectives[i])) \
					or (objectives[i]["type"] == Quest.OBJ_GO and world.map.id == objectives[i]["carte"]):
				counts[i] = 1


func _step_done(quest_id: String) -> bool:
	var objectives := _step_objectives(quest_id)
	var counts := _log().counters(quest_id)
	for i in objectives.size():
		if i >= counts.size() or counts[i] < Quest.goal(objectives[i]):
			return false
	return true


func _finish(quest_id: String, events: Array[Dictionary]) -> void:
	var quest: Dictionary = _quests()[quest_id]
	_log().finish(quest_id)
	var rewards: Dictionary = quest.get("recompenses", {})
	var gain := Quest.reward_xp(quest)
	var ecus := int(rewards.get("ecus", 0))
	var found: Array = []
	for entry: Dictionary in rewards.get("objets", []):
		_give(entry["objet"], int(entry.get("nombre", 1)), found)
	world.character.inventory.ecus += ecus
	events.append({"type": Protocol.EVT_QUEST_DONE, "quete": quest_id, "nom": quest["nom"], "xp": gain, "ecus": ecus,
		"objets": World._merged_loot(found)})
	if gain > 0:
		var levels := world.character.add_xp(gain)
		events.append({"type": Protocol.EVT_XP, "gain": gain, "xp": world.character.xp, "niveau": world.character.level})
		for reached in levels:
			events.append({"type": Protocol.EVT_LEVEL_UP, "niveau": reached, "points": world.character.unspent_points})
	events.append_array(world._inventory_events())
	# Une quête finie peut en débloquer d'autres : la suivante de la chaîne est suivie d'office.
	if _log().tracked.is_empty() and not _log().active_ids().is_empty():
		_log().tracked = _log().active_ids()[0]


func _step_objectives(quest_id: String) -> Array:
	var steps: Array = _quests()[quest_id]["etapes"]
	return steps[clampi(_log().step(quest_id), 0, steps.size() - 1)]["objectifs"]


func _is_equipped(objective: Dictionary) -> bool:
	var inventory := world.character.inventory
	if objective.has("emplacement"):
		return inventory.equipped.has(objective["emplacement"])
	for slot: String in inventory.equipped:
		if inventory.equipped_entry(slot).get("objet", "") == objective["objet"]:
			return true
	return false


func _snapshot() -> String:
	return var_to_str(_log().entries)


# --- Objets ------------------------------------------------------------------------------------

## Ajoute un objet au sac (les équipements avec leurs jets), et le note dans `found` (butin).
func _give(item_id: String, quantity: int, found: Array) -> void:
	var template: Dictionary = world.data.items[item_id]
	var equipment := Item.is_equipment(template)
	for _unit in (quantity if equipment else 1):
		world.character.inventory.add(template, 1 if equipment else quantity, Item.roll_bonuses(template, world.rng), true)
	found.append({"objet": item_id, "nom": template["nom"], "rarete": template["rarete"], "quantite": quantity})


func _take_items(item_id: String, quantity: int) -> void:
	var inventory := world.character.inventory
	var left := quantity
	for uid: String in inventory.entries.keys():
		if left <= 0:
			break
		var entry: Dictionary = inventory.entries[uid]
		if entry["objet"] != item_id or not inventory.slot_of(uid).is_empty():
			continue
		var taken := mini(left, int(entry["quantite"]))
		inventory.remove(uid, taken)
		left -= taken


# --- Textes et fiches --------------------------------------------------------------------------

func _dialogue(quest_id: String, npc_id: String, key: String) -> Array:
	return _quests()[quest_id].get("dialogues", {}).get(npc_id, {}).get(key, []).duplicate()


func _dialogue_event(npc: Dictionary, lines: Array, quest_id: String, events: Array[Dictionary]) -> void:
	events.append({
		"type": Protocol.EVT_DIALOGUE, "pnj": npc["id"], "nom": npc["nom"], "case": npc["case"],
		"repliques": lines if not lines.is_empty() else npc["repliques"].duplicate(), "quete": quest_id,
	})


func _journal_events(events: Array[Dictionary]) -> void:
	for i in range(events.size() - 1, -1, -1):
		if events[i]["type"] == Protocol.EVT_QUESTS:
			events.remove_at(i)
	events.append({"type": Protocol.EVT_QUESTS, "journal": sheet()})


## Nom d'un PNJ d'après son id (cherché sur toutes les cartes), ou l'id s'il est introuvable.
func npc_name(npc_id: String) -> String:
	return npc_location(npc_id).get("nom", npc_id)


## { nom, carte } d'un PNJ, ou {} s'il n'est sur aucune carte.
func npc_location(npc_id: String) -> Dictionary:
	if _npc_index.is_empty():
		var ids: Array[String] = world.map_ids.duplicate()
		if world.map != null and world.map.id not in ids:
			ids.append(world.map.id)
		for map_id in ids:
			var found := world.map_by_id(map_id)
			if found != null:
				for npc: Dictionary in found.npcs:
					_npc_index[npc["id"]] = {"nom": npc["nom"], "carte": map_id}
	if not _npc_index.has(npc_id) and world.map != null:
		var here := world.map.get_npc(npc_id)
		if not here.is_empty():
			_npc_index[npc_id] = {"nom": here["nom"], "carte": world.map.id}
	return _npc_index.get(npc_id, {})


func _objective_text(objective: Dictionary, count: int) -> String:
	var data := world.data
	var base: String = objective.get("texte", "")
	var type: String = objective["type"]
	if base.is_empty():
		match type:
			Quest.OBJ_TALK:
				base = "Parler à %s" % npc_name(objective["pnj"])
			Quest.OBJ_DEFEAT:
				base = "Vaincre : %s" % data.monsters[objective["monstre"]]["nom"]
			Quest.OBJ_DEFEAT_GROUP:
				base = "Vaincre %s" % data.monsters[objective["monstre"]]["nom"]
			Quest.OBJ_HARVEST:
				base = "Récolter : %s" % data.items[objective["objet"]]["nom"]
			Quest.OBJ_CRAFT:
				base = "Fabriquer : %s" % (data.items[objective["objet"]]["nom"] if objective.has("objet") else "un objet (%s)" % data.jobs[objective["metier"]]["nom"])
			Quest.OBJ_BRING:
				base = "Apporter à %s : %s" % [npc_name(objective["pnj"]), data.items[objective["objet"]]["nom"]]
			Quest.OBJ_EQUIP:
				base = "Équiper : %s" % (data.items[objective["objet"]]["nom"] if objective.has("objet") else Item.SLOT_NAMES[objective["emplacement"]])
			Quest.OBJ_GO:
				base = "Aller à : %s" % world.map_name(objective["carte"])
	if type in Quest.COUNTED and Quest.goal(objective) > 1:
		return "%s %d / %d" % [base, count, Quest.goal(objective)]
	return base


## Objectifs d'une étape : { texte, fait, carte (où aller, pour la carte du monde) }.
func _objective_texts(quest_id: String, step_index: int) -> Array:
	var objectives: Array = _quests()[quest_id]["etapes"][step_index]["objectifs"]
	var current := _log().is_active(quest_id) and _log().step(quest_id) == step_index
	var counts := _log().counters(quest_id) if current else []
	var texts: Array = []
	for i in objectives.size():
		var objective: Dictionary = objectives[i]
		var count: int = counts[i] if i < counts.size() else 0
		if objective["type"] == Quest.OBJ_BRING and count < Quest.goal(objective):
			count = mini(Quest.goal(objective), world.character.inventory.quantity_of(objective["objet"]))
		var where: String = objective.get("carte", npc_location(objective.get("pnj", "")).get("carte", ""))
		texts.append({"texte": _objective_text(objective, count), "fait": i < counts.size() and counts[i] >= Quest.goal(objective),
			"carte": where})
	return texts


func _reward_sheet(quest: Dictionary) -> Dictionary:
	var rewards: Dictionary = quest.get("recompenses", {})
	var items: Array = []
	for entry: Dictionary in rewards.get("objets", []):
		var template: Dictionary = world.data.items[entry["objet"]]
		items.append({"objet": entry["objet"], "nom": template["nom"], "rarete": template["rarete"], "quantite": int(entry.get("nombre", 1))})
	return {"xp": Quest.reward_xp(quest), "ecus": int(rewards.get("ecus", 0)), "objets": items}


## Journal pour l'interface : quêtes en cours (la suivie d'abord) puis terminées.
func sheet() -> Dictionary:
	var active: Array = []
	var done: Array = []
	for quest_id: String in _log().entries:
		if not _quests().has(quest_id):
			continue
		var quest: Dictionary = _quests()[quest_id]
		var entry := {
			"id": quest_id, "nom": quest["nom"], "categorie": quest["categorie"], "acte": int(quest.get("acte", 0)),
			"niveau": int(quest["niveau"]), "description": quest.get("description", ""),
			"donneur": npc_name(quest["pnj"]), "recompenses": _reward_sheet(quest),
		}
		if _log().is_active(quest_id):
			entry["etape"] = _log().step(quest_id) + 1
			entry["etapes"] = quest["etapes"].size()
			entry["objectifs"] = _objective_texts(quest_id, _log().step(quest_id))
			if quest_id == _log().tracked:
				active.push_front(entry)
			else:
				active.append(entry)
		else:
			done.append(entry)
	return {"en_cours": active, "terminees": done, "suivie": _log().tracked}
