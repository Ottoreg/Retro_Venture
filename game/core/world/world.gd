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
## Régénération hors combat : un PV toutes les REGEN_SECONDS secondes.
const REGEN_SECONDS := 2.0
## Quand un groupe devrait réapparaître sur la case du joueur, il attend encore un peu.
const RESPAWN_RETRY := 5.0
## Promenade des groupes de monstres : délai entre deux déplacements (secondes), nombre de pas au
## plus par déplacement, et distance maximale (en cases) de leur case d'origine.
const GROUP_WANDER_DELAY := [8.0, 20.0]
const GROUP_WANDER_STEPS := 3
const GROUP_WANDER_RANGE := 3
## Monstres élites : chaque espèce tente d'apparaître toutes les 5 à 6 minutes (temps de jeu
## global, quelle que soit la carte du joueur) tant qu'elle n'est pas déjà en vie quelque part. Elle
## gagne un rang d'ancienneté par ELITE_RANK_SECONDS sans être vaincue (10 au plus), chaque rang
## donnant +10 % de chances de butin au combat contre son groupe.
const ELITE_SPAWN_DELAY := [300.0, 360.0]
## Une minute par rang pour les tests (une heure prévue ensuite).
const ELITE_RANK_SECONDS := 60.0
const ELITE_MAX_RANK := 10
const ELITE_LOOT_BONUS_PER_RANK := 0.1
## Au-delà de ce nombre de groupes sur la carte, l'élite prend la place d'un monstre d'un groupe.
const ELITE_MAX_GROUPS := 3
## Id des groupes créés pour une élite (ceux qui ne viennent pas de la carte).
const ELITE_GROUP_PREFIX := "elite_"
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
## Groupes de monstres encore présents sur la carte actuelle : id → { id, case, monstres, niveaux }
## (`niveaux` : le niveau tiré de chaque monstre à l'apparition, dans l'ordre de `monstres`).
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
## Groupes de monstres vaincus en attente de réapparition : id de carte → { id du groupe: instant }.
var _respawns: Dictionary = {}
## Temps accumulé pour la régénération des PV hors combat.
var _regen_time := 0.0
## Prochaine promenade de chaque groupe de la carte actuelle : id du groupe → instant.
var _wander_times: Dictionary = {}
var _combat_count := 0
## Toutes les cartes du jeu (où les élites peuvent apparaître) ; rempli par le client.
var map_ids: Array[String] = []
## Élites en vie : id du monstre élite → { carte, groupe }.
var _elites: Dictionary = {}
## Prochaine tentative d'apparition des élites absentes : id du monstre élite → instant.
var _elite_attempts: Dictionary = {}
## Bonus de butin du combat en cours (élite ancienne), en fraction : 0.3 = +30 %.
var _combat_loot_bonus := 0.0
var _approach_from := Vector2i.ZERO


func _init(p_map: GameMap, p_data: GameData = null, p_map_loader: Callable = Callable(), p_character: Character = null) -> void:
	character = p_character if p_character != null else Character.create(DEFAULT_NAME, "humain", DEFAULT_VOIE)
	data = p_data
	_map_loader = p_map_loader
	rng.randomize()
	_init_travel()
	_set_map(p_map, p_map.spawn)


## Nom d'une carte d'après son id ("" si elle est introuvable).
func map_name(map_id: String) -> String:
	var found := _load_map(map_id)
	return found.display_name if found != null else ""


## Carte d'après son id, chargée au besoin (pour la carte du monde), ou `null` si elle est introuvable.
func map_by_id(map_id: String) -> GameMap:
	return _load_map(map_id)


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


## Groupe de monstres de la carte actuelle, par son id ({} s'il n'y est pas).
func group(group_id: String) -> Dictionary:
	return _groups.get(group_id, {})


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
		if type == Protocol.CMD_USE:
			return _use(command)
		if type == Protocol.CMD_DEPOSIT:
			return _transfer(command, character.inventory, character.chest)
		if type == Protocol.CMD_WITHDRAW:
			return _transfer(command, character.chest, character.inventory)
		if type == Protocol.CMD_TRAVEL:
			return _travel(command)
	return _refused(command, Protocol.REASON_UNKNOWN_COMMAND)


func _move(command: Dictionary) -> Array[Dictionary]:
	var entity_id: Variant = command.get("entite")
	var target: Variant = command.get("cible")
	var exit: Variant = command.get("sortie", "")
	var door: Variant = command.get("porte", false)
	if typeof(entity_id) != TYPE_STRING or typeof(target) != TYPE_VECTOR2I or typeof(exit) != TYPE_STRING or typeof(door) != TYPE_BOOL:
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
	elif door:
		if not map.doors.has(target):
			return _refused(command, Protocol.REASON_NO_EXIT)
		next_map = _load_map(map.doors[target])
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
		var previous_map := map.id
		_set_map(next_map, next_map.door_to(previous_map) if door else next_map.arrival_cell(exit, target))
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


