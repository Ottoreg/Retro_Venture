class_name GameMap
extends RefCounted
## Une carte du monde : un rectangle à l'écran entièrement couvert de cases en losange, en rangées
## décalées comme dans Dofus. Les cases entières sont jouables ; les demi-cases coupées par le bord
## du rectangle sont du décor.
##
## Le contenu est décrit par un plan texte : une ligne par rangée, un caractère par case (voir
## `LEGEND` et `data/README.md`). Les chiffres 1 à 9 placent les groupes de monstres décrits dans
## la liste `groupes`, les lettres minuscules les PNJ de la liste `pnj` (par leur `marqueur`).
## Les `sorties` relient les bords de la carte aux cartes voisines. Les lignes paires du plan (2e, 4e…) sont décalées d'une demi-case
## et commencent par un espace, qui représente la demi-case du bord gauche.

## Caractère du plan → type d'obstacle ("" = case praticable).
const LEGEND := {
	".": "", "@": "", "A": "arbre", "M": "mur", "R": "rocher", "E": "eau",
	"+": "", "$": "coffre", "=": "lit", ":": "", "#": "bloc", "*": "pierre_passage",
}
## Sol dessiné autrement que le sol de la carte (praticable) : caractère du plan → type.
const GROUND_KINDS := {":": "chemin"}
## Obstacles invisibles (sous un grand décor, comme un bâtiment).
const HIDDEN_OBSTACLES := ["bloc"]
## Zone cachée par un bâtiment, au-dessus de chaque case « bloc » à l'écran (pixels) : demi-largeur
## et hauteur. Les groupes de monstres ne vont pas s'y promener.
const BUILDING_SHADOW := Vector2(96, 144)
const NO_CELL := Vector2i(-99999, -99999)
## Porte : case praticable qui mène à une autre carte (liste `portes`, dans l'ordre du plan).
const DOOR_CHAR := "+"
## Meubles avec lesquels on interagit depuis une case voisine.
const FURNITURE := ["coffre", "lit", "pierre_passage"]
## Pierre de Passage : on y voyage d'une zone à l'autre (voir `data/passages/`).
const TRAVEL_STONE := "pierre_passage"
## Sols possibles (dessin).
const FLOORS := ["herbe", "parquet"]
## Instances : "" (carte partagée) ou "joueur" (une copie par joueur en multijoueur, comme sa maison).
const INSTANCES := ["", "joueur"]
## Délai de réapparition par défaut d'un groupe de monstres vaincu, en secondes : [min, max].
const DEFAULT_RESPAWN := [120, 180]
## Nombre maximal de monstres dans un groupe.
const MAX_GROUP_SIZE := 3
const SPAWN_CHAR := "@"
## Type d'obstacle des ressources récoltables (lettres majuscules hors légende, voir `Profession`).
const RESOURCE_OBSTACLE := "ressource"
## Obstacles plats : bloquent le passage mais se dessinent au niveau du sol.
const FLAT_OBSTACLES := ["eau"]
## Bords de carte, et bord d'arrivée sur la carte voisine.
const EXIT_DIRECTIONS := ["haut", "bas", "gauche", "droite"]
const OPPOSITE_DIRECTION := {"haut": "bas", "bas": "haut", "gauche": "droite", "droite": "gauche"}
## Cases de placement en combat, comme dans Dofus : un calque « placement » de la taille du plan,
## `j` pour les cases de départ des joueurs, `m` pour celles des monstres, « . » (ou l'espace du
## début des lignes décalées) ailleurs. Obligatoire sur une carte qui a des groupes de monstres.
const PLACEMENT_PLAYER := "j"
const PLACEMENT_MONSTER := "m"
## Caractères du plan sur lesquels une case de placement peut être posée (sol praticable, départ,
## chemin ; les chiffres des groupes aussi).
const PLACEMENT_GROUND := [".", "@", ":"]

