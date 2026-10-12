class_name World
extends RefCounted
## Point d'entrée du noyau de jeu. Le client envoie des commandes à `execute()`, qui les valide,
## met à jour l'état et renvoie les événements produits (voir `Protocol`).
## En multijoueur, ce même code tournera sur le serveur.

const PLAYER_ID := "joueur"
const DEFAULT_VOIE := "guerrier"
const DEFAULT_NAME := "Aventurier"
## Distance (en pas) entre le groupe de monstres et les cases de placement du joueur.
const PLACEMENT_DISTANCE_MIN := 4
const PLACEMENT_DISTANCE_MAX := 6
const PLACEMENT_CELL_COUNT := 6
## Quantité maximale d'un même objet par achat ou vente.
const MAX_TRADE_QUANTITY := 100

var map: GameMap
var data: GameData
## Personnage du joueur (niveau, caractéristiques…).
var character: Character
## Raccourcis vers le personnage.
var player_voie: String:
	get:
		return character.voie_id
	set(value):
		character.voie_id = value
var player_name: String:
	get:
		return character.display_name
	set(value):
		character.display_name = value
## Combat en cours, ou `null` en exploration.
var combat: Combat = null

## Case occupée par chaque entité, par identifiant (le joueur et les groupes de monstres).
var _positions: Dictionary = {}
## Groupes de monstres encore présents sur la carte actuelle : id → { id, case, monstres }.
var _groups: Dictionary = {}
## Chargement d'une carte par son id : Callable(id: String) -> GameMap (ou null).
var _map_loader: Callable
var _loaded_maps: Dictionary = {}
## Groupes restants des cartes déjà visitées : id de carte → groupes.
var _map_states: Dictionary = {}
var _combat_group := ""
## Cases du dernier trajet du joueur (départ compris), pour pouvoir l'interrompre en chemin.
var _last_walk: Array[Vector2i] = []
## Tirages au hasard hors combat : jets des objets achetés ou fabriqués, récoltes, repousse.
var rng := RandomNumberGenerator.new()
## Temps de jeu écoulé, en secondes (avancé par `update`).
var clock := 0.0
## Ressources récoltées en attente de repousse : id de carte → { case: instant de repousse }.
var _depleted: Dictionary = {}
var _combat_count := 0
var _approach_from := Vector2i.ZERO


func _init(p_map: GameMap, p_data: GameData = null, p_map_loader: Callable = Callable(), p_character: Character = null) -> void:
	character = p_character if p_character != null else Character.create(DEFAULT_NAME, "humain", DEFAULT_VOIE)
	data = p_data
	_map_loader = p_map_loader
	rng.randomize()
	_set_map(p_map, p_map.spawn)


## Nom de la carte voisine dans cette direction, ou "" s'il n'y en a pas.
func neighbor_name(direction: String) -> String:
	if not map.exits.has(direction):
		return ""
	var neighbor := _load_map(map.exits[direction])
	return neighbor.display_name if neighbor != null else ""


func has_entity(entity_id: String) -> bool:
	return _positions.has(entity_id)


func position_of(entity_id: String) -> Vector2i:
	return _positions.get(entity_id, Vector2i(-1, -1))


## Groupes de monstres présents sur la carte.
func groups() -> Array:
	return _groups.values()


## Groupe de monstres sur la case, ou `{}`.
func group_at(cell: Vector2i) -> Dictionary:
	for group: Dictionary in _groups.values():
		if group["case"] == cell:
			return group
	return {}


func in_combat() -> bool:
	return combat != null


func execute(command: Dictionary) -> Array[Dictionary]:
	if in_combat():
		var events := combat.execute(command)
		if combat.state == Combat.State.FINISHED:
			_end_combat(events)
		return events
	var type: Variant = command.get("type")
	if typeof(type) == TYPE_STRING:
		if type == Protocol.CMD_MOVE:
			return _move(command)
		if type == Protocol.CMD_ENGAGE:
			return _engage(command)
		if type == Protocol.CMD_TALK:
			return _talk(command)
		if type == Protocol.CMD_SPEND_POINTS:
			return _spend_points(command)
		if type == Protocol.CMD_EQUIP:
			return _equip(command)
		if type == Protocol.CMD_UNEQUIP:
			return _unequip(command)
		if type == Protocol.CMD_DROP:
			return _drop(command)
		if type == Protocol.CMD_BUY:
			return _buy(command)
		if type == Protocol.CMD_SELL:
			return _sell(command)
		if type == Protocol.CMD_HARVEST:
			return _harvest(command)
		if type == Protocol.CMD_CRAFT:
			return _craft(command)
	return _refused(command, Protocol.REASON_UNKNOWN_COMMAND)