## Change de carte : mémorise les groupes restants de l'ancienne, retrouve ceux de la nouvelle. La
## carte rejoint les cartes visitées du personnage.
func _set_map(next_map: GameMap, player_cell: Vector2i) -> void:
	if map != null:
		_map_states[map.id] = _groups
	map = next_map
	_loaded_maps[map.id] = map
	character.visit_map(map.id)
	_groups = {}
	if _map_states.has(map.id):
		_groups = _map_states[map.id]
	else:
		for group in map.groups:
			_groups[group["id"]] = GameMap.compose_group(group, rng, data)
	_positions = {PLAYER_ID: player_cell}
	_last_walk.clear()
	_wander_times.clear()
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
	if character.inventory.is_overloaded():
		return _refused(command, Protocol.REASON_INVENTORY_OVERLOADED)
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
	var levels: Array = group.get("niveaux", [])
	var index := 0
	for i in group["monstres"].size():
		# Chaque monstre à son niveau tiré à l'apparition (niveau de base s'il manque).
		var level := int(levels[i]) if i < levels.size() else -1
		var monster := data.create_monster(group["monstres"][i], "%s_%d" % [group["id"], index + 1], level)
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
	var player := combat.get_fighter(PLAYER_ID)
	var combat_map := map.id
	var wake_up := {}
	if combat.winner_team == Fighter.TEAM_PLAYERS:
		defeated_group = _combat_group
		var defeated: Dictionary = _groups[_combat_group]
		_combat_loot_bonus = ELITE_LOOT_BONUS_PER_RANK * elite_rank(defeated)
		if defeated.has("elite"):
			_elite_defeated(defeated["elite"])
		if not _combat_group.begins_with(ELITE_GROUP_PREFIX):
			_schedule_respawn(map.id, defeated)
		_groups.erase(_combat_group)
		_positions.erase(_combat_group)
		character.set_hp(player.hp, data)
	else:
		character.set_hp(1, data)  # Vaincu : on se relève avec 1 PV.
		wake_up = _wake_up()
		for event in events:
			if event["type"] == Protocol.EVT_COMBAT_ENDED:
				event["reveil"] = wake_up
	_reward(events)
	if combat.winner_team == Fighter.TEAM_PLAYERS:
		_loot(events)
	var back := {
		"type": Protocol.EVT_EXPLORATION,
		"position": _positions[PLAYER_ID],
		"groupe_vaincu": defeated_group,
	}
	if not wake_up.is_empty():
		back["reveil"] = wake_up
	events.append(back)
	if map.id != combat_map:
		events.append({"type": Protocol.EVT_MAP_CHANGED, "carte": map.id, "nom": map.display_name, "position": _positions[PLAYER_ID]})
	combat = null
	_combat_group = ""
	_combat_loot_bonus = 0.0


## Après une défaite, le joueur se réveille à côté de la Pierre de Passage de son point de
## résurrection, en changeant de carte s'il le faut ; sans point de résurrection (ou si sa carte est
## introuvable), au départ de la carte du combat. Renvoie où : { passage, nom, carte }.
func _wake_up() -> Dictionary:
	var passage: Dictionary = data.passages.get(character.respawn_passage, {}) if data != null else {}
	var target: GameMap = _load_map(passage["carte"]) if not passage.is_empty() else null
	if target == null or target.travel_stone() == Vector2i(-1, -1):
		_positions[PLAYER_ID] = map.spawn
		return {"passage": "", "nom": map.display_name, "carte": map.id}
	_set_map(target, target.beside(target.travel_stone()))
	return {"passage": passage["id"], "nom": passage["nom"], "carte": map.id}


## XP des monstres vaincus, même en cas de défaite (× `Character.XP_RATE`, bonus de Sagesse : +1 %
## par point), et montées de niveau.
func _reward(events: Array[Dictionary]) -> void:
	for event in events:
		if event["type"] == Protocol.EVT_COMBAT_ENDED:
			if int(event["xp"]) <= 0:
				return
			var gain := roundi(int(event["xp"]) * Character.XP_RATE * (100 + character.stat("sagesse", data)) / 100.0)
			event["xp"] = gain
			var levels := character.add_xp(gain)
			event["niveaux"] = levels
			events.append({"type": Protocol.EVT_XP, "gain": gain, "xp": character.xp, "niveau": character.level})
			for reached in levels:
				events.append({"type": Protocol.EVT_LEVEL_UP, "niveau": reached, "points": character.unspent_points})
			events.append(_character_event())
			return


