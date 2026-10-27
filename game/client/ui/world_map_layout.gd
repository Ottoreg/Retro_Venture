class_name WorldMapLayout
extends RefCounted
## Placement des cartes d'une zone sur la carte du monde, sans affichage (testé dans
## `tests/test_world_map.gd`).
##
## Une carte a des coordonnées si son id est de la forme « <zone>_<x>_<y> » (`brumerive_1_0`,
## `crasse_roc_-1_2`) : x vers la droite, y vers le bas, éventuellement négatifs. Les autres (maisons,
## intérieurs) n'apparaissent pas sur la carte du monde.
##
## Toutes les zones tiennent dans un même monde (`world_layout`) : chacune y est décalée de son
## origine (`ZONE_ORIGINS`), de sorte que les zones reliées par une porte se touchent.

## Texte d'une carte voisine pas encore visitée.
const UNKNOWN_NAME := "?"
## État de la Pierre de Passage d'une carte : aucune, découverte, pas encore découverte.
const STONE_NONE := ""
const STONE_KNOWN := "connue"
const STONE_UNKNOWN := "inconnue"

## Place de chaque zone dans le monde : coordonnées monde de sa carte (0, 0). Hautepierre au milieu ;
## les trois zones de départ s'y collent par leurs portes (Route de l'Ouest ↔ Gué de Brume-Haute,
## Route du Nord ↔ Orée du Sud, Route de l'Est ↔ Route des Charrois : vérifié par les tests). Une
## zone absente d'ici est posée sous les autres (`zone_origins`).
const ZONE_ORIGINS := {
	"hautepierre": Vector2i(0, 0),
	"brumerive": Vector2i(-4, 1),
	"sylvebrume": Vector2i(0, -3),
	"crasse_roc": Vector2i(5, 0),
}

static var _id_pattern: RegEx


## Zone et position d'une carte d'après son id : { zone: String, position: Vector2i }, ou {} si l'id
## n'a pas de coordonnées.
static func map_coordinates(map_id: String) -> Dictionary:
	if _id_pattern == null:
		_id_pattern = RegEx.create_from_string("^(.+)_(-?\\d+)_(-?\\d+)$")
	var found := _id_pattern.search(map_id)
	if found == null:
		return {}
	return {"zone": found.get_string(1), "position": Vector2i(int(found.get_string(2)), int(found.get_string(3)))}


## Nom court d'une carte : ce qui suit « — » dans son nom (« Place du village » pour
## « Brumerive — Place du village »), ou le nom entier.
static func short_name(display_name: String) -> String:
	var dash := display_name.find("—")
	return display_name.substr(dash + 1).strip_edges() if dash >= 0 else display_name.strip_edges()


## Zones visitées (celles des cartes à coordonnées de `visited`), dans l'ordre de la première visite.
static func visited_zones(visited: Array) -> Array[String]:
	var zones: Array[String] = []
	for map_id: String in visited:
		var coordinates := map_coordinates(map_id)
		if not coordinates.is_empty() and not zones.has(coordinates["zone"]):
			zones.append(coordinates["zone"])
	return zones


## Nom d'une zone : celui de sa Pierre de Passage sans précision entre parenthèses (« Trône de
## Cendre » pour « Trône de Cendre (élite) »), sinon ce qui précède « — » dans le nom de ses cartes,
## sinon son id. `maps` : id de carte → { nom, sorties } (voir `zone_layout`) ;
## `passages` : id de pierre → { nom, carte } (comme `GameData.passages`).
static func zone_name(zone_id: String, maps: Dictionary, passages: Dictionary = {}) -> String:
	var passage_ids := passages.keys()
	passage_ids.sort()
	for passage_id: String in passage_ids:
		var coordinates := map_coordinates(str(passages[passage_id].get("carte", "")))
		if not coordinates.is_empty() and coordinates["zone"] == zone_id:
			var stone_name := str(passages[passage_id]["nom"]).strip_edges()
			var bracket := stone_name.find(" (")
			if bracket > 0 and stone_name.ends_with(")"):
				stone_name = stone_name.substr(0, bracket)
			return stone_name
	var map_ids := maps.keys()
	map_ids.sort()
	for map_id: String in map_ids:
		var coordinates := map_coordinates(map_id)
		var display_name := str(maps[map_id].get("nom", ""))
		if not coordinates.is_empty() and coordinates["zone"] == zone_id and display_name.contains("—"):
			return display_name.substr(0, display_name.find("—")).strip_edges()
	return zone_id.capitalize()


