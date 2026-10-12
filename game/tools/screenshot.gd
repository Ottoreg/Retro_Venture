extends SceneTree
## Capture d'écran du jeu, pour vérifier les graphismes sans éditeur :
##   xvfb-run -s "-screen 0 1280x720x24" godot --path game --rendering-driver opengl3 \
##     -s res://tools/screenshot.gd -- sortie.png [carte] [frames] [action]
## Lance la scène du monde (nouvelle partie), attend quelques images et enregistre la vue.
## Action : « combat » (engage le premier groupe de la carte), « inventaire », « metiers » (ouvre la
## fenêtre) ou « pierre » (va utiliser la Pierre de Passage).
## Si « carte » commence par res://, c'est cette scène qui est capturée (menu, création…).

var _output := "capture.png"
var _frames := 30
var _scene: Node
var _action := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_output = args[0]
	var scene_path := "res://client/world/world.tscn"
	if args.size() > 1 and args[1].begins_with("res://"):
		scene_path = args[1]
	elif args.size() > 1 and not args[1].is_empty():
		Session.start_map = args[1]
	if args.size() > 2:
		_frames = int(args[2])
	_action = args[3] if args.size() > 3 else ""
	_scene = load(scene_path).instantiate()
	root.add_child(_scene)


func _process(_delta: float) -> bool:
	if not _action.is_empty() and _frames == 20:
		var view: MapView = _scene.get_node("MapView")
		if _action == "inventaire":
			_scene.get_node("InventoryWindow").toggle()
		elif _action == "metiers":
			_scene.get_node("JobsWindow").toggle()
		else:
			var target: Vector2i = view.world.groups()[0]["case"] if _action == "combat" else view.current_map().travel_stone()
			view._on_click(target)
			for i in 200:
				if not view.is_busy():
					break
				view._process(0.3)
		_action = ""
	_frames -= 1
	if _frames > 0:
		return false
	var image := root.get_viewport().get_texture().get_image()
	image.save_png(_output)
	print("Capture : %s (%d × %d)" % [_output, image.get_width(), image.get_height()])
	return true