var id: String
var display_name: String
## Nombre de cases par rangée.
var columns: int
## Nombre de rangées (pair) : la carte mesure columns × 64 px sur rows × 16 px.
var rows: int
var spawn: Vector2i
## Type d'obstacle (« arbre », « mur »…) par case bloquée.
var obstacles: Dictionary = {}
## Ressources récoltables (arbres, minerais) : case → caractère du plan (voir `GameData.nodes`).
## Elles bloquent le passage comme un obstacle de type `RESOURCE_OBSTACLE`.
var resource_nodes: Dictionary = {}
## Groupes de monstres : { id: String, case: Vector2i, monstres: Array (ids de monstres),
## reapparition: [min, max] }. Un groupe tiré au sort a aussi `parmi` (ids possibles) et `nombre`
## ([min, max]) : `monstres` est alors vide ici, le monde le compose (voir `compose_group`), avec le
## niveau de chaque monstre (`niveaux`).
## Dans le monde, un groupe a aussi son `foyer` (sa case d'origine) et peut s'en éloigner un peu.
var groups: Array[Dictionary] = []
## PNJ : { id: String, nom: String, case: Vector2i, repliques: Array (textes) }.
var npcs: Array[Dictionary] = []
## Cartes voisines : direction (« haut », « bas », « gauche », « droite ») → id de carte.
var exits: Dictionary = {}
## Portes : case → id de la carte où elles mènent.
var doors: Dictionary = {}
## Sol particulier (chemin de terre…) : case → type (voir GROUND_KINDS).
var ground: Dictionary = {}
## Grands décors (bâtiments…) : { image: String, case: Vector2i (case avant, la plus proche de l'écran) }.
var decors: Array[Dictionary] = []
## Sol dessiné (« herbe » ou « parquet »).
var floor_kind := "herbe"
## "" pour une carte partagée, "joueur" pour une carte personnelle (instanciée par joueur en multi).
var instance := ""
## Palette de couleurs de la zone (voir « palettes » dans art/art.json), "" pour celle de base.
var palette := ""
## Cases de départ en combat (voir `PLACEMENT_PLAYER`, `PLACEMENT_MONSTER`), dans l'ordre du calque.
var placement_players: Array[Vector2i] = []
var placement_monsters: Array[Vector2i] = []

