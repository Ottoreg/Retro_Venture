extends SceneTree
## Capture d'écran du jeu, pour vérifier les graphismes sans éditeur :
##   xvfb-run -s "-screen 0 1280x720x24" godot --path game --rendering-driver opengl3 \
##     -s res://tools/screenshot.gd -- sortie.png [carte] [frames] [combat]
## Lance la scène du monde (nouvelle partie), attend quelques images et enregistre la vue.
## Avec « combat », engage d'abord le premier groupe de monstres de la carte.

var _output := "capture.png"
var _frames := 30
var _scene: Node
var _fight := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_output = args[0]
	if args.size() > 1 and not args[1].is_empty():
		Session.start_map = args[1]
	if args.size() > 2:
		_frames = int(args[2])
	_fight = args.size() > 3 and args[3] == "combat"
	_scene = load("res://client/world/world.tscn").instantiate()
	root.add_child(_scene)


func _process(_delta: float) -> bool:
	if _fight and _frames == 20:
		_fight = false
		var view: MapView = _scene.get_node("MapView")
		view._on_click(view.world.groups()[0]["case"])
		for i in 200:
			if view.mode == MapView.Mode.COMBAT and not view.is_busy():
				break
			view._process(0.3)
	_frames -= 1
	if _frames > 0:
		return false
	var image := root.get_viewport().get_texture().get_image()
	image.save_png(_output)
	print("Capture : %s (%d × %d)" % [_output, image.get_width(), image.get_height()])
	return true
