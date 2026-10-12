class_name World
extends RefCounted
## Point d'entrée du noyau de jeu. Le client envoie des commandes à `execute()`, qui les valide,
## met à jour l'état et renvoie les événements produits (voir `Protocol`).
## En multijoueur, ce même code tournera sur le serveur.

const PLAYER_ID := "joueur"

var map: GameMap
## Case occupée par chaque entité, par identifiant.
var _positions: Dictionary = {}


func _init(p_map: GameMap) -> void:
	map = p_map
	_positions[PLAYER_ID] = map.spawn


func has_entity(entity_id: String) -> bool:
	return _positions.has(entity_id)


func position_of(entity_id: String) -> Vector2i:
	return _positions.get(entity_id, Vector2i(-1, -1))


func execute(command: Dictionary) -> Array[Dictionary]:
	var type: Variant = command.get("type")
	if typeof(type) == TYPE_STRING and type == Protocol.CMD_MOVE:
		return _move(command)
	return _refused(command, Protocol.REASON_UNKNOWN_COMMAND)


func _move(command: Dictionary) -> Array[Dictionary]:
	var entity_id: Variant = command.get("entite")
	var target: Variant = command.get("cible")
	if typeof(entity_id) != TYPE_STRING or typeof(target) != TYPE_VECTOR2I:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	if not has_entity(entity_id):
		return _refused(command, Protocol.REASON_UNKNOWN_ENTITY)
	if not map.is_inside(target):
		return _refused(command, Protocol.REASON_OUT_OF_MAP)
	if not map.is_walkable(target):
		return _refused(command, Protocol.REASON_BLOCKED)
	var from: Vector2i = _positions[entity_id]
	if from == target:
		return _refused(command, Protocol.REASON_ALREADY_THERE)
	var path := map.find_path(from, target)
	if path.is_empty():
		return _refused(command, Protocol.REASON_NO_PATH)

	_positions[entity_id] = target
	var events: Array[Dictionary] = [{
		"type": Protocol.EVT_MOVED,
		"entite": entity_id,
		"depuis": from,
		"chemin": path,
	}]
	return events


func _refused(command: Dictionary, reason: String) -> Array[Dictionary]:
	var events: Array[Dictionary] = [{
		"type": Protocol.EVT_REFUSED,
		"commande": str(command.get("type", "")),
		"raison": reason,
	}]
	return events
