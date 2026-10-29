class_name Inventory
extends RefCounted
## Inventaire du personnage : objets (les ressources s'empilent, chaque équipement est unique avec
## ses jets), emplacements d'équipement et brumes.

const MAX_ENTRIES := 60
const SLOTS := ["arme", "coiffe", "cape", "amulette", "anneau_1", "anneau_2", "ceinture", "bottes"]
## Emplacements des Reliques de l'Aube (huit bagues, équipables toutes en même temps en plus des deux
## anneaux). Visibles dans l'inventaire ; pas encore équipables (aucune Relique dans le jeu).
const RELIC_SLOT_COUNT := 8

## uid → { uid, objet (id du modèle), quantite, jets: { caractéristique: valeur } }
var entries: Dictionary = {}
## emplacement → uid
var equipped: Dictionary = {}
var ecus := 0
## Nombre maximal d'entrées (le coffre de la maison en a plus que le sac).
var capacity := MAX_ENTRIES
var _next_uid := 1


func is_full() -> bool:
	return entries.size() >= capacity


## Vrai si le sac déborde (du butin y est entré en surplus) : il faut faire de la place avant de
## pouvoir combattre à nouveau.
func is_overloaded() -> bool:
	return entries.size() > capacity


## Vrai s'il reste de la place pour `quantity` exemplaires de ce modèle (une ressource s'ajoute à
## sa pile, chaque équipement prend une place).
func has_room_for(template: Dictionary, quantity := 1) -> bool:
	var places := quantity if Item.is_equipment(template) else (0 if entries.has(template["id"]) else 1)
	return entries.size() + places <= capacity


func quantity_of(item_id: String) -> int:
	var total := 0
	for entry: Dictionary in entries.values():
		if entry["objet"] == item_id:
			total += int(entry["quantite"])
	return total


## Ajoute un objet ; renvoie son uid, ou "" si l'inventaire est plein (sauf avec `overflow` : le
## butin de combat entre toujours, en surplus).
func add(template: Dictionary, quantity := 1, rolled := {}, overflow := false) -> String:
	var item_id: String = template["id"]
	if not Item.is_equipment(template):
		if entries.has(item_id):
			entries[item_id]["quantite"] += quantity
			return item_id
		if is_full() and not overflow:
			return ""
		entries[item_id] = {"uid": item_id, "objet": item_id, "quantite": quantity, "jets": {}}
		return item_id
	if is_full() and not overflow:
		return ""
	var uid := "o%d" % _next_uid
	_next_uid += 1
	entries[uid] = {"uid": uid, "objet": item_id, "quantite": 1, "jets": rolled.duplicate()}
	return uid


## Retire une quantité ; un objet équipé est d'abord retiré de son emplacement.
func remove(uid: String, quantity := 1) -> bool:
	if not entries.has(uid) or quantity <= 0 or quantity > int(entries[uid]["quantite"]):
		return false
	entries[uid]["quantite"] -= quantity
	if int(entries[uid]["quantite"]) <= 0:
		var slot := slot_of(uid)
		if not slot.is_empty():
			equipped.erase(slot)
		entries.erase(uid)
	return true


func slot_of(uid: String) -> String:
	for slot: String in equipped:
		if equipped[slot] == uid:
			return slot
	return ""


func equip(uid: String, slot: String) -> void:
	var previous_slot := slot_of(uid)
	if not previous_slot.is_empty():
		equipped.erase(previous_slot)
	equipped[slot] = uid


func unequip(slot: String) -> void:
	equipped.erase(slot)


## Somme des jets d'une caractéristique sur les objets équipés.
func bonus(stat: String) -> int:
	var total := 0
	for uid: String in equipped.values():
		total += int(entries[uid]["jets"].get(stat, 0))
	return total


func equipped_entry(slot: String) -> Dictionary:
	return entries.get(equipped.get(slot, ""), {})


func to_dict() -> Dictionary:
	var saved_entries: Array = []
	for entry: Dictionary in entries.values():
		saved_entries.append(entry.duplicate(true))
	return {"objets": saved_entries, "equipement": equipped.duplicate(), "ecus": ecus, "prochain": _next_uid}


## Jets sauvegardés sous un ancien nom de caractéristique (GDD § 4.4, refonte du 29/10/2026).
const RENAMED_STATS := {"chance": "perception", "sagesse": "prospection"}


static func from_dict(data: Dictionary, known_items: Dictionary) -> Inventory:
	var inventory := Inventory.new()
	inventory.ecus = maxi(0, int(data.get("ecus", 0)))
	inventory._next_uid = maxi(1, int(data.get("prochain", 1)))
	var saved_entries: Variant = data.get("objets", [])
	if typeof(saved_entries) == TYPE_ARRAY:
		for entry: Variant in saved_entries:
			if typeof(entry) != TYPE_DICTIONARY or typeof(entry.get("uid")) != TYPE_STRING or not known_items.has(entry.get("objet")):
				continue
			var jets := {}
			if typeof(entry.get("jets")) == TYPE_DICTIONARY:
				for stat: Variant in entry["jets"]:
					# Avant le 29/10/2026 : Chance (devenue Perception) et Sagesse (devenue prospection).
					var key: String = RENAMED_STATS.get(str(stat), str(stat))
					jets[key] = int(jets.get(key, 0)) + int(entry["jets"][stat])
			inventory.entries[entry["uid"]] = {"uid": entry["uid"], "objet": entry["objet"], "quantite": maxi(1, int(entry.get("quantite", 1))), "jets": jets}
	var saved_equipment: Variant = data.get("equipement", {})
	if typeof(saved_equipment) == TYPE_DICTIONARY:
		for slot: Variant in saved_equipment:
			if slot in SLOTS and inventory.entries.has(saved_equipment[slot]):
				inventory.equipped[slot] = saved_equipment[slot]
	return inventory