## Butin de victoire, tiré par `Loot` (limite par monstre partagée entre les joueurs), plus des
## écus (+X % avec le passif de race « ecus »).
## Rien ne se perd : si le sac est plein, le butin y entre en surplus (`surcharge` dans
## l'événement) et les combats sont refusés tant qu'on n'a pas fait de la place.
func _loot(events: Array[Dictionary]) -> void:
	var ended: Dictionary = {}
	for event in events:
		if event["type"] == Protocol.EVT_COMBAT_ENDED:
			ended = event
	var player := combat.get_fighter(PLAYER_ID)
	var prospection: int = player.prospection if player != null else Character.BASE_PROSPECTION
	var rng := combat.rng
	var monsters: Array = []
	var coins := 0
	for fighter in combat.fighters:
		if fighter.team == Fighter.TEAM_PLAYERS or not data.monsters.has(fighter.kind):
			continue
		var monster: Dictionary = data.monsters[fighter.kind]
		monsters.append(monster)
		var coin_range: Array = monster.get("ecus", [0, 0])
		coins += rng.randi_range(int(coin_range[0]), int(coin_range[1]))
	coins = roundi(coins * (100 + data.passive_value(character.race_id, "ecus")) / 100.0)
	var found: Array[Dictionary] = []
	for drop: Dictionary in Loot.roll(monsters, {PLAYER_ID: prospection}, rng, _combat_loot_bonus)[PLAYER_ID]:
		var template: Dictionary = data.items[drop["objet"]]
		var quantity: int = drop["quantite"]
		for _unit in (quantity if Item.is_equipment(template) else 1):
			character.inventory.add(template, 1 if Item.is_equipment(template) else quantity, Item.roll_bonuses(template, rng), true)
			found.append({"objet": template["id"], "nom": template["nom"], "rarete": template["rarete"],
				"quantite": 1 if Item.is_equipment(template) else quantity})
	character.inventory.ecus += coins
	ended["butin"] = _merged_loot(found)
	ended["surcharge"] = character.inventory.is_overloaded()
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
	if not inventory.has_room_for(template, quantity):
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

## Fait avancer le temps : les PV se régénèrent hors combat, les ressources récoltées repoussent
## et les groupes de monstres vaincus réapparaissent. Renvoie un événement par ressource
## (EVT_RESOURCE_RESPAWNED) ou groupe (EVT_GROUP_RESPAWNED) revenu sur la carte actuelle.
func update(delta: float) -> Array[Dictionary]:
	clock += delta
	var events: Array[Dictionary] = []
	_regenerate(delta)
	_respawn_groups(events)
	_update_elites(events)
	_wander_groups(events)
	for map_id: String in _depleted:
		var cells: Dictionary = _depleted[map_id]
		for cell: Vector2i in cells.keys():
			if cells[cell] <= clock:
				cells.erase(cell)
				if map != null and map_id == map.id:
					events.append({"type": Protocol.EVT_RESOURCE_RESPAWNED, "carte": map_id, "case": cell})
	return events


## Les groupes de la carte actuelle se promènent de temps en temps, hors combat, sans trop
## s'éloigner de leur case d'origine.
func _wander_groups(events: Array[Dictionary]) -> void:
	if in_combat():
		return
	for group_id: String in _groups:
		if not _wander_times.has(group_id):
			_wander_times[group_id] = clock + rng.randf_range(GROUP_WANDER_DELAY[0], GROUP_WANDER_DELAY[1])
			continue
		if _wander_times[group_id] > clock:
			continue
		_wander_times[group_id] = clock + rng.randf_range(GROUP_WANDER_DELAY[0], GROUP_WANDER_DELAY[1])
		var path := _wander_path(_groups[group_id])
		if path.is_empty():
			continue
		_groups[group_id]["case"] = path[-1]
		_positions[group_id] = path[-1]
		events.append({"type": Protocol.EVT_GROUP_MOVED, "groupe": group_id, "chemin": path, "case": path[-1]})


## Petit trajet au hasard pour un groupe (sans sa case de départ), vide s'il reste sur place :
## des pas droits, sur des cases libres (ni joueur, ni autre groupe, ni porte, ni bord de sortie,
## ni derrière un bâtiment),
## à GROUP_WANDER_RANGE cases au plus de son origine.
func _wander_path(group: Dictionary) -> Array[Vector2i]:
	var start: Vector2i = group["case"]
	var home: Vector2i = group.get("foyer", start)
	var taken := {}
	for entity_id: String in _positions:
		taken[_positions[entity_id]] = true
	var parents := {start: start}
	var frontier: Array[Vector2i] = [start]
	var choices: Array[Vector2i] = []
	for _step in GROUP_WANDER_STEPS:
		var next_frontier: Array[Vector2i] = []
		for cell in frontier:
			for neighbor in IsoGrid.neighbors_4(cell):
				if parents.has(neighbor) or taken.has(neighbor) or not map.is_walkable(neighbor) or map.doors.has(neighbor) \
						or map.is_behind_building(neighbor) \
						or not map.exit_directions(neighbor).is_empty() \
						or maxi(absi(neighbor.x - home.x), absi(neighbor.y - home.y)) > GROUP_WANDER_RANGE:
					continue
				parents[neighbor] = cell
				next_frontier.append(neighbor)
				choices.append(neighbor)
		frontier = next_frontier
	var path: Array[Vector2i] = []
	if choices.is_empty():
		return path
	var cell: Vector2i = choices[rng.randi_range(0, choices.size() - 1)]
	while cell != start:
		path.push_front(cell)
		cell = parents[cell]
	return path