func _move(command: Dictionary) -> Array[Dictionary]:
	var entity_id: Variant = command.get("entite")
	var target: Variant = command.get("cible")
	var exit: Variant = command.get("sortie", "")
	if typeof(entity_id) != TYPE_STRING or typeof(target) != TYPE_VECTOR2I or typeof(exit) != TYPE_STRING:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	if entity_id != PLAYER_ID:
		return _refused(command, Protocol.REASON_UNKNOWN_ENTITY)
	if not map.is_inside(target):
		return _refused(command, Protocol.REASON_OUT_OF_MAP)
	if not map.is_walkable(target):
		return _refused(command, Protocol.REASON_BLOCKED)
	var next_map: GameMap = null
	if not exit.is_empty():
		if exit not in map.exit_directions(target):
			return _refused(command, Protocol.REASON_NO_EXIT)
		next_map = _load_map(map.exits[exit])
		if next_map == null:
			return _refused(command, Protocol.REASON_UNKNOWN_MAP)
	var start: Variant = _start_cell(command)
	if start == null:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var from: Vector2i = start
	var interrupted := command.has("interrompre_a")
	var path := map.find_path(from, target)
	if from == target and next_map == null and not interrupted:
		return _refused(command, Protocol.REASON_ALREADY_THERE)
	if path.is_empty() and from != target:
		return _refused(command, Protocol.REASON_NO_PATH)

	var events: Array[Dictionary] = []
	if not path.is_empty() or interrupted:
		events.append(_moved_event(from, path))
	_positions[PLAYER_ID] = target
	_remember_walk(from, path)
	if next_map != null:
		_set_map(next_map, next_map.arrival_cell(exit, target))
		events.append({
			"type": Protocol.EVT_MAP_CHANGED,
			"carte": map.id,
			"nom": map.display_name,
			"position": _positions[PLAYER_ID],
		})
	return events


## Le joueur marche à côté du PNJ, qui lui parle.
func _talk(command: Dictionary) -> Array[Dictionary]:
	var entity_id: Variant = command.get("entite")
	var npc_id: Variant = command.get("pnj")
	if typeof(entity_id) != TYPE_STRING or entity_id != PLAYER_ID or typeof(npc_id) != TYPE_STRING:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var npc := map.get_npc(npc_id)
	if npc.is_empty():
		return _refused(command, Protocol.REASON_UNKNOWN_ENTITY)
	var npc_cell: Vector2i = npc["case"]
	var start: Variant = _start_cell(command)
	if start == null:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var from: Vector2i = start
	var events: Array[Dictionary] = []
	if not GameMap.is_adjacent(from, npc_cell):
		var best := map.approach_path(from, npc_cell)
		if best.is_empty():
			return _refused(command, Protocol.REASON_NO_PATH)
		events.append(_moved_event(from, best))
		_positions[PLAYER_ID] = best[-1]
		_remember_walk(from, best)
	elif from != _positions[PLAYER_ID]:
		# Arrêté en chemin juste à côté du PNJ.
		events.append(_moved_event(from, [] as Array[Vector2i]))
		_positions[PLAYER_ID] = from
		_remember_walk(from, [] as Array[Vector2i])
	var workshop: String = npc.get("atelier", "")
	if not workshop.is_empty() and data != null and data.jobs.has(workshop):
		events.append({
			"type": Protocol.EVT_WORKSHOP,
			"pnj": npc["id"],
			"nom": npc["nom"],
			"case": npc_cell,
			"repliques": npc["repliques"].duplicate(),
			"metier": workshop,
			"nom_metier": data.jobs[workshop]["nom"],
			"recettes": _workshop_recipes(workshop),
		})
		return events
	if npc.get("marchand", false) and data != null:
		events.append({
			"type": Protocol.EVT_SHOP,
			"pnj": npc["id"],
			"nom": npc["nom"],
			"case": npc_cell,
			"repliques": npc["repliques"].duplicate(),
			"articles": _shop_articles(),
			"taux_revente": Item.RESALE_RATE,
		})
		return events
	events.append({
		"type": Protocol.EVT_DIALOGUE,
		"pnj": npc["id"],
		"nom": npc["nom"],
		"case": npc_cell,
		"repliques": npc["repliques"].duplicate(),
	})
	return events


## Case de départ d'une commande d'exploration : la position du joueur, ou la case du trajet en
## cours où il s'arrête (`interrompre_a`). `null` si cette case n'est pas sur le trajet.
func _start_cell(command: Dictionary) -> Variant:
	if not command.has("interrompre_a"):
		return _positions[PLAYER_ID]
	var stop: Variant = command["interrompre_a"]
	if typeof(stop) != TYPE_VECTOR2I or (stop not in _last_walk and stop != _positions[PLAYER_ID]):
		return null
	return stop


