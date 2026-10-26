class_name MapInstance
extends RefCounted
## Une carte vivante, partagée par tous les joueurs qui s'y trouvent : ses groupes de monstres
## (errance, réapparitions), ses ressources épuisées et la case de chacun (joueurs et groupes).
## Le `World` en tient une par carte visitée ; elle garde son état quand tout le monde est parti
## (GDD § 16.5).

var map: GameMap
## Groupes de monstres présents : id → { id, case, monstres, niveaux… } (voir `GameMap.compose_group`).
var groups: Dictionary = {}
## Case occupée par chaque entité, par identifiant (joueurs présents et groupes de monstres).
var positions: Dictionary = {}
## Prochaine promenade de chaque groupe : id du groupe → instant.
var wander_times: Dictionary = {}
## Ressources récoltées en attente de repousse : case → instant de repousse.
var depleted: Dictionary = {}
## Groupes vaincus en attente de réapparition : id du groupe → instant.
var respawns: Dictionary = {}
## Groupes en plein combat : id du groupe → id du joueur qui l'a engagé.
var fighting: Dictionary = {}
## Joueurs présents, dans l'ordre d'arrivée (ids).
var _players: Array[String] = []


func _init(p_map: GameMap, p_groups: Dictionary = {}) -> void:
	map = p_map
	set_groups(p_groups)


## Remplace les groupes (chargement d'une sauvegarde) ; les joueurs restent où ils sont.
func set_groups(p_groups: Dictionary) -> void:
	for group_id: String in groups:
		positions.erase(group_id)
	groups = p_groups
	for group_id: String in groups:
		positions[group_id] = groups[group_id]["case"]


func add_player(player_id: String, cell: Vector2i) -> void:
	if player_id not in _players:
		_players.append(player_id)
	positions[player_id] = cell


func remove_player(player_id: String) -> void:
	_players.erase(player_id)
	positions.erase(player_id)


## Ids des joueurs présents.
func player_ids() -> Array[String]:
	return _players.duplicate()


func has_players() -> bool:
	return not _players.is_empty()


func has_entity(entity_id: String) -> bool:
	return positions.has(entity_id)


func position_of(entity_id: String) -> Vector2i:
	return positions.get(entity_id, Vector2i(-1, -1))


## Groupe de monstres sur la case, ou `{}`.
func group_at(cell: Vector2i) -> Dictionary:
	for group: Dictionary in groups.values():
		if group["case"] == cell:
			return group
	return {}


## Cases occupées par un joueur ou un groupe (case → true).
func taken_cells() -> Dictionary:
	var taken := {}
	for entity_id: String in positions:
		taken[positions[entity_id]] = true
	return taken