## Rang d'ancienneté de l'élite d'un groupe (0 sans élite) : un par ELITE_RANK_SECONDS en vie.
func elite_rank(group: Dictionary) -> int:
	if not group.has("elite"):
		return 0
	return clampi(floori((clock - float(group["apparition"])) / ELITE_RANK_SECONDS), 0, ELITE_MAX_RANK)


## Où est l'élite de cette espèce : { carte, groupe }, ou {} si elle n'est pas en vie.
func elite_location(elite_id: String) -> Dictionary:
	return _elites.get(elite_id, {})


## Ids des monstres élites du jeu.
func elite_ids() -> Array[String]:
	var ids: Array[String] = []
	if data != null:
		for monster_id: String in data.monsters:
			if data.monsters[monster_id].get("elite", false):
				ids.append(monster_id)
	return ids


## Chaque élite absente tente d'apparaître toutes les 5 à 6 minutes de jeu.
func _update_elites(events: Array[Dictionary]) -> void:
	for elite_id in elite_ids():
		if _elites.has(elite_id):
			continue
		if not _elite_attempts.has(elite_id):
			_elite_attempts[elite_id] = clock + rng.randf_range(ELITE_SPAWN_DELAY[0], ELITE_SPAWN_DELAY[1])
		elif _elite_attempts[elite_id] <= clock:
			_elite_attempts[elite_id] = clock + rng.randf_range(ELITE_SPAWN_DELAY[0], ELITE_SPAWN_DELAY[1])
			if spawn_elite(elite_id, events):
				_elite_attempts.erase(elite_id)


## Fait apparaître l'élite sur une carte (au hasard) où vit sa famille : dans un nouveau groupe s'il
## y a moins de ELITE_MAX_GROUPS groupes, sinon à la place d'un monstre d'un groupe (de sa famille
## de préférence). Faux si c'est impossible pour l'instant (aucune carte, aucune place).
func spawn_elite(elite_id: String, events: Array[Dictionary] = []) -> bool:
	if data == null or not data.monsters.has(elite_id) or _elites.has(elite_id):
		return false
	var family: String = data.monsters[elite_id].get("famille", "")
	var candidates: Array[String] = []
	var ids := map_ids.duplicate()
	if ids.is_empty() and map != null:
		ids.append(map.id)  # Liste des cartes inconnue : au moins la carte actuelle.
	for map_id in ids:
		var candidate := _load_map(map_id)
		if candidate == null:
			continue
		for group in candidate.groups:
			if family in GameMap.possible_monsters(group):
				candidates.append(map_id)
				break
	if candidates.is_empty():
		return false
	var target_id: String = candidates[rng.randi_range(0, candidates.size() - 1)]
	var target := _load_map(target_id)
	var here := map != null and target_id == map.id
	var states := _groups_of(target_id)
	var group := {}
	if states.size() < ELITE_MAX_GROUPS:
		var cell := _free_cell(target, states, here)
		if cell == GameMap.NO_CELL:
			return false
		var monsters: Array = [elite_id]
		if rng.randf() < 0.5:
			monsters.append(family)  # Parfois avec un monstre de sa famille.
		group = {"id": ELITE_GROUP_PREFIX + elite_id, "case": cell, "foyer": cell, "monstres": monsters,
			"niveaux": data.roll_group_levels(monsters, rng), "reapparition": GameMap.DEFAULT_RESPAWN.duplicate()}
		states[group["id"]] = group
		if here:
			_positions[group["id"]] = cell
	else:
		var choices: Array = []
		var family_choices: Array = []
		for candidate: Dictionary in states.values():
			if candidate.has("elite") or (here and in_combat() and candidate["id"] == _combat_group):
				continue
			choices.append(candidate)
			if family in candidate["monstres"]:
				family_choices.append(candidate)
		if not family_choices.is_empty():
			choices = family_choices
		if choices.is_empty():
			return false
		group = choices[rng.randi_range(0, choices.size() - 1)]
		var slot: int = group["monstres"].find(family)
		group["monstres"][maxi(0, slot)] = elite_id
		# Les autres gardent leur niveau ; l'élite prend son niveau fixe.
		group["niveaux"] = _checked_levels(group["monstres"], group.get("niveaux"))
	group["elite"] = elite_id
	group["apparition"] = clock
	_elites[elite_id] = {"carte": target_id, "groupe": group["id"]}
	if here:
		events.append({"type": Protocol.EVT_GROUP_RESPAWNED, "carte": target_id, "groupe": group.duplicate(true)})
	return true


## L'élite a été vaincue : elle pourra réapparaître (5 à 6 minutes plus tard, au plus tôt).
func _elite_defeated(elite_id: String) -> void:
	_elites.erase(elite_id)
	_elite_attempts[elite_id] = clock + rng.randf_range(ELITE_SPAWN_DELAY[0], ELITE_SPAWN_DELAY[1])