## Cases jouables (Vector2i → true).
var _cells: Dictionary = {}
## Cases derrière un bâtiment (voir `is_behind_building`), avec NO_CELL une fois calculées.
var _behind_buildings: Dictionary = {}
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

	var groups_data: Variant = data.get("groupes", [])
	var group_count := 0
	if typeof(groups_data) != TYPE_ARRAY:
		errors.append("« groupes » doit être une liste")
	else:
		group_count = groups_data.size()
		for k in group_count:
			var group: Variant = groups_data[k]
			if typeof(group) != TYPE_DICTIONARY:
				errors.append("groupe %d : objet attendu" % (k + 1))
				continue
			if group.has("parmi"):
				var pool: Variant = group["parmi"]
				if typeof(pool) != TYPE_ARRAY or pool.is_empty() or not _all_strings(pool):
					errors.append("groupe %d : « parmi » doit lister des identifiants de monstres" % (k + 1))
				var count: Variant = group.get("nombre", [1, MAX_GROUP_SIZE])
				if typeof(count) != TYPE_ARRAY or count.size() != 2 or not Spell._is_int_at_least(count[0], 1) \
						or not Spell._is_int_at_least(count[1], 1) or int(count[0]) > int(count[1]) or int(count[1]) > MAX_GROUP_SIZE:
					errors.append("groupe %d : « nombre » doit être [min, max], de 1 à %d" % [k + 1, MAX_GROUP_SIZE])
				if group.has("monstres"):
					errors.append("groupe %d : « monstres » ou « parmi », pas les deux" % (k + 1))
			else:
				var monsters: Variant = group.get("monstres")
				if typeof(monsters) != TYPE_ARRAY or monsters.is_empty() or monsters.size() > MAX_GROUP_SIZE or not _all_strings(monsters):
					errors.append("groupe %d : « monstres » doit lister de 1 à %d identifiants de monstres" % [k + 1, MAX_GROUP_SIZE])
			var delay: Variant = group.get("reapparition", DEFAULT_RESPAWN) if typeof(group) == TYPE_DICTIONARY else null
			if typeof(delay) != TYPE_ARRAY or delay.size() != 2 or not Spell._is_int_at_least(delay[0], 1) \
					or not Spell._is_int_at_least(delay[1], 1) or int(delay[0]) > int(delay[1]):
				errors.append("groupe %d : « reapparition » doit être [min, max] en secondes" % (k + 1))
	var doors_data: Variant = data.get("portes", [])
	if typeof(doors_data) != TYPE_ARRAY:
		errors.append("« portes » doit être une liste d'id de cartes")
	else:
		for target: Variant in doors_data:
			if typeof(target) != TYPE_STRING or str(target).is_empty():
				errors.append("« portes » : id de carte attendu (%s)" % str(target))
	var decors_data: Variant = data.get("decors", [])
	if typeof(decors_data) != TYPE_ARRAY:
		errors.append("« decors » doit être une liste")
	else:
		for decor: Variant in decors_data:
			var spot: Variant = decor.get("case") if typeof(decor) == TYPE_DICTIONARY else null
			if typeof(decor) != TYPE_DICTIONARY or typeof(decor.get("image")) != TYPE_STRING \
					or typeof(spot) != TYPE_ARRAY or spot.size() != 2 or not Spell._is_int_at_least(spot[0], 0) \
					or not Spell._is_int_at_least(spot[1], 0):
				errors.append("décor invalide : { image, case: [ligne, colonne] } attendu (%s)" % str(decor))
	if data.get("sol", "herbe") not in FLOORS:
		errors.append("« sol » doit valoir %s" % str(FLOORS))
	if typeof(data.get("palette", "")) != TYPE_STRING:
		errors.append("« palette » doit être un nom de palette")
	if data.get("instance", "") not in INSTANCES:
		errors.append("« instance » doit valoir %s" % str(INSTANCES))
	var npc_markers := {}
	var npcs_data: Variant = data.get("pnj", [])
	if typeof(npcs_data) != TYPE_ARRAY:
		errors.append("« pnj » doit être une liste")
	else:
		for npc: Variant in npcs_data:
			if typeof(npc) != TYPE_DICTIONARY:
				errors.append("chaque PNJ doit être un objet")
				continue
			var marker: Variant = npc.get("marqueur")
			if typeof(marker) != TYPE_STRING or not _is_npc_char(marker) or npc_markers.has(marker):
				errors.append("PNJ : « marqueur » doit être une lettre minuscule unique (%s)" % str(marker))
			else:
				npc_markers[marker] = 0
			if typeof(npc.get("id")) != TYPE_STRING or str(npc.get("id")).is_empty() or typeof(npc.get("nom")) != TYPE_STRING:
				errors.append("PNJ %s : « id » et « nom » doivent être des textes" % str(marker))
			if typeof(npc.get("atelier", "")) != TYPE_STRING:
				errors.append("PNJ %s : « atelier » doit être un id de métier" % str(marker))
			if typeof(npc.get("marchand", false)) != TYPE_BOOL:
				errors.append("PNJ %s : « marchand » doit valoir true ou false" % str(marker))
			var lines: Variant = npc.get("repliques")
			if typeof(lines) != TYPE_ARRAY or lines.is_empty():
				errors.append("PNJ %s : « repliques » doit être une liste de textes non vide" % str(marker))
			else:
				for text: Variant in lines:
					if typeof(text) != TYPE_STRING:
						errors.append("PNJ %s : chaque réplique doit être un texte" % str(marker))
	var exits_data: Variant = data.get("sorties", {})
	if typeof(exits_data) != TYPE_DICTIONARY:
		errors.append("« sorties » doit être un objet { direction: id de carte }")
	else:
		for direction: Variant in exits_data:
			if direction not in EXIT_DIRECTIONS:
				errors.append("sortie « %s » inconnue (directions : %s)" % [str(direction), str(EXIT_DIRECTIONS)])
			elif typeof(exits_data[direction]) != TYPE_STRING or str(exits_data[direction]).is_empty():
				errors.append("sortie « %s » : id de carte attendu" % direction)
	var group_uses := {}
	var spawn_count := 0
	var door_count := 0
	for i in plan.size():
		var line: String = plan[i]
		if line.length() != width:
			errors.append("ligne %d : %d caractères au lieu de %d" % [i + 1, line.length(), width])
			continue
		var shifted: bool = i % 2 == 1
		for j in line.length():
			var character := line[j]
			if shifted and j == 0:
				if character != " ":
					errors.append("ligne %d : une ligne décalée doit commencer par un espace" % (i + 1))
			elif _is_group_char(character):
				if int(character) > group_count:
					errors.append("ligne %d, colonne %d : groupe %s absent de « groupes »" % [i + 1, j + 1, character])
				group_uses[character] = int(group_uses.get(character, 0)) + 1
			elif _is_npc_char(character):
				if not npc_markers.has(character):
					errors.append("ligne %d, colonne %d : PNJ « %s » absent de « pnj »" % [i + 1, j + 1, character])
				else:
					npc_markers[character] += 1
			elif Profession.is_node_char(character):
				pass  # Ressource : les tests de données vérifient qu'un métier la décrit.
			elif not LEGEND.has(character):
				errors.append("ligne %d, colonne %d : caractère « %s » inconnu" % [i + 1, j + 1, character])
			elif character == SPAWN_CHAR:
				spawn_count += 1
			elif character == DOOR_CHAR:
				door_count += 1
	if typeof(doors_data) == TYPE_ARRAY and door_count != doors_data.size():
		errors.append("le plan contient %d porte(s) « %s » pour %d carte(s) dans « portes »" % [door_count, DOOR_CHAR, doors_data.size()])
	if spawn_count != 1:
		errors.append("le plan doit contenir exactement une case de départ « @ » (%d trouvée(s))" % spawn_count)
	for k in group_count:
		var uses: int = group_uses.get(str(k + 1), 0)
		if uses != 1:
			errors.append("le groupe %d doit apparaître exactement une fois dans le plan (%d trouvé(s))" % [k + 1, uses])
	for marker: String in npc_markers:
		if npc_markers[marker] != 1:
			errors.append("le PNJ « %s » doit apparaître exactement une fois dans le plan (%d trouvé(s))" % [marker, npc_markers[marker]])
	errors.append_array(_validate_placement(data.get("placement"), plan, width, group_count))
	return errors


