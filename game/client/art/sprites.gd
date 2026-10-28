class_name Sprites
extends RefCounted
## Personnages en pixel art : une planche PNG par monstre (`res://art/sprites/`, faite par
## `tools/planche_sprites.py`), citée par « planche » dans la section `monstres` d'`art.json`.
##
## La planche a une ligne par direction (`DIRECTIONS`) et 5 cases de 96 × 96 : l'image fixe puis
## les 4 images de la course. Les pieds sont en `FEET` de chaque case. Elle est agrandie au
## chargement en `Art.SCALE` × sans lissage, puis dessinée à sa taille : les pixels restent nets
## même si l'écran met la carte à l'échelle.

const ROOT := "res://art"
## Ordre des lignes de la planche : du sud (vers le bas de l'écran) en tournant par l'est.
const DIRECTIONS := ["sud", "sud-est", "est", "nord-est", "nord", "nord-ouest", "ouest", "sud-ouest"]
const CELL := 96
const FEET := Vector2(48, 80)
const RUN_FRAMES := 4

static var _textures: Dictionary = {}


static func exists(sheet: String) -> bool:
	return ResourceLoader.exists(ROOT.path_join(sheet))


## Planche agrandie (`null` si elle n'existe pas).
static func texture(sheet: String) -> Texture2D:
	if _textures.has(sheet):
		return _textures[sheet]
	var result: Texture2D = null
	var path := ROOT.path_join(sheet)
	if ResourceLoader.exists(path):
		var image: Image = (load(path) as Texture2D).get_image()
		if image.is_compressed():
			image.decompress()
		image.resize(int(image.get_width() * Art.SCALE), int(image.get_height() * Art.SCALE), Image.INTERPOLATE_NEAREST)
		result = ImageTexture.create_from_image(image)
	else:
		push_error("Planche de sprites introuvable : %s" % path)
	_textures[sheet] = result
	return result


## Direction (indice dans `DIRECTIONS`) d'un déplacement à l'écran. La carte est isométrique (case
## deux fois plus large que haute) : on raisonne au sol, où un pas le long d'un axe de la grille
## est une diagonale.
static func direction_of(screen_delta: Vector2) -> int:
	var angle := atan2(screen_delta.y * 2.0, screen_delta.x)
	return posmod(roundi((PI / 2.0 - angle) / (PI / 4.0)), DIRECTIONS.size())


## Côté vers lequel regarde une direction : 1 à droite, -1 à gauche, 0 de face ou de dos.
static func side_of(direction: int) -> int:
	return 0 if direction % 4 == 0 else (1 if direction < 4 else -1)


## La même direction vue dans un miroir (est ↔ ouest).
static func mirrored(direction: int) -> int:
	return posmod(-direction, DIRECTIONS.size())


## Direction d'après l'ancienne orientation (`facing` ±1, `dos` vers le haut de l'écran).
static func from_facing(facing: float, back: bool) -> int:
	if back:
		return 3 if facing > 0.0 else 5
	return 1 if facing > 0.0 else 7


## Dessine la case (`direction`, `frame` : 0 fixe, 1 à 4 la course) les pieds en `base`.
static func draw(canvas: CanvasItem, sheet: String, base: Vector2, direction: int, frame: int,
		size_factor := 1.0, modulate := Color.WHITE) -> void:
	var tex := texture(sheet)
	if tex == null:
		return
	var source := Rect2(Vector2(frame, direction) * CELL * Art.SCALE, Vector2.ONE * CELL * Art.SCALE)
	var target := Rect2(base - FEET * size_factor, Vector2.ONE * CELL * size_factor)
	canvas.draw_texture_rect_region(tex, target, source, modulate)


## Dessine un personnage en pixel art avec les mêmes réglages que `Rig.draw` (`pose`) : la direction
## `cap` du dernier pas, retournée si le personnage regarde de l'autre côté (`facing`), sinon
## `facing` et `dos` ; la course quand il marche.
static func draw_pose(canvas: CanvasItem, appearance: Dictionary, base: Vector2, pose: Dictionary, modulate := Color.WHITE) -> void:
	var facing := float(pose.get("facing", 1.0))
	var direction := int(pose.get("cap", -1))
	if direction < 0:
		direction = from_facing(facing, pose.get("dos", false))
	elif side_of(direction) * facing < 0.0:
		direction = mirrored(direction)
	var walking: bool = pose.get("marche", false)
	var frame := 1 + posmod(int(float(pose.get("phase", 0.0)) * RUN_FRAMES / TAU), RUN_FRAMES) if walking else 0
	var size := float(appearance.get("echelle", 1.0)) * float(pose.get("zoom", 1.0))
	Art.draw(canvas, "ombre", base, {}, false, Color(1, 1, 1, modulate.a), size * 0.75)
	draw(canvas, appearance["planche"], base, direction, frame, size, modulate)