func _remember_walk(from: Vector2i, path: Array[Vector2i]) -> void:
	_last_walk = [from]
	_last_walk.append_array(path)


## Change de carte : mémorise les groupes restants de l'ancienne, retrouve ceux de la nouvelle.
func _set_map(next_map: GameMap, player_cell: Vector2i) -> void:
	if map != null:
		_map_states[map.id] = _groups
	map = next_map
	_loaded_maps[map.id] = map
	_groups = {}
	if _map_states.has(map.id):
		_groups = _map_states[map.id]
	else:
		for group in map.groups:
			_groups[group["id"]] = group.duplicate(true)
	_positions = {PLAYER_ID: player_cell}
	_last_walk.clear()
	for group_id: String in _groups:
		_positions[group_id] = _groups[group_id]["case"]


func _load_map(map_id: String) -> GameMap:
	if _loaded_maps.has(map_id):
		return _loaded_maps[map_id]
	if not _map_loader.is_valid():
		return null
	var loaded: GameMap = _map_loader.call(map_id)
	if loaded != null:
		_loaded_maps[map_id] = loaded
	return loaded


## Le joueur marche jusqu'au groupe de monstres, puis le combat commence.
func _engage(command: Dictionary) -> Array[Dictionary]:
	var group_id: Variant = command.get("groupe")
	var entity_id: Variant = command.get("entite")
	if typeof(entity_id) != TYPE_STRING or entity_id != PLAYER_ID or typeof(group_id) != TYPE_STRING:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	if not _groups.has(group_id):
		return _refused(command, Protocol.REASON_UNKNOWN_ENTITY)
	if data == null or not data.voies.has(player_voie):
		return _refused(command, Protocol.REASON_WRONG_PHASE)
	var group: Dictionary = _groups[group_id]
	var start: Variant = _start_cell(command)
	if start == null:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var from: Vector2i = start
	var target: Vector2i = group["case"]
	var path := map.find_path(from, target)
	if path.is_empty() and from != target:
		return _refused(command, Protocol.REASON_NO_PATH)

	var events: Array[Dictionary] = []
	if not path.is_empty() or command.has("interrompre_a"):
		events.append(_moved_event(from, path))
	# Arrivé sur le groupe par un déplacement juste avant : on se place du côté d'où il venait.
	var approach := from
	if path.is_empty() and _last_walk.size() > 1 and _last_walk[-1] == target:
		approach = _last_walk[0]
	_positions[PLAYER_ID] = target
	_last_walk.clear()
	combat = _create_combat(group, approach)
	_combat_group = group_id
	var start_events := combat.start()
	start_events[0]["groupe"] = group_id
	events.append_array(start_events)
	return events


func _create_combat(group: Dictionary, approach_from: Vector2i) -> Combat:
	var group_cell: Vector2i = group["case"]
	var fighters: Array[Fighter] = []
	var monster_cells := _cells_around(group_cell, group["monstres"].size())
	var index := 0
	for monster_id: String in group["monstres"]:
		var monster := data.create_monster(monster_id, "%s_%d" % [group["id"], index + 1])
		if monster == null:
			continue
		monster.cell = monster_cells[mini(index, monster_cells.size() - 1)]
		fighters.append(monster)
		index += 1

	var placement := _placement_cells(group_cell, approach_from, monster_cells)
	var player := data.create_character_fighter(character, PLAYER_ID)
	player.cell = placement[0]
	fighters.append(player)
	_combat_count += 1
	return Combat.new(map, fighters, placement, hash(map.id) + _combat_count)


## Cases de placement du joueur : à bonne distance du groupe, du côté d'où il arrive.
func _placement_cells(group_cell: Vector2i, approach_from: Vector2i, taken: Array[Vector2i]) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	for distance_range: Vector2i in [Vector2i(PLACEMENT_DISTANCE_MIN, PLACEMENT_DISTANCE_MAX), Vector2i(2, 9), Vector2i(1, 1000)]:
		for cell: Vector2i in map.cells():
			var distance := IsoGrid.distance(cell, group_cell)
			if map.is_walkable(cell) and cell not in taken and distance >= distance_range.x and distance <= distance_range.y:
				candidates.append(cell)
		if not candidates.is_empty():
			break
	_approach_from = approach_from
	candidates.sort_custom(_closer_to_approach)
	return candidates.slice(0, PLACEMENT_CELL_COUNT)


## Tri des cases de placement : les plus proches du point d'arrivée du joueur d'abord.
func _closer_to_approach(a: Vector2i, b: Vector2i) -> bool:
	var key_a := Vector3i(IsoGrid.distance(a, _approach_from), a.y, a.x)
	var key_b := Vector3i(IsoGrid.distance(b, _approach_from), b.y, b.x)
	return key_a < key_b


