extends SceneTree
## Planche de toutes les images de `art/art.json`, sans affichage (rendu des SVG sur le processeur) :
##   godot --headless --path game -s res://tools/art_sheet.gd -- planche.png [zoom]
## Chaque image est posée dans une case, son ancre marquée d'une croix rouge.

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var output := args[0] if args.size() > 0 else "planche.png"
	var zoom := float(args[1]) if args.size() > 1 else 1.0
	var images: Dictionary = Art.manifest()["images"]
	var cell := Vector2i(int(260 * zoom), int(260 * zoom))
	var columns := 6
	var rows := ceili(images.size() / float(columns))
	var sheet := Image.create(cell.x * columns, cell.y * rows, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.45, 0.52, 0.38))
	var index := 0
	for image_name: String in images:
		var svg := Art._svg(image_name, {})
		var picture := Image.new()
		if picture.load_svg_from_string(svg, Art.SCALE * zoom) != OK:
			print("ÉCHEC : ", image_name)
			index += 1
			continue
		picture.convert(Image.FORMAT_RGBA8)
		var origin := Vector2i(index % columns * cell.x, index / columns * cell.y)
		var anchor := Art.anchor(image_name) * Art.SCALE * zoom
		var at := origin + Vector2i(cell.x / 2, cell.y - int(30 * zoom)) - Vector2i(anchor)
		sheet.blend_rect(picture, Rect2i(Vector2i.ZERO, picture.get_size()), at)
		var cross := origin + Vector2i(cell.x / 2, cell.y - int(30 * zoom))
		for d in range(-4, 5):
			sheet.set_pixelv(cross + Vector2i(d, 0), Color.RED)
			sheet.set_pixelv(cross + Vector2i(0, d), Color.RED)
		print(index, " ", image_name, " ", picture.get_size())
		index += 1
	sheet.save_png(output)
	print("Planche : ", output)
	quit()
