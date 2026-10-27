class_name MapThumbnail
extends RefCounted
## Vignette d'une carte pour la minicarte et la carte du monde, façon Dofus Rétro : le plan de la
## carte vu d'en haut, une tache de couleur par case (sol, chemins, eau, arbres, bâtiments…).
## Dessinée une fois par carte, puis gardée.

## Pixels de la vignette par pixel de la carte à l'écran.
const SCALE := 1.0 / 8.0
const COLORS := {
	"herbe": Color("6f9a3f"),
	"parquet": Color("8a6640"),
	"chemin": Color("c9a66b"),
	"eau": Color("4f8fc0"),
	"arbre": Color("2f5a26"),
	"ressource": Color("3e6b2e"),
	"rocher": Color("8a8a80"),
	"mur": Color("6e6052"),
	"bloc": Color("9c4a32"),
	"pierre_passage": Color("7fd0f0"),
}

static var _cache: Dictionary = {}


## Vignette de la carte (ou `null` si elle est introuvable) ; `loader` : Callable(id) -> GameMap.
static func texture(map_id: String, loader: Callable) -> Texture2D:
	if _cache.has(map_id):
		return _cache[map_id]
	var game_map: GameMap = loader.call(map_id) if loader.is_valid() else null
	var made: Texture2D = ImageTexture.create_from_image(image(game_map)) if game_map != null else null
	_cache[map_id] = made
	return made


## Plan de la carte en couleurs : chaque case, un petit losange à sa place à l'écran.
static func image(game_map: GameMap) -> Image:
	var all: Array = game_map.cells()
	all.append_array(game_map.border_cells())
	var low := Vector2(INF, INF)
	var high := -low
	for cell: Vector2i in all:
		var center := IsoGrid.cell_to_screen(cell)
		low = low.min(center)
		high = high.max(center)
	var size := Vector2i(((high - low) * SCALE).ceil()) + Vector2i.ONE
	var picture := Image.create(maxi(size.x, 1), maxi(size.y, 1), false, Image.FORMAT_RGBA8)
	picture.fill(COLORS.get(game_map.floor_kind, COLORS["herbe"]))
	var half := IsoGrid.HALF_TILE * SCALE
	for cell: Vector2i in all:
		var color := cell_color(game_map, cell)
		if color == COLORS.get(game_map.floor_kind, COLORS["herbe"]):
			continue
		var center := (IsoGrid.cell_to_screen(cell) - low) * SCALE
		for y in range(floori(center.y - half.y), ceili(center.y + half.y) + 1):
			var spread := half.x * (1.0 - absf(y - center.y) / half.y)
			for x in range(floori(center.x - spread), ceili(center.x + spread) + 1):
				if x >= 0 and y >= 0 and x < size.x and y < size.y:
					picture.set_pixel(x, y, color)
	return picture


static func cell_color(game_map: GameMap, cell: Vector2i) -> Color:
	var floor_color: Color = COLORS.get(game_map.floor_kind, COLORS["herbe"])
	if game_map.resource_nodes.has(cell):
		return COLORS["ressource"]
	var obstacle: String = game_map.obstacles.get(cell, "")
	if not obstacle.is_empty():
		return COLORS.get(obstacle, floor_color.darkened(0.3))
	return COLORS.get(game_map.ground.get(cell, ""), floor_color)
