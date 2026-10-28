class_name Exchange
extends RefCounted
## Échange sécurisé entre deux joueurs (GDD § 16.5, jalon M4), sans réseau : les deux offres
## (objets non portés et brumes), les validations et le transfert. `World` applique les commandes
## et dit qui reçoit quoi ; le serveur sauvegarde les deux personnages ensemble.
##
## Règles (façon Dofus) : chaque changement d'une offre retire les deux validations, et on ne peut
## valider que VALIDATE_DELAY secondes après le dernier changement (contre l'objet retiré au
## dernier moment). L'échange se fait quand les deux ont validé, d'un seul coup : tout est vérifié
## sur des copies des deux inventaires avant de toucher aux vrais, si bien que rien ne peut être
## donné sans être reçu, ni reçu sans être donné. Une déconnexion, un changement de carte ou une
## annulation avant ce moment ne déplace rien.

const PROPOSE := "proposer"
const ACCEPT := "accepter"
const DECLINE := "refuser"
const ITEM := "objet"
const ECUS := "brumes"
const VALIDATE := "valider"
const CANCEL := "annuler"
const ACTIONS := [PROPOSE, ACCEPT, DECLINE, ITEM, ECUS, VALIDATE, CANCEL]

## Raisons de la fin d'un échange (EVT_EXCHANGE_CLOSED).
const CLOSED_DONE := "conclu"
const CLOSED_CANCELLED := "annule"
const CLOSED_DECLINED := "refuse"
const CLOSED_LEFT := "parti"

## Lignes d'objets dans une offre.
const MAX_ITEMS := 20
## Secondes entre le dernier changement d'une offre et la validation.
const VALIDATE_DELAY := 3.0

## Les deux joueurs (ids) : celui qui a proposé, puis celui qui a accepté.
var players: Array[String] = []
## Offre de chaque joueur : id → { objets: { uid: quantité }, brumes: int }.
var offers: Dictionary = {}
## Validation de chaque joueur : id → bool.
var validated: Dictionary = {}
## Heure du monde du dernier changement d'une offre.
var changed_at := 0.0


func _init(first: String, second: String, now: float) -> void:
	players = [first, second]
	for id in players:
		offers[id] = {"objets": {}, "brumes": 0}
		validated[id] = false
	changed_at = now


func other(id: String) -> String:
	return players[1] if id == players[0] else players[0]


## Met `quantity` exemplaires de l'objet `uid` dans l'offre de `id` (0 : le retire). Faux si l'offre
## a déjà MAX_ITEMS lignes.
func set_item(id: String, uid: String, quantity: int, now: float) -> bool:
	var items: Dictionary = offers[id]["objets"]
	if quantity <= 0:
		items.erase(uid)
	elif not items.has(uid) and items.size() >= MAX_ITEMS:
		return false
	else:
		items[uid] = quantity
	_changed(now)
	return true


func set_ecus(id: String, amount: int, now: float) -> void:
	offers[id]["brumes"] = amount
	_changed(now)


## Secondes avant de pouvoir valider (0 : maintenant).
func wait_time(now: float) -> float:
	return maxf(0.0, VALIDATE_DELAY - (now - changed_at))


func both_validated() -> bool:
	return validated[players[0]] and validated[players[1]]


func _changed(now: float) -> void:
	for id in players:
		validated[id] = false
	changed_at = now


## Fait l'échange entre les inventaires (id → Inventory) : tout ou rien. Faux (et rien n'a changé)
## si une offre n'est plus possible (objet disparu, porté ou de quête, brumes manquantes) ou si un
## sac n'a pas la place de ce qu'il reçoit.
func conclude(inventories: Dictionary, items: Dictionary) -> bool:
	var copies := {}
	for id in players:
		var inventory: Inventory = inventories[id]
		var copy := Inventory.from_dict(inventory.to_dict(), items)
		copy.capacity = inventory.capacity
		copies[id] = copy
	if not _transfer(copies, items):
		return false
	for id in players:
		var before: Inventory = inventories[id]
		if (copies[id] as Inventory).entries.size() > maxi(before.capacity, before.entries.size()):
			return false
	return _transfer(inventories, items)


## Retire les deux offres puis donne à chacun celle de l'autre.
func _transfer(inventories: Dictionary, items: Dictionary) -> bool:
	var given := {}
	for id in players:
		var inventory: Inventory = inventories[id]
		var offer: Dictionary = offers[id]
		if int(offer["brumes"]) > inventory.ecus:
			return false
		for uid: String in offer["objets"]:
			var entry: Dictionary = inventory.entries.get(uid, {})
			var quantity: int = offer["objets"][uid]
			if entry.is_empty() or quantity > int(entry["quantite"]) or not inventory.slot_of(uid).is_empty() \
					or not items.has(entry["objet"]) or items[entry["objet"]].get("type") == Item.TYPE_QUEST:
				return false
	for id in players:
		var inventory: Inventory = inventories[id]
		var offer: Dictionary = offers[id]
		given[id] = []
		for uid: String in offer["objets"]:
			var entry: Dictionary = inventory.entries[uid]
			given[id].append([items[entry["objet"]], int(offer["objets"][uid]), entry["jets"].duplicate()])
			inventory.remove(uid, offer["objets"][uid])
		inventory.ecus -= int(offer["brumes"])
	for id in players:
		var receiver: Inventory = inventories[other(id)]
		receiver.ecus += int(offers[id]["brumes"])
		for gift: Array in given[id]:
			if Item.is_equipment(gift[0]):
				for _unit in gift[1]:
					receiver.add(gift[0], 1, gift[2], true)
			else:
				receiver.add(gift[0], gift[1], {}, true)
	return true


## Ce que voit `id` de l'échange (EVT_EXCHANGE, sans `type` ni `pour`).
func view(id: String, inventories: Dictionary, now: float) -> Dictionary:
	return {
		"avec": other(id),
		"mien": _offer_view(id, inventories[id]),
		"sien": _offer_view(other(id), inventories[other(id)]),
		"valide_moi": validated[id],
		"valide_lui": validated[other(id)],
		"attente": wait_time(now),
	}


func _offer_view(id: String, inventory: Inventory) -> Dictionary:
	var lines: Array = []
	for uid: String in offers[id]["objets"]:
		var entry: Dictionary = inventory.entries.get(uid, {})
		if not entry.is_empty():
			lines.append({"uid": uid, "objet": entry["objet"], "quantite": offers[id]["objets"][uid],
				"jets": entry["jets"].duplicate()})
	return {"objets": lines, "brumes": offers[id]["brumes"]}
