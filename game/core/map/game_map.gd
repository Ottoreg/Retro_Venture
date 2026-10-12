class_name GameMap
extends RefCounted
## Une carte du monde : dimensions, cases bloquantes, case de départ et recherche de chemin.
## Format des données : voir `data/README.md`.

## Obstacles plats : bloquent le passage mais se dessinent au niveau du sol.
const FLAT_OBSTACLES := ["eau"]

var id: String
var display_name: String
var size: Vector2i
var spawn: Vector2i
## Type d'obstacle (« arbre », « mur »…) par case bloquée.
var obstacles: Dictionary = {}

var _astar_explore := AStarGrid2D.new()
var _astar_combat := AStarGrid2D.new()


## Liste des erreurs de `data` (vide si la carte est valide).
static func validate(data: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(data.get("id")) != TYPE_STRING or str(data.get("id")).is_empty():
		errors.append("« id » doit être un texte non vide")
	var width: Variant = data.get("largeur")
	var height: Variant = data.get("hauteur")
	if not _is_number(width) or int(width) <= 0 or not _is_number(height) or int(height) <= 0:
		errors.append("« largeur » et « hauteur » doivent être des entiers positifs")
		return errors
	var map_size := Vector2i(int(width), int(height))

	var occupied := {}
	var obstacles_data: Variant = data.get("obstacles", {})
	if typeof(obstacles_data) != TYPE_DICTIONARY:
		errors.append("« obstacles » doit être un objet { type: [[x, y], …] }")
	else:
		for kind: String in obstacles_data:
			var cells: Variant = obstacles_data[kind]
			if typeof(cells) != TYPE_ARRAY:
				errors.append("obstacles « %s » : liste de cases attendue" % kind)
				continue
			for raw: Variant in cells:
				if not _is_cell(raw):
					errors.append("obstacles « %s » : case invalide %s" % [kind, str(raw)])
					continue
				var cell := _to_cell(raw)
				if not Rect2i(Vector2i.ZERO, map_size).has_point(cell):
					errors.append("obstacles « %s » : case %s hors de la carte" % [kind, cell])
				elif occupied.has(cell):
					errors.append("obstacles « %s » : case %s déjà occupée" % [kind, cell])
				occupied[cell] = true

	var spawn_data: Variant = data.get("depart")
	if not _is_cell(spawn_data):
		errors.append("« depart » doit être une case [x, y]")
	else:
		var spawn_cell := _to_cell(spawn_data)
		if not Rect2i(Vector2i.ZERO, map_size).has_point(spawn_cell):
			errors.append("« depart » %s hors de la carte" % spawn_cell)
		elif occupied.has(spawn_cell):
			errors.append("« depart » %s est sur un obstacle" % spawn_cell)
	return errors


## Construit la carte. `data` doit avoir été vérifié avec `validate()`.
static func from_dict(data: Dictionary) -> GameMap:
	var map := GameMap.new()
	map.id = data["id"]
	map.display_name = str(data.get("nom", map.id))
	map.size = Vector2i(int(data["largeur"]), int(data["hauteur"]))
	map.spawn = _to_cell(data["depart"])
	var obstacles_data: Dictionary = data.get("obstacles", {})
	for kind: String in obstacles_data:
		for raw: Variant in obstacles_data[kind]:
			map.obstacles[_to_cell(raw)] = kind
	map._setup_pathfinding()
	return map


func is_inside(cell: Vector2i) -> bool:
	return Rect2i(Vector2i.ZERO, size).has_point(cell)


func is_walkable(cell: Vector2i) -> bool:
	return is_inside(cell) and not obstacles.has(cell)


## Chemin de `from` à `to`, sans la case de départ ; vide si impossible.
## En exploration, 8 directions (sans couper les coins d'obstacles) ;
## en combat (`combat = true`), 4 directions seulement.
func find_path(from: Vector2i, to: Vector2i, combat := false) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if not is_walkable(from) or not is_walkable(to) or from == to:
		return path
	var astar := _astar_combat if combat else _astar_explore
	path = astar.get_id_path(from, to)
	if not path.is_empty():
		path.remove_at(0)
	return path


func _setup_pathfinding() -> void:
	_astar_explore.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar_explore.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar_explore.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar_combat.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar_combat.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar_combat.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	for astar: AStarGrid2D in [_astar_explore, _astar_combat]:
		astar.region = Rect2i(Vector2i.ZERO, size)
		astar.update()
		for cell: Vector2i in obstacles:
			astar.set_point_solid(cell)


static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


static func _is_cell(value: Variant) -> bool:
	return typeof(value) == TYPE_ARRAY and value.size() == 2 and _is_number(value[0]) and _is_number(value[1])


static func _to_cell(value: Array) -> Vector2i:
	return Vector2i(int(value[0]), int(value[1]))