## Grille d'une zone pour la carte du monde.
## - `maps` : id de carte → { nom: String, sorties: Array (ids des cartes voisines) } ; il suffit d'y
##   mettre les cartes de la zone (les autres sont ignorées).
## - `visited` : ids des cartes visitées ; `current` : id de la carte actuelle.
## - `passages` : id de pierre → { nom, carte } ; `known_passages` : ids des pierres connues.
## Ne figurent que les cartes visitées et leurs voisines (reliées par une sortie) pas encore
## visitées, affichées en « ? » ; les bornes de la grille sont celles de ces cartes.
## Renvoie { zone, nom, origine: Vector2i (coordonnées de la case en haut à gauche), colonnes,
## lignes, cases: Array de { id, coordonnees: Vector2i, case: Vector2i (colonne, ligne dans la
## grille), nom (court, ou « ? »), nom_complet, visitee, actuelle, pierre (STONE_*) }, liens: Array de
## [case, case] (cartes affichées reliées par une sortie) }.
static func zone_layout(zone_id: String, maps: Dictionary, visited: Array, current := "",
		passages: Dictionary = {}, known_passages: Array = []) -> Dictionary:
	# Cartes de la zone : visitées, puis leurs voisines inconnues.
	var shown := {}
	for map_id: String in visited:
		if _in_zone(map_id, zone_id) and maps.has(map_id):
			shown[map_id] = true
	var visited_here := shown.keys()
	for map_id: String in visited_here:
		for neighbor: String in _exits_of(maps, map_id):
			if _in_zone(neighbor, zone_id):
				shown[neighbor] = shown.get(neighbor, false)
	var result := {"zone": zone_id, "nom": zone_name(zone_id, maps, passages), "origine": Vector2i.ZERO,
		"colonnes": 0, "lignes": 0, "cases": [], "liens": []}
	if shown.is_empty():
		return result
	# Bornes.
	var low := Vector2i(1 << 30, 1 << 30)
	var high := -low
	for map_id: String in shown:
		var position: Vector2i = map_coordinates(map_id)["position"]
		low = Vector2i(mini(low.x, position.x), mini(low.y, position.y))
		high = Vector2i(maxi(high.x, position.x), maxi(high.y, position.y))
	result["origine"] = low
	result["colonnes"] = high.x - low.x + 1
	result["lignes"] = high.y - low.y + 1
	# Pierres de Passage des cartes.
	var stones := {}
	for passage_id: String in passages:
		var stone_map := str(passages[passage_id].get("carte", ""))
		if stones.get(stone_map, STONE_NONE) != STONE_KNOWN:
			stones[stone_map] = STONE_KNOWN if passage_id in known_passages else STONE_UNKNOWN
	# Cases, de haut en bas puis de gauche à droite.
	var ids := shown.keys()
	ids.sort_custom(func(a: String, b: String) -> bool: return _before(map_coordinates(a)["position"], map_coordinates(b)["position"]))
	var cases: Array = []
	for map_id: String in ids:
		var position: Vector2i = map_coordinates(map_id)["position"]
		var seen: bool = shown[map_id]
		var full_name := str(maps.get(map_id, {}).get("nom", "")) if seen else ""
		cases.append({"id": map_id, "coordonnees": position, "case": position - low,
			"nom": short_name(full_name) if seen else UNKNOWN_NAME, "nom_complet": full_name,
			"visitee": seen, "actuelle": map_id == current, "pierre": stones.get(map_id, STONE_NONE) if seen else STONE_NONE})
	result["cases"] = cases
	# Liens entre cartes affichées (une fois chacun).
	var links: Array = []
	var linked := {}
	for map_id: String in visited_here:
		for neighbor: String in _exits_of(maps, map_id):
			if not shown.has(neighbor) or neighbor == map_id:
				continue
			var key := "%s|%s" % ([map_id, neighbor] if map_id < neighbor else [neighbor, map_id])
			if linked.has(key):
				continue
			linked[key] = true
			links.append([map_coordinates(map_id)["position"] - low, map_coordinates(neighbor)["position"] - low])
	result["liens"] = links
	return result