## Groupes présents sur une carte (créés comme à une première visite si on n'y est jamais allé).
func _groups_of(map_id: String) -> Dictionary:
	if map != null and map_id == map.id:
		return _groups
	if not _map_states.has(map_id):
		var groups := {}
		var source := _load_map(map_id)
		if source != null:
			for group in source.groups:
				groups[group["id"]] = GameMap.compose_group(group, rng, data)
		_map_states[map_id] = groups
	return _map_states[map_id]


## Case libre au hasard pour un nouveau groupe : praticable, ni occupée, ni porte, ni bord de
## sortie, ni derrière un bâtiment. GameMap.NO_CELL s'il n'y en a pas.
func _free_cell(target: GameMap, states: Dictionary, here: bool) -> Vector2i:
	var taken := {}
	for group: Dictionary in states.values():
		taken[group["case"]] = true
	if here:
		for entity_id: String in _positions:
			taken[_positions[entity_id]] = true
	var cells: Array[Vector2i] = []
	for cell: Vector2i in target.cells():
		if target.is_walkable(cell) and not taken.has(cell) and not target.doors.has(cell) and cell != target.spawn \
				and target.exit_directions(cell).is_empty() and not target.is_behind_building(cell):
			cells.append(cell)
	if cells.is_empty():
		return GameMap.NO_CELL
	return cells[rng.randi_range(0, cells.size() - 1)]


## Un PV toutes les REGEN_SECONDS secondes, hors combat.
func _regenerate(delta: float) -> void:
	if in_combat() or character.hp_lost <= 0:
		_regen_time = 0.0
		return
	_regen_time += delta
	var healed := floori(_regen_time / REGEN_SECONDS)
	if healed > 0:
		_regen_time -= healed * REGEN_SECONDS
		character.hp_lost = maxi(0, character.hp_lost - healed)


func _schedule_respawn(map_id: String, group: Dictionary) -> void:
	if not _respawns.has(map_id):
		_respawns[map_id] = {}
	var delay: Array = group.get("reapparition", GameMap.DEFAULT_RESPAWN)
	_respawns[map_id][group["id"]] = clock + rng.randf_range(float(delay[0]), float(delay[1]))


## Remet en place les groupes dont l'heure est venue (sur la carte actuelle ou une carte visitée).
func _respawn_groups(events: Array[Dictionary]) -> void:
	for map_id: String in _respawns:
		var waiting: Dictionary = _respawns[map_id]
		for group_id: String in waiting.keys():
			if waiting[group_id] > clock:
				continue
			var source := _load_map(map_id)
			var original: Dictionary = {}
			if source != null:
				for group in source.groups:
					if group["id"] == group_id:
						original = group
			var here := map != null and map_id == map.id
			if here and not original.is_empty() and original["case"] in _positions.values():
				waiting[group_id] = clock + RESPAWN_RETRY  # Le joueur (ou un groupe) est dessus : un peu plus tard.
				continue
			waiting.erase(group_id)
			if original.is_empty():
				continue
			var states: Dictionary = _groups if here else _map_states.get(map_id, {})
			var composed := GameMap.compose_group(original, rng, data)
			states[group_id] = composed
			if here:
				_positions[group_id] = original["case"]
				_wander_times.erase(group_id)
				events.append({"type": Protocol.EVT_GROUP_RESPAWNED, "carte": map_id, "groupe": composed.duplicate(true)})


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
	if inventory.entries.size() - freed + places > inventory.capacity:
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


# --- Maison : coffre et lit ----------------------------------------------------------------------

## Raison de refuser d'utiliser le meuble de la case `case` ("" si on peut) : ce doit être un meuble
## du type voulu (tous si `kind` est vide) et le joueur doit se tenir à côté.
func _furniture_refusal(command: Dictionary, kind := "") -> String:
	var cell: Variant = command.get("case")
	if not _is_player_command(command) or typeof(cell) != TYPE_VECTOR2I:
		return Protocol.REASON_INVALID_COMMAND
	var found: String = map.obstacles.get(cell, "")
	if found not in GameMap.FURNITURE or (not kind.is_empty() and found != kind):
		return Protocol.REASON_UNKNOWN_ENTITY
	if not GameMap.is_adjacent(_positions[PLAYER_ID], cell):
		return Protocol.REASON_TOO_FAR
	return ""


func _use(command: Dictionary) -> Array[Dictionary]:
	var reason := _furniture_refusal(command)
	if not reason.is_empty():
		return _refused(command, reason)
	var cell: Vector2i = command["case"]
	if map.obstacles[cell] == GameMap.TRAVEL_STONE:
		var touched: Array[Dictionary] = []
		_activate_passage(touched)
		touched.append(_travel_menu(cell))
		return touched
	if map.obstacles[cell] == "coffre":
		var opened: Array[Dictionary] = [_chest_event(cell)]
		return opened
	# Le lit : une bonne nuit, et tous les PV reviennent.
	var gain := character.hp_lost
	character.hp_lost = 0
	var events: Array[Dictionary] = [{
		"type": Protocol.EVT_RESTED,
		"gain": gain,
		"pv": character.hp(data),
		"pv_max": character.max_hp(data),
	}]
	events.append(_character_event())
	return events


