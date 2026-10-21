class_name ScreenLayout
extends RefCounted
## Disposition de l'écran, comme Dofus 2 : la zone de jeu au milieu, entourée de bordures
## d'interface qui ne la recouvrent jamais (GDD § 14.3). En haut le bandeau (nom de la carte,
## messages), à gauche et à droite deux bandes (minicarte et suivi des quêtes ; ordre de jeu ou
## résumé du personnage), en bas la barre (historique, sorts, menus).
##
## Une carte standard fait 1216 × 544 : plus large qu'un écran 16:9 une fois le bandeau et la barre
## posés. Elle est donc dessinée à l'échelle qui la fait tenir entre les bandes (≈ 81 % en
## 1280 × 720). Sur un écran plus large, le surplus élargit les bandes ; sur un écran plus haut, il
## laisse une marge au-dessus et au-dessous de la carte. Les petites cartes (intérieurs) gardent la
## même échelle, centrées dans la zone.

## Hauteur du bandeau du haut, liseré compris.
const TOP := 65.0
## Hauteur de la barre du bas.
const BOTTOM := 200.0
## Largeur minimale des bandes latérales.
const BAND := 150.0
## Taille d'une carte standard à l'échelle 1 (`GameMap.screen_rect`).
const MAP_SIZE := Vector2(1216, 544)


## Échelle de la carte pour un écran (taille logique) donné.
static func map_scale(screen: Vector2) -> float:
	return maxf(0.1, minf((screen.x - 2.0 * BAND) / MAP_SIZE.x, (screen.y - TOP - BOTTOM) / MAP_SIZE.y))


## Zone de jeu à l'écran : une carte standard, à l'échelle, centrée entre les bordures.
static func play_rect(screen: Vector2) -> Rect2:
	var drawn := MAP_SIZE * map_scale(screen)
	return Rect2(Vector2((screen.x - drawn.x) / 2.0, TOP + (screen.y - TOP - BOTTOM - drawn.y) / 2.0), drawn)


## Largeur de chaque bande latérale (au moins `BAND`).
static func band_width(screen: Vector2) -> float:
	return play_rect(screen).position.x


## Position de la carte (son coin haut gauche) : centrée dans la zone de jeu.
static func map_position(screen: Vector2, map_size: Vector2) -> Vector2:
	var area := play_rect(screen)
	return (area.get_center() - map_size * map_scale(screen) / 2.0).round()