## Calque « placement » : même taille que le plan, `j` et `m` sur des cases praticables ; au moins
## une case de joueur et `MAX_GROUP_SIZE` cases de monstres si la carte a des groupes.
static func _validate_placement(layer: Variant, plan: Array, width: int, group_count: int) -> PackedStringArray:
	var errors: PackedStringArray = []
	if layer == null:
		if group_count > 0:
			errors.append("« placement » obligatoire sur une carte avec des groupes de monstres (cases j et m)")
		return errors
	if typeof(layer) != TYPE_ARRAY or layer.size() != plan.size():
		errors.append("« placement » doit avoir autant de lignes que le plan (%d)" % plan.size())
		return errors
	var counts := {PLACEMENT_PLAYER: 0, PLACEMENT_MONSTER: 0}
	for i in layer.size():
		if typeof(layer[i]) != TYPE_STRING or str(layer[i]).length() != width:
			errors.append("placement, ligne %d : %d caractères attendus" % [i + 1, width])
			continue
		var line: String = layer[i]
		for j in line.length():
			var mark := line[j]
			if i % 2 == 1 and j == 0:
				continue
			if mark == "." or mark == " ":
				continue
			if not counts.has(mark):
				errors.append("placement, ligne %d, colonne %d : « %s » inconnu (j, m ou .)" % [i + 1, j + 1, mark])
				continue
			var ground: String = str(plan[i])[j]
			if ground not in PLACEMENT_GROUND and not _is_group_char(ground):
				errors.append("placement, ligne %d, colonne %d : case « %s » du plan non praticable" % [i + 1, j + 1, ground])
			counts[mark] += 1
	if counts[PLACEMENT_PLAYER] < 1:
		errors.append("« placement » : au moins une case de joueur « j »")
	if group_count > 0 and counts[PLACEMENT_MONSTER] < MAX_GROUP_SIZE:
		errors.append("« placement » : au moins %d cases de monstres « m » (%d trouvée(s))" % [MAX_GROUP_SIZE, counts[PLACEMENT_MONSTER]])
	return errors