## Déplace un objet entre l'inventaire et le coffre (dans un sens ou dans l'autre).
func _transfer(command: Dictionary, source: Inventory, destination: Inventory) -> Array[Dictionary]:
	var uid: Variant = command.get("objet")
	var quantity := _trade_quantity(command)
	if typeof(uid) != TYPE_STRING or quantity == 0:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var reason := _furniture_refusal(command, "coffre")
	if not reason.is_empty():
		return _refused(command, reason)
	if data == null or not source.entries.has(uid) or not data.items.has(source.entries[uid]["objet"]):
		return _refused(command, Protocol.REASON_UNKNOWN_ITEM)
	if not source.slot_of(uid).is_empty():
		return _refused(command, Protocol.REASON_ITEM_WORN)
	var entry: Dictionary = source.entries[uid]
	if quantity > int(entry["quantite"]):
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var template: Dictionary = data.items[entry["objet"]]
	if not destination.has_room_for(template, 1 if Item.is_equipment(template) else quantity):
		return _refused(command, Protocol.REASON_INVENTORY_FULL)
	var rolled: Dictionary = entry["jets"].duplicate()
	source.remove(uid, quantity)
	destination.add(template, quantity, rolled)
	var events: Array[Dictionary] = [_chest_event(command["case"])]
	events.append_array(_inventory_events())
	return events


# --- Pierres de Passage --------------------------------------------------------------------------

## Pierre de Passage de la carte actuelle (id), ou "".
func _here_passage() -> String:
	if data == null:
		return ""
	for passage_id: String in data.passages:
		if data.passages[passage_id]["carte"] == map.id:
			return passage_id
	return ""


## Vrai si le joueur peut voyager jusqu'à cette pierre : il l'a découverte, ou elle est
## `toujours_connue`.
func is_passage_known(passage_id: String) -> bool:
	return passage_id in character.known_passages or (data != null and data.passage_always_known(passage_id))


## Cartes où le joueur est déjà allé (ids, dans l'ordre des visites), pour l'interface.
func visited_maps() -> Array[String]:
	return character.visited_maps.duplicate()


## La pierre de la zone de départ de la race est toujours connue ; elle sert de point de résurrection
## tant qu'il n'y en a pas d'autre (nouveau personnage, vieille sauvegarde, pierre disparue).
func _init_travel() -> void:
	if data == null:
		return
	var start := data.start_passage(character.race_id)
	if start.is_empty():
		return
	character.discover_passage(start)
	if not data.passages.has(character.respawn_passage):
		character.respawn_passage = start


## Utiliser la pierre de la carte la découvre (si besoin) et en fait le point de résurrection.
func _activate_passage(events: Array[Dictionary]) -> void:
	var passage_id := _here_passage()
	if passage_id.is_empty():
		return
	var passage_name: String = data.passages[passage_id]["nom"]
	if not is_passage_known(passage_id):
		character.discover_passage(passage_id)
		events.append({"type": Protocol.EVT_PASSAGE_DISCOVERED, "passage": passage_id, "nom": passage_name})
	if character.respawn_passage != passage_id:
		character.respawn_passage = passage_id
		events.append({"type": Protocol.EVT_RESPAWN_POINT, "passage": passage_id, "nom": passage_name})


func _travel_menu(cell: Vector2i) -> Dictionary:
	var destinations: Array = []
	for passage_id: String in data.passages:
		var passage: Dictionary = data.passages[passage_id]
		destinations.append({"id": passage_id, "nom": passage["nom"], "carte": passage["carte"],
			"prix": data.passage_price(passage_id), "connue": is_passage_known(passage_id)})
	return {"type": Protocol.EVT_TRAVEL_MENU, "case": cell, "ici": _here_passage(), "destinations": destinations,
		"ecus": character.inventory.ecus, "resurrection": character.respawn_passage}


## Voyage d'une Pierre de Passage à une autre, déjà découverte (ou `toujours_connue`), contre son prix
## en écus : on arrive à côté de la pierre de destination. Arriver ainsi ne la découvre pas et n'en
## fait pas le point de résurrection : il faut l'utiliser.
func _travel(command: Dictionary) -> Array[Dictionary]:
	var destination: Variant = command.get("destination")
	if typeof(destination) != TYPE_STRING:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var reason := _furniture_refusal(command, GameMap.TRAVEL_STONE)
	if not reason.is_empty():
		return _refused(command, reason)
	if data == null or not data.passages.has(destination):
		return _refused(command, Protocol.REASON_UNKNOWN_ENTITY)
	if destination == _here_passage():
		return _refused(command, Protocol.REASON_ALREADY_THERE)
	if not is_passage_known(destination):
		return _refused(command, Protocol.REASON_PASSAGE_UNKNOWN)
	var next_map := _load_map(data.passages[destination]["carte"])
	if next_map == null or next_map.travel_stone() == Vector2i(-1, -1):
		return _refused(command, Protocol.REASON_UNKNOWN_MAP)
	var price := data.passage_price(destination)
	if price > character.inventory.ecus:
		return _refused(command, Protocol.REASON_NOT_ENOUGH_ECUS)
	character.inventory.ecus -= price
	_set_map(next_map, next_map.beside(next_map.travel_stone()))
	var events: Array[Dictionary] = [{
		"type": Protocol.EVT_MAP_CHANGED,
		"carte": map.id,
		"nom": map.display_name,
		"position": _positions[PLAYER_ID],
		"prix": price,
	}]
	if price > 0:
		events.append_array(_inventory_events())
	return events


