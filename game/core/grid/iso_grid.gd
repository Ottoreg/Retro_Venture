class_name IsoGrid
extends RefCounted
## Conversions entre la grille du jeu et l'écran (projection isométrique 2:1, cases de 64×32 px).
##
## Le centre de la case (x, y) est en ((x - y) × 32, (x + y) × 16) : augmenter x descend vers la
## droite à l'écran, augmenter y descend vers la gauche. Les 4 voisins directs d'une case sont donc
## ses voisins en diagonale à l'écran, comme dans Dofus.

const TILE_SIZE := Vector2i(64, 32)
const HALF_TILE := Vector2(32, 16)

const DIRECTIONS_4: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


## Centre de la case, en pixels, relatif au centre de la case (0, 0).
static func cell_to_screen(cell: Vector2i) -> Vector2:
	return grid_to_screen(Vector2(cell))


## Comme `cell_to_screen`, pour une position fractionnaire (personnage en train de marcher).
static func grid_to_screen(grid_pos: Vector2) -> Vector2:
	return Vector2((grid_pos.x - grid_pos.y) * HALF_TILE.x, (grid_pos.x + grid_pos.y) * HALF_TILE.y)


## Position fractionnaire sur la grille correspondant à un point de l'écran.
static func screen_to_grid(screen_pos: Vector2) -> Vector2:
	var a := screen_pos.x / HALF_TILE.x
	var b := screen_pos.y / HALF_TILE.y
	return Vector2((a + b) / 2.0, (b - a) / 2.0)


## Case dont le losange contient le point de l'écran.
static func screen_to_cell(screen_pos: Vector2) -> Vector2i:
	var grid_pos := screen_to_grid(screen_pos)
	return Vector2i(roundi(grid_pos.x), roundi(grid_pos.y))


## Ordre d'affichage : plus la valeur est grande, plus l'objet est devant.
static func depth(grid_pos: Vector2) -> float:
	return grid_pos.x + grid_pos.y


## Nombre de pas en déplacement 4 directions (coût en PM en combat).
static func distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


static func neighbors_4(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for direction in DIRECTIONS_4:
		result.append(cell + direction)
	return result


## Les 4 coins du losange d'une case centrée en `center` : haut, droite, bas, gauche.
static func diamond(center: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(0, -HALF_TILE.y),
		center + Vector2(HALF_TILE.x, 0),
		center + Vector2(0, HALF_TILE.y),
		center + Vector2(-HALF_TILE.x, 0),
	])