## Construit la carte. `data` doit avoir été vérifié avec `validate()`.
static func from_dict(data: Dictionary) -> GameMap:
	var map := GameMap.new()
	map.id = data["id"]
	map.display_name = str(data.get("nom", map.id))
	var plan: Array = data["plan"]
	var npcs_by_marker := {}
	for npc: Dictionary in data.get("pnj", []):
		npcs_by_marker[npc["marqueur"]] = npc
	map.exits = data.get("sorties", {}).duplicate()
	map.floor_kind = str(data.get("sol", "herbe"))
	map.instance = str(data.get("instance", ""))
	map.palette = str(data.get("palette", ""))
	for decor: Dictionary in data.get("decors", []):
		map.decors.append({"image": decor["image"], "case": plan_cell(int(decor["case"][0]), int(decor["case"][1]))})
	var door_targets: Array = data.get("portes", [])
	var door_index := 0
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
			elif character == DOOR_CHAR:
				map.doors[cell] = door_targets[door_index]
				door_index += 1
			elif GROUND_KINDS.has(character):
				map.ground[cell] = GROUND_KINDS[character]
			elif _is_group_char(character):
				var group_index := int(character)
				var group_data: Dictionary = data["groupes"][group_index - 1]
				var group := {
					"id": "groupe_%d" % group_index,
					"case": cell,
					"monstres": group_data.get("monstres", []).duplicate(),
					"reapparition": group_data.get("reapparition", DEFAULT_RESPAWN).duplicate(),
				}
				if group_data.has("parmi"):
					group["parmi"] = group_data["parmi"].duplicate()
					group["nombre"] = group_data.get("nombre", [1, MAX_GROUP_SIZE]).duplicate()
				map.groups.append(group)
			elif _is_npc_char(character):
				var npc: Dictionary = npcs_by_marker[character]
				map.npcs.append({"id": npc["id"], "nom": npc["nom"], "case": cell, "repliques": npc["repliques"].duplicate(),
					"marchand": npc.get("marchand", false), "atelier": npc.get("atelier", "")})
			elif Profession.is_node_char(character):
				map.resource_nodes[cell] = character
				map.obstacles[cell] = RESOURCE_OBSTACLE
			elif LEGEND[character] != "":
				map.obstacles[cell] = LEGEND[character]
	for row in map.rows + 1:
		for half_column in range(row % 2, 2 * map.columns + 1, 2):
			var cell := cell_at(row, half_column)
			if not map._cells.has(cell):
				map._border_cells.append(cell)
	map.groups.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["id"] < b["id"])
	var layer: Array = data.get("placement", [])
	for i in layer.size():
		var line: String = layer[i]
		for j in line.length():
			if i % 2 == 1 and j == 0:
				continue
			if line[j] == PLACEMENT_PLAYER:
				map.placement_players.append(plan_cell(i, j))
			elif line[j] == PLACEMENT_MONSTER:
				map.placement_monsters.append(plan_cell(i, j))
	map._setup_pathfinding()
	return map


static func _is_group_char(character: String) -> bool:
	return character.length() == 1 and character >= "1" and character <= "9"


static func _is_npc_char(character: String) -> bool:
	return character.length() == 1 and character >= "a" and character <= "z"


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


## Vrai si la case est derrière un bâtiment (on n'y verrait pas ce qui s'y tient).
func is_behind_building(cell: Vector2i) -> bool:
	if _behind_buildings.is_empty():
		_behind_buildings[NO_CELL] = true  # Calculé une fois pour toutes.
		var blocks: Array[Vector2] = []
		for block: Vector2i in obstacles:
			if obstacles[block] in HIDDEN_OBSTACLES:
				blocks.append(IsoGrid.cell_to_screen(block))
		for candidate: Vector2i in _cells:
			var at := IsoGrid.cell_to_screen(candidate)
			for block in blocks:
				var offset := block - at
				if absf(offset.x) <= BUILDING_SHADOW.x and offset.y > 0.0 and offset.y <= BUILDING_SHADOW.y:
					_behind_buildings[candidate] = true
					break
	return _behind_buildings.has(cell)


func is_walkable(cell: Vector2i) -> bool:
	return is_inside(cell) and not obstacles.has(cell) and npc_at(cell).is_empty()


## PNJ sur la case, ou `{}`.
func npc_at(cell: Vector2i) -> Dictionary:
	for npc in npcs:
		if npc["case"] == cell:
			return npc
	return {}


func get_npc(npc_id: String) -> Dictionary:
	for npc in npcs:
		if npc["id"] == npc_id:
			return npc
	return {}


## Case de la Pierre de Passage de la carte (Vector2i(-1, -1) s'il n'y en a pas).
func travel_stone() -> Vector2i:
	for cell: Vector2i in obstacles:
		if obstacles[cell] == TRAVEL_STONE:
			return cell
	return Vector2i(-1, -1)


## Case praticable qui touche `cell` (de préférence devant elle), pour y faire arriver le joueur.
func beside(cell: Vector2i) -> Vector2i:
	for offset: Vector2i in [Vector2i(1, 1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1)]:
		if is_walkable(cell + offset):
			return cell + offset
	return nearest_walkable(cell)


## Porte de cette carte qui mène à `map_id` (case d'arrivée quand on en vient), sinon le départ.
func door_to(map_id: String) -> Vector2i:
	for cell: Vector2i in doors:
		if doors[cell] == map_id:
			return cell
	return spawn