func _chest_event(cell: Vector2i) -> Dictionary:
	return {"type": Protocol.EVT_CHEST, "case": cell, "coffre": character.chest_sheet(data)}


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
		var groups: Array = []
		for group: Dictionary in _map_states[map_id].values():
			var cell: Vector2i = group["case"]
			var saved_group := {"id": group["id"], "case": [cell.x, cell.y], "monstres": group["monstres"].duplicate(),
				"niveaux": group.get("niveaux", []).duplicate()}
			if group.has("elite"):
				var home: Vector2i = group.get("foyer", cell)
				saved_group["elite"] = group["elite"]
				saved_group["age"] = clock - float(group["apparition"])
				saved_group["foyer"] = [home.x, home.y]
			groups.append(saved_group)
		remaining[map_id] = groups
	var attempts := {}
	for elite_id: String in _elite_attempts:
		attempts[elite_id] = maxf(0.0, float(_elite_attempts[elite_id]) - clock)
	var position := position_of(PLAYER_ID)
	return {
		"version": SAVE_VERSION,
		"personnage": character.to_dict(),
		"carte": map.id,
		"position": [position.x, position.y],
		"groupes_restants": remaining,
		"reapparitions": _saved_timers(_respawns),
		"repousses": _saved_timers(_depleted),
		"elites": attempts,
	}


## Butin regroupé par objet (une ligne par objet, quantités additionnées), dans l'ordre d'obtention.
static func _merged_loot(found: Array) -> Array:
	var merged: Array = []
	var index_of := {}
	for drop: Dictionary in found:
		var key: String = drop["objet"]
		if index_of.has(key):
			merged[index_of[key]]["quantite"] += int(drop["quantite"])
		else:
			index_of[key] = merged.size()
			merged.append(drop.duplicate())
	return merged


## Groupe d'une carte tel qu'il a été sauvegardé (monstres, niveaux et case), si la sauvegarde est
## cohérente ; sinon tel qu'il apparaît d'habitude.
func _restored_group(saved_map: GameMap, group: Dictionary, saved: Dictionary) -> Dictionary:
	var restored := GameMap.compose_group(group, rng, data)
	var monsters: Variant = saved.get("monstres")
	if typeof(monsters) == TYPE_ARRAY and not monsters.is_empty() and monsters.size() <= GameMap.MAX_GROUP_SIZE:
		var known := true
		for monster_id: Variant in monsters:
			known = known and typeof(monster_id) == TYPE_STRING and (data == null or data.monsters.has(monster_id))
		if known:
			restored["monstres"] = monsters.duplicate()
			restored["niveaux"] = _checked_levels(restored["monstres"], saved.get("niveaux"))
	var cell: Variant = saved.get("case")
	if typeof(cell) == TYPE_ARRAY and cell.size() == 2:
		var saved_cell := Vector2i(int(cell[0]), int(cell[1]))
		if saved_map.is_walkable(saved_cell):
			restored["case"] = saved_cell
	_restore_elite_fields(restored, saved)
	return restored


## Groupe d'élite apparu en plus des groupes de la carte, tel qu'il a été sauvegardé ({} si la
## sauvegarde est incohérente).
func _restored_elite_group(saved_map: GameMap, group_id: String, saved: Dictionary) -> Dictionary:
	var cell: Variant = saved.get("case")
	var monsters: Variant = saved.get("monstres")
	if not group_id.begins_with(ELITE_GROUP_PREFIX) or typeof(cell) != TYPE_ARRAY or cell.size() != 2 \
			or typeof(monsters) != TYPE_ARRAY or monsters.is_empty() or monsters.size() > GameMap.MAX_GROUP_SIZE:
		return {}
	for monster_id: Variant in monsters:
		if typeof(monster_id) != TYPE_STRING or (data != null and not data.monsters.has(monster_id)):
			return {}
	var saved_cell := Vector2i(int(cell[0]), int(cell[1]))
	if not saved_map.is_walkable(saved_cell):
		return {}
	var group := {"id": group_id, "case": saved_cell, "foyer": saved_cell, "monstres": monsters.duplicate(),
		"niveaux": _checked_levels(monsters, saved.get("niveaux")), "reapparition": GameMap.DEFAULT_RESPAWN.duplicate()}
	var home: Variant = saved.get("foyer")
	if typeof(home) == TYPE_ARRAY and home.size() == 2 and saved_map.is_walkable(Vector2i(int(home[0]), int(home[1]))):
		group["foyer"] = Vector2i(int(home[0]), int(home[1]))
	_restore_elite_fields(group, saved)
	return group if group.has("elite") else {}


