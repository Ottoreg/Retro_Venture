class_name GameMap
extends RefCounted
## Une carte du monde : un rectangle à l'écran entièrement couvert de cases en losange, en rangées
## décalées comme dans Dofus. Les cases entières sont jouables ; les demi-cases coupées par le bord
## du rectangle sont du décor.
##
## Le contenu est décrit par un plan texte : une ligne par rangée, un caractère par case (voir
## `LEGEND` et `data/README.md`). Les lignes paires du plan (2e, 4e…) sont décalées d'une demi-case
## et commencent par un espace, qui représente la demi-case du bord gauche.

## Caractère du plan → type d'obstacle ("" = case praticable).
const LEGEND := {".": "", "@": "", "A": "arbre", "M": "mur", "R": "rocher", "E": "eau"}
const SPAWN_CHAR := "@"
## Obstacles plats : bloquent le passage mais se dessinent au niveau du sol.
const FLAT_OBSTACLES := ["eau"]

var id: String
var display_name: String
## Nombre de cases par rangée.
var columns: int
## Nombre de rangées (pair) : la carte mesure columns × 64 px sur rows × 16 px.
var rows: int
var spawn: Vector2i
## Type d'obstacle (« arbre », « mur »…) par case bloquée.
var obstacles: Dictionary = {}

## Cases jouables (Vector2i → true).
var _cells: Dictionary = {}
## Demi-cases du bord, affichées mais hors jeu.
var _border_cells: Array[Vector2i] = []
var _astar_explore := AStarGrid2D.new()
var _astar_combat := AStarGrid2D.new()


## Case de la rangée `row` dont le centre est à `half_column` × 32 px du bord gauche.
@warning_ignore("integer_division")
static func cell_at(row: int, half_column: int) -> Vector2i:
	return Vector2i((row + half_column) / 2, (row - half_column) / 2)


## Case correspondant au caractère `char_index` de la ligne `line_index` du plan (à partir de 0).
static func plan_cell(line_index: int, char_index: int) -> Vector2i:
	var row := line_index + 1
	return cell_at(row, 2 * char_index + row % 2)


## Liste des erreurs de `data` (vide si la carte est valide).
static func validate(data: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(data.get("id")) != TYPE_STRING or str(data.get("id")).is_empty():
		errors.append("« id » doit être un texte non vide")
	var plan: Variant = data.get("plan")
	if typeof(plan) != TYPE_ARRAY or plan.size() < 3 or plan.size() % 2 == 0:
		errors.append("« plan » doit être une liste d'un nombre impair de lignes (au moins 3)")
		return errors
	for line: Variant in plan:
		if typeof(line) != TYPE_STRING:
			errors.append("« plan » ne doit contenir que des lignes de texte")
			return errors
	var width: int = str(plan[0]).length()
	if width < 2:
		errors.append("les lignes du plan doivent faire au moins 2 caractères")
		return errors

	var spawn_count := 0
	for i in plan.size():
		var line: String = plan[i]
		if line.length() != width:
			errors.append("ligne %d : %d caractères au lieu de %d" % [i + 1, line.length(), width])
			continue
		var shifted := i % 2 == 1
		for j in line.length():
			var character := line[j]
			if shifted and j == 0:
				if character != " ":
					errors.append("ligne %d : une ligne décalée doit commencer par un espace" % (i + 1))
			elif not LEGEND.has(character):
				errors.append("ligne %d, colonne %d : caractère « %s » inconnu" % [i + 1, j + 1, character])
			elif character == SPAWN_CHAR:
				spawn_count += 1
	if spawn_count != 1:
		errors.append("le plan doit contenir exactement une case de départ « @ » (%d trouvée(s))" % spawn_count)
	return errors


## Construit la carte. `data` doit avoir été vérifié avec `validate()`.
static func from_dict(data: Dictionary) -> GameMap:
	var map := GameMap.new()
	map.id = data["id"]
	map.display_name = str(data.get("nom", map.id))
	var plan: Array = data["plan"]
	map.columns = str(plan[0]).length()
	map.rows = plan.size() + 1
	for i in plan.size():
		var line: String = plan[i]
		for j in line.length():
			if i % 2 == 1 and j == 0:
				continue
			var cell := plan_cell(i, j)
			map._cells[cell] = true
			var character := line[j]
			if character == SPAWN_CHAR:
				map.spawn = cell
			elif LEGEND[character] != "":
				map.obstacles[cell] = LEGEND[character]
	for row in map.rows + 1:
		for half_column in range(row % 2, 2 * map.columns + 1, 2):
			var cell := cell_at(row, half_column)
			if not map._cells.has(cell):
				map._border_cells.append(cell)
	map._setup_pathfinding()
	return map


## Rectangle de la carte à l'écran, dans le repère de `IsoGrid.cell_to_screen`.
func screen_rect() -> Rect2:
	return Rect2(0, 0, columns * IsoGrid.TILE_SIZE.x, rows * IsoGrid.HALF_TILE.y)


## Cases jouables (avec ou sans obstacle).
func cells() -> Array:
	return _cells.keys()


func border_cells() -> Array[Vector2i]:
	return _border_cells


## Vrai pour une case jouable de la carte (les demi-cases du bord n'en font pas partie).
func is_inside(cell: Vector2i) -> bool:
	return _cells.has(cell)


func is_walkable(cell: Vector2i) -> bool:
	return is_inside(cell) and not obstacles.has(cell)


## Chemin de `from` à `to`, sans la case de départ ; vide si impossible.
## En exploration, 8 directions (un pas en diagonale de la grille est interdit seulement s'il passe
## entre deux cases bloquées qui se touchent par la pointe) ;
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
	var first: Vector2i = _cells.keys()[0]
	var min_cell := first
	var max_cell := first
	for cell: Vector2i in _cells:
		min_cell = Vector2i(mini(min_cell.x, cell.x), mini(min_cell.y, cell.y))
		max_cell = Vector2i(maxi(max_cell.x, cell.x), maxi(max_cell.y, cell.y))
	var region := Rect2i(min_cell, max_cell - min_cell + Vector2i.ONE)

	_astar_explore.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_AT_LEAST_ONE_WALKABLE
	_astar_explore.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar_explore.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar_combat.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar_combat.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar_combat.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	for astar: AStarGrid2D in [_astar_explore, _astar_combat]:
		astar.region = region
		astar.update()
		for y in range(region.position.y, region.end.y):
			for x in range(region.position.x, region.end.x):
				var cell := Vector2i(x, y)
				if not is_walkable(cell):
					astar.set_point_solid(cell)
