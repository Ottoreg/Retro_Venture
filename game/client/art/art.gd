class_name Art
extends RefCounted
## Images du jeu : des SVG (`res://art/**/*.svgt`) décrits dans `res://art/art.json`.
##
## Ce sont des modèles : `{{peau}}`, `{{tunique}}`… y sont remplacés par des couleurs avant le
## rendu, ce qui permet de varier races, tenues et PNJ avec les mêmes dessins. Chaque image est
## rendue en 2× (nette si la fenêtre est agrandie) puis dessinée à sa taille, autour de son
## `ancre` (le point posé au sol, en pixels du SVG).

const ROOT := "res://art"
const MANIFEST := "res://art/art.json"
## Facteur de rendu des SVG.
const SCALE := 2.0

static var _manifest: Dictionary = {}
static var _templates: Dictionary = {}
static var _textures: Dictionary = {}


## Contenu de `art.json` (chargé une fois).
static func manifest() -> Dictionary:
	if _manifest.is_empty():
		var data: Variant = DataLoader.load_json(MANIFEST)
		_manifest = data if typeof(data) == TYPE_DICTIONARY else {"images": {}}
	return _manifest


static func has_image(image_name: String) -> bool:
	return manifest()["images"].has(image_name)


## Point d'ancrage de l'image (en pixels, taille réelle).
static func anchor(image_name: String) -> Vector2:
	var spec: Dictionary = manifest()["images"].get(image_name, {})
	var point: Array = spec.get("ancre", [0, 0])
	return Vector2(point[0], point[1])


## Texture de l'image avec ces couleurs (les couleurs absentes prennent celles par défaut du
## manifeste). `null` si l'image n'existe pas.
static func texture(image_name: String, colors: Dictionary = {}) -> Texture2D:
	var key := image_name + str(colors)
	if _textures.has(key):
		return _textures[key]
	var svg := _svg(image_name, colors)
	if svg.is_empty():
		return null
	var image := Image.new()
	if image.load_svg_from_string(svg, SCALE) != OK:
		push_error("SVG illisible : %s" % image_name)
		return null
	# Les pixels transparents prennent la couleur de leurs voisins : pas de liseré sombre quand
	# l'image est réduite et filtrée.
	image.fix_alpha_edges()
	var result := ImageTexture.create_from_image(image)
	_textures[key] = result
	return result


## Texte SVG de l'image, couleurs remplacées ("" si elle n'existe pas).
static func _svg(image_name: String, colors: Dictionary) -> String:
	var spec: Dictionary = manifest()["images"].get(image_name, {})
	if spec.is_empty():
		return ""
	var path := ROOT.path_join(spec["fichier"])
	if not _templates.has(path):
		_templates[path] = FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
	var svg: String = _templates[path]
	# Couleurs : celles demandées, sinon celles de l'image, sinon celles par défaut du manifeste.
	var palette: Dictionary = manifest().get("couleurs", {}).duplicate()
	palette.merge(spec.get("couleurs", {}), true)
	palette.merge(colors, true)
	for color_name: String in palette:
		svg = svg.replace("{{%s}}" % color_name, "#" + str(palette[color_name]))
	return svg


## Dessine l'image sur `canvas`, son ancre en `position`, retournée si `flip`.
static func draw(canvas: CanvasItem, image_name: String, position: Vector2, colors: Dictionary = {},
		flip := false, modulate := Color.WHITE) -> void:
	var tex := texture(image_name, colors)
	if tex == null:
		return
	var size := tex.get_size() / SCALE
	var origin := anchor(image_name)
	if flip:
		canvas.draw_texture_rect(tex, Rect2(position + Vector2(origin.x, -origin.y), Vector2(-size.x, size.y)), false, modulate)
	else:
		canvas.draw_texture_rect(tex, Rect2(position - origin, size), false, modulate)