## Niveaux d'un groupe, un par monstre : ceux de `saved` quand chaque monstre peut encore les avoir
## (dans sa tranche, de poids non nul : voir `GameData.is_monster_level`), sinon tirés à nouveau
## (vieille sauvegarde sans niveaux, données changées depuis).
func _checked_levels(monsters: Array, saved: Variant) -> Array:
	var levels: Array = []
	for i in monsters.size():
		var level: Variant = saved[i] if typeof(saved) == TYPE_ARRAY and i < saved.size() else null
		if data == null:
			levels.append(int(level) if Spell._is_int_at_least(level, 1) else 1)
		elif data.is_monster_level(monsters[i], level):
			levels.append(int(level))
		else:
			levels.append(data.roll_monster_level(monsters[i], rng))
	return levels


## Reprend l'élite d'un groupe sauvegardé (et son ancienneté) si elle est cohérente.
func _restore_elite_fields(group: Dictionary, saved: Dictionary) -> void:
	var elite_id: Variant = saved.get("elite")
	if typeof(elite_id) != TYPE_STRING or elite_id not in group["monstres"]:
		return
	group["elite"] = elite_id
	group["apparition"] = clock - maxf(0.0, float(saved.get("age", 0.0)))


## Minuteries (réapparitions, repousses) en secondes restantes : id de carte → [[clé, secondes]…],
## la clé étant un id de groupe ou une case [x, y].
func _saved_timers(timers: Dictionary) -> Dictionary:
	var saved := {}
	for map_id: String in timers:
		var entries: Array = []
		for key: Variant in timers[map_id]:
			var left := maxf(0.0, float(timers[map_id][key]) - clock)
			entries.append([[key.x, key.y] if typeof(key) == TYPE_VECTOR2I else key, left])
		saved[map_id] = entries
	return saved


## Relit des minuteries sauvegardées (voir `_saved_timers`) ; `cells` : clés en cases.
func _load_timers(saved: Variant, cells: bool) -> Dictionary:
	var timers := {}
	if typeof(saved) != TYPE_DICTIONARY:
		return timers
	for map_id: Variant in saved:
		if typeof(map_id) != TYPE_STRING or typeof(saved[map_id]) != TYPE_ARRAY:
			continue
		var entries := {}
		for pair: Variant in saved[map_id]:
			if typeof(pair) != TYPE_ARRAY or pair.size() != 2 or typeof(pair[1]) not in [TYPE_INT, TYPE_FLOAT]:
				continue
			var key: Variant = pair[0]
			if cells:
				if typeof(key) != TYPE_ARRAY or key.size() != 2:
					continue
				key = Vector2i(int(key[0]), int(key[1]))
			elif typeof(key) != TYPE_STRING:
				continue
			entries[key] = clock + float(pair[1])
		timers[map_id] = entries
	return timers


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
			var saved_groups := {}
			for entry: Variant in remaining[map_id]:
				if typeof(entry) == TYPE_STRING:
					saved_groups[entry] = {}  # Ancienne sauvegarde : seulement l'id du groupe.
				elif typeof(entry) == TYPE_DICTIONARY and typeof(entry.get("id")) == TYPE_STRING:
					saved_groups[entry["id"]] = entry
			var groups := {}
			for group in saved_map.groups:
				if saved_groups.has(group["id"]):
					groups[group["id"]] = world._restored_group(saved_map, group, saved_groups[group["id"]])
					saved_groups.erase(group["id"])
			# Groupes d'élites apparus en plus de ceux de la carte.
			for group_id: String in saved_groups:
				var extra := world._restored_elite_group(saved_map, group_id, saved_groups[group_id])
				if not extra.is_empty():
					groups[group_id] = extra
			for group: Dictionary in groups.values():
				if group.has("elite"):
					world._elites[group["elite"]] = {"carte": map_id, "groupe": group["id"]}
			world._map_states[map_id] = groups
		if world._map_states.has(start_map.id):
			world._groups = world._map_states[start_map.id]
	var saved_position: Variant = save.get("position")
	var position := start_map.spawn
	if typeof(saved_position) == TYPE_ARRAY and saved_position.size() == 2:
		var cell := Vector2i(int(saved_position[0]), int(saved_position[1]))
		if start_map.is_walkable(cell):
			position = cell
	world._respawns = world._load_timers(save.get("reapparitions"), false)
	world._depleted = world._load_timers(save.get("repousses"), true)
	var attempts: Variant = save.get("elites", {})
	if typeof(attempts) == TYPE_DICTIONARY:
		for elite_id: Variant in attempts:
			if typeof(elite_id) == TYPE_STRING and typeof(attempts[elite_id]) in [TYPE_INT, TYPE_FLOAT] and not world._elites.has(elite_id):
				world._elite_attempts[elite_id] = world.clock + float(attempts[elite_id])
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