## Voisinage d'une carte pour la minicarte : la grille `layout` (voir `zone_layout`) recadrée sur une
## fenêtre fixe de (2 × `radius` + 1) cases, la carte de coordonnées `center` au milieu. Même format
## que `zone_layout` ; les cases hors de la fenêtre disparaissent, les liens qui en sortent restent
## (ils filent vers le bord).
static func neighborhood(layout: Dictionary, center: Vector2i, radius: Vector2i) -> Dictionary:
	var result := layout.duplicate()
	var low := center - radius
	var size := radius * 2 + Vector2i.ONE
	result["origine"] = low
	result["colonnes"] = size.x
	result["lignes"] = size.y
	var window := Rect2i(Vector2i.ZERO, size)
	var shift: Vector2i = layout.get("origine", Vector2i.ZERO) - low
	var cases: Array = []
	for case: Dictionary in layout.get("cases", []):
		var moved := case.duplicate()
		moved["case"] = case["case"] + shift
		if window.has_point(moved["case"]):
			cases.append(moved)
	result["cases"] = cases
	var links: Array = []
	for link: Array in layout.get("liens", []):
		var ends: Array = [link[0] + shift, link[1] + shift]
		if window.has_point(ends[0]) or window.has_point(ends[1]):
			links.append(ends)
	result["liens"] = links
	if layout.has("origines"):
		var origins := {}
		for zone_id: String in layout["origines"]:
			origins[zone_id] = layout["origines"][zone_id] - shift
		result["origines"] = origins
		var zones: Array = []
		for zone: Dictionary in layout.get("zones", []):
			var moved: Dictionary = zone.duplicate()
			moved["cases"] = Rect2i(zone["cases"].position + shift, zone["cases"].size)
			zones.append(moved)
		result["zones"] = zones
	return result


## Origine de chaque zone des cartes `map_ids` dans le monde : celle de `ZONE_ORIGINS`, sinon sous
## les zones placées, de gauche à droite, une carte d'écart entre deux zones (ordre des ids).
static func zone_origins(map_ids: Array) -> Dictionary:
	var bounds := {}  # zone → Rect2i de ses coordonnées
	for map_id: String in map_ids:
		var coordinates := map_coordinates(map_id)
		if coordinates.is_empty():
			continue
		var cell := Rect2i(coordinates["position"], Vector2i.ONE)
		bounds[coordinates["zone"]] = bounds[coordinates["zone"]].merge(cell) if bounds.has(coordinates["zone"]) else cell
	var origins := {}
	var placed := Rect2i()
	for zone_id: String in bounds:
		if ZONE_ORIGINS.has(zone_id):
			origins[zone_id] = ZONE_ORIGINS[zone_id]
			var rect: Rect2i = bounds[zone_id]
			rect.position += ZONE_ORIGINS[zone_id]
			placed = rect if placed.size == Vector2i.ZERO else placed.merge(rect)
	var others := bounds.keys().filter(func(zone_id: String) -> bool: return not origins.has(zone_id))
	others.sort()
	var x := placed.position.x
	for zone_id: String in others:
		var rect: Rect2i = bounds[zone_id]
		origins[zone_id] = Vector2i(x, placed.end.y + 1) - rect.position
		x += rect.size.x + 1
	return origins


## Coordonnées d'une carte dans le monde (son id, décalé de l'origine de sa zone), ou `null`.
static func world_position(map_id: String, origins: Dictionary) -> Variant:
	var coordinates := map_coordinates(map_id)
	if coordinates.is_empty() or not origins.has(coordinates["zone"]):
		return null
	return coordinates["position"] + origins[coordinates["zone"]]


