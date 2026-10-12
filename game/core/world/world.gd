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

var map: GameMap
var data: GameData
var player_voie := DEFAULT_VOIE
var player_name := DEFAULT_NAME
## Combat en cours, ou `null` en exploration.
var combat: Combat = null

## Case occupée par chaque entité, par identifiant (le joueur et les groupes de monstres).
var _positions: Dictionary = {}
## Groupes de monstres encore présents : id → { id, case, monstres }.
var _groups: Dictionary = {}
var _combat_group := ""
var _combat_count := 0
var _approach_from := Vector2i.ZERO


func _init(p_map: GameMap, p_data: GameData = null) -> void:
	map = p_map
	data = p_data
	_positions[PLAYER_ID] = map.spawn
	for group in map.groups:
		_groups[group["id"]] = group.duplicate(true)
		_positions[group["id"]] = group["case"]


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
	return _refused(command, Protocol.REASON_UNKNOWN_COMMAND)


func _move(command: Dictionary) -> Array[Dictionary]:
	var entity_id: Variant = command.get("entite")
	var target: Variant = command.get("cible")
	if typeof(entity_id) != TYPE_STRING or typeof(target) != TYPE_VECTOR2I:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	if entity_id != PLAYER_ID:
		return _refused(command, Protocol.REASON_UNKNOWN_ENTITY)
	if not map.is_inside(target):
		return _refused(command, Protocol.REASON_OUT_OF_MAP)
	if not map.is_walkable(target):
		return _refused(command, Protocol.REASON_BLOCKED)
	var from: Vector2i = _positions[PLAYER_ID]
	if from == target:
		return _refused(command, Protocol.REASON_ALREADY_THERE)
	var path := map.find_path(from, target)
	if path.is_empty():
		return _refused(command, Protocol.REASON_NO_PATH)

	_positions[PLAYER_ID] = target
	var events: Array[Dictionary] = [_moved_event(from, path)]
	return events


## Le joueur marche jusqu'au groupe de monstres, puis le combat commence.
func _engage(command: Dictionary) -> Array[Dictionary]:
	var group_id: Variant = command.get("groupe")
	var entity_id: Variant = command.get("entite")
	if typeof(entity_id) != TYPE_STRING or entity_id != PLAYER_ID or typeof(group_id) != TYPE_STRING:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	if not _groups.has(group_id):
		return _refused(command, Protocol.REASON_UNKNOWN_ENTITY)
	if data == null:
		return _refused(command, Protocol.REASON_WRONG_PHASE)
	var group: Dictionary = _groups[group_id]
	var from: Vector2i = _positions[PLAYER_ID]
	var target: Vector2i = group["case"]
	var path := map.find_path(from, target)
	if path.is_empty() and from != target:
		return _refused(command, Protocol.REASON_NO_PATH)

	var events: Array[Dictionary] = []
	if not path.is_empty():
		events.append(_moved_event(from, path))
	_positions[PLAYER_ID] = target
	combat = _create_combat(group, from)
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
	var player := data.create_player(player_voie, PLAYER_ID, player_name)
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
	events.append({
		"type": Protocol.EVT_EXPLORATION,
		"position": _positions[PLAYER_ID],
		"groupe_vaincu": defeated_group,
	})
	combat = null
	_combat_group = ""


func _moved_event(from: Vector2i, path: Array[Vector2i]) -> Dictionary:
	return {"type": Protocol.EVT_MOVED, "entite": PLAYER_ID, "depuis": from, "chemin": path}


func _refused(command: Dictionary, reason: String) -> Array[Dictionary]:
	var events: Array[Dictionary] = [{
		"type": Protocol.EVT_REFUSED,
		"commande": str(command.get("type", "")),
		"raison": reason,
	}]
	return events
