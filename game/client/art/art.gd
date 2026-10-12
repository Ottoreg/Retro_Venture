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
## Palette de la zone affichée (voir « palettes » dans art.json), "" pour les couleurs de base.
static var palette := ""
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
	var key := image_name + palette + str(colors)
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
	# Couleurs, de la moins à la plus prioritaire : celles par défaut, celles de la zone, celles de
	# l'image, celles de l'image dans cette zone, puis celles demandées.
	var zone: Dictionary = manifest().get("palettes", {}).get(palette, {})
	var chosen: Dictionary = manifest().get("couleurs", {}).duplicate()
	chosen.merge(zone.get("couleurs", {}), true)
	chosen.merge(spec.get("couleurs", {}), true)
	chosen.merge(zone.get("images", {}).get(image_name, {}), true)
	chosen.merge(colors, true)
	for color_name: String in chosen:
		svg = svg.replace("{{%s}}" % color_name, "#" + str(chosen[color_name]))
	return svg


## Image à utiliser à la place de `image_name` dans la zone en cours (« remplacer » de la palette :
## des champignons au lieu des fleurs chez les gobelins…).
static func substitute(image_name: String) -> String:
	return manifest().get("palettes", {}).get(palette, {}).get("remplacer", {}).get(image_name, image_name)


## Couleur de la palette en cours (« herbe »…).
static func color(color_name: String) -> Color:
	var zone: Dictionary = manifest().get("palettes", {}).get(palette, {})
	return Color("#" + str(zone.get("couleurs", {}).get(color_name, manifest()["couleurs"].get(color_name, "ff00ff"))))


## Dessine l'image sur `canvas`, son ancre en `position`, retournée si `flip`, à la taille
## `size_factor`.
static func draw(canvas: CanvasItem, image_name: String, position: Vector2, colors: Dictionary = {},
		flip := false, modulate := Color.WHITE, size_factor := 1.0) -> void:
	var tex := texture(image_name, colors)
	if tex == null:
		return
	var size := tex.get_size() / SCALE * size_factor
	var origin := anchor(image_name) * size_factor
	if flip:
		# Taille négative : Godot retourne l'image mais garde le bord gauche du rectangle à sa place ;
		# on part donc du bord gauche de l'image retournée (miroir autour de l'ancre).
		canvas.draw_texture_rect(tex, Rect2(position + Vector2(origin.x - size.x, -origin.y), Vector2(-size.x, size.y)), false, modulate)
	else:
		canvas.draw_texture_rect(tex, Rect2(position - origin, size), false, modulate)