## Directions des sorties accessibles depuis cette case (elle doit être au bord de la carte).
func exit_directions(cell: Vector2i) -> Array[String]:
	var result: Array[String] = []
	if not is_inside(cell):
		return result
	var row := cell.x + cell.y
	var half_column := cell.x - cell.y
	if row == 1 and exits.has("haut"):
		result.append("haut")
	if row == rows - 1 and exits.has("bas"):
		result.append("bas")
	if half_column <= 2 and exits.has("gauche"):
		result.append("gauche")
	if half_column >= 2 * columns - 2 and exits.has("droite"):
		result.append("droite")
	return result


## Case d'arrivée sur cette carte pour un personnage sorti par `direction` d'une carte voisine,
## depuis la case `from_cell` de celle-ci : même rangée (ou même colonne), sur le bord opposé.
func arrival_cell(direction: String, from_cell: Vector2i) -> Vector2i:
	var row := from_cell.x + from_cell.y
	var half_column := from_cell.x - from_cell.y
	if direction == "haut":
		row = rows - 1
	elif direction == "bas":
		row = 1
	row = clampi(row, 1, rows - 1)
	var first_half := 1 if row % 2 == 1 else 2
	var last_half := 2 * columns - 1 if row % 2 == 1 else 2 * columns - 2
	if direction == "droite":
		half_column = first_half
	elif direction == "gauche":
		half_column = last_half
	half_column = clampi(half_column, first_half, last_half)
	if (row + half_column) % 2 != 0:
		half_column += 1 if half_column < last_half else -1
	return nearest_walkable(cell_at(row, half_column))


## Case praticable la plus proche de `cell` (le départ de la carte si aucune).
func nearest_walkable(cell: Vector2i) -> Vector2i:
	var seen := {cell: true}
	var frontier: Array[Vector2i] = [cell]
	while not frontier.is_empty():
		var next_frontier: Array[Vector2i] = []
		for current in frontier:
			if is_walkable(current):
				return current
			for neighbor in IsoGrid.neighbors_4(current):
				if not seen.has(neighbor) and is_inside(neighbor):
					seen[neighbor] = true
					next_frontier.append(neighbor)
		frontier = next_frontier
	return spawn


## Vrai si les deux cases se touchent (par un côté ou par la pointe).
static func is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return maxi(absi(a.x - b.x), absi(a.y - b.y)) <= 1


## Plus court chemin de `from` jusqu'à une case praticable qui touche `target` (un PNJ, une
## ressource…), sans la case de départ ; vide si `from` la touche déjà ou si c'est impossible.
func approach_path(from: Vector2i, target: Vector2i) -> Array[Vector2i]:
	var best: Array[Vector2i] = []
	if is_adjacent(from, target):
		return best
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var path := find_path(from, target + Vector2i(dx, dy))
			if not path.is_empty() and (best.is_empty() or path.size() < best.size()):
				best = path
	return best


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


## Monstres qu'un groupe peut contenir (sa liste fixe, ou ceux qu'on tire au sort).
static func possible_monsters(group: Dictionary) -> Array:
	return group["parmi"] if group.has("parmi") else group["monstres"]


## Copie du groupe prête à paraître sur la carte : un groupe tiré au sort reçoit ses monstres, et
## chaque monstre son niveau (`niveaux`, dans l'ordre de `monstres`, tirés dans sa tranche par
## `GameData.roll_monster_level` ; 1 sans données). `foyer` : sa case d'origine, autour de laquelle
## il se promène.
static func compose_group(group: Dictionary, rng: RandomNumberGenerator, data: GameData = null) -> Dictionary:
	var composed := group.duplicate(true)
	composed["foyer"] = group["case"]
	if group.has("parmi"):
		var pool: Array = group["parmi"]
		var count: Array = group["nombre"]
		var monsters: Array = []
		for i in rng.randi_range(int(count[0]), int(count[1])):
			monsters.append(pool[rng.randi_range(0, pool.size() - 1)])
		composed["monstres"] = monsters
	if data != null:
		composed["niveaux"] = data.roll_group_levels(composed["monstres"], rng)
	else:
		var levels: Array = []
		levels.resize(composed["monstres"].size())
		levels.fill(1)
		composed["niveaux"] = levels
	return composed


static func _all_strings(values: Array) -> bool:
	for value: Variant in values:
		if typeof(value) != TYPE_STRING or str(value).is_empty():
			return false
	return true