## `count` cases praticables les plus proches de `center` (en largeur, 4 directions).
func _cells_around(center: Vector2i, count: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var seen := {center: true}
	var frontier: Array[Vector2i] = [center]
	while not frontier.is_empty() and result.size() < count:
		var next_frontier: Array[Vector2i] = []
		for cell in frontier:
			if map.is_walkable(cell) and result.size() < count:
				result.append(cell)
			for neighbor in IsoGrid.neighbors_4(cell):
				if not seen.has(neighbor) and map.is_inside(neighbor):
					seen[neighbor] = true
					next_frontier.append(neighbor)
		frontier = next_frontier
	return result


func _end_combat(events: Array[Dictionary]) -> void:
	var defeated_group := ""
	if combat.winner_team == Fighter.TEAM_PLAYERS:
		defeated_group = _combat_group
		_groups.erase(_combat_group)
		_positions.erase(_combat_group)
	else:
		_positions[PLAYER_ID] = map.spawn
	_reward(events)
	if combat.winner_team == Fighter.TEAM_PLAYERS:
		_loot(events)
	events.append({
		"type": Protocol.EVT_EXPLORATION,
		"position": _positions[PLAYER_ID],
		"groupe_vaincu": defeated_group,
	})
	combat = null
	_combat_group = ""


## XP des monstres vaincus, même en cas de défaite (bonus de Sagesse : +1 % par point), et
## montées de niveau.
func _reward(events: Array[Dictionary]) -> void:
	for event in events:
		if event["type"] == Protocol.EVT_COMBAT_ENDED:
			if int(event["xp"]) <= 0:
				return
			var gain := roundi(int(event["xp"]) * (100 + character.stat("sagesse", data)) / 100.0)
			event["xp"] = gain
			var levels := character.add_xp(gain)
			event["niveaux"] = levels
			events.append({"type": Protocol.EVT_XP, "gain": gain, "xp": character.xp, "niveau": character.level})
			for reached in levels:
				events.append({"type": Protocol.EVT_LEVEL_UP, "niveau": reached, "points": character.unspent_points})
			events.append(_character_event())
			return


## Butin de victoire : pour chaque monstre et chaque ligne de sa table, chance = taux × prospection
## / 100 (au plus 100 %). Pas de seuil : un personnage seul peut tout obtenir. Plus des écus.
func _loot(events: Array[Dictionary]) -> void:
	var ended: Dictionary = {}
	for event in events:
		if event["type"] == Protocol.EVT_COMBAT_ENDED:
			ended = event
	var player := combat.get_fighter(PLAYER_ID)
	var prospection: int = player.prospection if player != null else Character.BASE_PROSPECTION
	var rng := combat.rng
	var found: Array[Dictionary] = []
	var coins := 0
	for fighter in combat.fighters:
		if fighter.team == Fighter.TEAM_PLAYERS or not data.monsters.has(fighter.kind):
			continue
		var monster: Dictionary = data.monsters[fighter.kind]
		var coin_range: Array = monster.get("ecus", [0, 0])
		coins += rng.randi_range(int(coin_range[0]), int(coin_range[1]))
		for drop: Dictionary in monster.get("butin", []):
			var chance := minf(1.0, float(drop["taux"]) * prospection / 100.0)
			if rng.randf() >= chance:
				continue
			var amount: Array = drop.get("quantite", [1, 1])
			var template: Dictionary = data.items[drop["objet"]]
			var quantity := rng.randi_range(int(amount[0]), int(amount[1]))
			for _unit in (quantity if Item.is_equipment(template) else 1):
				var uid := character.inventory.add(template, 1 if Item.is_equipment(template) else quantity, Item.roll_bonuses(template, rng))
				found.append({"objet": template["id"], "nom": template["nom"], "rarete": template["rarete"],
					"quantite": 1 if Item.is_equipment(template) else quantity, "perdu": uid.is_empty()})
	character.inventory.ecus += coins
	ended["butin"] = found
	ended["ecus"] = coins
	events.append(_inventory_event())


func _equip(command: Dictionary) -> Array[Dictionary]:
	var uid: Variant = command.get("objet")
	var wanted_slot: Variant = command.get("emplacement", "")
	if not _is_player_command(command) or typeof(uid) != TYPE_STRING or typeof(wanted_slot) != TYPE_STRING:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var inventory := character.inventory
	if not inventory.entries.has(uid) or not data.items.has(inventory.entries[uid]["objet"]):
		return _refused(command, Protocol.REASON_UNKNOWN_ITEM)
	var template: Dictionary = data.items[inventory.entries[uid]["objet"]]
	if not Item.is_equipment(template):
		return _refused(command, Protocol.REASON_NOT_EQUIPPABLE)
	var slots: Array = Item.SLOTS_BY_TYPE[template["type"]]
	var slot: String = wanted_slot
	if slot.is_empty():
		slot = slots[0]
		for candidate: String in slots:
			if not inventory.equipped.has(candidate):
				slot = candidate
				break
	if slot not in slots:
		return _refused(command, Protocol.REASON_NOT_EQUIPPABLE)
	if character.level < int(template.get("niveau", 1)):
		return _refused(command, Protocol.REASON_REQUIREMENTS)
	var conditions: Dictionary = template.get("conditions", {})
	for stat_name: String in conditions:
		if character.stat(stat_name, data) < int(conditions[stat_name]):
			return _refused(command, Protocol.REASON_REQUIREMENTS)
	# Deux exemplaires du même objet (deux anneaux identiques…) ne se portent pas ensemble.
	for other_slot: String in slots:
		var other := inventory.equipped_entry(other_slot)
		if other_slot != slot and not other.is_empty() and other["uid"] != uid and other["objet"] == template["id"]:
			return _refused(command, Protocol.REASON_ALREADY_WORN)
	inventory.equip(uid, slot)
	return _inventory_events()


func _unequip(command: Dictionary) -> Array[Dictionary]:
	var slot: Variant = command.get("emplacement")
	if not _is_player_command(command) or typeof(slot) != TYPE_STRING or slot not in Inventory.SLOTS:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	if not character.inventory.equipped.has(slot):
		return _refused(command, Protocol.REASON_EMPTY_SLOT)
	character.inventory.unequip(slot)
	return _inventory_events()


func _drop(command: Dictionary) -> Array[Dictionary]:
	var uid: Variant = command.get("objet")
	var quantity: Variant = command.get("quantite", 1)
	if not _is_player_command(command) or typeof(uid) != TYPE_STRING or typeof(quantity) != TYPE_INT:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	if not character.inventory.remove(uid, quantity):
		return _refused(command, Protocol.REASON_UNKNOWN_ITEM)
	return _inventory_events()


# --- Marchands ----------------------------------------------------------------------------------

## Tous les objets du jeu, avec leur prix d'achat.
func _shop_articles() -> Array:
	var articles: Array = []
	for template: Dictionary in data.items.values():
		articles.append({
			"objet": template["id"],
			"nom": template["nom"],
			"type": template["type"],
			"rarete": template["rarete"],
			"niveau": int(template.get("niveau", 1)),
			"description": template.get("description", ""),
			"bonus": template.get("bonus", {}).duplicate(true),
			"conditions": template.get("conditions", {}).duplicate(),
			"prix": Item.buy_price(template),
		})
	articles.sort_custom(_article_order)
	return articles


## Tri de la boutique : équipements puis ressources, par rareté, niveau et nom.
static func _article_order(a: Dictionary, b: Dictionary) -> bool:
	var resource_a: bool = a["type"] == Item.TYPE_RESOURCE
	var resource_b: bool = b["type"] == Item.TYPE_RESOURCE
	if resource_a != resource_b:
		return resource_b
	var rarity_a := Item.RARITIES.find(a["rarete"])
	var rarity_b := Item.RARITIES.find(b["rarete"])
	if rarity_a != rarity_b:
		return rarity_a < rarity_b
	if a["niveau"] != b["niveau"]:
		return int(a["niveau"]) < int(b["niveau"])
	return str(a["nom"]) < str(b["nom"])


## Raison de refuser un achat, une vente ou une fabrication auprès du PNJ `pnj` de la commande
## ("" si tout va bien) : il doit être sur la carte et offrir ce service (`marchand`, ou `atelier`
## du métier `job_id`), et le joueur doit se tenir à côté de lui.
func _service_refusal(command: Dictionary, job_id := "") -> String:
	var npc_id: Variant = command.get("pnj")
	if typeof(npc_id) != TYPE_STRING:
		return Protocol.REASON_INVALID_COMMAND
	if data == null:
		return Protocol.REASON_WRONG_PHASE
	var npc := map.get_npc(npc_id)
	var offered: bool = npc.get("atelier", "") == job_id if not job_id.is_empty() else npc.get("marchand", false)
	if npc.is_empty() or not offered:
		return Protocol.REASON_UNKNOWN_ENTITY
	if not GameMap.is_adjacent(_positions[PLAYER_ID], npc["case"]):
		return Protocol.REASON_TOO_FAR
	return ""


func _trade_quantity(command: Dictionary) -> int:
	var quantity: Variant = command.get("quantite", 1)
	if typeof(quantity) != TYPE_INT or quantity < 1 or quantity > MAX_TRADE_QUANTITY:
		return 0
	return quantity


func _buy(command: Dictionary) -> Array[Dictionary]:
	var item_id: Variant = command.get("objet")
	var quantity := _trade_quantity(command)
	if not _is_player_command(command) or typeof(item_id) != TYPE_STRING or quantity == 0:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var reason := _service_refusal(command)
	if not reason.is_empty():
		return _refused(command, reason)
	if not data.items.has(item_id):
		return _refused(command, Protocol.REASON_UNKNOWN_ITEM)
	var template: Dictionary = data.items[item_id]
	var inventory := character.inventory
	var price := Item.buy_price(template) * quantity
	if price > inventory.ecus:
		return _refused(command, Protocol.REASON_NOT_ENOUGH_ECUS)
	# Chaque équipement prend une place ; une ressource s'ajoute à sa pile si on en a déjà.
	var equipment := Item.is_equipment(template)
	var places := quantity if equipment else (0 if inventory.entries.has(item_id) else 1)
	if inventory.entries.size() + places > Inventory.MAX_ENTRIES:
		return _refused(command, Protocol.REASON_INVENTORY_FULL)
	inventory.ecus -= price
	if equipment:
		for _unit in quantity:
			inventory.add(template, 1, Item.roll_bonuses(template, rng))
	else:
		inventory.add(template, quantity)
	return _trade_events("achat", template, quantity, price)


func _sell(command: Dictionary) -> Array[Dictionary]:
	var uid: Variant = command.get("objet")
	var quantity := _trade_quantity(command)
	if not _is_player_command(command) or typeof(uid) != TYPE_STRING or quantity == 0:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var reason := _service_refusal(command)
	if not reason.is_empty():
		return _refused(command, reason)
	var inventory := character.inventory
	if not inventory.entries.has(uid) or not data.items.has(inventory.entries[uid]["objet"]):
		return _refused(command, Protocol.REASON_UNKNOWN_ITEM)
	if not inventory.slot_of(uid).is_empty():
		return _refused(command, Protocol.REASON_ITEM_WORN)
	if quantity > int(inventory.entries[uid]["quantite"]):
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var template: Dictionary = data.items[inventory.entries[uid]["objet"]]
	var price := Item.sell_price(template) * quantity
	inventory.remove(uid, quantity)
	inventory.ecus += price
	return _trade_events("vente", template, quantity, price)


func _trade_events(operation: String, template: Dictionary, quantity: int, price: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = [{
		"type": Protocol.EVT_TRADE,
		"operation": operation,
		"objet": template["id"],
		"nom": template["nom"],
		"quantite": quantity,
		"prix": price,
		"ecus": character.inventory.ecus,
	}]
	events.append_array(_inventory_events())
	return events


# --- Métiers : récolte et artisanat ------------------------------------------------------------

## Fait avancer le temps : les ressources récoltées repoussent. Renvoie un événement
## EVT_RESOURCE_RESPAWNED par ressource de la carte actuelle qui a repoussé.
func update(delta: float) -> Array[Dictionary]:
	clock += delta
	var events: Array[Dictionary] = []
	for map_id: String in _depleted:
		var cells: Dictionary = _depleted[map_id]
		for cell: Vector2i in cells.keys():
			if cells[cell] <= clock:
				cells.erase(cell)
				if map != null and map_id == map.id:
					events.append({"type": Protocol.EVT_RESOURCE_RESPAWNED, "carte": map_id, "case": cell})
	return events


## Ressource de la carte actuelle sur cette case (voir `GameData.nodes`), ou {}.
func resource_node(cell: Vector2i) -> Dictionary:
	if data == null or not map.resource_nodes.has(cell):
		return {}
	return data.nodes.get(map.resource_nodes[cell], {})


## Vrai si la ressource de cette case (carte actuelle) a été récoltée et n'a pas encore repoussé.
func is_depleted(cell: Vector2i) -> bool:
	return _depleted.get(map.id, {}).has(cell)


## Raison de ne pas pouvoir récolter la ressource de cette case, distance mise à part ("" si on peut).
func harvest_refusal(cell: Vector2i) -> String:
	var node := resource_node(cell)
	if node.is_empty():
		return Protocol.REASON_UNKNOWN_ENTITY
	if is_depleted(cell):
		return Protocol.REASON_DEPLETED
	if character.job_level(node["metier"]) < int(node.get("niveau", 1)):
		return Protocol.REASON_JOB_LEVEL
	if character.inventory.is_full() and not character.inventory.entries.has(node["objet"]):
		return Protocol.REASON_INVENTORY_FULL
	return ""


func _harvest(command: Dictionary) -> Array[Dictionary]:
	var cell: Variant = command.get("case")
	if not _is_player_command(command) or typeof(cell) != TYPE_VECTOR2I:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var reason := harvest_refusal(cell)
	if not reason.is_empty():
		return _refused(command, reason)
	if not GameMap.is_adjacent(_positions[PLAYER_ID], cell):
		return _refused(command, Protocol.REASON_TOO_FAR)
	var node := resource_node(cell)
	var template: Dictionary = data.items[node["objet"]]
	var amount: Array = node.get("quantite", [1, 1])
	var quantity := rng.randi_range(int(amount[0]), int(amount[1]))
	character.inventory.add(template, quantity)
	var regrowth: Array = node["repousse"]
	if not _depleted.has(map.id):
		_depleted[map.id] = {}
	_depleted[map.id][cell] = clock + rng.randf_range(float(regrowth[0]), float(regrowth[1]))
	var events: Array[Dictionary] = [{
		"type": Protocol.EVT_HARVESTED,
		"entite": PLAYER_ID,
		"case": cell,
		"ressource": node["nom"],
		"objet": template["id"],
		"nom": template["nom"],
		"quantite": quantity,
		"metier": node["metier"],
	}]
	events.append(_job_event(node["metier"], int(node.get("xp", 0))))
	events.append_array(_inventory_events())
	return events


## Recettes d'un métier d'artisanat, par niveau puis par nom.
func _workshop_recipes(job_id: String) -> Array:
	var listed: Array = []
	for recipe: Dictionary in data.jobs[job_id].get("recettes", []):
		var template: Dictionary = data.items[recipe["objet"]]
		var ingredients: Array = []
		for item_id: String in recipe["ingredients"]:
			ingredients.append({"objet": item_id, "nom": data.items[item_id]["nom"], "quantite": int(recipe["ingredients"][item_id])})
		listed.append({
			"objet": template["id"],
			"nom": template["nom"],
			"type": template["type"],
			"rarete": template["rarete"],
			"niveau": int(recipe.get("niveau", 1)),
			"niveau_objet": int(template.get("niveau", 1)),
			"description": template.get("description", ""),
			"bonus": template.get("bonus", {}).duplicate(true),
			"conditions": template.get("conditions", {}).duplicate(),
			"ingredients": ingredients,
			"xp": int(recipe.get("xp", 0)),
		})
	listed.sort_custom(_recipe_order)
	return listed


static func _recipe_order(a: Dictionary, b: Dictionary) -> bool:
	if a["niveau"] != b["niveau"]:
		return int(a["niveau"]) < int(b["niveau"])
	return str(a["nom"]) < str(b["nom"])


func _craft(command: Dictionary) -> Array[Dictionary]:
	var recipe_id: Variant = command.get("recette")
	var quantity := _trade_quantity(command)
	if not _is_player_command(command) or typeof(recipe_id) != TYPE_STRING or quantity == 0:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	if data == null or not data.recipes.has(recipe_id):
		return _refused(command, Protocol.REASON_UNKNOWN_ITEM)
	var recipe: Dictionary = data.recipes[recipe_id]
	var job_id: String = recipe["metier"]
	var reason := _service_refusal(command, job_id)
	if not reason.is_empty():
		return _refused(command, reason)
	if character.job_level(job_id) < int(recipe.get("niveau", 1)):
		return _refused(command, Protocol.REASON_JOB_LEVEL)
	var inventory := character.inventory
	var ingredients: Dictionary = recipe["ingredients"]
	var freed := 0
	for item_id: String in ingredients:
		var needed := int(ingredients[item_id]) * quantity
		var owned := inventory.quantity_of(item_id)
		if owned < needed:
			return _refused(command, Protocol.REASON_MISSING_INGREDIENTS)
		if owned == needed:
			freed += 1
	var template: Dictionary = data.items[recipe_id]
	var equipment := Item.is_equipment(template)
	var places := quantity if equipment else (0 if inventory.entries.has(recipe_id) else 1)
	if inventory.entries.size() - freed + places > Inventory.MAX_ENTRIES:
		return _refused(command, Protocol.REASON_INVENTORY_FULL)
	# Les ingrédients sont des ressources : leur uid est leur id.
	for item_id: String in ingredients:
		inventory.remove(item_id, int(ingredients[item_id]) * quantity)
	if equipment:
		for _unit in quantity:
			inventory.add(template, 1, Item.roll_bonuses(template, rng))
	else:
		inventory.add(template, quantity)
	var events: Array[Dictionary] = [{
		"type": Protocol.EVT_CRAFTED,
		"objet": recipe_id,
		"nom": template["nom"],
		"quantite": quantity,
		"metier": job_id,
	}]
	events.append(_job_event(job_id, int(recipe.get("xp", 0)) * quantity))
	events.append_array(_inventory_events())
	return events


## Ajoute de l'XP de métier (avec le bonus de race) et décrit le résultat.
func _job_event(job_id: String, base_gain: int) -> Dictionary:
	var gain := floori(base_gain * (100 + character.job_xp_bonus(data)) / 100.0)
	var reached := character.add_job_xp(job_id, gain)
	var level := character.job_level(job_id)
	return {
		"type": Protocol.EVT_JOB,
		"metier": job_id,
		"nom": data.jobs[job_id]["nom"],
		"gain": gain,
		"niveau": level,
		"xp": character.job_xp(job_id),
		"xp_niveau": Profession.xp_for_level(level),
		"xp_suivant": Profession.xp_for_level(level + 1) if level < Profession.MAX_LEVEL else character.job_xp(job_id),
		"niveaux": reached,
	}


func _is_player_command(command: Dictionary) -> bool:
	var entity_id: Variant = command.get("entite")
	return typeof(entity_id) == TYPE_STRING and entity_id == PLAYER_ID


func _inventory_events() -> Array[Dictionary]:
	var events: Array[Dictionary] = [_inventory_event(), _character_event()]
	return events


func _inventory_event() -> Dictionary:
	return {"type": Protocol.EVT_INVENTORY, "inventaire": character.inventory_sheet(data)}


func _spend_points(command: Dictionary) -> Array[Dictionary]:
	var entity_id: Variant = command.get("entite")
	var stat_name: Variant = command.get("carac")
	var points: Variant = command.get("points", 1)
	if typeof(entity_id) != TYPE_STRING or entity_id != PLAYER_ID or typeof(stat_name) != TYPE_STRING or typeof(points) != TYPE_INT:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var reason := character.spend_points(stat_name, points)
	if not reason.is_empty():
		return _refused(command, reason)
	var events: Array[Dictionary] = [_character_event()]
	return events


func _character_event() -> Dictionary:
	return {"type": Protocol.EVT_CHARACTER, "personnage": character.sheet(data)}


# --- Sauvegarde ---------------------------------------------------------------------------------

const SAVE_VERSION := 1


## État à sauvegarder : personnage, carte et position, groupes restants des cartes visitées.
func save_data() -> Dictionary:
	var remaining := {}
	_map_states[map.id] = _groups
	for map_id: String in _map_states:
		remaining[map_id] = _map_states[map_id].keys()
	var position := position_of(PLAYER_ID)
	return {
		"version": SAVE_VERSION,
		"personnage": character.to_dict(),
		"carte": map.id,
		"position": [position.x, position.y],
		"groupes_restants": remaining,
	}


## Monde reconstruit depuis une sauvegarde, ou `null` si elle est inutilisable.
static func from_save(save: Dictionary, p_data: GameData, p_map_loader: Callable) -> World:
	if int(save.get("version", 0)) != SAVE_VERSION or typeof(save.get("personnage")) != TYPE_DICTIONARY:
		return null
	var saved_character := Character.from_dict(save["personnage"], p_data.items if p_data != null else {})
	if saved_character == null or typeof(save.get("carte")) != TYPE_STRING or not p_map_loader.is_valid():
		return null
	var start_map: GameMap = p_map_loader.call(save["carte"])
	if start_map == null:
		return null
	var world := World.new(start_map, p_data, p_map_loader, saved_character)
	var remaining: Variant = save.get("groupes_restants", {})
	if typeof(remaining) == TYPE_DICTIONARY:
		for map_id: Variant in remaining:
			if typeof(map_id) != TYPE_STRING or typeof(remaining[map_id]) != TYPE_ARRAY:
				continue
			var saved_map := world._load_map(map_id)
			if saved_map == null:
				continue
			var groups := {}
			for group in saved_map.groups:
				if group["id"] in remaining[map_id]:
					groups[group["id"]] = group.duplicate(true)
			world._map_states[map_id] = groups
		if world._map_states.has(start_map.id):
			world._groups = world._map_states[start_map.id]
	var saved_position: Variant = save.get("position")
	var position := start_map.spawn
	if typeof(saved_position) == TYPE_ARRAY and saved_position.size() == 2:
		var cell := Vector2i(int(saved_position[0]), int(saved_position[1]))
		if start_map.is_walkable(cell):
			position = cell
	world._positions = {PLAYER_ID: position}
	for group_id: String in world._groups:
		world._positions[group_id] = world._groups[group_id]["case"]
	return world


func _moved_event(from: Vector2i, path: Array[Vector2i]) -> Dictionary:
	return {"type": Protocol.EVT_MOVED, "entite": PLAYER_ID, "depuis": from, "chemin": path}


func _refused(command: Dictionary, reason: String) -> Array[Dictionary]:
	var events: Array[Dictionary] = [{
		"type": Protocol.EVT_REFUSED,
		"commande": str(command.get("type", "")),
		"raison": reason,
	}]
	return events