## Toutes les zones sur une même grille, chacune à sa place (`origins`, voir `zone_origins`). Mêmes
## arguments que `zone_layout` (`maps` avec toutes les zones ; une carte peut y avoir des `portes` :
## ids des cartes où mènent ses portes) et même format, en coordonnées monde (`origine`), avec en
## plus : pour chaque case sa `zone` ; `origines` : zone → coordonnées de zone qui tombent sur la
## case (0, 0) (case = position dans la zone − origines[zone]) ; `zones` : [{ zone, nom, cases:
## Rect2i (dans la grille) }]. Les liens comprennent les portes entre deux cartes voisines dans le
## monde (d'une zone à l'autre).
static func world_layout(maps: Dictionary, visited: Array, current := "", passages: Dictionary = {},
		known_passages: Array = [], origins: Dictionary = {}) -> Dictionary:
	if origins.is_empty():
		origins = zone_origins(maps.keys())
	var result := {"zone": "", "nom": "", "origine": Vector2i.ZERO, "colonnes": 0, "lignes": 0,
		"cases": [], "liens": [], "zones": [], "origines": {}}
	var layouts: Array = []
	var low := Vector2i(1 << 30, 1 << 30)
	var high := -low
	var zone_ids := origins.keys()
	zone_ids.sort()
	for zone_id: String in zone_ids:
		var layout := zone_layout(zone_id, maps, visited, current, passages, known_passages)
		if layout["cases"].is_empty():
			continue
		layouts.append(layout)
		var corner: Vector2i = layout["origine"] + origins[zone_id]
		low = Vector2i(mini(low.x, corner.x), mini(low.y, corner.y))
		high = Vector2i(maxi(high.x, corner.x + layout["colonnes"] - 1), maxi(high.y, corner.y + layout["lignes"] - 1))
	if layouts.is_empty():
		return result
	result["origine"] = low
	result["colonnes"] = high.x - low.x + 1
	result["lignes"] = high.y - low.y + 1
	var cells := {}  # id de carte → case
	for layout: Dictionary in layouts:
		var zone_id: String = layout["zone"]
		var shift: Vector2i = layout["origine"] + origins[zone_id] - low
		result["origines"][zone_id] = low - origins[zone_id]
		result["zones"].append({"zone": zone_id, "nom": layout["nom"],
			"cases": Rect2i(shift, Vector2i(layout["colonnes"], layout["lignes"]))})
		for case: Dictionary in layout["cases"]:
			var moved := case.duplicate()
			moved["case"] = case["case"] + shift
			moved["zone"] = zone_id
			result["cases"].append(moved)
			cells[case["id"]] = moved["case"]
		for link: Array in layout["liens"]:
			result["liens"].append([link[0] + shift, link[1] + shift])
	# Portes d'une zone à l'autre, entre cartes voisines dans le monde.
	var linked := {}
	for map_id: String in cells:
		for target: String in maps.get(map_id, {}).get("portes", []):
			if not cells.has(target) or map_coordinates(target)["zone"] == map_coordinates(map_id)["zone"]:
				continue
			var ends: Array = [cells[map_id], cells[target]]
			var key := "%s|%s" % ([map_id, target] if map_id < target else [target, map_id])
			if linked.has(key) or absi(ends[0].x - ends[1].x) + absi(ends[0].y - ends[1].y) != 1:
				continue
			linked[key] = true
			result["liens"].append(ends)
	result["cases"].sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _before(a["case"], b["case"]))
	return result


static func _in_zone(map_id: String, zone_id: String) -> bool:
	var coordinates := map_coordinates(map_id)
	return not coordinates.is_empty() and coordinates["zone"] == zone_id


static func _exits_of(maps: Dictionary, map_id: String) -> Array:
	return maps.get(map_id, {}).get("sorties", [])


## Ordre de lecture : de haut en bas, puis de gauche à droite.
static func _before(a: Vector2i, b: Vector2i) -> bool:
	return a.y < b.y or (a.y == b.y and a.x < b.x)
